import SwiftUI
import OSLog
@preconcurrency import FirebaseAuth

// MARK: - Authentication View

/// Main authentication view that handles user sign-in and integrates with FirebaseManager state machine
/// Serves as the primary entry point for unauthenticated users in the app
/// Updated to use new AuthFlowState pattern from FirebaseManager
struct AuthenticationView: View {
    // MARK: - Properties
    
    /// Firebase manager for handling authentication operations - using @StateObject for proper lifecycle
    // iOS 18/Swift 6: Use @State to properly observe @Observable singleton
    @State private var firebaseManager = FirebaseManager.shared
    
    /// Navigation manager for handling app-wide navigation state - uses @Observable
    @State private var navigationManager = NavigationManager.shared
    
    /// Analytics manager for tracking authentication events
    @State private var analyticsManager = AnalyticsManager.shared
    
    /// Phone authentication presentation state
    @State private var showingPhoneAuth = false
    
    /// MFA (Multi-Factor Authentication) flow state
    @State private var showingMFARequired = false
    @State private var showingMFASetup = false
    @State private var mfaResolverToPresent: MultiFactorResolver?
    
    /// Voice help presentation state
    @State private var showingVoiceHelp = false
    
    /// Loading and transition states for UI animations
    @State private var isTransitioning = false
    @State private var authenticationAttempts = 0
    
    /// Logger for authentication events and debugging
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "Authentication")
    
    /// Environment values for responsive design
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Computed Properties for Alert Presentation
    
    /// Binding for alert presentation based on Firebase auth state
    private var showErrorAlert: Binding<Bool> {
        Binding(
            get: {
                // Show alert if there's an error message in the auth flow state
                firebaseManager.authFlowState.errorMessage != nil
            },
            set: { newValue in
                // If alert is being dismissed and there was an error, clear it
                if !newValue && firebaseManager.authFlowState.errorMessage != nil {
                    self.handleErrorDismissal()
                }
            }
        )
    }
    
    /// Logo size based on dynamic type and device size
    private var logoSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 80
        case .medium, .large:
            return 100
        case .xLarge, .xxLarge:
            return 120
        case .xxxLarge:
            return 140
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 160
        @unknown default:
            return 100
        }
    }
    
    // MARK: - Main View Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient for visual appeal
                backgroundView
                
                // Main authentication content
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.extraLarge) {
                        // App branding and welcome section
                        brandingSection
                        
                        // Authentication options
                        authenticationOptionsSection
                        
                        // Legal and disclaimer section
                        legalSection
                    }
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.top, AppTheme.Spacing.xxLarge)
                    .padding(.bottom, AppTheme.Spacing.large)
                }
                
                // Loading overlay during authentication attempts
                if firebaseManager.authFlowState.isLoadingState || isTransitioning {
                    loadingOverlay
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                self.handleViewAppearance()
            }
            .onChange(of: firebaseManager.authFlowState) { _, newState in
                self.handleFirebaseAuthStateChange(newState)
            }
            .onChange(of: scenePhase) { _, newPhase in
                self.handleScenePhaseChange(newPhase)
            }
            .sheet(isPresented: $showingPhoneAuth) {
                phoneAuthenticationSheet
            }
            .sheet(isPresented: $showingMFARequired) {
                mfaRequiredSheet
            }
            .sheet(isPresented: $showingMFASetup) {
                mfaSetupSheet
            }
            .sheet(isPresented: $showingVoiceHelp) {
                voiceHelpSheet
            }
            .alert(AppStrings.ErrorMessages.authenticationError, isPresented: showErrorAlert) {
                alertButtons
            } message: {
                alertMessage
            }
            .task {
                await initializeAuthenticationView()
            }
            .onChange(of: firebaseManager.authFlowState) { _, newState in
                // Handle MFA Required state presentation
                if case .mfaRequired(let resolver) = newState {
                    self.mfaResolverToPresent = resolver
                    self.showingMFARequired = true
                } else if newState != .profileLoading { // Don't hide during profile loading
                    self.showingMFARequired = false
                    self.mfaResolverToPresent = nil
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Background view with adaptive gradient based on color scheme
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                AppTheme.Colors.background,
                AppTheme.Colors.surface
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    /// App branding section with logo, name, and welcome message
    private var brandingSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // App logo with accessibility support and transition animation
            Image(systemName: AppIcons.health)
                .font(.system(size: logoSize, weight: .light))
                .foregroundStyle(AppTheme.Colors.primary)
                .accessibilityLabel(AppStrings.Accessibility.appLogo)
                .scaleEffect(isTransitioning ? 1.1 : 1.0)
                .animation(AppTheme.Animation.spring, value: isTransitioning)
            
            // App name with dynamic type support
            Text(AppStrings.App.name)
                .font(AppTheme.Typography.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.Colors.onBackground)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            // Welcome message section
            VStack(spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Authentication.welcomeMessage)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
                
                Text(AppStrings.Authentication.welcomeSubtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.onBackground.opacity(AppTheme.Opacity.high))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    /// Authentication options section with Google and Phone sign-in
    private var authenticationOptionsSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Google Sign-In Button
            Button {
                Task {
                    await handleGoogleSignIn()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: AppIcons.googleSignIn)
                        .font(AppTheme.Typography.headline)
                    
                    Text(AppStrings.Authentication.signInWithGoogle)
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)
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
            }
            .disabled(firebaseManager.authFlowState.isLoadingState || isTransitioning)
            .accessibilityLabel(AppStrings.Accessibility.signInButton)
            .accessibilityHint(AppStrings.Accessibility.signInButtonHint)
            .sensoryFeedback(.impact(weight: .medium), trigger: firebaseManager.authFlowState.isLoadingState)
            .scaleEffect(firebaseManager.authFlowState.isLoadingState ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: firebaseManager.authFlowState.isLoadingState)
            
            // Phone Sign-In Button
            Button {
                self.handlePhoneSignInTap()
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: AppIcons.phone)
                        .font(AppTheme.Typography.headline)
                    
                    Text(AppStrings.Authentication.signInWithPhone)
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(AppTheme.Colors.secondary)
                .foregroundStyle(AppTheme.Colors.onSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.primary, lineWidth: 2)
                )
            }
            .disabled(firebaseManager.authFlowState.isLoadingState || isTransitioning)
            .accessibilityLabel(AppStrings.Authentication.signInWithPhone)
            .accessibilityHint("Sign in using phone number verification")
            
            // Voice Help Button
            Button {
                self.showingVoiceHelp = true
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: AppIcons.voice)
                        .font(AppTheme.Typography.subheadline)
                    
                    Text(AppStrings.Voice.quickEntry)
                        .font(AppTheme.Typography.subheadline)
                }
                .foregroundStyle(AppTheme.Colors.primary)
            }
            .disabled(firebaseManager.authFlowState.isLoadingState || isTransitioning)
            .accessibilityLabel(AppStrings.Voice.quickEntry)
            .accessibilityHint(AppStrings.Voice.quickEntrySubtitle)
        }
    }
    
    /// Legal and disclaimer section with privacy policy and terms
    private var legalSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Medical disclaimer
            Text(AppStrings.Legal.medicalDisclaimer)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(AppTheme.Opacity.high))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.medium)
            
            // Legal links
            HStack(spacing: AppTheme.Spacing.medium) {
                Button(AppStrings.Legal.privacyPolicy) {
                    // Handle privacy policy tap
                    logger.info("Privacy policy tapped")
                }
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.primary)
                
                Text(AppStrings.Common.dotSeparator)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.onBackground.opacity(AppTheme.Opacity.medium))
                
                Button(AppStrings.Legal.termsOfService) {
                    // Handle terms of service tap
                    logger.info("Terms of service tapped")
                }
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.primary)
            }
        }
    }
    
    /// Loading overlay with progress indicator and status message
    private var loadingOverlay: some View {
        AppTheme.Colors.onBackground.opacity(AppTheme.Opacity.medium)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: AppTheme.Spacing.medium) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppTheme.Colors.primary)
                    
                    Text(loadingMessage)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.onBackground)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.Spacing.large)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .shadow(
                    color: AppTheme.Shadow.medium.color,
                    radius: AppTheme.Shadow.medium.radius,
                    x: AppTheme.Shadow.medium.x,
                    y: AppTheme.Shadow.medium.y
                )
            )
    }
    
    /// Dynamic loading message based on current auth flow state
    private var loadingMessage: String {
        switch firebaseManager.authFlowState {
        case .initial:
            return AppStrings.Common.loading
        case .signingInGoogle:
            return AppStrings.Authentication.signingIn
        case .phoneVerifyingNumber:
            return "Sending verification code..."
        case .phoneVerifyingCode:
            return "Verifying code..."
        case .profileLoading:
            return "Setting up your profile..."
        default:
            if isTransitioning {
                return "Welcome to MyGuide!"
            }
            return AppStrings.Common.loading
        }
    }
    
    // MARK: - Sheet Views
    
    /// Phone authentication sheet presentation
    private var phoneAuthenticationSheet: some View {
        PhoneAuthView()
    }
    
    /// MFA required sheet presentation
    private var mfaRequiredSheet: some View {
        Group {
            if let resolver = mfaResolverToPresent {
                MFARequiredView(resolver: resolver)
            } else {
                Text(AppStrings.UI.mfaRequired)
                    .font(AppTheme.Typography.headline)
                    .padding()
            }
        }
    }
    
    /// MFA setup sheet presentation
    private var mfaSetupSheet: some View {
        MFASetupView {
                showingMFASetup = false
                logger.info("MFA setup completed successfully")
            }
        }
    
    
    /// Voice help sheet presentation
    private var voiceHelpSheet: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Text(AppStrings.Voice.quickEntry)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.onBackground)
            
            Text(AppStrings.UI.voiceSignInPrompt)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(AppTheme.Opacity.high))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)
            
            Button(AppStrings.Common.ok) {
                showingVoiceHelp = false
            }
            .font(AppTheme.Typography.headline)
            .foregroundStyle(AppTheme.Colors.onPrimary)
            .frame(width: 120, height: AppTheme.Layout.buttonHeight)
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(
            color: AppTheme.Shadow.large.color,
            radius: AppTheme.Shadow.large.radius,
            x: AppTheme.Shadow.large.x,
            y: AppTheme.Shadow.large.y
        )
    }
    
    // MARK: - Alert Components
    
    /// Alert buttons for error handling
    @ViewBuilder
    private var alertButtons: some View {
        Button(AppStrings.Common.ok) {
            handleErrorDismissal()
        }
        
        if authenticationAttempts < Configuration.App.maxAuthenticationAttempts {
            Button(AppStrings.Common.retry) {
                handleRetryAuthentication()
            }
        }
    }
    
    /// Alert message content
    private var alertMessage: some View {
        Group {
            if let errorMessage = firebaseManager.authFlowState.errorMessage {
                Text(errorMessage)
            } else {
                Text(AppStrings.ErrorMessages.genericError)
            }
        }
    }
    
    // MARK: - Action Handlers
    
    /// Handle view appearance and initialization
    private func handleViewAppearance() {
        logger.info("AuthenticationView appeared")
        logger.info("Current authFlowState: \(String(describing: firebaseManager.authFlowState))")
        logger.info("isLoadingState: \(firebaseManager.authFlowState.isLoadingState)")
        logger.info("isTransitioning: \(isTransitioning)")
        
        // Track screen view for analytics
        analyticsManager.trackScreenViewed("authentication")
        
        // Clear any previous error state
        if case .error = firebaseManager.authFlowState {
            firebaseManager.clearError()
        }
        
        // Reset authentication attempts counter
        authenticationAttempts = 0
    }
    
    /// Handle Firebase authentication state changes with proper UI updates
    private func handleFirebaseAuthStateChange(_ newState: AuthFlowState) {
        logger.info("Auth state changed to: \(String(describing: newState))")
        
        switch newState {
        case .signedIn:
            logger.info("Authentication successful, preparing transition")
            // Start transition animation to main app
            withAnimation(AppTheme.Animation.standard) {
                isTransitioning = true
            }
            
            // Track successful authentication
            analyticsManager.trackUserLogin("google_or_phone")
            
        case .error(let message):
            logger.error("Authentication error: \(message)")
            authenticationAttempts += 1
            
            // Track authentication error
            analyticsManager.trackError(
                AppError.authentication(.signInFailed),
                context: "authentication_view"
            )
            
        case .mfaRequired:
            logger.info("MFA required for authentication")
            // MFA presentation is handled by onChange observer
            
        case .profileLoading:
            logger.info("Loading user profile after authentication")
            // Keep loading state active
            
        default:
            break
        }
    }
    
    /// Handle scene phase changes for app lifecycle management
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            logger.debug("App became active during authentication")
            
        case .inactive:
            logger.debug("App became inactive during authentication")
            
        case .background:
            logger.debug("App moved to background during authentication")
            
        @unknown default:
            break
        }
    }
    
    /// Initialize authentication view with proper setup
    private func initializeAuthenticationView() async {
        logger.info("Initializing authentication view")
        
        // Set user properties for analytics
        analyticsManager.setUserProperty(
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            forName: "app_version"
        )
        
        // Check if authentication is already in progress
        if firebaseManager.authFlowState == .initial {
            // Let FirebaseManager handle initial state setup
            logger.debug("Authentication manager in initial state, ready for user action")
        }
    }
    
    /// Handle Google Sign-In button tap
    private func handleGoogleSignIn() async {
        logger.info("User initiated Google Sign-In")
        
        // Track Google sign-in attempt
        analyticsManager.trackFeatureUsed("google_signin_attempt")
        
        do {
            try await firebaseManager.signInWithGoogle()
            logger.info("Google Sign-In completed successfully")
        } catch {
            logger.error("Google Sign-In failed: \(error.localizedDescription)")
            // Error handling is managed by FirebaseManager state
        }
    }
    
    /// Handle phone authentication button tap
    private func handlePhoneSignInTap() {
        logger.info("User requested phone authentication")
        
        // Track phone sign-in attempt
        analyticsManager.trackFeatureUsed("phone_signin_attempt")
        
        // Present phone authentication view
        showingPhoneAuth = true
    }
    
    /// Handle error dismissal and cleanup
    private func handleErrorDismissal() {
        logger.debug("User dismissed authentication error")
        
        // Clear error state in Firebase manager
        firebaseManager.clearError()
        
        // Reset transition state if needed
        if isTransitioning {
            withAnimation(AppTheme.Animation.standard) {
                isTransitioning = false
            }
        }
    }
    
    /// Handle retry authentication after error
    private func handleRetryAuthentication() {
        logger.info("User requested retry authentication")
        
        // Clear error state
        firebaseManager.clearError()
        
        // Track retry attempt
        analyticsManager.trackFeatureUsed("authentication_retry")
        
        // Reset any UI state
        if isTransitioning {
            withAnimation(AppTheme.Animation.standard) {
                isTransitioning = false
            }
        }
    }
}

// MARK: - Supporting Views

/// MFA Required View for handling multi-factor authentication challenges
struct MFARequiredView: View {
    let resolver: MultiFactorResolver
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.large) {
                Image(systemName: AppIcons.security)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(AppTheme.Colors.warning)
                
                Text(AppStrings.Authentication.mfaRequired)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
                
                Text(AppStrings.Authentication.mfaVerificationSubtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.onBackground.opacity(AppTheme.Opacity.high))
                    .multilineTextAlignment(.center)
                
                // TODO: Implement actual MFA verification UI
                Button(AppStrings.Authentication.mfaVerifyButton) {
                    // Handle MFA verification
                }
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.CornerRadius.medium)
                
                Spacer()
            }
            .padding(AppTheme.Spacing.large)
            .navigationTitle("Security Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Authentication View") {
    AuthenticationView()
        .preferredColorScheme(.light)
}

#Preview("Authentication View - Dark Mode") {
    AuthenticationView()
        .preferredColorScheme(.dark)
}

#Preview("Authentication View - Loading") {
    AuthenticationView()
        .onAppear {
            // Simulate loading state for preview
            FirebaseManager.shared.authFlowState = .signingInGoogle
        }
}
