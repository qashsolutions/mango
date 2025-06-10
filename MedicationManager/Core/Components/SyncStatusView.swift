import SwiftUI

struct SyncStatusView: View {
    @StateObject private var dataSync = DataSyncManager.shared
    @State private var showingDetails: Bool = false
    
    var body: some View {
        Button(action: { showingDetails.toggle() }) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: dataSync.getSyncStatus().icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(syncStatusColor)
                    .rotationEffect(.degrees(dataSync.isSyncing ? 360 : 0))
                    .animation(
                        dataSync.isSyncing ?
                            .linear(duration: 1).repeatForever(autoreverses: false) :
                            .default,
                        value: dataSync.isSyncing
                    )
                
                Text(dataSync.getSyncStatus().displayText)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.onSurface.opacity(0.7))
            }
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(AppTheme.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showingDetails) {
            SyncDetailsView()
                .presentationCompactAdaptation(.popover)
        }
    }
    
    // MARK: - Computed Properties
    private var syncStatusColor: Color {
        // Map sync status to existing AppTheme colors using .color instead of .colorKey
        switch dataSync.getSyncStatus().color {
        case "syncOffline":
            return AppTheme.Colors.error
        case "syncInProgress":
            return AppTheme.Colors.primary
        case "syncSuccess":
            return AppTheme.Colors.success
        case "syncPending":
            return AppTheme.Colors.warning
        case "syncError":
            return AppTheme.Colors.error
        default:
            return AppTheme.Colors.onSurface.opacity(0.7)
        }
    }
}

struct SyncDetailsView: View {
    @StateObject private var dataSync = DataSyncManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Current Status
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(AppStrings.Sync.currentStatus)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.onSurface)
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: dataSync.getSyncStatus().icon)
                            .font(.system(size: 16))
                            .foregroundColor(syncStatusColor)
                        
                        Text(dataSync.getSyncStatus().displayText)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.onSurface)
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Last Sync
                if let lastSync = dataSync.lastSyncDate {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(AppStrings.Sync.lastSync)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.onSurface)
                        
                        Text(lastSync.formatted(.relative(presentation: .named)))
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.onSurface.opacity(0.7))
                    }
                    
                    Divider()
                }
                
                // Network Status
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(AppStrings.Sync.networkStatus)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.onSurface)
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: dataSync.isOnline ? "wifi" : "wifi.slash")
                            .font(.system(size: 16))
                            .foregroundColor(dataSync.isOnline ? AppTheme.Colors.success : AppTheme.Colors.error)
                        
                        Text(dataSync.isOnline ? AppStrings.Sync.online : AppStrings.Sync.offline)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.onSurface)
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Actions
                VStack(spacing: AppTheme.Spacing.medium) {
                    Button(action: {
                        Task {
                            await dataSync.forceSyncAll()
                        }
                    }) {
                        Text(AppStrings.Sync.forceSyncNow)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.onPrimary)
                            .frame(height: AppTheme.Layout.buttonHeight)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    .disabled(dataSync.isSyncing || !dataSync.isOnline)
                    
                    if let syncError = dataSync.syncError {
                        VStack(spacing: AppTheme.Spacing.small) {
                            // Error message for user context
                            Text(syncError.localizedDescription)
                                .font(AppTheme.Typography.caption1)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            // Retry button with error context
                            Button(action: {
                                Task {
                                    await dataSync.retryFailedSync()
                                }
                            }) {
                                HStack(spacing: AppTheme.Spacing.extraSmall) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .medium))
                                    Text(AppStrings.Common.retry)
                                        .font(AppTheme.Typography.headline)
                                }
                                .foregroundColor(AppTheme.Colors.error)
                                .frame(height: AppTheme.Layout.buttonHeight)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                        .stroke(AppTheme.Colors.error, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .navigationTitle(AppStrings.Sync.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.ok) {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
    }
    
    // MARK: - Computed Properties
    private var syncStatusColor: Color {
        // Map sync status to existing AppTheme colors using .color instead of .colorKey
        switch dataSync.getSyncStatus().color {
        case "syncOffline":
            return AppTheme.Colors.error
        case "syncInProgress":
            return AppTheme.Colors.primary
        case "syncSuccess":
            return AppTheme.Colors.success
        case "syncPending":
            return AppTheme.Colors.warning
        case "syncError":
            return AppTheme.Colors.error
        default:
            return AppTheme.Colors.onSurface.opacity(0.7)
        }
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.large) {
        SyncStatusView()
        
        SyncDetailsView()
    }
    .padding()
}
