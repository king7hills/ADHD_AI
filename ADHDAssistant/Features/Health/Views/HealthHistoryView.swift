//
//  HealthHistoryView.swift
//  ADHDAssistant
//
//  Historical view and analytics for health metrics
//

import SwiftUI

struct HealthHistoryView: View {
    @ObservedObject var viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDateRange: DateRange = .week
    @State private var selectedMetricType: HealthMetricType = .bloodSugar

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Date range picker
                    dateRangePicker

                    // Metric type selector
                    metricTypeSelector

                    // Average readings card
                    averageReadingsCard

                    // Chart visualization (placeholder)
                    chartSection

                    // Detailed history list
                    historyListSection

                    // Export option (placeholder)
                    exportSection
                }
                .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                .padding(.vertical, AppSpacing.screenVerticalPadding)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Health History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Time Period")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: AppSpacing.sm) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    DateRangeButton(
                        range: range,
                        isSelected: selectedDateRange == range,
                        action: {
                            selectedDateRange = range
                            HapticManager.shared.impact(.light)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Metric Type Selector

    private var metricTypeSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Metric")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    MetricTypeChip(
                        type: .bloodSugar,
                        isSelected: selectedMetricType == .bloodSugar,
                        action: { selectedMetricType = .bloodSugar }
                    )

                    MetricTypeChip(
                        type: .medication,
                        isSelected: selectedMetricType == .medication,
                        action: { selectedMetricType = .medication }
                    )

                    MetricTypeChip(
                        type: .meal,
                        isSelected: selectedMetricType == .meal,
                        action: { selectedMetricType = .meal }
                    )

                    MetricTypeChip(
                        type: .exercise,
                        isSelected: selectedMetricType == .exercise,
                        action: { selectedMetricType = .exercise }
                    )
                }
            }
        }
    }

    // MARK: - Average Readings Card

    private var averageReadingsCard: some View {
        GlowingCard(
            glowColor: metricColor,
            glowIntensity: .medium
        ) {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: selectedMetricType.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(metricColor)

                    Text("\(selectedDateRange.displayName) Summary")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()
                }

                // Stats based on metric type
                if selectedMetricType == .bloodSugar {
                    bloodSugarStats
                } else if selectedMetricType == .exercise {
                    exerciseStats
                } else {
                    generalStats
                }
            }
        }
    }

    // MARK: - Blood Sugar Stats

    private var bloodSugarStats: some View {
        VStack(spacing: AppSpacing.md) {
            // Average reading (placeholder)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text("--")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    + Text(" mg/dL")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Readings")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(filteredMetrics.count)")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Divider()

            // Range
            HStack {
                StatBox(
                    label: "Lowest",
                    value: lowestBloodSugar,
                    unit: "mg/dL",
                    color: AppColors.bloodSugarLow
                )

                Spacer()

                StatBox(
                    label: "Highest",
                    value: highestBloodSugar,
                    unit: "mg/dL",
                    color: AppColors.bloodSugarHigh
                )
            }
        }
    }

    // MARK: - Exercise Stats

    private var exerciseStats: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Time")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(totalExerciseMinutes)")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    + Text(" min")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Sessions")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(filteredMetrics.count)")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Divider()

            HStack {
                StatBox(
                    label: "Daily Avg",
                    value: dailyAverageExercise,
                    unit: "min",
                    color: AppColors.success
                )

                Spacer()

                StatBox(
                    label: "Goal Met",
                    value: daysGoalMet,
                    unit: "days",
                    color: AppColors.accent
                )
            }
        }
    }

    // MARK: - General Stats

    private var generalStats: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Entries")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(filteredMetrics.count)")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Per Day")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(String(format: "%.1f", perDayAverage))
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }

    // MARK: - Chart Section (Placeholder)

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Trend Chart")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            GlowingCard(glowColor: AppColors.divider, glowIntensity: .none) {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.textTertiary)

                    Text("Chart visualization")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)

                    Text("Coming soon: Interactive charts showing your trends over time")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            }
        }
    }

    // MARK: - History List

    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Detailed History")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(filteredMetrics.count) entries")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            if filteredMetrics.isEmpty {
                GlowingCard(glowColor: AppColors.divider, glowIntensity: .none) {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)

                        Text("No data for this period")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(filteredMetrics.prefix(20)) { metric in
                        HistoryMetricRow(metric: metric, viewModel: viewModel)
                    }

                    if filteredMetrics.count > 20 {
                        Text("Showing 20 of \(filteredMetrics.count) entries")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.vertical, AppSpacing.sm)
                    }
                }
            }
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Export Data")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Button(action: exportData) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export as CSV")
                        .font(AppTypography.buttonText)
                }
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.buttonPaddingVertical)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                        .stroke(AppColors.primary, lineWidth: 1)
                )
            }

            Text("Export your health data to share with your healthcare provider")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    // MARK: - Computed Properties

    private var filteredMetrics: [HealthMetric] {
        viewModel.recentMetrics
            .filter { $0.type == selectedMetricType }
            .filter { metric in
                selectedDateRange.contains(metric.recordedAt)
            }
    }

    private var metricColor: Color {
        switch selectedMetricType {
        case .bloodSugar: return AppColors.primary
        case .medication: return AppColors.secondary
        case .meal: return AppColors.accent
        case .exercise: return AppColors.success
        default: return AppColors.primary
        }
    }

    private var lowestBloodSugar: String {
        let values = filteredMetrics.compactMap { $0.bloodSugarReading?.value }
        guard let min = values.min() else { return "--" }
        return String(format: "%.0f", min)
    }

    private var highestBloodSugar: String {
        let values = filteredMetrics.compactMap { $0.bloodSugarReading?.value }
        guard let max = values.max() else { return "--" }
        return String(format: "%.0f", max)
    }

    private var totalExerciseMinutes: Int {
        Int(filteredMetrics.reduce(0) { $0 + $1.value })
    }

    private var dailyAverageExercise: String {
        let days = max(selectedDateRange.numberOfDays, 1)
        let average = Double(totalExerciseMinutes) / Double(days)
        return String(format: "%.0f", average)
    }

    private var daysGoalMet: String {
        // Placeholder - would need to group by day and check goal
        return "--"
    }

    private var perDayAverage: Double {
        let days = max(selectedDateRange.numberOfDays, 1)
        return Double(filteredMetrics.count) / Double(days)
    }

    // MARK: - Actions

    private func exportData() {
        // Placeholder for CSV export functionality
        HapticManager.shared.impact(.light)
    }
}

// MARK: - Date Range Enum

enum DateRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"

    var displayName: String {
        rawValue
    }

    var numberOfDays: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }

    func contains(_ date: Date) -> Bool {
        let daysAgo = Date().daysBetween(date)
        return abs(daysAgo) <= numberOfDays
    }
}

// MARK: - Supporting Views

private struct DateRangeButton: View {
    let range: DateRange
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(range.displayName)
                .font(AppTypography.subheadline)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(isSelected ? AppColors.primary : AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall)
                        .stroke(isSelected ? AppColors.primary : AppColors.divider, lineWidth: 1)
                )
        }
    }
}

private struct MetricTypeChip: View {
    let type: HealthMetricType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: type.iconName)
                    .font(.system(size: 16))

                Text(type.displayName)
                    .font(AppTypography.bodyBold)
            }
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? chipColor : AppColors.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? chipColor : AppColors.divider, lineWidth: 1)
            )
        }
    }

    private var chipColor: Color {
        switch type {
        case .bloodSugar: return AppColors.primary
        case .medication: return AppColors.secondary
        case .meal: return AppColors.accent
        case .exercise: return AppColors.success
        default: return AppColors.primary
        }
    }
}

private struct StatBox: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(color)
            + Text(" \(unit)")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}

private struct HistoryMetricRow: View {
    let metric: HealthMetric
    let viewModel: HealthViewModel

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Date and time
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.recordedAt.shortDateString)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)

                Text(metric.recordedAt.shortTimeString)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(width: 80, alignment: .leading)

            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.formattedValue)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(valueColor)

                if metric.type == .bloodSugar,
                   let reading = metric.bloodSugarReading {
                    Text(reading.timing.displayName)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Indicator
            Circle()
                .fill(valueColor)
                .frame(width: 8, height: 8)
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
    }

    private var valueColor: Color {
        switch metric.type {
        case .bloodSugar:
            return viewModel.bloodSugarColor(for: metric.bloodSugarReading)
        case .medication:
            return AppColors.secondary
        case .meal:
            return AppColors.accent
        case .exercise:
            return AppColors.success
        default:
            return AppColors.primary
        }
    }
}

// MARK: - Preview

#Preview {
    HealthHistoryView(viewModel: HealthViewModel())
}
