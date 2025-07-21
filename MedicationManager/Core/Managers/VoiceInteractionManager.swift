import Foundation
import UIKit
import Speech
import AVFoundation
import OSLog
import Observation

// MARK: - Voice Interaction Manager
@MainActor
@Observable
final class VoiceInteractionManager: NSObject {
    static let shared = VoiceInteractionManager()
    
    // MARK: - Observable Properties
    private(set) var isListening = false
    private(set) var isProcessing = false
    private(set) var transcribedText = ""
    private(set) var partialTranscription = ""
    private(set) var error: AppError?
    private(set) var hasPermission = false
    private(set) var audioLevel: Float = 0.0
    private(set) var transcription: String = ""
    
    // Computed properties
    var recordingDuration: TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Voice State
    enum VoiceState {
        case idle
        case listening
        case processing
        case completed
        case error(AppError)
    }
    
    private(set) var state: VoiceState = .idle
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "VoiceInteractionManager")
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Configuration.App.defaultCountry == "US" ? Configuration.Voice.Locales.us : Configuration.Voice.Locales.uk))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession: AVAudioSession?
    private var silenceTimer: Timer?
    private let analyticsManager = AnalyticsManager.shared
    
    // Timing
    private var recordingStartTime: Date?
    private var lastSpeechTime: Date?
    private var wordCount = 0
    
    // Medical context
    private var currentContext: VoiceInteractionContext = .general
    
    private override init() {
        super.init()
        setupSpeechRecognizer()
        checkPermission()
    }
    
    // MARK: - Setup
    
    private func setupSpeechRecognizer() {
        speechRecognizer?.delegate = self
        
        // Configure audio session
        audioSession = AVAudioSession.sharedInstance()
        
        // Check initial permission status
        checkPermission()
    }
    
    // MARK: - Permission Management
    
    func checkPermissions() async {
        checkPermission()
    }
    
    func checkPermission() {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch authStatus {
        case .authorized:
            hasPermission = true
            checkMicrophonePermission()
            
        case .denied, .restricted:
            hasPermission = false
            error = AppError.voice(.microphonePermissionDenied)
            
        case .notDetermined:
            hasPermission = false
            
        @unknown default:
            hasPermission = false
        }
    }
    
    func requestPermission() async -> Bool {
        logger.info("Requesting speech recognition permission")
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        self?.hasPermission = true
                        self?.checkMicrophonePermission()
                        continuation.resume(returning: true)
                        
                    default:
                        self?.hasPermission = false
                        self?.error = AppError.voice(.microphonePermissionDenied)
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    private func checkMicrophonePermission() {
        Task { [weak self] in
            guard let self else { return }
            let granted = await AVAudioApplication.requestRecordPermission()
            if granted {
                hasPermission = true
                error = nil
            } else {
                hasPermission = false
                error = AppError.voice(.microphonePermissionDenied)
            }
        }
    }
    
    // MARK: - Voice Recording
    
    func startRecording(context: VoiceInteractionContext) async throws {
        try await startListening(context: context, autoStop: true)
        transcription = transcribedText
    }
    
    func stopRecording() async throws -> String {
        stopListening()
        let finalTranscription = transcribedText
        transcription = finalTranscription
        return finalTranscription
    }
    
    
    func startListening(context: VoiceInteractionContext = .general, autoStop: Bool = true) async throws {
        guard hasPermission else {
            let granted = await requestPermission()
            if !granted {
                throw AppError.voice(.microphonePermissionDenied)
            }
            return
        }
        
        guard speechRecognizer?.isAvailable == true else {
            throw AppError.voice(.speechRecognitionUnavailable)
        }
        
        // Stop any existing session
        stopListening()
        
        // Reset state
        transcribedText = ""
        partialTranscription = ""
        error = nil
        wordCount = 0
        currentContext = context
        state = .listening
        isListening = true
        recordingStartTime = Date()
        
        logger.info("Starting voice recording with context: \(String(describing: context))")
        
        // Track analytics
        analyticsManager.trackVoiceInputStarted(context: String(describing: context))
        
        do {
            // Configure audio session
            try audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create and configure recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                throw AppError.voice(.speechRecognitionFailed)
            }
            
            recognitionRequest.shouldReportPartialResults = Configuration.Voice.showTranscriptionInRealTime
            recognitionRequest.requiresOnDeviceRecognition = false
            
            // Add medical context if enabled
            if Configuration.Voice.medicalVocabularyEnabled {
                recognitionRequest.contextualStrings = getMedicalContextStrings(for: context)
            }
            
            // Configure audio input
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: Configuration.Voice.Audio.bufferSize, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                
                // Update audio level for UI
                self?.updateAudioLevel(from: buffer)
            }
            
            // Start audio engine
            audioEngine.prepare()
            try audioEngine.start()
            
            // Start recognition task
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.handleRecognitionResult(result, error: error, autoStop: autoStop)
                }
            }
            
            // Set maximum recording timer
            if autoStop {
                silenceTimer = Timer.scheduledTimer(withTimeInterval: context.maxDuration, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.stopListening()
                    }
                }
            }
            
        } catch {
            logger.error("Failed to start voice recording: \(error)")
            stopListening()
            throw AppError.voice(.audioSessionError)
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        logger.info("Stopping voice recording")
        
        // Cancel timers
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Reset state
        isListening = false
        state = transcribedText.isEmpty ? .idle : .completed
        
        // Deactivate audio session
        try? audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        
        // Track analytics
        if let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            analyticsManager.trackVoiceInputCompleted(
                context: String(describing: currentContext),
                success: !transcribedText.isEmpty,
                duration: duration
            )
            
            if !transcribedText.isEmpty {
                analyticsManager.trackVoiceInput(
                    context: String(describing: currentContext),
                    duration: duration,
                    wordCount: wordCount
                )
            }
        }
        
        recordingStartTime = nil
    }
    
    // MARK: - Recognition Handling
    
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?, autoStop: Bool) {
        if let error = error {
            logger.error("Speech recognition error: \(error)")
            
            // Map to app error
            if (error as NSError).code == Configuration.Voice.ErrorCodes.noSpeechDetected { // No speech detected
                self.error = AppError.voice(.noSpeechDetected)
            } else {
                self.error = AppError.voice(.speechRecognitionFailed)
            }
            
            analyticsManager.trackVoiceInputError(
                context: String(describing: currentContext),
                errorType: (error as NSError).domain
            )
            
            stopListening()
            state = .error(self.error!)
            return
        }
        
        guard let result = result else { return }
        
        // Update transcription
        let transcription = result.bestTranscription.formattedString
        partialTranscription = transcription
        
        // Update word count
        wordCount = transcription.split(separator: " ").count
        
        // Check for silence detection
        if autoStop && Configuration.Voice.silenceDetectionSeconds > 0 {
            lastSpeechTime = Date()
            
            // Reset silence timer
            silenceTimer?.invalidate()
            silenceTimer = Timer.scheduledTimer(withTimeInterval: Configuration.Voice.silenceDetectionSeconds, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.completeRecognition(with: transcription)
                }
            }
        }
        
        // Handle final result
        if result.isFinal {
            completeRecognition(with: transcription)
        }
    }
    
    private func completeRecognition(with text: String) {
        transcribedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Apply medical corrections if enabled
        if Configuration.Voice.medicalVocabularyEnabled {
            transcribedText = applyMedicalCorrections(to: transcribedText, context: currentContext)
        }
        
        logger.info("Voice recognition completed: \(self.transcribedText)")
        
        stopListening()
        
        // Provide haptic feedback if enabled
        if Configuration.Voice.hapticFeedbackEnabled {
            provideHapticFeedback()
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataArray = Array(UnsafeBufferPointer(start: channelDataValue, count: Int(buffer.frameLength)))
        
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        
        // Normalize to 0-1 range
        let minDb: Float = Configuration.Voice.Audio.minDecibels
        let normalizedLevel = (avgPower - minDb) / -minDb
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.audioLevel = max(0, min(1, normalizedLevel))
        }
    }
    
    // MARK: - Medical Context
    
    private func getMedicalContextStrings(for context: VoiceInteractionContext) -> [String] {
        switch context {
        case .medicationName, .supplementName:
            // Common medication names
            return Configuration.Voice.MedicalVocabulary.commonMedications
            
        case .dosage:
            // Common dosage terms
            return Configuration.Voice.MedicalVocabulary.dosageTerms
            
        case .frequency:
            // Frequency terms
            return Configuration.Voice.MedicalVocabulary.frequencyTerms
            
        default:
            return []
        }
    }
    
    private func applyMedicalCorrections(to text: String, context: VoiceInteractionContext) -> String {
        var corrected = text
        
        // Common misrecognitions
        let corrections = Configuration.Voice.PhoneticCorrections.medications
        
        for (wrong, right) in corrections {
            corrected = corrected.replacingOccurrences(
                of: wrong,
                with: right,
                options: [.caseInsensitive]
            )
        }
        
        return corrected
    }
    
    // MARK: - Haptic Feedback
    
    private func provideHapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Public Convenience Methods
    
    func reset() {
        stopListening()
        transcribedText = ""
        partialTranscription = ""
        error = nil
        state = .idle
        audioLevel = 0.0
    }
    
    func confirmTranscription() {
        state = .completed
    }
    
    func editTranscription(_ newText: String) {
        transcribedText = newText
        state = .completed
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension VoiceInteractionManager: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            logger.info("Speech recognizer availability changed: \(available)")
            
            if !available {
                error = AppError.voice(.speechRecognitionUnavailable)
                stopListening()
            }
        }
    }
}

// MARK: - Voice-First Helpers
extension VoiceInteractionManager {
    
    /// Process a natural language medication query
    func processMedicationQuery(_ completion: @escaping (String) -> Void) async throws {
        try await startListening(context: .conflictQuery)
        
        let timeout = Date().addingTimeInterval(30) // 30 second timeout
        
        // Wait for completion with timeout
        while Date() < timeout {
            switch state {
            case .completed:
                completion(transcribedText)
                return
            case .error(let error):
                throw error
            case .idle:
                // If we're back to idle without completion, something went wrong
                throw AppError.voice(.speechRecognitionFailed)
            default:
                // Continue listening/processing
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }
        
        // Timeout reached
        stopListening()
        throw AppError.voice(.transcriptionTimeout)
    }
    
    /// Quick medication name capture
    func captureMedicationName() async throws -> String {
        try await startListening(context: .medicationName)
        
        let timeout = Date().addingTimeInterval(15) // 15 second timeout for medication names
        
        // Wait for completion with timeout
        while Date() < timeout {
            switch state {
            case .completed:
                return transcribedText
            case .error(let error):
                throw error
            case .idle:
                // If we're back to idle without completion, something went wrong
                throw AppError.voice(.speechRecognitionFailed)
            default:
                // Continue listening/processing
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }
        
        // Timeout reached
        stopListening()
        throw AppError.voice(.transcriptionTimeout)
    }
    
    /// Extract medication components from natural speech
    func extractMedicationComponents(from speech: String) -> (name: String?, dosage: String?, frequency: String?) {
        let components = speech.components(separatedBy: " ")
        
        // Simple extraction logic - can be enhanced with NLP
        var name: String?
        var dosage: String?
        var frequency: String?
        
        // Look for dosage patterns (number + mg/mcg)
        for (index, word) in components.enumerated() {
            if word.lowercased().contains(Configuration.Voice.MedicalVocabulary.mgIdentifier) || word.lowercased().contains(Configuration.Voice.MedicalVocabulary.mcgIdentifier) {
                if index > 0, let _ = Int(components[index - 1]) {
                    dosage = "\(components[index - 1]) \(word)"
                }
            }
            
            // Look for frequency patterns
            if word.lowercased() == Configuration.Voice.MedicalVocabulary.dailyIdentifier || word.lowercased() == Configuration.Voice.MedicalVocabulary.twiceIdentifier {
                frequency = components[index...].joined(separator: " ")
                break
            }
        }
        
        // Assume first word(s) are medication name if not dosage/frequency
        if name == nil {
            name = components.first
        }
        
        return (name, dosage, frequency)
    }
}
