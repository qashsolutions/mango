import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private var db: Firestore!
    private var auth: Auth!
    
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        configureFirebase()
        initializeFirebaseServices()
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            auth?.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Firebase Configuration
    private func configureFirebase() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let _ = NSDictionary(contentsOfFile: path) else {
            errorMessage = AppStrings.ErrorMessages.configurationError
            return
        }
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    private func initializeFirebaseServices() {
        // Initialize Firebase services after configuration
        auth = Auth.auth()
        db = Firestore.firestore()
        
        // Configure Firestore with updated cache settings
        let settings = FirestoreSettings()
        if #available(iOS 15.0, *) {
            settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        } else {
            settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        }
        db.settings = settings
    }
    
    // MARK: - Authentication State Management
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self = self else { return }
                self.isAuthenticated = firebaseUser != nil
                if let firebaseUser = firebaseUser {
                    await self.loadUserProfile(uid: firebaseUser.uid)
                } else {
                    self.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Phone Authentication
    func signInWithPhone(_ phoneNumber: String) async throws -> String {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            return verificationID
        } catch {
            errorMessage = AppStrings.ErrorMessages.phoneVerificationError
            throw AppError.authentication(.phoneVerificationFailed)
        }
    }
    
    func verifyPhoneCode(verificationID: String, verificationCode: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
            
            do {
                let authResult = try await auth.signIn(with: credential)
                
                // Create or update user profile
                await createOrUpdateUserProfile(from: authResult.user)
                
            } catch let error as NSError {
                // Check if MFA is required
                if error.code == AuthErrorCode.secondFactorRequired.rawValue,
                   let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as? MultiFactorResolver {
                    throw AppError.authentication(.mfaRequired)
                }
                throw error
            }
            
        } catch let appError as AppError {
            throw appError
        } catch {
            errorMessage = AppStrings.ErrorMessages.phoneCodeVerificationError
            throw AppError.authentication(.phoneCodeVerificationFailed)
        }
    }
    
    // MARK: - Multi-Factor Authentication
    func enrollMFA() async throws -> (totpSecret: TOTPSecret, qrCodeURL: String, backupCodes: [String]) {
        guard let user = auth.currentUser else {
            throw AppError.authentication(.userNotFound)
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Get multi-factor session
            let multiFactorSession = try await user.multiFactor.session()
            
            // Generate TOTP secret
            let totpSecret = try await TOTPMultiFactorGenerator.generateSecret(with: multiFactorSession)
            
            // Generate QR code URL for authenticator apps
            let qrCodeURL = totpSecret.generateQRCodeURL(
                withAccountName: user.email ?? "user",
                issuer: AppStrings.App.name
            )
            
            // Generate backup codes
            let backupCodes = generateBackupCodes()
            
            return (totpSecret: totpSecret, qrCodeURL: qrCodeURL, backupCodes: backupCodes)
            
        } catch {
            errorMessage = AppStrings.ErrorMessages.mfaEnrollmentError
            throw AppError.authentication(.mfaEnrollmentFailed)
        }
    }
    
    func finalizeMFAEnrollment(totpSecret: TOTPSecret, totpCode: String, displayName: String = "Authenticator App") async throws {
        guard let user = auth.currentUser else {
            throw AppError.authentication(.userNotFound)
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Create TOTP assertion with user's code
            let assertion = TOTPMultiFactorGenerator.assertionForEnrollment(
                with: totpSecret,
                oneTimePassword: totpCode
            )
            
            // Finalize enrollment
            try await user.multiFactor.enroll(with: assertion, displayName: displayName)
            
            // Update user profile with MFA status
            if var userData = currentUser {
                userData.mfaEnabled = true
                userData.mfaEnrolledAt = Date()
                try await updateUserProfile(userData)
            }
            
        } catch {
            errorMessage = AppStrings.ErrorMessages.mfaEnrollmentError
            throw AppError.authentication(.mfaEnrollmentFailed)
        }
    }
    
    func verifyMFACode(_ totpCode: String, resolver: MultiFactorResolver) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Get the TOTP factor from enrolled factors
            guard let totpFactor = resolver.hints.first(where: { $0.factorID == TOTPMultiFactorID }) else {
                throw AppError.authentication(.mfaVerificationFailed)
            }
            
            // Create assertion with verification code
            let assertion = TOTPMultiFactorGenerator.assertionForSignIn(
                withEnrollmentID: totpFactor.uid,
                oneTimePassword: totpCode
            )
            
            // Complete sign-in with MFA
            let authResult = try await resolver.resolveSignIn(with: assertion)
            
            // Load user profile
            await loadUserProfile(uid: authResult.user.uid)
            
        } catch {
            errorMessage = AppStrings.ErrorMessages.mfaVerificationError
            throw AppError.authentication(.mfaVerificationFailed)
        }
    }
    
    private func generateBackupCodes() -> [String] {
        // Generate 10 random 8-character backup codes
        return (1...10).map { _ in
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return String((0..<8).map { _ in characters.randomElement()! })
        }
    }
    
    private func updateUserProfile(_ user: User) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AppError.authentication(.userNotFound)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try db.collection("users").document(userId).setData(from: user, merge: true) { error in
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
        currentUser = user
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async throws {
        guard let presentingViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            throw AppError.authentication(.signInFailed)
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AppError.authentication(.configurationError)
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.authentication(.invalidCredentials)
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            do {
                let authResult = try await auth.signIn(with: credential)
                
                // Create or update user profile
                await createOrUpdateUserProfile(from: authResult.user)
                
            } catch let error as NSError {
                // Check if MFA is required
                if error.code == AuthErrorCode.secondFactorRequired.rawValue,
                   let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as? MultiFactorResolver {
                    throw AppError.authentication(.mfaRequired)
                }
                throw error
            }
            
        } catch let appError as AppError {
            throw appError
        } catch {
            errorMessage = AppStrings.ErrorMessages.authenticationError
            throw AppError.authentication(.signInFailed)
        }
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        do {
            GIDSignIn.sharedInstance.signOut()
            try auth.signOut()
            currentUser = nil
            errorMessage = nil
        } catch {
            errorMessage = AppStrings.ErrorMessages.signOutError
            throw AppError.authentication(.signOutFailed)
        }
    }
    
    // MARK: - User Profile Management
    private func createOrUpdateUserProfile(from firebaseUser: FirebaseAuth.User) async {
        let userData = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "",
            profileImageURL: firebaseUser.photoURL?.absoluteString,
            subscriptionStatus: .trial,
            subscriptionType: nil,
            trialEndDate: Calendar.current.date(byAdding: .day, value: Configuration.App.trialDurationDays, to: Date()),
            createdAt: Date(),
            lastLoginAt: Date(),
            preferences: UserPreferences(),
            caregiverAccess: User.CaregiverAccess(enabled: false, caregivers: []),
            mfaEnabled: false,
            mfaEnrolledAt: nil,
            backupCodes: nil
        )
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try db.collection("users").document(firebaseUser.uid).setData(from: userData, merge: true) { error in
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
        } catch {
            errorMessage = AppStrings.ErrorMessages.dataError
        }
    }
    
    private func loadUserProfile(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                currentUser = try document.data(as: User.self)
            } else {
                // Create new user profile if doesn't exist
                if let firebaseUser = auth.currentUser {
                    await createOrUpdateUserProfile(from: firebaseUser)
                }
            }
        } catch {
            errorMessage = AppStrings.ErrorMessages.dataError
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}
