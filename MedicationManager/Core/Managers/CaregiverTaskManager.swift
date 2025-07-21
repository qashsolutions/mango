import SwiftUI
import FirebaseFirestore
import UserNotifications

@MainActor
@Observable
final class CaregiverTaskManager {
    static let shared = CaregiverTaskManager()
    
    // Task state
    var todayTasks: [CaregiverTask] = []
    var upcomingTasks: [CaregiverTask] = []
    var completedTasks: [CaregiverTask] = []
    var isLoading = false
    var lastError: Error?
    
    // Dependencies
    private let firestore = Firestore.firestore()
    private let coreDataManager = CoreDataManager.shared
    private let notificationManager = NotificationManager.shared
    private let firebaseManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    private init() {}
    
    // MARK: - Task Creation

    func createTask(_ task: CaregiverTask) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Save to Firestore using Codable with completion handler
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try firestore
                        .collection("users")
                        .document(task.primaryUserId)
                        .collection("caregiverTasks")
                        .document(task.id)
                        .setData(from: task) { error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            // Schedule notification
            await scheduleTaskNotification(task)

            // Update local state
            if Calendar.current.isDateInToday(task.scheduledTime) {
                todayTasks.append(task)
                todayTasks.sort { $0.scheduledTime < $1.scheduledTime }
            } else {
                upcomingTasks.append(task)
                upcomingTasks.sort { $0.scheduledTime < $1.scheduledTime }
            }

            // Track analytics
            analyticsManager.trackEvent( // Removed 'await' here
                "caregiver_task_created",
                parameters: [
                    "task_type": task.type.rawValue,
                    "has_caregiver": task.assignedTo != nil
                ]
            )
        } catch {
            lastError = error
            throw error
        }
    }
    // MARK: - Task Loading
    
    func loadTasks(for userId: String, date: Date = Date()) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw AppError.data(.invalidDate)
        }
        
        do {
            let snapshot = try await firestore
                .collection("users")
                .document(userId)
                .collection("caregiverTasks")
                .whereField("scheduledTime", isGreaterThanOrEqualTo: startOfDay)
                .whereField("scheduledTime", isLessThan: endOfDay)
                .order(by: "scheduledTime")
                .getDocuments()
            
            let tasks = try snapshot.documents.compactMap { document in
                try document.data(as: CaregiverTask.self)
            }
            
            // Separate by completion status
            todayTasks = tasks.filter { !$0.isCompleted }
            completedTasks = tasks.filter { $0.isCompleted }
            
            // Track analytics
            analyticsManager.trackEvent(
                "caregiver_tasks_loaded",
                parameters: [
                    "task_count": tasks.count,
                    "completed_count": completedTasks.count
                ]
            )
        } catch {
            lastError = error
            throw error
        }
    }
    
    // MARK: - Task Completion
    
    func completeTask(
        _ task: CaregiverTask,
        completedBy caregiverId: String,
        caregiverName: String,
        note: String? = nil
    ) async throws {
        var updatedTask = task
        updatedTask.isCompleted = true
        updatedTask.completedBy = caregiverId
        updatedTask.completedByName = caregiverName
        updatedTask.completedAt = Date()
        updatedTask.completionNote = note
        updatedTask.lastModified = Date()
        
        do {
            // Update Firestore using Codable with completion handler
            let taskRef = firestore
                .collection("users")
                .document(task.primaryUserId)
                .collection("caregiverTasks")
                .document(task.id)
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try taskRef.setData(from: updatedTask, merge: true) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Create completion record
            let completion = TaskCompletion(
                task: updatedTask,
                completedBy: caregiverId,
                completedByName: caregiverName,
                note: note
            )
            
            try await saveTaskCompletion(completion, for: task.primaryUserId)
            
            // Send notification to primary user
            await notifyPrimaryUserOfCompletion(task: updatedTask)
            
            // Update local state
            if let index = todayTasks.firstIndex(where: { $0.id == task.id }) {
                todayTasks.remove(at: index)
                completedTasks.append(updatedTask)
                completedTasks.sort { $0.completedAt ?? Date() > $1.completedAt ?? Date() }
            }
            
            // Track analytics
            analyticsManager.trackEvent(
                "caregiver_task_completed",
                parameters: [
                    "task_type": task.type.rawValue,
                    "was_late": completion.wasLate,
                    "minutes_late": completion.minutesLate ?? 0
                ]
            )
            
            // Update related medication/supplement if applicable
            if let medicationId = task.medicationId {
                try await coreDataManager.markMedicationTaken(
                    medicationId: medicationId,
                    userId: task.primaryUserId,
                    takenAt: Date()
                )
            }
        } catch {
            lastError = error
            throw error
        }
    }
    
    // MARK: - Task Notifications
    
    private func scheduleTaskNotification(_ task: CaregiverTask) async {
        guard let assignedTo = task.assignedTo else { return }
        
        // Get caregiver's device token
        guard await getCaregiverDeviceToken(assignedTo) != nil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = AppStrings.Notifications.taskReminderTitle
        content.body = String(
            format: AppStrings.Notifications.taskReminderBody,
            task.title,
            task.displayTime
        )
        content.sound = task.type == .criticalMedication ? .defaultCritical : .default
        content.categoryIdentifier = "CAREGIVER_TASK"
        content.userInfo = [
            "taskId": task.id,
            "taskType": task.type.rawValue,
            "primaryUserId": task.primaryUserId
        ]
        
        // Add action buttons
        content.categoryIdentifier = "CAREGIVER_TASK_ACTIONS"
        
        // Schedule at task time
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: task.scheduledTime
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task_\(task.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling task notification: \(error)")
        }
    }
    
    private func notifyPrimaryUserOfCompletion(task: CaregiverTask) async {
        let content = UNMutableNotificationContent()
        content.title = AppStrings.Notifications.taskCompletedTitle
        content.body = String(
            format: AppStrings.Notifications.taskCompletedBody,
            task.title,
            task.completedByName ?? "Caregiver",
            task.completedAt?.formatted(date: .omitted, time: .shortened) ?? ""
        )
        content.sound = .default
        content.userInfo = [
            "taskId": task.id,
            "type": "task_completion"
        ]
        
        let request = UNNotificationRequest(
            identifier: "completion_\(task.id)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error sending completion notification: \(error)")
        }
    }
    
    // MARK: - Task Templates
    
    func createTasksFromTemplate(
        _ template: TaskTemplate,
        for date: Date,
        primaryUserId: String,
        assignedTo: String? = nil
    ) async throws {
        let task = template.createTask(
            for: date,
            primaryUserId: primaryUserId,
            assignedTo: assignedTo
        )
        
        try await createTask(task)
    }
    
    func createDailyTasks(
        from medications: [MedicationModel],
        supplements: [SupplementModel],
        for date: Date,
        primaryUserId: String,
        assignedTo: String? = nil
    ) async throws {
        var tasks: [CaregiverTask] = []
        
        // Create medication tasks
        for medication in medications where medication.isActive {
            // Parse medication schedule times
            for schedule in medication.schedule {
                let task = CaregiverTask(
                    primaryUserId: primaryUserId,
                    assignedTo: assignedTo,
                    type: .medication,
                    title: "Give \(medication.name) \(medication.dosage)",
                    description: medication.notes,
                    scheduledTime: schedule.time,
                    medicationId: medication.id
                )
                tasks.append(task)
            }
        }
        
        // Create supplement tasks
        for supplement in supplements where supplement.isActive {
            // Create one task per day for supplements (usually taken once)
            let scheduledTime = Calendar.current.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: date
            ) ?? date
            
            let task = CaregiverTask(
                primaryUserId: primaryUserId,
                assignedTo: assignedTo,
                type: .supplement,
                title: "Give \(supplement.name) \(supplement.dosage)",
                description: supplement.notes,
                scheduledTime: scheduledTime,
                supplementId: supplement.id
            )
            tasks.append(task)
        }
        
        // Create all tasks
        for task in tasks {
            try await createTask(task)
        }
    }
    
    // MARK: - Task History
    
    func loadTaskHistory(
        for userId: String,
        days: Int = 7
    ) async throws -> [TaskCompletion] {
        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        ) ?? Date()
        
        do {
            let snapshot = try await firestore
                .collection("users")
                .document(userId)
                .collection("taskCompletions")
                .whereField("completedAt", isGreaterThan: startDate)
                .order(by: "completedAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: TaskCompletion.self)
            }
        } catch {
            lastError = error
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCaregiverDeviceToken(_ caregiverId: String) async -> String? {
        // In a real implementation, this would fetch the device token from Firestore
        // For now, return nil to skip push notifications
        return nil
    }
    
    private func saveTaskCompletion(
        _ completion: TaskCompletion,
        for userId: String
    ) async throws {
        // Save to Firestore using Codable with completion handler
        let completionRef = firestore
            .collection("users")
            .document(userId)
            .collection("taskCompletions")
            .document(completion.taskId + "_" + String(Int(completion.completedAt.timeIntervalSince1970)))
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try completionRef.setData(from: completion) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Task Filtering
    
    func filterTasksForCaregiver(_ tasks: [CaregiverTask], caregiverId: String) -> [CaregiverTask] {
        // Caregiver sees tasks assigned to them or unassigned tasks
        tasks.filter { task in
            task.assignedTo == nil || task.assignedTo == caregiverId
        }
    }
    
    func getOverdueTasks() -> [CaregiverTask] {
        todayTasks.filter { $0.isOverdue }
    }
    
    func getUpcomingTasks(minutes: Int = 60) -> [CaregiverTask] {
        let cutoffTime = Date().addingTimeInterval(Double(minutes * 60))
        return todayTasks.filter { task in
            !task.isCompleted &&
            task.scheduledTime <= cutoffTime &&
            task.scheduledTime > Date()
        }
    }
}

// MARK: - Notification Categories
extension CaregiverTaskManager {
    static func registerNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: AppStrings.Notifications.actionComplete,
            options: [.authenticationRequired]
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP_TASK",
            title: AppStrings.Notifications.actionSkip,
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "CAREGIVER_TASK_ACTIONS",
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
