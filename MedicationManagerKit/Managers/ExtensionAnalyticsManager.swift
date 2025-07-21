//
//  ExtensionAnalyticsManager.swift
//  MedicationManagerKit
//
//  Created by Claude on 2025/01/14.
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import Foundation
import OSLog

/// Lightweight analytics manager for tracking extension usage and performance
/// Designed for minimal memory footprint and privacy-compliant tracking
@available(iOS 18.0, *)
public actor ExtensionAnalyticsManager {
    
    // MARK: - Properties
    
    /// Shared instance for singleton access
    public static let shared = ExtensionAnalyticsManager()
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.medicationmanager.kit", category: "ExtensionAnalytics")
    
    /// Shared UserDefaults for analytics storage
    private let sharedDefaults: UserDefaults?
    
    /// In-memory event buffer to batch analytics
    private var eventBuffer: [AnalyticsEvent] = []
    
    /// Maximum events to buffer before flushing
    private let maxBufferSize = 20
    
    /// Timer for periodic flushing
    private var flushTimer: Timer?
    
    /// Session start time
    private let sessionStartTime = Date()
    
    /// Current session ID
    private let sessionId = UUID().uuidString
    
    // MARK: - Analytics Keys
    
    private enum AnalyticsKeys {
        static let totalEvents = "extension.analytics.totalEvents"
        static let lastFlushDate = "extension.analytics.lastFlushDate"
        static let dailyEventCount = "extension.analytics.dailyEventCount"
        static let dailyEventDate = "extension.analytics.dailyEventDate"
        static let intentSuccessRate = "extension.analytics.intentSuccessRate"
        static let averageResponseTime = "extension.analytics.averageResponseTime"
        static let errorCounts = "extension.analytics.errorCounts"
        static let featureUsage = "extension.analytics.featureUsage"
        static let performanceMetrics = "extension.analytics.performanceMetrics"
    }
    
    // MARK: - Event Types
    
    /// Analytics event structure
    public struct AnalyticsEvent: Codable, Sendable {
        public let eventType: EventType
        public let timestamp: Date
        public let properties: [String: String]
        public let metrics: EventMetrics?
        public let sessionId: String
        
        public init(
            eventType: EventType,
            properties: [String: String] = [:],
            metrics: EventMetrics? = nil,
            sessionId: String
        ) {
            self.eventType = eventType
            self.timestamp = Date()
            self.properties = properties
            self.metrics = metrics
            self.sessionId = sessionId
        }
    }
    
    /// Types of events to track
    public enum EventType: String, Codable, Sendable {
        // Intent events
        case intentStarted = "intent_started"
        case intentCompleted = "intent_completed"
        case intentFailed = "intent_failed"
        case intentCancelled = "intent_cancelled"
        
        // Feature usage
        case conflictCheckRequested = "conflict_check_requested"
        case medicationAdded = "medication_added"
        case medicationLogged = "medication_logged"
        case medicationsViewed = "medications_viewed"
        case medicalQuestionAsked = "medical_question_asked"
        case reminderSet = "reminder_set"
        
        // Performance events
        case apiCallStarted = "api_call_started"
        case apiCallCompleted = "api_call_completed"
        case apiCallFailed = "api_call_failed"
        case memoryWarning = "memory_warning"
        case timeoutOccurred = "timeout_occurred"
        
        // Error events
        case errorOccurred = "error_occurred"
        case authenticationFailed = "authentication_failed"
        case dataFetchFailed = "data_fetch_failed"
        
        // Voice events
        case voiceInputUsed = "voice_input_used"
        case voiceRecognitionFailed = "voice_recognition_failed"
        case voiceResponseGenerated = "voice_response_generated"
    }
    
    /// Performance metrics for events
    public struct EventMetrics: Codable, Sendable {
        public let duration: TimeInterval?
        public let memoryUsageMB: Int?
        public let itemCount: Int?
        public let successRate: Double?
        public let errorCode: Int?
        
        public init(
            duration: TimeInterval? = nil,
            memoryUsageMB: Int? = nil,
            itemCount: Int? = nil,
            successRate: Double? = nil,
            errorCode: Int? = nil
        ) {
            self.duration = duration
            self.memoryUsageMB = memoryUsageMB
            self.itemCount = itemCount
            self.successRate = successRate
            self.errorCode = errorCode
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize shared UserDefaults
        self.sharedDefaults = UserDefaults(suiteName: Configuration.Extensions.appGroupIdentifier)
        
        // Clean up old analytics data
        Task {
            await cleanupOldAnalytics()
        }
    }
    
    // MARK: - Public Methods - Event Tracking
    
    /// Track an analytics event
    /// - Parameters:
    ///   - eventType: The type of event to track
    ///   - properties: Additional properties for the event
    ///   - metrics: Performance metrics for the event
    public func trackEvent(
        _ eventType: EventType,
        properties: [String: String] = [:],
        metrics: EventMetrics? = nil
    ) {
        let event = AnalyticsEvent(
            eventType: eventType,
            properties: properties,
            metrics: metrics,
            sessionId: sessionId
        )
        
        // Add to buffer
        eventBuffer.append(event)
        
        // Log for debugging
        logger.debug("Tracked event: \(eventType.rawValue)")
        
        // Check if we should flush
        if eventBuffer.count >= maxBufferSize {
            Task {
                await flushEvents()
            }
        }
        
        // Update daily count
        incrementDailyEventCount()
    }
    
    /// Track intent execution
    /// - Parameters:
    ///   - intentName: Name of the intent
    ///   - success: Whether the intent succeeded
    ///   - duration: Execution duration
    ///   - errorCode: Error code if failed
    public func trackIntent(
        _ intentName: String,
        success: Bool,
        duration: TimeInterval,
        errorCode: Int? = nil
    ) {
        let eventType: EventType = success ? .intentCompleted : .intentFailed
        
        let properties = [
            "intent_name": intentName,
            "success": String(success)
        ]
        
        let metrics = EventMetrics(
            duration: duration,
            memoryUsageMB: getCurrentMemoryUsage(),
            errorCode: errorCode
        )
        
        trackEvent(eventType, properties: properties, metrics: metrics)
        
        // Update success rate
        updateIntentSuccessRate(intentName: intentName, success: success)
    }
    
    /// Track API call performance
    /// - Parameters:
    ///   - endpoint: API endpoint called
    ///   - success: Whether the call succeeded
    ///   - duration: Call duration
    ///   - statusCode: HTTP status code
    public func trackAPICall(
        endpoint: String,
        success: Bool,
        duration: TimeInterval,
        statusCode: Int? = nil
    ) {
        let eventType: EventType = success ? .apiCallCompleted : .apiCallFailed
        
        var properties = ["endpoint": endpoint]
        if let statusCode = statusCode {
            properties["status_code"] = String(statusCode)
        }
        
        let metrics = EventMetrics(
            duration: duration,
            memoryUsageMB: getCurrentMemoryUsage()
        )
        
        trackEvent(eventType, properties: properties, metrics: metrics)
        
        // Update average response time
        updateAverageResponseTime(duration: duration)
    }
    
    /// Track error occurrence
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Additional context about where the error occurred
    public func trackError(_ error: ExtensionError, context: String) {
        let properties = [
            "error_type": String(describing: type(of: error)),
            "error_code": String(error.errorCode),
            "error_severity": error.severity.rawValue,
            "context": context
        ]
        
        let metrics = EventMetrics(
            errorCode: error.errorCode,
            memoryUsageMB: getCurrentMemoryUsage()
        )
        
        trackEvent(.errorOccurred, properties: properties, metrics: metrics)
        
        // Update error counts
        incrementErrorCount(errorCode: error.errorCode)
    }
    
    /// Track feature usage
    /// - Parameters:
    ///   - feature: Feature name
    ///   - additionalInfo: Additional information about the usage
    public func trackFeatureUsed(_ feature: String, additionalInfo: [String: String] = [:]) {
        var properties = additionalInfo
        properties["feature"] = feature
        
        // Map to specific event type if possible
        let eventType: EventType
        switch feature.lowercased() {
        case "conflict_check":
            eventType = .conflictCheckRequested
        case "add_medication":
            eventType = .medicationAdded
        case "log_medication":
            eventType = .medicationLogged
        case "view_medications":
            eventType = .medicationsViewed
        case "ask_question":
            eventType = .medicalQuestionAsked
        case "set_reminder":
            eventType = .reminderSet
        default:
            eventType = .intentCompleted
        }
        
        trackEvent(eventType, properties: properties)
        
        // Update feature usage counts
        incrementFeatureUsage(feature: feature)
    }
    
    // MARK: - Public Methods - Metrics Retrieval
    
    /// Get analytics summary for the extension
    /// - Returns: Dictionary of analytics metrics
    public func getAnalyticsSummary() async -> [String: Any] {
        guard let defaults = sharedDefaults else {
            return [:]
        }
        
        var summary: [String: Any] = [:]
        
        // Basic metrics
        summary["total_events"] = defaults.integer(forKey: AnalyticsKeys.totalEvents)
        summary["session_duration"] = Date().timeIntervalSince(sessionStartTime)
        summary["current_memory_mb"] = getCurrentMemoryUsage()
        
        // Daily metrics
        if let dailyDate = defaults.object(forKey: AnalyticsKeys.dailyEventDate) as? Date,
           Calendar.current.isDateInToday(dailyDate) {
            summary["daily_event_count"] = defaults.integer(forKey: AnalyticsKeys.dailyEventCount)
        }
        
        // Success rate
        if let successRateData = defaults.data(forKey: AnalyticsKeys.intentSuccessRate),
           let successRates = try? JSONDecoder().decode([String: Double].self, from: successRateData) {
            summary["intent_success_rates"] = successRates
        }
        
        // Average response time
        summary["average_response_time"] = defaults.double(forKey: AnalyticsKeys.averageResponseTime)
        
        // Error counts
        if let errorData = defaults.data(forKey: AnalyticsKeys.errorCounts),
           let errorCounts = try? JSONDecoder().decode([String: Int].self, from: errorData) {
            summary["error_counts"] = errorCounts
        }
        
        // Feature usage
        if let featureData = defaults.data(forKey: AnalyticsKeys.featureUsage),
           let featureUsage = try? JSONDecoder().decode([String: Int].self, from: featureData) {
            summary["feature_usage"] = featureUsage
        }
        
        return summary
    }
    
    /// Get performance metrics for monitoring
    /// - Returns: Performance metrics dictionary
    public func getPerformanceMetrics() async -> PerformanceMetrics {
        let memoryUsage = getCurrentMemoryUsage()
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let eventCount = eventBuffer.count
        
        return PerformanceMetrics(
            memoryUsageMB: memoryUsage,
            sessionDurationSeconds: sessionDuration,
            bufferedEventCount: eventCount,
            totalEventCount: sharedDefaults?.integer(forKey: AnalyticsKeys.totalEvents) ?? 0
        )
    }
    
    // MARK: - Public Methods - Lifecycle
    
    /// Flush any buffered events (call before extension terminates)
    public func flushEvents() async {
        guard !eventBuffer.isEmpty else { return }
        
        logger.info("Flushing \(self.eventBuffer.count) analytics events")
        
        // In a real implementation, this would send events to an analytics service
        // For now, we'll just log and clear the buffer
        
        // Update total event count
        if let defaults = sharedDefaults {
            let currentTotal = defaults.integer(forKey: AnalyticsKeys.totalEvents)
            defaults.set(currentTotal + eventBuffer.count, forKey: AnalyticsKeys.totalEvents)
            defaults.set(Date(), forKey: AnalyticsKeys.lastFlushDate)
        }
        
        // Clear buffer
        eventBuffer.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Get current memory usage in MB
    private func getCurrentMemoryUsage() -> Int {
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
            return Int(info.resident_size / 1024 / 1024)
        }
        
        return 0
    }
    
    /// Increment daily event count
    private func incrementDailyEventCount() {
        guard let defaults = sharedDefaults else { return }
        
        let today = Date()
        let storedDate = defaults.object(forKey: AnalyticsKeys.dailyEventDate) as? Date
        
        if let storedDate = storedDate, Calendar.current.isDateInToday(storedDate) {
            // Same day, increment count
            let count = defaults.integer(forKey: AnalyticsKeys.dailyEventCount)
            defaults.set(count + 1, forKey: AnalyticsKeys.dailyEventCount)
        } else {
            // New day, reset count
            defaults.set(1, forKey: AnalyticsKeys.dailyEventCount)
            defaults.set(today, forKey: AnalyticsKeys.dailyEventDate)
        }
    }
    
    /// Update intent success rate
    private func updateIntentSuccessRate(intentName: String, success: Bool) {
        guard let defaults = sharedDefaults else { return }
        
        // Load existing rates
        var successRates: [String: Double] = [:]
        if let data = defaults.data(forKey: AnalyticsKeys.intentSuccessRate),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            successRates = decoded
        }
        
        // Update rate (simple moving average)
        let currentRate = successRates[intentName] ?? 0.0
        let newRate = (currentRate * 0.9) + (success ? 0.1 : 0.0)
        successRates[intentName] = newRate
        
        // Save back
        if let encoded = try? JSONEncoder().encode(successRates) {
            defaults.set(encoded, forKey: AnalyticsKeys.intentSuccessRate)
        }
    }
    
    /// Update average response time
    private func updateAverageResponseTime(duration: TimeInterval) {
        guard let defaults = sharedDefaults else { return }
        
        let currentAverage = defaults.double(forKey: AnalyticsKeys.averageResponseTime)
        
        // Simple moving average
        let newAverage = currentAverage > 0 
            ? (currentAverage * 0.9) + (duration * 0.1)
            : duration
        
        defaults.set(newAverage, forKey: AnalyticsKeys.averageResponseTime)
    }
    
    /// Increment error count
    private func incrementErrorCount(errorCode: Int) {
        guard let defaults = sharedDefaults else { return }
        
        // Load existing counts
        var errorCounts: [String: Int] = [:]
        if let data = defaults.data(forKey: AnalyticsKeys.errorCounts),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            errorCounts = decoded
        }
        
        // Increment count
        let key = String(errorCode)
        errorCounts[key] = (errorCounts[key] ?? 0) + 1
        
        // Save back
        if let encoded = try? JSONEncoder().encode(errorCounts) {
            defaults.set(encoded, forKey: AnalyticsKeys.errorCounts)
        }
    }
    
    /// Increment feature usage count
    private func incrementFeatureUsage(feature: String) {
        guard let defaults = sharedDefaults else { return }
        
        // Load existing usage
        var featureUsage: [String: Int] = [:]
        if let data = defaults.data(forKey: AnalyticsKeys.featureUsage),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            featureUsage = decoded
        }
        
        // Increment count
        featureUsage[feature] = (featureUsage[feature] ?? 0) + 1
        
        // Save back
        if let encoded = try? JSONEncoder().encode(featureUsage) {
            defaults.set(encoded, forKey: AnalyticsKeys.featureUsage)
        }
    }
    
    /// Clean up old analytics data
    private func cleanupOldAnalytics() {
        guard let defaults = sharedDefaults else { return }
        
        // Check last flush date
        if let lastFlush = defaults.object(forKey: AnalyticsKeys.lastFlushDate) as? Date {
            let daysSinceFlush = Calendar.current.dateComponents([.day], from: lastFlush, to: Date()).day ?? 0
            
            // Clear old data after 30 days
            if daysSinceFlush > 30 {
                logger.info("Cleaning up analytics data older than 30 days")
                
                // Reset counters
                defaults.removeObject(forKey: AnalyticsKeys.errorCounts)
                defaults.removeObject(forKey: AnalyticsKeys.featureUsage)
                defaults.removeObject(forKey: AnalyticsKeys.intentSuccessRate)
                defaults.set(0, forKey: AnalyticsKeys.totalEvents)
            }
        }
    }
}

// MARK: - Supporting Types

/// Performance metrics structure
@available(iOS 18.0, *)
public struct PerformanceMetrics: Sendable {
    public let memoryUsageMB: Int
    public let sessionDurationSeconds: TimeInterval
    public let bufferedEventCount: Int
    public let totalEventCount: Int
}

// MARK: - Convenience Methods

@available(iOS 18.0, *)
public extension ExtensionAnalyticsManager {
    
    /// Track a timed operation
    /// - Parameters:
    ///   - operationName: Name of the operation
    ///   - operation: The async operation to time
    /// - Returns: The result of the operation
    func trackTimedOperation<T>(
        _ operationName: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        
        do {
            let result = try await operation()
            
            let duration = Date().timeIntervalSince(startTime)
            trackEvent(.intentCompleted, properties: ["operation": operationName], metrics: EventMetrics(duration: duration))
            
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            if let extensionError = error as? ExtensionError {
                trackError(extensionError, context: operationName)
            } else {
                trackEvent(.intentFailed, properties: ["operation": operationName, "error": String(describing: error)], metrics: EventMetrics(duration: duration))
            }
            
            throw error
        }
    }
    
    /// Create a performance report for debugging
    func generatePerformanceReport() async -> String {
        let metrics = await getPerformanceMetrics()
        let summary = await getAnalyticsSummary()
        
        var report = "Extension Performance Report\n"
        report += "===========================\n\n"
        
        report += "Session Info:\n"
        report += "- Duration: \(Int(metrics.sessionDurationSeconds))s\n"
        report += "- Memory Usage: \(metrics.memoryUsageMB)MB\n"
        report += "- Events Tracked: \(metrics.totalEventCount)\n\n"
        
        if let successRates = summary["intent_success_rates"] as? [String: Double] {
            report += "Intent Success Rates:\n"
            for (intent, rate) in successRates {
                report += "- \(intent): \(Int(rate * 100))%\n"
            }
            report += "\n"
        }
        
        if let featureUsage = summary["feature_usage"] as? [String: Int] {
            report += "Feature Usage:\n"
            for (feature, count) in featureUsage.sorted(by: { $0.value > $1.value }) {
                report += "- \(feature): \(count) times\n"
            }
        }
        
        return report
    }
}