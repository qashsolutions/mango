import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()
    
    @Published var isRecording: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var recognizedText: String = ""
    @Published var speechError: AppError?
    @Published var isProcessing: Bool = false
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    private override init() {
        super.init()
        setupSpeechRecognizer()
        checkAuthorizationStatus()
    }
    
    // MARK: - Setup
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    private func checkAuthorizationStatus() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            isAuthorized = true
        case .denied, .restricted, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Authorization
    func requestSpeechAuthorization() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self?.isAuthorized = true
                    case .denied:
                        self?.speechError = AppError.voice(.microphonePermissionDenied)
                        self?.isAuthorized = false
                    case .restricted:
                        self?.speechError = AppError.voice(.speechRecognitionUnavailable)
                        self?.isAuthorized = false
                    case .notDetermined:
                        self?.speechError = AppError.voice(.speechRecognitionUnavailable)
                        self?.isAuthorized = false
                    @unknown default:
                        self?.speechError = AppError.voice(.speechRecognitionFailed)
                        self?.isAuthorized = false
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Recording Control
    func startRecording() async throws {
        guard isAuthorized else {
            throw AppError.voice(.microphonePermissionDenied)
        }
        
        guard !isRecording else {
            return
        }
        
        let microphoneGranted = await requestMicrophoneAccess()
        guard microphoneGranted else {
            throw AppError.voice(.microphonePermissionDenied)
        }
        
        try await setupAudioSession()
        try await startSpeechRecognition()
        
        isRecording = true
        recognizedText = ""
        speechError = nil
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        isRecording = false
    }
    
    private func setupAudioSession() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                continuation.resume()
            } catch {
                continuation.resume(throwing: AppError.voice(.audioSessionError))
            }
        }
    }
    
    private func startSpeechRecognition() async throws {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw AppError.voice(.speechRecognitionFailed)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                    self?.processRecognizedText(result.bestTranscription.formattedString, isFinal: result.isFinal)
                }
                
                if let error = error {
                    self?.speechError = AppError.voice(.speechRecognitionFailed)
                    self?.stopRecording()
                }
            }
        }
    }
    
    // MARK: - Text Processing
    private func processRecognizedText(_ text: String, isFinal: Bool) {
        guard isFinal else { return }
        
        isProcessing = true
        
        Task {
            let processedText = await enhanceTextForMedicalContext(text)
            
            await MainActor.run {
                self.recognizedText = processedText
                self.isProcessing = false
            }
        }
    }
    
    private func enhanceTextForMedicalContext(_ text: String) async -> String {
        var enhancedText = text.lowercased()
        
        // Common medication name corrections
        let medicationCorrections: [String: String] = [
            "advil": "Advil",
            "tylenol": "Tylenol",
            "aspirin": "Aspirin",
            "ibuprofen": "Ibuprofen",
            "acetaminophen": "Acetaminophen",
            "lisinopril": "Lisinopril",
            "metformin": "Metformin",
            "atorvastatin": "Atorvastatin",
            "amlodipine": "Amlodipine",
            "omeprazole": "Omeprazole",
            "levothyroxine": "Levothyroxine",
            "albuterol": "Albuterol",
            "prednisone": "Prednisone",
            "warfarin": "Warfarin",
            "insulin": "Insulin"
        ]
        
        // Dosage corrections
        let dosageCorrections: [String: String] = [
            "milligrams": "mg",
            "milligram": "mg",
            "grams": "g",
            "gram": "g",
            "milliliters": "ml",
            "milliliter": "ml",
            "tablets": "tablets",
            "tablet": "tablet",
            "capsules": "capsules",
            "capsule": "capsule",
            "teaspoons": "tsp",
            "teaspoon": "tsp",
            "tablespoons": "tbsp",
            "tablespoon": "tbsp"
        ]
        
        // Frequency corrections
        let frequencyCorrections: [String: String] = [
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
            "with food": "with food",
            "on empty stomach": "on empty stomach"
        ]
        
        // Apply corrections
        for (incorrect, correct) in medicationCorrections {
            enhancedText = enhancedText.replacingOccurrences(of: incorrect, with: correct)
        }
        
        for (incorrect, correct) in dosageCorrections {
            enhancedText = enhancedText.replacingOccurrences(of: incorrect, with: correct)
        }
        
        for (incorrect, correct) in frequencyCorrections {
            enhancedText = enhancedText.replacingOccurrences(of: incorrect, with: correct)
        }
        
        // Capitalize first letter of sentences
        enhancedText = enhancedText.capitalizingFirstLetter()
        
        return enhancedText
    }
    
    // MARK: - Specialized Voice Input
    func recognizeMedicationName() async throws -> String {
        try await startRecording()
        
        return await withCheckedContinuation { continuation in
            // Wait for final result or timeout
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.stopRecording()
                continuation.resume(returning: self.recognizedText)
            }
        }
    }
    
    func recognizeDosage() async throws -> String {
        try await startRecording()
        
        return await withCheckedContinuation { continuation in
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                self.stopRecording()
                let dosage = self.extractDosageFromText(self.recognizedText)
                continuation.resume(returning: dosage)
            }
        }
    }
    
    func recognizeFrequency() async throws -> String {
        try await startRecording()
        
        return await withCheckedContinuation { continuation in
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.stopRecording()
                let frequency = self.extractFrequencyFromText(self.recognizedText)
                continuation.resume(returning: frequency)
            }
        }
    }
    
    // MARK: - Text Extraction Helpers
    private func extractDosageFromText(_ text: String) -> String {
        let dosagePatterns = [
            #"\d+\s*(mg|milligrams?|g|grams?|ml|milliliters?|tablets?|capsules?|tsp|teaspoons?|tbsp|tablespoons?)"#,
            #"\d+/\d+\s*(mg|g|ml|tablets?|capsules?)"#,
            #"(one|two|three|four|five|six|seven|eight|nine|ten)\s*(mg|milligrams?|g|grams?|ml|milliliters?|tablets?|capsules?|tsp|teaspoons?|tbsp|tablespoons?)"#
        ]
        
        for pattern in dosagePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                return String(text[match])
            }
        }
        
        return text
    }
    
    private func extractFrequencyFromText(_ text: String) -> String {
        let frequencyKeywords = [
            "once daily", "twice daily", "three times daily", "four times daily",
            "every morning", "every evening", "every night",
            "before meals", "after meals", "with food", "on empty stomach",
            "as needed", "when necessary"
        ]
        
        for keyword in frequencyKeywords {
            if text.lowercased().contains(keyword) {
                return keyword
            }
        }
        
        return text
    }
    
    // MARK: - Error Handling
    func clearError() {
        speechError = nil
    }
    
    func resetSpeechRecognition() {
        stopRecording()
        recognizedText = ""
        speechError = nil
        isProcessing = false
    }
}

// MARK: - Speech Recognizer Delegate
extension SpeechManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            speechError = AppError.voice(.speechRecognitionUnavailable)
            stopRecording()
        }
    }
}

// MARK: - String Extensions
extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

// MARK: - Voice Input Context
enum VoiceInputContext {
    case medicationName
    case dosage
    case frequency
    case notes
    case doctorName
    case doctorSpecialty
    case foodName
    case general
    
    var promptText: String {
        switch self {
        case .medicationName:
            return "Say the medication name"
        case .dosage:
            return "Say the dosage amount"
        case .frequency:
            return "Say how often to take"
        case .notes:
            return "Add any notes"
        case .doctorName:
            return "Say the doctor's name"
        case .doctorSpecialty:
            return "Say the specialty"
        case .foodName:
            return "Say the food name"
        case .general:
            return "Start speaking"
        }
    }
    
    var maxDuration: TimeInterval {
        switch self {
        case .medicationName, .doctorName, .foodName:
            return 3.0
        case .dosage:
            return 2.0
        case .frequency:
            return 5.0
        case .notes:
            return 10.0
        case .doctorSpecialty:
            return 3.0
        case .general:
            return 8.0
        }
    }
}

// MARK: - Sample Data for Development
#if DEBUG
extension SpeechManager {
    static let mockSpeechManager: SpeechManager = {
        let manager = SpeechManager()
        manager.isAuthorized = true
        manager.recognizedText = "Lisinopril 10 mg once daily"
        return manager
    }()
}
#endif
