import Foundation

@MainActor
class ConflictsViewModel: ObservableObject {
    @Published var conflicts: [MedicationConflict] = []
    @Published var conflictSummary: ConflictAnalysisSummary = ConflictAnalysisSummary(
        totalConflicts: 0,
        criticalConflicts: 0,
        highRiskConflicts: 0,
        medicationsInvolved: [],
        supplementsInvolved: [],
        lastAnalysisDate: nil
    )
    @Published var isLoading: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var error: AppError?
    @Published var currentFilter: ConflictFilter = .all
    
    private let coreDataManager = CoreDataManager.shared
    private let dataSyncManager = DataSyncManager.shared
    private let authManager = FirebaseManager.shared
    private let analyticsManager = AnalyticsManager.shared
    
    // MARK: - Computed Properties
    var filteredConflicts: [MedicationConflict] {
        return filterConflicts(conflicts, by: currentFilter)
    }
    
    var criticalConflicts: [MedicationConflict] {
        return conflicts.filter { $0.highestSeverity == .critical }
    }
    
    var unresolvedConflicts: [MedicationConflict] {
        return conflicts.filter { !$0.isResolved }
    }
    
    var hasUrgentConflicts: Bool {
        return !criticalConflicts.isEmpty || conflicts.contains { $0.requiresUrgentAttention }
    }
    
    // MARK: - Data Loading
    func loadData() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            conflicts = try await loadConflicts(for: userId)
            updateConflictSummary()
            analyticsManager.trackScreenViewed("conflicts")
        } catch {
            self.error = error as? AppError ?? AppError.data(.loadFailed)
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await dataSyncManager.syncPendingChanges()
        await loadData()
    }
    
    private func loadConflicts(for userId: String) async throws -> [MedicationConflict] {
        // TODO: Implement conflict fetching in CoreDataManager
        // For now, return sample data
        return MedicationConflict.sampleConflicts.filter { $0.userId == userId }
    }
    
    // MARK: - Conflict Analysis
    func checkForConflicts() async {
        guard let userId = authManager.currentUser?.id else {
            error = AppError.authentication(.notAuthenticated)
            return
        }
        
        isAnalyzing = true
        error = nil
        
        do {
            // Get user's medications and supplements
            let medications = try await coreDataManager.fetchMedications(for: userId)
            let supplements = try await coreDataManager.fetchSupplements(for: userId)
            
            guard !medications.isEmpty else {
                error = AppError.data(.noData)
                isAnalyzing = false
                return
            }
            
            // Analyze conflicts (this would integrate with MedGemma AI in the future)
            let newConflicts = await analyzeConflicts(
                medications: medications,
                supplements: supplements,
                userId: userId
            )
            
            // Save new conflicts
            for conflict in newConflicts {
                try await saveConflict(conflict)
            }
            
            // Reload data to show new conflicts
            await loadData()
            
            analyticsManager.trackConflictCheck(
                source: "manual",
                conflictsFound: !newConflicts.isEmpty,
                severity: newConflicts.first?.highestSeverity.rawValue
            )
            
        } catch {
            self.error = error as? AppError ?? AppError.sync(.syncTimeout)
        }
        
        isAnalyzing = false
    }
    
    private func analyzeConflicts(
        medications: [Medication],
        supplements: [Supplement],
        userId: String
    ) async -> [MedicationConflict] {
        // Simulate AI analysis (in production, this would call MedGemma API)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        
        var detectedConflicts: [MedicationConflict] = []
        
        // Check medication-medication interactions
        for i in 0..<medications.count {
            for j in (i+1)..<medications.count {
                let med1 = medications[i]
                let med2 = medications[j]
                
                if let conflict = checkMedicationInteraction(med1, med2, userId: userId) {
                    detectedConflicts.append(conflict)
                }
            }
        }
        
        // Check medication-supplement interactions
        for medication in medications {
            for supplement in supplements {
                if let conflict = checkMedicationSupplementInteraction(medication, supplement, userId: userId) {
                    detectedConflicts.append(conflict)
                }
            }
        }
        
        return detectedConflicts
    }
    
    private func checkMedicationInteraction(_ med1: Medication, _ med2: Medication, userId: String) -> MedicationConflict? {
        // Simplified conflict detection logic
        let knownInteractions: [String: (String, ConflictSeverity)] = [
            "Warfarin-Aspirin": ("Increased bleeding risk", .high),
            "Lisinopril-Ibuprofen": ("Reduced effectiveness", .medium),
            "Metformin-Alcohol": ("Lactic acidosis risk", .critical)
        ]
        
        let interactionKey = "\(med1.name)-\(med2.name)"
        let reverseKey = "\(med2.name)-\(med1.name)"
        
        if let interaction = knownInteractions[interactionKey] ?? knownInteractions[reverseKey] {
            let conflictDetail = ConflictDetail.create(
                medication1: med1.name,
                medication2: med2.name,
                interactionType: "Drug-Drug Interaction",
                description: interaction.0,
                severity: interaction.1,
                mechanism: "Pharmacokinetic interaction",
                clinicalSignificance: "Monitor closely",
                management: "Consult healthcare provider"
            )
            
            return MedicationConflict.create(
                for: userId,
                queryText: "Checking \(med1.name) and \(med2.name)",
                medications: [med1.name, med2.name],
                supplements: [],
                conflictsFound: true,
                severity: interaction.1,
                conflictDetails: [conflictDetail],
                recommendations: [
                    "Monitor for signs of \(interaction.0.lowercased())",
                    "Consult with your healthcare provider",
                    "Consider alternative medications if necessary"
                ],
                educationalInfo: "This interaction occurs when \(med1.name) and \(med2.name) are taken together.",
                source: .medgemma
            )
        }
        
        return nil
    }
    
    private func checkMedicationSupplementInteraction(_ medication: Medication, _ supplement: Supplement, userId: String) -> MedicationConflict? {
        // Simplified supplement interaction logic
        let knownInteractions: [String: (String, ConflictSeverity)] = [
            "Warfarin-Vitamin K": ("Reduced anticoagulation", .medium),
            "Lisinopril-Potassium": ("Hyperkalemia risk", .high),
            "Metformin-Chromium": ("Enhanced glucose lowering", .low)
        ]
        
        let interactionKey = "\(medication.name)-\(supplement.name)"
        
        if let interaction = knownInteractions[interactionKey] {
            let conflictDetail = ConflictDetail.create(
                medication1: medication.name,
                medication2: supplement.name,
                interactionType: "Drug-Supplement Interaction",
                description: interaction.0,
                severity: interaction.1,
                mechanism: "Nutrient interaction",
                clinicalSignificance: "Monitor levels",
                management: "Adjust timing or dosage"
            )
            
            return MedicationConflict.create(
                for: userId,
                queryText: "Checking \(medication.name) and \(supplement.name)",
                medications: [medication.name],
                supplements: [supplement.name],
                conflictsFound: true,
                severity: interaction.1,
                conflictDetails: [conflictDetail],
                recommendations: [
                    "Monitor for \(interaction.0.lowercased())",
                    "Consider timing separation between doses",
                    "Discuss with healthcare provider"
                ],
                educationalInfo: "This interaction may occur between \(medication.name) and \(supplement.name).",
                source: .medgemma
            )
        }
        
        return nil
    }
    
    private func saveConflict(_ conflict: MedicationConflict) async throws {
        // TODO: Implement conflict saving in CoreDataManager
        // For now, just add to local array
        conflicts.append(conflict)
    }
    
    // MARK: - Conflict Management
    func resolveConflict(_ conflict: MedicationConflict) async {
        do {
            var resolvedConflict = conflict
            resolvedConflict.markAsResolved()
            
            // TODO: Update conflict in CoreDataManager
            // try await coreDataManager.saveConflict(resolvedConflict)
            
            // Update local state
            if let index = conflicts.firstIndex(where: { $0.id == conflict.id }) {
                conflicts[index] = resolvedConflict
            }
            
            updateConflictSummary()
            
            analyticsManager.trackConflictResolved(severity: conflict.highestSeverity.rawValue)
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    func addUserNote(to conflict: MedicationConflict, note: String) async {
        do {
            var updatedConflict = conflict
            updatedConflict.addUserNote(note)
            
            // TODO: Update conflict in CoreDataManager
            // try await coreDataManager.saveConflict(updatedConflict)
            
            // Update local state
            if let index = conflicts.firstIndex(where: { $0.id == conflict.id }) {
                conflicts[index] = updatedConflict
            }
            
            analyticsManager.trackFeatureUsed("conflict_note_added")
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    func deleteConflict(_ conflict: MedicationConflict) async {
        do {
            var deletedConflict = conflict
            deletedConflict.isDeleted = true
            deletedConflict.markForSync()
            
            // TODO: Update conflict in CoreDataManager
            // try await coreDataManager.saveConflict(deletedConflict)
            
            // Update local state
            conflicts.removeAll { $0.id == conflict.id }
            updateConflictSummary()
            
            analyticsManager.trackFeatureUsed("conflict_deleted")
            
        } catch {
            self.error = error as? AppError ?? AppError.data(.saveFailed)
        }
    }
    
    // MARK: - Filtering and Sorting
    func updateFilter(_ filter: ConflictFilter) {
        currentFilter = filter
        analyticsManager.trackFeatureUsed("conflicts_filtered_\(filter.rawValue)")
    }
    
    private func filterConflicts(_ conflicts: [MedicationConflict], by filter: ConflictFilter) -> [MedicationConflict] {
        switch filter {
        case .all:
            return conflicts
        case .critical:
            return conflicts.filter { $0.highestSeverity == .critical }
        case .high:
            return conflicts.filter { $0.highestSeverity == .high || $0.highestSeverity == .critical }
        case .unresolved:
            return conflicts.filter { !$0.isResolved }
        case .resolved:
            return conflicts.filter { $0.isResolved }
        case .recent:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return conflicts.filter { $0.createdAt > oneWeekAgo }
        }
    }
    
    func sortConflicts(_ conflicts: [MedicationConflict], by sortOption: ConflictSortOption) -> [MedicationConflict] {
        switch sortOption {
        case .severity:
            return conflicts.sorted { $0.highestSeverity.priority > $1.highestSeverity.priority }
        case .date:
            return conflicts.sorted { $0.createdAt > $1.createdAt }
        case .resolved:
            return conflicts.sorted { !$0.isResolved && $1.isResolved }
        }
    }
    
    // MARK: - Statistics and Analysis
    private func updateConflictSummary() {
        let allMedications = Set(conflicts.flatMap { $0.medications })
        let allSupplements = Set(conflicts.flatMap { $0.supplements })
        
        conflictSummary = ConflictAnalysisSummary(
            totalConflicts: conflicts.count,
            criticalConflicts: conflicts.filter { $0.highestSeverity == .critical }.count,
            highRiskConflicts: conflicts.filter { $0.highestSeverity == .high || $0.highestSeverity == .critical }.count,
            medicationsInvolved: allMedications,
            supplementsInvolved: allSupplements,
            lastAnalysisDate: conflicts.isEmpty ? nil : Date()
        )
    }
    
    func getConflictStatistics() -> ConflictStatistics {
        return ConflictStatistics(
            totalAnalyses: conflicts.count,
            conflictsDetected: conflicts.filter { $0.conflictsFound }.count,
            conflictsResolved: conflicts.filter { $0.isResolved }.count,
            averageSeverity: getAverageSeverity(),
            mostCommonInteractions: getMostCommonInteractions(),
            detectionRate: getDetectionRate()
        )
    }
    
    private func getAverageSeverity() -> Double {
        guard !conflicts.isEmpty else { return 0.0 }
        
        let totalSeverity = conflicts.reduce(0) { $0 + $1.highestSeverity.priority }
        return Double(totalSeverity) / Double(conflicts.count)
    }
    
    private func getMostCommonInteractions() -> [String] {
        let interactions = conflicts.flatMap { $0.conflictDetails }.map { $0.interactionType }
        let grouped = Dictionary(grouping: interactions) { $0 }
        return grouped.sorted { $0.value.count > $1.value.count }.map { $0.key }
    }
    
    private func getDetectionRate() -> Double {
        guard !conflicts.isEmpty else { return 0.0 }
        
        let conflictsFound = conflicts.filter { $0.conflictsFound }.count
        return Double(conflictsFound) / Double(conflicts.count)
    }
    
    // MARK: - Educational Content
    func getEducationalContent(for severity: ConflictSeverity) -> EducationalContent {
        switch severity {
        case .low:
            return EducationalContent(
                title: "Low Risk Interactions",
                description: "These interactions are generally minor and may not require immediate action.",
                recommendations: [
                    "Monitor for any unusual symptoms",
                    "Inform your healthcare provider at next visit",
                    "Continue medications as prescribed"
                ]
            )
        case .medium:
            return EducationalContent(
                title: "Moderate Risk Interactions",
                description: "These interactions should be monitored and may require dosage adjustments.",
                recommendations: [
                    "Contact your healthcare provider",
                    "Monitor symptoms closely",
                    "Do not stop medications without consulting doctor"
                ]
            )
        case .high:
            return EducationalContent(
                title: "High Risk Interactions",
                description: "These interactions may require immediate attention and medication changes.",
                recommendations: [
                    "Contact your healthcare provider immediately",
                    "Monitor for serious side effects",
                    "Consider alternative medications"
                ]
            )
        case .critical:
            return EducationalContent(
                title: "Critical Risk Interactions",
                description: "These interactions are potentially dangerous and require immediate medical attention.",
                recommendations: [
                    "Seek immediate medical attention",
                    "Do not take these medications together",
                    "Contact emergency services if experiencing symptoms"
                ]
            )
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
    
    func retryLastAction() async {
        await loadData()
    }
    
    // MARK: - Real-time Monitoring
    func enableRealtimeMonitoring() async {
        analyticsManager.trackFeatureUsed("realtime_monitoring_enabled")
        // TODO: Implement real-time conflict monitoring
    }
    
    func disableRealtimeMonitoring() async {
        analyticsManager.trackFeatureUsed("realtime_monitoring_disabled")
        // TODO: Disable real-time conflict monitoring
    }
}

// MARK: - Supporting Models
enum ConflictSortOption: String, CaseIterable {
    case severity = "severity"
    case date = "date"
    case resolved = "resolved"
    
    var displayName: String {
        switch self {
        case .severity:
            return "Severity"
        case .date:
            return "Date"
        case .resolved:
            return "Resolution Status"
        }
    }
}

struct ConflictStatistics {
    let totalAnalyses: Int
    let conflictsDetected: Int
    let conflictsResolved: Int
    let averageSeverity: Double
    let mostCommonInteractions: [String]
    let detectionRate: Double
    
    var resolutionRate: Double {
        guard conflictsDetected > 0 else { return 0.0 }
        return Double(conflictsResolved) / Double(conflictsDetected)
    }
    
    var detectionRatePercentage: String {
        return "\(Int(detectionRate * 100))%"
    }
    
    var resolutionRatePercentage: String {
        return "\(Int(resolutionRate * 100))%"
    }
}

struct EducationalContent {
    let title: String
    let description: String
    let recommendations: [String]
}

// MARK: - Sample Data Extension
#if DEBUG
extension ConflictsViewModel {
    static let sampleViewModel: ConflictsViewModel = {
        let viewModel = ConflictsViewModel()
        viewModel.conflicts = MedicationConflict.sampleConflicts
        viewModel.conflictSummary = ConflictAnalysisSummary.sampleSummary
        return viewModel
    }()
}

extension ConflictStatistics {
    static let sampleStatistics = ConflictStatistics(
        totalAnalyses: 12,
        conflictsDetected: 4,
        conflictsResolved: 3,
        averageSeverity: 2.5,
        mostCommonInteractions: ["Drug-Drug Interaction", "Drug-Supplement Interaction"],
        detectionRate: 0.33
    )
}

extension EducationalContent {
    static let sampleContent = EducationalContent(
        title: "Understanding Drug Interactions",
        description: "Drug interactions occur when medications affect each other's effectiveness or safety.",
        recommendations: [
            "Always inform healthcare providers of all medications",
            "Read medication labels carefully",
            "Use one pharmacy for all prescriptions"
        ]
    )
}
#endif