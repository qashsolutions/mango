@preconcurrency import UserNotifications
import SwiftUI
import FirebaseMessaging

@MainActor
@Observable
final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    // Notification state
    var isAuthorized = false
    var fcmToken: String?
    var pendingNotifications: [UNNotificationRequest] = []
    
    // Error handling
    var lastError: Error?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        notificationCenter.delegate = self
        checkAuthorizationStatus()
        
        // Configure Firebase Messaging
        Messaging.messaging().delegate = self
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )
            
            isAuthorized = granted
            
            if granted {
                await registerForRemoteNotifications()
                
                // Track analytics
                AnalyticsManager.shared.trackEvent(
                    "notification_permission_granted",
                    parameters: [:]
                )
            } else {
                AnalyticsManager.shared.trackEvent(
                    "notification_permission_denied",
                    parameters: [:]
                )
            }
            
            return granted
        } catch {
            lastError = error
            let appError = error as? AppError ?? AppError.data(.unknown)
            AnalyticsManager.shared.trackError(
                appError,
                context: "NotificationManager.requestAuthorization"
            )
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Medication Reminders
    
    func scheduleMedicationReminder(
        medication: MedicationModel,
        times: [Date]
    ) async throws {
        guard isAuthorized else {
            throw AppError.notificationPermissionDenied
        }
        
        // Cancel existing reminders for this medication
        await cancelMedicationReminders(medicationId: medication.id)
        
        // Schedule new reminders
        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = AppStrings.Notifications.medicationReminderTitle
            content.body = String(
                format: AppStrings.Notifications.medicationReminderBody,
                medication.name,
                medication.dosage
            )
            content.sound = .default
            content.categoryIdentifier = NotificationCategory.medicationReminder.rawValue
            content.userInfo = [
                "medicationId": medication.id,
                "medicationName": medication.name,
                "dosage": medication.dosage,
                "type": "medication_reminder"
            ]
            
            // Add action buttons
            content.categoryIdentifier = NotificationCategory.medicationReminder.rawValue
            
            // Create trigger
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
            
            // Create request
            let identifier = "\(medication.id)_\(index)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            try await notificationCenter.add(request)
        }
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(
            "medication_reminder_scheduled",
            parameters: [
                "medication_id": medication.id,
                "reminder_count": times.count
            ]
        )
    }
    
    func cancelMedicationReminders(medicationId: String) async {
        let identifiers = await getPendingNotificationIdentifiers()
        let medicationIdentifiers = identifiers.filter { $0.hasPrefix(medicationId) }
        
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: medicationIdentifiers
        )
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(
            "medication_reminder_cancelled",
            parameters: ["medication_id": medicationId]
        )
    }
    
    // MARK: - Conflict Alerts
    
    func sendConflictAlert(
        conflict: MedicationConflict,
        medications: [String]
    ) async throws {
        guard isAuthorized else {
            throw AppError.notificationPermissionDenied
        }
        
        let content = UNMutableNotificationContent()
        content.title = AppStrings.Notifications.conflictAlertTitle
        content.body = String(
            format: AppStrings.Notifications.conflictAlertBody,
            medications.joined(separator: ", ")
        )
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        content.categoryIdentifier = NotificationCategory.conflictAlert.rawValue
        content.userInfo = [
            "conflictId": conflict.id,
            "severity": conflict.severity?.rawValue ?? "unknown",
            "type": "conflict_alert"
        ]
        
        // Immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "conflict_\(conflict.id)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(
            "conflict_alert_sent",
            parameters: [
                "conflict_id": conflict.id,
                "severity": conflict.severity?.rawValue ?? "unknown"
            ]
        )
    }
    
    // MARK: - Caregiver Notifications
    
    func sendCaregiverAlert(
        message: String,
        caregiverId: String
    ) async throws {
        guard isAuthorized else {
            throw AppError.notificationPermissionDenied
        }
        
        let content = UNMutableNotificationContent()
        content.title = AppStrings.Notifications.caregiverAlertTitle
        content.body = message
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.caregiverAlert.rawValue
        content.userInfo = [
            "caregiverId": caregiverId,
            "type": "caregiver_alert"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "caregiver_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Utility Methods
    
    nonisolated func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    private func getPendingNotificationIdentifiers() async -> [String] {
        let requests = await getPendingNotifications()
        return requests.map { $0.identifier }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        AnalyticsManager.shared.trackEvent(
            "all_notifications_cancelled",
            parameters: [:]
        )
    }
    
    func updateBadgeCount(_ count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {
            // Error setting badge count
            lastError = error
        }
    }
    
    // MARK: - Notification Categories
    
    func registerNotificationCategories() {
        let categories: Set<UNNotificationCategory> = [
            createMedicationReminderCategory(),
            createConflictAlertCategory(),
            createCaregiverAlertCategory()
        ]
        
        notificationCenter.setNotificationCategories(categories)
    }
    
    private func createMedicationReminderCategory() -> UNNotificationCategory {
        let takeAction = UNNotificationAction(
            identifier: NotificationAction.takeMedication.rawValue,
            title: AppStrings.Notifications.actionTake,
            options: [.authenticationRequired]
        )
        
        let skipAction = UNNotificationAction(
            identifier: NotificationAction.skipMedication.rawValue,
            title: AppStrings.Notifications.actionSkip,
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snoozeMedication.rawValue,
            title: AppStrings.Notifications.actionSnooze,
            options: []
        )
        
        return UNNotificationCategory(
            identifier: NotificationCategory.medicationReminder.rawValue,
            actions: [takeAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }
    
    private func createConflictAlertCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: NotificationAction.viewConflict.rawValue,
            title: AppStrings.Notifications.actionView,
            options: [.foreground]
        )
        
        return UNNotificationCategory(
            identifier: NotificationCategory.conflictAlert.rawValue,
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    private func createCaregiverAlertCategory() -> UNNotificationCategory {
        let replyAction = UNTextInputNotificationAction(
            identifier: NotificationAction.replyToCaregiver.rawValue,
            title: AppStrings.Notifications.actionReply,
            options: [],
            textInputButtonTitle: AppStrings.Common.send,
            textInputPlaceholder: AppStrings.Notifications.replyPlaceholder
        )
        
        return UNNotificationCategory(
            identifier: NotificationCategory.caregiverAlert.rawValue,
            actions: [replyAction],
            intentIdentifiers: [],
            options: []
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await handleNotificationResponse(response)
        }
        completionHandler()
    }
    
    @MainActor
    private func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case NotificationAction.takeMedication.rawValue:
            if let medicationId = userInfo["medicationId"] as? String {
                await handleTakeMedication(medicationId: medicationId)
            }
            
        case NotificationAction.skipMedication.rawValue:
            if let medicationId = userInfo["medicationId"] as? String {
                await handleSkipMedication(medicationId: medicationId)
            }
            
        case NotificationAction.snoozeMedication.rawValue:
            if let medicationId = userInfo["medicationId"] as? String {
                await handleSnoozeMedication(medicationId: medicationId)
            }
            
        case NotificationAction.viewConflict.rawValue:
            if let conflictId = userInfo["conflictId"] as? String {
                handleViewConflict(conflictId: conflictId)
            }
            
        case NotificationAction.replyToCaregiver.rawValue:
            if let textResponse = response as? UNTextInputNotificationResponse,
               let caregiverId = userInfo["caregiverId"] as? String {
                await handleCaregiverReply(
                    message: textResponse.userText,
                    caregiverId: caregiverId
                )
            }
            
        default:
            // Handle tap on notification
            handleDefaultAction(userInfo: userInfo)
        }
    }
    
    private func handleTakeMedication(medicationId: String) async {
        // Log medication as taken
        // This would integrate with your medication tracking system
        AnalyticsManager.shared.trackEvent(
            "medication_taken_from_notification",
            parameters: ["medication_id": medicationId]
        )
    }
    
    private func handleSkipMedication(medicationId: String) async {
        // Log medication as skipped
        AnalyticsManager.shared.trackEvent(
            "medication_skipped_from_notification",
            parameters: ["medication_id": medicationId]
        )
    }
    
    private func handleSnoozeMedication(medicationId: String) async {
        // Reschedule notification for 10 minutes later
        // Implementation would reschedule the specific reminder
        AnalyticsManager.shared.trackEvent(
            "medication_snoozed_from_notification",
            parameters: ["medication_id": medicationId]
        )
    }
    
    private func handleViewConflict(conflictId: String) {
        // Navigate to conflict details
        NavigationManager.shared.navigateToConflictDetail(conflictId: conflictId)
    }
    
    private func handleCaregiverReply(message: String, caregiverId: String) async {
        // Send reply to caregiver
        AnalyticsManager.shared.trackEvent(
            "caregiver_reply_sent",
            parameters: ["caregiver_id": caregiverId]
        )
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        if let type = userInfo["type"] as? String {
            switch type {
            case "medication_reminder":
                NavigationManager.shared.selectTab(.myHealth)
            case "conflict_alert":
                NavigationManager.shared.selectTab(.conflicts)
            case "caregiver_alert":
                NavigationManager.shared.selectTab(.groups)
            default:
                break
            }
        }
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.fcmToken = fcmToken
            
            if let token = fcmToken {
                // Save FCM token to user profile
                await saveFCMToken(token)
            }
        }
    }
    
    @MainActor
    private func saveFCMToken(_ token: String) async {
        // Save token to Firebase for this user
        // This would integrate with your user profile system
        AnalyticsManager.shared.trackEvent(
            "fcm_token_received",
            parameters: [:]
        )
    }
}

// MARK: - Notification Enums
enum NotificationCategory: String {
    case medicationReminder = "MEDICATION_REMINDER"
    case conflictAlert = "CONFLICT_ALERT"
    case caregiverAlert = "CAREGIVER_ALERT"
}

enum NotificationAction: String {
    case takeMedication = "TAKE_MEDICATION"
    case skipMedication = "SKIP_MEDICATION"
    case snoozeMedication = "SNOOZE_MEDICATION"
    case viewConflict = "VIEW_CONFLICT"
    case replyToCaregiver = "REPLY_TO_CAREGIVER"
}

// MARK: - App Error Extension
extension AppError {
    static let notificationPermissionDenied = AppError.data(.validationFailed)
}
