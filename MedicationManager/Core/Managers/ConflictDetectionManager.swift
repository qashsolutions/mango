import Foundation
import OSLog
import CoreData
import Observation

// MARK: - Conflict Detection Manager
@MainActor
@Observable
final class ConflictDetectionManager {
    // MARK: - Type Aliases
    typealias MedicationConflictAnalysis = ClaudeAIClient.ConflictAnalysis
    
    static let shared = ConflictDetectionManager()
    
    // MARK: - Observable Properties
    private(set) var isAnalyzing = false
    private(set) var lastAnalysis: ClaudeAIClient.ConflictAnalysis?
    private(set) var analysisHistory: [ClaudeAIClient.ConflictAnalysis] = []
    private(set) var cachedAnalyses: [String: ClaudeAIClient.ConflictAnalysis] = [:]
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "ConflictDetectionManager")
    private let claudeClient = ClaudeAIClient.shared
    private let analyticsManager = AnalyticsManager.shared
    private let cacheExpirationHours = Configuration.ClaudeAPI.cacheExpirationHours
    
    // Subscription limits
    private let freeUserAnalysisLimit = Configuration.App.freeUserAnalysisLimit
    private let freeUserAnalysisResetHours = Configuration.App.freeUserAnalysisResetHours
    
    private init() {
        loadAnalysisHistory()
        cleanExpiredCache()
    }
    
    // MARK: - Public Methods
    
    /// Analyze conflicts for a list of medications
    func analyzeConflicts(for medications: [String], supplements: [String] = []) async throws -> ClaudeAIClient.ConflictAnalysis {
        guard !medications.isEmpty else {
            logger.warning("No medications provided for analysis")
            throw AppError.data(.noData)
        }
        
        // Check cache first
        let cacheKey = generateCacheKey(medications: medications, supplements: supplements)
        if let cachedAnalysis = getCachedAnalysis(for: cacheKey) {
            logger.info("Returning cached analysis for \(medications.count) medications")
            analyticsManager.trackConflictAnalysis(
                medicationCount: medications.count,
                supplementCount: supplements.count,
                conflictsFound: cachedAnalysis.conflictsFound,
                cached: true
            )
            var analysisWithCacheFlag = cachedAnalysis
            analysisWithCacheFlag.fromCache = true
            return analysisWithCacheFlag
        }
        
        // Check subscription limits
        try await checkAnalysisLimits()
        
        // Start analysis
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        logger.info("Starting conflict analysis for \(medications.count) medications, \(supplements.count) supplements")
        
        do {
            // Make API call with retry logic
            let analysis = try await claudeClient.analyzeMedicationConflicts(
                medications: medications,
                supplements: supplements
            )
            
            // Cache the result
            cacheAnalysis(analysis, for: cacheKey)
            
            // Update state
            lastAnalysis = analysis
            analysisHistory.append(analysis)
            saveAnalysisHistory()
            
            // Track analytics
            analyticsManager.trackConflictAnalysis(
                medicationCount: medications.count,
                supplementCount: supplements.count,
                conflictsFound: analysis.conflictsFound,
                cached: false
            )
            
            // Log severity if conflicts found
            if analysis.conflictsFound {
                logger.warning("Conflicts found: \(analysis.conflicts.count) with severity: \(analysis.severity.rawValue)")
            }
            
            return analysis
            
        } catch {
            logger.error("Conflict analysis failed: \(error)")
            analyticsManager.trackError(category: "conflict_detection", error: error)
            throw error
        }
    }
    
    /// Analyze medications for conflicts
    func analyzeMedications(medications: [String], supplements: [String]) async throws -> MedicationConflictAnalysis {
        // This is essentially a wrapper around analyzeConflicts with a different return type name
        // MedicationConflictAnalysis is expected to be the same as ClaudeAIClient.ConflictAnalysis
        return try await analyzeConflicts(for: medications, supplements: supplements)
    }
    
    /// Analyze a natural language query about medications
    func analyzeNaturalLanguageQuery(_ query: String) async throws -> ClaudeAIClient.ConflictAnalysis {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.data(.validationFailed)
        }
        
        // Get user's current medications for context
        let userMedications = await getCurrentUserMedications()
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        logger.info("Processing natural language query: \(query)")
        
        do {
            let analysis = try await claudeClient.analyzeNaturalLanguageQuery(
                query,
                userMedications: userMedications
            )
            
            // Update state
            lastAnalysis = analysis
            analysisHistory.append(analysis)
            saveAnalysisHistory()
            
            // Track analytics
            analyticsManager.trackVoiceQuery(
                queryType: "conflict_check",
                success: true
            )
            
            return analysis
            
        } catch {
            logger.error("Natural language query failed: \(error)")
            analyticsManager.trackVoiceQuery(
                queryType: "conflict_check",
                success: false
            )
            throw error
        }
    }
    
    /// Analyze query - wrapper for analyzeNaturalLanguageQuery
    func analyzeQuery(_ query: String) async throws -> ClaudeAIClient.ConflictAnalysis {
        return try await analyzeNaturalLanguageQuery(query)
    }
    
    /// Clear analysis history
    func clearHistory() {
        analysisHistory.removeAll()
        saveAnalysisHistory()
        logger.info("Analysis history cleared")
    }
    
    /// Filter history by severity
    func filterHistory(by severity: ClaudeAIClient.ConflictSeverity? = nil) -> [ClaudeAIClient.ConflictAnalysis] {
        guard let severity = severity else { return analysisHistory }
        return analysisHistory.filter { $0.severity == severity }
    }
    
    /// Search history
    func searchHistory(query: String) -> [ClaudeAIClient.ConflictAnalysis] {
        let lowercasedQuery = query.lowercased()
        return analysisHistory.filter { analysis in
            // Search in medications
            let medicationsMatch = analysis.medicationsAnalyzed.contains { medication in
                medication.lowercased().contains(lowercasedQuery)
            }
            
            // Search in summary
            let summaryMatch = analysis.summary.lowercased().contains(lowercasedQuery)
            
            // Search in conflicts
            let conflictsMatch = analysis.conflicts.contains { conflict in
                conflict.drug1.lowercased().contains(lowercasedQuery) ||
                conflict.drug2.lowercased().contains(lowercasedQuery) ||
                conflict.description.lowercased().contains(lowercasedQuery)
            }
            
            return medicationsMatch || summaryMatch || conflictsMatch
        }
    }
    
    /// Export analysis history
    func exportHistory() -> String {
        var export = "Medication Conflict Analysis History\n"
        export += "Generated: \(Date().formatted())\n\n"
        
        for (index, analysis) in analysisHistory.enumerated() {
            export += "Analysis #\(index + 1)\n"
            export += "Date: \(analysis.timestamp.formatted())\n"
            export += "Medications: \(analysis.medicationsAnalyzed.joined(separator: ", "))\n"
            export += "Severity: \(analysis.severity.rawValue)\n"
            export += "Summary: \(analysis.summary)\n"
            
            if !analysis.conflicts.isEmpty {
                export += "\nConflicts:\n"
                for conflict in analysis.conflicts {
                    export += "- \(conflict.drug1) + \(conflict.drug2): \(conflict.description)\n"
                    export += "  Recommendation: \(conflict.recommendation)\n"
                }
            }
            
            if !analysis.recommendations.isEmpty {
                export += "\nRecommendations:\n"
                for recommendation in analysis.recommendations {
                    export += "- \(recommendation)\n"
                }
            }
            
            export += "\n---\n\n"
        }
        
        return export
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(medications: [String], supplements: [String]) -> String {
        let allItems = (medications + supplements).sorted().joined(separator: ",")
        return allItems.lowercased()
    }
    
    private func getCachedAnalysis(for key: String) -> ClaudeAIClient.ConflictAnalysis? {
        guard let cached = cachedAnalyses[key] else { return nil }
        
        // Check if cache is expired
        let expirationDate = cached.timestamp.addingTimeInterval(TimeInterval(cacheExpirationHours * 3600))
        if Date() > expirationDate {
            cachedAnalyses.removeValue(forKey: key)
            return nil
        }
        
        return cached
    }
    
    private func cacheAnalysis(_ analysis: ClaudeAIClient.ConflictAnalysis, for key: String) {
        cachedAnalyses[key] = analysis
        
        // Limit cache size
        if cachedAnalyses.count > Configuration.App.maxCacheSize {
            cleanExpiredCache()
        }
    }
    
    private func cleanExpiredCache() {
        let now = Date()
        cachedAnalyses = cachedAnalyses.filter { _, analysis in
            let expirationDate = analysis.timestamp.addingTimeInterval(TimeInterval(cacheExpirationHours * 3600))
            return now < expirationDate
        }
    }
    
    private func checkAnalysisLimits() async throws {
        // TODO: Implement subscription checking
        // For now, we'll track usage in analytics
        
        // Check if user has active subscription
        let hasSubscription = false // TODO: Check actual subscription status
        
        if !hasSubscription {
            // Count analyses in last 24 hours
            let recentAnalyses = analysisHistory.filter { analysis in
                analysis.timestamp > Date().addingTimeInterval(-TimeInterval(freeUserAnalysisResetHours * 3600))
            }
            
            if recentAnalyses.count >= freeUserAnalysisLimit {
                logger.warning("User exceeded free analysis limit")
                throw AppError.subscription(.subscriptionExpired)
            }
        }
    }
    
    private func getCurrentUserMedications() async -> [String] {
        // TODO: Integrate with actual medication data
        // For now, return empty array
        return []
    }
    
    // MARK: - Persistence
    
    private func loadAnalysisHistory() {
        // TODO: Load from Core Data or UserDefaults
        // For now, start with empty history
        analysisHistory = []
    }
    
    private func saveAnalysisHistory() {
        // TODO: Save to Core Data or UserDefaults
        // Limit history size
        if analysisHistory.count > Configuration.App.maxHistorySize {
            analysisHistory = Array(analysisHistory.suffix(Configuration.App.maxHistorySize))
        }
    }
}

// MARK: - Convenience Methods
extension ConflictDetectionManager {
    
    /// Quick check for any conflicts
    func hasConflicts(for medications: [String]) async -> Bool {
        do {
            let analysis = try await analyzeConflicts(for: medications)
            return analysis.conflictsFound
        } catch {
            logger.error("Quick conflict check failed: \(error)")
            return false
        }
    }
    
    /// Get severity for medications
    func getSeverity(for medications: [String]) async -> ClaudeAIClient.ConflictSeverity {
        do {
            let analysis = try await analyzeConflicts(for: medications)
            return analysis.severity
        } catch {
            return .none
        }
    }
    
    /// Check if analysis is available in cache
    func isCached(medications: [String], supplements: [String] = []) -> Bool {
        let cacheKey = generateCacheKey(medications: medications, supplements: supplements)
        return getCachedAnalysis(for: cacheKey) != nil
    }
}

// MARK: - Voice Integration
extension ConflictDetectionManager {
    
    /// Process voice transcription for conflict checking
    func processVoiceQuery(_ transcription: String) async throws -> ClaudeAIClient.ConflictAnalysis {
        logger.info("Processing voice query: \(transcription)")
        
        // Start voice processing animation
        analyticsManager.trackVoiceInput(
            context: "conflict_query",
            duration: 0,
            wordCount: transcription.split(separator: " ").count
        )
        
        return try await analyzeNaturalLanguageQuery(transcription)
    }
    
    /// Get voice-optimized response
    func getVoiceResponse(for analysis: ClaudeAIClient.ConflictAnalysis) -> String {
        var response = analysis.summary
        
        // Add severity if conflicts found
        if analysis.conflictsFound {
            response += " "
            switch analysis.severity {
            case .critical:
                response += AppStrings.Conflicts.Severity.critical
            case .high:
                response += AppStrings.Conflicts.Severity.high
            case .medium:
                response += AppStrings.Conflicts.Severity.medium
            case .low:
                response += AppStrings.Conflicts.Severity.low
            case .none:
                break
            }
        }
        
        // Always add disclaimer
        response += " " + AppStrings.AI.consultDoctor
        
        return response
    }
}
