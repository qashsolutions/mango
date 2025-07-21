import SwiftUI

struct GroupsView: View {
    @State private var viewModel = GroupsViewModel()
    // Use singleton directly - it manages its own lifecycle with @Observable
    private let navigationManager = NavigationManager.shared
    @State private var showingSettings: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.large) {
                    // Caregiver Access Status
                    CaregiverAccessStatusCard(
                        accessControl: viewModel.accessControl,
                        onToggleAccess: {
                            Task {
                                await viewModel.toggleCaregiverAccess()
                            }
                        },
                        onManageSettings: {
                            navigationManager.navigate(to: .caregiverSettings)
                        }
                    )
                    
                    if viewModel.accessControl.caregiverAccess.enabled {
                        // Active Caregivers Section
                        if !viewModel.accessControl.caregiverAccess.activeCaregivers.isEmpty {
                            ActiveCaregiversSection(
                                caregivers: viewModel.accessControl.caregiverAccess.activeCaregivers,
                                onCaregiverTap: { caregiver in
                                    // Navigate to caregiver detail
                                },
                                onEditPermissions: { caregiver in
                                    Task {
                                        await viewModel.editCaregiverPermissions(caregiver)
                                    }
                                },
                                onRemoveCaregiver: { caregiver in
                                    Task {
                                        await viewModel.removeCaregiver(caregiver)
                                    }
                                },
                                onAddCaregiver: {
                                    navigationManager.presentSheet(.inviteCaregiver)
                                }
                            )
                        }
                        
                        // Pending Invitations Section
                        if !viewModel.accessControl.pendingInvitations.isEmpty {
                            PendingInvitationsSection(
                                invitations: viewModel.accessControl.pendingInvitations,
                                onResendInvitation: { invitation in
                                    Task {
                                        await viewModel.resendInvitation(invitation)
                                    }
                                },
                                onCancelInvitation: { invitation in
                                    Task {
                                        await viewModel.cancelInvitation(invitation)
                                    }
                                },
                                onAddInvitation: {
                                    navigationManager.presentSheet(.inviteCaregiver)
                                }
                            )
                        }
                        
                        // Add Caregiver Section
                        AddCaregiverSection {
                            navigationManager.presentSheet(.inviteCaregiver)
                        }
                        
                        // Access Control Information
                        AccessControlInfoSection(
                            onAddAccessControl: {
                                navigationManager.navigate(to: .caregiverSettings)
                            }
                        )
                    } else {
                        // Caregiver Access Disabled
                        CaregiverAccessDisabledSection(
                            onEnable: {
                                Task {
                                    await viewModel.enableCaregiverAccess()
                                }
                            },
                            onAddAccessControl: {
                                navigationManager.navigate(to: .caregiverSettings)
                            }
                        )
                    }
                    
                    // Family Settings Section
                    FamilySettingsSection(
                        onPrivacySettings: {
                            navigationManager.navigate(to: .privacySettings)
                        },
                        onNotificationSettings: {
                            navigationManager.navigate(to: .notificationSettings)
                        },
                        onAddSetting: {
                            navigationManager.navigate(to: .appSettings)
                        }
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationTitle(AppStrings.Tabs.groups)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        SyncActionButton()
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: AppIcons.settings)
                                .font(AppTheme.Typography.callout)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                GroupSettingsView()
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.error.map { AlertItem.fromError($0) } },
                set: { _ in viewModel.clearError() }
            )) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text(AppStrings.Common.ok))
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Caregiver Access Status Card
struct CaregiverAccessStatusCard: View {
    let accessControl: AccessControl
    let onToggleAccess: () -> Void
    let onManageSettings: () -> Void
    
    private var summary: CaregiverAccessSummary {
        accessControl.getCaregiverSummary()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(AppStrings.Caregivers.caregiverAccess)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(summary.statusText)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                Toggle(isOn: Binding(
                    get: { summary.isEnabled },
                    set: { _ in onToggleAccess() }
                )) {
                    EmptyView()
                }
                .labelsHidden()
            }
            
            if summary.isEnabled {
                Divider()
                
                // Statistics
                HStack(spacing: AppTheme.Spacing.large) {
                    StatisticView(
                        title: AppStrings.Caregivers.activeCaregivers,
                        value: "\(summary.activeCaregivers)",
                        color: AppTheme.Colors.success
                    )
                    
                    StatisticView(
                        title: AppStrings.Caregivers.pendingInvitations,
                        value: "\(summary.pendingInvitations)",
                        color: AppTheme.Colors.warning
                    )
                    
                    StatisticView(
                        title: AppStrings.Caregivers.availableSlots,
                        value: "\(summary.availableSlots)",
                        color: AppTheme.Colors.primary
                    )
                }
                
                // Quick Actions
                HStack(spacing: AppTheme.Spacing.medium) {
                    ActionButton(
                        title: AppStrings.Caregivers.managePermissions,
                        action: onManageSettings,
                        style: .outline
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(
            color: AppTheme.Colors.shadow,
            radius: AppTheme.Shadows.cardRadius,
            x: AppTheme.Shadows.cardOffset.x,
            y: AppTheme.Shadows.cardOffset.y
        )
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraSmall) {
            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Caregivers Section
struct ActiveCaregiversSection: View {
    let caregivers: [CaregiverInfo]
    let onCaregiverTap: (CaregiverInfo) -> Void
    let onEditPermissions: (CaregiverInfo) -> Void
    let onRemoveCaregiver: (CaregiverInfo) -> Void
    let onAddCaregiver: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            GroupsSectionHeader(
                title: AppStrings.Caregivers.activeCaregivers,
                subtitle: AppStrings.Caregivers.caregiverCount(caregivers.count),
                onAdd: onAddCaregiver
            )
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(caregivers, id: \.id) { caregiver in
                    CaregiverCard(
                        caregiver: caregiver,
                        onTap: { onCaregiverTap(caregiver) },
                        onEditPermissions: { onEditPermissions(caregiver) },
                        onRemove: { onRemoveCaregiver(caregiver) }
                    )
                }
            }
        }
    }
}

// MARK: - Caregiver Card
struct CaregiverCard: View {
    let caregiver: CaregiverInfo
    let onTap: () -> Void
    let onEditPermissions: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Caregiver Avatar
                Text(caregiver.initials)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.onPrimary)
                    .frame(width: AppTheme.Sizing.iconLarge, height: AppTheme.Sizing.iconLarge)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.extraLarge)
                
                // Caregiver Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(caregiver.displayName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text(caregiver.caregiverEmail)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: AppTheme.Spacing.extraSmall) {
                        Text(caregiver.permissionSummary)
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        if caregiver.notificationsEnabled {
                            Image(systemName: AppIcons.notifications)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                    }
                }
                
                Spacer()
                
                // Status Indicator
                VStack(spacing: AppTheme.Spacing.extraSmall) {
                    Circle()
                        .fill(caregiver.isActive ? AppTheme.Colors.success : AppTheme.Colors.inactive)
                        .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
                    
                    Text(AppStrings.Caregivers.grantedDate(caregiver.grantedAt))
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onEditPermissions) {
                Label(AppStrings.Caregivers.editPermissions, systemImage: AppIcons.permissions)
            }
            
            Button(action: {
                // Toggle notifications
            }) {
                Label(
                    caregiver.notificationsEnabled ?
                        AppStrings.Caregivers.disableNotifications :
                        AppStrings.Caregivers.enableNotifications,
                    systemImage: AppIcons.notifications
                )
            }
            
            Button(role: .destructive, action: onRemove) {
                Label(AppStrings.Caregivers.removeCaregiver, systemImage: AppIcons.remove)
            }
        }
    }
}

// MARK: - Pending Invitations Section
struct PendingInvitationsSection: View {
    let invitations: [CaregiverInvitation]
    let onResendInvitation: (CaregiverInvitation) -> Void
    let onCancelInvitation: (CaregiverInvitation) -> Void
    let onAddInvitation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            GroupsSectionHeader(
                title: AppStrings.Caregivers.pendingInvitations,
                subtitle: AppStrings.Caregivers.invitationCount(invitations.count),
                onAdd: onAddInvitation
            )
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(invitations, id: \.id) { invitation in
                    InvitationCard(
                        invitation: invitation,
                        onResend: { onResendInvitation(invitation) },
                        onCancel: { onCancelInvitation(invitation) }
                    )
                }
            }
        }
    }
}

// MARK: - Invitation Card
struct InvitationCard: View {
    let invitation: CaregiverInvitation
    let onResend: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Invitation Icon
            Image(systemName: AppIcons.invitation)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.warning)
                .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                .background(AppTheme.Colors.warningBackground)
                .cornerRadius(AppTheme.CornerRadius.extraLarge)
            
            // Invitation Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(invitation.caregiverEmail)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .lineLimit(1)
                
                Text(AppStrings.Caregivers.invitationCode(invitation.invitationCode))
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(AppStrings.Caregivers.expires(invitation.expiresAt))
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(invitation.isExpired ? AppTheme.Colors.error : AppTheme.Colors.secondaryText)
                    
                    if invitation.isExpired {
                        Text(AppStrings.Caregivers.expired)
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.error)
                            .padding(.horizontal, AppTheme.Spacing.extraSmall)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.errorBackground)
                            .cornerRadius(AppTheme.CornerRadius.extraSmall)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: AppTheme.Spacing.extraSmall) {
                CompactActionButton(
                    title: AppStrings.Common.resend,
                    action: onResend,
                    style: .outline
                )
                
                CompactActionButton(
                    title: AppStrings.Common.cancel,
                    action: onCancel,
                    style: .destructive
                )
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(invitation.isExpired ? AppTheme.Colors.error : AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Add Caregiver Section
struct AddCaregiverSection: View {
    let onAddCaregiver: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            GroupsSectionHeader(
                title: AppStrings.Caregivers.addCaregiver,
                subtitle: AppStrings.Caregivers.addCaregiverSubtitle,
                onAdd: onAddCaregiver
            )
            
            Button(action: onAddCaregiver) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: AppIcons.plus)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                        .background(AppTheme.Colors.primaryBackground)
                        .cornerRadius(AppTheme.CornerRadius.extraLarge)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                        Text(AppStrings.Caregivers.inviteNewCaregiver)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Text(AppStrings.Caregivers.inviteDescription)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.primary.opacity(AppTheme.Opacity.low), lineWidth: 1.5)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Access Control Info Section
struct AccessControlInfoSection: View {
    let onAddAccessControl: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            GroupsSectionHeader(
                title: AppStrings.Caregivers.howItWorks,
                subtitle: AppStrings.Caregivers.howItWorksSubtitle,
                onAdd: onAddAccessControl
            )
            
            VStack(spacing: AppTheme.Spacing.small) {
                InfoCard(
                    icon: AppIcons.security,
                    title: AppStrings.Caregivers.secureAccess,
                    description: AppStrings.Caregivers.secureAccessDescription
                )
                
                InfoCard(
                    icon: AppIcons.permissions,
                    title: AppStrings.Caregivers.granularPermissions,
                    description: AppStrings.Caregivers.granularPermissionsDescription
                )
                
                InfoCard(
                    icon: AppIcons.privacy,
                    title: AppStrings.Caregivers.privacyFirst,
                    description: AppStrings.Caregivers.privacyFirstDescription
                )
            }
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(description)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.infoBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Caregiver Access Disabled Section
struct CaregiverAccessDisabledSection: View {
    let onEnable: () -> Void
    let onAddAccessControl: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            EmptyStateView(
                icon: AppIcons.caregivers,
                title: AppStrings.Caregivers.accessDisabled,
                message: AppStrings.Caregivers.accessDisabledMessage,
                actionTitle: AppStrings.Caregivers.enableAccess,
                action: onEnable
            )
            
            AccessControlInfoSection(
                onAddAccessControl: onAddAccessControl
            )
        }
    }
}

// MARK: - Family Settings Section
struct FamilySettingsSection: View {
    let onPrivacySettings: () -> Void
    let onNotificationSettings: () -> Void
    let onAddSetting: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            GroupsSectionHeader(
                title: AppStrings.Groups.familySettings,
                subtitle: AppStrings.Groups.familySettingsSubtitle,
                onAdd: onAddSetting
            )
            
            VStack(spacing: AppTheme.Spacing.small) {
                SettingsRow(
                    icon: AppIcons.privacy,
                    title: AppStrings.Settings.privacy,
                    subtitle: AppStrings.Settings.privacySubtitle,
                    action: onPrivacySettings
                )
                
                SettingsRow(
                    icon: AppIcons.notifications,
                    title: AppStrings.Settings.notifications,
                    subtitle: AppStrings.Settings.notificationsSubtitle,
                    action: onNotificationSettings
                )
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                    .background(AppTheme.Colors.primaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Group Settings View
struct GroupSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(AppStrings.UI.groupSettings)
                    .font(AppTheme.Typography.title2)
                    .padding()
                
                Spacer()
            }
            .navigationTitle(AppStrings.Groups.settings)
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
}

// MARK: - Helper Components
struct GroupsSectionHeader: View {
    let title: String
    let subtitle: String
    let onAdd: (() -> Void)?
    
    init(title: String, subtitle: String, onAdd: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.onAdd = onAdd
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            if let onAdd = onAdd {
                Button(action: onAdd) {
                    Image(systemName: AppIcons.plus)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }
}

#Preview {
    GroupsView()
}
