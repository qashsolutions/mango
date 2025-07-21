import Foundation

// MARK: - Common Strings used across the app
extension AppStrings.Common {
    // Additional common strings not in main AppStrings
    static let add = NSLocalizedString("common.add", value: "Add", comment: "Add")
    static let asNeeded = NSLocalizedString("common.asNeeded", value: "As needed", comment: "As needed")
    static let back = NSLocalizedString("common.back", value: "Back", comment: "Back")
    static let date = NSLocalizedString("common.date", value: "Date", comment: "Date")
    static let capsules = NSLocalizedString("common.capsules", value: "capsules", comment: "capsules")
    static let close = NSLocalizedString("common.close", value: "Close", comment: "Close")
    static let completed = NSLocalizedString("common.completed", value: "Completed", comment: "Completed")
    static let daily = NSLocalizedString("common.daily", value: "Daily", comment: "Daily")
    static let delete = NSLocalizedString("common.delete", value: "Delete", comment: "Delete")
    static let details = NSLocalizedString("common.details", value: "Details", comment: "Details")
    static let dueNow = NSLocalizedString("common.dueNow", value: "Due Now", comment: "Due now")
    static let error = NSLocalizedString("common.error", value: "Error", comment: "Error")
    static let fourTimesDaily = NSLocalizedString("common.fourTimesDaily", value: "Four times daily", comment: "Four times daily")
    static let mcg = NSLocalizedString("common.mcg", value: "mcg", comment: "mcg")
    static let mg = NSLocalizedString("common.mg", value: "mg", comment: "mg")
    static let ml = NSLocalizedString("common.ml", value: "ml", comment: "ml")
    static let monthly = NSLocalizedString("common.monthly", value: "Monthly", comment: "Monthly")
    static let next = NSLocalizedString("common.next", value: "Next", comment: "Next")
    static let no = NSLocalizedString("common.no", value: "No", comment: "No")
    static let none = NSLocalizedString("common.none", value: "None", comment: "None")
    static let notes = NSLocalizedString("common.notes", value: "Notes", comment: "Notes")
    static let onceDaily = NSLocalizedString("common.onceDaily", value: "Once daily", comment: "Once daily")
    static let optional = NSLocalizedString("common.optional", value: "Optional", comment: "Optional")
    static let other = NSLocalizedString("common.other", value: "Other", comment: "Other")
    static let overdue = NSLocalizedString("common.overdue", value: "Overdue", comment: "Overdue")
    static let pleaseWait = NSLocalizedString("common.pleaseWait", value: "Please wait...", comment: "Please wait...")
    static let processing = NSLocalizedString("common.processing", value: "Processing...", comment: "Processing...")
    static let refresh = NSLocalizedString("common.refresh", value: "Refresh", comment: "Refresh")
    static let save = NSLocalizedString("common.save", value: "Save", comment: "Save")
    static let saving = NSLocalizedString("common.saving", value: "Saving...", comment: "Saving...")
    static let scheduled = NSLocalizedString("common.scheduled", value: "Scheduled", comment: "Scheduled")
    static let search = NSLocalizedString("common.search", value: "Search", comment: "Search")
    static let select = NSLocalizedString("common.select", value: "Select", comment: "Select")
    static let selected = NSLocalizedString("common.selected", value: "Selected", comment: "Selected")
    static let send = NSLocalizedString("common.send", value: "Send", comment: "Send")
    static let sort = NSLocalizedString("common.sort", value: "Sort", comment: "Sort")
    static let tablets = NSLocalizedString("common.tablets", value: "tablets", comment: "tablets")
    static let threeTimesDaily = NSLocalizedString("common.threeTimesDaily", value: "Three times daily", comment: "Three times daily")
    static let today = NSLocalizedString("common.today", value: "Today", comment: "Today")
    static let tomorrow = NSLocalizedString("common.tomorrow", value: "Tomorrow", comment: "Tomorrow")
    static let twiceDaily = NSLocalizedString("common.twiceDaily", value: "Twice daily", comment: "Twice daily")
    static let update = NSLocalizedString("common.update", value: "Update", comment: "Update")
    static let updating = NSLocalizedString("common.updating", value: "Updating...", comment: "Updating...")
    static let weekly = NSLocalizedString("common.weekly", value: "Weekly", comment: "Weekly")
    static let yesterday = NSLocalizedString("common.yesterday", value: "Yesterday", comment: "Yesterday")
    static let markAsTaken = NSLocalizedString("common.markAsTaken", value: "Mark as Taken", comment: "Mark as taken")
    static let meal = NSLocalizedString("common.meal", value: "Meal", comment: "Meal")
    static let medication = NSLocalizedString("common.medication", value: "Medication", comment: "Medication")
    static let supplement = NSLocalizedString("common.supplement", value: "Supplement", comment: "Supplement")
    static let notAvailable = NSLocalizedString("common.notAvailable", value: "Not Available", comment: "Not available")
    static let doctorName = NSLocalizedString("common.doctorName", value: "Doctor's name", comment: "Doctor's name")
    static let safety = NSLocalizedString("common.safety", value: "Safety", comment: "Safety")
    
    // MARK: - Interpolated Strings
    static func please(_ action: String) -> String {
        String(format: NSLocalizedString("common.please", value: "Please %@", comment: "Please do something"), action)
    }
}

extension AppStrings {
    struct Success {
        static func itemAdded(_ item: String) -> String {
            String(format: NSLocalizedString("success.itemAdded", value: "%@ added", comment: "Item added"), item)
        }
        
        static func itemSaved(_ item: String) -> String {
            String(format: NSLocalizedString("success.itemSaved", value: "%@ saved", comment: "Item saved"), item)
        }
        
        static func itemDeleted(_ item: String) -> String {
            String(format: NSLocalizedString("success.itemDeleted", value: "%@ deleted", comment: "Item deleted"), item)
        }
    }
}

// MARK: - Error Messages Extension
extension AppStrings.ErrorMessages {
    static func failedTo(_ action: String) -> String {
        String(format: NSLocalizedString("error.failedTo", value: "Failed to %@", comment: "Failed to do something"), action)
    }
    
    static func unableTo(_ action: String) -> String {
        String(format: NSLocalizedString("error.unableTo", value: "Unable to %@", comment: "Unable to do something"), action)
    }
    
    static func errorOccurred(_ context: String) -> String {
        String(format: NSLocalizedString("error.occurred", value: "Error occurred: %@", comment: "Error occurred"), context)
    }
}
