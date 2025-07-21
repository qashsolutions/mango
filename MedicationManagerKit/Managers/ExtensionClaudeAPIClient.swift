//
//  ExtensionClaudeAPIClient.swift
//  MedicationManagerKit
//
//  Created by Claude on 2025/01/14.
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import Foundation
import OSLog

/// Lightweight Claude API client optimized for extension memory constraints
/// Implements minimal dependencies and efficient request/response handling
@available(iOS 18.0, *)
public actor ExtensionClaudeAPIClient {
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    public static let shared = ExtensionClaudeAPIClient()
    
    /// URL session configured for extensions
    private let session: URLSession
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.medicationmanager.kit", category: "ClaudeAPI")
    
    /// API endpoint from Configuration
    private let apiEndpoint = Configuration.ClaudeAPI.endpoint
    
    /// API version
    private let apiVersion = Configuration.ClaudeAPI.apiVersion
    
    /// Model name
    private let modelName = Configuration.ClaudeAPI.modelName
    
    /// Maximum tokens for extension responses
    private let maxTokens = Configuration.ClaudeAPI.voiceQueryMaxTokens
    
    /// Request timeout
    private let timeout = Configuration.Extensions.Timeouts.apiCallTimeout
    
    // MARK: - Response Models
    
    /// Minimal response model for memory efficiency
    public struct ConflictAnalysisResponse: Sendable {
        public let hasConflicts: Bool
        public let severity: ConflictSeverity
        public let summary: String
        public let conflicts: [MedicationConflict]
        public let recommendations: [String]
        public let confidence: Double
    }
    
    /// Individual conflict detail
    public struct MedicationConflict: Sendable {
        public let medication1: String
        public let medication2: String
        public let severity: ConflictSeverity
        public let description: String
        public let recommendation: String
    }
    
    /// Conflict severity levels
    public enum ConflictSeverity: String, Sendable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case none = "None"
        
        /// Numeric value for sorting
        public var numericValue: Int {
            switch self {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            case .none: return 0
            }
        }
        
        /// Color name for UI
        public var colorName: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "yellow"
            case .low: return "blue"
            case .none: return "green"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Configure URLSession for extensions
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.waitsForConnectivity = false // Don't wait in extensions
        configuration.allowsCellularAccess = true
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = false
        
        // Memory efficient settings
        configuration.urlCache = nil // No caching in extension
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Public Methods
    
    /// Analyze medication conflicts using Claude API
    /// - Parameters:
    ///   - medications: Array of medications to check
    ///   - supplements: Array of supplements to check
    ///   - voiceOptimized: Whether to optimize response for voice output
    /// - Returns: Conflict analysis response
    public func analyzeConflicts(
        medications: [SendableMedication],
        supplements: [SendableSupplement] = [],
        voiceOptimized: Bool = true
    ) async throws -> ConflictAnalysisResponse {
        
        // Check memory before processing
        try checkMemoryUsage()
        
        // Get API key
        let apiKey = try await ExtensionKeychain.shared.getClaudeAPIKey()
        
        // Build prompt
        let prompt = buildConflictAnalysisPrompt(
            medications: medications,
            supplements: supplements,
            voiceOptimized: voiceOptimized
        )
        
        // Create request
        let request = try createAPIRequest(prompt: prompt, apiKey: apiKey)
        
        // Make API call
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        try validateResponse(response, data: data)
        
        // Parse response
        return try parseConflictResponse(from: data)
    }
    
    /// Answer a medical question using Claude API
    /// - Parameters:
    ///   - question: The question to answer
    ///   - context: User's medications for context
    /// - Returns: Answer string optimized for voice
    public func answerMedicalQuestion(
        _ question: String,
        context: [SendableMedication] = []
    ) async throws -> String {
        
        // Check memory
        try checkMemoryUsage()
        
        // Get API key
        let apiKey = try await ExtensionKeychain.shared.getClaudeAPIKey()
        
        // Build prompt
        let prompt = buildQuestionPrompt(question: question, medications: context)
        
        // Create request
        let request = try createAPIRequest(prompt: prompt, apiKey: apiKey)
        
        // Make API call
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        try validateResponse(response, data: data)
        
        // Extract answer
        return try extractAnswer(from: data)
    }
    
    // MARK: - Private Methods - Prompt Building
    
    /// Build conflict analysis prompt
    private func buildConflictAnalysisPrompt(
        medications: [SendableMedication],
        supplements: [SendableSupplement],
        voiceOptimized: Bool
    ) -> String {
        
        var prompt = Configuration.ClaudeAPI.medicalContextSystemPrompt + "\n\n"
        
        if voiceOptimized {
            prompt += "IMPORTANT: Optimize your response for text-to-speech. Use simple, clear language. Avoid complex medical terms when possible.\n\n"
        }
        
        prompt += "Analyze the following medications and supplements for potential interactions:\n\n"
        
        // Add medications
        if !medications.isEmpty {
            prompt += "MEDICATIONS:\n"
            for (index, med) in medications.enumerated() {
                prompt += "\(index + 1). \(med.name) \(med.dosage)\(med.dosageUnit.abbreviation)"
                if let purpose = med.purpose {
                    prompt += " (for \(purpose))"
                }
                prompt += "\n"
            }
            prompt += "\n"
        }
        
        // Add supplements
        if !supplements.isEmpty {
            prompt += "SUPPLEMENTS:\n"
            for (index, supp) in supplements.enumerated() {
                prompt += "\(index + 1). \(supp.name) \(supp.dosage)\(supp.dosageUnit.abbreviation)"
                if let purpose = supp.purpose {
                    prompt += " (for \(purpose))"
                }
                prompt += "\n"
            }
            prompt += "\n"
        }
        
        prompt += """
        Please provide:
        1. Overall severity level (Critical, High, Medium, Low, or None)
        2. Brief summary of findings (1-2 sentences)
        3. List each specific interaction found
        4. Practical recommendations
        
        Format your response as JSON:
        {
            "severity": "High",
            "summary": "Found 2 moderate interactions that require monitoring.",
            "conflicts": [
                {
                    "item1": "Aspirin",
                    "item2": "Warfarin",
                    "severity": "High",
                    "description": "Increased bleeding risk",
                    "recommendation": "Monitor closely, adjust dosing"
                }
            ],
            "recommendations": [
                "Take aspirin 2 hours before warfarin",
                "Monitor for unusual bleeding"
            ],
            "confidence": 0.95
        }
        """
        
        return prompt
    }
    
    /// Build medical question prompt
    private func buildQuestionPrompt(question: String, medications: [SendableMedication]) -> String {
        var prompt = "You are a medical information assistant. Answer the following question clearly and concisely, optimized for voice output.\n\n"
        
        if !medications.isEmpty {
            prompt += "User's current medications:\n"
            for med in medications.prefix(10) { // Limit context for memory
                prompt += "- \(med.displayName)\n"
            }
            prompt += "\n"
        }
        
        prompt += "Question: \(question)\n\n"
        prompt += "Provide a brief, clear answer suitable for text-to-speech. Include a reminder to consult healthcare providers for medical decisions."
        
        return prompt
    }
    
    // MARK: - Private Methods - API Communication
    
    /// Create API request
    private func createAPIRequest(prompt: String, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: apiEndpoint) else {
            throw ExtensionError.invalidAPIResponse(statusCode: nil, responseBody: "Invalid API endpoint")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": Configuration.ClaudeAPI.temperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        return request
    }
    
    /// Validate API response
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExtensionError.networkError(.unknown(nil))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
            
        case 401:
            throw ExtensionError.apiKeyMissing(service: .claude)
            
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw ExtensionError.rateLimitExceeded(retryAfter: retryAfter)
            
        case 500...599:
            throw ExtensionError.networkError(.serverError(statusCode: httpResponse.statusCode))
            
        default:
            let responseBody = String(data: data, encoding: .utf8)
            throw ExtensionError.invalidAPIResponse(
                statusCode: httpResponse.statusCode,
                responseBody: responseBody
            )
        }
    }
    
    // MARK: - Private Methods - Response Parsing
    
    /// Parse conflict analysis response
    private func parseConflictResponse(from data: Data) throws -> ConflictAnalysisResponse {
        do {
            // Parse Claude API response structure
            let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
            
            // Extract content from first message
            guard let content = apiResponse.content.first?.text else {
                throw ExtensionError.invalidAPIResponse(statusCode: 200, responseBody: "No content in response")
            }
            
            // Extract JSON from content (Claude may include markdown formatting)
            let jsonContent = extractJSON(from: content)
            
            // Parse the conflict analysis
            guard let jsonData = jsonContent.data(using: .utf8) else {
                throw ExtensionError.invalidAPIResponse(statusCode: 200, responseBody: "Invalid JSON content")
            }
            
            let analysis = try JSONDecoder().decode(ConflictAnalysisJSON.self, from: jsonData)
            
            // Convert to response model
            let conflicts = analysis.conflicts.map { conflict in
                MedicationConflict(
                    medication1: conflict.item1,
                    medication2: conflict.item2,
                    severity: ConflictSeverity(rawValue: conflict.severity) ?? .medium,
                    description: conflict.description,
                    recommendation: conflict.recommendation
                )
            }
            
            return ConflictAnalysisResponse(
                hasConflicts: !conflicts.isEmpty,
                severity: ConflictSeverity(rawValue: analysis.severity) ?? .none,
                summary: analysis.summary,
                conflicts: conflicts,
                recommendations: analysis.recommendations,
                confidence: analysis.confidence
            )
            
        } catch {
            logger.error("Failed to parse conflict response: \(error)")
            throw ExtensionError.invalidAPIResponse(statusCode: 200, responseBody: "Failed to parse response")
        }
    }
    
    /// Extract answer from response
    private func extractAnswer(from data: Data) throws -> String {
        do {
            let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
            
            guard let content = apiResponse.content.first?.text else {
                throw ExtensionError.invalidAPIResponse(statusCode: 200, responseBody: "No content in response")
            }
            
            // Clean up for voice output
            let cleanedContent = content
                .replacingOccurrences(of: "\n\n", with: ". ")
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return cleanedContent
            
        } catch {
            logger.error("Failed to extract answer: \(error)")
            throw ExtensionError.invalidAPIResponse(statusCode: 200, responseBody: "Failed to parse response")
        }
    }
    
    /// Extract JSON from potentially markdown-formatted content
    private func extractJSON(from content: String) -> String {
        // Look for JSON between ```json and ``` markers
        if let range = content.range(of: "```json\n(.*?)\n```", options: .regularExpression) {
            let json = String(content[range])
                .replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "\n```", with: "")
            return json
        }
        
        // Look for JSON starting with {
        if let startIndex = content.firstIndex(of: "{"),
           let endIndex = content.lastIndex(of: "}") {
            return String(content[startIndex...endIndex])
        }
        
        return content
    }
    
    // MARK: - Memory Management
    
    /// Check memory usage before making requests
    private func checkMemoryUsage() throws {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usageMB = Int(info.resident_size / 1024 / 1024)
            if usageMB > 40 { // Leave 20MB buffer
                throw ExtensionError.memoryLimitExceeded(
                    currentUsageMB: usageMB,
                    limitMB: Configuration.Extensions.MemoryLimits.maxExtensionMemoryMB
                )
            }
        }
    }
}

// MARK: - Response Models

/// Claude API response structure
private struct ClaudeAPIResponse: Decodable {
    let content: [ContentBlock]
    let id: String
    let model: String
    let role: String
}

private struct ContentBlock: Decodable {
    let text: String
    let type: String
}

/// Conflict analysis JSON structure
private struct ConflictAnalysisJSON: Decodable {
    let severity: String
    let summary: String
    let conflicts: [ConflictJSON]
    let recommendations: [String]
    let confidence: Double
}

private struct ConflictJSON: Decodable {
    let item1: String
    let item2: String
    let severity: String
    let description: String
    let recommendation: String
}