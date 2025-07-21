import Foundation
import OSLog

/// ConflictFilter enum for filtering conflict analysis results
enum ConflictFilterType: String, CaseIterable {
    case all = "all"
    case critical = "critical"
    case high = "high"
    case unresolved = "unresolved"
    case resolved = "resolved"
    case recent = "recent"
    
    var displayName: String {
        switch self {
        case .all:
            return AppStrings.Conflicts.all
        case .critical:
            return AppStrings.Conflicts.critical
        case .high:
            return AppStrings.Conflicts.high
        case .unresolved:
            return AppStrings.Conflicts.unresolved
        case .resolved:
            return AppStrings.Conflicts.resolved
        case .recent:
            return AppStrings.Conflicts.recent
        }
    }
}

/// ConflictSortOption enum for sorting conflict results
enum ConflictSortOption: String, CaseIterable {
    case severity = "severity"
    case date = "date"
    case resolved = "resolved"
    
    var displayName: String {
        switch self {
        case .severity:
            return AppStrings.Conflicts.criticalConflicts
        case .date:
            return AppStrings.Common.date
        case .resolved:
            return AppStrings.Conflicts.resolved
        }
    }
}

/// Main ViewModel for managing medication conflict detection and analysis
/// Integrates AI-powered conflict detection with local data management
@MainActor
@Observable
class ConflictsViewModel {
    
    // MARK: - Published Properties
    
    /// Array of all medication conflicts for current user
    var conflicts: [MedicationConflict] = []
    
    /// Summary statistics for conflict analysis
    var conflictSummary: ConflictAnalysisSummary = ConflictAnalysisSummary(
        totalConflicts: 0,
        criticalConflicts: 0,
        highRiskConflicts: 0,
        medicationsInvolved: [],
        supplementsInvolved: [],
        lastAnalysisDate: nil
    )
    
    /// Loading state for UI binding
    var isLoading: Bool = false
    
    /// AI analysis state for UI binding
    var isAnalyzing: Bool = false
    
    /// Current error state with user-friendly messages
    var error: AppError?
    
    /// Current filter applied to conflicts list
    var currentFilter: ConflictFilterType = .all
    
    /// Current sort option for conflicts display
    var currentSort: ConflictSortOption = .severity
    
    /// Voice recording state
    var isRecordingVoice: Bool = false
    
    /// Current voice query text
    var voiceQueryText: String = ""
    
    /// Current analysis result for display
    var currentAnalysis: ConflictDetectionManager.MedicationConflictAnalysis?
    
    /// Analysis history
    var analysisHistory: [ConflictDetectionManager.MedicationConflictAnalysis] = []
    
    /// Search text for history
    var searchText: String = ""
    
    // MARK: - Private Properties
    
    /// Logger for debugging and monitoring
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "ConflictsViewModel")
    
    /// Core Data manager for local persistence
    private let coreDataManager = CoreDataManager.shared
    
    /// Data sync manager for Firebase operations
    private let dataSyncManager = DataSyncManager.shared
    
    /// Authentication manager for user context
    private let authManager = FirebaseManager.shared
    
    /// Analytics manager for usage tracking
    private let analyticsManager = AnalyticsManager.shared
    
    /// Conflict detection manager for AI analysis
    private let conflictDetectionManager = ConflictDetectionManager.shared
    
    /// Voice interaction manager for voice input
    private let voiceManager = VoiceInteractionManager.shared
    
    // MARK: - Computed Properties
    
    /// Filtered conflicts based on current filter setting
    var filteredConflicts: [MedicationConflict] {
        let filtered = filterConflicts(conflicts, by: currentFilter)
        return sortConflicts(filtered, by: currentSort)
    }
    
    /// Critical conflicts requiring immediate attention
    var criticalConflicts: [MedicationConflict] {
        return conflicts.filter { $0.highestSeverity == .critical }
    }
    
    /// Unresolved conflicts needing user action
    var unresolvedConflicts: [MedicationConflict] {
        return conflicts.filter { !$0.isResolved }
    }
    
    /// Indicates if there are urgent conflicts requiring attention
    var hasUrgentConflicts: Bool {
        return !criticalConflicts.isEmpty || conflicts.contains { $0.requiresUrgentAttention }
    }
    
    /// Count of conflicts for each filter type
    var filterCounts: [ConflictFilterType: Int] {
        var counts: [ConflictFilterType: Int] = [:]
        for filter in ConflictFilterType.allCases {
            counts[filter] = filterConflicts(conflicts, by: filter).count
        }
        return counts
    }
    
    /// Filtered analysis history based on search text
    var filteredAnalysisHistory: [ConflictDetectionManager.MedicationConflictAnalysis] {
        if searchText.isEmpty {
            return analysisHistory
        }
        return analysisHistory.filter { analysis in
            analysis.summary.localizedCaseInsensitiveContains(searchText) ||
            analysis.medications.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// Indicates if voice input is available
    var isVoiceAvailable: Bool {
        return voiceManager.hasPermission
    }
    
    /// Indicates if we have cached results available
    var hasCachedResults: Bool {
        return !analysisHistory.isEmpty
    }
    
    // MARK: - Initialization
    
    init() {
        logger.info("ConflictsViewModel initialized")
        
        // Check voice permissions on init
        Task {
            await voiceManager.checkPermissions()
        }
    }
    
    // MARK: - Data Loading
    
    /// Loads conflict data for current authenticated user
    /// Updates conflict summary and tracks analytics
    func loadData() async {
        guard let userId = authManager.currentUser?.id else {
            await handleError(AppError.authentication(.notAuthenticated))
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            logger.info("Loading conflicts for user: \(userId)")
            
            // Load conflicts from Core Data (Phase 3+: Replace with real implementation)
            conflicts = try await loadConflicts(for: userId)
            
            // Update summary statistics
            updateConflictSummary()
            
            // Track analytics
            analyticsManager.trackScreenViewed(AppStrings.TabTitles.conflicts)
            
            logger.info("Successfully loaded \(self.conflicts.count) conflicts")
            
        } catch {
            let appError = error as? AppError ?? AppError.data(.loadFailed)
            await handleError(appError)
            analyticsManager.trackError(category: "conflicts_data_load", error: appError)
        }
        
        isLoading = false
    }
    
    /// Refreshes data by syncing with Firebase and reloading
    func refreshData() async {
        logger.info("Refreshing conflicts data")
        
        // Sync in isolated context to prevent error propagation
        Task {
            do {
                try await dataSyncManager.syncPendingChanges()
            } catch {
                logger.error("Sync failed during refresh: \(error)")
            }
        }
        
        // Always reload data
        await loadData()
    }
    
    /// Loads conflicts from Core Data storage
    /// - Parameter userId: User ID to load conflicts for
    /// - Returns: Array of medication conflicts
    /// - Throws: AppError for data loading failures
    private func loadConflicts(for userId: String) async throws -> [MedicationConflict] {
        // Load conflicts from Core Data
        let conflicts = try await coreDataManager.fetchConflicts(for: userId)
        
        #if DEBUG
        // In DEBUG mode, add sample conflicts if none exist
        if conflicts.isEmpty {
            logger.debug("No conflicts in Core Data, using sample data for testing")
            return MedicationConflict.sampleConflicts.filter { $0.userId == userId }
        }
        #endif
        
        return conflicts
    }
    
    // MARK: - Conflict Analysis
    
    /// Performs AI-powered conflict analysis on user's current medications
    /// Integrates with Claude AI for comprehensive drug interaction checking
    func checkForConflicts() async {
        guard let userId = authManager.currentUser?.id else {
            await handleError(AppError.authentication(.notAuthenticated))
            return
        }
        
        isAnalyzing = true
        error = nil
        
        do {
            logger.info("Starting conflict analysis for user: \(userId)")
            
            // Get user's current medications and supplements
            let medications = try await coreDataManager.fetchMedications(for: userId)
            let supplements = try await coreDataManager.fetchSupplements(for: userId)
            
            // Validate we have medications to analyze
            guard !medications.isEmpty else {
                await handleError(AppError.data(.noData))
                isAnalyzing = false
                return
            }
            
            // Prepare medication names for analysis
            let medicationNames = medications.map { $0.name }
            let supplementNames = supplements.map { $0.name }
            
            logger.info("Analyzing \(medicationNames.count) medications and \(supplementNames.count) supplements")
            
            // Perform AI analysis using ConflictDetectionManager
            _ = medicationNames + supplementNames
            let analysis = try await conflictDetectionManager.analyzeMedications(
                medications: medicationNames,
                supplements: supplementNames
            )
            
            // Store analysis result
            currentAnalysis = analysis
            analysisHistory.insert(analysis, at: 0)
            
            // Save analysis results
            try await saveConflict(analysis)
            
            // Reload data to show new results
            await loadData()
            
            // Track analytics
            analyticsManager.trackConflictCheck(
                source: ConflictSource.manual.rawValue,
                conflictsFound: analysis.conflictsFound,
                severity: analysis.severity.rawValue
            )
            
            // Track successful completion for Siri shortcuts
            // TODO: Fix DynamicShortcutsManager reference - class not found
            // DynamicShortcutsManager.trackConflictAnalysisCompleted()
            
            logger.info("Conflict analysis completed - Conflicts found: \(analysis.conflictsFound)")
            
        } catch {
            let appError = error as? AppError ?? AppError.sync(.syncTimeout)
            await handleError(appError)
            analyticsManager.trackError(category: "conflict_analysis", error: appError)
        }
        
        isAnalyzing = false
    }
    
    /// Analyzes a specific natural language query about medications
    /// - Parameter query: User's medical question or concern
    func analyzeQuery(_ query: String) async {
        guard (authManager.currentUser?.id) != nil else {
            await handleError(AppError.authentication(.notAuthenticated))
            return
        }
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await handleError(AppError.data(.validationFailed))
            return
        }
        
        isAnalyzing = true
        error = nil
        
        do {
            logger.info("Analyzing query: \(query.prefix(50))...")
            
            // Perform AI query analysis
            let analysis = try await conflictDetectionManager.analyzeQuery(query)
            
            // Store analysis result
            currentAnalysis = analysis
            analysisHistory.insert(analysis, at: 0)
            
            // Save query analysis results
            try await saveConflict(analysis)
            
            // Reload data
            await loadData()
            
            // Track analytics
            analyticsManager.trackFeatureUsed("conflict_query_analysis")
            
            // Track successful completion for Siri shortcuts
            // TODO: Fix DynamicShortcutsManager reference - class not found
            // DynamicShortcutsManager.trackConflictAnalysisCompleted()
            
            logger.info("Query analysis completed")
            
        } catch {
            let appError = error as? AppError ?? AppError.sync(.syncTimeout)
            await handleError(appError)
            analyticsManager.trackError(category: "query_analysis", error: appError)
        }
        
        isAnalyzing = false
    }
    
    /// Saves conflict analysis to Core Data
    /// - Parameter analysis: MedicationConflictAnalysis to save
    /// - Throws: AppError for save failures
    private func saveConflict(_ analysis: ConflictDetectionManager.MedicationConflictAnalysis) async throws {
        // Convert analysis to MedicationConflict for storage
        let conflict = MedicationConflict.fromAnalysis(analysis, userId: authManager.currentUser?.id ?? "")
        
        // Save to Core Data (local only, no sync)
        try await coreDataManager.saveConflict(conflict)
        
        // Update local state
        conflicts.insert(conflict, at: 0)
        updateConflictSummary()
    }
    
    // MARK: - Conflict Management
    
    /// Marks a conflict as resolved by the user
    /// - Parameter conflict: Conflict to mark as resolved
    func resolveConflict(_ conflict: MedicationConflict) async {
        logger.info("Resolving conflict: \(conflict.id)")
        
        var resolvedConflict = conflict
        resolvedConflict.markAsResolved()
        
        do {
            // Update conflict in Core Data
            try await coreDataManager.saveConflict(resolvedConflict)
            
            // Update local state
            if let index = self.conflicts.firstIndex(where: { $0.id == conflict.id }) {
                self.conflicts[index] = resolvedConflict
            }
            
            // Update summary
            updateConflictSummary()
            
            // Track analytics
            analyticsManager.trackConflictResolved(severity: conflict.highestSeverity.rawValue)
            
            logger.info("Successfully resolved conflict")
            
        } catch {
            logger.error("Failed to resolve conflict: \(error)")
            await handleError(AppError.data(.saveFailed))
        }
    }
    
    /// Adds a user note to a specific conflict
    /// - Parameters:
    ///   - conflict: Conflict to add note to
    ///   - note: User's note text
    func addUserNote(to conflict: MedicationConflict, note: String) async {
        logger.info("Adding user note to conflict: \(conflict.id)")
        
        var updatedConflict = conflict
        updatedConflict.addUserNote(note)
        
        do {
            // Update conflict in Core Data
            try await coreDataManager.saveConflict(updatedConflict)
            
            // Update local state
            if let index = self.conflicts.firstIndex(where: { $0.id == conflict.id }) {
                self.conflicts[index] = updatedConflict
            }
                //update summary
            updateConflictSummary()
            // Track analytics
            analyticsManager.trackFeatureUsed("conflict_note_added")
            
            logger.info("Successfully added user note")
            
        } catch {
            logger.error("Failed to add user note: \(error)")
            await handleError(AppError.data(.saveFailed))
        }
    }
    
    /// Deletes a conflict from the user's history
    /// - Parameter conflict: Conflict to delete
    func deleteConflict(_ conflict: MedicationConflict) async {
        logger.info("Deleting conflict: \(conflict.id)")
        
        var deletedConflict = conflict
        deletedConflict.markDeleted()
        
        do {
            // Delete conflict from Core Data
            try await coreDataManager.deleteConflict(conflict.id)
            
            // Update local state
            self.conflicts.removeAll { $0.id == conflict.id }
            updateConflictSummary()
            
            // Track analytics
            analyticsManager.trackFeatureUsed("conflict_deleted")
            
            logger.info("Successfully deleted conflict")
            
        } catch {
            logger.error("Failed to delete conflict: \(error)")
            await handleError(AppError.data(.saveFailed))
        }
    }
    
    // MARK: - Filtering and Sorting
    
    /// Updates the current filter for conflicts display
    /// - Parameter filter: New filter to apply
    func updateFilter(_ filter: ConflictFilterType) {
        logger.debug("Updating filter to: \(filter.rawValue)")
        currentFilter = filter
        analyticsManager.trackFeatureUsed("conflicts_filtered_\(filter.rawValue)")
    }
    
    /// Updates the current sort option for conflicts display
    /// - Parameter sortOption: New sort option to apply
    func updateSort(_ sortOption: ConflictSortOption) {
        logger.debug("Updating sort to: \(sortOption.rawValue)")
        currentSort = sortOption
        analyticsManager.trackFeatureUsed("conflicts_sorted_\(sortOption.rawValue)")
    }
    
    /// Filters conflicts based on specified criteria
    /// - Parameters:
    ///   - conflicts: Array of conflicts to filter
    ///   - filter: Filter criteria to apply
    /// - Returns: Filtered array of conflicts
    private func filterConflicts(_ conflicts: [MedicationConflict], by filter: ConflictFilterType) -> [MedicationConflict] {
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
    
    /// Sorts conflicts based on specified criteria
    /// - Parameters:
    ///   - conflicts: Array of conflicts to sort
    ///   - sortOption: Sort criteria to apply
    /// - Returns: Sorted array of conflicts
    private func sortConflicts(_ conflicts: [MedicationConflict], by sortOption: ConflictSortOption) -> [MedicationConflict] {
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
    
    /// Updates the conflict summary statistics
    private func updateConflictSummary() {
        let allMedications = Set(conflicts.flatMap { $0.medications })
        let allSupplements = Set(conflicts.flatMap { $0.supplements })
        
        conflictSummary = ConflictAnalysisSummary(
            totalConflicts: conflicts.count,
            criticalConflicts: conflicts.filter { $0.highestSeverity == .critical }.count,
            highRiskConflicts: conflicts.filter {
                $0.highestSeverity == .high || $0.highestSeverity == .critical
            }.count,
            medicationsInvolved: allMedications,
            supplementsInvolved: allSupplements,
            lastAnalysisDate: conflicts.isEmpty ? nil : conflicts.first?.createdAt
        )
        
        logger.debug("Updated conflict summary - Total: \(self.conflictSummary.totalConflicts), Critical: \(self.conflictSummary.criticalConflicts)")
    }
    
    /// Generates comprehensive statistics about conflict detection
    /// - Returns: ConflictStatistics with detailed metrics
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
    
    /// Calculates average severity across all conflicts
    /// - Returns: Average severity as Double (1.0-4.0 scale)
    private func getAverageSeverity() -> Double {
        guard !conflicts.isEmpty else { return 0.0 }
        
        let totalSeverity = conflicts.reduce(0) { $0 + $1.highestSeverity.priority }
        return Double(totalSeverity) / Double(conflicts.count)
    }
    
    /// Identifies most common interaction types
    /// - Returns: Array of interaction types sorted by frequency
    private func getMostCommonInteractions() -> [String] {
        let interactions = conflicts.flatMap { $0.conflictDetails }.map { $0.interactionType }
        let grouped = Dictionary(grouping: interactions) { $0 }
        return grouped.sorted { $0.value.count > $1.value.count }.map { $0.key }
    }
    
    /// Calculates conflict detection rate
    /// - Returns: Percentage of analyses that found conflicts
    private func getDetectionRate() -> Double {
        guard !conflicts.isEmpty else { return 0.0 }
        
        let conflictsFound = conflicts.filter { $0.conflictsFound }.count
        return Double(conflictsFound) / Double(conflicts.count)
    }
    
    // MARK: - Educational Content
    
    /// Provides educational content based on conflict severity
    /// - Parameter severity: Conflict severity level
    /// - Returns: EducationalContent with guidance and recommendations
    func getEducationalContent(for severity: ConflictSeverity) -> EducationalContent {
        switch severity {
        case .none:
            return EducationalContent(
                title: AppStrings.Conflicts.noConflicts,
                description: AppStrings.Conflicts.noConflictsMessage,
                recommendations: []
            )
        case .low:
            return EducationalContent(
                title: AppStrings.Conflicts.conflictAnalysis,
                description: AppStrings.Conflicts.educationalInfo,
                recommendations: [
                    AppStrings.Conflicts.medicalGuidance,
                    AppStrings.Common.retry,
                    AppStrings.Conflicts.checkNow
                ]
            )
        case .medium:
            return EducationalContent(
                title: AppStrings.Conflicts.requiresAttention,
                description: AppStrings.Conflicts.medicalGuidanceDescription,
                recommendations: [
                    AppStrings.Conflicts.medicalGuidance,
                    AppStrings.Common.retry,
                    AppStrings.Conflicts.checkNow
                ]
            )
        case .high:
            return EducationalContent(
                title: AppStrings.Conflicts.high,
                description: AppStrings.Conflicts.medicalGuidanceDescription,
                recommendations: [
                    AppStrings.Conflicts.medicalGuidance,
                    AppStrings.Common.retry,
                    AppStrings.Conflicts.checkNow
                ]
            )
        case .critical:
            return EducationalContent(
                title: AppStrings.Conflicts.criticalConflicts,
                description: AppStrings.Conflicts.medicalGuidanceDescription,
                recommendations: [
                    AppStrings.Conflicts.medicalGuidance,
                    AppStrings.Common.retry,
                    AppStrings.Conflicts.checkNow
                ]
            )
        }
    }
    
    // MARK: - Error Handling
    
    /// Handles errors with user-friendly messaging and logging
    /// - Parameter error: AppError to handle
    private func handleError(_ error: AppError) async {
        self.error = error
        logger.error("ConflictsViewModel error: \(error.localizedDescription)")
        
        // Track error in analytics
        analyticsManager.trackError(error, context: "ConflictsViewModel")
    }
    
    /// Clears the current error state
    func clearError() {
        error = nil
        logger.debug("Error state cleared")
    }
    
    /// Retries the last failed action
    func retryLastAction() async {
        logger.info("Retrying last action")
        clearError()
        await loadData()
    }
    
    // MARK: - Real-time Monitoring (Phase 3+)
    
    /// Enables real-time conflict monitoring for medication changes
    func enableRealtimeMonitoring() async {
        logger.info("Enabling real-time conflict monitoring")
        analyticsManager.trackFeatureUsed("realtime_monitoring_enabled")
        
        // TODO: Phase 3+ - Implement real-time monitoring integration
        // This would listen for medication/supplement changes and automatically check conflicts
    }
    
    /// Disables real-time conflict monitoring
    func disableRealtimeMonitoring() async {
        logger.info("Disabling real-time conflict monitoring")
        analyticsManager.trackFeatureUsed("realtime_monitoring_disabled")
        
        // TODO: Phase 3+ - Disable real-time monitoring
    }
    
    // MARK: - Voice Input Methods
    
    /// Current voice transcription from voice manager
    var currentTranscription: String {
        voiceManager.transcribedText
    }
    
    /// Current recording state from voice manager
    var isCurrentlyRecording: Bool {
        voiceManager.isListening
    }
    
    /// Starts voice recording for conflict query
    func startVoiceQuery() async {
        do {
            try await voiceManager.startRecording(context: .conflictQuery)
            analyticsManager.trackVoiceInputStarted(context: VoiceInteractionContext.conflictQuery.rawValue)
        } catch {
            let appError = error as? AppError ?? AppError.voiceInteraction(.recordingFailed)
            await handleError(appError)
            analyticsManager.trackError(category: "voice_recording_start", error: appError)
        }
    }
    
    /// Stops voice recording and processes the query
    func stopVoiceQuery() async {
        do {
            let transcription = try await voiceManager.stopRecording()
            if !transcription.isEmpty {
                voiceQueryText = transcription
                await analyzeQuery(transcription)
                
                analyticsManager.trackVoiceInputCompleted(
                    duration: voiceManager.recordingDuration,
                    wordCount: transcription.split(separator: " ").count
                )
            }
        } catch {
            let appError = error as? AppError ?? AppError.voiceInteraction(.transcriptionFailed)
            await handleError(appError)
            analyticsManager.trackError(category: "voice_transcription", error: appError)
        }
    }
    
    /// Cancels voice recording without processing
    func cancelVoiceQuery() async {
        do {
            _ = try await voiceManager.stopRecording()
            voiceQueryText = ""
        } catch {
            logger.error("Failed to cancel voice recording: \(error)")
            analyticsManager.trackError(category: "voice_cancel", error: error)
        }
    }
    
    // MARK: - Analysis History Methods
    
    /// Clears analysis history
    func clearAnalysisHistory() {
        analysisHistory.removeAll()
        analyticsManager.trackFeatureUsed("analysis_history_cleared")
    }
    
    /// Exports analysis history
    func exportAnalysisHistory() async -> URL? {
        do {
            let exportData = analysisHistory.map { analysis in
                """
                Date: \(analysis.timestamp.formatted())
                Medications: \(analysis.medications.joined(separator: ", "))
                Summary: \(analysis.summary)
                Severity: \(analysis.overallSeverity.rawValue.capitalized)
                Conflicts: \(analysis.conflictCount)
                ---
                """
            }.joined(separator: "\n")
            
            let fileName = "conflict_analysis_\(Date().formatted(.iso8601)).txt"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try exportData.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            
            analyticsManager.trackFeatureUsed("analysis_history_exported")
            return url
        } catch {
            logger.error("Failed to export analysis history: \(error)")
            analyticsManager.trackError(category: "export_history", error: error)
            return nil
        }
    }
    
}

// MARK: - Supporting Models

/// Statistics about conflict detection performance and usage
struct ConflictStatistics {
    let totalAnalyses: Int
    let conflictsDetected: Int
    let conflictsResolved: Int
    let averageSeverity: Double
    let mostCommonInteractions: [String]
    let detectionRate: Double
    
    /// Calculates resolution rate percentage
    var resolutionRate: Double {
        guard conflictsDetected > 0 else { return 0.0 }
        return Double(conflictsResolved) / Double(conflictsDetected)
    }
    
    /// Detection rate as formatted percentage string
    var detectionRatePercentage: String {
        return "\(Int(detectionRate * 100))%"
    }
    
    /// Resolution rate as formatted percentage string
    var resolutionRatePercentage: String {
        return "\(Int(resolutionRate * 100))%"
    }
}

/// Educational content for user guidance
struct EducationalContent {
    let title: String
    let description: String
    let recommendations: [String]
}

// MARK: - Sample Data Extension

#if DEBUG
extension ConflictsViewModel {
    /// Sample view model for development and testing
    static let sampleViewModel: ConflictsViewModel = {
        let viewModel = ConflictsViewModel()
        viewModel.conflicts = MedicationConflict.sampleConflicts
        viewModel.conflictSummary = ConflictAnalysisSummary.sampleSummary
        return viewModel
    }()
}

extension ConflictStatistics {
    /// Sample statistics for development and testing
    static let sampleStatistics = ConflictStatistics(
        totalAnalyses: 12,
        conflictsDetected: 4,
        conflictsResolved: 3,
        averageSeverity: 2.5,
        mostCommonInteractions: [
            "Drug-Drug Interaction",
            "Drug-Supplement Interaction"
        ],
        detectionRate: 0.33
    )
}

extension EducationalContent {
    /// Sample educational content for development and testing
    static let sampleContent = EducationalContent(
        title: AppStrings.Conflicts.conflictAnalysis,
        description: AppStrings.Conflicts.educationalInfo,
        recommendations: [
            AppStrings.Conflicts.medicalGuidance,
            AppStrings.Common.retry,
            AppStrings.Conflicts.checkNow
        ]
    )
}
#endif
