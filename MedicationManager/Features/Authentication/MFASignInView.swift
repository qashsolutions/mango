import SwiftUI
import FirebaseAuth

struct MFASignInView: View {
    @State private var firebaseManager = FirebaseManager.shared
    let resolver: MultiFactorResolver
    @State private var selectedFactorIndex = 0
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    let onComplete: () -> Void
    
    private var selectedFactor: MultiFactorInfo {
        resolver.hints[selectedFactorIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.large) {
                Spacer()
                
                headerSection
                
                factorSelectionSection
                
                verificationSection
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .navigationTitle(AppStrings.Authentication.mfaRequired)
            .navigationBarTitleDisplayMode(.large)
            .alert(AppStrings.ErrorMessages.genericError, isPresented: $showError) {
                Button(AppStrings.Common.ok) {
                    showError = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.Colors.primary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Authentication.mfaRequired)
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
                
                Text("Please verify your identity using one of your registered methods.")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.onSurface)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var factorSelectionSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if resolver.hints.count > 1 {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Choose verification method:")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.onBackground)
                    
                    Picker("Verification Method", selection: $selectedFactorIndex) {
                        ForEach(0..<resolver.hints.count, id: \.self) { index in
                            Text(factorDisplayName(for: resolver.hints[index]))
                                .tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            } else {
                Text("Verification method: \(factorDisplayName(for: selectedFactor))")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.onBackground)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(
            color: AppTheme.Shadow.medium.color,
            radius: AppTheme.Shadow.medium.radius,
            x: AppTheme.Shadow.medium.x,
            y: AppTheme.Shadow.medium.y
        )
    }
    
    private var verificationSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            VStack(spacing: AppTheme.Spacing.medium) {
                if selectedFactor.factorID == PhoneMultiFactorID {
                    Text("Enter the SMS code sent to your phone:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.onSurface)
                        .multilineTextAlignment(.center)
                } else if selectedFactor.factorID == TOTPMultiFactorID {
                    Text(AppStrings.Authentication.mfaVerificationSubtitle)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.onSurface)
                        .multilineTextAlignment(.center)
                }
                
                TextField(
                    AppStrings.Authentication.mfaCodePlaceholder,
                    text: $verificationCode
                )
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .frame(maxWidth: AppTheme.Layout.inputFieldMaxWidth)
                .font(.system(.title2, design: .monospaced))
                .multilineTextAlignment(.center)
                .accessibilityLabel("MFA verification code input")
            }
            
            Button {
                Task {
                    await verifySecondFactor()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.onPrimary))
                            .scaleEffect(0.8)
                    } else {
                        Text(AppStrings.Authentication.mfaVerifyButton)
                            .font(AppTheme.Typography.headline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(verificationCode.count == 6 ? AppTheme.Colors.primary : AppTheme.Colors.secondary.opacity(0.6))
                .foregroundStyle(AppTheme.Colors.onPrimary)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .shadow(
                    color: AppTheme.Shadow.medium.color,
                    radius: AppTheme.Shadow.medium.radius,
                    x: AppTheme.Shadow.medium.x,
                    y: AppTheme.Shadow.medium.y
                )
            }
            .disabled(verificationCode.count != 6 || isLoading)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.error)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(
            color: AppTheme.Shadow.medium.color,
            radius: AppTheme.Shadow.medium.radius,
            x: AppTheme.Shadow.medium.x,
            y: AppTheme.Shadow.medium.y
        )
    }
    
    private func factorDisplayName(for factor: MultiFactorInfo) -> String {
        switch factor.factorID {
        case PhoneMultiFactorID:
            return "SMS"
        case TOTPMultiFactorID:
            return "Authenticator App"
        default:
            return factor.displayName ?? "Unknown"
        }
    }
    
    private func verifySecondFactor() async {
        isLoading = true
        errorMessage = ""
        
        defer {
            isLoading = false
        }
        
        do {
            try await firebaseManager.verifyMFACode(verificationCode, resolver: resolver)
            onComplete()
        } catch {
            errorMessage = "Invalid code. Please try again."
            verificationCode = ""
            showError = true
        }
    }
}

#if DEBUG
struct MFASignInView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock preview since we can't create a real MultiFactorResolver
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.Colors.primary)
            
            Text("MFA Sign-In Preview")
                .font(AppTheme.Typography.largeTitle)
                .fontWeight(.bold)
            
            TextField("123456", text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: AppTheme.Layout.inputFieldMaxWidth)
            
            Button("Verify") {}
                .font(AppTheme.Typography.headline)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(AppTheme.Colors.primary)
                .foregroundStyle(AppTheme.Colors.onPrimary)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding()
    }
}
#endif