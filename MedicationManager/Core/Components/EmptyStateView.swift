import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .light))
                    .foregroundColor(AppTheme.Colors.onBackground)
                
                VStack(spacing: AppTheme.Spacing.small) {
                    Text(title)
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.onBackground)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.onBackground)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.onPrimary)
                        .frame(height: AppTheme.Layout.buttonHeight)
                        .frame(maxWidth: actionButtonMaxWidth)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    private var iconSize: CGFloat {
        AppTheme.Spacing.xxLarge
    }
    
    private var actionButtonMaxWidth: CGFloat {
        AppTheme.Layout.inputFieldMaxWidth
    }
}

// MARK: - Specialized Empty States
struct MedicationEmptyState: View {
    let onAddMedication: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.medicationEmpty,
            title: AppStrings.Medications.noMedications,
            message: AppStrings.Medications.noMedicationsMessage,
            actionTitle: AppStrings.Medications.addFirst,
            action: onAddMedication
        )
    }
}

struct SupplementEmptyState: View {
    let onAddSupplement: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.supplement,
            title: AppStrings.Supplements.noSupplements,
            message: AppStrings.Supplements.noSupplementsMessage,
            actionTitle: AppStrings.Supplements.addFirst,
            action: onAddSupplement
        )
    }
}

struct DietEmptyState: View {
    let onAddEntry: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.diet,
            title: AppStrings.Diet.noEntries,
            message: AppStrings.Diet.noEntriesMessage,
            actionTitle: AppStrings.Diet.addFirst,
            action: onAddEntry
        )
    }
}

struct DoctorEmptyState: View {
    let onAddDoctor: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.doctorEmpty,
            title: AppStrings.Doctors.noDoctors,
            message: AppStrings.Doctors.noDoctorsMessage,
            actionTitle: AppStrings.Doctors.addFirst,
            action: onAddDoctor
        )
    }
}

struct ConflictEmptyState: View {
    let onCheckConflicts: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.warning,
            title: AppStrings.Conflicts.noConflicts,
            message: AppStrings.Conflicts.noConflictsMessage,
            actionTitle: AppStrings.Conflicts.checkNow,
            action: onCheckConflicts
        )
    }
}

struct CaregiverEmptyState: View {
    let onInviteCaregiver: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.groupEmpty,
            title: AppStrings.Caregivers.noCaregivers,
            message: AppStrings.Caregivers.noCaregiversMessage,
            actionTitle: AppStrings.Caregivers.inviteFirst,
            action: onInviteCaregiver
        )
    }
}

// MARK: - Search Empty State
struct SearchEmptyState: View {
    let searchTerm: String
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.search,
            title: AppStrings.Search.noResults,
            message: AppStrings.Search.noResultsMessage(searchTerm)
        )
    }
}

// MARK: - Network Error State
struct NetworkErrorState: View {
    let onRetry: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.networkError,
            title: AppStrings.Network.connectionError,
            message: AppStrings.Network.connectionErrorMessage,
            actionTitle: AppStrings.Common.retry,
            action: onRetry
        )
    }
}

// MARK: - Sync Error State
struct SyncErrorState: View {
    let onRetry: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.syncError,
            title: AppStrings.Sync.errorTitle,
            message: AppStrings.Sync.errorMessage,
            actionTitle: AppStrings.Common.retry,
            action: onRetry
        )
    }
}

// MARK: - Loading State
struct LoadingState: View {
    let message: String
    
    init(message: String = AppStrings.Common.loading) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
            
            Text(message)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.onBackground)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compact Empty States
struct CompactEmptyState: View {
    let icon: String
    let message: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.onBackground)
            
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.onBackground)
                .multilineTextAlignment(.leading)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Contextual Empty States
struct OfflineEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: AppIcons.offline,
            title: AppStrings.Offline.title,
            message: AppStrings.Offline.message
        )
    }
}

struct PermissionEmptyState: View {
    let permissionType: String
    let onOpenSettings: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: AppIcons.permission,
            title: AppStrings.Permissions.title(permissionType),
            message: AppStrings.Permissions.message(permissionType),
            actionTitle: AppStrings.Common.openSettings,
            action: onOpenSettings
        )
    }
}

struct MaintenanceEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: AppIcons.maintenance,
            title: AppStrings.Maintenance.title,
            message: AppStrings.Maintenance.message
        )
    }
}

// MARK: - Animation Wrapper
struct AnimatedEmptyState<Content: View>: View {
    let content: Content
    @State private var isVisible: Bool = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.easeOut(duration: 0.6), value: isVisible)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Usage Examples
#Preview {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.extraLarge) {
            MedicationEmptyState(onAddMedication: {})
            
            Divider()
            
            SearchEmptyState(searchTerm: "aspirin")
                
                Divider()
                
                NetworkErrorState(onRetry: {})
                
                Divider()
                
                LoadingState()
                
                Divider()
                
                CompactEmptyState(
                    icon: AppIcons.medicationEmpty,
                    message: "No medications scheduled for today"
                )
            }
        }
        .padding()
        .background(AppTheme.Colors.background)
    }

