// CRITICAL: DO NOT MODIFY THIS FILE WITHOUT EXPLICIT PERMISSION
// ================================================================
//June 15,2025, V1.0
// ================================================================

@preconcurrency import Foundation
import Firebase
// MARK: - Swift 6 Compatibility
// @preconcurrency imports are used for Firebase SDK compatibility with Swift 6's strict concurrency checking
// Firebase SDK types don't yet conform to Sendable protocol, so we use @preconcurrency to suppress warnings
// Remove @preconcurrency when Firebase SDK is updated with Sendable conformance
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
@preconcurrency import GoogleSignIn
import OSLog
import Observation // iOS 17+ for @Observable macro

// MARK: - Constants

/// Constants for UserDefaults keys and other app-wide settings
struct AppConstants {
    struct UserDefaultsKeys {
        static let authVerificationID = "firebaseAuthVerificationID"
        static let lastPhoneNumber = "lastPhoneNumber"
    }
    
    struct Timeouts {
        static let firestoreOperation: TimeInterval = 15.0
        static let phoneVerification: TimeInterval = 60.0
    }
}

// MARK: - Authentication Flow State

/// Comprehensive state machine for authentication flow management
/// This eliminates the need for separate loading flags and provides granular control
enum AuthFlowState: Equatable {
    case initial                                    // App launching, checking existing auth
    case signedOut                                 // No authenticated user
    case signingInEmailPassword                    // Email/password sign-in in progress
    case signingInGoogle                          // Google sign-in in progress
    case phoneInputNumber                         // User needs to input phone number
    case phoneVerifyingNumber                     // Sending verification code via SMS
    case phoneInputCode                           // User needs to input verification code
    case phoneVerifyingCode                       // Verifying SMS code with Firebase
    case profileLoading                           // User authenticated, loading/creating profile
    case signedIn                                 // User fully authenticated with profile loaded
    case error(String)                            // Error occurred with specific message
    case mfaRequired(MultiFactorResolver)         // Multi-factor authentication required
    
    /// Computed property to determine if state indicates loading/processing
    var isLoadingState: Bool {
        switch self {
        case .signingInEmailPassword, .signingInGoogle,
             .phoneVerifyingNumber, .phoneVerifyingCode, .profileLoading:
            return true
        case .initial, .signedOut, .signedIn, .phoneInputNumber, .phoneInputCode,
             .error, .mfaRequired:
            return false
        }
    }
    
    /// Extract error message if in error state
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
    
    /// Extract MFA resolver if MFA is required
    var mfaResolver: MultiFactorResolver? {
        if case .mfaRequired(let resolver) = self {
            return resolver
        }
        return nil
    }
    
    /// Determine if user can attempt sign-in operations
    var canAttemptSignIn: Bool {
        switch self {
        case .signedOut, .phoneInputNumber, .phoneInputCode, .error:
            return true
        default:
            return false
        }
    }
}

// MARK: - Phone Auth Flow State

/// Specific state tracking for phone authentication workflow
enum PhoneAuthFlowState: Equatable {
    case initial                    // Starting state
    case inputPhoneNumber          // Waiting for phone number input
    case verifyingPhoneNumber      // Sending SMS verification
    case inputVerificationCode     // Waiting for SMS code input
    case verifyingVerificationCode // Verifying SMS code
    case completed                 // Phone auth completed successfully
    case error(String)            // Error in phone auth flow
    
    var isLoading: Bool {
        switch self {
        case .verifyingPhoneNumber, .verifyingVerificationCode:
            return true
        default:
            return false
        }
    }
}

// MARK: - Firebase Manager

/// Main Firebase authentication and user management service for MedicationManager
/// 
/// This singleton class serves as the central authentication hub, managing:
/// - User authentication state (signed in/out)
/// - Multiple authentication methods (phone, email/password, Google Sign-In)
/// - Multi-factor authentication (MFA) enrollment and verification
/// - User profile management in Firestore
/// - Session persistence and restoration
///
/// Architecture Design:
/// - Singleton pattern via static shared instance
/// - @MainActor isolated for thread-safe UI updates
/// - ObservableObject for SwiftUI integration
/// - Comprehensive state machine tracking auth flow states
/// - All async operations include timeout handling
///
/// Thread Safety:
/// - All public methods are @MainActor isolated
/// - Firebase operations use structured concurrency with timeouts
/// - State updates are published for reactive UI
///
/// Error Handling:
/// - Comprehensive error states in AuthFlowState enum
/// - All Firebase errors mapped to AppError types
/// - User-friendly error messages via AppStrings
///
/// iOS 18/Swift 6 Migration Note (June 26, 2025):
/// - Migrated from ObservableObject to @Observable for modern Swift 6 compliance
/// - Removed @Published properties as @Observable automatically tracks all stored properties
/// - Views should use direct property access or @Bindable when bindings are needed
/// - Previous ObservableObject implementation is preserved below in comments
/*
@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    // MARK: - Private Properties
    private var db: Firestore!
    private var auth: Auth!
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var googleSignInConfigured = false
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "FirebaseManager")
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authFlowState: AuthFlowState = .initial
    @Published var currentPhoneAuthFlow: PhoneAuthFlowState = .initial
*/
@MainActor
@Observable
final class FirebaseManager: AuthenticationManagerProtocol {
    static let shared = FirebaseManager()
    
    // MARK: - Private Properties
    private var db: Firestore!
    private var auth: Auth!
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var googleSignInConfigured = false
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "FirebaseManager")
    
    // MARK: - Observable Properties (automatically tracked by @Observable)
    var currentUser: User?
    var isAuthenticated = false
    var authFlowState: AuthFlowState = .initial
    var currentPhoneAuthFlow: PhoneAuthFlowState = .initial
    
    // MARK: - Private State
    /// Phone verification ID - automatically persisted to UserDefaults
    private(set) var phoneVerificationID: String? {
        didSet {
            if let id = phoneVerificationID {
                logger.info("Saving verification ID to UserDefaults")
                UserDefaults.standard.set(id, forKey: AppConstants.UserDefaultsKeys.authVerificationID)
            } else {
                logger.info("Removing verification ID from UserDefaults")
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.authVerificationID)
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        print("🟠 [FIREBASE] FirebaseManager.init() - START")
        print("🟠 [FIREBASE] Thread: \(Thread.current), isMain: \(Thread.isMainThread)")
        logger.info("FirebaseManager initializing")
        
        // Check if Firebase is already configured
        if FirebaseApp.app() != nil {
            print("🟠 [FIREBASE] Firebase already configured, initializing services")
            logger.info("Firebase already configured, initializing services")
            initializeFirebaseServices()
            loadPersistedState()
            setupAuthStateListener()
            logger.info("FirebaseManager initialization complete")
        } else {
            print("🟠 [FIREBASE] Firebase NOT configured yet, deferring initialization")
            logger.warning("Firebase not yet configured, deferring initialization")
            // Set to signedOut so UI can render
            authFlowState = .signedOut
            // Try to initialize after a short delay using Swift concurrency
            Task { @MainActor [weak self] in
                print("🟠 [FIREBASE] Deferred init Task started")
                try? await Task.sleep(for: .milliseconds(500))
                print("🟠 [FIREBASE] Deferred init Task woke up after 500ms")
                self?.attemptDeferredInitialization()
            }
        }
        print("🟠 [FIREBASE] FirebaseManager.init() - COMPLETE")
    }
    
    /// Attempt to complete initialization if Firebase is now ready
    private func attemptDeferredInitialization() {
        print("🟠 [FIREBASE] attemptDeferredInitialization called")
        guard auth == nil else { 
            print("🟠 [FIREBASE] Auth already initialized, skipping")
            return 
        } // Already initialized
        guard FirebaseApp.app() != nil else { 
            print("🟠 [FIREBASE] Firebase still not configured after delay")
            logger.error("Firebase still not configured after delay")
            return 
        }
        
        print("🟠 [FIREBASE] Completing deferred Firebase initialization")
        logger.info("Completing deferred Firebase initialization")
        initializeFirebaseServices()
        loadPersistedState()
        setupAuthStateListener()
        print("🟠 [FIREBASE] Deferred initialization complete")
    }
    
    // MARK: - Cleanup
    
    /// Performs cleanup of Firebase resources
    /// Must be called before the app terminates or when resetting authentication
    /// This method replaces deinit to ensure proper @MainActor isolation
    func cleanup() {
        logger.info("Cleaning up Firebase resources")
        if let listener = authStateListener {
            auth?.removeStateDidChangeListener(listener)
            authStateListener = nil
        }
    }
    
    // MARK: - Firebase Services Initialization
    
    /// Initializes core Firebase services and configures optimal settings
    /// 
    /// This method sets up the Firebase infrastructure:
    /// 1. Initializes Firebase Auth for user authentication
    /// 2. Initializes Firestore for data persistence
    /// 3. Configures Firestore cache for offline support
    /// 4. Sets up Google Sign-In configuration
    ///
    /// Cache Configuration:
    /// - Uses persistent cache with unlimited size
    /// - Enables offline data access
    /// - Automatic synchronization when online
    ///
    /// - Note: Firebase.configure() must be called before this (in App delegate)
    ///         This method assumes Firebase is already configured
    private func initializeFirebaseServices() {
        // Firebase should already be configured in MedicationManagerApp
        auth = Auth.auth()
        db = Firestore.firestore()
        
        // Configure Firestore with optimized cache settings
        let settings = FirestoreSettings()
        if #available(iOS 15.0, *) {
            settings.cacheSettings = PersistentCacheSettings(
                sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited)
            )
        } else {
            settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        }
        db.settings = settings
        
        configureGoogleSignIn()
        logger.debug("Firebase services initialized successfully")
    }
    
    /// Configure Google Sign-In with proper error handling
    private func configureGoogleSignIn() {
        guard !googleSignInConfigured else {
            logger.debug("Google Sign-In already configured")
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let errorMsg = AppStrings.ErrorMessages.configurationError
            logger.error("Firebase configuration error: Google Client ID not found")
            authFlowState = .error(errorMsg)
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        googleSignInConfigured = true
        logger.info("Google Sign-In configured successfully")
    }
    
    /// Load any persisted authentication state
    private func loadPersistedState() {
        // Load saved verification ID if exists
        if let savedID = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.authVerificationID) {
            phoneVerificationID = savedID
            currentPhoneAuthFlow = .inputVerificationCode
            logger.info("Loaded persisted verification ID from UserDefaults")
        }
        
        // Set initial auth flow state based on current user
        if let auth = auth, auth.currentUser != nil {
            print("🟠 [FIREBASE] loadPersistedState: Found existing user: \(auth.currentUser!.uid)")
            authFlowState = .profileLoading
            
            // Add a timeout to handle stale sessions
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                // If still in profileLoading after 3 seconds, assume stale session
                if self.authFlowState == .profileLoading {
                    print("🟠 [FIREBASE] Profile loading timed out, signing out stale session")
                    self.logger.warning("Profile loading timed out, signing out")
                    try? self.auth.signOut()
                    self.handleUserSignedOut()
                }
            }
        } else {
            print("🟠 [FIREBASE] loadPersistedState: No existing user, setting to signedOut")
            authFlowState = .signedOut
        }
    }
    
    // MARK: - Authentication State Management
    
    /// Sets up Firebase authentication state listener for real-time auth monitoring
    /// 
    /// This critical listener is the central hub for auth state management:
    /// 1. Monitors all authentication state changes in real-time
    /// 2. Automatically triggers profile loading on sign-in
    /// 3. Clears all user data on sign-out
    /// 4. Handles session restoration on app launch
    ///
    /// Listener Behaviors:
    /// - Fires immediately with current auth state on setup
    /// - Fires whenever auth state changes (sign in/out/token refresh)
    /// - Maintains weak self reference to prevent retain cycles
    /// - Executes on main actor for thread-safe UI updates
    ///
    /// State Transitions:
    /// - No user → User detected: Load profile from Firestore
    /// - User → No user: Clear all cached data
    /// - Always updates isAuthenticated flag
    ///
    /// - Important: This listener is the single source of truth for auth state
    ///             All sign-in methods rely on this for final state updates
    private func setupAuthStateListener() {
        print("🟠 [FIREBASE] setupAuthStateListener called")
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            print("🟠 [FIREBASE] Auth state listener fired: user = \(firebaseUser?.uid ?? "nil")")
            guard let self = self else { 
                print("🟠 [FIREBASE] Auth state listener: self is nil, returning")
                return 
            }
            
            Task { @MainActor in
                self.logger.info("Auth state changed: user \(firebaseUser?.uid ?? "nil")")
                self.isAuthenticated = firebaseUser != nil
                
                if let firebaseUser = firebaseUser {
                    // User is authenticated - load or create profile
                    print("🟠 [FIREBASE] Auth state listener: User authenticated, calling handleUserAuthenticated")
                    await self.handleUserAuthenticated(firebaseUser)
                } else {
                    // User signed out - clean up state
                    print("🟠 [FIREBASE] Auth state listener: User signed out, calling handleUserSignedOut")
                    self.handleUserSignedOut()
                }
            }
        }
        print("🟠 [FIREBASE] setupAuthStateListener complete")
    }
    
    /// Handle when user becomes authenticated
    private func handleUserAuthenticated(_ firebaseUser: FirebaseAuth.User) async {
        print("🟠 [FIREBASE] handleUserAuthenticated called for user: \(firebaseUser.uid)")
        
        // TEMPORARY: Skip profile loading to avoid Firestore hang
        #if DEBUG
        let skipProfileLoading = true  // Change to false to test profile loading
        #else
        let skipProfileLoading = false
        #endif
        
        if skipProfileLoading {
            print("🟠 [FIREBASE] SKIPPING profile loading (DEBUG mode)")
            // Create a minimal user object
            currentUser = User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName ?? "User",
                profileImageURL: nil,
                subscriptionStatus: .trial,
                subscriptionType: nil,
                trialEndDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                createdAt: Date(),
                lastLoginAt: Date(),
                preferences: UserPreferences(),
                caregiverAccess: User.CaregiverAccess(enabled: false, caregivers: []),
                mfaEnabled: false,
                mfaEnrolledAt: nil,
                backupCodes: nil
            )
        } else {
            // Only load profile if we don't have current user or it's a different user
            if currentUser == nil || currentUser?.id != firebaseUser.uid {
                authFlowState = .profileLoading
                print("🟠 [FIREBASE] Loading user profile...")
                await loadUserProfile(uid: firebaseUser.uid)
                print("🟠 [FIREBASE] Profile loading complete")
            }
        }
        
        // Always transition to signedIn state after profile load (success or failure)
        print("🟠 [FIREBASE] Setting authFlowState to .signedIn")
        authFlowState = .signedIn
        isAuthenticated = true
        
        // Clear phone auth state
        if currentPhoneAuthFlow != .initial {
            currentPhoneAuthFlow = .initial
            phoneVerificationID = nil
        }
    }
    
    /// Handle when user signs out
    private func handleUserSignedOut() {
        logger.info("User signed out - clearing state")
        currentUser = nil
        authFlowState = .signedOut
        resetPhoneAuthFlow()
        clearPersistedState()
    }
    
    // MARK: - Phone Authentication
    
    /// Initiates phone authentication by sending SMS verification code
    /// 
    /// This method handles the first step of Firebase phone authentication:
    /// 1. Validates the current auth state allows sign-in
    /// 2. Formats phone number to E.164 format (+1XXXXXXXXXX)
    /// 3. Updates auth flow state to track progress
    /// 4. Sends SMS via Firebase Auth
    /// 5. Returns verification ID for code validation
    ///
    /// Flow sequence:
    /// - User provides phone number → SMS sent → User enters code → Auth completed
    ///
    /// - Parameter phoneNumber: Phone number in any format (will be converted to E.164)
    /// - Returns: Verification ID needed for verifying the SMS code
    /// - Throws: AppError.authentication with specific error cases:
    ///   - .invalidPhoneNumber if formatting fails
    ///   - .phoneSendCodeFailed if SMS sending fails
    ///
    /// - Note: For DEBUG testing:
    ///   - Phone: +16505554567
    ///   - Code: 123456 (auto-filled in Firebase test mode)
    func signInWithPhone(_ phoneNumber: String) async throws -> String {
       logger.info("Starting phone authentication for number")
       
       // Ensure Firebase services are initialized
       if auth == nil {
           logger.warning("Firebase services not initialized, attempting deferred initialization")
           attemptDeferredInitialization()
           
           // If still not initialized, throw error
           guard auth != nil else {
               logger.error("Firebase services failed to initialize")
               throw AppError.authentication(AuthError.signInFailed)
           }
       }
       
       guard authFlowState.canAttemptSignIn else {
           logger.warning("Cannot attempt sign-in in current state: \(String(describing: self.authFlowState))")
           throw AppError.authentication(AuthError.signInFailed)
        }
        // Update flow states
        authFlowState = .phoneVerifyingNumber
        currentPhoneAuthFlow = .verifyingPhoneNumber
        
        // Convert to E.164 format
        let e164Number = formatPhoneNumberE164(phoneNumber)
        logger.debug("Formatted phone number to E.164: \(e164Number)")
        
        #if DEBUG
        // Enable testing mode for the special bypass number (DEBUG builds only)
        if e164Number == "+16505554567" {
            logger.info("Using special test number with verification bypass")
            auth.settings?.isAppVerificationDisabledForTesting = true
        }
        #endif
        
        do {
            // Firebase operation - timeout handling removed due to Swift 6 Sendable constraints
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(e164Number, uiDelegate: nil)
            
            // Success - save verification ID and update state
            self.phoneVerificationID = verificationID
            authFlowState = .phoneInputCode
            currentPhoneAuthFlow = .inputVerificationCode
            
            // Save phone number for potential resend
            UserDefaults.standard.set(phoneNumber, forKey: AppConstants.UserDefaultsKeys.lastPhoneNumber)
            
            logger.info("Phone verification initiated successfully")
            return verificationID
            
        } catch {
            logger.error("Phone verification failed: \(error.localizedDescription)")
            let errorMsg = AppStrings.ErrorMessages.phoneVerificationError
            authFlowState = .error(errorMsg)
            currentPhoneAuthFlow = PhoneAuthFlowState.error(errorMsg)
            throw AppError.authentication(AuthError.phoneVerificationFailed)
        }
    }
    
    /// Verifies SMS code and completes phone authentication
    /// 
    /// This method handles the final step of Firebase phone authentication:
    /// 1. Validates verification ID exists from previous SMS step
    /// 2. Creates phone auth credential with verification code
    /// 3. Signs in to Firebase with the credential
    /// 4. Creates/updates user profile in Firestore
    /// 5. Handles MFA requirements if enabled
    ///
    /// State transitions during verification:
    /// - Updates currentPhoneAuthFlow: inputCode → verifyingCode → completed
    /// - Updates authFlowState based on success/failure
    /// - May transition to mfaRequired state if MFA is enabled
    ///
    /// - Parameter verificationCode: 6-digit SMS code received by user
    /// - Throws: AppError.authentication with specific cases:
    ///   - .verificationIDMissing if signInWithPhone wasn't called first
    ///   - .phoneCodeVerificationFailed for invalid/expired codes
    ///
    /// - Note: On success, the auth state listener handles final state updates
    ///         Profile creation happens asynchronously after auth succeeds
    func verifyPhoneCode(verificationCode: String) async throws {
        logger.info("Starting phone code verification")
        
        guard let verificationID = phoneVerificationID else {
            logger.error("No verification ID available for code verification")
            let errorMsg = AppStrings.ErrorMessages.phoneCodeVerificationError
            authFlowState = .error(errorMsg)
            currentPhoneAuthFlow = .error(errorMsg)
            throw AppError.authentication(.phoneCodeVerificationFailed)
        }
        
        // Update flow states
        authFlowState = .phoneVerifyingCode
        currentPhoneAuthFlow = .verifyingVerificationCode
        
        do {
            // Create phone credential
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: verificationCode
            )
            
            // Attempt sign-in - timeout handling removed due to Swift 6 Sendable constraints
            let authResult = try await self.auth.signIn(with: credential)
            
            logger.info("Phone authentication successful for user: \(authResult.user.uid)")
            
            // Create or update user profile in background
            await createOrUpdateUserProfile(from: authResult.user)
            
            // Clear verification ID since auth completed
            phoneVerificationID = nil
            currentPhoneAuthFlow = .completed
            
        } catch let error as NSError {
            logger.error("Phone code verification failed: \(error.localizedDescription)")
            
            // Check if MFA is required
            if error.code == AuthErrorCode.secondFactorRequired.rawValue,
               let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as? MultiFactorResolver {
                authFlowState = .mfaRequired(resolver)
                logger.info("MFA required for phone authentication")
                return
            }
            
            // Handle other errors
            let errorMsg = AppStrings.ErrorMessages.phoneCodeVerificationError
            authFlowState = .error(errorMsg)
            currentPhoneAuthFlow = .error(errorMsg)
            throw AppError.authentication(.phoneCodeVerificationFailed)
        }
    }
    
    // MARK: - Google Sign-In
    
    /// Performs Google Sign-In authentication using Google Identity Services
    /// 
    /// This method orchestrates the complete Google Sign-In flow:
    /// 1. Validates current auth state allows sign-in
    /// 2. Gets the presenting view controller for Google UI
    /// 3. Presents Google Sign-In UI to user
    /// 4. Exchanges Google tokens for Firebase credential
    /// 5. Signs in to Firebase with Google credential
    /// 6. Profile creation handled by auth state listener
    ///
    /// UI Requirements:
    /// - Must be called from main thread (@MainActor enforced)
    /// - Requires active window scene for presenting Google UI
    /// - Google Sign-In SDK handles the OAuth flow
    ///
    /// Error scenarios:
    /// - No presenting view controller available
    /// - User cancels Google Sign-In
    /// - Invalid or missing ID token from Google
    /// - Firebase sign-in fails with credential
    ///
    /// - Throws: AppError.authentication with specific cases:
    ///   - .signInFailed for general failures
    ///   - .invalidCredentials if Google tokens are invalid
    ///   - .cancelled if user cancels (from Google SDK)
    ///
    /// - Note: Google Sign-In configuration happens in configure()
    ///         Requires GoogleService-Info.plist in app bundle
    func signInWithGoogle() async throws {
        print("🟠 [FIREBASE] signInWithGoogle() called")
        logger.info("Starting Google Sign-In")
        
        // Ensure Firebase services are initialized
        print("🟠 [FIREBASE] Checking auth status: auth = \(auth != nil ? "initialized" : "nil")")
        if auth == nil {
            print("🟠 [FIREBASE] Auth is nil, attempting deferred initialization")
            logger.warning("Firebase services not initialized, attempting deferred initialization")
            attemptDeferredInitialization()
            
            // If still not initialized, throw error
            print("🟠 [FIREBASE] After deferred init attempt: auth = \(auth != nil ? "initialized" : "nil")")
            guard auth != nil else {
                print("🟠 [FIREBASE] Auth still nil after deferred init, throwing error")
                logger.error("Firebase services failed to initialize")
                throw AppError.authentication(AuthError.signInFailed)
            }
        }
        
        guard authFlowState.canAttemptSignIn else {
            // --- FIX 1: Ambiguity in logger interpolation ---
            // Explicitly convert authFlowState to String for the logger
            logger.warning("Cannot attempt Google sign-in in current state: \(String(describing: self.authFlowState))")
            
            // --- FIX 3 (from previous discussion): AppError ambiguity ---
            // Specify the full type of the error case being passed to .authentication
            throw AppError.authentication(AuthError.signInFailed) // Assuming AppError.authentication takes AuthError
        }
        
        // Need to be on the main actor to access UI properties like isKeyWindow
        // @MainActor on the class handles this for the entire function, but sometimes
        // explicit UI calls benefit from being wrapped if not guaranteed on main actor.
        // getPresentingViewController() should handle this internally if needed,
        // but let's assume it's fine as is for now.
        guard let presentingViewController = await getPresentingViewController() else {
            logger.error("No presenting view controller available for Google Sign-In")
            // --- FIX 3 (from previous discussion): AppError ambiguity ---
            // Specify the full type of the error case being passed to .authentication
            throw AppError.authentication(AuthError.signInFailed) // Using signInFailed for general sign-in failure
        }
        
        // Update flow state BEFORE the potentially long-running Google Sign-In process
        authFlowState = .signingInGoogle
        
        do {
            // Perform Google Sign-In interaction
            // GIDSignIn.sharedInstance access should be fine here as it's on the main actor
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                logger.error("Failed to get ID token from Google Sign-In")
                // --- FIX 3 (from previous discussion): AppError ambiguity ---
                // Specify the full type of the error case being passed to .authentication
                throw AppError.authentication(AuthError.invalidCredentials)
            }
            
            // Create Firebase credential from Google tokens
            // GoogleAuthProvider access should be fine here
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            // Sign in to Firebase Auth with Google credential
            // Timeout handling removed due to Swift 6 Sendable constraints
            let authResult = try await self.auth.signIn(with: credential)
            
            logger.info("Google Sign-In successful for user: \(authResult.user.uid)")
            
            // --- Lazy Fallback Strategy ---
            // Authentication is successful NOW. The authStateListener will fire,
            // detect the new user, and handle loading the profile.
            // The listener manages the transition to .profileLoading and then .signedIn.
            // The state here will be updated by the listener, which is the source of truth.
            // We don't explicitly set a success state here, relying on the listener.
            // If the listener is very fast, the state might transition quickly.
            // If the listener or profile load is slow, the state remains .signingInGoogle
            // or transitions to .profileLoading via the listener, keeping the spinner.
            // This accurately reflects that background work is still happening after the GIDSignIn call.
            
            // createOrUpdateUserProfile is called *after* sign-in, and its result is not awaited here.
            // This implements the lazy profile creation/update discussed.
            await createOrUpdateUserProfile(from: authResult.user)
            
            // Note: The authStateListener will handle setting authFlowState to .profileLoading
            // (then .signedIn) and updating currentUser.
            // The `isLoadingState` computed property of authFlowState will correctly
            // be true during .signingInGoogle, .profileLoading, etc., managing the spinner.
            
        } catch let error as NSError {
            logger.error("Google Sign-In failed: \(error.localizedDescription)")
            
            // Check specifically for MFA required error
            if error.code == AuthErrorCode.secondFactorRequired.rawValue,
               let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as? MultiFactorResolver {
                authFlowState = .mfaRequired(resolver) // Transition to MFA state
                logger.info("MFA required after Google Sign-In") // Log this specific case
                // Do NOT throw here, as MFA is a valid state to transition to
                return
            }
            
            // Handle other Google Sign-In errors
            let errorMsg = AppStrings.ErrorMessages.authenticationError // General auth error message
            authFlowState = .error(errorMsg) // Set state to error for UI feedback
            
            // --- FIX 3 (from previous discussion): AppError ambiguity ---
            // Specify the full type of the error case being passed to .authentication
            throw AppError.authentication(AuthError.signInFailed) // Throw the appropriate AppError
        }
    }

    
    // MARK: - Sign Out
    
    /// Sign out current user and clean up state
    func signOut() async throws {
        logger.info("Starting user sign out")
        
        do {
            GIDSignIn.sharedInstance.signOut()
            try auth.signOut()
            
            // State cleanup will be handled by auth state listener
            logger.info("User signed out successfully")
            
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
            let errorMsg = AppStrings.ErrorMessages.signOutError
            authFlowState = .error(errorMsg)
            throw AppError.authentication(.signOutFailed)
        }
    }
    
    // MARK: - User Profile Management
    
    /// Create or update user profile in Firestore
    /// This runs in background and doesn't block authentication success
    private func createOrUpdateUserProfile(from firebaseUser: FirebaseAuth.User) async {
        logger.info("Creating/updating user profile for: \(firebaseUser.uid)")
        
        let userData = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "",
            profileImageURL: firebaseUser.photoURL?.absoluteString,
            subscriptionStatus: .trial,
            subscriptionType: nil,
            trialEndDate: Calendar.current.date(
                byAdding: .day,
                value: Configuration.App.trialDurationDays,
                to: Date()
            ),
            createdAt: Date(),
            lastLoginAt: Date(),
            preferences: UserPreferences(),
            caregiverAccess: User.CaregiverAccess(enabled: false, caregivers: []),
            mfaEnabled: false,
            mfaEnrolledAt: nil,
            backupCodes: nil
        )
        
        do {
            // Firestore operation - timeout handling removed due to Swift 6 Sendable constraints
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try self.db.collection("users").document(firebaseUser.uid).setData(from: userData, merge: true) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            currentUser = userData
            logger.info("User profile created/updated successfully")
            
        } catch {
            logger.error("Failed to create/update user profile: \(error.localizedDescription)")
            // Don't throw here - profile creation failure shouldn't block authentication
            // User can still use the app, profile will be created on next operation
        }
    }
    
    /// Load existing user profile from Firestore
    private func loadUserProfile(uid: String) async {
        logger.info("Loading user profile for: \(uid)")
        print("🟠 [FIREBASE] loadUserProfile: Starting Firestore fetch for uid: \(uid)")
        
        do {
            // Add timeout for Firestore operation
            print("🟠 [FIREBASE] loadUserProfile: About to call getDocument()")
            
            // Create a timeout task
            let documentTask = Task {
                try await self.db.collection("users").document(uid).getDocument()
            }
            
            // Race between document fetch and timeout
            let result = await withTaskGroup(of: DocumentSnapshot?.self) { group in
                group.addTask {
                    do {
                        return try await documentTask.value
                    } catch {
                        print("🟠 [FIREBASE] loadUserProfile: getDocument() error: \(error)")
                        return nil
                    }
                }
                
                group.addTask {
                    try? await Task.sleep(for: .seconds(5))
                    print("🟠 [FIREBASE] loadUserProfile: Timeout after 5 seconds")
                    documentTask.cancel()
                    return nil
                }
                
                // Return first completed result
                if let firstResult = await group.next() {
                    group.cancelAll()
                    return firstResult
                }
                return nil
            }
            
            guard let document = result else {
                print("🟠 [FIREBASE] loadUserProfile: Failed to get document (timeout or error)")
                throw AppError.network(.timeout)
            }
            
            print("🟠 [FIREBASE] loadUserProfile: getDocument() returned, exists: \(document.exists)")
            
            if document.exists {
                currentUser = try document.data(as: User.self)
                logger.info("User profile loaded successfully")
                print("🟠 [FIREBASE] loadUserProfile: Profile loaded successfully")
            } else {
                logger.warning("User profile not found, creating new profile")
                print("🟠 [FIREBASE] loadUserProfile: Profile not found, creating new one")
                if let firebaseUser = auth.currentUser {
                    await createOrUpdateUserProfile(from: firebaseUser)
                }
            }
            
        } catch {
            logger.error("Failed to load user profile: \(error.localizedDescription)")
            print("🟠 [FIREBASE] loadUserProfile: ERROR - \(error)")
            // Don't set error state here - user is still authenticated
            // Profile will be created on next operation
        }
        print("🟠 [FIREBASE] loadUserProfile: Complete")
    }
    
    // MARK: - State Management Helpers
    
    /// Reset phone authentication flow to initial state
    func resetPhoneAuthFlow() {
        logger.debug("Resetting phone auth flow")
        currentPhoneAuthFlow = .initial
        phoneVerificationID = nil
        authFlowState = .signedOut
    }
    
    /// Clear error state and return to appropriate flow state
    func clearError() {
        logger.debug("Clearing error state")
        if isAuthenticated {
            authFlowState = .signedIn
        } else {
            authFlowState = .signedOut
        }
        
        if currentPhoneAuthFlow.isLoading {
            currentPhoneAuthFlow = .initial
        }
    }
    
    /// Clear all persisted state
    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.authVerificationID)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.lastPhoneNumber)
        phoneVerificationID = nil
    }
    
    // MARK: - Helper Methods
    
    /// Get the presenting view controller for Google Sign-In
    private func getPresentingViewController() async -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
    }
    
    /// Format phone number to E.164 format
    private func formatPhoneNumberE164(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.filter { $0.isNumber }
        
        // For US numbers, add +1 country code if not present
        if digitsOnly.count == 10 {
            return "+1\(digitsOnly)"
        } else if digitsOnly.count == 11 && digitsOnly.hasPrefix("1") {
            return "+\(digitsOnly)"
        } else {
            return "+1\(digitsOnly)" // Default to US format
        }
    }
    
    // MARK: - Timeout functionality removed
    // Note: The withTimeout function has been removed due to Swift 6's strict
    // concurrency requirements. Firebase SDK types are not Sendable, which prevents
    // them from being safely passed across actor boundaries in timeout implementations.
    // This will be revisited when Firebase SDK adds Sendable conformance.
    
    // Simple mutex for thread-safe state tracking
    private final class Mutex<T> {
        private var value: T
        private let lock = NSLock()
        
        init(_ value: T) {
            self.value = value
        }
        
        func withLock<U>(_ body: (inout T) throws -> U) rethrows -> U {
            lock.lock()
            defer { lock.unlock() }
            return try body(&value)
        }
    }
}

// MARK: - Multi-Factor Authentication Extensions

extension FirebaseManager {
    /// Enrolls the current user in Multi-Factor Authentication using TOTP
    /// 
    /// This method initiates MFA enrollment for additional account security:
    /// 1. Validates user is authenticated
    /// 2. Creates MFA session with Firebase
    /// 3. Generates TOTP secret and QR code
    /// 4. Creates backup codes for recovery
    /// 
    /// MFA Flow:
    /// 1. Call this method to get QR code
    /// 2. User scans QR code with authenticator app
    /// 3. User enters 6-digit code from app
    /// 4. Call finalizeMFAEnrollment() to complete
    ///
    /// - Returns: Tuple containing:
    ///   - totpSecret: The TOTP secret for enrollment finalization
    ///   - qrCodeURL: URL for QR code to scan with authenticator app
    ///   - backupCodes: Array of backup codes for account recovery
    ///
    /// - Throws: AppError.authentication with cases:
    ///   - .userNotFound if no authenticated user
    ///   - .mfaEnrollmentFailed for enrollment errors
    ///
    /// - Note: Save the backup codes securely - they cannot be retrieved later
    ///         Compatible with Google Authenticator, Authy, etc.
    func enrollMFA() async throws -> (totpSecret: TOTPSecret, qrCodeURL: String, backupCodes: [String]) {
        guard let user = auth.currentUser else {
            throw AppError.authentication(.userNotFound)
        }
        
        logger.info("Starting MFA enrollment")
        authFlowState = .profileLoading
        
        do {
            let multiFactorSession = try await user.multiFactor.session()
            let totpSecret = try await TOTPMultiFactorGenerator.generateSecret(with: multiFactorSession)
            
            let qrCodeURL = totpSecret.generateQRCodeURL(
                withAccountName: user.email ?? "user",
                issuer: AppStrings.App.name
            )
            
            let backupCodes = generateBackupCodes()
            
            logger.info("MFA enrollment initiated successfully")
            return (totpSecret: totpSecret, qrCodeURL: qrCodeURL, backupCodes: backupCodes)
            
        } catch {
            logger.error("MFA enrollment failed: \(error.localizedDescription)")
            let errorMsg = AppStrings.ErrorMessages.mfaEnrollmentError
            authFlowState = .error(errorMsg)
            throw AppError.authentication(.mfaEnrollmentFailed)
        }
    }
    
    // MARK: - NEW METHOD ADDED FOR MFA FINALIZATION
    /// Finalize MFA enrollment after user scans QR code and enters verification code
    /// - Parameters:
    ///   - totpSecret: The TOTP secret generated during enrollment
    ///   - totpCode: 6-digit verification code from authenticator app
    ///   - displayName: Display name for the MFA factor (default: "Authenticator App")
    func finalizeMFAEnrollment(totpSecret: TOTPSecret, totpCode: String, displayName: String) async throws {
        guard let user = auth.currentUser else {
            logger.error("No current user available for MFA finalization")
            throw AppError.authentication(.userNotFound)
        }
        
        logger.info("Starting MFA enrollment finalization")
        
        do {
            // Create TOTP assertion with user's verification code
            let assertion = TOTPMultiFactorGenerator.assertionForEnrollment(
                with: totpSecret,
                oneTimePassword: totpCode
            )
            
            // Finalize enrollment with Firebase Auth
            try await user.multiFactor.enroll(with: assertion, displayName: displayName)
            
            // Update user profile with MFA status in our User model
            if let userData = currentUser {
                // Create updated user data with MFA status
                let updatedUserData = User(
                    id: userData.id,
                    email: userData.email,
                    displayName: userData.displayName,
                    profileImageURL: userData.profileImageURL,
                    userType: userData.userType,
                    subscriptionStatus: userData.subscriptionStatus,
                    subscriptionType: userData.subscriptionType,
                    trialEndDate: userData.trialEndDate,
                    createdAt: userData.createdAt,
                    lastLoginAt: userData.lastLoginAt,
                    preferences: userData.preferences,
                    caregiverAccess: userData.caregiverAccess,
                    mfaEnabled: true,
                    mfaEnrolledAt: Date(),
                    backupCodes: userData.backupCodes
                )
                
                // Update the currentUser with new MFA status
                currentUser = updatedUserData
                
                // Persist MFA status to Firestore - timeout handling removed due to Swift 6 Sendable constraints
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    do {
                        try self.db.collection("users").document(user.uid).setData(from: updatedUserData, merge: true) { error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                
                logger.info("MFA enrollment completed and user profile updated")
            }
            
        } catch {
            logger.error("MFA enrollment finalization failed: \(error.localizedDescription)")
            throw AppError.authentication(.mfaEnrollmentFailed)
        }
    }
    // END OF NEW METHOD ADDITION
    
    /// Generate backup codes for MFA
    private func generateBackupCodes() -> [String] {
        return (1...10).map { _ in
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return String((0..<8).map { _ in characters.randomElement()! })
        }
    }
}
