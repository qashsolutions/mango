import Foundation
import FirebaseFirestore

struct MedicationConflict: Codable, Identifiable, SyncableModel, UserOwnedModel {
    let id: String = UUID().uuidString
    let userId: String
    let queryText: String
    let medications: [String]
    let supplements: [String]
    let conflictsFound: Bool
    let severity: ConflictSeverity?
    let conflictDetails: [ConflictDetail]
    let recommendations: [String]
    let educationalInfo: String?
    let source: ConflictSource
    let createdAt: Date
    var updatedAt: Date
    var isResolved: Bool = false
    var userNotes: String?
    
    // Sync properties
    var needsSync: Bool = false
    var isDeleted: Bool = false
}

// MARK: - Conflict Severity
enum ConflictSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low Risk"
        case .medium:
            return "Moderate Risk"
        case .high:
            return "High Risk"
        case .critical:
            return "Critical Risk"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "conflictLow"
        case .medium:
            return "conflictMedium"
        case .high:
            return "conflictHigh"
        case .critical:
            return "conflictCritical"
        }
    }
    
    var icon: String {
        switch self {
        case .low:
            return "info.circle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
    
    var priority: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        case .critical:
            return 4
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "Minor interaction that may not require action"
        case .medium:
            return "Moderate interaction that should be monitored"
        case .high:
            return "Significant interaction that may require dosage adjustment"
        case .critical:
            return "Dangerous interaction that requires immediate attention"
        }
    }
}

// MARK: - Conflict Detail
struct ConflictDetail: Codable, Identifiable {
    let id: String = UUID().uuidString
    let medication1: String
    let medication2: String?
    let interactionType: String
    let description: String
    let severity: ConflictSeverity
    let mechanism: String?
    let clinicalSignificance: String?
    let management: String?
    
    var involvesSupplements: Bool {
        return medication2?.contains("supplement") == true || 
               medication1.contains("supplement")
    }
    
    var displayTitle: String {
        if let medication2 = medication2 {
            return "\(medication1) + \(medication2)"
        } else {
            return medication1
        }
    }
}

// MARK: - Conflict Source
enum ConflictSource: String, Codable {
    case medgemma = "medgemma_ai"
    case manual = "manual_entry"
    case scheduled = "scheduled_check"
    case realtime = "realtime_check"
    
    var displayName: String {
        switch self {
        case .medgemma:
            return "AI Analysis"
        case .manual:
            return "Manual Check"
        case .scheduled:
            return "Scheduled Review"
        case .realtime:
            return "Real-time Check"
        }
    }
    
    var icon: String {
        switch self {
        case .medgemma:
            return "brain.head.profile"
        case .manual:
            return "hand.raised.fill"
        case .scheduled:
            return "clock.fill"
        case .realtime:
            return "bolt.fill"
        }
    }
}

// MARK: - Conflict Extensions
extension MedicationConflict {
    var highestSeverity: ConflictSeverity {
        let maxSeverity = conflictDetails.map { $0.severity }.max { $0.priority < $1.priority }
        return maxSeverity ?? severity ?? .low
    }
    
    var criticalConflicts: [ConflictDetail] {
        return conflictDetails.filter { $0.severity == .critical }
    }
    
    var hasActionableRecommendations: Bool {
        return !recommendations.isEmpty
    }
    
    var totalMedicationsInvolved: Int {
        return medications.count + supplements.count
    }
    
    var displaySummary: String {
        if !conflictsFound {
            return "No conflicts detected"
        }
        
        let conflictCount = conflictDetails.count
        let severityText = highestSeverity.displayName
        
        if conflictCount == 1 {
            return "1 \(severityText.lowercased()) conflict detected"
        } else {
            return "\(conflictCount) conflicts detected (highest: \(severityText.lowercased()))"
        }
    }
    
    var requiresUrgentAttention: Bool {
        return conflictsFound && (highestSeverity == .critical || highestSeverity == .high)
    }
    
    mutating func markAsResolved(withNotes notes: String? = nil) {
        isResolved = true
        userNotes = notes
        markForSync()
    }
    
    mutating func addUserNote(_ note: String) {
        if let existingNotes = userNotes, !existingNotes.isEmpty {
            userNotes = "\(existingNotes)\n\(note)"
        } else {
            userNotes = note
        }
        markForSync()
    }
}

// MARK: - Conflict Creation Helpers
extension MedicationConflict {
    static func create(
        for userId: String,
        queryText: String,
        medications: [String],
        supplements: [String] = [],
        conflictsFound: Bool,
        severity: ConflictSeverity? = nil,
        conflictDetails: [ConflictDetail] = [],
        recommendations: [String] = [],
        educationalInfo: String? = nil,
        source: ConflictSource
    ) -> MedicationConflict {
        var conflict = MedicationConflict(
            userId: userId,
            queryText: queryText,
            medications: medications,
            supplements: supplements,
            conflictsFound: conflictsFound,
            severity: severity,
            conflictDetails: conflictDetails,
            recommendations: recommendations,
            educationalInfo: educationalInfo,
            source: source,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        conflict.markForSync()
        return conflict
    }
    
    static func noConflictResult(
        for userId: String,
        queryText: String,
        medications: [String],
        supplements: [String] = [],
        source: ConflictSource
    ) -> MedicationConflict {
        return create(
            for: userId,
            queryText: queryText,
            medications: medications,
            supplements: supplements,
            conflictsFound: false,
            source: source
        )
    }
}

extension ConflictDetail {
    static func create(
        medication1: String,
        medication2: String?,
        interactionType: String,
        description: String,
        severity: ConflictSeverity,
        mechanism: String? = nil,
        clinicalSignificance: String? = nil,
        management: String? = nil
    ) -> ConflictDetail {
        return ConflictDetail(
            medication1: medication1,
            medication2: medication2,
            interactionType: interactionType,
            description: description,
            severity: severity,
            mechanism: mechanism,
            clinicalSignificance: clinicalSignificance,
            management: management
        )
    }
}

// MARK: - Conflict Analysis Summary
struct ConflictAnalysisSummary {
    let totalConflicts: Int
    let criticalConflicts: Int
    let highRiskConflicts: Int
    let medicationsInvolved: Set<String>
    let supplementsInvolved: Set<String>
    let lastAnalysisDate: Date?
    
    var hasAnyConflicts: Bool {
        return totalConflicts > 0
    }
    
    var requiresAttention: Bool {
        return criticalConflicts > 0 || highRiskConflicts > 0
    }
    
    var totalSubstancesInvolved: Int {
        return medicationsInvolved.count + supplementsInvolved.count
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension MedicationConflict {
    static let sampleConflict = MedicationConflict(
        userId: "sample-user-id",
        queryText: "Check interactions between Warfarin and Aspirin",
        medications: ["Warfarin", "Aspirin"],
        supplements: [],
        conflictsFound: true,
        severity: .high,
        conflictDetails: [
            ConflictDetail(
                medication1: "Warfarin",
                medication2: "Aspirin",
                interactionType: "Drug-Drug Interaction",
                description: "Increased risk of bleeding when warfarin is combined with aspirin. Both medications affect blood clotting.",
                severity: .high,
                mechanism: "Additive anticoagulant effects",
                clinicalSignificance: "Significantly increased bleeding risk",
                management: "Monitor INR closely and watch for signs of bleeding"
            )
        ],
        recommendations: [
            "Monitor INR levels more frequently",
            "Watch for signs of unusual bleeding or bruising",
            "Consider alternative pain management options",
            "Consult with your healthcare provider before making changes"
        ],
        educationalInfo: "Warfarin and aspirin both affect blood clotting but through different mechanisms. When taken together, they can significantly increase the risk of bleeding.",
        source: .medgemma,
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        updatedAt: Date()
    )
    
    static let sampleNoConflict = MedicationConflict(
        userId: "sample-user-id",
        queryText: "Check interactions for Lisinopril and Vitamin D",
        medications: ["Lisinopril"],
        supplements: ["Vitamin D"],
        conflictsFound: false,
        severity: nil,
        conflictDetails: [],
        recommendations: [],
        educationalInfo: "No significant interactions found between Lisinopril and Vitamin D3 supplements.",
        source: .realtime,
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        updatedAt: Date()
    )
    
    static let sampleConflicts: [MedicationConflict] = [
        sampleConflict,
        sampleNoConflict,
        MedicationConflict(
            userId: "sample-user-id",
            queryText: "Daily medication review",
            medications: ["Metformin", "Lisinopril", "Atorvastatin"],
            supplements: ["Omega-3", "Vitamin D"],
            conflictsFound: true,
            severity: .medium,
            conflictDetails: [
                ConflictDetail(
                    medication1: "Metformin",
                    medication2: "Omega-3",
                    interactionType: "Drug-Supplement Interaction",
                    description: "Omega-3 supplements may slightly enhance the glucose-lowering effects of metformin.",
                    severity: .low,
                    mechanism: "Enhanced insulin sensitivity",
                    clinicalSignificance: "Minimal clinical impact",
                    management: "Monitor blood glucose levels as usual"
                )
            ],
            recommendations: [
                "Continue current medication regimen",
                "Regular monitoring of blood glucose recommended"
            ],
            educationalInfo: "This is a minor interaction with potential benefits for diabetes management.",
            source: .scheduled,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            updatedAt: Date()
        )
    ]
}

extension ConflictAnalysisSummary {
    static let sampleSummary = ConflictAnalysisSummary(
        totalConflicts: 3,
        criticalConflicts: 0,
        highRiskConflicts: 1,
        medicationsInvolved: ["Warfarin", "Aspirin", "Metformin", "Lisinopril"],
        supplementsInvolved: ["Omega-3", "Vitamin D"],
        lastAnalysisDate: Date()
    )
}
#endif