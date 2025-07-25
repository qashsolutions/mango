import SwiftUI
@preconcurrency import FirebaseAuth
import CoreImage

struct MFASetupView: View {
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let firebaseManager = FirebaseManager.shared
    @State private var isLoading = false
    @State private var totpSecret: TOTPSecret?
    @State private var qrCodeURL = ""
    @State private var backupCodes: [String] = []
    @State private var verificationCode = ""
    @State private var showBackupCodes = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    headerSection
                    
                    if totpSecret != nil {
                        setupSection
                    }
                    
                    if showBackupCodes {
                        backupCodesSection
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle(AppStrings.Authentication.mfaSetupTitle)
            .navigationBarTitleDisplayMode(.large)
            .task {
                await enrollMFA()
            }
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
            Image(systemName: "shield.checkered")
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Authentication.mfaSetupTitle)
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
                
                Text(AppStrings.Authentication.mfaSetupSubtitle)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text(AppStrings.Authentication.mfaSecurityMessage)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppTheme.Spacing.small)
            }
        }
    }
    
    private var setupSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.Authentication.mfaScanQRTitle)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                
                Text(AppStrings.Authentication.mfaScanQRSubtitle)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.onSurface)
                    .multilineTextAlignment(.center)
                
                if let qrImage = generateQRCode(from: qrCodeURL) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: AppTheme.Layout.qrCodeSize, height: AppTheme.Layout.qrCodeSize)
                        .background(AppTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        .shadow(
                            color: AppTheme.Shadow.medium.color,
                            radius: AppTheme.Shadow.medium.radius,
                            x: AppTheme.Shadow.medium.x,
                            y: AppTheme.Shadow.medium.y
                        )
                }
            }
            
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.Authentication.mfaEnterCodeTitle)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                
                TextField(
                    AppStrings.Authentication.mfaCodePlaceholder,
                    text: $verificationCode
                )
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .frame(maxWidth: AppTheme.Layout.inputFieldMaxWidth)
                .accessibilityLabel("MFA verification code input")
                
                Button {
                    // Note: No [weak self] needed here because MFASetupView is a struct (value type).
                    // SwiftUI views are designed as structs that get recreated frequently, so there's
                    // no risk of retain cycles like with reference types (classes).
                    Task {
                        await finalizeMFASetup()
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.small) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.onPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Text(AppStrings.Authentication.mfaCompleteSetup)
                                .font(AppTheme.Typography.headline)
                                .fontWeight(.semibold)
                        }
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
                .disabled(verificationCode.count != 6 || isLoading)
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
    
    private var backupCodesSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            VStack(spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Authentication.mfaBackupCodesTitle)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.onBackground)
                
                Text(AppStrings.Authentication.mfaBackupCodesSubtitle)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.onSurface)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppTheme.Spacing.small) {
                ForEach(backupCodes, id: \.self) { code in
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.onSurface)
                        .padding(AppTheme.Spacing.small)
                        .background(AppTheme.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
            
            Button {
                onComplete()
            } label: {
                Text(AppStrings.Authentication.mfaSaveCodesButton)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
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
    
    private func enrollMFA() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let mfaData = try await firebaseManager.enrollMFA()
            totpSecret = mfaData.totpSecret
            qrCodeURL = mfaData.qrCodeURL
            backupCodes = mfaData.backupCodes
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func finalizeMFASetup() async {
            guard let totpSecret = totpSecret else { return }
            
            isLoading = true
            defer { isLoading = false }
            
        do {
                 // --- FIX IS HERE ---
                 // Access the firebaseManager instance via the wrapper's wrappedValue
                 // Call the finalizeMFAEnrollment method on the wrapped value.
            try await (self.firebaseManager as FirebaseManager).finalizeMFAEnrollment( // <-- Corrected line
                     totpSecret: totpSecret,
                     totpCode: verificationCode, // Access local state directly
                     displayName: "Authenticator App"
                 )
                 // --- Update local state on success ---
                 showBackupCodes = true // Local state variable
                 // --- Dismiss the view and call completion on success ---
                 dismiss()
                 onComplete() // Call the completion handler

            } catch {
                // --- Update local error state on failure ---
                errorMessage = error.localizedDescription
                // Local state variable
                showError = true
                // Local state variable to present alert
                verificationCode = ""
                // Clear verification code input on error
            }
        // The 'defer { isLoading = false }' handles clearing local isLoading when the function exits (successfully or due to error).
         }
    }
    
        
        private func generateQRCode(from string: String) -> UIImage? {
            let context = CIContext()
            guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
            
            filter.setValue(Data(string.utf8), forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                
                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
            
            return nil
        }

    #if DEBUG
    struct MFASetupView_Previews: PreviewProvider {
        static var previews: some View {
            MFASetupView(onComplete: {})
        }
    }
#endif
