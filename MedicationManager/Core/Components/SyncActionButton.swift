import SwiftUI

struct SyncActionButton: View {
    private let dataSyncManager = DataSyncManager.shared
    @State private var isAnimating = false
    @State private var lastSyncTime: Date?
    @State private var showingSyncStatus = false
    
    var body: some View {
        Button(action: performSync) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: AppIcons.sync)
                    .font(AppTheme.Typography.body)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        isAnimating ? 
                        Animation.linear(duration: 1).repeatForever(autoreverses: false) :
                        .default,
                        value: isAnimating
                    )
                
                if dataSyncManager.isSyncing {
                    Text(AppStrings.Sync.syncing)
                        .font(AppTheme.Typography.caption)
                } else if let lastSync = lastSyncTime {
                    Text(timeAgoString(from: lastSync))
                        .font(AppTheme.Typography.caption)
                }
            }
            .foregroundColor(dataSyncManager.hasPendingChanges ? AppTheme.Colors.warning : AppTheme.Colors.primary)
        }
        .disabled(dataSyncManager.isSyncing)
        .onAppear {
            loadLastSyncTime()
            startAnimationIfNeeded()
        }
        .onChange(of: dataSyncManager.isSyncing) { _, isSyncing in
            isAnimating = isSyncing
            if !isSyncing {
                loadLastSyncTime()
            }
        }
        .popover(isPresented: $showingSyncStatus) {
            SyncStatusPopoverView()
                .frame(width: 300, height: 200)
        }
        .onLongPressGesture {
            showingSyncStatus = true
        }
    }
    
    private func performSync() {
        Task {
            do {
                try await dataSyncManager.syncPendingChanges()
                
                // Show success feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Track analytics
                AnalyticsManager.shared.trackEvent(
                    "manual_sync_triggered",
                    parameters: [
                        "has_pending_changes": dataSyncManager.hasPendingChanges
                    ]
                )
            } catch {
                // Error is already set in dataSyncManager.syncError
                // The UI components observing DataSyncManager will update automatically
                print("Sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadLastSyncTime() {
        lastSyncTime = UserDefaults.standard.object(forKey: "LastSyncTime") as? Date
    }
    
    private func startAnimationIfNeeded() {
        isAnimating = dataSyncManager.isSyncing
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return AppStrings.Sync.justNow
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(format: AppStrings.Sync.minutesAgo, minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return String(format: AppStrings.Sync.hoursAgo, hours)
        } else {
            let days = Int(interval / 86400)
            return String(format: AppStrings.Sync.daysAgo, days)
        }
    }
}

// MARK: - Sync Status Popover
private struct SyncStatusPopoverView: View {
    private let dataSyncManager = DataSyncManager.shared
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.Sync.syncStatus)
                    .font(AppTheme.Typography.headline)
                Spacer()
            }
            
            Divider()
            
            // Sync Status
            HStack {
                Text(AppStrings.Common.status)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                Spacer()
                Text(dataSyncManager.isSyncing ? AppStrings.Sync.syncing : AppStrings.Sync.upToDate)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(dataSyncManager.isSyncing ? AppTheme.Colors.warning : AppTheme.Colors.success)
            }
            
            // Pending Changes
            HStack {
                Text(AppStrings.Sync.pendingChanges)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                Spacer()
                Text(dataSyncManager.hasPendingChanges ? AppStrings.Common.yes : AppStrings.Common.no)
                    .font(AppTheme.Typography.body)
            }
            
            // Last Sync
            if let lastSync = UserDefaults.standard.object(forKey: "LastSyncTime") as? Date {
                HStack {
                    Text(AppStrings.Sync.lastSync)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    Spacer()
                    Text(lastSync, style: .relative)
                        .font(AppTheme.Typography.body)
                }
            }
            
            Spacer()
            
            if dataSyncManager.hasPendingChanges && !dataSyncManager.isSyncing {
                Button(AppStrings.Sync.syncNow) {
                    Task {
                        do {
                            try await dataSyncManager.syncPendingChanges()
                        } catch {
                            // Error is already set in dataSyncManager.syncError
                            // The UI components observing DataSyncManager will update automatically
                            print("Sync failed from popover: \(error.localizedDescription)")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(AppTheme.Spacing.medium)
    }
}

#Preview {
    HStack {
        SyncActionButton()
            .padding()
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}
