import SwiftUI

struct PhoneAuthView: View {
    @State private var firebaseManager = FirebaseManager.shared
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?
    @State private var showVerificationCodeField = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.large) {
                // Header
                headerSection
                
                // Phone Number Input
                phoneNumberSection
                
                // Verification Code Input (shown after phone verification)
                if showVerificationCodeField {
                    verificationCodeSection
                }
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
            }
            .padding(AppTheme.Spacing.large)
            .background(AppTheme.Colors.background)
            .navigationTitle(AppStrings.Authentication.signInWithPhone)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: AppIcons.phone)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(AppTheme.Colors.primary)
            
            Text(AppStrings.Authentication.phoneVerificationTitle)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.onBackground)
                .multilineTextAlignment(.center)
            
            Text(AppStrings.Authentication.phoneVerificationSubtitle)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    private var phoneNumberSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Authentication.phoneNumber)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.onBackground)
            
            TextField("+1 (555) 123-4567", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(AppTheme.Colors.secondary.opacity(0.3), lineWidth: 1)
                )
                .disabled(showVerificationCodeField)
        }
    }
    
    private var verificationCodeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Authentication.verificationCode)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.onBackground)
            
            TextField("123456", text: $verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.surface)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(AppTheme.Colors.secondary.opacity(0.3), lineWidth: 1)
                )
            
            Text(AppStrings.Authentication.verificationCodeHint)
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.6))
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if !showVerificationCodeField {
                // Send Code Button
                Button {
                    Task {
                        await sendVerificationCode()
                    }
                } label: {
                    Text(AppStrings.Authentication.sendCode)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Layout.buttonHeight)
                        .background(phoneNumber.isEmpty ? AppTheme.Colors.secondary.opacity(0.5) : AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .disabled(phoneNumber.isEmpty || firebaseManager.isLoading)
            } else {
                // Verify Code Button
                Button {
                    Task {
                        await verifyCode()
                    }
                } label: {
                    Text(AppStrings.Authentication.verifyCode)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Layout.buttonHeight)
                        .background(verificationCode.isEmpty ? AppTheme.Colors.secondary.opacity(0.5) : AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .disabled(verificationCode.isEmpty || firebaseManager.isLoading)
                
                // Resend Code Button
                Button {
                    Task {
                        await sendVerificationCode()
                    }
                } label: {
                    Text(AppStrings.Authentication.resendCode)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                .disabled(firebaseManager.isLoading)
            }
        }
    }
    
    // MARK: - Actions
    private func sendVerificationCode() async {
        do {
            let verificationID = try await firebaseManager.signInWithPhone(phoneNumber)
            self.verificationID = verificationID
            showVerificationCodeField = true
        } catch {
            // Error handling is managed by FirebaseManager
        }
    }
    
    private func verifyCode() async {
        guard let verificationID = verificationID else { return }
        
        do {
            try await firebaseManager.verifyPhoneCode(verificationID: verificationID, verificationCode: verificationCode)
            dismiss()
        } catch {
            // Error handling is managed by FirebaseManager
        }
    }
}

// MARK: - Preview
#Preview("Phone Auth View") {
    PhoneAuthView()
}

#Preview("Phone Auth View - Verification") {
    PhoneAuthView()
        .onAppear {
            // Simulate verification code step
        }
}