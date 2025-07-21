import SwiftUI
import AppIntents

@MainActor
struct SiriTipPresenter {
    static func showTip(for intent: SiriIntentType, in window: UIWindow) {
        // iOS 18 way to show Siri tips
        Task {
            switch intent {
            case .addMedication(let name, let dosage, let frequency):
                // Create a tip for adding medication
                let phrase = createAddMedicationPhrase(name: name, dosage: dosage, frequency: frequency)
                await showSiriTip(phrase: phrase, in: window)
                
            case .viewMedications:
                await showSiriTip(phrase: AppStrings.Siri.viewMedicationsPhrase, in: window)
                
            case .checkConflicts:
                await showSiriTip(phrase: AppStrings.Siri.checkConflictsPhrase, in: window)
                
            case .viewDoctors:
                await showSiriTip(phrase: AppStrings.Siri.viewDoctorsPhrase, in: window)
                
            case .morningMedications:
                await showSiriTip(phrase: AppStrings.Siri.morningMedicationsPhrase, in: window)
                
            case .eveningMedications:
                await showSiriTip(phrase: AppStrings.Siri.eveningMedicationsPhrase, in: window)
            }
        }
    }
    
    private static func createAddMedicationPhrase(name: String, dosage: String?, frequency: MedicationFrequency?) -> String {
        var phrase = AppStrings.Siri.addMedicationPhrase
            .replacingOccurrences(of: "{medication}", with: name)
        
        if let dosage = dosage {
            phrase = phrase.replacingOccurrences(of: "{dosage}", with: dosage)
        } else {
            phrase = phrase.replacingOccurrences(of: " {dosage}", with: "")
        }
        
        if let frequency = frequency {
            phrase = phrase.replacingOccurrences(of: "{frequency}", with: frequency.displayName.lowercased())
        } else {
            phrase = phrase.replacingOccurrences(of: " {frequency}", with: "")
        }
        
        return phrase
    }
    
    private static func showSiriTip(phrase: String, in window: UIWindow) async {
        // iOS 18 Siri tips implementation
        // This would show a native iOS tip bubble with the suggested phrase
        
        // For now, show a custom toast notification
        await MainActor.run {
            let tipView = SiriTipToast(phrase: phrase)
            
            if window.windowScene != nil {
                let hostingController = UIHostingController(rootView: tipView)
                hostingController.view.backgroundColor = .clear
                
                window.addSubview(hostingController.view)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    hostingController.view.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: AppTheme.Spacing.medium),
                    hostingController.view.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -AppTheme.Spacing.medium),
                    hostingController.view.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.large)
                ])
                
                // Animate in
                hostingController.view.alpha = 0
                hostingController.view.transform = CGAffineTransform(translationX: 0, y: -20)
                
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    hostingController.view.alpha = 1
                    hostingController.view.transform = .identity
                } completion: { _ in
                    // Auto dismiss after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        UIView.animate(withDuration: 0.3) {
                            hostingController.view.alpha = 0
                            hostingController.view.transform = CGAffineTransform(translationX: 0, y: -20)
                        } completion: { _ in
                            hostingController.view.removeFromSuperview()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Siri Intent Types
enum SiriIntentType {
    case addMedication(name: String, dosage: String?, frequency: MedicationFrequency?)
    case viewMedications
    case checkConflicts
    case viewDoctors
    case morningMedications
    case eveningMedications
}

// MARK: - Siri Tip Toast View
private struct SiriTipToast: View {
    let phrase: String
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: AppIcons.microphone)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppTheme.Colors.primary.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(AppStrings.Siri.tipTitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text("\"\(phrase)\"")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.Colors.background)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            // Open Siri with the phrase
            openSiriWithPhrase(phrase)
        }
    }
    
    private func openSiriWithPhrase(_ phrase: String) {
        // In iOS 18, we would use the proper Siri API to pre-fill the phrase
        // For now, just copy to clipboard as a fallback
        UIPasteboard.general.string = phrase
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(
            "siri_tip_tapped",
            parameters: ["phrase": phrase]
        )
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
        
        SiriTipToast(phrase: "Add ibuprofen 200mg twice daily")
            .padding()
    }
}
