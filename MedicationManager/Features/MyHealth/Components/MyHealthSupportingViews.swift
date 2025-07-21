import SwiftUI

// MARK: - Sync Status Header
struct SyncStatusHeader: View {
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let dataSync = DataSyncManager.shared
    
    var body: some View {
        if !dataSync.isOnline || dataSync.syncError != nil {
            HStack(spacing: AppTheme.Spacing.small) {
                statusIcon
                statusText
                Spacer()
                SyncStatusView()
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.warningBackground)
            )
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: dataSync.isOnline ? "exclamationmark.triangle.fill" : "wifi.slash")
            .font(AppTheme.Typography.footnote)
            .foregroundColor(dataSync.isOnline ? AppTheme.Colors.warning : AppTheme.Colors.error)
    }
    
    @ViewBuilder
    private var statusText: some View {
        Text(dataSync.isOnline ? AppStrings.Sync.syncIssues : AppStrings.Sync.offline)
            .font(AppTheme.Typography.caption1)
            .foregroundColor(AppTheme.Colors.secondaryText)
    }
}

// MARK: - My Health Sync Button
struct MyHealthSyncButton: View {
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let dataSync = DataSyncManager.shared
    
    var body: some View {
        Button(action: { 
            Task { 
                do {
                    try await dataSync.forceSyncAll()
                } catch {
                    // Error is already set in dataSync.syncError
                    // UI will update automatically via @Observable
                }
            } 
        }) {
            Image(systemName: dataSync.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.triangle.2.circlepath")
                .font(AppTheme.Typography.callout)
                .rotationEffect(.degrees(dataSync.isSyncing ? 360 : 0))
                .animation(dataSync.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: dataSync.isSyncing)
        }
        .disabled(dataSync.isSyncing)
    }
}