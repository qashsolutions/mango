import SwiftUI
import OSLog
@preconcurrency import FirebaseAuth

// MARK: - Identifiable Wrapper for MultiFactorResolver

struct IdentifiableMultiFactorResolver: Identifiable {
    let id = UUID()
    let resolver: MultiFactorResolver
}

// MARK: - Login View

struct LoginView: View {
    // --- Properties MUST be inside the struct ---
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let firebaseManager = FirebaseManager.shared
    @State private var showPhoneAuth = false
    @State private var identifiableMfaResolverToPresent: IdentifiableMultiFactorResolver?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.dismiss) private var dismiss
    
    // --- Computed property for alert binding MUST be inside the struct ---
    private var showErrorAlert: Binding<Bool> {
        Binding(
            get: { firebaseManager.authFlowState.errorMessage != nil },
            set: { _ in
                // When the alert is dismissed (set to false), clear the error in the manager
                if firebaseManager.authFlowState.errorMessage != nil {
                    firebaseManager.clearError()
                }
            }
        )
    }
    
    // --- body computed property MUST be inside the struct ---
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.extraLarge) {
                // Call the computed properties defined later in this struct
                brandingSection
                welcomeSection
                signInSection
                disclaimerSection
                
                Spacer()
            }
            .padding(AppTheme.Spacing.large)
            .background(AppTheme.Colors.background)
            .overlay {
                // Access the computed property from the struct instance (no self. needed here)
                if firebaseManager.authFlowState.isLoadingState {
                    loadingOverlay // Call the computed property
                }
            }
            // Bind the alert's isPresented to the computed showErrorAlert Binding
            .alert(AppStrings.ErrorMessages.genericError, isPresented: showErrorAlert) {
                Button(AppStrings.Common.ok) {
                    // Action handled by Binding setter
                }
            } message: {
                // Access the computed property from the struct instance (no self. needed here)
                if let errorMessage = firebaseManager.authFlowState.errorMessage {
                    Text(errorMessage)
                }
            }
            // Use .onChange observer here, reacting to state changes
            .onChange(of: firebaseManager.authFlowState) { _, newState in
                handleFirebaseAuthStateChange(newState)
                if case .signedIn = newState {
                    dismiss()
                }
                if case .mfaRequired(let resolver) = newState {
                    identifiableMfaResolverToPresent = IdentifiableMultiFactorResolver(resolver: resolver)
                }
            }
            .sheet(item: $identifiableMfaResolverToPresent) { identifiableResolver in
                MFASignInView(resolver: identifiableResolver.resolver) {
                    // MFA completed successfully, clear the resolver
                    identifiableMfaResolverToPresent = nil
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var brandingSection: some View {
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: AppIcons.health)
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .accessibilityLabel(AppStrings.Accessibility.appLogo)
                
                Text(AppStrings.App.name)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppTheme.Spacing.xxLarge)
    }
    
    private var welcomeSection: some View {
            VStack(spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Authentication.welcomeMessage)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
                
                Text(AppStrings.Authentication.welcomeSubtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
    }
    
    private var signInSection: some View {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Google Sign-In Button
                Button { // Action closure starts here
                    // Note: No [weak self] needed here because LoginView is a struct (value type).
                    // SwiftUI views are designed as structs that get recreated frequently, so there's
                    // no risk of retain cycles like with reference types (classes).
                    Task { // Task closure starts here
                        // --- Access the method of the LoginView instance ---
                        await signInWithGoogle() // Call the LoginView's method (defined below)
                    } // Task closure ends here
                } label: { // Label closure starts here
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: AppIcons.googleSignIn)
                            .font(AppTheme.Typography.headline)
                        
                        Text(AppStrings.Authentication.signInWithGoogle)
                            .font(AppTheme.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Layout.buttonHeight)
                    .background(AppTheme.Colors.primary)
                    .foregroundStyle(AppTheme.Colors.onPrimary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .shadow(
                        color: AppTheme.Shadow.medium.color,
                        radius: AppTheme.Shadow.medium.radius,
                        x: AppTheme.Shadow.medium.x,
                        y: AppTheme.Shadow.medium.y
                    )
                } // Label closure ends here
                // --- Access firebaseManager property directly ---
                .disabled(firebaseManager.authFlowState.isLoadingState)
                
                .accessibilityLabel(AppStrings.Accessibility.signInButton)
                .accessibilityHint(AppStrings.Accessibility.signInButtonHint)
                // --- Access firebaseManager property directly ---
                .sensoryFeedback(.impact(weight: .medium), trigger: firebaseManager.authFlowState.isLoadingState)
                
                // Phone Sign-In Button
                Button { // Button action closure starts here
                    // --- KEEP self. here ---
                    // Accessing the showPhoneAuth property of the LoginView instance within the closure
                    self.showPhoneAuth = true
                } label: { // Label closure starts here
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: AppIcons.phone)
                            .font(AppTheme.Typography.headline)
                        
                        Text(AppStrings.Authentication.signInWithPhone)
                            .font(AppTheme.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Layout.buttonHeight)
                    .background(AppTheme.Colors.surface)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(AppTheme.Colors.primary, lineWidth: 2)
                    )
                } // Label closure ends here
                // --- Access firebaseManager property directly ---
                .disabled(firebaseManager.authFlowState.isLoadingState)
            } // VStack ends here
            // The .sheet modifier is attached to the root VStack of this section
            // --- KEEP self.$ here ---
            // Accessing the binding for the showPhoneAuth property of the LoginView instance within the modifier
            .sheet(isPresented: self.$showPhoneAuth) { // Closure for sheet content starts here
                PhoneAuthView()
                // Consider passing the environment object or necessary data down if PhoneAuthView needs it
                // .environmentObject(self.firebaseManager) // Accessing self.firebaseManager here is correct
            } // Closure for sheet content ends here
    }
    
    private var disclaimerSection: some View {
            VStack(spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Legal.medicalDisclaimer)
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: AppTheme.Spacing.small) {
                    Button(AppStrings.Legal.privacyPolicy) {
                        // Handle privacy policy tap - If using self. properties, keep self.
                    }
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.primary)
                    
                    // --- FIX: Use string constant for the dot separator ---
                    Text(AppStrings.Common.dotSeparator) // Use the defined constant
                        .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.6))
                    
                    Button(AppStrings.Legal.termsOfService) {
                        // Handle terms of service tap - If using self. properties, keep self.
                    }
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
    }
    
    private var loadingOverlay: some View {
            ZStack {
                AppTheme.Colors.background.opacity(0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.Spacing.medium) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                        .scaleEffect(1.2)
                    
                    Text(AppStrings.Authentication.signingIn) // You might want this text to update based on authFlowState?
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.onBackground)
                }
                .padding(AppTheme.Spacing.large)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .shadow(
                    color: AppTheme.Shadow.large.color,
                    radius: AppTheme.Shadow.large.radius,
                    x: AppTheme.Shadow.large.x,
                    y: AppTheme.Shadow.large.y
                )
            }
    }
    
    // MARK: - Actions
    
    private func signInWithGoogle() async {
        // Inside this method, accessing firebaseManager does NOT need self.
        // because methods automatically get 'self' context.
        print("🔵 [LOGIN] signInWithGoogle() called")
        print("🔵 [LOGIN] authFlowState: \(firebaseManager.authFlowState)")
        
        do {
            try await firebaseManager.signInWithGoogle() // Accessing manager property directly is correct here
        } catch {
            print("🔵 [LOGIN] signInWithGoogle failed with error: \(error)")
            // Error handling is managed by FirebaseManager
            // The FirebaseManager sets its authFlowState to .error on failure,
            // which the LoginView body observes to show the alert.
        }
    }
    
    private func handleFirebaseAuthStateChange(_ newState: AuthFlowState) {
        let logger = Logger(subsystem: Configuration.App.bundleId, category: "LoginView")
        logger.info("Auth state changed to: \(String(describing: newState))")
        
        switch newState {
        case .signedIn:
            logger.info("Authentication successful")
            // Dismissal is handled in the onChange modifier
            
        case .error(let message):
            logger.error("Authentication error: \(message)")
            // Error display is handled by the alert modifier
            
        case .mfaRequired:
            logger.info("MFA required for authentication")
            // MFA presentation is handled in the onChange modifier
            
        default:
            break
        }
    }
}
