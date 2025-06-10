import Foundation

struct AppStrings {
    // MARK: - Tab Titles
    struct TabTitles {
        static let myHealth = NSLocalizedString("tab.myHealth", value: "MyHealth", comment: "MyHealth tab title")
        static let groups = NSLocalizedString("tab.groups", value: "Groups", comment: "Groups tab title")
        static let doctorList = NSLocalizedString("tab.doctorList", value: "Doctors", comment: "Doctor list tab title")
        static let conflicts = NSLocalizedString("tab.conflicts", value: "Conflicts", comment: "Conflicts tab title")
    }
    
    // MARK: - App
    struct App {
        static let name = NSLocalizedString("app.name", value: "Mango Health", comment: "App name")
    }
    
    // MARK: - Authentication
    struct Authentication {
        static let signIn = NSLocalizedString("auth.signIn", value: "Sign In", comment: "Sign in button")
        static let signUp = NSLocalizedString("auth.signUp", value: "Sign Up", comment: "Sign up button")
        static let signOut = NSLocalizedString("auth.signOut", value: "Sign Out", comment: "Sign out button")
        static let welcomeMessage = NSLocalizedString("auth.welcome", value: "Welcome to Mango Health", comment: "Welcome message")
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
        static let settings = NSLocalizedString("common.settings", value: "Settings", comment: "Settings button")
        static let cancel = NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel button")
        static let loading = NSLocalizedString("common.loading", value: "Loading...", comment: "Loading message")
        static let confirm = NSLocalizedString("common.confirm", value: "Confirm", comment: "Confirm button")
        static let retry = NSLocalizedString("common.retry", value: "Retry", comment: "Retry button")
        static let openSettings = NSLocalizedString("common.openSettings", value: "Open Settings", comment: "Open settings button")
        static let edit = NSLocalizedString("common.edit", value: "Edit", comment: "Edit button")
        static let share = NSLocalizedString("common.share", value: "Share", comment: "Share button")
        static let viewAll = NSLocalizedString("common.viewAll", value: "View All", comment: "View all button")
        static func viewAllCount(_ count: Int) -> String {
            return NSLocalizedString("common.viewAllCount", value: "View All (\(count) more)", comment: "View all with count")
        }
        static let done = NSLocalizedString("common.done", value: "Done", comment: "Done button")
        static let resend = NSLocalizedString("common.resend", value: "Resend", comment: "Resend button")
        static let analyze = NSLocalizedString("common.analyze", value: "Analyze", comment: "Analyze button")
        static let all = NSLocalizedString("common.all", value: "All", comment: "All button")
        static let filter = NSLocalizedString("common.filter", value: "Filter", comment: "Filter button")
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
    }
    
    // MARK: - Supplements
    struct Supplements {
        static let title = NSLocalizedString("supplements.title", value: "Supplements", comment: "Supplements section title")
        static let supplements = NSLocalizedString("supplements.supplements", value: "Supplements", comment: "Supplements title")
        static let addSupplement = NSLocalizedString("supplements.addSupplement", value: "Add Supplement", comment: "Add supplement button")
        static let noSupplements = NSLocalizedString("supplements.noSupplements", value: "No Supplements", comment: "No supplements empty state title")
        static let noSupplementsMessage = NSLocalizedString("supplements.noSupplementsMessage", value: "You haven't added any supplements yet", comment: "No supplements empty state message")
        static let addFirst = NSLocalizedString("supplements.addFirst", value: "Add First Supplement", comment: "Add first supplement button")
        static func supplementCount(_ count: Int) -> String {
            return NSLocalizedString("supplements.supplementCount", value: "\(count) supplement\(count == 1 ? "" : "s")", comment: "Supplement count")
        
        }
    }
    
    // MARK: - Diet
    struct Diet {
        static let title = NSLocalizedString("diet.title", value: "Diet", comment: "Diet section title")
        static let todaysNutrition = NSLocalizedString("diet.todaysNutrition", value: "Today's Nutrition", comment: "Today's nutrition title")
        static let addDietEntry = NSLocalizedString("diet.addDietEntry", value: "Add Diet Entry", comment: "Add diet entry button")
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
        static let addManually = NSLocalizedString("doctors.addManually", value: "Add Manually", comment: "Add manually button")
        static let totalDoctors = NSLocalizedString("doctors.totalDoctors", value: "%d Doctors", comment: "Total doctors count format")
        static let doctors = NSLocalizedString("doctors.doctors", value: "Doctor(s)", comment: "Pluralized doctors count format")
        static let recentlyAdded = NSLocalizedString("doctors.recentlyAdded", value: "Recently Added", comment: "Recently added doctors section title")
        static let contactImported = NSLocalizedString("doctors.contactImported", value: "Contact Imported", comment: "Contact imported doctors section title")
        static let contactDoctor = NSLocalizedString("doctors.contactDoctor", value: "Contact Doctor", comment: "Contact doctor button")
        static let contactDoctorSubtitle = NSLocalizedString("doctors.contactDoctorSubtitle", value: "Get in touch with your care team", comment: "Contact doctor subtitle")
        static let loadingContacts = NSLocalizedString("doctors.loadingContacts", value: "Loading Contacts...", comment: "Loading contacts label")
        static let importFromContacts = NSLocalizedString("doctors.importFromContacts", value: "Import from Contacts", comment: "Import from contacts button")
        static let searchContacts = NSLocalizedString("doctors.searchContacts", value: "Search Contacts...", comment: "Search contacts label")
        static let selectSpecialty = NSLocalizedString("doctors.selectSpecialty", value: "Select Specialty", comment: "Select specialty placeholder")
        static let specialties = NSLocalizedString("doctors.specialties", value: "Specialties", comment: "Specialties placeholder")
        static let noContacts = NSLocalizedString("doctors.noContacts", value: "No Contacts", comment: "No contacts empty state title")
        static let noContactsMessage = NSLocalizedString("doctors.noContactsMessage", value: "No contacts imported yet", comment: "No contacts empty state message")
        static let withContact = NSLocalizedString("doctors.withContact", value: "With Contact", comment: "With contact button")
    }
    
    // MARK: - Conflicts
    struct Conflicts {
        static let title = NSLocalizedString("conflicts.title", value: "Conflicts", comment: "Conflicts section title")
        static let noConflicts = NSLocalizedString("conflicts.noConflicts", value: "No Conflicts", comment: "No conflicts empty state title")
        static let noConflictsMessage = NSLocalizedString("conflicts.noConflictsMessage", value: "No medication conflicts detected", comment: "No conflicts empty state message")
        static let checkNow = NSLocalizedString("conflicts.checkNow", value: "Check for Conflicts", comment: "Check conflicts button")
        static let checkConflicts = NSLocalizedString("conflicts.checkConflicts", value: "Check Conflicts", comment: "Check conflicts action")
        static let checkConflictsSubtitle = NSLocalizedString("conflicts.checkConflictsSubtitle", value: "AI-powered conflict detection", comment: "Check conflicts subtitle")
        static let analyzingConflicts = NSLocalizedString("conflicts.analyzingConflicts", value: "Analyzing Conflicts...", comment: "Analyzing conflicts label")
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
        static let educationalInfo = NSLocalizedString("conflicts.educationalInfo", value: "Educational Info", comment: "Educational info section title")
        static let medicationCount = NSLocalizedString("conflicts.medicationCount", value: "Medication Count", comment: "Medication count label")
        static let lastChecked = NSLocalizedString("conflicts.lastChecked", value: "Last Checked:", comment: "Last checked label")
        static let criticalConflicts = NSLocalizedString("conflicts.criticalConflicts", value: "Critical Conflicts", comment: "Critical conflicts section title")
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
    }
    
    // MARK: - Empty States
    struct EmptyStates {
        static let noMedications = NSLocalizedString("empty.medications", value: "No Medications", comment: "No medications empty state title")
        static let addFirstMedication = NSLocalizedString("empty.addFirst", value: "Add your first medication to get started", comment: "Add first medication description")
        static let noDoctors = NSLocalizedString("empty.doctors", value: "No Doctors Added", comment: "No doctors empty state")
        static let noConflicts = NSLocalizedString("empty.conflicts", value: "No Conflicts Found", comment: "No conflicts empty state")
    }
    
    // MARK: - Accessibility
    struct Accessibility {
        static let medicationCard = NSLocalizedString("accessibility.medicationCard", value: "Medication card", comment: "Medication card accessibility label")
        static let addButton = NSLocalizedString("accessibility.addButton", value: "Add new item", comment: "Add button accessibility label")
        static let voiceInputButton = NSLocalizedString("accessibility.voiceInput", value: "Voice input", comment: "Voice input button accessibility label")
        static let appLogo = NSLocalizedString("accessibility.appLogo", value: "Mango Health logo", comment: "App logo accessibility label")
        static let signInButton = NSLocalizedString("accessibility.signInButton", value: "Sign in with Google", comment: "Sign in button accessibility label")
        static let signInButtonHint = NSLocalizedString("accessibility.signInButtonHint", value: "Double tap to sign in with your Google account", comment: "Sign in button accessibility hint")
    }
    
    // MARK: - Voice
    struct Voice {
        static let medicationNamePrompt = NSLocalizedString("voice.medicationNamePrompt", value: "Say the medication name", comment: "Voice prompt for medication name")
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
    
    // MARK: - Actions
    struct Actions {
        static let save = NSLocalizedString("actions.save", value: "Save", comment: "Save action")
        static let add = NSLocalizedString("actions.add", value: "Add", comment: "Add action")
        static let delete = NSLocalizedString("actions.delete", value: "Delete", comment: "Delete action")
    }
    
    // MARK: - Alerts
    struct Alerts {
        static let title = NSLocalizedString("alerts.title", value: "Alert", comment: "Alert title")
    }
    
    // MARK: - Forms
    struct Forms {
        static let required = NSLocalizedString("forms.required", value: "Required", comment: "Required field")
    }
    
    // MARK: - Settings
    struct Settings {
        static let title = NSLocalizedString("settings.title", value: "Settings", comment: "Settings title")
        static let privacy = NSLocalizedString("settings.privacy", value: "Privacy", comment: "Privacy settings")
        static let privacySubtitle = NSLocalizedString("settings.privacySubtitle", value: "Manage your privacy preferences", comment: "Privacy settings subtitle")
        static let notificationsSubtitle = NSLocalizedString("settings.notificationsSubtitle", value: "Manage notification preferences", comment: "Notifications settings subtitle")
        static let notifications = NSLocalizedString("settings.notifications", value: "Notifications", comment: "Notifications settings")
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let title = NSLocalizedString("notifications.title", value: "Notifications", comment: "Notifications title")
    }
    
    // MARK: - Profile
    struct Profile {
        static let title = NSLocalizedString("profile.title", value: "Profile", comment: "Profile title")
    }
    
    // MARK: - Errors
    struct Errors {
        static let genericErrorTitle = NSLocalizedString("errors.genericErrorTitle", value: "Error", comment: "Generic error title")
        static let genericErrorMessage = NSLocalizedString("errors.genericErrorMessage", value: "An unexpected error occurred.", comment: "Generic error message")
        static let title = NSLocalizedString("errors.title", value: "Error", comment: "Error title")
    }
}
