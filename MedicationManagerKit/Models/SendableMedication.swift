//
//  SendableMedication.swift
//  MedicationManagerKit
//
//  Created by Claude on 2025/01/14.
//  Copyright © 2025 MedicationManager. All rights reserved.
//

import Foundation

/// Thread-safe, immutable medication model for use in extensions and concurrent contexts
/// Designed for minimal memory footprint and Sendable compliance in Swift 6
@available(iOS 18.0, *)
public struct SendableMedication: Sendable, Codable, Identifiable, Hashable {
    
    // MARK: - Core Properties
    
    /// Unique identifier for the medication
    public let id: String
    
    /// User ID who owns this medication
    public let userId: String
    
    /// Name of the medication (e.g., "Ibuprofen", "Metformin")
    public let name: String
    
    /// Generic name if different from brand name
    public let genericName: String?
    
    /// Dosage amount (e.g., "200", "500")
    public let dosage: String
    
    /// Dosage unit (e.g., "mg", "mcg", "ml")
    public let dosageUnit: DosageUnit
    
    /// How often the medication is taken
    public let frequency: MedicationFrequency
    
    /// Specific times to take medication (24-hour format)
    public let scheduledTimes: [ScheduledTime]
    
    /// Active status of the medication
    public let isActive: Bool
    
    /// Instructions for taking the medication
    public let instructions: String?
    
    /// Purpose or condition being treated
    public let purpose: String?
    
    /// Start date of the medication
    public let startDate: Date
    
    /// End date of the medication (nil if ongoing)
    public let endDate: Date?
    
    /// Prescribing doctor ID (optional)
    public let doctorId: String?
    
    /// Last modification timestamp
    public let lastModified: Date
    
    /// Sync status for offline support
    public let syncStatus: SyncStatus
    
    // MARK: - Computed Properties
    
    /// Full display name with dosage
    public var displayName: String {
        "\(name) \(dosage)\(dosageUnit.abbreviation)"
    }
    
    /// Check if medication is currently active (not expired)
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
    
    /// Check if medication should be taken at a specific meal time
    public func shouldTakeAt(mealTime: MealTime) -> Bool {
        scheduledTimes.contains { $0.mealTime == mealTime }
    }
    
    /// Get scheduled time for a specific meal
    public func scheduledTimeFor(mealTime: MealTime) -> ScheduledTime? {
        scheduledTimes.first { $0.mealTime == mealTime }
    }
    
    // MARK: - Initialization
    
    public init(
        id: String,
        userId: String,
        name: String,
        genericName: String? = nil,
        dosage: String,
        dosageUnit: DosageUnit,
        frequency: MedicationFrequency,
        scheduledTimes: [ScheduledTime] = [],
        isActive: Bool = true,
        instructions: String? = nil,
        purpose: String? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        doctorId: String? = nil,
        lastModified: Date = Date(),
        syncStatus: SyncStatus = .synced
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.genericName = genericName
        self.dosage = dosage
        self.dosageUnit = dosageUnit
        self.frequency = frequency
        self.scheduledTimes = scheduledTimes
        self.isActive = isActive
        self.instructions = instructions
        self.purpose = purpose
        self.startDate = startDate
        self.endDate = endDate
        self.doctorId = doctorId
        self.lastModified = lastModified
        self.syncStatus = syncStatus
    }
}

// MARK: - Supporting Types

/// Units for medication dosage
@available(iOS 18.0, *)
public enum DosageUnit: String, Codable, Sendable, CaseIterable {
    case milligram = "mg"
    case microgram = "mcg"
    case gram = "g"
    case milliliter = "ml"
    case liter = "l"
    case unit = "unit"
    case tablet = "tablet"
    case capsule = "capsule"
    case drop = "drop"
    case patch = "patch"
    case puff = "puff"
    case spray = "spray"
    
    /// Abbreviated form for display
    public var abbreviation: String {
        switch self {
        case .milligram: return "mg"
        case .microgram: return "mcg"
        case .gram: return "g"
        case .milliliter: return "ml"
        case .liter: return "L"
        case .unit: return "U"
        case .tablet: return " tab"
        case .capsule: return " cap"
        case .drop: return " drop"
        case .patch: return " patch"
        case .puff: return " puff"
        case .spray: return " spray"
        }
    }
    
    /// Full name for voice output
    public var fullName: String {
        switch self {
        case .milligram: return "milligrams"
        case .microgram: return "micrograms"
        case .gram: return "grams"
        case .milliliter: return "milliliters"
        case .liter: return "liters"
        case .unit: return "units"
        case .tablet: return "tablets"
        case .capsule: return "capsules"
        case .drop: return "drops"
        case .patch: return "patches"
        case .puff: return "puffs"
        case .spray: return "sprays"
        }
    }
}

/// Frequency of medication intake
@available(iOS 18.0, *)
public enum MedicationFrequency: String, Codable, Sendable, CaseIterable {
    case onceDaily = "once_daily"
    case twiceDaily = "twice_daily"
    case threeTimesDaily = "three_times_daily"
    case fourTimesDaily = "four_times_daily"
    case asNeeded = "as_needed"
    case everyOtherDay = "every_other_day"
    case weekly = "weekly"
    case custom = "custom"
    
    /// Natural language description
    public var naturalDescription: String {
        switch self {
        case .onceDaily: return "Once daily"
        case .twiceDaily: return "Twice daily"
        case .threeTimesDaily: return "Three times daily"
        case .fourTimesDaily: return "Four times daily"
        case .asNeeded: return "As needed"
        case .everyOtherDay: return "Every other day"
        case .weekly: return "Weekly"
        case .custom: return "Custom schedule"
        }
    }
    
    /// Number of times per day (nil for non-daily frequencies)
    public var timesPerDay: Int? {
        switch self {
        case .onceDaily: return 1
        case .twiceDaily: return 2
        case .threeTimesDaily: return 3
        case .fourTimesDaily: return 4
        case .asNeeded, .everyOtherDay, .weekly, .custom: return nil
        }
    }
}

/// Scheduled time for medication
@available(iOS 18.0, *)
public struct ScheduledTime: Codable, Sendable, Hashable {
    /// Hour in 24-hour format (0-23)
    public let hour: Int
    
    /// Minute (0-59)
    public let minute: Int
    
    /// Associated meal time (optional)
    public let mealTime: MealTime?
    
    /// Additional notes (e.g., "with food", "on empty stomach")
    public let notes: String?
    
    public init(hour: Int, minute: Int, mealTime: MealTime? = nil, notes: String? = nil) {
        self.hour = hour
        self.minute = minute
        self.mealTime = mealTime
        self.notes = notes
    }
    
    /// Time as string in 12-hour format
    public var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        let components = DateComponents(hour: hour, minute: minute)
        
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        
        return "\(hour):\(String(format: "%02d", minute))"
    }
    
    /// Time as string in 24-hour format
    public var time24Hour: String {
        "\(hour):\(String(format: "%02d", minute))"
    }
}

/// Meal times for medication scheduling
@available(iOS 18.0, *)
public enum MealTime: String, Codable, Sendable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case bedtime = "bedtime"
    case snack = "snack"
    
    /// Default time ranges for each meal
    public var defaultTimeRange: (start: Int, end: Int) {
        switch self {
        case .breakfast: return (5, 10)   // 5 AM - 10 AM
        case .lunch: return (11, 14)      // 11 AM - 2 PM
        case .dinner: return (17, 21)     // 5 PM - 9 PM
        case .bedtime: return (21, 23)    // 9 PM - 11 PM
        case .snack: return (14, 16)      // 2 PM - 4 PM
        }
    }
    
    /// Natural language description
    public var description: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .bedtime: return "Bedtime"
        case .snack: return "Snack time"
        }
    }
}

/// Sync status for offline support
@available(iOS 18.0, *)
public enum SyncStatus: String, Codable, Sendable {
    case synced = "synced"
    case pending = "pending"
    case failed = "failed"
}

// MARK: - Extension Helpers

@available(iOS 18.0, *)
public extension SendableMedication {
    
    /// Create a minimal version for memory-constrained environments
    func minimalVersion() -> MinimalMedication {
        MinimalMedication(
            id: id,
            name: name,
            dosage: dosage,
            dosageUnit: dosageUnit.abbreviation,
            isActive: isActive
        )
    }
    
    /// Convert to voice-friendly description
    var voiceDescription: String {
        var description = "\(name), \(dosage) \(dosageUnit.fullName)"
        
        if let purpose = purpose {
            description += " for \(purpose)"
        }
        
        description += ", taken \(frequencyDescription.lowercased())"
        
        if !scheduledTimes.isEmpty {
            let times = scheduledTimes.map { $0.displayTime }.joined(separator: ", ")
            description += " at \(times)"
        }
        
        return description
    }
    
    /// Check if medication matches search query
    func matches(searchQuery: String) -> Bool {
        let query = searchQuery.lowercased()
        
        return name.lowercased().contains(query) ||
               (genericName?.lowercased().contains(query) ?? false) ||
               (purpose?.lowercased().contains(query) ?? false)
    }
}

/// Minimal medication model for memory-constrained contexts
@available(iOS 18.0, *)
public struct MinimalMedication: Sendable, Codable {
    public let id: String
    public let name: String
    public let dosage: String
    public let dosageUnit: String
    public let isActive: Bool
}

// MARK: - Array Extensions

@available(iOS 18.0, *)
public extension Array where Element == SendableMedication {
    
    /// Filter medications for a specific meal time
    func forMealTime(_ mealTime: MealTime) -> [SendableMedication] {
        filter { medication in
            medication.isCurrentlyActive && medication.shouldTakeAt(mealTime: mealTime)
        }
    }
    
    /// Filter active medications only
    var activeMedications: [SendableMedication] {
        filter { $0.isCurrentlyActive }
    }
    
    /// Group medications by frequency
    func groupedByFrequency() -> [MedicationFrequency: [SendableMedication]] {
        Dictionary(grouping: self, by: { $0.frequency })
    }
    
    /// Convert to voice-friendly list
    var voiceListDescription: String {
        if isEmpty {
            return "No medications found"
        }
        
        let medicationList = enumerated().map { index, medication in
            "\(index + 1). \(medication.displayName)"
        }.joined(separator: ", ")
        
        return "You have \(count) medication\(count == 1 ? "" : "s"): \(medicationList)"
    }
}