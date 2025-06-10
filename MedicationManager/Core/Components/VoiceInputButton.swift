import SwiftUI

struct VoiceInputButton: View {
    let context: VoiceInputContext
    let onResult: (String) -> Void
    
    @StateObject private var speechManager = SpeechManager.shared
    @State private var isPressed: Bool = false
    @State private var showingPermissionAlert: Bool = false
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                Circle()
                    .fill(buttonBackgroundColor)
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay {
                        Circle()
                            .stroke(buttonBorderColor, lineWidth: buttonBorderWidth)
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .shadow(
                        color: shadowColor,
                        radius: shadowRadius,
                        x: 0,
                        y: shadowOffset
                    )
                
                VStack(spacing: AppTheme.Spacing.extraSmall) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(iconColor)
                        .scaleEffect(speechManager.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: speechManager.isRecording)
                    
                    if showStatusText {
                        Text(statusText)
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(statusTextColor)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(speechManager.isProcessing || !speechManager.isAuthorized)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
                
                if pressing && speechManager.isAuthorized {
                    startVoiceInput()
                } else if !pressing && speechManager.isRecording {
                    stopVoiceInput()
                }
            },
            perform: {}
        )
        .alert(AppStrings.Voice.permissionRequired, isPresented: $showingPermissionAlert) {
            Button(AppStrings.Common.settings) {
                openSettings()
            }
            Button(AppStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.Voice.permissionMessage)
        }
        .onChange(of: speechManager.recognizedText) { _, newText in
            if !newText.isEmpty && !speechManager.isRecording {
                onResult(newText)
            }
        }
        .task {
            if !speechManager.isAuthorized {
                await speechManager.requestSpeechAuthorization()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var buttonSize: CGFloat {
        switch context {
        case .medicationName, .doctorName, .foodName:
            return 64
        case .dosage:
            return 56
        case .frequency, .notes:
            return 60
        case .doctorSpecialty:
            return 56
        case .general:
            return 68
        }
    }
    
    private var iconSize: CGFloat {
        buttonSize * 0.35
    }
    
    private var buttonBackgroundColor: Color {
        if speechManager.isRecording {
            return AppTheme.Colors.voiceActive
        } else if speechManager.isProcessing {
            return AppTheme.Colors.voiceProcessing
        } else if !speechManager.isAuthorized {
            return AppTheme.Colors.voiceDisabled
        } else {
            return AppTheme.Colors.voiceIdle
        }
    }
    
    private var buttonBorderColor: Color {
        if speechManager.isRecording {
            return AppTheme.Colors.voiceActiveBorder
        } else {
            return AppTheme.Colors.voiceIdleBorder
        }
    }
    
    private var buttonBorderWidth: CGFloat {
        speechManager.isRecording ? 3.0 : 1.0
    }
    
    private var iconColor: Color {
        if speechManager.isRecording {
            return AppTheme.Colors.onVoiceActive
        } else if !speechManager.isAuthorized {
            return AppTheme.Colors.onVoiceDisabled
        } else {
            return AppTheme.Colors.onVoiceIdle
        }
    }
    
    private var buttonIcon: String {
        if speechManager.isProcessing {
            return "waveform.circle"
        } else if speechManager.isRecording {
            return "mic.fill"
        } else if !speechManager.isAuthorized {
            return "mic.slash"
        } else {
            return "mic"
        }
    }
    
    private var statusText: String {
        if speechManager.isProcessing {
            return AppStrings.Voice.processing
        } else if speechManager.isRecording {
            return AppStrings.Voice.listening
        } else if !speechManager.isAuthorized {
            return AppStrings.Voice.permissionNeeded
        } else {
            return AppStrings.Voice.tapToSpeak
        }
    }
    
    private var statusTextColor: Color {
        if !speechManager.isAuthorized {
            return AppTheme.Colors.error
        } else {
            return AppTheme.Colors.secondaryText
        }
    }
    
    private var showStatusText: Bool {
        switch context {
        case .general:
            return true
        default:
            return false
        }
    }
    
    private var shadowColor: Color {
        if speechManager.isRecording {
            return AppTheme.Colors.voiceActive.opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        speechManager.isRecording ? 8 : 4
    }
    
    private var shadowOffset: CGFloat {
        speechManager.isRecording ? 0 : 2
    }
    
    // MARK: - Actions
    private func handleTap() {
        guard speechManager.isAuthorized else {
            showingPermissionAlert = true
            return
        }
        
        if speechManager.isRecording {
            stopVoiceInput()
        } else {
            startVoiceInput()
        }
    }
    
    private func startVoiceInput() {
        guard !speechManager.isRecording && !speechManager.isProcessing else { return }
        
        Task {
            do {
                AnalyticsManager.shared.trackVoiceInputStarted(context: context.analyticsName)
                try await speechManager.startRecording()
                
                // Auto-stop after context-specific duration
                DispatchQueue.main.asyncAfter(deadline: .now() + context.maxDuration) {
                    if speechManager.isRecording {
                        stopVoiceInput()
                    }
                }
            } catch {
                AnalyticsManager.shared.trackVoiceInputError(
                    context: context.analyticsName,
                    errorType: error.localizedDescription
                )
            }
        }
    }
    
    private func stopVoiceInput() {
        speechManager.stopRecording()
        
        if !speechManager.recognizedText.isEmpty {
            AnalyticsManager.shared.trackVoiceInputCompleted(
                context: context.analyticsName,
                success: true,
                duration: context.maxDuration
            )
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Voice Input Context Extensions
extension VoiceInputContext {
    var analyticsName: String {
        switch self {
        case .medicationName:
            return "medication_name"
        case .dosage:
            return "dosage"
        case .frequency:
            return "frequency"
        case .notes:
            return "notes"
        case .doctorName:
            return "doctor_name"
        case .doctorSpecialty:
            return "doctor_specialty"
        case .foodName:
            return "food_name"
        case .general:
            return "general"
        }
    }
}

// MARK: - Compact Voice Input Button
struct CompactVoiceInputButton: View {
    let context: VoiceInputContext
    let onResult: (String) -> Void
    
    @StateObject private var speechManager = SpeechManager.shared
    
    var body: some View {
        Button(action: {
            if speechManager.isRecording {
                speechManager.stopRecording()
            } else {
                Task {
                    try? await speechManager.startRecording()
                }
            }
        }) {
            Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(speechManager.isRecording ? AppTheme.Colors.voiceActive : AppTheme.Colors.primary)
        }
        .frame(width: 32, height: 32)
        .background(
            Circle()
                .fill(speechManager.isRecording ? AppTheme.Colors.voiceActive.opacity(0.1) : Color.clear)
        )
        .disabled(!speechManager.isAuthorized)
        .onChange(of: speechManager.recognizedText) { _, newText in
            if !newText.isEmpty && !speechManager.isRecording {
                onResult(newText)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.large) {
        VoiceInputButton(context: .general) { text in
            print("Voice result: \(text)")
        }
        
        VoiceInputButton(context: .medicationName) { text in
            print("Medication: \(text)")
        }
        
        CompactVoiceInputButton(context: .dosage) { text in
            print("Dosage: \(text)")
        }
    }
    .padding()
}
