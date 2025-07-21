import Foundation
import FirebaseFirestore

// MARK: - Caregiver Task Model
struct CaregiverTask: Codable, Identifiable, Equatable {
    let id: String
    let primaryUserId: String
    let assignedTo: String? // Caregiver ID if assigned to specific caregiver
    let type: TaskType
    let title: String
    let description: String?
    let scheduledTime: Date
    let windowStartTime: Date // Task can be completed within a window
    let windowEndTime: Date
    let medicationId: String? // If task is medication-related
    let supplementId: String? // If task is supplement-related
    let mealType: MealType? // If task is meal-related
    
    // Completion tracking
    var isCompleted: Bool = false
    var completedBy: String? // Caregiver ID who completed
    var completedByName: String? // Caregiver name for display
    var completedAt: Date?
    var completionNote: String?
    
    // Metadata
    let createdAt: Date
    var lastModified: Date
    var isActive: Bool = true
    var needsSync: Bool = false
    
    // Notification tracking
    var notificationSent: Bool = false
    var notificationSentAt: Date?
    
    // Template reference
    var templateId: String? // If created from template
    
    // MARK: - Computed Properties
    
    var isOverdue: Bool {
        !isCompleted && Date() > windowEndTime
    }
    
    var isInWindow: Bool {
        let now = Date()
        return now >= windowStartTime && now <= windowEndTime
    }
    
    var canBeCompleted: Bool {
        !isCompleted && (isInWindow || isOverdue)
    }
    
    var timeUntilDue: TimeInterval {
        scheduledTime.timeIntervalSince(Date())
    }
    
    var displayTime: String {
        scheduledTime.formatted(date: .omitted, time: .shortened)
    }
    
    var windowDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: windowStartTime)) - \(formatter.string(from: windowEndTime))"
    }
    
    var statusDisplay: String {
        if isCompleted {
            return AppStrings.Common.completed
        } else if isOverdue {
            return AppStrings.Common.overdue
        } else if isInWindow {
            return AppStrings.Common.dueNow
        } else {
            return AppStrings.Common.scheduled
        }
    }
    
    var priorityLevel: TaskPriority {
        if type == .medication || type == .criticalMedication {
            return .high
        } else if type == .meal {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Init
    
    init(
        id: String = UUID().uuidString,
        primaryUserId: String,
        assignedTo: String? = nil,
        type: TaskType,
        title: String,
        description: String? = nil,
        scheduledTime: Date,
        windowStartTime: Date? = nil,
        windowEndTime: Date? = nil,
        medicationId: String? = nil,
        supplementId: String? = nil,
        mealType: MealType? = nil,
        templateId: String? = nil
    ) {
        self.id = id
        self.primaryUserId = primaryUserId
        self.assignedTo = assignedTo
        self.type = type
        self.title = title
        self.description = description
        self.scheduledTime = scheduledTime
        
        // Default window is ±30 minutes if not specified
        self.windowStartTime = windowStartTime ?? scheduledTime.addingTimeInterval(-30 * 60)
        self.windowEndTime = windowEndTime ?? scheduledTime.addingTimeInterval(30 * 60)
        
        self.medicationId = medicationId
        self.supplementId = supplementId
        self.mealType = mealType
        self.templateId = templateId
        
        self.createdAt = Date()
        self.lastModified = Date()
    }
}

// MARK: - Task Type
enum TaskType: String, Codable, CaseIterable {
    case medication = "medication"
    case criticalMedication = "critical_medication"
    case supplement = "supplement"
    case meal = "meal"
    case hydration = "hydration"
    case exercise = "exercise"
    case appointment = "appointment"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .medication:
            return AppStrings.Common.medication
        case .criticalMedication:
            return AppStrings.Tasks.criticalMedication
        case .supplement:
            return AppStrings.Common.supplement
        case .meal:
            return AppStrings.Common.meal
        case .hydration:
            return AppStrings.Tasks.hydration
        case .exercise:
            return AppStrings.Tasks.exercise
        case .appointment:
            return AppStrings.Tasks.appointment
        case .other:
            return AppStrings.Common.other
        }
    }
    
    var icon: String {
        switch self {
        case .medication, .criticalMedication:
            return AppIcons.medication
        case .supplement:
            return AppIcons.supplement
        case .meal:
            return AppIcons.food
        case .hydration:
            return "drop.fill"
        case .exercise:
            return "figure.walk"
        case .appointment:
            return "calendar"
        case .other:
            return "checklist"
        }
    }
    
    var defaultWindowMinutes: Int {
        switch self {
        case .criticalMedication:
            return 15 // Strict 15-minute window
        case .medication:
            return 30 // 30-minute window
        case .meal:
            return 60 // 1-hour window
        case .supplement, .hydration, .exercise:
            return 120 // 2-hour window
        case .appointment:
            return 0 // Exact time
        case .other:
            return 60 // 1-hour default
        }
    }
}

// MARK: - Task Priority
enum TaskPriority: Int, Codable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
    
    var color: String {
        switch self {
        case .low:
            return "AppTheme.Colors.success"
        case .medium:
            return "AppTheme.Colors.warning"
        case .high:
            return "AppTheme.Colors.error"
        case .critical:
            return "AppTheme.Colors.critical"
        }
    }
}

// MARK: - Task Completion
struct TaskCompletion: Codable {
    let taskId: String
    let completedBy: String
    let completedByName: String
    let completedAt: Date
    let note: String?
    let wasLate: Bool
    let minutesLate: Int?
    
    init(task: CaregiverTask, completedBy: String, completedByName: String, note: String? = nil) {
        self.taskId = task.id
        self.completedBy = completedBy
        self.completedByName = completedByName
        self.completedAt = Date()
        self.note = note
        
        // Calculate if completed late
        let now = Date()
        self.wasLate = now > task.windowEndTime
        if wasLate {
            self.minutesLate = Int(now.timeIntervalSince(task.windowEndTime) / 60)
        } else {
            self.minutesLate = nil
        }
    }
}

// MARK: - Task Template
struct TaskTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let type: TaskType
    let title: String
    let description: String?
    let defaultTime: DateComponents // Store as components for daily application
    let windowMinutes: Int
    let isActive: Bool
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         type: TaskType,
         title: String,
         description: String? = nil,
         defaultTime: DateComponents,
         windowMinutes: Int,
         isActive: Bool = true,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.title = title
        self.description = description
        self.defaultTime = defaultTime
        self.windowMinutes = windowMinutes
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    func createTask(for date: Date, primaryUserId: String, assignedTo: String? = nil) -> CaregiverTask {
        let calendar = Calendar.current
        let scheduledTime = calendar.date(byAdding: defaultTime, to: calendar.startOfDay(for: date)) ?? date
        
        return CaregiverTask(
            primaryUserId: primaryUserId,
            assignedTo: assignedTo,
            type: type,
            title: title,
            description: description,
            scheduledTime: scheduledTime,
            windowStartTime: scheduledTime.addingTimeInterval(Double(-windowMinutes * 60 / 2)),
            windowEndTime: scheduledTime.addingTimeInterval(Double(windowMinutes * 60 / 2)),
            templateId: id
        )
    }
}

// MARK: - Sample Data
#if DEBUG
extension CaregiverTask {
    static let sampleMedicationTask = CaregiverTask(
        primaryUserId: "sample-user",
        type: .medication,
        title: "Give Metformin 500mg",
        description: "Take with breakfast",
        scheduledTime: Date().addingTimeInterval(3600),
        medicationId: "med-123"
    )
    
    static let sampleMealTask = CaregiverTask(
        primaryUserId: "sample-user",
        type: .meal,
        title: "Serve Lunch",
        description: "Low sodium diet - see meal plan",
        scheduledTime: Date().addingTimeInterval(7200),
        mealType: .lunch
    )
    
    static let sampleCompletedTask: CaregiverTask = {
        var task = CaregiverTask(
            primaryUserId: "sample-user",
            type: .supplement,
            title: "Give Vitamin D",
            scheduledTime: Date().addingTimeInterval(-3600)
        )
        task.isCompleted = true
        task.completedBy = "caregiver-123"
        task.completedByName = "Jane Smith"
        task.completedAt = Date().addingTimeInterval(-3000)
        return task
    }()
}

extension TaskTemplate {
    static let sampleMorningMeds = TaskTemplate(
        name: "Morning Medications",
        type: .medication,
        title: "Morning medication routine",
        description: "All morning medications with breakfast",
        defaultTime: DateComponents(hour: 8, minute: 0),
        windowMinutes: 60
    )
}
#endif
