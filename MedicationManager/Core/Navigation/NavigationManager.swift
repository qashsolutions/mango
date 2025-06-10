import Foundation
import SwiftUI

@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var selectedTab: MainTab = .myHealth
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreenCover: FullScreenDestination?
    @Published var showingAlert: AlertItem?
    
    private init() {}
    
    // MARK: - Tab Navigation
    func selectTab(_ tab: MainTab) {
        selectedTab = tab
        AnalyticsManager.shared.trackScreenViewed(tab.analyticsName)
    }
    
    func resetToRootTab() {
        navigationPath = NavigationPath()
        selectedTab = .myHealth
    }
    
    // MARK: - Navigation Stack Management
    func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
        AnalyticsManager.shared.trackScreenViewed(destination.analyticsName)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    func popToRoot(for tab: MainTab) {
        selectedTab = tab
        navigationPath = NavigationPath()
    }
    
    // MARK: - Sheet Presentation
    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
        AnalyticsManager.shared.trackScreenViewed(destination.analyticsName)
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    // MARK: - Full Screen Cover Presentation
    func presentFullScreenCover(_ destination: FullScreenDestination) {
        presentedFullScreenCover = destination
        AnalyticsManager.shared.trackScreenViewed(destination.analyticsName)
    }
    
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
    // MARK: - Alert Management
    func showAlert(_ alert: AlertItem) {
        showingAlert = alert
    }
    
    func dismissAlert() {
        showingAlert = nil
    }
    
    // MARK: - Deep Linking
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              scheme == Configuration.App.urlScheme else {
            return
        }
        
        let path = components.path
        let queryItems = components.queryItems ?? []
        
        switch path {
        case "/medication":
            if let medicationId = queryItems.first(where: { $0.name == "id" })?.value {
                navigateToMedication(id: medicationId)
            } else {
                selectTab(.myHealth)
            }
            
        case "/doctor":
            if let doctorId = queryItems.first(where: { $0.name == "id" })?.value {
                navigateToDoctor(id: doctorId)
            } else {
                selectTab(.doctorList)
            }
            
        case "/conflicts":
            selectTab(.conflicts)
            
        case "/groups":
            selectTab(.groups)
            
        case "/caregiver-invitation":
            if let invitationCode = queryItems.first(where: { $0.name == "code" })?.value {
                handleCaregiverInvitation(code: invitationCode)
            }
            
        default:
            // Default to MyHealth tab
            selectTab(.myHealth)
        }
    }
    
    private func navigateToMedication(id: String) {
        selectTab(.myHealth)
        navigate(to: .medicationDetail(id: id))
    }
    
    private func navigateToDoctor(id: String) {
        selectTab(.doctorList)
        navigate(to: .doctorDetail(id: id))
    }
    
    private func handleCaregiverInvitation(code: String) {
        presentSheet(.caregiverInvitation(code: code))
    }
    
    // MARK: - Contextual Navigation
    func navigateToAddMedication(with voiceText: String? = nil) {
        selectTab(.myHealth)
        presentSheet(.addMedication(voiceText: voiceText))
    }
    
    func navigateToAddDoctor(with contact: Contact? = nil) {
        selectTab(.doctorList)
        presentSheet(.addDoctor(contact: contact))
    }
    
    func navigateToConflictDetail(conflictId: String) {
        selectTab(.conflicts)
        navigate(to: .conflictDetail(id: conflictId))
    }
    
    func navigateToCaregiverSettings() {
        selectTab(.groups)
        navigate(to: .caregiverSettings)
    }
    
    // MARK: - Authentication Navigation
    func handleAuthenticationRequired() {
        presentFullScreenCover(.authentication)
    }
    
    func handleAuthenticationSuccess() {
        dismissFullScreenCover()
        resetToRootTab()
    }
    
    // MARK: - Error Navigation
    func handleError(_ error: AppError, context: String = "") {
        let alertItem = AlertItem.fromError(error, context: context)
        showAlert(alertItem)
        AnalyticsManager.shared.trackError(error, context: context)
    }
    
    // MARK: - Voice Input Navigation
    func handleVoiceInputResult(_ result: VoiceInputResult) {
        switch result.context {
        case .medicationName:
            navigateToAddMedication(with: result.text)
        case .doctorName:
            navigateToAddDoctor()
        case .general:
            // Handle general voice input
            break
        default:
            break
        }
    }
}

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case medicationDetail(id: String)
    case supplementDetail(id: String)
    case dietEntryDetail(id: String)
    case doctorDetail(id: String)
    case conflictDetail(id: String)
    case caregiverSettings
    case userProfile
    case appSettings
    case privacySettings
    case notificationSettings
    case syncSettings
    case aboutApp
    
    var analyticsName: String {
        switch self {
        case .medicationDetail:
            return "medication_detail"
        case .supplementDetail:
            return "supplement_detail"
        case .dietEntryDetail:
            return "diet_entry_detail"
        case .doctorDetail:
            return "doctor_detail"
        case .conflictDetail:
            return "conflict_detail"
        case .caregiverSettings:
            return "caregiver_settings"
        case .userProfile:
            return "user_profile"
        case .appSettings:
            return "app_settings"
        case .privacySettings:
            return "privacy_settings"
        case .notificationSettings:
            return "notification_settings"
        case .syncSettings:
            return "sync_settings"
        case .aboutApp:
            return "about_app"
        }
    }
}

// MARK: - Sheet Destinations
enum SheetDestination: Identifiable {
    case addMedication(voiceText: String?)
    case editMedication(id: String)
    case addSupplement(voiceText: String?)
    case editSupplement(id: String)
    case addDietEntry(voiceText: String?)
    case editDietEntry(id: String)
    case addDoctor(contact: Contact?)
    case editDoctor(id: String)
    case caregiverInvitation(code: String)
    case inviteCaregiver
    case voiceInput(context: VoiceInputContext)
    case medicationConflictCheck
    case userProfileEdit
    
    var id: String {
        switch self {
        case .addMedication:
            return "add_medication"
        case .editMedication(let id):
            return "edit_medication_\(id)"
        case .addSupplement:
            return "add_supplement"
        case .editSupplement(let id):
            return "edit_supplement_\(id)"
        case .addDietEntry:
            return "add_diet_entry"
        case .editDietEntry(let id):
            return "edit_diet_entry_\(id)"
        case .addDoctor:
            return "add_doctor"
        case .editDoctor(let id):
            return "edit_doctor_\(id)"
        case .caregiverInvitation:
            return "caregiver_invitation"
        case .inviteCaregiver:
            return "invite_caregiver"
        case .voiceInput:
            return "voice_input"
        case .medicationConflictCheck:
            return "medication_conflict_check"
        case .userProfileEdit:
            return "user_profile_edit"
        }
    }
    
    var analyticsName: String {
        switch self {
        case .addMedication:
            return "add_medication_sheet"
        case .editMedication:
            return "edit_medication_sheet"
        case .addSupplement:
            return "add_supplement_sheet"
        case .editSupplement:
            return "edit_supplement_sheet"
        case .addDietEntry:
            return "add_diet_entry_sheet"
        case .editDietEntry:
            return "edit_diet_entry_sheet"
        case .addDoctor:
            return "add_doctor_sheet"
        case .editDoctor:
            return "edit_doctor_sheet"
        case .caregiverInvitation:
            return "caregiver_invitation_sheet"
        case .inviteCaregiver:
            return "invite_caregiver_sheet"
        case .voiceInput:
            return "voice_input_sheet"
        case .medicationConflictCheck:
            return "conflict_check_sheet"
        case .userProfileEdit:
            return "user_profile_edit_sheet"
        }
    }
}

// MARK: - Full Screen Cover Destinations
enum FullScreenDestination: Identifiable {
    case authentication
    case onboarding
    case caregiverOnboarding
    
    var id: String {
        switch self {
        case .authentication:
            return "authentication"
        case .onboarding:
            return "onboarding"
        case .caregiverOnboarding:
            return "caregiver_onboarding"
        }
    }
    
    var analyticsName: String {
        switch self {
        case .authentication:
            return "authentication_screen"
        case .onboarding:
            return "onboarding_screen"
        case .caregiverOnboarding:
            return "caregiver_onboarding_screen"
        }
    }
}

// MARK: - Main Tabs
enum MainTab: String, CaseIterable {
    case myHealth = "myhealth"
    case doctorList = "doctorlist"
    case groups = "groups"
    case conflicts = "conflicts"
    
    var displayName: String {
        switch self {
        case .myHealth:
            return AppStrings.Tabs.myHealth
        case .doctorList:
            return AppStrings.Tabs.doctorList
        case .groups:
            return AppStrings.Tabs.groups
        case .conflicts:
            return AppStrings.Tabs.conflicts
        }
    }
    
    var icon: String {
        switch self {
        case .myHealth:
            return AppIcons.myHealth
        case .doctorList:
            return AppIcons.doctorList
        case .groups:
            return AppIcons.groups
        case .conflicts:
            return AppIcons.conflicts
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .myHealth:
            return AppIcons.myHealthFilled
        case .doctorList:
            return AppIcons.doctorListFilled
        case .groups:
            return AppIcons.groupsFilled
        case .conflicts:
            return AppIcons.conflictsFilled
        }
    }
    
    var analyticsName: String {
        switch self {
        case .myHealth:
            return "my_health_tab"
        case .doctorList:
            return "doctor_list_tab"
        case .groups:
            return "groups_tab"
        case .conflicts:
            return "conflicts_tab"
        }
    }
}

// MARK: - Alert Management
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButton: AlertButton?
    let secondaryButton: AlertButton?
    
    static func fromError(_ error: AppError, context: String = "") -> AlertItem {
        return AlertItem(
            title: AppStrings.Errors.title,
            message: error.localizedDescription,
            primaryButton: AlertButton(
                title: AppStrings.Common.ok,
                action: {}
            ),
            secondaryButton: nil
        )
    }
    
    static func confirmation(
        title: String,
        message: String,
        confirmTitle: String = AppStrings.Common.confirm,
        cancelTitle: String = AppStrings.Common.cancel,
        confirmAction: @escaping () -> Void
    ) -> AlertItem {
        return AlertItem(
            title: title,
            message: message,
            primaryButton: AlertButton(
                title: confirmTitle,
                action: confirmAction
            ),
            secondaryButton: AlertButton(
                title: cancelTitle,
                action: {}
            )
        )
    }
}

struct AlertButton {
    let title: String
    let action: () -> Void
}

// MARK: - Voice Input Result
struct VoiceInputResult {
    let text: String
    let context: VoiceInputContext
    let confidence: Float
}

// MARK: - Contact Model (for doctor import)
struct Contact {
    let id: String
    let name: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let organization: String?
}

// MARK: - Navigation Extensions
extension NavigationManager {
    func canNavigateBack() -> Bool {
        return !navigationPath.isEmpty
    }
    
    func getNavigationDepth() -> Int {
        return navigationPath.count
    }
    
    func getCurrentDestination() -> NavigationDestination? {
        // This would need to be implemented based on the current navigation path
        return nil
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension NavigationManager {
    static let mockNavigationManager: NavigationManager = {
        let manager = NavigationManager()
        manager.selectedTab = .myHealth
        return manager
    }()
}
#endif