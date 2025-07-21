import Foundation

struct AppStrings {
    // MARK: - UI Components
    struct UI {
        static let severityBadges = NSLocalizedString("ui.severityBadges", value: "Severity Badges", comment: "Severity badges label")
        static let severityIndicators = NSLocalizedString("ui.severityIndicators", value: "Severity Indicators", comment: "Severity indicators label")
        static let severityProgressBars = NSLocalizedString("ui.severityProgressBars", value: "Severity Progress Bars", comment: "Severity progress bars label")
        static let conflictCountBadges = NSLocalizedString("ui.conflictCountBadges", value: "Conflict Count Badges", comment: "Conflict count badges label")
        static let alertBanners = NSLocalizedString("ui.alertBanners", value: "Alert Banners", comment: "Alert banners label")
        static let mfaRequired = NSLocalizedString("ui.mfaRequired", value: "MFA Required", comment: "MFA required label")
        static let voiceSignInPrompt = NSLocalizedString("ui.voiceSignInPrompt", value: "Voice input will be available after signing in to help you quickly add medications, supplements, and diet entries.", comment: "Voice sign in prompt")
        static let groupSettings = NSLocalizedString("ui.groupSettings", value: "Group Settings", comment: "Group settings label")
    }
    
    // MARK: - Settings
    struct Settings {
        static let title = NSLocalizedString("settings.title", value: "Settings", comment: "Settings title")
        static let caregiverSettings = NSLocalizedString("settings.caregiverSettings", value: "Caregiver Settings", comment: "Caregiver settings")
        static let userProfile = NSLocalizedString("settings.userProfile", value: "User Profile", comment: "User profile")
        static let appSettings = NSLocalizedString("settings.appSettings", value: "App Settings", comment: "App settings")
        static let privacySettings = NSLocalizedString("settings.privacySettings", value: "Privacy Settings", comment: "Privacy settings")
        static let notificationSettings = NSLocalizedString("settings.notificationSettings", value: "Notification Settings", comment: "Notification settings")
        static let syncSettings = NSLocalizedString("settings.syncSettings", value: "Sync Settings", comment: "Sync settings")
        static let aboutApp = NSLocalizedString("settings.aboutApp", value: "About App", comment: "About app")
        static let inviteCaregiver = NSLocalizedString("settings.inviteCaregiver", value: "Invite Caregiver", comment: "Invite caregiver")
        static let editUserProfile = NSLocalizedString("settings.editUserProfile", value: "Edit User Profile", comment: "Edit user profile")
        static let privacy = NSLocalizedString("settings.privacy", value: "Privacy", comment: "Privacy settings")
        static let privacySubtitle = NSLocalizedString("settings.privacySubtitle", value: "Manage your privacy preferences", comment: "Privacy settings subtitle")
        static let notificationsSubtitle = NSLocalizedString("settings.notificationsSubtitle", value: "Manage notification preferences", comment: "Notifications settings subtitle")
        static let notifications = NSLocalizedString("settings.notifications", value: "Notifications", comment: "Notifications settings")
    }
    
    // MARK: - Actions
    struct Actions {
        static let addMedication = NSLocalizedString("actions.addMedication", value: "Add Medication", comment: "Add medication")
        static let addSupplement = NSLocalizedString("actions.addSupplement", value: "Add Supplement", comment: "Add supplement")
        static let addDietEntry = NSLocalizedString("actions.addDietEntry", value: "Add Diet Entry", comment: "Add diet entry")
        static let addDoctor = NSLocalizedString("actions.addDoctor", value: "Add Doctor", comment: "Add doctor")
        static let conflictCheck = NSLocalizedString("actions.conflictCheck", value: "Conflict Check", comment: "Conflict check")
        static let onboarding = NSLocalizedString("actions.onboarding", value: "Onboarding", comment: "Onboarding")
        static let caregiverOnboarding = NSLocalizedString("actions.caregiverOnboarding", value: "Caregiver Onboarding", comment: "Caregiver onboarding")
        static let editMedication = NSLocalizedString("actions.editMedication", value: "Edit Medication", comment: "Edit medication")
        static let editSupplement = NSLocalizedString("actions.editSupplement", value: "Edit Supplement", comment: "Edit supplement")
        static let editDietEntry = NSLocalizedString("actions.editDietEntry", value: "Edit Diet Entry", comment: "Edit diet entry")
        static let editDoctor = NSLocalizedString("actions.editDoctor", value: "Edit Doctor", comment: "Edit doctor")
        static let save = NSLocalizedString("actions.save", value: "Save", comment: "Save action")
        static let add = NSLocalizedString("actions.add", value: "Add", comment: "Add action")
        static let delete = NSLocalizedString("actions.delete", value: "Delete", comment: "Delete action")
        static let checkConflicts = NSLocalizedString("actions.checkConflicts", value: "Check for Conflicts", comment: "Check conflicts button")
        static let getStarted = NSLocalizedString("actions.getStarted", value: "Get Started", comment: "Get started button")
    }
    
    // MARK: - Tab Titles
    struct TabTitles {
        static let myHealth = NSLocalizedString("tab.myHealth", value: "MyHealth", comment: "MyHealth tab title")
        static let groups = NSLocalizedString("tab.groups", value: "Groups", comment: "Groups tab title")
        static let doctorList = NSLocalizedString("tab.doctorList", value: "Doctors", comment: "Doctor list tab title")
        static let conflicts = NSLocalizedString("tab.conflicts", value: "Conflicts", comment: "Conflicts tab title")
    }
    
    // MARK: - App
    struct App {
        static let name = NSLocalizedString("app.name", value: "MyGuide", comment: "App name")
    }
    
    // MARK: - Authentication
    struct Authentication {
        static let signIn = NSLocalizedString("auth.signIn", value: "Sign In", comment: "Sign in button")
        static let signUp = NSLocalizedString("auth.signUp", value: "Sign Up", comment: "Sign up button")
        static let signOut = NSLocalizedString("auth.signOut", value: "Sign Out", comment: "Sign out button")
        static let welcomeMessage = NSLocalizedString("auth.welcome", value: "Welcome to MyGuide", comment: "Welcome message")
        static let welcomeSubtitle = NSLocalizedString("auth.welcomeSubtitle", value: "Your personal medication manager with AI-powered conflict detection", comment: "Welcome subtitle")
        static let signInWithGoogle = NSLocalizedString("auth.signInWithGoogle", value: "Sign in with Google", comment: "Sign in with Google button")
        static let signInWithPhone = NSLocalizedString("auth.signInWithPhone", value: "Sign in with Phone", comment: "Sign in with phone button")
        static let phoneNumber = NSLocalizedString("auth.phoneNumber", value: "Phone Number", comment: "Phone number field label")
        static let verificationCode = NSLocalizedString("auth.verificationCode", value: "Verification Code", comment: "Verification code field label")
        static let sendCode = NSLocalizedString("auth.sendCode", value: "Send Code", comment: "Send verification code button")
        static let verifyCode = NSLocalizedString("auth.verifyCode", value: "Verify Code", comment: "Verify code button")
        static let resendCode = NSLocalizedString("auth.resendCode", value: "Resend Code", comment: "Resend verification code button")
        static let phoneVerificationTitle = NSLocalizedString("auth.phoneVerificationTitle", value: "Phone Verification", comment: "Phone verification title")
        static let phoneVerificationSubtitle = NSLocalizedString("auth.phoneVerificationSubtitle", value: "We'll send you a verification code to confirm your phone number", comment: "Phone verification subtitle")
        static let verificationCodeHint = NSLocalizedString("auth.verificationCodeHint", value: "Enter the 6-digit code sent to your phone", comment: "Verification code hint")
        static let signingIn = NSLocalizedString("auth.signingIn", value: "Signing in...", comment: "Signing in loading message")
        static let welcomeTitle = NSLocalizedString("auth.welcomeTitle", value: "Welcome to MyGuide", comment: "Welcome title")
        
        // MFA Strings
        static let mfaRequired = NSLocalizedString("auth.mfaRequired", value: "Multi-Factor Authentication Required", comment: "MFA required title")
        static let mfaSetupTitle = NSLocalizedString("auth.mfaSetupTitle", value: "Set Up Two-Factor Authentication", comment: "MFA setup title")
        static let mfaSetupSubtitle = NSLocalizedString("auth.mfaSetupSubtitle", value: "Protect your medical data with an extra layer of security", comment: "MFA setup subtitle")
        static let mfaSecurityMessage = NSLocalizedString("auth.mfaSecurityMessage", value: "Your medication information is sensitive and requires additional protection", comment: "MFA security importance message")
        static let mfaEnrollButton = NSLocalizedString("auth.mfaEnrollButton", value: "Set Up Authenticator", comment: "MFA enrollment button")
        static let mfaVerificationTitle = NSLocalizedString("auth.mfaVerificationTitle", value: "Enter Authentication Code", comment: "MFA verification title")
        static let mfaVerificationSubtitle = NSLocalizedString("auth.mfaVerificationSubtitle", value: "Open your authenticator app and enter the 6-digit code", comment: "MFA verification subtitle")
        static let mfaCodePlaceholder = NSLocalizedString("auth.mfaCodePlaceholder", value: "123456", comment: "MFA code placeholder")
        static let mfaBackupCodesTitle = NSLocalizedString("auth.mfaBackupCodesTitle", value: "Backup Recovery Codes", comment: "MFA backup codes title")
        static let mfaBackupCodesSubtitle = NSLocalizedString("auth.mfaBackupCodesSubtitle", value: "Save these codes in a secure location. You can use them to access your account if you lose your authenticator.", comment: "MFA backup codes subtitle")
        static let mfaSaveCodesButton = NSLocalizedString("auth.mfaSaveCodesButton", value: "I've Saved These Codes", comment: "MFA save codes button")
        static let mfaScanQRTitle = NSLocalizedString("auth.mfaScanQRTitle", value: "Scan QR Code", comment: "MFA QR code scanning title")
        static let mfaScanQRSubtitle = NSLocalizedString("auth.mfaScanQRSubtitle", value: "Use your authenticator app to scan this QR code", comment: "MFA QR code scanning subtitle")
        static let mfaEnterCodeTitle = NSLocalizedString("auth.mfaEnterCodeTitle", value: "Enter Verification Code", comment: "MFA code entry title")
        static let mfaCompleteSetup = NSLocalizedString("auth.mfaCompleteSetup", value: "Complete Setup", comment: "MFA complete setup button")
        static let mfaVerifyButton = NSLocalizedString("auth.mfaVerifyButton", value: "Verify", comment: "MFA verify button")
    }
    
    // MARK: - Common
    struct Common {
        static let ok = NSLocalizedString("common.ok", value: "OK", comment: "OK button")
        static let pending = NSLocalizedString("common.pending", value: "Pending", comment: "Pending state")
        static let dotSeparator = NSLocalizedString("common.dotSeparator", value: ". ", comment: "Dot separator")
        static let unknown = NSLocalizedString("common.unknown", value: "Unknown", comment: "Unknown value")
        static let addressSeparator = NSLocalizedString("common.addressSeparator", value: ", ", comment: "Address separator")
        static let settings = NSLocalizedString("common.settings", value: "Settings", comment: "Settings button")
        static let getStarted = NSLocalizedString("common.getStarted", value: "Get Started", comment: "Get Started button")
        static let `continue` = NSLocalizedString("common.continue", value: "Continue", comment: "Continue button")
        static let cancel = NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel button")
        static let call = NSLocalizedString("common.call", value: "Call", comment: "Call button")
        static let loading = NSLocalizedString("common.loading", value: "Loading...", comment: "Loading message")
        static let status = NSLocalizedString("common.status", value: "Status", comment: "Status label")
        static let confirm = NSLocalizedString("common.confirm", value: "Confirm", comment: "Confirm button")
        static let retry = NSLocalizedString("common.retry", value: "Retry", comment: "Retry button")
        static let openSettings = NSLocalizedString("common.openSettings", value: "Open Settings", comment: "Open settings button")
        static let edit = NSLocalizedString("common.edit", value: "Edit", comment: "Edit button")
        static let share = NSLocalizedString("common.share", value: "Share", comment: "Share button")
        static let viewAll = NSLocalizedString("common.viewAll", value: "View All", comment: "View all button")
        static let deleteDietEntry = NSLocalizedString("common.deleteDietEntry", value: "Delete Diet Entry", comment: "Delete diet entry button")
        static let noMedicationsForMeal = NSLocalizedString("common.noMedicationsForMeal", value: "No medications for this meal", comment: "No medications for meal")
        static let dietEntryNotFoundDescription = NSLocalizedString("common.dietEntryNotFoundDescription", value: "The diet entry you are looking for could not be found.", comment: "Diet entry not found description")
        static let dietEntryNotFound = NSLocalizedString("common.dietEntryNotFound", value: "Diet Entry Not Found", comment: "Diet entry not found title")
        static func viewAllCount(_ count: Int) -> String {
            return NSLocalizedString("common.viewAllCount", value: "View All (\(count) more)", comment: "View all with count")
        }
        static let done = NSLocalizedString("common.done", value: "Done", comment: "Done button")
        static let resend = NSLocalizedString("common.resend", value: "Resend", comment: "Resend button")
        static let analyze = NSLocalizedString("common.analyze", value: "Analyze", comment: "Analyze button")
        static let all = NSLocalizedString("common.all", value: "All", comment: "All button")
        static let filter = NSLocalizedString("common.filter", value: "Filter", comment: "Filter button")
        static let specialtyPrimaryCare = NSLocalizedString("common.specialtyPrimaryCare", value: "Specialty Primary Care", comment: "Specialty Primary Care button")
        static let deleteConfirmationTitle = NSLocalizedString("common.deleteConfirmationTitle", value: "Delete Confirmation", comment: "Delete Confirmation title")
        static let deleteSupplementConfirmation = NSLocalizedString("common.deleteSupplementConfirmation", value: "Are you sure you want to delete this supplement?", comment: "Delete Supplement Confirmation message")
        static let supplementNotFound = NSLocalizedString("common.supplementNotFound", value: "Supplement not found", comment: "Supplement not found message")
        static let supplementNotFoundDescription = NSLocalizedString("common.supplementNotFoundDescription", value: "This supplement is no longer available.", comment: "Supplement not found description")
        static let frequency = NSLocalizedString("common.frequency", value: "Frequency", comment: "Frequency label")
        static let clear = NSLocalizedString("common.clear", value: "Clear", comment: "Clear button")
        static let submit = NSLocalizedString("common.submit", value: "Submit", comment: "Submit button")
        static let empty = ""
        static let added = NSLocalizedString("common.added", value: "Added", comment: "Added label")
        static let tapToViewDetails = NSLocalizedString("common.tapToViewDetails", value: "Tap to view details", comment: "Tap to view details")
        static let viewDetails = NSLocalizedString("common.viewDetails", value: "View Details", comment: "View details button")
        static let yes = NSLocalizedString("common.yes", value: "Yes", comment: "Yes")
        static let export = NSLocalizedString("common.export", value: "Export", comment: "Export button")
        static let exporting = NSLocalizedString("common.exporting", value: "Exporting...", comment: "Exporting in progress")
        static let exportPDF = NSLocalizedString("common.exportPDF", value: "Export as PDF", comment: "Export PDF option")
        static let exportText = NSLocalizedString("common.exportText", value: "Export as Text", comment: "Export text option")
        static let sendToDoctor = NSLocalizedString("common.sendToDoctor", value: "Send to Doctor", comment: "Send to doctor option")
        static let exportOptions = NSLocalizedString("common.exportOptions", value: "Export Options", comment: "Export options header")
        static let hasEndDate = NSLocalizedString("common.hasEndDate", value: "Has End Date", comment: "Has end date toggle")
        static let endDate = NSLocalizedString("common.endDate", value: "End Date", comment: "End date label")
        static let taskCompletedBody = NSLocalizedString("common.taskCompletedBody", value: "You have completed this task.", comment: "Task completed body")
        static let dosageHint = NSLocalizedString("common.dosageHint", value: "e.g., 500mg, 1 tablet", comment: "Dosage field hint")
        static let nutritionInfo = NSLocalizedString("common.nutritionInfo", value: "Nutrition Information", comment: "Nutrition information label")
        static let allergens = NSLocalizedString("common.allergens", value: "Allergens", comment: "Allergens label")
        static let medicationTiming = NSLocalizedString("common.medicationTiming", value: "Medication Timing", comment: "Medication timing label")
        static let withFood = NSLocalizedString("common.withFood", value: "Take with Food", comment: "Take with food label")
        static let confirmDelete = NSLocalizedString("common.confirmDelete", value: "Confirm Delete", comment: "Confirm delete title")
        static let confirmDeleteMessage = NSLocalizedString("common.confirmDeleteMessage", value: "Are you sure you want to delete this? This action cannot be undone.", comment: "Confirm delete message")
        static let dietEntry = NSLocalizedString("common.dietEntry", value: "Diet Entry", comment: "Diet entry label")
        static let deleteDietEntryConfirmation = NSLocalizedString("common.deleteDietEntryConfirmation", value: "Are you sure you want to delete this diet entry? This action cannot be undone.", comment: "Delete diet entry confirmation message")
        static let calories = NSLocalizedString("common.calories", value: "Calories", comment: "Calories label")
        static let name = NSLocalizedString("common.name", value: "Name", comment: "Name label")
        static let startDate = NSLocalizedString("common.startDate", value: "Start Date", comment: "Start date label")
        static let additionalInfo = NSLocalizedString("common.additionalInfo", value: "Additional Information", comment: "Additional info section")
        static let active = NSLocalizedString("common.active", value: "Active", comment: "Active status label")
        static let inactive = NSLocalizedString("common.inactive", value: "Inactive", comment: "Inactive status label")
        static let prescribedBy = NSLocalizedString("common.prescribedBy", value: "Prescribed By", comment: "Prescribed by label")
        
        // Missing date-related strings
        static let dateRange = NSLocalizedString("common.dateRange", value: "Date Range", comment: "Date range label")
        static let lastWeek = NSLocalizedString("common.lastWeek", value: "Last Week", comment: "Last week option")
        static let lastMonth = NSLocalizedString("common.lastMonth", value: "Last Month", comment: "Last month option")
    }
    
    // MARK: - Legal
    struct Legal {
        static let medicalDisclaimer = NSLocalizedString("legal.medicalDisclaimer", value: "This app is for educational purposes only and is not intended to replace professional medical advice.", comment: "Medical disclaimer")
        static let privacyPolicy = NSLocalizedString("legal.privacyPolicy", value: "Privacy Policy", comment: "Privacy policy link")
        static let termsOfService = NSLocalizedString("legal.termsOfService", value: "Terms of Service", comment: "Terms of service link")
    }
    
    // MARK: - Medications
    struct Medications {
        static let title = NSLocalizedString("medications.title", value: "Medications", comment: "Medications section title")
        static let medications = NSLocalizedString("medications.medications", value: "Medications", comment: "Medications title")
        static let addMedication = NSLocalizedString("medications.add", value: "Add Medication", comment: "Add medication button")
        static let addSupplement = NSLocalizedString("medications.addSupplement", value: "Add Supplement", comment: "Add supplement button")
        static let dosage = NSLocalizedString("medications.dosage", value: "Dosage", comment: "Dosage label")
        static let frequency = NSLocalizedString("medications.frequency", value: "Frequency", comment: "Frequency label")
        static let schedule = NSLocalizedString("medications.schedule", value: "Schedule", comment: "Schedule label")
        static let notes = NSLocalizedString("medications.notes", value: "Notes", comment: "Notes label")
        static let noMedications = NSLocalizedString("medications.noMedications", value: "No Medications", comment: "No medications empty state title")
        static let noMedicationsMessage = NSLocalizedString("medications.noMedicationsMessage", value: "You haven't added any medications yet", comment: "No medications empty state message")
        static let addFirst = NSLocalizedString("medications.addFirst", value: "Add First Medication", comment: "Add first medication button")
        static let addFirstMedication = NSLocalizedString("medications.addFirstMedication", value: "Add First Medication", comment: "Add first medication button")
        static let markTaken = NSLocalizedString("medications.markTaken", value: "Mark Taken", comment: "Mark medication as taken button")
        static let confirmTake = NSLocalizedString("medications.confirmTake", value: "Confirm Medication", comment: "Confirm take medication alert title")
        static func confirmTakeMessage(_ medicationName: String) -> String {
            return NSLocalizedString("medications.confirmTakeMessage", value: "Mark \(medicationName) as taken?", comment: "Confirm take medication message")
        }
        static func medicationCount(_ count: Int) -> String {
            return NSLocalizedString("medications.medicationCount", value: "\(count) medication\(count == 1 ? "" : "s")", comment: "Medication count")
        }
        
        // Schedule status strings - NEWLY ADDED
        static let noScheduleSet = NSLocalizedString("medications.noScheduleSet", value: "No schedule set", comment: "No medication schedule message")
        static let noActiveTimes = NSLocalizedString("medications.noActiveTimes", value: "No active times", comment: "No active schedule times message")
        static func nextAt(_ time: String) -> String {
            return NSLocalizedString("medications.nextAt", value: "Next at \(time)", comment: "Next medication time message")
        }
        static func multipleTimesPerDay(_ count: Int) -> String {
            return NSLocalizedString("medications.multipleTimesPerDay", value: "\(count) times per day", comment: "Multiple medication times per day")
        }
        static func nextDose(_ time: String) -> String {
            return NSLocalizedString("medications.nextDose", value: "Next: \(time)", comment: "Next dose time message")
        }
        static let defaultDosage = NSLocalizedString("medications.defaultDosage", value: "As directed", comment: "Default dosage when not specified")
        static let editMedication = NSLocalizedString("medications.editMedication", value: "Edit Medication", comment: "Edit medication button")
        static let reminders = NSLocalizedString("medications.reminders", value: "Reminders", comment: "Reminders label")
    }
    
    // MARK: - Supplements
    struct Supplements {
        static let title = NSLocalizedString("supplements.title", value: "Supplements", comment: "Supplements section title")
        static let supplements = NSLocalizedString("supplements.supplements", value: "Supplements", comment: "Supplements title")
        static let addSupplement = NSLocalizedString("supplements.addSupplement", value: "Add Supplement", comment: "Add supplement button")
        static let noSupplements = NSLocalizedString("supplements.noSupplements", value: "No Supplements", comment: "No supplements empty state title")
        static let noSupplementsMessage = NSLocalizedString("supplements.noSupplementsMessage", value: "You haven't added any supplements yet", comment: "No supplements empty state message")
        static let addFirst = NSLocalizedString("supplements.addFirst", value: "Add First Supplement", comment: "Add first supplement button")
        static let addFirstSupplement = NSLocalizedString("supplements.addFirstSupplement", value: "Add First Supplement", comment: "Add first supplement button")
        static let name = NSLocalizedString("supplements.name", value: "Supplement Name", comment: "Supplement name label")
        static let safety = NSLocalizedString("supplements.safety", value: "Safety Check", comment: "Safety check section title")
        static func supplementCount(_ count: Int) -> String {
            return NSLocalizedString("supplements.supplementCount", value: "\(count) supplement\(count == 1 ? "" : "s")", comment: "Supplement count")
        
        }
        static let supplementIdentifier = "supplement"
    }
    
    // MARK: - Diet
    struct Diet {
        static let title = NSLocalizedString("diet.title", value: "Diet", comment: "Diet section title")
        static let todaysNutrition = NSLocalizedString("diet.todaysNutrition", value: "Today's Nutrition", comment: "Today's nutrition title")
        static let addDietEntry = NSLocalizedString("diet.addDietEntry", value: "Add Diet Entry", comment: "Add diet entry button")
        static let breakfast = NSLocalizedString("diet.breakfast", value: "Breakfast", comment: "Breakfast label")
        static let lunch = NSLocalizedString("diet.lunch", value: "Lunch", comment: "Lunch label")
        static let dinner = NSLocalizedString("diet.dinner", value: "Dinner", comment: "Dinner label")
        static let snack = NSLocalizedString("diet.snack", value: "Snack", comment: "Snack label")
        static let totalCalories = NSLocalizedString("diet.totalCalories", value: "Total Calories", comment: "Total calories label")
        static let mealsLogged = NSLocalizedString("diet.mealsLogged", value: "Meals Logged", comment: "Meals logged label")
        static let noEntries = NSLocalizedString("diet.noEntries", value: "No Diet Entries", comment: "No diet entries empty state title")
        static let noEntriesMessage = NSLocalizedString("diet.noEntriesMessage", value: "You haven't logged any meals yet", comment: "No diet entries empty state message")
        static let addFirst = NSLocalizedString("diet.addFirst", value: "Log First Meal", comment: "Add first diet entry button")
        static func mealCount(_ count: Int) -> String {
            return NSLocalizedString("diet.mealCount", value: "\(count) meal\(count == 1 ? "" : "s")", comment: "Meal count")
        }
    }
    
    // MARK: - Doctors
    struct Doctors {
        static let title = NSLocalizedString("doctors.title", value: "Doctors", comment: "Doctors section title")
        static let noDoctors = NSLocalizedString("doctors.noDoctors", value: "No Doctors", comment: "No doctors empty state title")
        static let noDoctorsMessage = NSLocalizedString("doctors.noDoctorsMessage", value: "You haven't added any doctors yet", comment: "No doctors empty state message")
        static let addFirst = NSLocalizedString("doctors.addFirst", value: "Add First Doctor", comment: "Add first doctor button")
        static let loadingDoctors = NSLocalizedString("doctors.loadingDoctors", value: "Loading Doctors...", comment: "Loading doctors label")
        static let searchDoctors = NSLocalizedString("doctors.searchDoctors", value: "Search Doctors...", comment: "Search doctors label")
        static let addDoctor = NSLocalizedString("doctors.addDoctor", value: "Add Doctor", comment: "Add doctor button")
        static let editDoctor = NSLocalizedString("doctors.editDoctor", value: "Edit Doctor", comment: "Edit doctor button")
        static let addManually = NSLocalizedString("doctors.addManually", value: "Add Manually", comment: "Add manually button")
        static let totalDoctors = NSLocalizedString("doctors.totalDoctors", value: "%d Doctors", comment: "Total doctors count format")
        static let doctors = NSLocalizedString("doctors.doctors", value: "Doctor(s)", comment: "Pluralized doctors count format")
        static let recentlyAdded = NSLocalizedString("doctors.recentlyAdded", value: "Recently Added", comment: "Recently added doctors section title")
        static let contactImported = NSLocalizedString("doctors.contactImported", value: "Contact Imported", comment: "Contact imported doctors section title")
        static let contactDoctor = NSLocalizedString("doctors.contactDoctor", value: "Contact Doctor", comment: "Contact doctor button")
        static let contactDoctorSubtitle = NSLocalizedString("doctors.contactDoctorSubtitle", value: "Get in touch with your care team", comment: "Contact doctor subtitle")
        static let loadingContacts = NSLocalizedString("doctors.loadingContacts", value: "Loading Contacts...", comment: "Loading contacts label")
        static let importFromContacts = NSLocalizedString("doctors.importFromContacts", value: "Import from Contacts", comment: "Import from contacts button")
        static let importedFromContacts = NSLocalizedString("doctors.importedFromContacts", value: "Imported from Contacts", comment: "Imported from contacts label")
        static let searchContacts = NSLocalizedString("doctors.searchContacts", value: "Search Contacts...", comment: "Search contacts label")
        static let selectSpecialty = NSLocalizedString("doctors.selectSpecialty", value: "Select Specialty", comment: "Select specialty placeholder")
        static let specialties = NSLocalizedString("doctors.specialties", value: "Specialties", comment: "Specialties placeholder")
        static let noContacts = NSLocalizedString("doctors.noContacts", value: "No Contacts", comment: "No contacts empty state title")
        static let noContactsMessage = NSLocalizedString("doctors.noContactsMessage", value: "No contacts imported yet", comment: "No contacts empty state message")
        static let withContact = NSLocalizedString("doctors.withContact", value: "With Contact", comment: "With contact button")
        static let noSpecialty = NSLocalizedString("doctors.noSpecialty", value: "No Specialty", comment: "No specialty placeholder")
        static let emergencyContact = NSLocalizedString("doctors.emergencyContact", value: "Emergency Contact", comment: "Emergency contact label")
        static let markEmergency = NSLocalizedString("doctors.markEmergency", value: "Mark as Emergency", comment: "Mark as emergency button")
        static let removeEmergency = NSLocalizedString("doctors.removeEmergency", value: "Remove from Emergency", comment: "Remove from emergency button")
        static let emergencyDoctors = NSLocalizedString("doctors.emergencyDoctors", value: "Emergency Doctors", comment: "Emergency doctors section")
        static let nameRequired = NSLocalizedString("doctors.nameRequired", value: "Name is required", comment: "Name required validation")
        static let contactRequired = NSLocalizedString("doctors.contactRequired", value: "Email or phone number is required", comment: "Contact required validation")
        static let invalidEmail = NSLocalizedString("doctors.invalidEmail", value: "Invalid email format", comment: "Invalid email validation")
        static let contactInfo = NSLocalizedString("doctors.contactInfo", value: "Contact Information", comment: "Contact information section title")
        static let address = NSLocalizedString("doctors.address", value: "Address", comment: "Address section title")
        static let notes = NSLocalizedString("doctors.notes", value: "Notes", comment: "Notes section title")
        static let prescribedMedications = NSLocalizedString("doctors.prescribedMedications", value: "Prescribed Medications", comment: "Prescribed medications section title")
        static let noContactInfo = NSLocalizedString("doctors.noContactInfo", value: "No contact information available", comment: "No contact info message")
        static let noPrescribedMedications = NSLocalizedString("doctors.noPrescribedMedications", value: "No medications prescribed by this doctor", comment: "No prescribed medications message")
        static let notFound = NSLocalizedString("doctors.notFound", value: "Doctor Not Found", comment: "Doctor not found title")
        static let notFoundDescription = NSLocalizedString("doctors.notFoundDescription", value: "The doctor information could not be found", comment: "Doctor not found description")
        static let deleteConfirmation = NSLocalizedString("doctors.deleteConfirmation", value: "Are you sure you want to delete this doctor? This action cannot be undone.", comment: "Delete doctor confirmation message")
        static let invalidPhone = NSLocalizedString("doctors.invalidPhone", value: "Invalid phone number format", comment: "Invalid phone validation")
        static let exportToContacts = NSLocalizedString("doctors.exportToContacts", value: "Export to Contacts", comment: "Export to contacts button")
        static let shareDoctor = NSLocalizedString("doctors.shareDoctor", value: "Share Doctor", comment: "Share doctor button")
        static let specialty = NSLocalizedString("doctors.specialty", value: "Specialty", comment: "Specialty field label")
        static let phone = NSLocalizedString("doctors.phone", value: "Phone", comment: "Phone field label")
        static let email = NSLocalizedString("doctors.email", value: "Email", comment: "Email field label")
        static let drPrefix = NSLocalizedString("doctors.drPrefix", value: "Dr.", comment: "Doctor prefix")
        static let drPrefixShort = NSLocalizedString("doctors.drPrefixShort", value: "Dr", comment: "Doctor prefix short")
        static let phoneFormat = NSLocalizedString("doctors.phoneFormat", value: "({area}) {exchange}-{number}", comment: "Phone format")
        static let emailPlaceholder = NSLocalizedString("doctors.emailPlaceholder", value: "doctor@example.com", comment: "Email placeholder")
        static let specialtyPrimaryCare = "Primary Care"
        static let specialtyCardiology = "Cardiology"
        static let specialtyEndocrinology = "Endocrinology"
        static let specialtyNeurology = "Neurology"
        static let specialtyPsychiatry = "Psychiatry"
        static let specialtyDermatology = "Dermatology"
        static let specialtyOrthopedics = "Orthopedics"
        static let specialtyOphthalmology = "Ophthalmology"
        static let specialtyGastroenterology = "Gastroenterology"
        static let specialtyPulmonology = "Pulmonology"
        static let specialtyNephrology = "Nephrology"
        static let specialtyRheumatology = "Rheumatology"
        static let specialtyOncology = "Oncology"
        static let specialtyUrology = "Urology"
        static let specialtyGynecology = "Gynecology"
        static let specialtyPediatrics = "Pediatrics"
        static let specialtyEmergency = "Emergency Medicine"
        static let specialtyAnesthesiology = "Anesthesiology"
        static let specialtyRadiology = "Radiology"
        static let specialtyPathology = "Pathology"
        static let specialtyOther = "Other"
        // Sample data (3 doctors x 6 fields each = 18 constants)
        static let sampleName1 = "Dr. Sarah Johnson"
        static let samplePhone1 = "(555) 123-4567"
        static let sampleEmail1 = "dr.johnson@medicalpractice.com"
        static let sampleStreet1 = "123 Medical Center Dr"
        static let sampleCity1 = "San Francisco"
        static let sampleState1 = "CA"
        static let sampleZip1 = "94103"
        static let sampleNotes1 = "Excellent bedside manner. Accepts most insurance plans."

        static let sampleName2 = "Dr. Michael Chen"
        static let samplePhone2 = "(555) 987-6543"
        static let sampleEmail2 = "m.chen@heartcenter.com"
        static let sampleStreet2 = "456 Heart Health Blvd"
        static let sampleCity2 = "San Francisco"
        static let sampleState2 = "CA"
        static let sampleZip2 = "94110"
        static let sampleNotes2 = "Specializes in preventive cardiology."

        static let sampleName3 = "Dr. Emily Rodriguez"
        static let samplePhone3 = "(555) 456-7890"
        static let sampleEmail3 = "e.rodriguez@diabetescenter.org"
        static let sampleStreet3 = "789 Diabetes Care Way"
        static let sampleCity3 = "Oakland"
        static let sampleState3 = "CA"
        static let sampleZip3 = "94601"
        static let sampleNotes3 = "Diabetes specialist. Very knowledgeable."
        static let sampleContactId = "ABC123"
    }
    
    // MARK: - Conflicts
    struct Conflicts {
        static let title = NSLocalizedString("conflicts.title", value: "Conflicts", comment: "Conflicts section title")
        static let noConflicts = NSLocalizedString("conflicts.noConflicts", value: "No Conflicts", comment: "No conflicts empty state title")
        static let noConflictsMessage = NSLocalizedString("conflicts.noConflictsMessage", value: "No medication conflicts detected", comment: "No conflicts empty state message")
        static let checkNow = NSLocalizedString("conflicts.checkNow", value: "Check for Conflicts", comment: "Check conflicts button")
        static let clinicalSignificance = NSLocalizedString("conflicts.clinicalSignificance", value: "Clinical Significance", comment: "Clinical significance label")
        static let checkConflicts = NSLocalizedString("conflicts.checkConflicts", value: "Check Conflicts", comment: "Check conflicts action")
        static let analysisDetails = NSLocalizedString("conflicts.analysisDetails", value: "Details", comment: "Analysis details button")
        static let checkConflictsSubtitle = NSLocalizedString("conflicts.checkConflictsSubtitle", value: "AI-powered conflict detection", comment: "Check conflicts subtitle")
        static let analyzingConflicts = NSLocalizedString("conflicts.analyzingConflicts", value: "Analyzing Conflicts...", comment: "Analyzing conflicts label")
        static let detectedConflicts = NSLocalizedString("conflicts.detectedConflicts", value: "Detected Conflicts", comment: "Detected conflicts label")
        static let medications = NSLocalizedString("conflicts.medications", value: "Medications", comment: "Medications column header")
        static let supplements = NSLocalizedString("conflicts.supplements", value: "Supplements", comment: "Supplements column header")
        static let mechanism = NSLocalizedString("conflicts.mechanism", value: "Mechanism", comment: "Mechanism column header")
        static let management = NSLocalizedString("conflicts.management", value: "Management", comment: "Management column header")
        static let references = NSLocalizedString("conflicts.references", value: "References", comment: "References column header")
        
        // Voice-first prompts
        static let voicePrompt = NSLocalizedString("conflicts.voicePrompt", value: "Ask about drug interactions...", comment: "Voice prompt for conflicts")
        static let voicePromptExample = NSLocalizedString("conflicts.voicePromptExample", value: "Try saying: \"What happens if I take aspirin with warfarin?\"", comment: "Voice prompt example")
        static let listeningTitle = NSLocalizedString("conflicts.listeningTitle", value: "Listening...", comment: "Voice listening status")
        static let analyzingTitle = NSLocalizedString("conflicts.analyzingTitle", value: "Analyzing interactions...", comment: "Analyzing interactions status")
        static let processingVoice = NSLocalizedString("conflicts.processingVoice", value: "Processing your question...", comment: "Processing voice input")
        static let speakNaturally = NSLocalizedString("conflicts.speakNaturally", value: "Speak naturally about your medications", comment: "Natural speech instruction")
        static let tapForText = NSLocalizedString("conflicts.tapForText", value: "Tap anywhere to type instead", comment: "Text fallback instruction")
        static let voiceNotAvailable = NSLocalizedString("conflicts.voiceNotAvailable", value: "Voice input unavailable", comment: "Voice not available")
        static let all = NSLocalizedString("conflicts.all", value: "All", comment: "All button")
        static let critical = NSLocalizedString("conflicts.critical", value: "Critical", comment: "Critical button")
        static let high = NSLocalizedString("conflicts.high", value: "High", comment: "High button")
        static let unresolved = NSLocalizedString("conflicts.unresolved", value: "Unresolved", comment: "Unresolved button")
        static let resolved = NSLocalizedString("conflicts.resolved", value: "Resolved", comment: "Resolved button")
        static let recent = NSLocalizedString("conflicts.recent", value: "Recent", comment: "Recent button")
        static let checkConfirmation = NSLocalizedString("conflicts.checkConfirmation", value: "Are you sure you want to check for conflicts now?", comment: "Check conflicts confirmation message")
        static let checkConfirmationMessage = NSLocalizedString("conflicts.checkConfirmationMessage", value: "This will refresh your conflicts list.", comment: "Check conflicts confirmation message")
        static let allConflicts = NSLocalizedString("conflicts.allConflicts", value: "All Conflicts", comment: "All conflicts button")
        static let analyzedBy = NSLocalizedString("conflicts.analyzedBy", value: "Analyzed by", comment: "Analyzed by label")
        static let conflictAnalysis = NSLocalizedString("conflicts.conflictAnalysis", value: "Conflict Analysis", comment: "Conflict analysis section title")
        static let checkAllMedications = NSLocalizedString("conflicts.checkAllMedications", value: "Check all medications", comment: "Check all medications")
        static let analysisComplete = NSLocalizedString("conflicts.analysisComplete", value: "Analysis complete", comment: "Analysis complete")
        static let conflictsDetected = NSLocalizedString("conflicts.conflictsDetected", value: "conflicts detected", comment: "Conflicts detected")
        static let conflictsFound = NSLocalizedString("conflicts.conflictsFound", value: "Conflicts Found", comment: "Conflicts found label")
        static let educationalInfo = NSLocalizedString("conflicts.educationalInfo", value: "Educational Info", comment: "Educational info section title")
        static let medicationCount = NSLocalizedString("conflicts.medicationCount", value: "Medication Count", comment: "Medication count label")
        static let severityLevels = NSLocalizedString("conflicts.severityLevels", value: "Severity Levels", comment: "Severity levels section title")
        static let lastChecked = NSLocalizedString("conflicts.lastChecked", value: "Last Checked:", comment: "Last checked label")
        static let criticalConflicts = NSLocalizedString("conflicts.criticalConflicts", value: "Critical Conflicts", comment: "Critical conflicts section title")
        static let criticalAlertMessage = NSLocalizedString("conflicts.criticalAlertMessage", value: "We strongly recommend that you review your medication list.", comment: "Critical alert message")
        static let moderateAlertMessage = NSLocalizedString("conflicts.moderateAlertMessage", value: "We recommend that you review your medication list.", comment: "Moderate alert message")
        static let supplementCount = NSLocalizedString("conflicts.supplementCount", value: "Supplement Count", comment: "Supplement count label")
        static let aiPowered = NSLocalizedString("conflicts.aiPowered", value: "AI-Powered", comment: "AI-Powered label")
        static let aiPoweredDescription = NSLocalizedString("conflicts.aiPoweredDescription", value: "We use AI to help you identify potential medication conflicts.", comment: "AI-Powered description")
        static let realtimeChecking = NSLocalizedString("conflicts.realtimeChecking", value: "Realtime Checking", comment: "Realtime checking label")
        static let realtimeCheckingDescription = NSLocalizedString("conflicts.realtimeCheckingDescription", value: "We check for conflicts in real time as you add medications and supplements.", comment: "Realtime checking description")
        static let requiresAttention = NSLocalizedString("conflicts.requiresAttention", value: "Requires Attention", comment: "Requires attention label")
        static let noConflictsForFilter = NSLocalizedString("conflicts.noConflictsForFilter", value: "No conflicts for this filter.", comment: "No conflicts for filter empty state message")
        static let medicalGuidance = NSLocalizedString("conflicts.medicalGuidance", value: "Medical Guidance", comment: "Medical guidance section title")
        static let medicalGuidanceDescription = NSLocalizedString("conflicts.medicalGuidanceDescription", value: "Always consult your healthcare provider before starting any new medication or supplement.", comment: "Medical guidance description")
        static func lastCheckedDate(_ date: Date) -> String {  // Function - can take parameters
                return "Last checked: \(date.formatted())"
            }
        static let noAnalysisYet = NSLocalizedString("conflicts.noAnalysisYet", value: "No analysis yet.", comment: "No analysis yet empty state message")
        static let totalConflicts = NSLocalizedString("conflicts.totalConflicts", value: "Total Conflicts:", comment: "Total conflicts label")
        static let medicationsInvolved = NSLocalizedString("conflicts.medicationsInvolved", value: "Medications Involved:", comment: "Medications involved label")
        static func medicationCountValue(_ count: Int) -> String {
                return NSLocalizedString("conflicts.medicationCount",
                                        value: "\(count) medications",
                                        comment: "Medication count with number")
            }
        static func analyzedBySource(_ source: String) -> String {
                return NSLocalizedString("conflicts.analyzedBySource",
                                        value: "Analyzed by \(source)",
                                        comment: "Analysis source attribution")
            }
        static let hasRecommendations = NSLocalizedString("conflicts.hasRecommendations", value: "Has Recommendations", comment: "Has recommendations label")
        static func recommendationsCount(_ count: Int) -> String {
                return NSLocalizedString("conflicts.recommendationsCount",
                                        value: "\(count) recommendations",
                                        comment: "Number of recommendations available")
            }
        static let markResolved = NSLocalizedString("conflicts.markResolved", value: "Mark Resolved", comment: "Mark resolved button title")
        static func supplementCountValue(_ count: Int) -> String {
                return NSLocalizedString("conflicts.supplementCount",
                                        value: "\(count) supplements",
                                        comment: "Supplement count with number")
            }
        
        struct Severity {
            static let low = NSLocalizedString("conflicts.severity.low", value: "Low Risk", comment: "Low risk conflict")
            static let medium = NSLocalizedString("conflicts.severity.medium", value: "Moderate Risk", comment: "Medium risk conflict")
            static let high = NSLocalizedString("conflicts.severity.high", value: "High Risk", comment: "High risk conflict")
            static let critical = NSLocalizedString("conflicts.severity.critical", value: "Critical Risk", comment: "Critical risk conflict")
            
            static let lowDescription = NSLocalizedString("conflicts.severity.lowDesc", value: "Minor interaction that may not require action", comment: "Low risk description")
            static let mediumDescription = NSLocalizedString("conflicts.severity.mediumDesc", value: "Moderate interaction that should be monitored", comment: "Medium risk description")
            static let highDescription = NSLocalizedString("conflicts.severity.highDesc", value: "Significant interaction that may require dosage adjustment", comment: "High risk description")
            static let criticalDescription = NSLocalizedString("conflicts.severity.criticalDesc", value: "Dangerous interaction that requires immediate attention", comment: "Critical risk description")
            static let noneDescription = NSLocalizedString("conflicts.severity.noneDesc", value: "No potential interactions", comment: "No potential interactions description")
        }
        
        // AI Analysis
        struct Analysis {
            static let poweredByClaude = NSLocalizedString("conflicts.analysis.poweredByClaude", value: "Powered by Claude AI", comment: "Claude AI attribution")
            static let confidence = NSLocalizedString("conflicts.analysis.confidence", value: "Confidence", comment: "Analysis confidence label")
            static let lastUpdated = NSLocalizedString("conflicts.analysis.lastUpdated", value: "Last Updated", comment: "Last updated label")
            static let medications = NSLocalizedString("conflicts.analysis.medications", value: "Medications Analyzed", comment: "Medications analyzed label")
            static let recommendations = NSLocalizedString("conflicts.analysis.recommendations", value: "Recommendations", comment: "Recommendations section")
            static let details = NSLocalizedString("conflicts.analysis.details", value: "View Details", comment: "View details button")
            static let summary = NSLocalizedString("conflicts.analysis.summary", value: "Summary", comment: "Summary section")
            static let shareAnalysis = NSLocalizedString("conflicts.analysis.share", value: "Share Analysis", comment: "Share analysis button")
            static let saveReport = NSLocalizedString("conflicts.analysis.saveReport", value: "Save Report", comment: "Save report button")
        }
        
        // History
        struct History {
            static let title = NSLocalizedString("conflicts.history.title", value: "Analysis History", comment: "History title")
            static let searchPlaceholder = NSLocalizedString("conflicts.history.search", value: "Search past analyses...", comment: "Search placeholder")
            static let noHistory = NSLocalizedString("conflicts.history.noHistory", value: "No Previous Analyses", comment: "No history message")
            static let noHistoryMessage = NSLocalizedString("conflicts.history.noHistoryMessage", value: "Your analysis history will appear here", comment: "No history description")
            static let clearHistory = NSLocalizedString("conflicts.history.clear", value: "Clear History", comment: "Clear history button")
            static let exportHistory = NSLocalizedString("conflicts.history.export", value: "Export History", comment: "Export history button")
            static let filterBySeverity = NSLocalizedString("conflicts.history.filterBySeverity", value: "Filter by Severity", comment: "Filter by severity")
            static let sortByDate = NSLocalizedString("conflicts.history.sortByDate", value: "Sort by Date", comment: "Sort by date")
            static let totalAnalyses = NSLocalizedString("conflicts.history.totalAnalyses", value: "Total Analyses", comment: "Total analyses count label")
        }
        
        // Source
        struct Source {
            static let aiAnalysis = NSLocalizedString("conflicts.source.aiAnalysis", value: "AI Analysis", comment: "AI analysis source")
            static let manualCheck = NSLocalizedString("conflicts.source.manualCheck", value: "Manual Check", comment: "Manual check source")
            static let scheduledReview = NSLocalizedString("conflicts.source.scheduledReview", value: "Scheduled Review", comment: "Scheduled review source")
            static let realtimeCheck = NSLocalizedString("conflicts.source.realtimeCheck", value: "Real-time Check", comment: "Real-time check source")
        }
        
        // Messages
        struct Messages {
            static let noConflictsDetected = NSLocalizedString("conflicts.messages.noConflictsDetected", value: "No conflicts detected", comment: "No conflicts detected message")
            static func oneConflictDetected(_ severity: String) -> String {
                return NSLocalizedString("conflicts.messages.oneConflictDetected", value: "1 \(severity) conflict detected", comment: "One conflict detected with severity")
            }
            static func multipleConflictsDetected(_ count: Int, _ severity: String) -> String {
                return NSLocalizedString("conflicts.messages.multipleConflictsDetected", value: "\(count) conflicts detected (highest: \(severity))", comment: "Multiple conflicts detected with count and highest severity")
            }
        }
        
    }
    
    // MARK: - Caregivers
    struct Caregivers {
        static let title = NSLocalizedString("caregivers.title", value: "Caregivers", comment: "Caregivers section title")
        static let pendingInvitations = NSLocalizedString("caregivers.pendingInvitations", value: "Pending Invitations", comment: "Pending invitations section title")
        static let caregiverAccess = NSLocalizedString("caregivers.caregiverAccess", value: "Caregiver Access", comment: "Caregiver access section title")
        static let activeCaregivers = NSLocalizedString("caregivers.activeCaregivers", value: "Active Caregivers", comment: "Active caregivers section title")
        static let noCaregivers = NSLocalizedString("caregivers.noCaregivers", value: "No Caregivers", comment: "No caregivers empty state title")
        static let noCaregiversMessage = NSLocalizedString("caregivers.noCaregiversMessage", value: "You haven't invited any caregivers yet", comment: "No caregivers empty state message")
        static let inviteFirst = NSLocalizedString("caregivers.inviteFirst", value: "Invite First Caregiver", comment: "Invite first caregiver button")
        static let accessDisabled = NSLocalizedString("caregivers.accessDisabled", value: "Caregiver access disabled", comment: "Caregiver access disabled status")
        static let onboardingTitle = NSLocalizedString("caregivers.onboardingTitle", value: "Caregiver Setup", comment: "Caregiver onboarding title")
        static let onboardingMessage = NSLocalizedString("caregivers.onboardingMessage", value: "Set up caregiver access to help manage medications together", comment: "Caregiver onboarding message")
        static func activeCaregiversCount(_ count: Int) -> String {
            return NSLocalizedString("caregivers.activeCaregiversCount", value: "\(count) active caregiver\(count == 1 ? "" : "s")", comment: "Active caregivers count")
        }
        static func pendingInvitationsCount(_ count: Int) -> String {
            return NSLocalizedString("caregivers.pendingInvitationsCount", value: "\(count) pending invitation\(count == 1 ? "" : "s")", comment: "Pending invitations count")
        }
        static let availableSlots = NSLocalizedString("caregivers.availableSlots", value: "Available Slots", comment: "Available slots section title")
        static let caregiverCount = NSLocalizedString("caregivers.caregiverCount", value: "Caregiver Count", comment: "Caregiver count section title")
        static func invitationCount(_ count: Int) -> String {
            return NSLocalizedString("caregivers.invitationCount", value: "\(count) invitation\(count == 1 ? "" : "s")", comment: "Invitation count")
        }
        static let addCaregiverButton = NSLocalizedString("caregivers.addCaregiverButton", value: "Add Caregiver", comment: "Add caregiver button")
        static let addCaregiverSubtitle = NSLocalizedString("caregivers.addCaregiverSubtitle", value: "Invite a caregiver to manage your schedule", comment: "Add caregiver subtitle")
        static let howItWorksTitle = NSLocalizedString("caregivers.howItWorksTitle", value: "How it Works", comment: "How it works section title")
        static let accessDisabledMessage = NSLocalizedString("caregivers.accessDisabledMessage", value: "Caregiver access is disabled until you invite a caregiver.", comment: "Caregiver access disabled message")
        static let howItWorksSubtitle = NSLocalizedString("caregivers.howItWorksSubtitle", value: "Invite a caregiver to manage your schedule.", comment: "How it works subtitle")
        static let managePermissions = NSLocalizedString("caregivers.managePermissions", value: "Manage Permissions", comment: "Manage permissions button")
        static let addCaregiver = NSLocalizedString("caregivers.addCaregiver", value: "Add Caregiver", comment: "Add caregiver button")
        static let howItWorks = NSLocalizedString("caregivers.howItWorks", value: "How it Works", comment: "How it works section title")
        static let enableAccess = NSLocalizedString("caregivers.enableAccess", value: "Enable Access", comment: "Enable access button")
        static func grantedDate(_ date: Date) -> String {
            return NSLocalizedString("caregivers.grantedDate", value: "Granted \(date.formatted(date: .abbreviated, time: .omitted))", comment: "Granted date with formatted date")
        }
        static func invitationCode(_ code: String) -> String {
            return NSLocalizedString("caregivers.invitationCode", value: "Code: \(code)", comment: "Invitation code with value")
        }
        static func caregiverCount(_ count: Int) -> String {
            return NSLocalizedString("caregivers.caregiverCount", value: "\(count) caregiver\(count == 1 ? "" : "s")", comment: "Caregiver count")
        }
        static func expires(_ date: Date) -> String {
            return NSLocalizedString("caregivers.expires", value: "Expires \(date.formatted(date: .abbreviated, time: .omitted))", comment: "Expiration date")
        }
        static let expired = NSLocalizedString("caregivers.expired", value: "Expired", comment: "Expired status")
        static let editPermissions = NSLocalizedString("caregivers.editPermissions", value: "Edit Permissions", comment: "Edit permissions button")
        static let disableNotifications = NSLocalizedString("caregivers.disableNotifications", value: "Disable Notifications", comment: "Disable notifications button")
        static let enableNotifications = NSLocalizedString("caregivers.enableNotifications", value: "Enable Notifications", comment: "Enable notifications button")
        static let removeCaregiver = NSLocalizedString("caregivers.removeCaregiver", value: "Remove Caregiver", comment: "Remove caregiver button")
        static let inviteNewCaregiver = NSLocalizedString("caregivers.inviteNewCaregiver", value: "Invite New Caregiver", comment: "Invite new caregiver button")
        static let inviteDescription = NSLocalizedString("caregivers.inviteDescription", value: "Send an invitation to grant access", comment: "Invite description")
        static let secureAccess = NSLocalizedString("caregivers.secureAccess", value: "Secure Access", comment: "Secure access title")
        static let secureAccessDescription = NSLocalizedString("caregivers.secureAccessDescription", value: "All caregiver access is encrypted and secure", comment: "Secure access description")
        static let granularPermissions = NSLocalizedString("caregivers.granularPermissions", value: "Granular Permissions", comment: "Granular permissions title")
        static let granularPermissionsDescription = NSLocalizedString("caregivers.granularPermissionsDescription", value: "Control exactly what caregivers can access", comment: "Granular permissions description")
        static let privacyFirst = NSLocalizedString("caregivers.privacyFirst", value: "Privacy First", comment: "Privacy first title")
        static let manageAccess = NSLocalizedString("caregivers.manageAccess", value: "Manage Access", comment: "Manage caregiver access action")
        static let manageAccessSubtitle = NSLocalizedString("caregivers.manageAccessSubtitle", value: "Control caregiver permissions", comment: "Manage access subtitle")
        static let privacyFirstDescription = NSLocalizedString("caregivers.privacyFirstDescription", value: "Your privacy is our top priority", comment: "Privacy first description")
    }
    
    // MARK: - Groups
    struct Groups {
        static let title = NSLocalizedString("groups.title", value: "Groups", comment: "Groups section title")
        static let noGroups = NSLocalizedString("groups.noGroups", value: "No Groups", comment: "No groups empty state title")
        static let noGroupsMessage = NSLocalizedString("groups.noGroupsMessage", value: "You haven't joined any groups yet", comment: "No groups empty state message")
        static let createFirst = NSLocalizedString("groups.createFirst", value: "Create First Group", comment: "Create first group button")
        static let createGroup = NSLocalizedString("groups.createGroup", value: "Create Group", comment: "Create group button")
        static let joinGroup = NSLocalizedString("groups.joinGroup", value: "Join Group", comment: "Join group button")
        static let groupName = NSLocalizedString("groups.groupName", value: "Group Name", comment: "Group name label")
        static let groupDescription = NSLocalizedString("groups.groupDescription", value: "Group Description", comment: "Group description label")
        static let members = NSLocalizedString("groups.members", value: "Members", comment: "Group members label")
        static let admin = NSLocalizedString("groups.admin", value: "Admin", comment: "Group admin label")
        static let leaveGroup = NSLocalizedString("groups.leaveGroup", value: "Leave Group", comment: "Leave group button")
        static let deleteGroup = NSLocalizedString("groups.deleteGroup", value: "Delete Group", comment: "Delete group button")
        static let settings = NSLocalizedString("groups.settings", value: "Settings", comment: "Group settings button")
        static let familySettingsSubtitle = NSLocalizedString("groups.familySettingsSubtitle", value: "Family Settings", comment: "Group family settings subtitle")
        static let familySettings = NSLocalizedString("groups.familySettings", value: "Family Settings", comment: "Group family settings title")
    }
    
    // MARK: - Search
    struct Search {
        static let title = NSLocalizedString("search.title", value: "Search", comment: "Search section title")
        static let noResults = NSLocalizedString("search.noResults", value: "No Results", comment: "No search results empty state title")
        static func noResultsMessage(_ searchTerm: String) -> String {
            return NSLocalizedString("search.noResultsMessage", value: "No results found for '\(searchTerm)'", comment: "No search results empty state message")
        }
    }
    
    // MARK: - Network
    struct Network {
        static let connectionError = NSLocalizedString("network.connectionError", value: "Connection Error", comment: "Network connection error title")
        static let connectionErrorMessage = NSLocalizedString("network.connectionErrorMessage", value: "Unable to connect to the server. Please check your internet connection.", comment: "Network connection error message")
    }
    
    // MARK: - MyHealth
    struct MyHealth {
        static let todaysSchedule = NSLocalizedString("myhealth.todaysSchedule", value: "Today's Schedule", comment: "Today's schedule title")
        static let noScheduleToday = NSLocalizedString("myhealth.noScheduleToday", value: "No schedule for today", comment: "No schedule today message")
        static let quickActions = NSLocalizedString("myhealth.quickActions", value: "Quick Actions", comment: "Quick actions title")
        static let addNewItem = NSLocalizedString("myhealth.addNewItem", value: "Add New Item", comment: "Add new item action sheet title")
        static let title = NSLocalizedString("myhealth.title", value: "My Health", comment: "My health section title")
    }
    
    // MARK: - Sync
    struct Sync {
        static let errorTitle = NSLocalizedString("sync.errorTitle", value: "Sync Error", comment: "Sync error title")
        static let errorMessage = NSLocalizedString("sync.errorMessage", value: "Unable to sync your data. Please try again.", comment: "Sync error message")
        static let title = NSLocalizedString("sync.title", value: "Sync Status", comment: "Sync status title")
        static let currentStatus = NSLocalizedString("sync.currentStatus", value: "Current Status", comment: "Current sync status label")
        static let lastSync = NSLocalizedString("sync.lastSync", value: "Last Sync", comment: "Last sync time label")
        static let networkStatus = NSLocalizedString("sync.networkStatus", value: "Network Status", comment: "Network status label")
        static let online = NSLocalizedString("sync.online", value: "Online", comment: "Online status")
        static let offline = NSLocalizedString("sync.offline", value: "Offline", comment: "Offline status")
        static let forceSyncNow = NSLocalizedString("sync.forceSyncNow", value: "Sync Now", comment: "Force sync now button")
        static let syncing = NSLocalizedString("sync.syncing", value: "Syncing...", comment: "Syncing in progress message")
        static let syncComplete = NSLocalizedString("sync.syncComplete", value: "Sync Complete", comment: "Sync completed message")
        static let syncFailed = NSLocalizedString("sync.syncFailed", value: "Sync Failed", comment: "Sync failed message")
        static let syncIssues = NSLocalizedString("sync.syncIssues", value: "Sync Issues", comment: "Sync issues status")
        
        // Properties from second Sync struct
        static let upToDate = NSLocalizedString("sync.upToDate", value: "Up to date", comment: "Up to date status")
        static let syncStatus = NSLocalizedString("sync.syncStatus", value: "Sync Status", comment: "Sync status title")
        static let pendingChanges = NSLocalizedString("sync.pendingChanges", value: "Pending Changes", comment: "Pending changes label")
        static let syncNow = NSLocalizedString("sync.syncNow", value: "Sync Now", comment: "Sync now button")
        static let justNow = NSLocalizedString("sync.justNow", value: "Just now", comment: "Just now time")
        static let minutesAgo = NSLocalizedString("sync.minutesAgo", value: "%d minutes ago", comment: "Minutes ago format")
        static let hoursAgo = NSLocalizedString("sync.hoursAgo", value: "%d hours ago", comment: "Hours ago format")
        static let daysAgo = NSLocalizedString("sync.daysAgo", value: "%d days ago", comment: "Days ago format")
    }
    
    // MARK: - Offline
    struct Offline {
        static let title = NSLocalizedString("offline.title", value: "Offline Mode", comment: "Offline mode title")
        static let message = NSLocalizedString("offline.message", value: "You're currently offline. Some features may be limited.", comment: "Offline mode message")
    }
    
    // MARK: - Permissions
    struct Permissions {
        static func title(_ permissionType: String) -> String {
            return NSLocalizedString("permissions.title", value: "\(permissionType) Access Required", comment: "Permission required title")
        }
        static func message(_ permissionType: String) -> String {
            return NSLocalizedString("permissions.message", value: "Please grant \(permissionType) access in Settings to use this feature.", comment: "Permission required message")
        }
    }
    
    // MARK: - Maintenance
    struct Maintenance {
        static let title = NSLocalizedString("maintenance.title", value: "Under Maintenance", comment: "Maintenance mode title")
        static let message = NSLocalizedString("maintenance.message", value: "The app is currently under maintenance. Please try again later.", comment: "Maintenance mode message")
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let genericError = NSLocalizedString("error.generic", value: "Something went wrong. Please try again.", comment: "Generic error message")
        static let networkError = NSLocalizedString("error.network", value: "Network connection error. Please check your internet connection.", comment: "Network error message")
        static let authenticationError = NSLocalizedString("error.authentication", value: "Authentication failed. Please sign in again.", comment: "Authentication error")
        static let signOutError = NSLocalizedString("error.signOut", value: "Sign out failed. Please try again.", comment: "Sign out error")
        static let userNotFound = NSLocalizedString("error.userNotFound", value: "User not found. Please sign up first.", comment: "User not found error")
        static let invalidCredentials = NSLocalizedString("error.invalidCredentials", value: "Invalid credentials. Please check your information.", comment: "Invalid credentials error")
        static let configurationError = NSLocalizedString("error.configuration", value: "Configuration error. Please contact support.", comment: "Configuration error")
        static let serverError = NSLocalizedString("error.server", value: "Server error. Please try again later.", comment: "Server error")
        static let dataError = NSLocalizedString("error.data", value: "Data error. Please try again.", comment: "Data error")
        static let corruptedDataError = NSLocalizedString("error.corruptedData", value: "Data is corrupted. Please reinstall the app.", comment: "Corrupted data error")
        static let phoneVerificationError = NSLocalizedString("error.phoneVerification", value: "Phone verification failed. Please check your number and try again.", comment: "Phone verification error")
        static let phoneCodeVerificationError = NSLocalizedString("error.phoneCodeVerification", value: "Invalid verification code. Please try again.", comment: "Phone code verification error")
        static let mfaEnrollmentError = NSLocalizedString("error.mfaEnrollment", value: "Failed to set up two-factor authentication. Please try again.", comment: "MFA enrollment error")
        static let mfaVerificationError = NSLocalizedString("error.mfaVerification", value: "Invalid authentication code. Please check your authenticator app.", comment: "MFA verification error")
        static let mfaRequiredError = NSLocalizedString("error.mfaRequired", value: "Two-factor authentication is required to continue.", comment: "MFA required error")
        static let permissionDenied = NSLocalizedString("error.permission", value: "Permission denied. Please enable in Settings.", comment: "Permission denied error")
        
        // Claude API Errors
        static let claudeAPIUnauthorized = NSLocalizedString("error.claudeAPI.unauthorized", value: "AI service authentication failed. Please check your settings.", comment: "Claude API unauthorized")
        static let claudeAPIRateLimited = NSLocalizedString("error.claudeAPI.rateLimited", value: "Too many requests. Please try again in a few moments.", comment: "Claude API rate limited")
        static let claudeAPIInvalidResponse = NSLocalizedString("error.claudeAPI.invalidResponse", value: "Received invalid response from AI service.", comment: "Claude API invalid response")
        static let claudeAPIModelUnavailable = NSLocalizedString("error.claudeAPI.modelUnavailable", value: "AI service temporarily unavailable. Please try again later.", comment: "Claude API model unavailable")
        static let claudeAPITokenLimit = NSLocalizedString("error.claudeAPI.tokenLimit", value: "Request too large. Please try a shorter query.", comment: "Claude API token limit")
        static let claudeAPIKeyMissing = NSLocalizedString("error.claudeAPI.keyMissing", value: "AI service not configured. Please contact support.", comment: "Claude API key missing")
        static let claudeAPIInvalidRequest = NSLocalizedString("error.claudeAPI.invalidRequest", value: "Invalid request format. Please try again.", comment: "Claude API invalid request")
        static let claudeAPIParsingError = NSLocalizedString("error.claudeAPI.parsingError", value: "Could not understand AI response. Please try again.", comment: "Claude API parsing error")
        
        // Conflict Analysis Errors
        static let conflictAnalysisError = NSLocalizedString("error.conflictAnalysis", value: "Unable to analyze conflicts. Please try again.", comment: "Conflict analysis error")
        static let analysisTimeoutError = NSLocalizedString("error.analysisTimeout", value: "Analysis took too long. Please try again with fewer medications.", comment: "Analysis timeout error")
    }
    
    // MARK: - Empty States
    struct EmptyStates {
        static let noMedications = NSLocalizedString("empty.medications", value: "No Medications", comment: "No medications empty state title")
        static let addFirstMedication = NSLocalizedString("empty.addFirst", value: "Add your first medication to get started", comment: "Add first medication description")
        static let noDoctors = NSLocalizedString("empty.doctors", value: "No Doctors Added", comment: "No doctors empty state")
        static let noConflicts = NSLocalizedString("empty.conflicts", value: "No Conflicts Found", comment: "No conflicts empty state")
        static let noMedicationsSubtitle = NSLocalizedString("empty.noMedicationsSubtitle", value: "Start managing your health by adding your first medication", comment: "No medications subtitle")
        static let noSupplements = NSLocalizedString("empty.noSupplements", value: "No Supplements", comment: "No supplements empty state")
        static let noSupplementsSubtitle = NSLocalizedString("empty.noSupplementsSubtitle", value: "Add supplements to track your complete health regimen", comment: "No supplements subtitle")
        static let noDietEntries = NSLocalizedString("empty.noDietEntries", value: "No Diet Entries", comment: "No diet entries empty state")
        static let noDietEntriesSubtitle = NSLocalizedString("empty.noDietEntriesSubtitle", value: "Start tracking your meals for better health insights", comment: "No diet entries subtitle")
        
        // Functions from CommonStrings.swift
        static func noItemsFound(_ items: String) -> String {
            String(format: NSLocalizedString("empty.noItemsFound", value: "No %@ found", comment: "No items"), items)
        }
        
        static func youHaveNo(_ items: String) -> String {
            String(format: NSLocalizedString("empty.youHaveNo", value: "You have no %@", comment: "You have no items"), items)
        }
    }
    
    // MARK: - User Mode
    struct UserMode {
        static let primaryUser = NSLocalizedString("userMode.primaryUser", value: "Primary User", comment: "Primary user mode")
        static let caregiver = NSLocalizedString("userMode.caregiver", value: "Caregiver", comment: "Caregiver mode")
        static let familyMember = NSLocalizedString("userMode.familyMember", value: "Family Member", comment: "Family member mode")
        static let welcomePrimary = NSLocalizedString("userMode.welcomePrimary", value: "Welcome back!", comment: "Welcome message for primary user")
        static let welcomeCaregiver = NSLocalizedString("userMode.welcomeCaregiver", value: "Welcome, %@!", comment: "Welcome message for caregiver with name")
        static let welcomeFamily = NSLocalizedString("userMode.welcomeFamily", value: "Welcome! You have view-only access.", comment: "Welcome message for family member")
    }
    
    // MARK: - Accessibility
    struct Accessibility {
        static let medicationCard = NSLocalizedString("accessibility.medicationCard", value: "Medication card", comment: "Medication card accessibility label")
        static let addButton = NSLocalizedString("accessibility.addButton", value: "Add new item", comment: "Add button accessibility label")
        static let voiceInputButton = NSLocalizedString("accessibility.voiceInput", value: "Voice input", comment: "Voice input button accessibility label")
        static let appLogo = NSLocalizedString("accessibility.appLogo", value: "MyGuide logo", comment: "App logo accessibility label")
        static let signInButton = NSLocalizedString("accessibility.signInButton", value: "Sign in with Google", comment: "Sign in button accessibility label")
        static let signInButtonHint = NSLocalizedString("accessibility.signInButtonHint", value: "Double tap to sign in with your Google account", comment: "Sign in button accessibility hint")
    }
    
    // MARK: - Voice
    struct Voice {
        static let medicationNamePrompt = NSLocalizedString("voice.medicationNamePrompt", value: "Say the medication name", comment: "Voice prompt for medication name")
        static let heardText = NSLocalizedString("voice.heardText", value: "Heard: %@", comment: "Voice heard text format")
        static let stopListening = NSLocalizedString("voice.stopListening", value: "Stop listening", comment: "Voice stop listening button")
        static let startListening = NSLocalizedString("voice.startListening", value: "Start listening", comment: "Voice start listening button")
        static let dosagePrompt = NSLocalizedString("voice.dosagePrompt", value: "Say the dosage amount", comment: "Voice prompt for dosage")
        static let frequencyPrompt = NSLocalizedString("voice.frequencyPrompt", value: "Say how often to take", comment: "Voice prompt for frequency")
        static let useVoice = NSLocalizedString("voice.useVoice", value: "Use Voice", comment: "Use voice input button")
        static let permissionRequired = NSLocalizedString("voice.permissionRequired", value: "Microphone Permission Required", comment: "Voice permission required title")
        static let permissionNeeded = NSLocalizedString("voice.permissionNeeded", value: "We need microphone access", comment: "Voice permission needed title")
        static let permissionMessage = NSLocalizedString("voice.permissionMessage", value: "Please allow microphone access to use voice input", comment: "Voice permission message")
        static let listening = NSLocalizedString("voice.listening", value: "Listening...", comment: "Voice listening status")
        static let tapToSpeak = NSLocalizedString("voice.tapToSpeak", value: "Tap to speak", comment: "Voice input instruction")
        static let processing = NSLocalizedString("voice.processing", value: "Processing...", comment: "Voice processing status")
        static let notesPrompt = NSLocalizedString("voice.notesPrompt", value: "Add any notes", comment: "Voice prompt for notes")
        static let doctorNamePrompt = NSLocalizedString("voice.doctorNamePrompt", value: "Say the doctor's name", comment: "Voice prompt for doctor name")
        static let doctorSpecialtyPrompt = NSLocalizedString("voice.doctorSpecialtyPrompt", value: "Say the specialty", comment: "Voice prompt for doctor specialty")
        static let foodNamePrompt = NSLocalizedString("voice.foodNamePrompt", value: "Say the food name", comment: "Voice prompt for food name")
        static let generalPrompt = NSLocalizedString("voice.generalPrompt", value: "Start speaking", comment: "General voice prompt")
        static let quickEntry = NSLocalizedString("voice.quickEntry", value: "Quick Entry", comment: "Quick voice entry title")
        static let quickEntrySubtitle = NSLocalizedString("voice.quickEntrySubtitle", value: "Add items with your voice", comment: "Quick voice entry subtitle")
        
        // Voice-First UI
        static let voiceActive = NSLocalizedString("voice.voiceActive", value: "Voice Active", comment: "Voice is active indicator")
        static let speakClearly = NSLocalizedString("voice.speakClearly", value: "Speak clearly", comment: "Speak clearly instruction")
        static let tapMicToStop = NSLocalizedString("voice.tapMicToStop", value: "Tap mic to stop", comment: "Stop recording instruction")
        static let noSpeechDetected = NSLocalizedString("voice.noSpeechDetected", value: "No speech detected", comment: "No speech detected message")
        static let tryAgain = NSLocalizedString("voice.tryAgain", value: "Try speaking again", comment: "Try again message")
        static let confirmTranscription = NSLocalizedString("voice.confirmTranscription", value: "Is this correct?", comment: "Confirm transcription")
        static let editTranscription = NSLocalizedString("voice.editTranscription", value: "Tap to edit", comment: "Edit transcription instruction")
        static let askAnything = NSLocalizedString("voice.askAnything", value: "Ask anything about your medications", comment: "Voice prompt")
        static let typeInstead = NSLocalizedString("voice.typeInstead", value: "Type instead", comment: "Type instead button")
        static let tapToSpeakMedication = NSLocalizedString("voice.tapToSpeakMedication", value: "Tap to speak medication name", comment: "Medication voice prompt")
        static let tapToSpeakSupplement = NSLocalizedString("voice.tapToSpeakSupplement", value: "Tap to speak supplement name", comment: "Supplement voice prompt")
        static let tapToSpeakDosage = NSLocalizedString("voice.tapToSpeakDosage", value: "Tap to speak dosage", comment: "Dosage voice prompt")
        static let tapToAskQuestion = NSLocalizedString("voice.tapToAskQuestion", value: "Tap to ask a question", comment: "Question voice prompt")
        static let startDictation = NSLocalizedString("voice.startDictation", value: "Start dictation", comment: "Start dictation accessibility label")
        
        // Natural Language
        static let conflictQueryPrompt = NSLocalizedString("voice.conflictQueryPrompt", value: "Ask about medication interactions", comment: "Conflict query prompt")
        static let naturalLanguageHint = NSLocalizedString("voice.naturalLanguageHint", value: "Speak naturally, like talking to a pharmacist", comment: "Natural language hint")
        static let exampleQueries = NSLocalizedString("voice.exampleQueries", value: "Example Questions", comment: "Example queries title")
        static let example1 = NSLocalizedString("voice.example1", value: "Can I take ibuprofen with my blood pressure medication?", comment: "Example query 1")
        static let example2 = NSLocalizedString("voice.example2", value: "What supplements interact with warfarin?", comment: "Example query 2")
        static let example3 = NSLocalizedString("voice.example3", value: "Is it safe to take these medications together?", comment: "Example query 3")
        
        // Voice-First Feature
        static let voiceFirst = NSLocalizedString("voice.voiceFirst", value: "Voice-First Design", comment: "Voice-first feature title")
        static let voiceFirstDescription = NSLocalizedString("voice.voiceFirstDescription", value: "Use natural voice commands to ask questions about your medications", comment: "Voice-first feature description")
        
        // Voice Feedback
        static let understood = NSLocalizedString("voice.understood", value: "Got it!", comment: "Understood confirmation")
        static let analyzing = NSLocalizedString("voice.analyzing", value: "Analyzing your question...", comment: "Analyzing voice query")
        static let didntCatch = NSLocalizedString("voice.didntCatch", value: "Sorry, I didn't catch that", comment: "Didn't understand")
        static let speakLouder = NSLocalizedString("voice.speakLouder", value: "Please speak a bit louder", comment: "Speak louder instruction")
        static let tooNoisy = NSLocalizedString("voice.tooNoisy", value: "Too noisy - try typing instead", comment: "Too noisy message")
        static let askQuestion = NSLocalizedString("voice.askQuestion", value: "Ask a Question", comment: "Ask question title")
        static let exampleQueriesTitle = NSLocalizedString("voice.exampleQueriesTitle", value: "Example Questions", comment: "Example queries title")
        static let exampleQuery1 = NSLocalizedString("voice.exampleQuery1", value: "Can I take aspirin with warfarin?", comment: "Example query 1")
        static let exampleQuery2 = NSLocalizedString("voice.exampleQuery2", value: "What are the interactions between ibuprofen and metformin?", comment: "Example query 2")
        static let exampleQuery3 = NSLocalizedString("voice.exampleQuery3", value: "What are the side effects of metformin?", comment: "Example query 3")
        static let exampleQuery4 = NSLocalizedString("voice.exampleQuery4", value: "Can I drink alcohol with my medications?", comment: "Example query 4")
        static let exampleQuery5 = NSLocalizedString("voice.exampleQuery5", value: "Is it safe to take vitamins with my medications?", comment: "Example query 5")
        static let quickExample1 = NSLocalizedString("voice.quickExample1", value: "Drug interactions", comment: "Quick example 1")
        static let quickExample2 = NSLocalizedString("voice.quickExample2", value: "Food interactions", comment: "Quick example 2")
        static let quickExample3 = NSLocalizedString("voice.quickExample3", value: "Side effects", comment: "Quick example 3")
        static let voiceQueryInstructions = NSLocalizedString("voice.voiceQueryInstructions", value: "Ask any question about your medications or potential interactions", comment: "Voice query instructions")
        static let yourQuery = NSLocalizedString("voice.yourQuery", value: "Your Query", comment: "Your query label")
        static let voiceInput = NSLocalizedString("voice.voiceInput", value: "Voice Input", comment: "Voice input navigation title")
        static let askAboutMedications = NSLocalizedString("voice.askAboutMedications", value: "Ask about your medications", comment: "Ask about medications prompt")
    }
    
    // MARK: - Tabs
    struct Tabs {
        static let myHealth = NSLocalizedString("tabs.myHealth", value: "My Health", comment: "My Health tab")
        static let groups = NSLocalizedString("tabs.groups", value: "Groups", comment: "Groups tab")
        static let doctors = NSLocalizedString("tabs.doctors", value: "Doctors", comment: "Doctors tab")
        static let conflicts = NSLocalizedString("tabs.conflicts", value: "Conflicts", comment: "Conflicts tab")
        static let doctorList = NSLocalizedString("tabs.doctorlist", value: "Doctorlist", comment: "Doctorlist tab")
    }
    
    // MARK: - Navigation
    struct Navigation {
        static let back = NSLocalizedString("navigation.back", value: "Back", comment: "Back button")
        static let close = NSLocalizedString("navigation.close", value: "Close", comment: "Close button")
        static let done = NSLocalizedString("navigation.done", value: "Done", comment: "Done button")
    }
    
    // MARK: - Features
    struct Features {
        static let addMedication = NSLocalizedString("features.addMedication", value: "Add Medication", comment: "Add medication feature")
        static let voiceInput = NSLocalizedString("features.voiceInput", value: "Voice Input", comment: "Voice input feature")
    }
    
    // MARK: - Alerts
    struct Alerts {
        static let title = NSLocalizedString("alerts.title", value: "Alert", comment: "Alert title")
    }
    
    // MARK: - Forms
    struct Forms {
        static let required = NSLocalizedString("forms.required", value: "Required", comment: "Required field")
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let title = NSLocalizedString("notifications.title", value: "Notifications", comment: "Notifications title")
        static let medicationReminderTitle = NSLocalizedString("notifications.medicationReminder.title", value: "Medication Reminder", comment: "Medication reminder title")
        static let taskCompletedBody = NSLocalizedString("notifications.taskCompleted.body", value: "%@ - %@", comment: "Task completed body")
        static let taskReminderTitle = NSLocalizedString("notifications.taskReminder.title", value: "Task Reminder", comment: "Task reminder title")
        static let taskReminderBody = NSLocalizedString("notifications.taskReminder.body", value: "%@ - %@", comment: "Task reminder body")
        static let taskCompletedTitle = NSLocalizedString("notifications.taskCompleted.title", value: "Task Completed", comment: "Task completed title")
        static let actionComplete = NSLocalizedString("notifications.action.complete", value: "Complete", comment: "Complete task action")
        static let medicationReminderBody = NSLocalizedString("notifications.medicationReminder.body", value: "Time to take %@ - %@", comment: "Medication reminder body")
        static let conflictAlertTitle = NSLocalizedString("notifications.conflictAlert.title", value: "Medication Conflict Alert", comment: "Conflict alert title")
        static let conflictAlertBody = NSLocalizedString("notifications.conflictAlert.body", value: "Potential interaction detected between: %@", comment: "Conflict alert body")
        static let caregiverAlertTitle = NSLocalizedString("notifications.caregiverAlert.title", value: "Caregiver Message", comment: "Caregiver alert title")
        static let actionTake = NSLocalizedString("notifications.action.take", value: "Take", comment: "Take medication action")
        static let actionSkip = NSLocalizedString("notifications.action.skip", value: "Skip", comment: "Skip medication action")
        static let actionSnooze = NSLocalizedString("notifications.action.snooze", value: "Snooze", comment: "Snooze medication action")
        static let actionView = NSLocalizedString("notifications.action.view", value: "View", comment: "View action")
        static let actionReply = NSLocalizedString("notifications.action.reply", value: "Reply", comment: "Reply action")
        static let replyPlaceholder = NSLocalizedString("notifications.replyPlaceholder", value: "Type a message...", comment: "Reply placeholder")
    }
    
    // MARK: - Profile
    struct Profile {
        static let title = NSLocalizedString("profile.title", value: "Profile", comment: "Profile title")
        static let editTitle = NSLocalizedString("profile.editTitle", value: "Edit Profile", comment: "Edit profile title")
        
        // Account Info
        static let accountInfo = NSLocalizedString("profile.accountInfo", value: "Account Information", comment: "Account info section")
        static let loginMethod = NSLocalizedString("profile.loginMethod", value: "Login", comment: "Login method label")
        
        // Personal Info
        static let personalInfo = NSLocalizedString("profile.personalInfo", value: "Personal Information", comment: "Personal info section")
        static let displayName = NSLocalizedString("profile.displayName", value: "Display Name", comment: "Display name label")
        static let namePlaceholder = NSLocalizedString("profile.namePlaceholder", value: "Your Name", comment: "Name placeholder")
        
        // Emergency Contact
        static let emergencyContact = NSLocalizedString("profile.emergencyContact", value: "Emergency Contact", comment: "Emergency contact section")
        static let emergencyName = NSLocalizedString("profile.emergencyName", value: "Contact Name", comment: "Emergency contact name")
        static let emergencyNamePlaceholder = NSLocalizedString("profile.emergencyNamePlaceholder", value: "Emergency Contact", comment: "Emergency name placeholder")
        static let emergencyPhone = NSLocalizedString("profile.emergencyPhone", value: "Contact Phone", comment: "Emergency contact phone")
        static let phonePlaceholder = NSLocalizedString("profile.phonePlaceholder", value: "(555) 555-5555", comment: "Phone placeholder")
        static let shareWithCaregivers = NSLocalizedString("profile.shareWithCaregivers", value: "Share with Caregivers", comment: "Share with caregivers toggle")
        static let shareWithCaregiversDescription = NSLocalizedString("profile.shareWithCaregiversDescription", value: "Allow caregivers to view and call emergency contact", comment: "Share description")
        static let emergencyLocalFooter = NSLocalizedString("profile.emergencyLocalFooter", value: "Emergency contact information is stored securely on this device only", comment: "Emergency local footer")
        static let emergencySharedFooter = NSLocalizedString("profile.emergencySharedFooter", value: "Caregivers will be able to view and call your emergency contact", comment: "Emergency shared footer")
        
        // Preferences
        static let preferences = NSLocalizedString("profile.preferences", value: "Preferences", comment: "Preferences section")
        static let notifications = NSLocalizedString("profile.notifications", value: "Notifications", comment: "Notifications toggle")
        static let conflictAlerts = NSLocalizedString("profile.conflictAlerts", value: "Conflict Alerts", comment: "Conflict alerts toggle")
        static let voiceShortcuts = NSLocalizedString("profile.voiceShortcuts", value: "Voice Shortcuts", comment: "Voice shortcuts toggle")
        static let preferencesFooter = NSLocalizedString("profile.preferencesFooter", value: "These settings apply to this iPhone only", comment: "Preferences footer")
        
        // Delete Profile
        static let deleteDataTitle = NSLocalizedString("profile.deleteDataTitle", value: "Delete Profile Data?", comment: "Delete data title")
        static let deleteDataMessage = NSLocalizedString("profile.deleteDataMessage", value: "This will remove your emergency contact information and preferences. You'll need to enter this information again if needed later.", comment: "Delete data message")
        
        // User Type Specific
        static let yourInfo = NSLocalizedString("profile.yourInfo", value: "Your Information", comment: "Primary user info header")
        static let caregiverInfo = NSLocalizedString("profile.caregiverInfo", value: "Caregiver Profile", comment: "Caregiver info header")
        static let familyMemberInfo = NSLocalizedString("profile.familyMemberInfo", value: "Family Member Profile", comment: "Family member info header")
        static let yourEmergencyContact = NSLocalizedString("profile.yourEmergencyContact", value: "Your Emergency Contact", comment: "Primary user emergency contact")
        static let patientEmergencyContact = NSLocalizedString("profile.patientEmergencyContact", value: "Patient's Emergency Contact", comment: "Patient emergency contact")
        static let patientEmergencyFooter = NSLocalizedString("profile.patientEmergencyFooter", value: "This is the patient's emergency contact information", comment: "Patient emergency footer")
        
        // Account Type Labels
        static let accountTypeLabel = NSLocalizedString("profile.accountType", value: "Account Type", comment: "Account type label")
        static let primaryAccountDesc = NSLocalizedString("profile.primaryAccountDesc", value: "You manage medications and caregiver access", comment: "Primary account description")
        static let caregiverAccountDesc = NSLocalizedString("profile.caregiverAccountDesc", value: "You have temporary access to help with patient care", comment: "Caregiver account description")
        static let familyAccountDesc = NSLocalizedString("profile.familyAccountDesc", value: "You have view-only access to monitor care", comment: "Family account description")
    }
    
    // MARK: - Errors
    struct Errors {
        static let genericErrorTitle = NSLocalizedString("errors.genericErrorTitle", value: "Error", comment: "Generic error title")
        static let genericErrorMessage = NSLocalizedString("errors.genericErrorMessage", value: "An unexpected error occurred.", comment: "Generic error message")
        static let title = NSLocalizedString("errors.title", value: "Error", comment: "Error title")
        static let coreDataGenericError = NSLocalizedString("errors.coreDataGenericError", value: "Database error occurred.", comment: "Core Data generic error")
        static let genericIntentError = NSLocalizedString("errors.genericIntentError", value: "Unable to complete action.", comment: "Generic intent error")
        static let userNotAuthenticated = NSLocalizedString("errors.userNotAuthenticated", value: "User not authenticated.", comment: "User not authenticated")
        static let userIdNotFound = NSLocalizedString("errors.userIdNotFound", value: "User ID not found.", comment: "User ID not found")
        static let authenticationRequired = NSLocalizedString("errors.authenticationRequired", value: "Authentication required", comment: "Authentication required")
        static let authenticationExpired = NSLocalizedString("errors.authenticationExpired", value: "Authentication expired.", comment: "Authentication expired")
        static let invalidMedicationName = NSLocalizedString("errors.invalidMedicationName", value: "Medication name is required.", comment: "Invalid medication name")
        static let invalidDosage = NSLocalizedString("errors.invalidDosage", value: "Dosage is required.", comment: "Invalid dosage")
        static let invalidFrequency = NSLocalizedString("errors.invalidFrequency", value: "Frequency is required.", comment: "Invalid frequency")
        static let medicationNotFound = NSLocalizedString("errors.medicationNotFound", value: "Medication not found.", comment: "Medication not found")
        static let duplicateMedication = NSLocalizedString("errors.duplicateMedication", value: "Medication already exists.", comment: "Duplicate medication")
        static let coreDataSaveFailure = NSLocalizedString("errors.coreDataSaveFailure", value: "Failed to save data to the database.", comment: "Core Data save failure")
        static let coreDataFetchFailure = NSLocalizedString("errors.coreDataFetchFailure", value: "Failed to fetch data from the database.", comment: "Core Data fetch failure")
        static let voiceInputAmbiguous = NSLocalizedString("errors.voiceInputAmbiguous", value: "Voice input ambiguous.", comment: "Voice input ambiguous")
        static let memoryLimitExceeded = NSLocalizedString("errors.memoryLimitExceeded", value: "Memory limit exceeded.", comment: "Memory limit exceeded")
        static let pleaseSignIn = NSLocalizedString("errors.pleaseSignIn", value: "Please sign in.", comment: "Please sign in")
        static let coreDataMigrationRequired = NSLocalizedString("errors.coreDataMigrationRequired", value: "Database migration required.", comment: "Core Data migration required")
        static let networkUnavailable = NSLocalizedString("errors.networkUnavailable", value: "Network unavailable.", comment: "Network unavailable")
        static let apiKeyMissing = NSLocalizedString("errors.apiKeyMissing", value: "API key missing.", comment: "API key missing")
        static let apiRequestFailed = NSLocalizedString("errors.apiRequestFailed", value: "API request failed.", comment: "API request failed")
        static let apiResponseInvalid = NSLocalizedString("errors.apiResponseInvalid", value: "API response invalid.", comment: "API response invalid")
        static let voiceInputambiguous = NSLocalizedString("errors.voiceInputambiguous", value: "Voice input ambiguous.", comment: "Voice input ambiguous")
        static let voiceInputNotRecognized = NSLocalizedString("errors.voiceInputNotRecognized", value: "Voice input not recognized.", comment: "Voice input not recognized")
        static let medicalTermNotFound = NSLocalizedString("errors.medicalTermNotFound", value: "Medical term not found.", comment: "Medical term not found")
        static let conflictDetectionFailed = NSLocalizedString("errors.conflictDetectionFailed", value: "Conflict detection failed.", comment: "Conflict detection failed")
        static let maxMedicationsReached = NSLocalizedString("errors.maxMedicationsReached", value: "Maximum number of medications reached.", comment: "Maximum number of medications reached")
        static let subscriptionRequired = NSLocalizedString("errors.subscriptionRequired", value: "Subscription required.", comment: "Subscription required")
        static let memoryLimitRequired = NSLocalizedString("errors.memoryLimitRequired", value: "Memory limit required.", comment: "Memory limit required")
        static let extensionTimeout = NSLocalizedString("errors.extensionTimeout", value: "Extension timeout.", comment: "Extension timeout")
        static let unknownError = NSLocalizedString("errors.unknownError", value: "Unknown error.", comment: "Unknown error")
        
        // MARK: - Recovery Suggestions
        struct Recovery {
            static let pleaseSignIn = NSLocalizedString("errors.recovery.pleaseSignIn", value: "Please sign in to continue", comment: "Please sign in recovery")
            static let checkMedicationSpelling = NSLocalizedString("errors.recovery.checkMedicationSpelling", value: "Check the medication spelling and try again", comment: "Check medication spelling")
            static let useDosageFormat = NSLocalizedString("errors.recovery.useDosageFormat", value: "Use format like '100mg' or '2 tablets'", comment: "Use dosage format")
            static let useFrequencyFormat = NSLocalizedString("errors.recovery.useFrequencyFormat", value: "Try 'once daily', 'twice daily', or 'as needed'", comment: "Use frequency format")
            static let checkMedicationList = NSLocalizedString("errors.recovery.checkMedicationList", value: "Check your medication list and try again", comment: "Check medication list")
            static let medicationAlreadyExists = NSLocalizedString("errors.recovery.medicationAlreadyExists", value: "This medication is already in your list", comment: "Medication already exists")
            static let checkInternetConnection = NSLocalizedString("errors.recovery.checkInternetConnection", value: "Check your internet connection and try again", comment: "Check internet connection")
            static let tryMoreSpecific = NSLocalizedString("errors.recovery.tryMoreSpecific", value: "Try being more specific", comment: "Try more specific")
            static let upgradePlan = NSLocalizedString("errors.recovery.upgradePlan", value: "Upgrade your plan to add more medications", comment: "Upgrade plan")
            static let tryAgainLater = NSLocalizedString("errors.recovery.tryAgainLater", value: "Please try again later", comment: "Try again later")
        }
        
    }
    
    // MARK: - Siri
    struct Siri {
        static let checkInteractionsTitle = NSLocalizedString("siri.checkInteractions.title", value: "Check Medication Interactions", comment: "Siri shortcut title")
        static let checkInteractionsPhrase = NSLocalizedString("siri.checkInteractions.phrase", value: "Check my medications", comment: "Siri shortcut phrase")
        static let addMedicationTitle = NSLocalizedString("siri.addMedication.title", value: "Add Medication", comment: "Add medication shortcut title")
        static let addMedicationPhrase = NSLocalizedString("siri.addMedication.phrase", value: "Add a medication", comment: "Add medication shortcut phrase")
        static let medicationReminderTitle = NSLocalizedString("siri.medicationReminder.title", value: "Medication Reminder", comment: "Reminder shortcut title")
        static let medicationReminderPhrase = NSLocalizedString("siri.medicationReminder.phrase", value: "When should I take my medicine", comment: "Reminder shortcut phrase")
        static let shortcutAdded = NSLocalizedString("siri.shortcutAdded", value: "Siri Shortcut Added", comment: "Shortcut added confirmation")
        static let shortcutUpdated = NSLocalizedString("siri.shortcutUpdated", value: "Siri Shortcut Updated", comment: "Shortcut updated confirmation")
        static let addToSiri = NSLocalizedString("siri.addToSiri", value: "Add to Siri", comment: "Add to Siri button")
        static let editInSiri = NSLocalizedString("siri.editInSiri", value: "Edit in Siri", comment: "Edit shortcut button")
        static let siriTipsTitle = NSLocalizedString("siri.tipsTitle", value: "Siri Shortcuts", comment: "Siri tips title")
        static let defaultConflictQuery = NSLocalizedString("siri.defaultConflictQuery", value: "Check my current medications for conflicts", comment: "Default conflict query")
        static let conflictAnalysisResponse = NSLocalizedString("siri.conflictAnalysisResponse", value: "%d conflicts found. %@", comment: "Conflict analysis response")
        static let checkConflictsContent = NSLocalizedString("siri.checkConflictsContent", value: "Check medication conflicts", comment: "Check conflicts content")
        
        // Check medications shortcut
        static let checkMedicationsPhrase = NSLocalizedString("siri.checkMedications.phrase", value: "Check my medications", comment: "Check medications shortcut phrase")
        static let checkConflictsPhrase = NSLocalizedString("siri.checkConflicts.phrase", value: "Check for conflicts", comment: "Check conflicts shortcut phrase")
        static let logMedicationPhrase = NSLocalizedString("siri.logMedication.phrase", value: "Log medication", comment: "Log medication shortcut phrase")
        static let remindMePhrase = NSLocalizedString("siri.remindMe.phrase", value: "Remind me about my medication", comment: "Remind me shortcut phrase")
        
        // Response messages
        static let medicationCountResponse = NSLocalizedString("siri.medicationCount.response", value: "You have %d active medications", comment: "Medication count response")
        static let addMedicationError = NSLocalizedString("siri.addMedication.error", value: "I need a medication name to add", comment: "Add medication error")
        static let medicationAddedResponse = NSLocalizedString("siri.medicationAdded.response", value: "Added %@ to your medications", comment: "Medication added response")
        static let checkConflictsError = NSLocalizedString("siri.checkConflicts.error", value: "Unable to check conflicts right now", comment: "Check conflicts error")
        static let logMedicationError = NSLocalizedString("siri.logMedication.error", value: "I need a medication name to log", comment: "Log medication error")
        static let medicationLoggedResponse = NSLocalizedString("siri.medicationLogged.response", value: "Logged %@ as taken", comment: "Medication logged response")
        static let medicationSkippedResponse = NSLocalizedString("siri.medicationSkipped.response", value: "Marked %@ as skipped", comment: "Medication skipped response")
        static let reminderError = NSLocalizedString("siri.reminder.error", value: "I need a medication name for the reminder", comment: "Reminder error")
        static let reminderSetResponse = NSLocalizedString("siri.reminderSet.response", value: "Reminder set for %@ at %@", comment: "Reminder set response")
        static let notSignedInResponse = NSLocalizedString("siri.notSignedIn.response", value: "Please sign in to the app first", comment: "Not signed in response")
        static let checkMedicationsError = NSLocalizedString("siri.checkMedications.error", value: "Unable to check medications right now", comment: "Check medications error")
        static let noMedicationsToCheck = NSLocalizedString("siri.noMedicationsToCheck", value: "You don't have any medications to check", comment: "No medications to check")
        static let medicationNotFoundResponse = NSLocalizedString("siri.medicationNotFound.response", value: "I couldn't find %@ in your medications", comment: "Medication not found response")
        static let voiceSkippedReason = NSLocalizedString("siri.voiceSkippedReason", value: "Skipped via Siri", comment: "Voice skipped reason")
        static let defaultReminderTime = NSLocalizedString("siri.defaultReminderTime", value: "the scheduled time", comment: "Default reminder time")
        static let voiceQueryError = NSLocalizedString("siri.voiceQueryError", value: "Sorry, I couldn't understand your query", comment: "Voice query error")
        static let noMedicationsForMealResponse = NSLocalizedString("siri.noMedicationsForMealResponse", value: "No medications scheduled for %@", comment: "No medications for meal")
        static let mealMedicationsResponse = NSLocalizedString("siri.mealMedicationsResponse", value: "For %@, take: %@", comment: "Meal medications response")
        
        // Siri Tips
        static let tipTitle = NSLocalizedString("siri.tipTitle", value: "Try saying:", comment: "Siri tip title")
        static let viewMedicationsPhrase = NSLocalizedString("siri.viewMedicationsPhrase", value: "Show my medications", comment: "View medications phrase")
        static let viewDoctorsPhrase = NSLocalizedString("siri.viewDoctorsPhrase", value: "Show my doctors", comment: "View doctors phrase")
        static let morningMedicationsPhrase = NSLocalizedString("siri.morningMedicationsPhrase", value: "What medications should I take this morning?", comment: "Morning medications phrase")
        static let eveningMedicationsPhrase = NSLocalizedString("siri.eveningMedicationsPhrase", value: "What medications should I take this evening?", comment: "Evening medications phrase")
    }
    
    // MARK: - Sync
    
    // MARK: - Entities
    struct Entities {
        static let medicationType = NSLocalizedString("entities.medicationType", value: "Medication", comment: "Medication entity type")
        static let medicationNumericFormat = NSLocalizedString("entities.medicationNumericFormat", value: "%d medications", comment: "Medication numeric format")
        static let frequencyType = NSLocalizedString("entities.frequencyType", value: "Medication Frequency", comment: "Frequency entity type")
    }
    
    // MARK: - Frequency
    struct Frequency {
        static let onceDaily = NSLocalizedString("frequency.onceDaily", value: "Once Daily", comment: "Once daily frequency")
        static let twiceDaily = NSLocalizedString("frequency.twiceDaily", value: "Twice Daily", comment: "Twice daily frequency")
        static let thriceDaily = NSLocalizedString("frequency.thriceDaily", value: "Three Times Daily", comment: "Three times daily frequency")
        static let asNeeded = NSLocalizedString("frequency.asNeeded", value: "As Needed", comment: "As needed frequency")
        static let custom = NSLocalizedString("frequency.custom", value: "Custom Schedule", comment: "Custom frequency")
        
        struct Voice {
            static let once = NSLocalizedString("frequency.voice.once", value: "once a day", comment: "Voice: once daily")
            static let twice = NSLocalizedString("frequency.voice.twice", value: "twice a day", comment: "Voice: twice daily")
            static let thrice = NSLocalizedString("frequency.voice.thrice", value: "three times a day", comment: "Voice: three times daily")
            static let asNeeded = NSLocalizedString("frequency.voice.asNeeded", value: "as needed", comment: "Voice: as needed")
            static let custom = NSLocalizedString("frequency.voice.custom", value: "custom schedule", comment: "Voice: custom")
        }
    }
    
    // MARK: - AI
    struct AI {
        static let poweredByClaude = NSLocalizedString("ai.poweredByClaude", value: "Powered by Claude AI", comment: "Claude AI attribution")
        static let analyzing = NSLocalizedString("ai.analyzing", value: "AI is analyzing...", comment: "AI analyzing status")
        static let analyzingMedications = NSLocalizedString("ai.analyzingMedications", value: "Analyzing medications...", comment: "Analyzing medications message")
        static let analyzingQuery = NSLocalizedString("ai.analyzingQuery", value: "Analyzing your query...", comment: "Analyzing query message")
        static let claudeDescription = NSLocalizedString("ai.claudeDescription", value: "Powered by Claude AI for intelligent medication analysis", comment: "Claude AI description")
        static let pleaseWait = NSLocalizedString("ai.pleaseWait", value: "Please wait while we analyze", comment: "Please wait message")
        static let generatingResponse = NSLocalizedString("ai.generatingResponse", value: "Generating response...", comment: "AI generating response")
        static let confidence = NSLocalizedString("ai.confidence", value: "Confidence Level", comment: "AI confidence label")
        static let highConfidence = NSLocalizedString("ai.highConfidence", value: "High Confidence", comment: "High confidence")
        static let mediumConfidence = NSLocalizedString("ai.mediumConfidence", value: "Medium Confidence", comment: "Medium confidence")
        static let lowConfidence = NSLocalizedString("ai.lowConfidence", value: "Low Confidence", comment: "Low confidence")
        static let consultDoctor = NSLocalizedString("ai.consultDoctor", value: "Always consult your doctor", comment: "Consult doctor reminder")
        static let educationalOnly = NSLocalizedString("ai.educationalOnly", value: "For educational purposes only", comment: "Educational disclaimer")
        static let aiResponse = NSLocalizedString("ai.aiResponse", value: "AI Response", comment: "AI response label")
        static let analyzeWithClaude = NSLocalizedString("ai.analyzeWithClaude", value: "Analyze with Claude AI", comment: "Analyze with Claude button")
        static let analysisTitle = NSLocalizedString("ai.analysisTitle", value: "Conflict Analysis", comment: "AI analysis title")
        static let summary = NSLocalizedString("ai.summary", value: "Summary", comment: "AI summary title")
        static let queryDisclaimer = NSLocalizedString("ai.queryDisclaimer", value: "AI analysis is for informational purposes only", comment: "AI query disclaimer")
        static let cached = NSLocalizedString("ai.cached", value: "Cached", comment: "Cached result indicator")
        static let aiPoweredAnalysis = NSLocalizedString("ai.aiPoweredAnalysis", value: "AI-Powered Analysis", comment: "AI powered analysis title")
        static let totalAnalyses = NSLocalizedString("ai.totalAnalyses", value: "Total Analyses", comment: "Total analyses label")
        static let lastAnalysis = NSLocalizedString("ai.lastAnalysis", value: "Last Analysis", comment: "Last analysis label")
        static let viewHistory = NSLocalizedString("ai.viewHistory", value: "View History", comment: "View history button")
        // Duplicate removed - already defined earlier in AI struct
        // static let analyzingMedications = NSLocalizedString("ai.analyzingMedications", value: "Analyzing medications", comment: "Analyzing medications status")
        // static let analyzingQuery = NSLocalizedString("ai.analyzingQuery", value: "Analyzing your query...", comment: "Analyzing query message")
        static let checkingInteractions = NSLocalizedString("ai.checkingInteractions", value: "Checking for interactions...", comment: "Checking interactions status")
        static let recommendations = NSLocalizedString("ai.recommendations", value: "Recommendations", comment: "Recommendations title")
        static let additionalInfo = NSLocalizedString("ai.additionalInfo", value: "Additional Information", comment: "Additional info title")
        static let disclaimer = NSLocalizedString("ai.disclaimer", value: "This analysis is for informational purposes only. Always consult your healthcare provider before making changes to your medications.", comment: "AI disclaimer")
        static let analysisAttribution = NSLocalizedString("ai.analysisAttribution", value: "Analysis powered by Claude 3 Sonnet", comment: "AI analysis attribution")
        static let importantNote = NSLocalizedString("ai.importantNote", value: "Important Note", comment: "Important note title")
        static let askQuestion = NSLocalizedString("ai.askQuestion", value: "Ask a Question", comment: "Ask question title")
        static let analysisReport = NSLocalizedString("ai.analysisReport", value: "Medication Conflict Analysis Report", comment: "Analysis report title")
    }
    
    // MARK: - Medical Terminology
    struct MedicalTerminology {
        static let enterMedicationName = NSLocalizedString("medical.enterMedicationName", value: "Enter medication name", comment: "Enter medication name placeholder")
        static let enterSupplementName = NSLocalizedString("medical.enterSupplementName", value: "Enter supplement name", comment: "Enter supplement name placeholder")
        static let notRecognized = NSLocalizedString("medical.notRecognized", value: "Not recognized - continue anyway?", comment: "Medication not recognized warning")
        static let searchingMedications = NSLocalizedString("medical.searchingMedications", value: "Searching medications...", comment: "Searching medications")
        static let noSuggestions = NSLocalizedString("medical.noSuggestions", value: "No suggestions found", comment: "No suggestions found")
        static let didYouMean = NSLocalizedString("medical.didYouMean", value: "Did you mean:", comment: "Did you mean label")
        static let commonMedications = NSLocalizedString("medical.commonMedications", value: "Common Medications", comment: "Common medications title")
        static let recentMedications = NSLocalizedString("medical.recentMedications", value: "Recent Medications", comment: "Recent medications title")
    }
    
    // MARK: - Testing
    struct Testing {
        static let title = NSLocalizedString("testing.title", value: "Sync Test Runner", comment: "Testing title")
        static let runTests = NSLocalizedString("testing.runTests", value: "Run Tests", comment: "Run tests button")
        static let runningTests = NSLocalizedString("testing.runningTests", value: "Running tests...", comment: "Running tests message")
        static let testsPassed = NSLocalizedString("testing.testsPassed", value: "All tests passed!", comment: "Tests passed message")
        static let testsFailed = NSLocalizedString("testing.testsFailed", value: "Some tests failed", comment: "Tests failed message")
        static let seeDetails = NSLocalizedString("testing.seeDetails", value: "See Details", comment: "See details button")
        static let medicationFetchedSuccessfully = NSLocalizedString("testing.medicationFetchedSuccessfully", value: "Medication fetched successfully", comment: "Medication fetched successfully")
        static let medicationNotFound = NSLocalizedString("testing.medicationNotFound", value: "Medication not found", comment: "Medication not found")
        static let medicationUpdatedSuccessfully = NSLocalizedString("testing.medicationUpdatedSuccessfully", value: "Medication updated successfully", comment: "Medication updated successfully")
        static let supplementFetchedSuccessfully = NSLocalizedString("testing.supplementFetchedSuccessfully", value: "Supplement fetched successfully", comment: "Supplement fetched successfully")
        static let supplementNotFound = NSLocalizedString("testing.supplementNotFound", value: "Supplement not found", comment: "Supplement not found")
    }
    
    // MARK: - Tasks
    struct Tasks {
        static let title = NSLocalizedString("tasks.title", value: "Tasks", comment: "Tasks title")
        static let taskDetails = NSLocalizedString("tasks.taskDetails", value: "Task Details", comment: "Task details title")
        static let timeWindow = NSLocalizedString("tasks.timeWindow", value: "Time Window", comment: "Time window label")
        static let priority = NSLocalizedString("tasks.priority", value: "Priority", comment: "Priority label")
        static let status = NSLocalizedString("tasks.status", value: "Status", comment: "Status label")
        static let addNote = NSLocalizedString("tasks.addNote", value: "Add Note", comment: "Add note button")
        static let notes = NSLocalizedString("tasks.notes", value: "Notes", comment: "Notes label")
        static let completionNotes = NSLocalizedString("tasks.completionNotes", value: "Completion Notes", comment: "Completion notes label")
        static let markAsCompleted = NSLocalizedString("tasks.markAsCompleted", value: "Mark as Completed", comment: "Mark as completed button")
        static let markAsSkipped = NSLocalizedString("tasks.markAsSkipped", value: "Mark as Skipped", comment: "Mark as skipped button")
        static let importantReminders = NSLocalizedString("tasks.importantReminders", value: "Important Reminders", comment: "Important reminders section")
        static let beforeMedication = NSLocalizedString("tasks.beforeMedication", value: "Before giving medication", comment: "Before medication reminder")
        static let verifyMedication = NSLocalizedString("tasks.verifyMedication", value: "Verify medication name and dosage", comment: "Verify medication instruction")
        static let checkExpiration = NSLocalizedString("tasks.checkExpiration", value: "Check expiration date", comment: "Check expiration instruction")
        static let followInstructions = NSLocalizedString("tasks.followInstructions", value: "Follow prescribed instructions", comment: "Follow instructions reminder")
        static let medicationGiven = NSLocalizedString("tasks.medicationGiven", value: "Medication Given", comment: "Medication given confirmation")
        static let medicationSkipped = NSLocalizedString("tasks.medicationSkipped", value: "Medication Skipped", comment: "Medication skipped confirmation")
        static let mealServed = NSLocalizedString("tasks.mealServed", value: "Meal Served", comment: "Meal served confirmation")
        static let mealSkipped = NSLocalizedString("tasks.mealSkipped", value: "Meal Skipped", comment: "Meal skipped confirmation")
        static let exerciseCompleted = NSLocalizedString("tasks.exerciseCompleted", value: "Exercise Completed", comment: "Exercise completed confirmation")
        static let exerciseSkipped = NSLocalizedString("tasks.exerciseSkipped", value: "Exercise Skipped", comment: "Exercise skipped confirmation")
        static let appointmentAttended = NSLocalizedString("tasks.appointmentAttended", value: "Appointment Attended", comment: "Appointment attended confirmation")
        static let appointmentMissed = NSLocalizedString("tasks.appointmentMissed", value: "Appointment Missed", comment: "Appointment missed confirmation")
        static let medicationReminder = NSLocalizedString("tasks.medicationReminder", value: "Medication Reminder", comment: "Medication reminder label")
        static let mealReminder = NSLocalizedString("tasks.mealReminder", value: "Meal Reminder", comment: "Meal reminder label")
        static let exerciseReminder = NSLocalizedString("tasks.exerciseReminder", value: "Exercise Reminder", comment: "Exercise reminder label")
        static let appointmentReminder = NSLocalizedString("tasks.appointmentReminder", value: "Appointment Reminder", comment: "Appointment reminder label")
        static let generalReminder = NSLocalizedString("tasks.generalReminder", value: "General Reminder", comment: "General reminder label")
        static let completed = NSLocalizedString("tasks.completed", value: "Completed", comment: "Completed status")
        static let pending = NSLocalizedString("tasks.pending", value: "Pending", comment: "Pending status")
        static let skipped = NSLocalizedString("tasks.skipped", value: "Skipped", comment: "Skipped status")
        static let overdue = NSLocalizedString("tasks.overdue", value: "Overdue", comment: "Overdue status")
        static let criticalMedication = NSLocalizedString("tasks.criticalMedication", value: "Critical Medication", comment: "Critical medication task")
        static let hydration = NSLocalizedString("tasks.hydration", value: "Hydration", comment: "Hydration task")
        static let exercise = NSLocalizedString("tasks.exercise", value: "Exercise", comment: "Exercise task")
        static let appointment = NSLocalizedString("tasks.appointment", value: "Appointment", comment: "Appointment task")
        static let noTasksToday = NSLocalizedString("tasks.noTasksToday", value: "No tasks scheduled for today", comment: "No tasks today message")
        static let todayOnlyNotice = NSLocalizedString("tasks.todayOnlyNotice", value: "Caregivers can only view today's tasks", comment: "Today only notice for caregivers")
        static let allCaughtUp = NSLocalizedString("tasks.allCaughtUp", value: "All tasks caught up!", comment: "All tasks caught up message")
        
        // Missing strings for TaskCompletionSheet
        static let completeTask = NSLocalizedString("tasks.completeTask", value: "Complete Task", comment: "Complete task title")
        static let confirmationRequired = NSLocalizedString("tasks.confirmationRequired", value: "Confirmation Required", comment: "Confirmation required label")
        static let noteOptional = NSLocalizedString("tasks.noteOptional", value: "Note (Optional)", comment: "Note optional label")
        static let photoEvidence = NSLocalizedString("tasks.photoEvidence", value: "Photo Evidence", comment: "Photo evidence label")
        static let checkAllergies = NSLocalizedString("tasks.checkAllergies", value: "Check for allergies", comment: "Check allergies reminder")
        static let supplementGiven = NSLocalizedString("tasks.supplementGiven", value: "Supplement Given", comment: "Supplement given confirmation")
        static let hydrationCompleted = NSLocalizedString("tasks.hydrationCompleted", value: "Hydration Completed", comment: "Hydration completed confirmation")
        static let taskCompleted = NSLocalizedString("tasks.taskCompleted", value: "Task Completed", comment: "Task completed confirmation")
        
        // Missing strings for TaskHistoryView
        static let taskHistory = NSLocalizedString("tasks.taskHistory", value: "Task History", comment: "Task history title")
        static let totalCompleted = NSLocalizedString("tasks.totalCompleted", value: "Total Completed", comment: "Total completed label")
        
        // Additional missing strings for TaskCompletionSheet
        static let correctDosageGiven = NSLocalizedString("tasks.correctDosageGiven", value: "Correct dosage given", comment: "Correct dosage given confirmation")
        static let notePlaceholder = NSLocalizedString("tasks.notePlaceholder", value: "Add any additional notes here...", comment: "Note placeholder text")
        static let takePhoto = NSLocalizedString("tasks.takePhoto", value: "Take Photo", comment: "Take photo button")
        static let contactPrimaryUser = NSLocalizedString("tasks.contactPrimaryUser", value: "Contact primary user if concerns", comment: "Contact primary user reminder")
        static let markComplete = NSLocalizedString("tasks.markComplete", value: "Mark Complete", comment: "Mark complete button")
        static let skipTask = NSLocalizedString("tasks.skipTask", value: "Skip Task", comment: "Skip task button")
        static let noAdverseReaction = NSLocalizedString("tasks.noAdverseReaction", value: "No adverse reactions observed", comment: "No adverse reaction confirmation")
        static let mealConsumed = NSLocalizedString("tasks.mealConsumed", value: "Meal consumed successfully", comment: "Meal consumed confirmation")
        
        // Additional missing strings for TaskHistoryView
        static let onTimeRate = NSLocalizedString("tasks.onTimeRate", value: "On-Time Rate", comment: "On-time completion rate label")
        static let noHistoryFound = NSLocalizedString("tasks.noHistoryFound", value: "No task history found", comment: "No history found message")
        static let averageDelay = NSLocalizedString("tasks.averageDelay", value: "Average Delay", comment: "Average delay label")
        static let mostActive = NSLocalizedString("tasks.mostActive", value: "Most Active", comment: "Most active caregiver label")
        static let tasks = NSLocalizedString("tasks.tasks", value: "tasks", comment: "Tasks plural label")
        static let noTasksCompleted = NSLocalizedString("tasks.noTasksCompleted", value: "No tasks have been completed in this period", comment: "No tasks completed message")
    }
    
    // MARK: - Export
    struct Export {
        static let exportHistory = NSLocalizedString("export.exportHistory", value: "Export History", comment: "Export history button")
        static let exportFormat = NSLocalizedString("export.exportFormat", value: "Export Format", comment: "Export format label")
        static let exportOptions = NSLocalizedString("export.exportOptions", value: "Export Options", comment: "Export options section header")
        static let exportToPDF = NSLocalizedString("export.exportToPDF", value: "Export to PDF", comment: "Export to PDF option")
        static let exportToCSV = NSLocalizedString("export.exportToCSV", value: "Export to CSV", comment: "Export to CSV option")
        static let share = NSLocalizedString("export.share", value: "Share", comment: "Share button")
        static let pdf = NSLocalizedString("export.pdf", value: "PDF", comment: "PDF format option")
        static let csv = NSLocalizedString("export.csv", value: "CSV", comment: "CSV format option")
    }
}
