import Foundation
import OSLog
import SwiftUI

// MARK: - Claude API Client
actor ClaudeAIClient {
    static let shared = ClaudeAIClient()
    
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "ClaudeAIClient")
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(Configuration.ClaudeAPI.timeoutSeconds)
        config.timeoutIntervalForResource = TimeInterval(Configuration.ClaudeAPI.timeoutSeconds * 2)
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Models
    
    struct Message: Codable, Sendable {
        let role: String
        let content: String
    }
    
    struct Request: Codable, Sendable {
        let model: String
        let messages: [Message]
        let maxTokens: Int
        let temperature: Double
        let system: String?
        
        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case maxTokens = "max_tokens"
            case temperature
            case system
        }
    }
    
    struct Response: Codable, Sendable {
        let id: String
        let type: String
        let role: String
        let content: [Content]
        let model: String
        let stopReason: String?
        let stopSequence: String?
        let usage: Usage
        
        enum CodingKeys: String, CodingKey {
            case id, type, role, content, model
            case stopReason = "stop_reason"
            case stopSequence = "stop_sequence"
            case usage
        }
    }
    
    struct Content: Codable, Sendable {
        let type: String
        let text: String
    }
    
    struct Usage: Codable, Sendable {
        let inputTokens: Int
        let outputTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
    
    struct ErrorResponse: Codable, Sendable {
        let type: String
        let error: APIError
    }
    
    struct APIError: Codable, Sendable {
        let type: String
        let message: String
    }
    
    // MARK: - Conflict Analysis Models
    
    struct ConflictAnalysis: Codable, Sendable, Hashable {
        let conflictsFound: Bool
        let severity: ConflictSeverity
        let conflicts: [DrugConflict]
        let recommendations: [String]
        let confidence: Double
        let summary: String
        let timestamp: Date
        let medicationsAnalyzed: [String]
        var fromCache: Bool = false
        
        // Computed properties for UI
        var overallSeverity: ConflictSeverity {
            severity
        }
        
        var conflictCount: Int {
            conflicts.count
        }
        
        var medications: [String] {
            medicationsAnalyzed
        }
        
        var requiresDoctor: Bool {
            severity == .high || severity == .critical
        }
        
        var additionalInfo: String? {
            // Could be populated from API response if needed
            nil
        }
    }
    
    enum ConflictSeverity: String, Codable, Sendable, Hashable {
        case none = "none"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
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
    }
    
    struct DrugConflict: Codable, Identifiable, Sendable, Hashable {
        let id: String
        let drug1: String
        let drug2: String
        let severity: ConflictSeverity
        let description: String
        let recommendation: String
        let mechanism: String?
        let clinicalSignificance: String?
        let management: String?
        let references: [String]
        
        // Default initializer for backward compatibility
        init(
            id: String? = nil,
            drug1: String,
            drug2: String,
            severity: ConflictSeverity,
            description: String,
            recommendation: String,
            mechanism: String? = nil,
            clinicalSignificance: String? = nil,
            management: String? = nil,
            references: [String] = []
        ) {
            self.id = id ?? UUID().uuidString
            self.drug1 = drug1
            self.drug2 = drug2
            self.severity = severity
            self.description = description
            self.recommendation = recommendation
            self.mechanism = mechanism
            self.clinicalSignificance = clinicalSignificance
            self.management = management
            self.references = references
        }
    }
    
    // MARK: - Public Methods
    
    /// Analyze medication conflicts using Claude AI
    func analyzeMedicationConflicts(medications: [String], supplements: [String] = []) async throws -> ConflictAnalysis {
        logger.info("Analyzing conflicts for \(medications.count) medications and \(supplements.count) supplements")
        
        // Get API key
        let apiKey = try await KeychainManager.shared.getClaudeAPIKey()
        
        // Build the prompt
        let prompt = buildConflictAnalysisPrompt(medications: medications, supplements: supplements)
        
        // Create request
        let request = Request(
            model: Configuration.ClaudeAPI.modelName,
            messages: [Message(role: "user", content: prompt)],
            maxTokens: Configuration.ClaudeAPI.voiceQueryMaxTokens,
            temperature: Configuration.ClaudeAPI.temperature,
            system: Configuration.ClaudeAPI.medicalContextSystemPrompt
        )
        
        // Make API call
        let response = try await makeAPICall(request: request, apiKey: apiKey)
        
        // Parse response
        let analysis = try parseConflictAnalysis(from: response, medications: medications)
        
        // Log success
        logger.info("Successfully analyzed conflicts: \(analysis.conflictsFound ? "Found" : "None found")")
        
        return analysis
    }
    
    /// Analyze a natural language query about medications
    func analyzeNaturalLanguageQuery(_ query: String, userMedications: [String] = []) async throws -> ConflictAnalysis {
        logger.info("Analyzing natural language query: \(query)")
        
        // Get API key
        let apiKey = try await KeychainManager.shared.getClaudeAPIKey()
        
        // Build the prompt
        let prompt = buildNaturalLanguagePrompt(query: query, userMedications: userMedications)
        
        // Create request
        let request = Request(
            model: Configuration.ClaudeAPI.modelName,
            messages: [Message(role: "user", content: prompt)],
            maxTokens: Configuration.ClaudeAPI.voiceQueryMaxTokens,
            temperature: Configuration.ClaudeAPI.temperature,
            system: Configuration.ClaudeAPI.medicalContextSystemPrompt
        )
        
        // Make API call
        let response = try await makeAPICall(request: request, apiKey: apiKey)
        
        // Parse response
        let analysis = try parseConflictAnalysis(from: response, medications: userMedications)
        
        return analysis
    }
    
    // MARK: - Private Methods
    
    private func makeAPICall(request: Request, apiKey: String) async throws -> Response {
        guard let url = URL(string: Configuration.ClaudeAPI.endpoint) else {
            throw AppError.claudeAPI(.invalidRequest)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Configuration.ClaudeAPI.apiVersion, forHTTPHeaderField: "anthropic-version")
        
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            logger.error("Failed to encode request: \(error)")
            throw AppError.claudeAPI(.invalidRequest)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.claudeAPI(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let apiResponse = try decoder.decode(Response.self, from: data)
                    logger.debug("API call successful, used \(apiResponse.usage.inputTokens) input tokens, \(apiResponse.usage.outputTokens) output tokens")
                    return apiResponse
                } catch {
                    logger.error("Failed to decode response: \(error)")
                    throw AppError.claudeAPI(.parsingError)
                }
                
            case 401:
                throw AppError.claudeAPI(.unauthorized)
                
            case 429:
                throw AppError.claudeAPI(.rateLimited)
                
            case 400:
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    logger.error("API error: \(errorResponse.error.message)")
                    
                    if errorResponse.error.type.contains("invalid_request") {
                        throw AppError.claudeAPI(.invalidRequest)
                    } else if errorResponse.error.type.contains("tokens") {
                        throw AppError.claudeAPI(.tokenLimitExceeded)
                    }
                }
                throw AppError.claudeAPI(.invalidRequest)
                
            case 500...599:
                throw AppError.claudeAPI(.serverError)
                
            default:
                logger.error("Unexpected status code: \(httpResponse.statusCode)")
                throw AppError.claudeAPI(.invalidResponse)
            }
            
        } catch let error as AppError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw AppError.claudeAPI(.networkTimeout)
            }
            logger.error("Network error: \(error)")
            throw AppError.network(.unknown)
        }
    }
    
    private func buildConflictAnalysisPrompt(medications: [String], supplements: [String]) -> String {
        return """
        Analyze the following medications and supplements for potential interactions:
        
        Medications: \(medications.joined(separator: ", "))
        Supplements: \(supplements.joined(separator: ", "))
        
        Please provide a detailed analysis in the following JSON format:
        {
            "conflictsFound": boolean,
            "severity": "none|low|medium|high|critical",
            "conflicts": [
                {
                    "id": "unique identifier",
                    "drug1": "medication name",
                    "drug2": "medication or supplement name",
                    "severity": "low|medium|high|critical",
                    "description": "Clear explanation of the interaction",
                    "recommendation": "Specific actionable advice",
                    "mechanism": "How the interaction occurs (optional)",
                    "clinicalSignificance": "Clinical importance (optional)",
                    "management": "How to manage the interaction (optional)",
                    "references": ["List of reference sources"]
                }
            ],
            "recommendations": ["General recommendations list"],
            "confidence": 0.0-1.0,
            "summary": "Brief overall summary optimized for voice output"
        }
        
        Guidelines:
        1. Be thorough but concise
        2. Focus on clinically significant interactions
        3. Provide actionable recommendations
        4. Use language suitable for patients
        5. Format the summary to be easily spoken by text-to-speech
        6. Always recommend consulting healthcare providers for critical interactions
        """
    }
    
    private func buildNaturalLanguagePrompt(query: String, userMedications: [String]) -> String {
        var prompt = "User's natural language query: \"\(query)\"\n\n"
        
        if !userMedications.isEmpty {
            prompt += "User's current medications: \(userMedications.joined(separator: ", "))\n\n"
        }
        
        prompt += """
        Please analyze this query about medication interactions and provide a response in the following JSON format:
        {
            "conflictsFound": boolean,
            "severity": "none|low|medium|high|critical",
            "conflicts": [
                {
                    "id": "unique identifier",
                    "drug1": "medication name",
                    "drug2": "medication name",
                    "severity": "low|medium|high|critical",
                    "description": "Clear explanation",
                    "recommendation": "Specific advice",
                    "mechanism": "How the interaction occurs (optional)",
                    "clinicalSignificance": "Clinical importance (optional)",
                    "management": "How to manage the interaction (optional)",
                    "references": ["List of reference sources"]
                }
            ],
            "recommendations": ["List of recommendations"],
            "confidence": 0.0-1.0,
            "summary": "Natural, conversational response to the user's question"
        }
        
        Important:
        1. Answer the user's specific question directly
        2. Use conversational, easy-to-understand language
        3. If the query mentions medications not in their current list, still analyze them
        4. Format the summary as if speaking directly to the user
        5. Be helpful but always recommend consulting healthcare providers
        """
        
        return prompt
    }
    
    private func parseConflictAnalysis(from response: Response, medications: [String]) throws -> ConflictAnalysis {
        guard let content = response.content.first?.text else {
            throw AppError.claudeAPI(.parsingError)
        }
        
        // Extract JSON from the response
        let jsonString = extractJSON(from: content) ?? content
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AppError.claudeAPI(.parsingError)
        }
        
        do {
            var analysis = try decoder.decode(ConflictAnalysis.self, from: jsonData)
            
            // Add metadata
            analysis = ConflictAnalysis(
                conflictsFound: analysis.conflictsFound,
                severity: analysis.severity,
                conflicts: analysis.conflicts,
                recommendations: analysis.recommendations,
                confidence: analysis.confidence,
                summary: analysis.summary,
                timestamp: Date(),
                medicationsAnalyzed: medications
            )
            
            return analysis
        } catch {
            logger.error("Failed to parse conflict analysis: \(error)")
            
            // Fallback: Create a basic response
            return ConflictAnalysis(
                conflictsFound: false,
                severity: .none,
                conflicts: [],
                recommendations: [AppStrings.AI.consultDoctor],
                confidence: 0.5,
                summary: content,
                timestamp: Date(),
                medicationsAnalyzed: medications
            )
        }
    }
    
    private func extractJSON(from text: String) -> String? {
        // Try to extract JSON from the response
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        return nil
    }
}

// MARK: - Retry Logic
extension ClaudeAIClient {
    func analyzeWithRetry(medications: [String], maxRetries: Int = Configuration.ClaudeAPI.maxRetries) async throws -> ConflictAnalysis {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await analyzeMedicationConflicts(medications: medications)
            } catch let error as AppError {
                lastError = error
                
                // Don't retry for certain errors
                switch error {
                case .claudeAPI(.unauthorized), .claudeAPI(.apiKeyMissing), .claudeAPI(.tokenLimitExceeded):
                    throw error
                case .claudeAPI(.rateLimited):
                    // Exponential backoff for rate limiting
                    let delay = pow(2.0, Double(attempt)) * Configuration.App.apiRetryBaseDelay
                    logger.info("Rate limited, waiting \(delay) seconds before retry \(attempt + 1)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                default:
                    // Short delay for other errors
                    try await Task.sleep(nanoseconds: UInt64(Configuration.App.apiRetryShortDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AppError.claudeAPI(.serverError)
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension ClaudeAIClient.ConflictAnalysis {
    static let sampleAnalysis = ClaudeAIClient.ConflictAnalysis(
        conflictsFound: true,
        severity: .high,
        conflicts: [
            ClaudeAIClient.DrugConflict(
                drug1: "Warfarin",
                drug2: "Aspirin",
                severity: .high,
                description: "Increased risk of bleeding when warfarin is combined with aspirin. Both medications affect blood clotting.",
                recommendation: "Monitor INR closely and watch for signs of bleeding",
                mechanism: "Both drugs inhibit platelet function and affect coagulation cascade",
                clinicalSignificance: "Major - can result in serious bleeding complications",
                management: "Consider alternative pain relief, monitor INR more frequently, watch for bleeding signs",
                references: ["FDA Drug Interaction Database", "Clinical Pharmacology Reference"]
            ),
            ClaudeAIClient.DrugConflict(
                drug1: "Lisinopril",
                drug2: "Ibuprofen",
                severity: .medium,
                description: "NSAIDs like ibuprofen may reduce the effectiveness of ACE inhibitors like lisinopril",
                recommendation: "Consider acetaminophen for pain relief instead",
                mechanism: "NSAIDs inhibit prostaglandin synthesis, reducing renal blood flow",
                clinicalSignificance: "Moderate - may lead to reduced blood pressure control",
                management: "Use lowest effective NSAID dose, monitor blood pressure regularly",
                references: ["American Heart Association Guidelines"]
            )
        ],
        recommendations: [
            "Monitor INR levels more frequently",
            "Watch for signs of unusual bleeding or bruising",
            "Consider alternative pain management options",
            "Consult with your healthcare provider before making changes"
        ],
        confidence: 0.85,
        summary: "Found 2 interactions. High severity interaction between Warfarin and Aspirin requires close monitoring. Medium severity interaction between Lisinopril and Ibuprofen may affect blood pressure control.",
        timestamp: Date(),
        medicationsAnalyzed: ["Warfarin", "Aspirin", "Lisinopril", "Ibuprofen"]
    )
    
    static let sampleNoConflicts = ClaudeAIClient.ConflictAnalysis(
        conflictsFound: false,
        severity: .none,
        conflicts: [],
        recommendations: [
            "Continue taking medications as prescribed",
            "Maintain regular check-ups with your healthcare provider"
        ],
        confidence: 0.95,
        summary: "No significant interactions found between your medications. Continue taking them as prescribed.",
        timestamp: Date(),
        medicationsAnalyzed: ["Metformin", "Vitamin D", "Omega-3"]
    )
}

#endif
