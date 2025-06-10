import Foundation
import FirebaseAnalytics

@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var isEnabled: Bool = true
    @Published var usageStats: UsageStats = UsageStats()
    
    private let userDefaults = UserDefaults.standard
    private let analyticsEnabledKey = "analytics_enabled"
    
    private init() {
        isEnabled = userDefaults.bool(forKey: analyticsEnabledKey)
        if userDefaults.object(forKey: analyticsEnabledKey) == nil {
            // First time launch - enable by default
            isEnabled = true
            userDefaults.set(true, forKey: analyticsEnabledKey)
        }
        
        updateAnalyticsCollection()
    }
    
    // MARK: - Analytics Control
    func enableAnalytics() {
        isEnabled = true
        userDefaults.set(true, forKey: analyticsEnabledKey)
        updateAnalyticsCollection()
    }
    
    func disableAnalytics() {
        isEnabled = false
        userDefaults.set(false, forKey: analyticsEnabledKey)
        updateAnalyticsCollection()
    }
    
    private func updateAnalyticsCollection() {
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
    }
    
    // MARK: - User Events
    func trackUserLogin(_ method: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
        
        usageStats.incrementLoginCount()
    }
    
    func trackUserSignup(_ method: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    func trackUserLogout() {
        guard isEnabled else { return }
        
        Analytics.logEvent("user_logout", parameters: [:])
    }
    
    // MARK: - Medication Events
    func trackMedicationAdded(method: String, hasVoiceInput: Bool = false) {
        guard isEnabled else { return }
        
        Analytics.logEvent("medication_added", parameters: [
            "input_method": method,
            "voice_input_used": hasVoiceInput
        ])
        
        usageStats.incrementMedicationCount()
        if hasVoiceInput {
            usageStats.incrementVoiceInputUsage()
        }
    }
    
    func trackMedicationUpdated(field: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("medication_updated", parameters: [
            "field_updated": field
        ])
    }
    
    func trackMedicationDeleted() {
        guard isEnabled else { return }
        
        Analytics.logEvent("medication_deleted", parameters: [:])
        usageStats.decrementMedicationCount()
    }
    
    func trackMedicationTaken(onTime: Bool) {
        guard isEnabled else { return }
        
        Analytics.logEvent("medication_taken", parameters: [
            "on_time": onTime
        ])
        
        usageStats.incrementMedicationTaken()
        if onTime {
            usageStats.incrementOnTimeTaken()
        }
    }
    
    // MARK: - Supplement Events
    func trackSupplementAdded(method: String, hasVoiceInput: Bool = false) {
        guard isEnabled else { return }
        
        Analytics.logEvent("supplement_added", parameters: [
            "input_method": method,
            "voice_input_used": hasVoiceInput
        ])
        
        usageStats.incrementSupplementCount()
        if hasVoiceInput {
            usageStats.incrementVoiceInputUsage()
        }
    }
    
    func trackSupplementTaken(onTime: Bool) {
        guard isEnabled else { return }
        
        Analytics.logEvent("supplement_taken", parameters: [
            "on_time": onTime
        ])
        
        usageStats.incrementSupplementTaken()
    }
    
    // MARK: - Diet Events
    func trackDietEntryAdded(mealType: String, hasVoiceInput: Bool = false) {
        guard isEnabled else { return }
        
        Analytics.logEvent("diet_entry_added", parameters: [
            "meal_type": mealType,
            "voice_input_used": hasVoiceInput
        ])
        
        usageStats.incrementDietEntryCount()
        if hasVoiceInput {
            usageStats.incrementVoiceInputUsage()
        }
    }
    
    func trackMealLogged(mealType: String, onTime: Bool) {
        guard isEnabled else { return }
        
        Analytics.logEvent("meal_logged", parameters: [
            "meal_type": mealType,
            "on_time": onTime
        ])
    }
    
    // MARK: - Doctor Events
    func trackDoctorAdded(method: String, fromContacts: Bool = false) {
        guard isEnabled else { return }
        
        Analytics.logEvent("doctor_added", parameters: [
            "input_method": method,
            "from_contacts": fromContacts
        ])
        
        usageStats.incrementDoctorCount()
    }
    
    func trackDoctorContacted(method: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("doctor_contacted", parameters: [
            "contact_method": method
        ])
    }
    
    // MARK: - Conflict Events
    func trackConflictCheck(source: String, conflictsFound: Bool, severity: String?) {
        guard isEnabled else { return }
        
        var parameters: [String: Any] = [
            "source": source,
            "conflicts_found": conflictsFound
        ]
        
        if let severity = severity {
            parameters["highest_severity"] = severity
        }
        
        Analytics.logEvent("conflict_check", parameters: parameters)
        
        usageStats.incrementConflictCheck()
        if conflictsFound {
            usageStats.incrementConflictsFound()
        }
    }
    
    func trackConflictResolved(severity: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("conflict_resolved", parameters: [
            "severity": severity
        ])
    }
    
    // MARK: - Voice Input Events
    func trackVoiceInputStarted(context: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("voice_input_started", parameters: [
            "context": context
        ])
    }
    
    func trackVoiceInputCompleted(context: String, success: Bool, duration: TimeInterval) {
        guard isEnabled else { return }
        
        Analytics.logEvent("voice_input_completed", parameters: [
            "context": context,
            "success": success,
            "duration_seconds": Int(duration)
        ])
        
        if success {
            usageStats.incrementVoiceInputUsage()
        }
    }
    
    func trackVoiceInputError(context: String, errorType: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("voice_input_error", parameters: [
            "context": context,
            "error_type": errorType
        ])
    }
    
    // MARK: - Caregiver Events
    func trackCaregiverInvited() {
        guard isEnabled else { return }
        
        Analytics.logEvent("caregiver_invited", parameters: [:])
    }
    
    func trackCaregiverAccessEnabled() {
        guard isEnabled else { return }
        
        Analytics.logEvent("caregiver_access_enabled", parameters: [:])
    }
    
    func trackCaregiverPermissionChanged(permission: String, granted: Bool) {
        guard isEnabled else { return }
        
        Analytics.logEvent("caregiver_permission_changed", parameters: [
            "permission": permission,
            "granted": granted
        ])
    }
    
    // MARK: - Navigation Events
    func trackScreenViewed(_ screenName: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
        
        usageStats.incrementScreenView(screenName)
    }
    
    func trackFeatureUsed(_ featureName: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("feature_used", parameters: [
            "feature_name": featureName
        ])
        
        usageStats.incrementFeatureUsage(featureName)
    }
    
    // MARK: - Sync Events
    func trackSyncStarted(type: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("sync_started", parameters: [
            "sync_type": type
        ])
    }
    
    func trackSyncCompleted(type: String, success: Bool, duration: TimeInterval) {
        guard isEnabled else { return }
        
        Analytics.logEvent("sync_completed", parameters: [
            "sync_type": type,
            "success": success,
            "duration_seconds": Int(duration)
        ])
        
        if success {
            usageStats.incrementSuccessfulSync()
        }
    }
    
    // MARK: - Error Events
    func trackError(_ error: AppError, context: String) {
        guard isEnabled else { return }
        
        Analytics.logEvent("app_error", parameters: [
            "error_type": error.category,
            "error_code": error.code,
            "context": context
        ])
    }
    
    // MARK: - Performance Events
    func trackAppLaunchTime(_ duration: TimeInterval) {
        guard isEnabled else { return }
        
        Analytics.logEvent("app_launch", parameters: [
            "launch_duration_ms": Int(duration * 1000)
        ])
    }
    
    func trackDatabaseSize(_ sizeInBytes: Int64) {
        guard isEnabled else { return }
        
        Analytics.logEvent("database_size", parameters: [
            "size_bytes": Int(sizeInBytes)
        ])
    }
    
    // MARK: - Custom User Properties
    func setUserProperty(_ value: String?, forName name: String) {
        guard isEnabled else { return }
        
        Analytics.setUserProperty(value, forName: name)
    }
    
    func setUserID(_ userID: String?) {
        guard isEnabled else { return }
        
        Analytics.setUserID(userID)
    }
    
    // MARK: - Usage Statistics
    func updateUsageStats(_ stats: UsageStats) {
        usageStats = stats
    }
    
    func getUsageStats() -> UsageStats {
        return usageStats
    }
    
    func resetUsageStats() {
        usageStats = UsageStats()
    }
}

// MARK: - Usage Statistics Model
struct UsageStats: Codable {
    var totalLogins: Int = 0
    var medicationsAdded: Int = 0
    var supplementsAdded: Int = 0
    var dietEntriesAdded: Int = 0
    var doctorsAdded: Int = 0
    var voiceInputUsages: Int = 0
    var conflictChecks: Int = 0
    var conflictsFound: Int = 0
    var medicationsTaken: Int = 0
    var onTimeTaken: Int = 0
    var supplementsTaken: Int = 0
    var successfulSyncs: Int = 0
    var screenViews: [String: Int] = [:]
    var featureUsage: [String: Int] = [:]
    var lastUpdated: Date = Date()
    
    // MARK: - Statistics Methods
    mutating func incrementLoginCount() {
        totalLogins += 1
        lastUpdated = Date()
    }
    
    mutating func incrementMedicationCount() {
        medicationsAdded += 1
        lastUpdated = Date()
    }
    
    mutating func decrementMedicationCount() {
        if medicationsAdded > 0 {
            medicationsAdded -= 1
        }
        lastUpdated = Date()
    }
    
    mutating func incrementSupplementCount() {
        supplementsAdded += 1
        lastUpdated = Date()
    }
    
    mutating func incrementDietEntryCount() {
        dietEntriesAdded += 1
        lastUpdated = Date()
    }
    
    mutating func incrementDoctorCount() {
        doctorsAdded += 1
        lastUpdated = Date()
    }
    
    mutating func incrementVoiceInputUsage() {
        voiceInputUsages += 1
        lastUpdated = Date()
    }
    
    mutating func incrementConflictCheck() {
        conflictChecks += 1
        lastUpdated = Date()
    }
    
    mutating func incrementConflictsFound() {
        conflictsFound += 1
        lastUpdated = Date()
    }
    
    mutating func incrementMedicationTaken() {
        medicationsTaken += 1
        lastUpdated = Date()
    }
    
    mutating func incrementOnTimeTaken() {
        onTimeTaken += 1
        lastUpdated = Date()
    }
    
    mutating func incrementSupplementTaken() {
        supplementsTaken += 1
        lastUpdated = Date()
    }
    
    mutating func incrementSuccessfulSync() {
        successfulSyncs += 1
        lastUpdated = Date()
    }
    
    mutating func incrementScreenView(_ screenName: String) {
        screenViews[screenName, default: 0] += 1
        lastUpdated = Date()
    }
    
    mutating func incrementFeatureUsage(_ featureName: String) {
        featureUsage[featureName, default: 0] += 1
        lastUpdated = Date()
    }
    
    // MARK: - Computed Properties
    var adherenceRate: Double {
        guard medicationsTaken > 0 else { return 0.0 }
        return Double(onTimeTaken) / Double(medicationsTaken)
    }
    
    var voiceInputAdoptionRate: Double {
        let totalEntries = medicationsAdded + supplementsAdded + dietEntriesAdded
        guard totalEntries > 0 else { return 0.0 }
        return Double(voiceInputUsages) / Double(totalEntries)
    }
    
    var conflictDetectionRate: Double {
        guard conflictChecks > 0 else { return 0.0 }
        return Double(conflictsFound) / Double(conflictChecks)
    }
    
    var mostUsedScreen: String? {
        return screenViews.max(by: { $0.value < $1.value })?.key
    }
    
    var mostUsedFeature: String? {
        return featureUsage.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - App Error Extensions
extension AppError {
    var category: String {
        switch self {
        case .authentication:
            return "authentication"
        case .network:
            return "network"
        case .data:
            return "data"
        case .voice:
            return "voice"
        case .sync:
            return "sync"
        case .caregiver:
            return "caregiver"
        case .caregiverAccessError:
            return "caregiverAccess"
        case .subscription:
            return "subscription"
        }
    }
    
    var code: String {
        switch self {
        case .authentication(let authError):
            return "auth_\(authError)"
        case .network(let networkError):
            return "network_\(networkError)"
        case .data(let dataError):
            return "data_\(dataError)"
        case .voice(let voiceError):
            return "voice_\(voiceError)"
        case .sync(let syncError):
            return "sync_\(syncError)"
        case .caregiver(let caregiverError):
            return "caregiver_\(caregiverError)"
        case .caregiverAccessError(let caregiverAccessError):
            return "caregiverAccess_\(caregiverAccessError)"
        case .subscription(let subscriptionError):
            return "subscription_\(subscriptionError)"
        }
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension AnalyticsManager {
    static let mockAnalyticsManager: AnalyticsManager = {
        let manager = AnalyticsManager()
        manager.usageStats = UsageStats(
            totalLogins: 25,
            medicationsAdded: 8,
            supplementsAdded: 4,
            dietEntriesAdded: 15,
            doctorsAdded: 3,
            voiceInputUsages: 12,
            conflictChecks: 6,
            conflictsFound: 2,
            medicationsTaken: 45,
            onTimeTaken: 38,
            supplementsTaken: 20,
            successfulSyncs: 18,
            screenViews: ["MyHealth": 45, "DoctorList": 12, "Groups": 8, "Conflicts": 6],
            featureUsage: ["VoiceInput": 12, "ConflictCheck": 6, "CaregiverAccess": 3],
            lastUpdated: Date()
        )
        return manager
    }()
}

extension UsageStats {
    static let sampleStats = UsageStats(
        totalLogins: 25,
        medicationsAdded: 8,
        supplementsAdded: 4,
        dietEntriesAdded: 15,
        doctorsAdded: 3,
        voiceInputUsages: 12,
        conflictChecks: 6,
        conflictsFound: 2,
        medicationsTaken: 45,
        onTimeTaken: 38,
        supplementsTaken: 20,
        successfulSyncs: 18,
        screenViews: ["MyHealth": 45, "DoctorList": 12, "Groups": 8, "Conflicts": 6],
        featureUsage: ["VoiceInput": 12, "ConflictCheck": 6, "CaregiverAccess": 3],
        lastUpdated: Date()
    )
}
#endif
