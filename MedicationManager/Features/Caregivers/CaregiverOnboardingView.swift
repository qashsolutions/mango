import SwiftUI

@MainActor
struct CaregiverOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var caregiverName = ""
    @State private var caregiverRelationship = CaregiverRelationship.family
    @State private var accessLevel = CaregiverAccessLevel.viewOnly
    @State private var showingQRCode = false
    @State private var invitationCode = ""
    
    private let steps = 3
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                    .font(AppTheme.Typography.body)
                    
                    Spacer()
                    
                    // Progress indicator
                    HStack(spacing: AppTheme.Spacing.small) {
                        ForEach(0..<steps, id: \.self) { step in
                            Circle()
                                .fill(currentStep >= step ? AppTheme.Colors.primary : AppTheme.Colors.divider)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentStep)
                        }
                    }
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Color.clear
                        .frame(width: 60)
                }
                .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.extraLarge) {
                        // Step content
                        switch currentStep {
                        case 0:
                            welcomeStep
                        case 1:
                            setupStep
                        case 2:
                            invitationStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Navigation buttons
                HStack(spacing: AppTheme.Spacing.medium) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text(AppStrings.Navigation.back)
                            }
                            .font(AppTheme.Typography.body)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(action: nextStepOrComplete) {
                        HStack {
                            Text(currentStep == steps - 1 ? 
                                 NSLocalizedString("caregiver.onboarding.sendInvitation", value: "Send Invitation", comment: "Send invitation") :
                                 AppStrings.Common.next)
                            if currentStep < steps - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.vertical, AppTheme.Spacing.medium)
                    }
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .disabled(currentStep == 1 && caregiverName.isEmpty)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeInvitationView(invitationCode: invitationCode)
        }
        .onAppear {
            AnalyticsManager.shared.trackScreenViewed("caregiver_onboarding_start")
        }
    }
    
    // MARK: - Step Views
    
    @ViewBuilder
    private var welcomeStep: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: AppIcons.caregivers)
                .font(.system(size: 80))
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.bottom)
            
            Text(NSLocalizedString("caregiver.onboarding.welcome.title", value: "Invite a Caregiver", comment: "Welcome title"))
                .font(AppTheme.Typography.largeTitle)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("caregiver.onboarding.welcome.description", value: "Caregivers can help you manage your medications and stay on track with your health goals", comment: "Welcome description"))
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                FeatureRow(
                    icon: "eye",
                    title: NSLocalizedString("caregiver.onboarding.feature1.title", value: "View Medications", comment: "Feature 1 title"),
                    description: NSLocalizedString("caregiver.onboarding.feature1.description", value: "Caregivers can see your medication schedule", comment: "Feature 1 description")
                )
                
                FeatureRow(
                    icon: "bell",
                    title: NSLocalizedString("caregiver.onboarding.feature2.title", value: "Receive Alerts", comment: "Feature 2 title"),
                    description: NSLocalizedString("caregiver.onboarding.feature2.description", value: "Get notified about missed doses or conflicts", comment: "Feature 2 description")
                )
                
                FeatureRow(
                    icon: "shield",
                    title: NSLocalizedString("caregiver.onboarding.feature3.title", value: "Secure Access", comment: "Feature 3 title"),
                    description: NSLocalizedString("caregiver.onboarding.feature3.description", value: "You control what caregivers can see and do", comment: "Feature 3 description")
                )
            }
            .padding(.top)
        }
    }
    
    @ViewBuilder
    private var setupStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.extraLarge) {
            Text(NSLocalizedString("caregiver.onboarding.setup.title", value: "Caregiver Details", comment: "Setup title"))
                .font(AppTheme.Typography.title)
            
            // Name input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("caregiver.onboarding.setup.name", value: "Caregiver Name", comment: "Name label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(
                    NSLocalizedString("caregiver.onboarding.setup.namePlaceholder", value: "Enter name", comment: "Name placeholder"),
                    text: $caregiverName
                )
                .textFieldStyle(.roundedBorder)
            }
            
            // Relationship picker
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("caregiver.onboarding.setup.relationship", value: "Relationship", comment: "Relationship label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Picker("", selection: $caregiverRelationship) {
                    ForEach(CaregiverRelationship.allCases, id: \.self) { relationship in
                        Text(relationship.displayName).tag(relationship)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Access level
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("caregiver.onboarding.setup.accessLevel", value: "Access Level", comment: "Access level label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                ForEach(CaregiverAccessLevel.allCases, id: \.self) { level in
                    AccessLevelRow(
                        level: level,
                        isSelected: accessLevel == level,
                        onSelect: { accessLevel = level }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var invitationStep: some View {
        VStack(spacing: AppTheme.Spacing.extraLarge) {
            Image(systemName: AppIcons.invitation)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(NSLocalizedString("caregiver.onboarding.invitation.title", value: "Ready to Send Invitation", comment: "Invitation title"))
                .font(AppTheme.Typography.title)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                SummaryRow(
                    label: NSLocalizedString("caregiver.onboarding.summary.name", value: "Name", comment: "Name label"),
                    value: caregiverName
                )
                
                SummaryRow(
                    label: NSLocalizedString("caregiver.onboarding.summary.relationship", value: "Relationship", comment: "Relationship label"),
                    value: caregiverRelationship.displayName
                )
                
                SummaryRow(
                    label: NSLocalizedString("caregiver.onboarding.summary.access", value: "Access", comment: "Access label"),
                    value: accessLevel.displayName
                )
            }
            .padding()
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            
            Text(NSLocalizedString("caregiver.onboarding.invitation.description", value: "We'll generate a secure invitation code that your caregiver can use to connect to your account", comment: "Invitation description"))
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Actions
    
    private func previousStep() {
        withAnimation {
            currentStep = max(0, currentStep - 1)
        }
    }
    
    private func nextStepOrComplete() {
        if currentStep < steps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            sendInvitation()
        }
    }
    
    private func sendInvitation() {
        // Generate invitation code
        invitationCode = generateInvitationCode()
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(
            "caregiver_invitation_sent",
            parameters: [
                "relationship": caregiverRelationship.rawValue,
                "access_level": accessLevel.rawValue
            ]
        )
        
        // Show QR code
        showingQRCode = true
    }
    
    private func generateInvitationCode() -> String {
        // In production, this would be a secure server-generated code
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

private struct AccessLevelRow: View {
    let level: CaregiverAccessLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(level.displayName)
                        .font(AppTheme.Typography.body)
                    Text(level.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.divider)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.body)
        }
    }
}

private struct QRCodeInvitationView: View {
    let invitationCode: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.extraLarge) {
                Text(NSLocalizedString("caregiver.invitation.success.title", value: "Invitation Created!", comment: "Success title"))
                    .font(AppTheme.Typography.largeTitle)
                
                // QR Code placeholder
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.secondaryBackground)
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode")
                                .font(.system(size: 80))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            Text("QR Code")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    )
                
                Text(NSLocalizedString("caregiver.invitation.code.label", value: "Invitation Code", comment: "Code label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text(invitationCode)
                    .font(.system(.largeTitle, design: .monospaced))
                    .padding()
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.small)
                
                Button(action: shareInvitation) {
                    HStack {
                        Image(systemName: AppIcons.share)
                        Text(AppStrings.Common.share)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle(NSLocalizedString("caregiver.invitation.title", value: "Share Invitation", comment: "Share invitation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareInvitation() {
        let message = String(
            format: NSLocalizedString("caregiver.invitation.shareMessage", value: "Join as my caregiver on Mango Health with code: %@", comment: "Share message"),
            invitationCode
        )
        
        let activityController = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        Task { @MainActor in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityController, animated: true)
            }
        }
    }
}

// MARK: - Enums

enum CaregiverRelationship: String, CaseIterable {
    case family = "family"
    case friend = "friend"
    case professional = "professional"
    
    var displayName: String {
        switch self {
        case .family:
            return NSLocalizedString("caregiver.relationship.family", value: "Family", comment: "Family relationship")
        case .friend:
            return NSLocalizedString("caregiver.relationship.friend", value: "Friend", comment: "Friend relationship")
        case .professional:
            return NSLocalizedString("caregiver.relationship.professional", value: "Healthcare Professional", comment: "Professional relationship")
        }
    }
}

enum CaregiverAccessLevel: String, CaseIterable {
    case viewOnly = "view_only"
    case viewAndRemind = "view_remind"
    case fullAccess = "full_access"
    
    var displayName: String {
        switch self {
        case .viewOnly:
            return NSLocalizedString("caregiver.access.viewOnly", value: "View Only", comment: "View only access")
        case .viewAndRemind:
            return NSLocalizedString("caregiver.access.viewRemind", value: "View & Remind", comment: "View and remind access")
        case .fullAccess:
            return NSLocalizedString("caregiver.access.full", value: "Full Access", comment: "Full access")
        }
    }
    
    var description: String {
        switch self {
        case .viewOnly:
            return NSLocalizedString("caregiver.access.viewOnly.description", value: "Can view medications and schedules", comment: "View only description")
        case .viewAndRemind:
            return NSLocalizedString("caregiver.access.viewRemind.description", value: "Can view and send reminders", comment: "View and remind description")
        case .fullAccess:
            return NSLocalizedString("caregiver.access.full.description", value: "Can view, remind, and manage medications", comment: "Full access description")
        }
    }
}

#Preview {
    CaregiverOnboardingView()
}