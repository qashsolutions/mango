// CRITICAL: DO NOT MODIFY THIS FILE WITHOUT EXPLICIT PERMISSION
// ================================================================
// This file has been thoroughly tested and debugged.
// Any modifications may break phone authentication functionality.
// Last verified working: June 12, 2025
// If changes are needed, get explicit approval first.
// ================================================================

import SwiftUI
import OSLog

// MARK: - Phone Authentication View

/// Complete phone authentication interface using state machine pattern
/// Handles the full flow: phone input → SMS verification → authentication completion
struct PhoneAuthView: View {
    // MARK: - Properties
    
    /// Firebase manager instance - use @StateObject for proper SwiftUI lifecycle management
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let firebaseManager = FirebaseManager.shared
    
    /// Local UI state for form inputs
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    
    /// Environment values
    @Environment(\.dismiss) private var dismiss
    
    /// Logger for debugging and error tracking
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "PhoneAuthView")
    
    // MARK: - Main View Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                mainContentView
                
                // Loading overlay when processing
                if firebaseManager.authFlowState.isLoadingState {
                    LoadingOverlayView()
                }
            }
        }
        .onAppear {
            handleViewAppear()
        }
        .onChange(of: firebaseManager.authFlowState) { _, newState in
            handleAuthStateChange(newState)
        }
    }
    
    // MARK: - Main Content View
    
    /// Primary content layout
    private var mainContentView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Header with icon and instructions
            headerSection
            
            // Dynamic input section based on flow state
            inputSection
            
            // Dynamic action buttons based on flow state
            actionButtonsSection
            
            Spacer()
            
            // Error display at bottom
            errorSection
            
            // MFA notification if required
            mfaSection
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.background)
        .navigationTitle(AppStrings.Authentication.signInWithPhone)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                cancelButton
            }
        }
    }
    
    // MARK: - Header Section
    
    /// Header with phone icon and contextual instructions
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Phone icon
            Image(systemName: AppIcons.phone)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(AppTheme.Colors.primary)
                .accessibilityLabel(AppStrings.Accessibility.appLogo)
            
            // Title
            Text(AppStrings.Authentication.phoneVerificationTitle)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.onBackground)
                .multilineTextAlignment(.center)
            
            // Dynamic subtitle based on current flow state
            Text(dynamicSubtitleText)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.8))
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: dynamicSubtitleText)
        }
    }
    
    // MARK: - Input Section
    
    /// Dynamic input fields based on current authentication flow state
    private var inputSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            switch firebaseManager.currentPhoneAuthFlow {
            case .initial, .inputPhoneNumber:
                phoneNumberInputView
                
            case .inputVerificationCode:
                verificationCodeInputView
                
            case .verifyingPhoneNumber, .verifyingVerificationCode, .completed:
                // Show processing message instead of input fields
                processingMessageView
                
            case .error:
                // Input fields remain visible in error state for retry
                if phoneNumber.isEmpty {
                    phoneNumberInputView
                } else {
                    verificationCodeInputView
                }
            }
        }
    }
    
    /// Phone number input field with validation
    private var phoneNumberInputView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Field label
            Text(AppStrings.Authentication.phoneNumber)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.onBackground)
            
            // Phone number input field
            #if DEBUG
            TextField("6505554567", text: $phoneNumber)  // Test number in DEBUG
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .disableAutocorrection(true)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(phoneNumberBorderColor, lineWidth: 1)
                )
                .disabled(firebaseManager.authFlowState.isLoadingState)
                .accessibilityLabel(AppStrings.Authentication.phoneNumber)
                .accessibilityHint("Enter your 10-digit phone number")
            #else
            TextField("", text: $phoneNumber)  // No placeholder in production
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .disableAutocorrection(true)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(phoneNumberBorderColor, lineWidth: 1)
                )
                .disabled(firebaseManager.authFlowState.isLoadingState)
                .accessibilityLabel(AppStrings.Authentication.phoneNumber)
                .accessibilityHint("Enter your 10-digit phone number")
            #endif
            
            // Helper text with format example
            #if DEBUG
            Text("Enter 10 digits only (example: 6505554567)")
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.6))
            #else
            Text("Enter your 10-digit phone number")
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.6))
            #endif
        }
    }
    
    /// SMS verification code input field
    private var verificationCodeInputView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Field label
            Text(AppStrings.Authentication.verificationCode)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.onBackground)
            
            // Verification code input field
            TextField("123456", text: $verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode) // Enable SMS autofill
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(verificationCodeBorderColor, lineWidth: 1)
                )
                .disabled(firebaseManager.authFlowState.isLoadingState)
                .accessibilityLabel(AppStrings.Authentication.verificationCode)
                .accessibilityHint("Enter the 6-digit code from SMS")
            
            // Helper text
            Text(AppStrings.Authentication.verificationCodeHint)
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.6))
            
            // Show formatted phone number for verification
            if !phoneNumber.isEmpty {
                Text("Code sent to: \(formatPhoneNumberForDisplay(phoneNumber))")
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .padding(.top, AppTheme.Spacing.extraSmall)
            }
        }
    }
    
    /// Processing message view shown during operations
    private var processingMessageView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppTheme.Colors.primary)
            
            Text(processingMessage)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.onBackground)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Action Buttons Section
    
    /// Dynamic action buttons based on current flow state
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            switch firebaseManager.currentPhoneAuthFlow {
            case .initial, .inputPhoneNumber:
                sendCodeButton
                
            case .inputVerificationCode:
                VStack(spacing: AppTheme.Spacing.small) {
                    verifyCodeButton
                    resendCodeButton
                }
                
            case .verifyingPhoneNumber, .verifyingVerificationCode, .completed:
                // No buttons shown during processing
                EmptyView()
                
            case .error:
                // Show retry button based on context
                if phoneNumber.isEmpty {
                    sendCodeButton
                } else {
                    VStack(spacing: AppTheme.Spacing.small) {
                        verifyCodeButton
                        resendCodeButton
                    }
                }
            }
        }
    }
    
    /// Send verification code button
    private var sendCodeButton: some View {
        Button {
            Task {
                await handleSendCode()
            }
        } label: {
            Text(AppStrings.Authentication.sendCode)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(sendCodeButtonColor)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .disabled(!isPhoneNumberValid || firebaseManager.authFlowState.isLoadingState)
        .accessibilityLabel(AppStrings.Authentication.sendCode)
        .accessibilityHint("Send verification code to your phone")
    }
    
    /// Verify SMS code button
    private var verifyCodeButton: some View {
        Button {
            Task {
                await handleVerifyCode()
            }
        } label: {
            Text(AppStrings.Authentication.verifyCode)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(verifyCodeButtonColor)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .disabled(!isVerificationCodeValid || firebaseManager.authFlowState.isLoadingState)
        .accessibilityLabel(AppStrings.Authentication.verifyCode)
        .accessibilityHint("Verify the SMS code")
    }
    
    /// Resend verification code button
    private var resendCodeButton: some View {
        Button {
            Task {
                await handleResendCode()
            }
        } label: {
            Text(AppStrings.Authentication.resendCode)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(resendButtonColor)
        }
        .disabled(firebaseManager.authFlowState.isLoadingState)
        .accessibilityLabel(AppStrings.Authentication.resendCode)
        .accessibilityHint("Request a new verification code")
    }
    
    /// Cancel navigation button
    private var cancelButton: some View {
        Button(AppStrings.Common.cancel) {
            logger.info("User cancelled phone authentication")
            firebaseManager.resetPhoneAuthFlow()
            dismiss()
        }
        .disabled(firebaseManager.authFlowState.isLoadingState)
    }
    
    // MARK: - Error Section
    
    /// Error message display with retry option
    private var errorSection: some View {
        Group {
            if let errorMessage = firebaseManager.authFlowState.errorMessage {
                ErrorDisplayView(
                    message: errorMessage,
                    onRetry: {
                        firebaseManager.clearError()
                    }
                )
                .padding(.top, AppTheme.Spacing.medium)
            }
        }
    }
    
    // MARK: - MFA Section
    
    /// Multi-factor authentication notification
    private var mfaSection: some View {
        Group {
            if firebaseManager.authFlowState.mfaResolver != nil {
                VStack(spacing: AppTheme.Spacing.small) {
                    Text("Multi-Factor Authentication Required")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.warning)
                    
                    Text("Please complete the second factor authentication.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.onBackground)
                        .multilineTextAlignment(.center)
                    
                    // MFA implementation planned for Phase 4
                    Button("Continue with MFA") {
                        // Navigate to MFA view when implemented
                        logger.info("MFA flow requested - to be implemented in Phase 4")
                    }
                    .foregroundStyle(AppTheme.Colors.primary)
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.warning.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Validate phone number format (10 digits)
    private var isPhoneNumberValid: Bool {
        let digitsOnly = phoneNumber.filter { $0.isNumber }
        return digitsOnly.count == 10
    }
    
    /// Validate verification code format (6 digits)
    private var isVerificationCodeValid: Bool {
        let digitsOnly = verificationCode.filter { $0.isNumber }
        return digitsOnly.count == 6
    }
    
    /// Dynamic subtitle text based on flow state
    private var dynamicSubtitleText: String {
        switch firebaseManager.currentPhoneAuthFlow {
        case .initial, .inputPhoneNumber:
            return AppStrings.Authentication.phoneVerificationSubtitle
        case .verifyingPhoneNumber:
            return "Sending verification code..."
        case .inputVerificationCode:
            return "Enter the 6-digit code sent to your phone"
        case .verifyingVerificationCode:
            return "Verifying your code..."
        case .completed:
            return "Verification complete!"
        case .error:
            return "Please try again"
        }
    }
    
    /// Processing message for loading states
    private var processingMessage: String {
        switch firebaseManager.currentPhoneAuthFlow {
        case .verifyingPhoneNumber:
            return "Sending verification code to \(formatPhoneNumberForDisplay(phoneNumber))"
        case .verifyingVerificationCode:
            return "Verifying your code..."
        default:
            return "Processing..."
        }
    }
    
    /// Phone number input border color based on validation
    private var phoneNumberBorderColor: Color {
        if phoneNumber.isEmpty {
            return AppTheme.Colors.secondary.opacity(0.3)
        } else if isPhoneNumberValid {
            return AppTheme.Colors.success
        } else {
            return AppTheme.Colors.warning
        }
    }
    
    /// Verification code input border color based on validation
    private var verificationCodeBorderColor: Color {
        if verificationCode.isEmpty {
            return AppTheme.Colors.secondary.opacity(0.3)
        } else if isVerificationCodeValid {
            return AppTheme.Colors.success
        } else {
            return AppTheme.Colors.warning
        }
    }
    
    /// Send code button background color
    private var sendCodeButtonColor: Color {
        isPhoneNumberValid ? AppTheme.Colors.primary : AppTheme.Colors.secondary.opacity(0.5)
    }
    
    /// Verify code button background color
    private var verifyCodeButtonColor: Color {
        isVerificationCodeValid ? AppTheme.Colors.primary : AppTheme.Colors.secondary.opacity(0.5)
    }
    
    /// Resend button text color
    private var resendButtonColor: Color {
        firebaseManager.authFlowState.isLoadingState ?
        AppTheme.Colors.primary.opacity(0.5) : AppTheme.Colors.primary
    }
    
    // MARK: - Action Handlers
    
    /// Handle view appearance
    private func handleViewAppear() {
        logger.info("PhoneAuthView appeared")
        
        // Clear any previous error state
        if case .error = firebaseManager.authFlowState {
            firebaseManager.clearError()
        }
        
        // Set initial flow state if needed
        if firebaseManager.currentPhoneAuthFlow == .initial {
            firebaseManager.currentPhoneAuthFlow = .inputPhoneNumber
        }
    }
    
    /// Handle authentication state changes
    // This function is now likely called FROM the authStateListener in FirebaseManager,
    // which is already on the @MainActor. So keeping this function definition fine.
    private func handleAuthStateChange(_ newState: AuthFlowState) {
        // --- FIX IS HERE ---
        // Explicitly convert newState to a String for the logger
        logger.info("Auth state changed to: \(String(describing: newState))")
        
        // Note: The 'dismiss()' and UI-related logic from the original snippet
        // should be moved out of the FirebaseManager and handled in the View
        // observing the authFlowState property. The Manager's job is to manage state,
        // the View's job is to react to state and update the UI (including dismissal).
        // Assuming this function is now part of the View reacting to state changes.
        
        switch newState {
        case .signedIn:
            logger.info("Authentication successful, dismissing view")
            // Dismissal logic belongs in the View observing state.
            // The View should watch for firebaseManager.authFlowState == .signedIn
            // and call dismiss() itself.
            // dismiss() // This line should likely be in your View, not the Manager.
            break // Use break here if dismissal is handled by the View
            
        case .error(let message):
            logger.error("Authentication error: \(message)")
            // UI (View) should observe authFlowState.errorMessage and display it.
            
        case .mfaRequired: // Extract resolver here if needed in this function
            logger.info("MFA required for authentication")
            // UI (View) should observe authFlowState.mfaResolver and present MFA challenge view.
            
        default:
            // Handle other states if needed, or do nothing
            break
        }
    }

    
    /// Handle send verification code action
    private func handleSendCode() async {
        logger.info("User requested to send verification code")
        
        guard isPhoneNumberValid else {
            logger.warning("Invalid phone number format")
            return
        }
        
        do {
            _ = try await firebaseManager.signInWithPhone(phoneNumber)
            logger.info("Verification code sent successfully")
        } catch {
            logger.error("Failed to send verification code: \(error.localizedDescription)")
            // Error handling is managed by FirebaseManager
        }
    }
    
    /// Handle verify SMS code action
    private func handleVerifyCode() async {
        logger.info("User requested to verify SMS code")
        
        guard isVerificationCodeValid else {
            logger.warning("Invalid verification code format")
            return
        }
        
        do {
            try await firebaseManager.verifyPhoneCode(verificationCode: verificationCode)
            logger.info("Phone verification successful")
        } catch {
            logger.error("Phone verification failed: \(error.localizedDescription)")
            // Error handling is managed by FirebaseManager
        }
    }
    
    /// Handle resend verification code action
    private func handleResendCode() async {
        logger.info("User requested to resend verification code")
        
        // Reset flow to phone input and clear verification code
        verificationCode = ""
        firebaseManager.resetPhoneAuthFlow()
        firebaseManager.currentPhoneAuthFlow = .inputPhoneNumber
        
        // Automatically send new code if phone number is valid
        if isPhoneNumberValid {
            await handleSendCode()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format phone number for display (e.g., "+1 (469) 203-9202")
    private func formatPhoneNumberForDisplay(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.filter { $0.isNumber }
        
        guard digitsOnly.count == 10 else {
            return phoneNumber
        }
        
        let area = digitsOnly.prefix(3)
        let exchange = digitsOnly.dropFirst(3).prefix(3)
        let number = digitsOnly.suffix(4)
        
        return "+1 (\(area)) \(exchange)-\(number)"
    }
}

// MARK: - Supporting Views

/// Loading overlay view with progress indicator
struct LoadingOverlayView: View {
    var body: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: AppTheme.Spacing.medium) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppTheme.Colors.primary)
                    
                    Text("Processing...")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.onBackground)
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
}

/// Error display view with retry option
struct ErrorDisplayView: View {
    let message: String
    let onRetry: () -> Void
    
    @State private var isShowingAlert = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: AppIcons.error)
                    .foregroundStyle(AppTheme.Colors.error)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.error)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            Button("Retry") {
                onRetry()
            }
            .font(AppTheme.Typography.subheadline)
            .foregroundStyle(AppTheme.Colors.primary)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.error.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .stroke(AppTheme.Colors.error, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Phone Auth View") {
    PhoneAuthView()
}

#Preview("Phone Auth View - Verification Code") {
    PhoneAuthView()
        .onAppear {
            // Simulate verification code step for preview
            FirebaseManager.shared.currentPhoneAuthFlow = .inputVerificationCode
        }
}
