import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

@available(iOS 18.0, *)
public struct MedicationShortcuts: AppShortcutsProvider {
    
    public static var appShortcuts: [AppShortcut] {
        // Note: iOS 18 uses result builder pattern - no array brackets or commas!
        
        AppShortcut(
            intent: CheckMedicationsIntent(),
            phrases: [
                "Check my medications in \(.applicationName)",
                "What medications do I take in \(.applicationName)",
                "Show my pills in \(.applicationName)",
                "List my medications in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(stringLiteral: "Check Medications"),
            systemImageName: "pills.fill"
        )
        
        AppShortcut(
            intent: AddMedicationIntent(),
            phrases: [
                "Add medication to \(.applicationName)",
                "Add new medication to \(.applicationName)",
                "Add a medication in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(stringLiteral: "Add Medication"),
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: CheckConflictsIntent(),
            phrases: [
                "Check medication conflicts in \(.applicationName)",
                "Check if my medications interact in \(.applicationName)",
                "Are my medications safe together in \(.applicationName)",
                "Check drug interactions in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(stringLiteral: "Check Conflicts"),
            systemImageName: "exclamationmark.triangle.fill"
        )
        
        AppShortcut(
            intent: LogMedicationIntent(),
            phrases: [
                "Log medication in \(.applicationName)",
                "Mark medication as taken in \(.applicationName)",
                "I took my medication in \(.applicationName)",
                "Skip medication in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(stringLiteral: "Log Medication"),
            systemImageName: "checkmark.circle.fill"
        )
        
        AppShortcut(
            intent: SetReminderIntent(),
            phrases: [
                "Set medication reminder in \(.applicationName)",
                "Remind me about medication in \(.applicationName)",
                "Set medication reminder in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(stringLiteral: "Set Reminder"),
            systemImageName: "bell.fill"
        )
        
        AppShortcut(
            intent: VoiceQueryIntent(),
            phrases: [
                "Ask \(.applicationName) a question",
                "Ask about medications in \(.applicationName)",
                "Check medications in \(.applicationName)",
                "What medications should I take with breakfast in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(stringLiteral: "Ask Question"),
            systemImageName: "questionmark.circle.fill"
        )
    }
    
    public static let shortcutTileColor: ShortcutTileColor = .blue
}

// MARK: - Dynamic Shortcuts Manager

@available(iOS 18.0, *)
public struct DynamicShortcutsManager {
    
    /// Update shortcuts based on user behavior
    public static func updateShortcuts(for userId: String) async {
        // This is called from various places in the app to update shortcuts
        // based on user behavior patterns
        
        // Donate frequently used intents
        await MedicationIntentsRegistration.donateCommonIntents()
        
        // Track that shortcuts were updated
        await MainActor.run {
            AnalyticsManager.shared.trackEvent(
                "shortcuts_updated",
                parameters: ["userId": userId]
            )
        }
    }
    
    /// Track when specific views are opened for shortcut suggestions
    @MainActor
    public static func trackConflictViewOpened() {
        AnalyticsManager.shared.trackEvent("conflict_view_opened_for_shortcuts")
    }
    
    @MainActor
    public static func trackMedicationViewOpened() {
        AnalyticsManager.shared.trackEvent("medication_view_opened_for_shortcuts")
    }
}