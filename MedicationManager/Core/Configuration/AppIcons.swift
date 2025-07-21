import SwiftUI

struct AppIcons {
    // MARK: - Tab Bar Icons
    static let health = "heart.fill"
    static let groups = "person.3.fill"
    static let doctorList = "stethoscope"
    static let conflicts = "exclamationmark.triangle.fill"
    static let myHealth = "person.fill"
    static let myHealthFilled = "person.crop.circle.fill.badge.checkmark"
    static let doctorListFilled = "stethoscope.badge.top.right"
    static let groupsFilled = "person.3.fill.badge.top.right"
    static let conflictsFilled = "exclamationmark.triangle.fill.badge.top.right"
    static let settings = "gearshape"
    static let plus = "plus"
    static let conflictLow = "info.circle.fill"
    static let conflictMedium = "exclamationmark.triangle.fill"
    static let conflictHigh = "exclamationmark.triangle.fill"
    static let conflictCritical = "exclamationmark.octagon.fill"
    
    // MARK: - Conflict Sources
    struct Conflicts {
        struct Source {
            static let manual = "hand.raised.fill"
            static let realtime = "bolt.fill"
        }
    }
    
    // MARK: - Action Icons
    static let add = "plus.circle.fill"
    static let edit = "pencil.circle.fill"
    static let delete = "trash.circle.fill"
    static let voice = "mic.circle.fill"
    static let microphone = "mic.fill"
    static let search = "magnifyingglass"
    static let filter = "line.3.horizontal.decrease.circle"
    static let googleSignIn = "person.circle.fill"
    static let phone = "phone.fill"
    static let email = "envelope.fill"
    static let notifications = "bell.fill"
    static let close = "xmark"
    
    // MARK: - Status Icons
    static let success = "checkmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let error = "xmark.circle.fill"
    static let info = "info.circle.fill"
    
    // MARK: - Medication Icons
    static let medication = "pills.fill"
    static let supplement = "leaf.fill"
    static let diet = "fork.knife"
    static let schedule = "clock.fill"
    static let doctors = "person.3"
    static let time = "clock"
    
    // MARK: - Medication Struct
    struct Medication {
        static let inactive = "pills"
        static let schedule = "clock.fill"
    }
    
    // MARK: - Empty State Icons
    static let medicationEmpty = "pills"
    static let doctorEmpty = "stethoscope"
    static let groupEmpty = "person.3"
    
    // MARK: - Additional Icons
    static let networkError = "wifi.slash"
    static let sync = "arrow.triangle.2.circlepath"
    static let syncError = "arrow.triangle.2.circlepath"
    static let offline = "cloud.slash"
    static let permission = "lock.circle"
    static let permissions = "lock.circle.fill"
    static let maintenance = "gear"
    static let retry = "arrow.clockwise"
    static let openSettings = "gear"
    static let contactImported = "person.3.fill"
    static let specialties = "book.fill"
    static let contacts = "person.3.fill"
    static let invitations = "envelope.fill"
    static let contact = "person.fill"
    static let share = "square.and.arrow.up"
    static let caregivers = "person.3.fill"
    static let invitation = "envelope.badge.fill"
    static let remove = "minus.circle.fill"
    static let security = "shield.fill"
    static let privacy = "lock.shield.fill"
    static let medications = "pills.fill"
    static let supplements = "leaf.fill"
    static let diets = "fork.knife"
    static let scheduleEmpty = "calendar"
    static let voiceInput = "mic.circle.fill"
    static let critical = "exclamationmark.triangle.fill"
    static let ai = "brain.head.profile"
    static let realtime = "arrow.clockwise.circlepath"
    static let medical = "cross.circle.fill"
    static let recommendations = "arrow.clockwise.circlepath"
    static let onboarding = "person.badge.plus"
    static let onboardingCompleted = "checkmark.circle.fill"
    static let caregiverOnboarding = "person.2.badge.plus"
    static let lunch = "egg.and.cheese"
    static let breakfast = "egg.and.cheese"
    static let dinner = "egg.and.cheese"
    static let snack = "egg.and.cheese"
    static let food = "fork.knife"
    
    // MARK: - Voice Icons
    static let voiceRecording = "mic.circle.fill"
    static let clear = "xmark.circle.fill"
    static let send = "arrow.up.circle.fill"
    static let siri = "mic.badge.plus"
    
    // MARK: - Additional Icons
    static let claudeSonnet = "sparkles"
    static let cached = "clock.arrow.circlepath"
    static let chevronRight = "chevron.right"
    static let chevronUp = "chevron.up"
    static let chevronDown = "chevron.down"
    static let frequency = "arrow.triangle.2.circlepath"
    static let pause = "pause.circle.fill"
    static let play = "play.circle.fill"
    
    // MARK: - Compile-Time Constants for AppShortcuts
    // These are required for AppShortcuts systemImageName parameter
    static let conflictsLiteral = "exclamationmark.triangle.fill"
    static let plusLiteral = "plus.circle.fill"
    static let successLiteral = "checkmark.circle.fill"
    static let voiceInputLiteral = "mic.circle.fill"
    static let medicationsLiteral = "pills.fill"
    static let calendar = "calendar"
    
    // MARK: - Additional Icons for Export/Share
    static let document = "doc.fill"
    static let text = "doc.text.fill"
    static let download = "arrow.down.circle.fill"
    static let more = "ellipsis.circle.fill"
    static let history = "clock.arrow.circlepath"
    static let checkmark = "checkmark"
    static let trash = "trash"
}
