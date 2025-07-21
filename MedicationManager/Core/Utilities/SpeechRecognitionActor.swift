import Foundation
import AVFoundation
import OSLog

// MARK: - Recognition State
/// Represents the current state of speech recognition
enum RecognitionState: Sendable {
    case idle
    case requestingPermissions
    case permissionsGranted
    case permissionsDenied(reason: PermissionDeniedReason)
    case preparing
    case recording
    case processing
    case stopped(reason: StopReason)
    case error(AppError)
    
    enum PermissionDeniedReason: Sendable {
        case microphone
        case speechRecognition
        case both
    }
    
    enum StopReason: Sendable {
        case userInitiated
        case finalResult
        case timeout
        case interruption
        case error
    }
}

// MARK: - Recognition Result
struct RecognitionResult: Sendable {
    let text: String
    let isFinal: Bool
    let timestamp: Date
}

// MARK: - Speech Recognition Actor
/// Business logic layer managing speech recognition state and coordination
/// This actor ensures thread-safe state management and business rule enforcement
actor SpeechRecognitionActor {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "SpeechRecognition")
    private var audioSessionManager: AudioSessionManager
    
    // State management
    private(set) var state: RecognitionState = .idle
    private(set) var currentResult: RecognitionResult?
    private(set) var isRecording = false
    
    // Timers for timeout management
    private var recognitionTimer: Task<Void, Never>?
    private let recognitionTimeout: Duration
    
    // Enhanced text processing
    private let medicalVocabularyEnhancer = MedicalVocabularyEnhancer()
    
    // MARK: - Initialization
    init(recognitionTimeout: Duration = .seconds(30)) {
        self.recognitionTimeout = recognitionTimeout
        
        // We'll set up the audio session manager after init
        // to avoid capture issues
        self.audioSessionManager = AudioSessionManager { _ in
            // Placeholder - will be connected later
        }
        
        logger.info("SpeechRecognitionActor initialized")
    }
    
    /// Complete initialization - must be called after creation
    func initialize() async {
        // Create a new audio session manager with proper event handling
        let eventStream = AsyncStream<AudioEvent> { continuation in
            self.audioSessionManager = AudioSessionManager { event in
                continuation.yield(event)
            }
        }
        
        // Initialize the manager
        await audioSessionManager.initialize()
        
        // Process events in a separate task
        Task {
            for await event in eventStream {
                await self.handleAudioEvent(event)
            }
        }
    }
    
    // MARK: - Public Interface
    
    /// Get current state
    func getCurrentState() -> RecognitionState {
        return state
    }
    
    /// Request necessary permissions
    func requestPermissions() async -> Bool {
        logger.debug("Requesting permissions")
        updateState(.requestingPermissions)
        
        // Check current permissions first
        let currentPermissions = await audioSessionManager.checkPermissions()
        
        // Request microphone if needed
        let microphoneGranted: Bool
        if currentPermissions.microphone {
            microphoneGranted = true
        } else {
            microphoneGranted = await audioSessionManager.requestMicrophonePermission()
        }
        
        // Request speech recognition if needed
        let speechGranted: Bool
        if currentPermissions.speech {
            speechGranted = true
        } else {
            speechGranted = await audioSessionManager.requestSpeechPermission()
        }
        
        // Update state based on results
        if microphoneGranted && speechGranted {
            updateState(.permissionsGranted)
            return true
        } else {
            let reason: RecognitionState.PermissionDeniedReason
            if !microphoneGranted && !speechGranted {
                reason = .both
            } else if !microphoneGranted {
                reason = .microphone
            } else {
                reason = .speechRecognition
            }
            updateState(.permissionsDenied(reason: reason))
            return false
        }
    }
    
    /// Start recording with optional context
    func startRecording(context: VoiceInteractionContext? = nil) async throws {
        logger.debug("Start recording requested, context: \(String(describing: context))")
        
        // Validate state
        guard canStartRecording() else {
            logger.warning("Cannot start recording in current state: \(String(describing: self.state))")
            throw AppError.voice(.invalidState)
        }
        
        // Ensure permissions
        if case .idle = state {
            let hasPermissions = await requestPermissions()
            guard hasPermissions else {
                throw AppError.voice(.microphonePermissionDenied)
            }
        }
        
        updateState(.preparing)
        
        do {
            // Start audio recording
            try await audioSessionManager.startRecording()
            
            // Update state
            isRecording = true
            updateState(.recording)
            currentResult = nil
            
            // Start timeout timer
            startTimeoutTimer()
            
            logger.info("Recording started successfully")
            
        } catch {
            updateState(.error(error as? AppError ?? .voice(.audioSessionError)))
            throw error
        }
    }
    
    /// Stop recording
    func stopRecording(reason: RecognitionState.StopReason = .userInitiated) async {
        logger.debug("Stop recording requested, reason: \(String(describing: reason))")
        
        guard isRecording else {
            logger.warning("Not currently recording")
            return
        }
        
        // Cancel timeout timer
        cancelTimeoutTimer()
        
        // Stop audio recording
        await audioSessionManager.stopRecording()
        
        // Update state
        isRecording = false
        updateState(.stopped(reason: reason))
        
        logger.info("Recording stopped")
    }
    
    /// Reset to idle state
    func reset() {
        logger.debug("Resetting to idle state")
        
        cancelTimeoutTimer()
        isRecording = false
        currentResult = nil
        updateState(.idle)
    }
    
    /// Process text for specific context
    func processTextForContext(_ text: String, context: VoiceInteractionContext) -> String {
        logger.debug("Processing text for context: \(String(describing: context))")
        
        updateState(.processing)
        
        let enhancedText: String
        
        switch context {
        case .medicationName:
            enhancedText = medicalVocabularyEnhancer.enhanceMedicationName(text)
        case .dosage:
            enhancedText = medicalVocabularyEnhancer.extractDosage(text)
        case .frequency:
            enhancedText = medicalVocabularyEnhancer.extractFrequency(text)
        default:
            enhancedText = medicalVocabularyEnhancer.enhanceGeneralText(text)
        }
        
        // Update state back to previous
        if isRecording {
            updateState(.recording)
        } else {
            updateState(.idle)
        }
        
        return enhancedText
    }
    
    // MARK: - Private Methods
    
    private func updateState(_ newState: RecognitionState) {
        logger.debug("State transition: \(String(describing: self.state)) -> \(String(describing: newState))")
        self.state = newState
    }
    
    private func canStartRecording() -> Bool {
        switch state {
        case .idle, .permissionsGranted, .stopped, .error:
            return true
        default:
            return false
        }
    }
    
    private func startTimeoutTimer() {
        cancelTimeoutTimer()
        
        recognitionTimer = Task { [weak self, timeout = recognitionTimeout] in
            do {
                try await Task.sleep(for: timeout)
                
                // If still recording after timeout, stop
                guard let self = self else { return }
                let isStillRecording = await self.isRecording
                if isStillRecording {
                    self.logger.info("Recognition timeout reached")
                    await self.stopRecording(reason: .timeout)
                }
            } catch {
                // Task cancelled
            }
        }
    }
    
    private func cancelTimeoutTimer() {
        recognitionTimer?.cancel()
        recognitionTimer = nil
    }
    
    // MARK: - Audio Event Handling
    
    private func handleAudioEvent(_ event: AudioEvent) async {
        logger.debug("Handling audio event: \(String(describing: event))")
        
        switch event {
        case .recordingStarted:
            // Already handled in startRecording
            break
            
        case .recordingStopped:
            // Already handled in stopRecording
            break
            
        case .audioDataReceived:
            // Could be used for audio level monitoring
            break
            
        case .recognitionResult(let text, let isFinal):
            // Handle recognition result
            logger.debug("Recognition result: '\(text)', final: \(isFinal)")
            
            self.currentResult = RecognitionResult(
                text: text,
                isFinal: isFinal,
                timestamp: Date()
            )
            
            if isFinal && self.isRecording {
                await self.stopRecording(reason: .finalResult)
            }
            
        case .recognitionError(let error):
            // Handle recognition error
            logger.debug("Recognition error: \(String(describing: error))")
            
            // Check if this is just a "no speech detected" error which is normal when user stops speaking
            if let nsError = error as NSError? {
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    // This is normal - user just stopped speaking
                    logger.info("User stopped speaking - normal completion")
                    if self.isRecording {
                        await self.stopRecording(reason: .finalResult)
                    }
                    return
                } else if nsError.domain == "kLSRErrorDomain" && nsError.code == 301 {
                    // Recognition request was canceled - this is also normal when we stop recording
                    logger.info("Recognition canceled - normal completion")
                    return
                }
            }
            
            // This is an actual error
            logger.error("Recognition error: \(String(describing: error))")
            let appError = error as? AppError ?? .voice(.speechRecognitionFailed)
            updateState(.error(appError))
            
            if self.isRecording {
                await self.stopRecording(reason: .error)
            }
            
        case .audioSessionInterrupted(let type):
            // Handle interruption
            switch type {
            case .began:
                logger.info("Handling interruption began")
                if self.isRecording {
                    await self.stopRecording(reason: .interruption)
                }
                
            case .ended(let shouldResume):
                logger.info("Handling interruption ended, shouldResume: \(String(describing: shouldResume))")
                // We don't auto-resume - user must restart manually
            }
            
        case .audioRouteChanged(let reason):
            // Handle route change
            switch reason {
            case .oldDeviceUnavailable:
                logger.info("Audio device became unavailable")
                if self.isRecording {
                    await self.stopRecording(reason: .interruption)
                }
                
            case .categoryChange:
                logger.info("Audio category changed")
                if self.isRecording {
                    await self.stopRecording(reason: .interruption)
                }
                
            case .other:
                // No action needed
                break
            }
            
        case .microphonePermissionChanged(let granted):
            logger.info("Microphone permission changed: \(String(describing: granted))")
            
        case .speechPermissionChanged(let granted):
            logger.info("Speech permission changed: \(String(describing: granted))")
        }
    }
    
}

// MARK: - Medical Vocabulary Enhancer
/// Processes and enhances text for medical context
private struct MedicalVocabularyEnhancer {
    
    func enhanceMedicationName(_ text: String) -> String {
        let lowercased = text.lowercased()
        
        // Common medication corrections
        let corrections: [String: String] = [
            "advil": "Advil",
            "tylenol": "Tylenol",
            "aspirin": "Aspirin",
            "ibuprofen": "Ibuprofen",
            "acetaminophen": "Acetaminophen",
            "lisinopril": "Lisinopril",
            "metformin": "Metformin",
            "atorvastatin": "Atorvastatin",
            "amlodipine": "Amlodipine",
            "omeprazole": "Omeprazole"
        ]
        
        for (pattern, replacement) in corrections {
            if lowercased.contains(pattern) {
                return lowercased.replacingOccurrences(of: pattern, with: replacement)
            }
        }
        
        return text.capitalized
    }
    
    func extractDosage(_ text: String) -> String {
        let patterns = [
            #"\d+\s*(mg|milligrams?|g|grams?|ml|milliliters?|tablets?|capsules?)"#,
            #"\d+/\d+\s*(mg|g|ml|tablets?|capsules?)"#,
            #"(one|two|three|four|five)\s*(mg|milligrams?|tablets?|capsules?)"#
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var result = String(text[range])
                
                // Standardize units
                result = result.replacingOccurrences(of: "milligrams", with: "mg", options: .caseInsensitive)
                result = result.replacingOccurrences(of: "milligram", with: "mg", options: .caseInsensitive)
                result = result.replacingOccurrences(of: "milliliters", with: "ml", options: .caseInsensitive)
                result = result.replacingOccurrences(of: "milliliter", with: "ml", options: .caseInsensitive)
                
                return result
            }
        }
        
        return text
    }
    
    func extractFrequency(_ text: String) -> String {
        let lowercased = text.lowercased()
        
        let frequencyMap: [String: String] = [
            "once a day": "once daily",
            "twice a day": "twice daily",
            "three times a day": "three times daily",
            "four times a day": "four times daily",
            "every day": "daily",
            "every morning": "every morning",
            "every evening": "every evening",
            "every night": "every night",
            "before meals": "before meals",
            "after meals": "after meals",
            "with food": "with food"
        ]
        
        for (pattern, replacement) in frequencyMap {
            if lowercased.contains(pattern) {
                return replacement
            }
        }
        
        return text
    }
    
    func enhanceGeneralText(_ text: String) -> String {
        // Basic capitalization
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
