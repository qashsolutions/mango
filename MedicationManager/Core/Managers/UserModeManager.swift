import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Notification Names
extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}

// MARK: - User Mode
enum UserMode: String, Codable {
    case primaryUser = "primary"
    case caregiver = "caregiver"
    case familyMember = "family"
    
    var displayName: String {
        switch self {
        case .primaryUser:
            return AppStrings.UserMode.primaryUser
        case .caregiver:
            return AppStrings.UserMode.caregiver
        case .familyMember:
            return AppStrings.UserMode.familyMember
        }
    }
    
    var canEditData: Bool {
        self == .primaryUser
    }
    
    var canCompleteTasks: Bool {
        self == .primaryUser || self == .caregiver
    }
    
    var canViewHistory: Bool {
        true // All modes can view history
    }
    
    var visibleDays: Int {
        switch self {
        case .primaryUser:
            return 7 // Can see a week ahead
        case .caregiver, .familyMember:
            return 1 // Only today
        }
    }
    
    var availableTabs: [MainTab] {
        switch self {
        case .primaryUser:
            return MainTab.allCases
        case .caregiver:
            return [.myHealth, .doctorList] // Limited tabs
        case .familyMember:
            return [.myHealth] // View only
        }
    }
}

// MARK: - User Mode Manager
@MainActor
@Observable
final class UserModeManager {
    static let shared = UserModeManager()
    
    // Current user state
    var currentMode: UserMode = .primaryUser
    var primaryUserId: String?
    var caregiverInfo: CaregiverInfo?
    var permissions: [Permission] = []
    var isLoading = false
    
    // Restrictions
    var canEdit: Bool { currentMode.canEditData }
    var canCompleteTasks: Bool { currentMode.canCompleteTasks }
    var visibleDays: Int { currentMode.visibleDays }
    var availableTabs: [MainTab] { currentMode.availableTabs }
    
    // Dependencies
    private let firebaseManager = FirebaseManager.shared
    private let firestore = Firestore.firestore()
    private let analyticsManager = AnalyticsManager.shared
    
    private init() {
        observeAuthChanges()
    }
    
    // MARK: - Auth Observation
    
    private func observeAuthChanges() {
        Task {
            // Monitor auth state changes
            for await _ in NotificationCenter.default.notifications(named: .authStateDidChange) {
                await determineUserMode()
            }
        }
    }
    
    // MARK: - User Mode Determination
    
    func determineUserMode() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let currentUser = firebaseManager.currentUser else {
            currentMode = .primaryUser
            primaryUserId = nil
            caregiverInfo = nil
            permissions = []
            return
        }
        
        do {
            // First, check if user is a primary user (has their own data)
            let userDoc = try await firestore
                .collection("users")
                .document(currentUser.id ?? "")
                .getDocument()
            
            if userDoc.exists {
                // This is a primary user
                currentMode = .primaryUser
                primaryUserId = currentUser.id
                caregiverInfo = nil
                permissions = Permission.allCases // Full permissions
                
                analyticsManager.trackEvent(
                    "user_mode_determined",
                    parameters: ["mode": "primary"]
                )
                return
            }
            
            // Not a primary user, check if they're a caregiver
            let caregiverQuery = try await firestore
                .collectionGroup("caregivers")
                .whereField("caregiverId", isEqualTo: currentUser.id ?? "")
                .whereField("isActive", isEqualTo: true)
                .limit(to: 1)
                .getDocuments()
            
            if let caregiverDoc = caregiverQuery.documents.first,
               let caregiver = try? caregiverDoc.data(as: CaregiverInfo.self) {
                // This is a caregiver
                currentMode = .caregiver
                primaryUserId = caregiverDoc.reference.parent.parent?.documentID
                caregiverInfo = caregiver
                permissions = caregiver.permissions
                
                analyticsManager.trackEvent(
                    "user_mode_determined",
                    parameters: [
                        "mode": "caregiver",
                        "has_task_permission": caregiver.permissions.contains(.myhealth)
                    ]
                )
                return
            }
            
            // Check if they're a family member (read-only access)
            // For now, default to family member if not primary or caregiver
            currentMode = .familyMember
            permissions = [.myhealth] // Read-only access
            
            analyticsManager.trackEvent(
                "user_mode_determined",
                parameters: ["mode": "family"]
            )
            
        } catch {
            print("Error determining user mode: \(error)")
            // Default to most restrictive mode on error
            currentMode = .familyMember
            permissions = []
        }
    }
    
    // MARK: - Permission Checking
    
    func hasPermission(_ permission: Permission) -> Bool {
        if currentMode == .primaryUser {
            return true // Primary users have all permissions
        }
        return permissions.contains(permission)
    }
    
    func canAccessTab(_ tab: MainTab) -> Bool {
        availableTabs.contains(tab)
    }
    
    func canViewDate(_ date: Date) -> Bool {
        if currentMode == .primaryUser {
            return true // No date restrictions
        }
        
        // Caregivers and family can only see today
        return Calendar.current.isDateInToday(date)
    }
    
    func canEditMedication(_ medication: MedicationModel) -> Bool {
        currentMode == .primaryUser
    }
    
    func canCompleteTask(_ task: CaregiverTask) -> Bool {
        switch currentMode {
        case .primaryUser:
            return true
        case .caregiver:
            // Can complete if assigned to them or unassigned
            return task.assignedTo == nil || 
                   task.assignedTo == firebaseManager.currentUser?.id
        case .familyMember:
            return false
        }
    }
    
    // MARK: - View Modifiers
    
    func restrictedDateRange(from date: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch currentMode {
        case .primaryUser:
            // Can see past 30 days to future 30 days
            guard let start = calendar.date(byAdding: .day, value: -30, to: today),
                  let end = calendar.date(byAdding: .day, value: 30, to: today) else {
                // Fallback to today if date calculation fails
                return today...today
            }
            return start...end
            
        case .caregiver, .familyMember:
            // Only today
            return today...today
        }
    }
    
    // MARK: - UI Helpers
    
    func shouldShowEditButton(for view: String) -> Bool {
        currentMode == .primaryUser
    }
    
    func shouldShowAddButton() -> Bool {
        currentMode == .primaryUser
    }
    
    func shouldShowTaskCompletionButton() -> Bool {
        currentMode == .primaryUser || currentMode == .caregiver
    }
    
    func getWelcomeMessage() -> String {
        switch currentMode {
        case .primaryUser:
            return AppStrings.UserMode.welcomePrimary
        case .caregiver:
            return String(
                format: AppStrings.UserMode.welcomeCaregiver,
                caregiverInfo?.displayName ?? ""
            )
        case .familyMember:
            return AppStrings.UserMode.welcomeFamily
        }
    }
    
    // MARK: - Navigation Restrictions
    
    func filterNavigationDestinations(_ destinations: [NavigationDestination]) -> [NavigationDestination] {
        destinations.filter { destination in
            switch destination {
            case .medicationDetail, .supplementDetail, .dietEntryDetail, .doctorDetail:
                return hasPermission(.myhealth)
            case .conflictDetail:
                return hasPermission(.conflicts)
            case .caregiverSettings:
                return currentMode == .primaryUser
            default:
                return true
            }
        }
    }
    
    func filterSheetDestinations(_ destinations: [SheetDestination]) -> [SheetDestination] {
        guard currentMode != .primaryUser else {
            return destinations // Primary users can access everything
        }
        
        return destinations.filter { destination in
            switch destination {
            case .addMedication, .editMedication,
                 .addSupplement, .editSupplement,
                 .addDietEntry, .editDietEntry,
                 .addDoctor, .editDoctor:
                return false // Only primary users can add/edit
                
            case .medicationConflictCheck:
                return hasPermission(.conflicts)
                
            case .voiceInput:
                return currentMode == .primaryUser
                
            default:
                return true
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func restrictedToUserMode(_ allowedModes: UserMode...) -> some View {
        self.modifier(UserModeRestriction(allowedModes: allowedModes))
    }
    
    func hiddenForCaregiver() -> some View {
        self.modifier(UserModeRestriction(allowedModes: [.primaryUser, .familyMember]))
    }
    
    func primaryUserOnly() -> some View {
        self.modifier(UserModeRestriction(allowedModes: [.primaryUser]))
    }
}

// MARK: - User Mode Restriction Modifier
struct UserModeRestriction: ViewModifier {
    let allowedModes: [UserMode]
    @State private var userModeManager = UserModeManager.shared
    
    func body(content: Content) -> some View {
        if allowedModes.contains(userModeManager.currentMode) {
            content
        } else {
            EmptyView()
        }
    }
}
