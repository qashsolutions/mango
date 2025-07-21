//
//  SendableSupplement.swift
//  MedicationManagerKit
//
//  Created by Claude on 2025/01/14.
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import Foundation

/// Thread-safe, immutable supplement model for use in extensions and concurrent contexts
/// Designed for vitamins, minerals, and nutritional supplements with Swift 6 compliance
@available(iOS 18.0, *)
public struct SendableSupplement: Sendable, Codable, Identifiable, Hashable {
    
    // MARK: - Core Properties
    
    /// Unique identifier for the supplement
    public let id: String
    
    /// User ID who owns this supplement
    public let userId: String
    
    /// Name of the supplement (e.g., "Vitamin D3", "Omega-3")
    public let name: String
    
    /// Brand name (optional)
    public let brand: String?
    
    /// Dosage amount (e.g., "1000", "500")
    public let dosage: String
    
    /// Dosage unit specific to supplements
    public let dosageUnit: SupplementDosageUnit
    
    /// Form of the supplement
    public let form: SupplementForm
    
    /// How often the supplement is taken
    public let frequency: SupplementFrequency
    
    /// Specific times to take supplement (24-hour format)
    public let scheduledTimes: [ScheduledTime]
    
    /// Active status of the supplement
    public let isActive: Bool
    
    /// Instructions for taking the supplement
    public let instructions: String?
    
    /// Purpose or health benefit
    public let purpose: String?
    
    /// Category of supplement
    public let category: SupplementCategory
    
    /// Start date of the supplement
    public let startDate: Date
    
    /// End date of the supplement (nil if ongoing)
    public let endDate: Date?
    
    /// Whether to take with food
    public let withFood: Bool
    
    /// Last modification timestamp
    public let lastModified: Date
    
    /// Sync status for offline support
    public let syncStatus: SyncStatus
    
    // MARK: - Computed Properties
    
    /// Full display name with dosage
    public var displayName: String {
        var display = name
        if let brand = brand {
            display += " (\(brand))"
        }
        display += " \(dosage)\(dosageUnit.abbreviation)"
        return display
    }
    
    /// Check if supplement is currently active (not expired)
    public var isCurrentlyActive: Bool {
        guard isActive else { return false }
        
        if let endDate = endDate {
            return Date() <= endDate
        }
        return true
    }
    
    /// Natural language frequency description
    public var frequencyDescription: String {
        frequency.naturalDescription
    }
    
    /// Instructions for voice output
    public var voiceInstructions: String {
        var instructions = [String]()
        
        // Add form information
        instructions.append("Take \(form.voiceDescription)")
        
        // Add food requirement
        if withFood {
            instructions.append("with food")
        } else if let customInstructions = self.instructions {
            instructions.append(customInstructions)
        }
        
        // Add frequency
        instructions.append(frequencyDescription.lowercased())
        
        return instructions.joined(separator: " ")
    }
    
    /// Check if supplement should be taken at a specific meal time
    public func shouldTakeAt(mealTime: MealTime) -> Bool {
        scheduledTimes.contains { $0.mealTime == mealTime }
    }
    
    // MARK: - Initialization
    
    public init(
        id: String,
        userId: String,
        name: String,
        brand: String? = nil,
        dosage: String,
        dosageUnit: SupplementDosageUnit,
        form: SupplementForm = .tablet,
        frequency: SupplementFrequency,
        scheduledTimes: [ScheduledTime] = [],
        isActive: Bool = true,
        instructions: String? = nil,
        purpose: String? = nil,
        category: SupplementCategory,
        startDate: Date = Date(),
        endDate: Date? = nil,
        withFood: Bool = false,
        lastModified: Date = Date(),
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.brand = brand
        self.dosage = dosage
        self.dosageUnit = dosageUnit
        self.form = form
        self.frequency = frequency
        self.scheduledTimes = scheduledTimes
        self.isActive = isActive
        self.instructions = instructions
        self.purpose = purpose
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.withFood = withFood
        self.lastModified = lastModified
        self.syncStatus = syncStatus
    }
}

// MARK: - Supporting Types

/// Units specific to supplements
@available(iOS 18.0, *)
public enum SupplementDosageUnit: String, Codable, Sendable, CaseIterable {
    case milligram = "mg"
    case microgram = "mcg"
    case gram = "g"
    case internationalUnit = "IU"
    case colonyFormingUnit = "CFU"
    case milliliter = "ml"
    case drop = "drop"
    case teaspoon = "tsp"
    case tablespoon = "tbsp"
    case packet = "packet"
    case scoop = "scoop"
    
    /// Abbreviated form for display
    public var abbreviation: String {
        switch self {
        case .milligram: return "mg"
        case .microgram: return "mcg"
        case .gram: return "g"
        case .internationalUnit: return "IU"
        case .colonyFormingUnit: return "CFU"
        case .milliliter: return "ml"
        case .drop: return " drops"
        case .teaspoon: return " tsp"
        case .tablespoon: return " tbsp"
        case .packet: return " packet"
        case .scoop: return " scoop"
        }
    }
    
    /// Full name for voice output
    public var fullName: String {
        switch self {
        case .milligram: return "milligrams"
        case .microgram: return "micrograms"
        case .gram: return "grams"
        case .internationalUnit: return "international units"
        case .colonyFormingUnit: return "colony forming units"
        case .milliliter: return "milliliters"
        case .drop: return "drops"
        case .teaspoon: return "teaspoons"
        case .tablespoon: return "tablespoons"
        case .packet: return "packets"
        case .scoop: return "scoops"
        }
    }
}

/// Forms of supplements
@available(iOS 18.0, *)
public enum SupplementForm: String, Codable, Sendable, CaseIterable {
    case tablet = "tablet"
    case capsule = "capsule"
    case softgel = "softgel"
    case gummy = "gummy"
    case powder = "powder"
    case liquid = "liquid"
    case chewable = "chewable"
    case sublingual = "sublingual"
    case patch = "patch"
    case lozenge = "lozenge"
    
    /// Description for voice output
    public var voiceDescription: String {
        switch self {
        case .tablet: return "one tablet"
        case .capsule: return "one capsule"
        case .softgel: return "one softgel"
        case .gummy: return "gummies"
        case .powder: return "powder"
        case .liquid: return "liquid"
        case .chewable: return "chewable tablet"
        case .sublingual: return "sublingual tablet"
        case .patch: return "patch"
        case .lozenge: return "lozenge"
        }
    }
}

/// Frequency specific to supplements
@available(iOS 18.0, *)
public enum SupplementFrequency: String, Codable, Sendable, CaseIterable {
    case daily = "daily"
    case twiceDaily = "twice_daily"
    case threeTimesDaily = "three_times_daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case asNeeded = "as_needed"
    case withMeals = "with_meals"
    case custom = "custom"
    
    /// Natural language description
    public var naturalDescription: String {
        switch self {
        case .daily: return "Once daily"
        case .twiceDaily: return "Twice daily"
        case .threeTimesDaily: return "Three times daily"
        case .weekly: return "Once weekly"
        case .biweekly: return "Every two weeks"
        case .monthly: return "Once monthly"
        case .asNeeded: return "As needed"
        case .withMeals: return "With meals"
        case .custom: return "Custom schedule"
        }
    }
}

/// Categories of supplements
@available(iOS 18.0, *)
public enum SupplementCategory: String, Codable, Sendable, CaseIterable {
    case vitamin = "vitamin"
    case mineral = "mineral"
    case herb = "herb"
    case aminoAcid = "amino_acid"
    case enzyme = "enzyme"
    case probiotic = "probiotic"
    case omega = "omega"
    case antioxidant = "antioxidant"
    case fiber = "fiber"
    case protein = "protein"
    case other = "other"
    
    /// Display name
    public var displayName: String {
        switch self {
        case .vitamin: return "Vitamin"
        case .mineral: return "Mineral"
        case .herb: return "Herbal"
        case .aminoAcid: return "Amino Acid"
        case .enzyme: return "Enzyme"
        case .probiotic: return "Probiotic"
        case .omega: return "Omega Fatty Acid"
        case .antioxidant: return "Antioxidant"
        case .fiber: return "Fiber"
        case .protein: return "Protein"
        case .other: return "Other"
        }
    }
    
    /// Common examples for each category
    public var examples: [String] {
        switch self {
        case .vitamin: return ["Vitamin D", "Vitamin C", "B12", "Vitamin E"]
        case .mineral: return ["Calcium", "Iron", "Magnesium", "Zinc"]
        case .herb: return ["Echinacea", "Ginseng", "Turmeric", "Garlic"]
        case .aminoAcid: return ["L-Glutamine", "L-Arginine", "BCAA"]
        case .enzyme: return ["Digestive Enzymes", "Bromelain", "Papain"]
        case .probiotic: return ["Lactobacillus", "Bifidobacterium", "Saccharomyces"]
        case .omega: return ["Omega-3", "Fish Oil", "Flaxseed Oil"]
        case .antioxidant: return ["CoQ10", "Resveratrol", "Alpha Lipoic Acid"]
        case .fiber: return ["Psyllium", "Inulin", "Methylcellulose"]
        case .protein: return ["Whey Protein", "Collagen", "Plant Protein"]
        case .other: return ["Glucosamine", "Melatonin", "Probiotics"]
        }
    }
}

// MARK: - Extension Helpers

@available(iOS 18.0, *)
public extension SendableSupplement {
    
    /// Create a minimal version for memory-constrained environments
    func minimalVersion() -> MinimalSupplement {
        MinimalSupplement(
            id: id,
            name: name,
            dosage: dosage,
            dosageUnit: dosageUnit.abbreviation,
            category: category.rawValue,
            isActive: isActive
        )
    }
    
    /// Convert to voice-friendly description
    var voiceDescription: String {
        var description = name
        
        if let brand = brand {
            description += " by \(brand)"
        }
        
        description += ", \(dosage) \(dosageUnit.fullName)"
        
        if let purpose = purpose {
            description += " for \(purpose)"
        }
        
        description += ", taken \(frequencyDescription.lowercased())"
        
        if withFood {
            description += " with food"
        }
        
        return description
    }
    
    /// Check if supplement matches search query
    func matches(searchQuery: String) -> Bool {
        let query = searchQuery.lowercased()
        
        return name.lowercased().contains(query) ||
               (brand?.lowercased().contains(query) ?? false) ||
               (purpose?.lowercased().contains(query) ?? false) ||
               category.displayName.lowercased().contains(query)
    }
    
    /// Check for potential interactions with medications
    var potentialInteractionCategories: [String] {
        switch category {
        case .vitamin:
            // Some vitamins can interact with medications
            if name.lowercased().contains("k") {
                return ["anticoagulants", "warfarin"]
            }
            return []
            
        case .mineral:
            // Minerals can affect absorption
            if name.lowercased().contains("calcium") || name.lowercased().contains("iron") {
                return ["antibiotics", "thyroid medications"]
            }
            return []
            
        case .herb:
            // Many herbs have drug interactions
            return ["blood thinners", "antidepressants", "immunosuppressants"]
            
        case .omega:
            // Omega-3s can affect blood clotting
            return ["anticoagulants", "antiplatelet drugs"]
            
        default:
            return []
        }
    }
}

/// Minimal supplement model for memory-constrained contexts
@available(iOS 18.0, *)
public struct MinimalSupplement: Sendable, Codable {
    public let id: String
    public let name: String
    public let dosage: String
    public let dosageUnit: String
    public let category: String
    public let isActive: Bool
}

// MARK: - Array Extensions

@available(iOS 18.0, *)
public extension Array where Element == SendableSupplement {
    
    /// Filter supplements for a specific meal time
    func forMealTime(_ mealTime: MealTime) -> [SendableSupplement] {
        filter { supplement in
            supplement.isCurrentlyActive && supplement.shouldTakeAt(mealTime: mealTime)
        }
    }
    
    /// Filter active supplements only
    var activeSupplements: [SendableSupplement] {
        filter { $0.isCurrentlyActive }
    }
    
    /// Group supplements by category
    func groupedByCategory() -> [SupplementCategory: [SendableSupplement]] {
        Dictionary(grouping: self, by: { $0.category })
    }
    
    /// Filter supplements that need to be taken with food
    var withFoodRequired: [SendableSupplement] {
        filter { $0.withFood }
    }
    
    /// Convert to voice-friendly list
    var voiceListDescription: String {
        if isEmpty {
            return "No supplements found"
        }
        
        let supplementList = enumerated().map { index, supplement in
            "\(index + 1). \(supplement.displayName)"
        }.joined(separator: ", ")
        
        return "You have \(count) supplement\(count == 1 ? "" : "s"): \(supplementList)"
    }
    
    /// Get supplements by category
    func byCategory(_ category: SupplementCategory) -> [SendableSupplement] {
        filter { $0.category == category }
    }
}