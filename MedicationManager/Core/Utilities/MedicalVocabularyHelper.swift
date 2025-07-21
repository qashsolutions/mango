import Foundation
import NaturalLanguage
import OSLog

// MARK: - Medical Vocabulary Helper
@MainActor
final class MedicalVocabularyHelper {
    static let shared = MedicalVocabularyHelper()
    
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "MedicalVocabularyHelper")
    
    // MARK: - Medical Terms Database
    
    private let commonMedications: Set<String> = [
        // Pain Relievers
        "acetaminophen", "tylenol", "paracetamol",
        "ibuprofen", "advil", "motrin",
        "aspirin", "bayer",
        "naproxen", "aleve",
        
        // Antibiotics
        "amoxicillin", "augmentin",
        "azithromycin", "zithromax", "z-pak",
        "ciprofloxacin", "cipro",
        "doxycycline", "vibramycin",
        "cephalexin", "keflex",
        
        // Blood Pressure
        "lisinopril", "prinivil", "zestril",
        "amlodipine", "norvasc",
        "metoprolol", "lopressor", "toprol",
        "losartan", "cozaar",
        "atenolol", "tenormin",
        "hydrochlorothiazide", "hctz",
        
        // Cholesterol
        "atorvastatin", "lipitor",
        "simvastatin", "zocor",
        "rosuvastatin", "crestor",
        "pravastatin", "pravachol",
        
        // Diabetes
        "metformin", "glucophage",
        "glipizide", "glucotrol",
        "insulin", "lantus", "humalog", "novolog",
        "januvia", "sitagliptin",
        
        // Mental Health
        "sertraline", "zoloft",
        "fluoxetine", "prozac",
        "escitalopram", "lexapro",
        "citalopram", "celexa",
        "bupropion", "wellbutrin",
        "alprazolam", "xanax",
        "lorazepam", "ativan",
        
        // Stomach/GI
        "omeprazole", "prilosec",
        "pantoprazole", "protonix",
        "ranitidine", "zantac",
        "famotidine", "pepcid",
        
        // Thyroid
        "levothyroxine", "synthroid",
        
        // Pain/Nerve
        "gabapentin", "neurontin",
        "pregabalin", "lyrica",
        "tramadol", "ultram",
        
        // Blood Thinners
        "warfarin", "coumadin",
        "rivaroxaban", "xarelto",
        "apixaban", "eliquis",
        "clopidogrel", "plavix"
    ]
    
    private let commonSupplements: Set<String> = [
        // Vitamins
        "vitamin a", "vitamin b", "vitamin b12", "vitamin b6",
        "vitamin c", "vitamin d", "vitamin d3", "vitamin e", "vitamin k",
        "multivitamin", "prenatal vitamin",
        
        // Minerals
        "calcium", "iron", "magnesium", "zinc", "potassium",
        "selenium", "chromium", "copper",
        
        // Herbs & Natural
        "fish oil", "omega 3", "omega-3",
        "turmeric", "curcumin",
        "ginger", "garlic",
        "echinacea", "elderberry",
        "ginkgo", "ginkgo biloba",
        "ginseng", "ashwagandha",
        "valerian", "melatonin",
        "st johns wort", "milk thistle",
        
        // Other Supplements
        "probiotics", "prebiotics",
        "glucosamine", "chondroitin",
        "coq10", "coenzyme q10",
        "collagen", "biotin"
    ]
    
    // Common misrecognitions and corrections
    private let voiceCorrections: [String: String] = [
        // Medication misrecognitions
        "i be profen": "ibuprofen",
        "i buprofen": "ibuprofen",
        "eye be profen": "ibuprofen",
        "met form in": "metformin",
        "met formin": "metformin",
        "metform in": "metformin",
        "as pirin": "aspirin",
        "as prin": "aspirin",
        "ass prin": "aspirin",
        "lip it or": "lipitor",
        "lip itor": "lipitor",
        "at or vastatin": "atorvastatin",
        "ator vastatin": "atorvastatin",
        "sim vastatin": "simvastatin",
        "simva statin": "simvastatin",
        "los artan": "losartan",
        "los sartan": "losartan",
        "hydrochloro thiazide": "hydrochlorothiazide",
        "hydro chlorothiazide": "hydrochlorothiazide",
        "h c t z": "hctz",
        "gaba pentin": "gabapentin",
        "gabba pentin": "gabapentin",
        "ome prazole": "omeprazole",
        "omepra zole": "omeprazole",
        "levo thyroxine": "levothyroxine",
        "levothy roxine": "levothyroxine",
        "war farin": "warfarin",
        "warfa rin": "warfarin",
        "cooma din": "coumadin",
        "coo madin": "coumadin",
        
        // Brand name corrections
        "advil": "ibuprofen",
        "tylenol": "acetaminophen",
        "motrin": "ibuprofen",
        "aleve": "naproxen",
        
        // Dosage corrections
        "milligram": "mg",
        "milligrams": "mg",
        "milli gram": "mg",
        "milli grams": "mg",
        "microgram": "mcg",
        "micrograms": "mcg",
        "micro gram": "mcg",
        "micro grams": "mcg",
        
        // Vitamin corrections
        "vitamin d": "vitamin D",
        "vitamin d3": "vitamin D3",
        "vitamin b 12": "vitamin B12",
        "vitamin b twelve": "vitamin B12",
        "vitamin c": "vitamin C",
        "vitamin e": "vitamin E",
        "vitamin k": "vitamin K",
        
        // Supplement corrections
        "fish oil": "fish oil",
        "omega three": "omega-3",
        "omega 3": "omega-3",
        "co q 10": "CoQ10",
        "co q ten": "CoQ10",
        "saint johns wort": "St. John's wort",
        "st johns wort": "St. John's wort"
    ]
    
    // Medical dosage patterns
    private let dosagePatterns = [
        "once daily", "twice daily", "three times daily", "four times daily",
        "once a day", "twice a day", "three times a day", "four times a day",
        "every morning", "every evening", "at bedtime",
        "with food", "without food", "on empty stomach",
        "as needed", "as directed", "prn"
    ]
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Correct medical terms in voice transcription
    func correctMedicalTerms(in text: String) -> String {
        var correctedText = text.lowercased()
        
        // Apply voice corrections
        for (wrong, right) in voiceCorrections {
            correctedText = correctedText.replacingOccurrences(
                of: wrong,
                with: right,
                options: [.caseInsensitive]
            )
        }
        
        // Normalize spacing around numbers and units
        correctedText = normalizeUnits(in: correctedText)
        
        // Capitalize proper medication names
        correctedText = capitalizeMedications(in: correctedText)
        
        logger.debug("Corrected text: '\(text)' -> '\(correctedText)'")
        
        return correctedText
    }
    
    /// Extract medication information from natural language
    func extractMedicationInfo(from text: String) -> MedicationInfo {
        let normalizedText = text.lowercased()
        
        var info = MedicationInfo()
        
        // Extract medication name
        info.name = extractMedicationName(from: normalizedText)
        
        // Extract dosage
        info.dosage = extractDosage(from: normalizedText)
        
        // Extract frequency
        info.frequency = extractFrequency(from: normalizedText)
        
        // Extract timing
        info.timing = extractTiming(from: normalizedText)
        
        // Extract notes
        info.notes = extractNotes(from: normalizedText)
        
        logger.info("Extracted medication info: \(String(describing: info))")
        
        return info
    }
    
    /// Check if text contains a known medication
    func containsMedication(_ text: String) -> Bool {
        let normalizedText = text.lowercased()
        
        // Check common medications
        for medication in commonMedications {
            if normalizedText.contains(medication) {
                return true
            }
        }
        
        // Check supplements
        for supplement in commonSupplements {
            if normalizedText.contains(supplement) {
                return true
            }
        }
        
        return false
    }
    
    /// Get medication suggestions based on partial input
    func getSuggestions(for partialText: String, limit: Int = Configuration.App.suggestionLimit) -> [String] {
        let searchText = partialText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return [] }
        
        var suggestions: [String] = []
        
        // Search medications
        let medicationMatches = commonMedications.filter { medication in
            medication.hasPrefix(searchText) || medication.contains(searchText)
        }.sorted { first, second in
            // Prioritize prefix matches
            if first.hasPrefix(searchText) && !second.hasPrefix(searchText) {
                return true
            } else if !first.hasPrefix(searchText) && second.hasPrefix(searchText) {
                return false
            }
            return first < second
        }
        
        suggestions.append(contentsOf: medicationMatches.prefix(limit / 2))
        
        // Search supplements
        let supplementMatches = commonSupplements.filter { supplement in
            supplement.hasPrefix(searchText) || supplement.contains(searchText)
        }.sorted { first, second in
            if first.hasPrefix(searchText) && !second.hasPrefix(searchText) {
                return true
            } else if !first.hasPrefix(searchText) && second.hasPrefix(searchText) {
                return false
            }
            return first < second
        }
        
        suggestions.append(contentsOf: supplementMatches.prefix(limit / 2))
        
        return Array(suggestions.prefix(limit))
    }
    
    /// Validate medication name
    func isValidMedication(_ name: String) -> Bool {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return commonMedications.contains(normalized) || commonSupplements.contains(normalized)
    }
    
    /// Validate supplement name
    func isValidSupplement(_ name: String) -> Bool {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return commonSupplements.contains(normalized)
    }
    
    // MARK: - Private Methods
    
    private func normalizeUnits(in text: String) -> String {
        var result = text
        
        // Add space before units if missing
        result = result.replacingOccurrences(of: "(\\d+)(mg|mcg|ml|g)", with: "$1 $2", options: .regularExpression)
        
        // Normalize unit format
        result = result.replacingOccurrences(of: " milligram", with: " mg")
        result = result.replacingOccurrences(of: " milligrams", with: " mg")
        result = result.replacingOccurrences(of: " microgram", with: " mcg")
        result = result.replacingOccurrences(of: " micrograms", with: " mcg")
        result = result.replacingOccurrences(of: " milliliter", with: " ml")
        result = result.replacingOccurrences(of: " milliliters", with: " ml")
        
        return result
    }
    
    private func capitalizeMedications(in text: String) -> String {
        var result = text
        
        // Capitalize brand names that should be capitalized
        let brandNames = ["tylenol", "advil", "motrin", "aleve", "lipitor", "zocor", "crestor", "prilosec", "nexium", "zantac"]
        for brand in brandNames {
            result = result.replacingOccurrences(
                of: "\\b\(brand)\\b",
                with: brand.capitalized,
                options: .regularExpression
            )
        }
        
        // Capitalize vitamins
        result = result.replacingOccurrences(of: "vitamin d", with: "vitamin D")
        result = result.replacingOccurrences(of: "vitamin b12", with: "vitamin B12")
        
        return result
    }
    
    private func extractMedicationName(from text: String) -> String? {
        // First check for exact matches
        for medication in commonMedications {
            if text.contains(medication) {
                return medication
            }
        }
        
        for supplement in commonSupplements {
            if text.contains(supplement) {
                return supplement
            }
        }
        
        // Use NLP to find potential medication names
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var potentialMedication: String?
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            let word = String(text[range])
            
            // Check if it could be a medication
            if word.count > 3 && word.rangeOfCharacter(from: .decimalDigits) == nil {
                potentialMedication = word
                return false
            }
            
            return true
        }
        
        return potentialMedication
    }
    
    private func extractDosage(from text: String) -> String? {
        // Look for number + unit patterns
        let pattern = "(\\d+(?:\\.\\d+)?\\s*(?:mg|mcg|g|ml|iu|units?))"
        
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        
        return nil
    }
    
    private func extractFrequency(from text: String) -> String? {
        // Check common frequency patterns
        for pattern in dosagePatterns {
            if text.contains(pattern) {
                return pattern
            }
        }
        
        // Look for "X times" patterns
        let timesPattern = "(\\d+|once|twice|three|four)\\s+times?\\s+(a\\s+)?(day|daily)"
        if let range = text.range(of: timesPattern, options: .regularExpression) {
            return String(text[range])
        }
        
        return nil
    }
    
    private func extractTiming(from text: String) -> String? {
        let timingKeywords = ["morning", "evening", "night", "bedtime", "breakfast", "lunch", "dinner", "meal", "food"]
        
        for keyword in timingKeywords {
            if text.contains(keyword) {
                // Extract the phrase around the keyword
                if let keywordRange = text.range(of: keyword) {
                    let start = text.index(keywordRange.lowerBound, offsetBy: -10, limitedBy: text.startIndex) ?? text.startIndex
                    let end = text.index(keywordRange.upperBound, offsetBy: 10, limitedBy: text.endIndex) ?? text.endIndex
                    return String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return nil
    }
    
    private func extractNotes(from text: String) -> String? {
        // Look for special instructions
        let noteKeywords = ["avoid", "take with", "do not", "caution", "warning", "empty stomach", "full stomach"]
        
        for keyword in noteKeywords {
            if text.contains(keyword) {
                if let keywordRange = text.range(of: keyword) {
                    let start = keywordRange.lowerBound
                    let end = text.index(start, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex
                    return String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types

struct MedicationInfo {
    var name: String?
    var dosage: String?
    var frequency: String?
    var timing: String?
    var notes: String?
    
    var isComplete: Bool {
        return name != nil && dosage != nil && frequency != nil
    }
}

// MARK: - Voice Context Extensions

extension MedicalVocabularyHelper {
    
    /// Get contextual hints for voice recognition
    func getContextualHints(for context: VoiceInteractionContext) -> [String] {
        switch context {
        case .medicationName:
            return Array(commonMedications.prefix(50))
            
        case .supplementName:
            return Array(commonSupplements.prefix(30))
            
        case .dosage:
            return ["1 mg", "5 mg", "10 mg", "25 mg", "50 mg", "100 mg", "250 mg", "500 mg", "1000 mg",
                    "0.5 mg", "2.5 mg", "12.5 mg", "0.25 mg", "0.125 mg",
                    "once daily", "twice daily", "three times daily", "as needed"]
            
        case .frequency:
            return dosagePatterns
            
        case .conflictQuery:
            return ["what happens if", "can I take", "is it safe", "interaction between",
                    "side effects", "together with", "at the same time"]
            
        default:
            return []
        }
    }
    
    /// Format medication for display
    func formatMedication(_ medication: String, dosage: String? = nil, frequency: String? = nil) -> String {
        var formatted = medication.capitalized
        
        if let dosage = dosage {
            formatted += " \(dosage)"
        }
        
        if let frequency = frequency {
            formatted += " - \(frequency)"
        }
        
        return formatted
    }
}

// MARK: - Spell Check Extensions

extension MedicalVocabularyHelper {
    
    /// Check if a word is likely misspelled medication
    func isMisspelledMedication(_ word: String) -> Bool {
        let normalized = word.lowercased()
        
        // Check exact matches first
        if commonMedications.contains(normalized) || commonSupplements.contains(normalized) {
            return false
        }
        
        // Check if it's close to any known medication
        for medication in commonMedications {
            if levenshteinDistance(normalized, medication) <= 2 {
                return true
            }
        }
        
        return false
    }
    
    /// Get spelling suggestions for medication
    func getSpellingSuggestions(for word: String) -> [String] {
        let normalized = word.lowercased()
        var suggestions: [(String, Int)] = []
        
        // Check medications
        for medication in commonMedications {
            let distance = levenshteinDistance(normalized, medication)
            if distance <= 3 {
                suggestions.append((medication, distance))
            }
        }
        
        // Check supplements
        for supplement in commonSupplements {
            let distance = levenshteinDistance(normalized, supplement)
            if distance <= 3 {
                suggestions.append((supplement, distance))
            }
        }
        
        // Sort by distance and return top suggestions
        return suggestions
            .sorted { $0.1 < $1.1 }
            .prefix(Configuration.App.spellCheckSuggestionLimit)
            .map { $0.0 }
    }
    
    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            matrix[i][0] = i
        }
        
        for j in 0...n {
            matrix[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1[s1.index(s1.startIndex, offsetBy: i - 1)] == s2[s2.index(s2.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }
        
        return matrix[m][n]
    }
}
