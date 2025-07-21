import SwiftUI
import Observation

@MainActor
struct VoiceInputSheet: View {
    let context: VoiceInteractionContext
    @Environment(\.dismiss) private var dismiss
    // iOS 18/Swift 6: Direct reference to @Observable singletons
    private let voiceManager = VoiceInteractionManager.shared
    private let navigationManager = NavigationManager.shared
    @State private var transcribedText = ""
    @State private var isListening = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.large) {
                // Instructions
                Text(context.prompt)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppTheme.Spacing.extraLarge)
                
                // Voice Animation
                VoiceAnimationView(isListening: $isListening)
                    .frame(height: 200)
                
                // Transcription Display
                if !voiceManager.transcribedText.isEmpty {
                    VStack(spacing: AppTheme.Spacing.small) {
                        Text(AppStrings.Voice.heardText)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Text(voiceManager.transcribedText)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .padding()
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: AppTheme.Spacing.medium) {
                    if voiceManager.isListening {
                        Button(action: stopListening) {
                            Label(AppStrings.Voice.stopListening, systemImage: "stop.circle.fill")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.Colors.error)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                    } else {
                        Button(action: startListening) {
                            Label(AppStrings.Voice.startListening, systemImage: "mic.circle.fill")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.Colors.primary)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                    }
                    
                    if !voiceManager.transcribedText.isEmpty && !voiceManager.isListening {
                        Button(action: processVoiceInput) {
                            Text(AppStrings.Common.continue)
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.Colors.success)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.large)
            }
            .navigationTitle(AppStrings.Voice.voiceInput)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: voiceManager.isListening) { _, newValue in
            isListening = newValue
        }
    }
    
    // MARK: - Actions
    
    private func startListening() {
        Task {
            do {
                try await voiceManager.startListening(context: context)
            } catch {
                // Error handled by VoiceInteractionManager
            }
        }
    }
    
    private func stopListening() {
        voiceManager.stopListening()
    }
    
    private func processVoiceInput() {
        let text = voiceManager.transcribedText
        dismiss()
        
        // Route based on context
        switch context {
        case .medicationName, .dosage, .frequency:
            navigationManager.presentSheet(.addMedication(voiceText: text))
        case .supplementName:
            navigationManager.presentSheet(.addSupplement(voiceText: text))
        case .foodName:
            navigationManager.presentSheet(.addDietEntry(voiceText: text))
        case .doctorName:
            navigationManager.presentSheet(.addDoctor(contact: nil))
        case .conflictQuery:
            navigationManager.selectTab(.conflicts)
        case .general, .notes:
            // Parse general input
            handleGeneralVoiceInput(text)
        }
    }
    
    private func handleGeneralVoiceInput(_ text: String) {
        let lowercasedText = text.lowercased()
        
        if lowercasedText.contains("medication") || lowercasedText.contains("medicine") {
            navigationManager.presentSheet(.addMedication(voiceText: text))
        } else if lowercasedText.contains("supplement") || lowercasedText.contains("vitamin") {
            navigationManager.presentSheet(.addSupplement(voiceText: text))
        } else if lowercasedText.contains("meal") || lowercasedText.contains("food") {
            navigationManager.presentSheet(.addDietEntry(voiceText: text))
        } else if lowercasedText.contains("doctor") {
            navigationManager.presentSheet(.addDoctor(contact: nil))
        } else if lowercasedText.contains("conflict") || lowercasedText.contains("interaction") {
            navigationManager.selectTab(.conflicts)
        } else {
            // Default to medication
            navigationManager.presentSheet(.addMedication(voiceText: text))
        }
    }
}

// MARK: - Voice Animation View
struct VoiceAnimationView: View {
    @Binding var isListening: Bool
    @State private var animationAmount: CGFloat = 1
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(AppTheme.Colors.voiceActive.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: 100 + CGFloat(index) * 40, height: 100 + CGFloat(index) * 40)
                    .scaleEffect(isListening ? animationAmount : 1)
                    .animation(
                        isListening ?
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2) :
                        .default,
                        value: isListening
                    )
            }
            
            Image(systemName: isListening ? "mic.fill" : "mic")
                .font(.system(size: 60))
                .foregroundColor(isListening ? AppTheme.Colors.voiceActive : AppTheme.Colors.primary)
                .scaleEffect(isListening ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isListening)
        }
        .onAppear {
            animationAmount = 1.3
        }
    }
}

#Preview {
    VoiceInputSheet(context: .general)
}
