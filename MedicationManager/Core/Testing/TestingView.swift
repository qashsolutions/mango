import SwiftUI

#if DEBUG
struct TestingView: View {
    @StateObject private var testRunner = SyncTestRunner()
    @State private var showingResults: Bool = false
    @State private var selectedConfiguration: TestConfiguration = .standard
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Test Status Header
                TestStatusHeader(
                    isRunning: testRunner.isRunning,
                    currentTest: testRunner.currentTest,
                    testCount: testRunner.testResults.count
                )
                
                if testRunner.isRunning {
                    // Running Tests View
                    RunningTestsView(currentTest: testRunner.currentTest)
                } else if testRunner.testResults.isEmpty {
                    // No Tests Run Yet
                    NoTestsView {
                        Task {
                            await testRunner.runAllTests()
                        }
                    }
                } else {
                    // Test Results View
                    TestResultsView(
                        testResults: testRunner.testResults,
                        onShowDetails: { showingResults = true },
                        onRunAgain: {
                            Task {
                                await testRunner.runAllTests()
                            }
                        }
                    )
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .navigationTitle("Sync Testing")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingResults) {
                TestResultsDetailView(testResults: testRunner.testResults)
            }
        }
    }
}

// MARK: - Test Status Header
struct TestStatusHeader: View {
    let isRunning: Bool
    let currentTest: String
    let testCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text("Sync Test Suite")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    if isRunning {
                        Text("Running tests...")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.warning)
                    } else if testCount > 0 {
                        Text("Last run: \(testCount) tests")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    } else {
                        Text("No tests run yet")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                if isRunning {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                }
            }
            
            if isRunning && !currentTest.isEmpty {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text(currentTest)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, AppTheme.Spacing.extraSmall)
                .background(AppTheme.Colors.primaryBackground)
                .cornerRadius(AppTheme.CornerRadius.small)
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

// MARK: - Running Tests View
struct RunningTestsView: View {
    let currentTest: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.Colors.primary)
                    .rotationEffect(.degrees(45))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: true)
                
                Text("Running Tests")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                if !currentTest.isEmpty {
                    Text(currentTest)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Text("Testing offline storage, sync functionality, and data integrity...")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.large)
            }
            
            Spacer()
        }
    }
}

// MARK: - No Tests View
struct NoTestsView: View {
    let onRunTests: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("Sync Testing")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Test the offline storage and sync functionality to ensure data integrity across online and offline states.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.large)
                
                VStack(spacing: AppTheme.Spacing.small) {
                    TestCapabilityRow(icon: "internaldrive", title: "Offline Storage", description: "Core Data persistence")
                    TestCapabilityRow(icon: "icloud", title: "Cloud Sync", description: "Firebase synchronization")
                    TestCapabilityRow(icon: "arrow.triangle.2.circlepath", title: "Conflict Resolution", description: "Data merge strategies")
                    TestCapabilityRow(icon: "network", title: "Network Handling", description: "Online/offline transitions")
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.infoBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            ActionButton(
                title: "Run All Tests",
                action: onRunTests,
                style: .primary
            )
            
            Spacer()
        }
    }
}

struct TestCapabilityRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(description)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Test Results View
struct TestResultsView: View {
    let testResults: [TestResult]
    let onShowDetails: () -> Void
    let onRunAgain: () -> Void
    
    private var summary: TestSummary {
        TestSummary(results: testResults)
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Summary Card
            TestSummaryCard(summary: summary)
            
            // Quick Results
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Test Categories")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(summary.categoryResults, id: \.category) { categoryResult in
                        TestCategoryRow(categoryResult: categoryResult)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: AppTheme.Spacing.medium) {
                ActionButton(
                    title: "View Details",
                    action: onShowDetails,
                    style: .outline
                )
                
                ActionButton(
                    title: "Run Again",
                    action: onRunAgain,
                    style: .primary
                )
            }
        }
    }
}

// MARK: - Test Summary Card
struct TestSummaryCard: View {
    let summary: TestSummary
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text("Test Results")
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(summary.overallStatus)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(summary.successRate == 1.0 ? AppTheme.Colors.success : AppTheme.Colors.warning)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
                    Text("\(Int(summary.successRate * 100))%")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(summary.successRate >= 0.8 ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    Text("Success Rate")
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            
            // Test Statistics
            HStack(spacing: AppTheme.Spacing.large) {
                TestStatistic(title: "Passed", value: "\(summary.passedCount)", color: AppTheme.Colors.success)
                TestStatistic(title: "Failed", value: "\(summary.failedCount)", color: AppTheme.Colors.error)
                TestStatistic(title: "Total", value: "\(summary.totalCount)", color: AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(summary.successRate == 1.0 ? AppTheme.Colors.successBackground : AppTheme.Colors.warningBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(summary.successRate == 1.0 ? AppTheme.Colors.success : AppTheme.Colors.warning, lineWidth: 1)
        )
    }
}

struct TestStatistic: View {
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
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Test Category Row
struct TestCategoryRow: View {
    let categoryResult: CategoryResult
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: categoryResult.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(categoryResult.success ? AppTheme.Colors.success : AppTheme.Colors.error)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(categoryResult.category)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("\(categoryResult.passedCount)/\(categoryResult.totalCount) tests passed")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            Text("\(Int(categoryResult.successRate * 100))%")
                .font(AppTheme.Typography.caption1)
                .foregroundColor(categoryResult.success ? AppTheme.Colors.success : AppTheme.Colors.error)
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, AppTheme.Spacing.extraSmall)
                .background(categoryResult.success ? AppTheme.Colors.successBackground : AppTheme.Colors.errorBackground)
                .cornerRadius(AppTheme.CornerRadius.small)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Test Results Detail View
struct TestResultsDetailView: View {
    let testResults: [TestResult]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Dictionary(grouping: testResults) { $0.category }.keys.sorted(), id: \.self) { category in
                    Section(category) {
                        ForEach(testResults.filter { $0.category == category }) { result in
                            TestResultRow(result: result)
                        }
                    }
                }
            }
            .navigationTitle("Test Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareTestResults()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func shareTestResults() {
        let testRunner = SyncTestRunner()
        let report = testRunner.exportTestResults()
        
        let activityVC = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: result.statusIcon)
                .font(.system(size: 16))
                .foregroundColor(result.success ? AppTheme.Colors.success : AppTheme.Colors.error)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(result.operation)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(result.message)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(result.timestamp.formatted(.dateTime.hour().minute()))
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.tertiaryText)
        }
        .padding(.vertical, AppTheme.Spacing.extraSmall)
    }
}

// MARK: - Supporting Models
struct TestSummary {
    let results: [TestResult]
    
    var totalCount: Int { results.count }
    var passedCount: Int { results.filter { $0.success }.count }
    var failedCount: Int { totalCount - passedCount }
    var successRate: Double { totalCount > 0 ? Double(passedCount) / Double(totalCount) : 0.0 }
    
    var overallStatus: String {
        if successRate == 1.0 {
            return "All tests passed"
        } else if successRate >= 0.8 {
            return "Most tests passed"
        } else {
            return "Some tests failed"
        }
    }
    
    var categoryResults: [CategoryResult] {
        let grouped = Dictionary(grouping: results) { $0.category }
        return grouped.map { category, results in
            CategoryResult(
                category: category,
                results: results
            )
        }.sorted { $0.category < $1.category }
    }
}

struct CategoryResult {
    let category: String
    let results: [TestResult]
    
    var totalCount: Int { results.count }
    var passedCount: Int { results.filter { $0.success }.count }
    var successRate: Double { totalCount > 0 ? Double(passedCount) / Double(totalCount) : 0.0 }
    var success: Bool { successRate == 1.0 }
}

#Preview {
    TestingView()
}
#endif
