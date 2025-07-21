import Foundation

/// Extensions for Calendar to provide safe date calculations
extension Calendar {
    
    /// Safely calculates the end of day for a given date
    /// - Parameter date: The date to calculate end of day for
    /// - Returns: The end of day (start of next day)
    /// - Throws: AppError if date calculation fails
    func safeEndOfDay(for date: Date) throws -> Date {
        let startOfDay = self.startOfDay(for: date)
        guard let endOfDay = self.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw AppError.data(.invalidDate)
        }
        return endOfDay
    }
    
    /// Safely calculates the start of day for a given date
    /// - Parameter date: The date to calculate start of day for
    /// - Returns: The start of day
    /// - Throws: AppError if date calculation fails
    func safeStartOfDay(for date: Date) throws -> Date {
        let startOfDay = self.startOfDay(for: date)
        return startOfDay
    }
    
    /// Safely adds days to a date
    /// - Parameters:
    ///   - days: Number of days to add (can be negative)
    ///   - date: The base date
    /// - Returns: The new date with days added
    /// - Throws: AppError if date calculation fails
    func safeAdd(days: Int, to date: Date) throws -> Date {
        guard let newDate = self.date(byAdding: .day, value: days, to: date) else {
            throw AppError.data(.invalidDate)
        }
        return newDate
    }
    
    /// Safely adds a date component to a date
    /// - Parameters:
    ///   - component: The calendar component to add
    ///   - value: The value to add
    ///   - date: The base date
    /// - Returns: The new date with component added
    /// - Throws: AppError if date calculation fails
    func safeAdd(component: Calendar.Component, value: Int, to date: Date) throws -> Date {
        guard let newDate = self.date(byAdding: component, value: value, to: date) else {
            throw AppError.data(.invalidDate)
        }
        return newDate
    }
}
