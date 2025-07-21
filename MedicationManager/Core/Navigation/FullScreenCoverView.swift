import SwiftUI
import OSLog
import FirebaseAuth

/// Full screen cover view that handles different full screen presentations based on destination type
/// Used for authentication flows, onboarding, and caregiver setup processes
struct FullScreenCoverView: View {
    /// The destination type that determines which view to present
    let destination: FullScreenDestination
    /// View factory for creating views without direct Feature dependencies
    let viewFactory: ViewFactoryProtocol
    
    /// Logger for tracking view presentations and user interactions
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "FullScreenCover")
    
    /// Environment object for managing navigation state and dismissal
    @Environment(\.dismiss) private var dismiss
    
    /// Firebase manager for handling authentication state
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let firebaseManager = FirebaseManager.shared
    
    /// State for tracking if MFA is required during authentication
    @State private var showingMFARequired = false
    
    /// MFA resolver for handling multi-factor authentication flow
    @State private var mfaResolver: MultiFactorResolver?
    
    /// State for managing MFA setup flow
    @State private var showingMFASetup = false
    
    /// State for tracking loading states during transitions
    @State private var isLoading = false
    
    /// State for managing error presentation
    @State private var showingError = false
    
    /// Current error message to display to user
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Main content based on destination type
            configuredDestinationContent
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            // Loading overlay for transitions
            if isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            handleViewAppearance()
        }
        .onChange(of: firebaseManager.isAuthenticated) { _, isAuthenticated in
            handleAuthenticationStateChange(isAuthenticated)
        }
        .alert(AppStrings.ErrorMessages.genericError, isPresented: $showingError) {
            Button(AppStrings.Common.ok) {
                handleErrorDismissal()
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingMFARequired) {
            handleMFARequired()
        }
        .sheet(isPresented: $showingMFASetup) {
            handleMFASetup()
        }
    }
    
    // MARK: - View Components
    
    /// Returns the appropriate view content based on the destination type
    @ViewBuilder
    private var destinationContent: some View {
        viewFactory.createFullScreenView(for: destination)
    }
    
    /// Configured view content with authentication event handling
    private var configuredDestinationContent: some View {
        Group {
            if case .authentication = destination {
                viewFactory.createFullScreenView(for: destination)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MFARequired"))) { notification in
                        handleMFARequiredNotification(notification)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AuthenticationError"))) { notification in
                        handleAuthenticationErrorNotification(notification)
                    }
            } else {
                viewFactory.createFullScreenView(for: destination)
            }
        }
    }
    
    /// Loading overlay shown during state transitions
    private var loadingOverlay: some View {
        ZStack {
            AppTheme.Colors.background.opacity(AppTheme.Opacity.high)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.medium) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                    .scaleEffect(1.2)
                
                Text(AppStrings.Common.loading)
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
    
    // MARK: - Event Handlers
    
    /// Handles view appearance with logging and analytics
    private func handleViewAppearance() {
        logger.info("FullScreenCoverView appeared with destination: \(destination.analyticsName)")
        
        // Track analytics for screen presentation
        AnalyticsManager.shared.trackScreenViewed(destination.analyticsName)
        
        // Log destination-specific information
        switch destination {
        case .authentication:
            logger.debug("Presenting authentication flow")
        case .onboarding:
            logger.debug("Presenting user onboarding flow")
        case .caregiverOnboarding:
            logger.debug("Presenting caregiver onboarding flow")
        }
    }
    
    /// Handles authentication state changes with proper navigation
    /// - Parameter isAuthenticated: Current authentication state
    private func handleAuthenticationStateChange(_ isAuthenticated: Bool) {
        logger.info("Authentication state changed: \(isAuthenticated)")
        
        if isAuthenticated {
            switch destination {
            case .authentication:
                handleSuccessfulAuthentication()
            case .onboarding, .caregiverOnboarding:
                // User authenticated during onboarding, continue with flow
                logger.debug("User authenticated during onboarding flow")
            }
        } else {
            // Handle sign-out or authentication failure
            logger.debug("User not authenticated, maintaining current flow")
        }
    }
    
    /// Handles successful authentication with navigation and cleanup
    private func handleSuccessfulAuthentication() {
        logger.info("Authentication successful, dismissing cover view")
        
        // Track successful authentication
        AnalyticsManager.shared.trackUserLogin("successful_login")
        
        // Dismiss with animation
        withAnimation(AppTheme.Animation.standard) {
            isLoading = false
            dismiss()
        }
        
        // Notify navigation manager of successful authentication
        NavigationManager.shared.handleAuthenticationSuccess()
    }
    
    /// Handles MFA required notification from authentication flow
    /// - Parameter notification: Notification containing MFA resolver
    private func handleMFARequiredNotification(_ notification: Notification) {
        logger.info("MFA required for authentication")
        
        guard let resolver = notification.userInfo?["resolver"] as? MultiFactorResolver else {
            logger.error("MFA required but no resolver provided")
            showError(AppStrings.ErrorMessages.authenticationError)
            return
        }
        
        mfaResolver = resolver
        showingMFARequired = true
        
        // Track MFA requirement
        AnalyticsManager.shared.trackFeatureUsed("mfa_required")
    }
    
    /// Handles authentication error notifications
    /// - Parameter notification: Notification containing error information
    private func handleAuthenticationErrorNotification(_ notification: Notification) {
        logger.warning("Authentication error received")
        
        if let error = notification.userInfo?["error"] as? AppError {
            showError(error.localizedDescription)
            AnalyticsManager.shared.trackError(error, context: "authentication_flow")
        } else {
            showError(AppStrings.ErrorMessages.authenticationError)
        }
    }
    
    /// Handles onboarding completion with proper navigation
    private func handleOnboardingCompletion() {
        logger.info("User completed onboarding flow")
        
        isLoading = true
        
        // Track onboarding completion
        AnalyticsManager.shared.trackFeatureUsed("onboarding_completed")
        
        // Simulate onboarding completion delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(AppTheme.Animation.standard) {
                isLoading = false
                dismiss()
            }
        }
    }
    
    /// Handles caregiver onboarding completion
    private func handleCaregiverOnboardingCompletion() {
        logger.info("Caregiver completed onboarding flow")
        
        isLoading = true
        
        // Track caregiver onboarding completion
        AnalyticsManager.shared.trackFeatureUsed("caregiver_onboarding_completed")
        
        // Simulate caregiver setup completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(AppTheme.Animation.standard) {
                isLoading = false
                dismiss()
            }
        }
    }
    
    /// Handles error dismissal with cleanup
    private func handleErrorDismissal() {
        logger.debug("Error alert dismissed by user")
        showingError = false
        errorMessage = ""
    }
    
    /// Returns MFA required view for sheet presentation
    @ViewBuilder
    private func handleMFARequired() -> some View {
        if let resolver = mfaResolver {
            MFASignInView(resolver: resolver) {
                logger.info("MFA verification completed successfully")
                showingMFARequired = false
                mfaResolver = nil
                
                // Track successful MFA verification
                AnalyticsManager.shared.trackFeatureUsed("mfa_verified")
            }
        } else {
            // Fallback view if resolver is missing
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.ErrorMessages.genericError)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                
                Button(AppStrings.Common.ok) {
                    showingMFARequired = false
                }
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.onPrimary)
                .frame(height: AppTheme.Layout.buttonHeight)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .padding(AppTheme.Spacing.large)
        }
    }
    
    /// Returns MFA setup view for sheet presentation
    @ViewBuilder
    private func handleMFASetup() -> some View {
        MFASetupView {
            logger.info("MFA setup completed successfully")
            showingMFASetup = false
            
            // Track MFA setup completion
            AnalyticsManager.shared.trackFeatureUsed("mfa_setup_completed")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Shows error message to user with logging
    /// - Parameter message: Error message to display
    private func showError(_ message: String) {
        logger.error("Showing error to user: \(message)")
        errorMessage = message
        showingError = true
        isLoading = false
    }
}

// MARK: - Preview Provider
#Preview("Authentication") {
    FullScreenCoverView(destination: .authentication, viewFactory: AppViewFactory())
        .preferredColorScheme(.light)
}

#Preview("Onboarding") {
    FullScreenCoverView(destination: .onboarding, viewFactory: AppViewFactory())
        .preferredColorScheme(.light)
}

#Preview("Caregiver Onboarding") {
    FullScreenCoverView(destination: .caregiverOnboarding, viewFactory: AppViewFactory())
        .preferredColorScheme(.dark)
}
