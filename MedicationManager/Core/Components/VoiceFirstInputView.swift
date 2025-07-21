import SwiftUI
import AVFoundation

struct VoiceFirstInputView: View {
    @Binding var text: String
    let placeholder: String
    let voiceContext: VoiceInteractionContext
    let onSubmit: () -> Void
    
    @State private var isRecording: Bool = false
    @State private var showingTextField: Bool = false
    @State private var recordingError: AppError?
    @State private var showingPermissionAlert: Bool = false
    
    @State private var speechManager = SpeechManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if showingTextField {
                textInputView()
            } else {
                voiceInputView()
            }
            
            transcriptionDisplay()
        }
        .alert(AppStrings.Voice.permissionRequired, isPresented: $showingPermissionAlert) {
            Button(AppStrings.Common.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(AppStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.Voice.permissionMessage)
        }
        .onChange(of: speechManager.isRecording) {_, newValue in
            isRecording = newValue
        }
        .onChange(of: speechManager.recognizedText) {_, newValue in
            if !newValue.isEmpty && !speechManager.isRecording {
                text = newValue
            }
        }
        .task {
            await checkVoicePermissions()
        }
    }
    
    // MARK: - Voice Input View
    @ViewBuilder
    private func voiceInputView() -> some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Microphone Button with Animation
            ZStack {
                // Outer animated rings
                if isRecording {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(AppTheme.Colors.voiceActive.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                            .scaleEffect(isRecording ? 1.5 + CGFloat(index) * 0.2 : 1.0)
                            .opacity(isRecording ? 0 : 1)
                            .animation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                value: isRecording
                            )
                    }
                }
                
                // Audio level indicator
                Circle()
                    .fill(AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low))
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)
                
                // Main microphone button
                Button(action: toggleRecording) {
                    Image(systemName: isRecording ? AppIcons.voiceRecording : AppIcons.voiceInput)
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.onPrimary)
                        .frame(width: 80, height: 80)
                        .background(isRecording ? AppTheme.Colors.voiceActive : AppTheme.Colors.primary)
                        .clipShape(Circle())
                        .shadow(
                            color: isRecording ? AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low) : AppTheme.Shadow.large.color,
                            radius: AppTheme.Shadow.large.radius,
                            x: AppTheme.Shadow.large.x,
                            y: AppTheme.Shadow.large.y
                        )
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
            .frame(width: 120, height: 120)
            
            // Instructions
            VStack(spacing: AppTheme.Spacing.small) {
                Text(isRecording ? AppStrings.Voice.listening : getInstructionText())
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                if !isRecording {
                    Button(action: { showingTextField = true }) {
                        Text(AppStrings.Voice.typeInstead)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.large)
    }
    
    // MARK: - Text Input View
    @ViewBuilder
    private func textInputView() -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Use MedicationAutocompleteField for medication/supplement contexts
            if shouldUseAutocomplete() {
                HStack(spacing: AppTheme.Spacing.small) {
                    MedicationAutocompleteField(
                        text: $text,
                        placeholder: placeholder,
                        medicationType: getMedicationType(),
                        onCommit: onSubmit
                    )
                    
                    // Voice dictation button
                    Button(action: {
                        showingTextField = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            toggleRecording()
                        }
                    }) {
                        Image(systemName: AppIcons.voiceInput)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                    }
                    .padding(.trailing, AppTheme.Spacing.small)
                }
            } else {
                // Regular text field for other contexts
                HStack(spacing: AppTheme.Spacing.small) {
                    TextField(placeholder, text: $text)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(onSubmit)
                    
                    // Voice dictation button
                    Button(action: {
                        showingTextField = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            toggleRecording()
                        }
                    }) {
                        Image(systemName: AppIcons.voiceInput)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
                )
            }
            
            HStack {
                Button(AppStrings.Common.cancel) {
                    text = ""
                    showingTextField = false
                    isTextFieldFocused = false
                }
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                
                Spacer()
                
                Button(AppStrings.Common.done) {
                    onSubmit()
                    showingTextField = false
                    isTextFieldFocused = false
                }
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.primary)
                .disabled(text.isEmpty)
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - Transcription Display
    @ViewBuilder
    private func transcriptionDisplay() -> some View {
        if isRecording || !text.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                if isRecording && speechManager.recognizedText.isEmpty && text.isEmpty {
                    WaveformView(audioLevel: 0.5) // Static waveform for now
                        .frame(height: AppTheme.Layout.navBarHeight)
                } else {
                    ScrollView {
                        Text(isRecording && !speechManager.recognizedText.isEmpty ? speechManager.recognizedText : text)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.Spacing.medium)
                    }
                    .frame(maxHeight: 120)
                    .background(AppTheme.Colors.inputBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
                    )
                }
                
                if !text.isEmpty && !isRecording {
                    HStack {
                        Button(action: { text = "" }) {
                            HStack(spacing: AppTheme.Spacing.extraSmall) {
                                Image(systemName: AppIcons.clear)
                                    .font(AppTheme.Typography.caption)
                                Text(AppStrings.Common.clear)
                                    .font(AppTheme.Typography.caption1)
                            }
                            .foregroundColor(AppTheme.Colors.error)
                        }
                        
                        Spacer()
                        
                        Button(action: onSubmit) {
                            HStack(spacing: AppTheme.Spacing.extraSmall) {
                                Text(AppStrings.Common.submit)
                                    .font(AppTheme.Typography.caption1)
                                Image(systemName: AppIcons.send)
                                    .font(AppTheme.Typography.caption)
                            }
                            .foregroundColor(AppTheme.Colors.onPrimary)
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.vertical, AppTheme.Spacing.small)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: isRecording)
            .animation(.easeInOut(duration: 0.3), value: !text.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        Task {
            do {
                // Clear any previous text
                speechManager.recognizedText = ""
                
                // Start recording - let user control when to stop
                try await speechManager.startRecording()
                
                analyticsManager.trackVoiceInputStarted(context: voiceContext.rawValue)
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            } catch {
                recordingError = error as? AppError ?? AppError.voice(.speechRecognitionFailed)
                if case AppError.voice(.microphonePermissionDenied) = error {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func stopRecording() {
        speechManager.stopRecording()
        
        // Track analytics if we got text
        if !speechManager.recognizedText.isEmpty {
            analyticsManager.trackVoiceInputCompleted(
                context: voiceContext.rawValue,
                success: true,
                duration: voiceContext.maxDuration
            )
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func checkVoicePermissions() async {
        await speechManager.requestSpeechAuthorization()
        if !speechManager.isAuthorized && Configuration.Voice.autoPromptPermission {
            showingPermissionAlert = true
        }
    }
    
    private func getInstructionText() -> String {
        switch voiceContext {
        case .medicationName:
            return AppStrings.Voice.tapToSpeakMedication
        case .supplementName:
            return AppStrings.Voice.tapToSpeakSupplement
        case .dosage:
            return AppStrings.Voice.tapToSpeakDosage
        case .conflictQuery:
            return AppStrings.Voice.tapToAskQuestion
        case .general:
            return AppStrings.Voice.tapToSpeak
        case .notes:
            return AppStrings.Voice.notesPrompt
        case .doctorName:
            return AppStrings.Voice.doctorNamePrompt
        case .frequency:
            return AppStrings.Voice.frequencyPrompt
        case .foodName:
            return AppStrings.Voice.foodNamePrompt
        }
    }
    
    private func shouldUseAutocomplete() -> Bool {
        switch voiceContext {
        case .medicationName, .supplementName:
            return true
        default:
            return false
        }
    }
    
    private func getMedicationType() -> MedicationAutocompleteField.MedicationType {
        switch voiceContext {
        case .medicationName:
            return .medication
        case .supplementName:
            return .supplement
        default:
            return .medication
        }
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    let audioLevel: CGFloat
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                let wavelength = width / 5
                let amplitude = (height / 3) * audioLevel
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / wavelength
                    let y = midHeight + amplitude * sin(relativeX * .pi * 2 + phase)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low),
                        AppTheme.Colors.voiceActive,
                        AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Compact Voice Input
struct CompactVoiceInput: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        if isExpanded {
            VoiceFirstInputView(
                text: $text,
                placeholder: placeholder,
                voiceContext: .general,
                onSubmit: {
                    onSubmit()
                    withAnimation {
                        isExpanded = false
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
        } else {
            Button(action: {
                withAnimation {
                    isExpanded = true
                }
            }) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: AppIcons.voiceInput)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text(placeholder)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.large) {
        VoiceFirstInputView(
            text: .constant(""),
            placeholder: AppStrings.Voice.askAnything,
            voiceContext: .conflictQuery,
            onSubmit: {}
        )
        
        Divider()
        
        CompactVoiceInput(
            text: .constant(""),
            placeholder: AppStrings.Voice.tapToSpeak,
            onSubmit: {}
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
}
