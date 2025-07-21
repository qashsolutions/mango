import Foundation
import FirebaseFirestore
import SwiftUI

struct MedicationConflict: Codable, Identifiable, Sendable, SyncableModel, UserOwnedModel {
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
    let confidence: Double?
    let createdAt: Date
    var updatedAt: Date
    var isResolved: Bool = false
    var userNotes: String?
    
    // Sync properties
    var needsSync: Bool = false
    var isDeletedFlag: Bool = false
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case userId, queryText, medications, supplements, conflictsFound
        case severity, conflictDetails, recommendations, educationalInfo
        case source, confidence, createdAt, updatedAt, isResolved, userNotes
        case needsSync, isDeletedFlag
    }
}

// MARK: - Conflict Severity
enum ConflictSeverity: String, Codable, CaseIterable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .low:
            return AppStrings.Conflicts.Severity.low
        case .medium:
            return AppStrings.Conflicts.Severity.medium
        case .high:
            return AppStrings.Conflicts.Severity.high
        case .critical:
            return AppStrings.Conflicts.Severity.critical
        }
    }
    
    var color: Color {
        switch self {
        case .none:
            return AppTheme.Colors.success
        case .low:
            return AppTheme.Colors.conflictLow
        case .medium:
            return AppTheme.Colors.conflictMedium
        case .high:
            return AppTheme.Colors.conflictHigh
        case .critical:
            return AppTheme.Colors.conflictCritical
        }
    }
    
    var icon: String {
        switch self {
        case .none:
            return AppIcons.success
        case .low:
            return AppIcons.conflictLow
        case .medium:
            return AppIcons.conflictMedium
        case .high:
            return AppIcons.conflictHigh
        case .critical:
            return AppIcons.conflictCritical
        }
    }
    
    var priority: Int {
        switch self {
        case .none:
            return 0
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
        case .none:
            return AppStrings.Conflicts.Severity.noneDescription
        case .low:
            return AppStrings.Conflicts.Severity.lowDescription
        case .medium:
            return AppStrings.Conflicts.Severity.mediumDescription
        case .high:
            return AppStrings.Conflicts.Severity.highDescription
        case .critical:
            return AppStrings.Conflicts.Severity.criticalDescription
        }
    }
    
    var level: Int {
        return priority
    }
    
    var backgroundColor: Color {
        return color.opacity(AppTheme.Opacity.low)
    }
    
    var foregroundColor: Color {
        return color
    }
    
    var borderColor: Color {
        return color.opacity(AppTheme.Opacity.medium)
    }
    
    // MARK: - Conversion from ClaudeAIClient.ConflictSeverity
    init(from clientSeverity: ClaudeAIClient.ConflictSeverity) {
        switch clientSeverity {
        case .none:
            self = .none
        case .low:
            self = .low
        case .medium:
            self = .medium
        case .high:
            self = .high
        case .critical:
            self = .critical
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
       // TODO: Implement proper supplement detection in next release
       return false
   }
   
   var displayTitle: String {
       if let medication2 = medication2 {
           return "\(medication1) + \(medication2)"
       } else {
           return medication1
       }
   }
   
   // MARK: - Codable
   enum CodingKeys: String, CodingKey {
       case medication1, medication2, interactionType, description
       case severity, mechanism, clinicalSignificance, management
   }
}

// MARK: - Conflict Source
enum ConflictSource: String, Codable {
    case claudeAI = "claude_ai"
    case manual = "manual_entry"
    case scheduled = "scheduled_check"
    case realtime = "realtime_check"
    
    var displayName: String {
        switch self {
        case .claudeAI:
            return AppStrings.Conflicts.Source.aiAnalysis
        case .manual:
            return AppStrings.Conflicts.Source.manualCheck
        case .scheduled:
            return AppStrings.Conflicts.Source.scheduledReview
        case .realtime:
            return AppStrings.Conflicts.Source.realtimeCheck
        }
    }
    
    var icon: String {
        switch self {
        case .claudeAI:
            return AppIcons.ai
        case .manual:
            return AppIcons.Conflicts.Source.manual
        case .scheduled:
            return AppIcons.schedule
        case .realtime:
            return AppIcons.Conflicts.Source.realtime
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
            return AppStrings.Conflicts.Messages.noConflictsDetected
        }
        
        let conflictCount = conflictDetails.count
        let severityText = highestSeverity.displayName
        
        if conflictCount == 1 {
            return AppStrings.Conflicts.Messages.oneConflictDetected(severityText.lowercased())
        } else {
            return AppStrings.Conflicts.Messages.multipleConflictsDetected(conflictCount, severityText.lowercased())
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
            userNotes = "\(existingNotes)\(Configuration.Text.newlineCharacter)\(note)"
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
        source: ConflictSource,
        confidence: Double? = nil
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
            confidence: confidence,
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
    
    /// Creates a MedicationConflict from ClaudeAIClient.ConflictAnalysis
    /// - Parameters:
    ///   - analysis: The conflict analysis from Claude AI
    ///   - userId: The user ID for the conflict record
    /// - Returns: A MedicationConflict instance
    static func fromAnalysis(_ analysis: ClaudeAIClient.ConflictAnalysis, userId: String) -> MedicationConflict {
        // Convert conflict details from ClaudeAIClient.DrugConflict to ConflictDetail
        let conflictDetails = analysis.conflicts.map { conflict in
            ConflictDetail.create(
                medication1: conflict.drug1,
                medication2: conflict.drug2,
                interactionType: "Drug-Drug Interaction",
                description: conflict.description,
                severity: ConflictSeverity(from: conflict.severity),
                mechanism: conflict.mechanism,
                clinicalSignificance: conflict.clinicalSignificance,
                management: conflict.management
            )
        }
        
        // Create MedicationConflict using the standard create method
        return create(
            for: userId,
            queryText: "AI Analysis at \(analysis.timestamp.formatted())",
            medications: analysis.medicationsAnalyzed,
            supplements: [],
            conflictsFound: analysis.conflictsFound,
            severity: ConflictSeverity(from: analysis.severity),
            conflictDetails: conflictDetails,
            recommendations: analysis.recommendations,
            educationalInfo: analysis.summary,
            source: .claudeAI,
            confidence: analysis.confidence
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
struct ConflictAnalysisSummary: Sendable {
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
        source: .claudeAI,
        confidence: 0.95, // High confidence for known interaction
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
        confidence: 0.90, // High confidence for no interaction
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
            confidence: 0.75, // Moderate confidence
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
