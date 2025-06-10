import SwiftUI

struct LoginView: View {
    @State private var firebaseManager = FirebaseManager.shared
    @State private var showPhoneAuth = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.extraLarge) {
                // Logo and Branding Section
                brandingSection
                
                // Welcome Message
                welcomeSection
                
                // Sign In Button
                signInSection
                
                // Medical Disclaimer
                disclaimerSection
                
                Spacer()
            }
            .padding(AppTheme.Spacing.large)
            .background(AppTheme.Colors.background)
            .overlay {
                if firebaseManager.isLoading {
                    loadingOverlay
                }
            }
            .alert(AppStrings.ErrorMessages.genericError, isPresented: .constant(firebaseManager.errorMessage != nil)) {
                Button(AppStrings.Common.ok) {
                    firebaseManager.clearError()
                }
            } message: {
                if let errorMessage = firebaseManager.errorMessage {
                    Text(errorMessage)
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
            Button {
                Task {
                    await signInWithGoogle()
                }
            } label: {
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
            }
            .disabled(firebaseManager.isLoading)
            .accessibilityLabel(AppStrings.Accessibility.signInButton)
            .accessibilityHint(AppStrings.Accessibility.signInButtonHint)
            .sensoryFeedback(.impact(weight: .medium), trigger: firebaseManager.isLoading)
            
            // Phone Sign-In Button
            Button {
                showPhoneAuth = true
            } label: {
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
            }
            .disabled(firebaseManager.isLoading)
        }
        .sheet(isPresented: $showPhoneAuth) {
            PhoneAuthView()
        }
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
                    // Handle privacy policy tap
                }
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.primary)
                
                Text("•")
                    .foregroundStyle(AppTheme.Colors.onBackground.opacity(0.6))
                
                Button(AppStrings.Legal.termsOfService) {
                    // Handle terms of service tap
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
                
                Text(AppStrings.Authentication.signingIn)
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
        do {
            try await firebaseManager.signInWithGoogle()
        } catch {
            // Error handling is managed by FirebaseManager
        }
    }
}

// MARK: - Preview
#Preview("Login View") {
    LoginView()
        .preferredColorScheme(.light)
}

#Preview("Login View - Dark") {
    LoginView()
        .preferredColorScheme(.dark)
}

#Preview("Login View - Loading") {
    LoginView()
        .preferredColorScheme(.light)
        .onAppear {
            FirebaseManager.shared.isLoading = true
        }
}