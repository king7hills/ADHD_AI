//
//  HealthDashboardView.swift
//  ADHDAssistant
//
//  Main dashboard for Health Feature - Diabetes Management
//

import SwiftUI

struct HealthDashboardView: View {
    @StateObject private var viewModel = HealthViewModel()
    @State private var showBloodSugarLog = false
    @State private var showMedicationLog = false
    @State private var showMealLog = false
    @State private var showExerciseLog = false
    @State private var showHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header with streak
                headerSection

                // Blood sugar summary card
                bloodSugarCard

                // Medication adherence card
                medicationCard

                // Quick action buttons
                quickActionsSection

                // Recent activity
                recentLogsSection

                // Encouragement message
                encouragementSection
            }
            .padding(.horizontal, AppSpacing.screenHorizontalPadding)
            .padding(.vertical, AppSpacing.screenVerticalPadding)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Health")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showHistory = true }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showBloodSugarLog) {
            BloodSugarLogView(viewModel: viewModel)
        }
        .sheet(isPresented: $showMedicationLog) {
            MedicationLogView(viewModel: viewModel)
        }
        .sheet(isPresented: $showExerciseLog) {
            ExerciseTrackerView(viewModel: viewModel)
        }
        .sheet(isPresented: $showHistory) {
            HealthHistoryView(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.fetchHealthData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Your Health")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                if viewModel.healthStreak > 0 {
                    Text("\(viewModel.healthStreak) day streak 🔥")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.accent)
                }
            }

            Spacer()

            if viewModel.healthStreak > 0 {
                StreakBadge(days: viewModel.healthStreak)
            }
        }
    }

    // MARK: - Blood Sugar Card

    private var bloodSugarCard: some View {
        GlowingCard(
            glowColor: viewModel.bloodSugarColor(for: viewModel.latestBloodSugar?.bloodSugarReading),
            glowIntensity: .medium
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.bloodSugarColor(for: viewModel.latestBloodSugar?.bloodSugarReading))

                    Text("Blood Sugar")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    if let reading = viewModel.latestBloodSugar?.bloodSugarReading {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.bloodSugarTrend.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(viewModel.bloodSugarTrend.description)
                                .font(AppTypography.caption)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }
                }

                // Latest reading
                if let metric = viewModel.latestBloodSugar,
                   let reading = metric.bloodSugarReading {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("\(Int(reading.value))")
                            .font(AppTypography.pointsDisplay)
                            .foregroundColor(viewModel.bloodSugarColor(for: reading))
                        + Text(" mg/dL")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textSecondary)

                        HStack {
                            Text(reading.timing.displayName)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)

                            Text("•")
                                .foregroundColor(AppColors.textTertiary)

                            Text(metric.recordedAt.timeAgoString)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textTertiary)
                        }

                        // Level indicator
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(viewModel.bloodSugarColor(for: reading))
                                .frame(width: 8, height: 8)

                            Text(reading.level.displayName)
                                .font(AppTypography.caption)
                                .foregroundColor(viewModel.bloodSugarColor(for: reading))
                        }
                        .padding(.top, AppSpacing.xs)
                    }
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("No readings yet")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textSecondary)

                        Text("Tap the button below to log your first blood sugar reading")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                // Quick log button
                Button(action: { showBloodSugarLog = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Blood Sugar")
                            .font(AppTypography.buttonTextSmall)
                    }
                    .foregroundColor(AppColors.primary)
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }

    // MARK: - Medication Card

    private var medicationCard: some View {
        GlowingCard(
            glowColor: viewModel.nextMedication?.isOverdue == true ? AppColors.error : AppColors.primary,
            glowIntensity: viewModel.nextMedication?.isOverdue == true ? .strong : .subtle
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)

                    Text("Medications")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    // Adherence rate
                    if !viewModel.todayMedications.isEmpty {
                        Text("\(Int(viewModel.medicationAdherenceRate * 100))%")
                            .font(AppTypography.headline)
                            .foregroundColor(
                                viewModel.medicationAdherenceRate >= 0.8 ? AppColors.success : AppColors.warning
                            )
                    }
                }

                // Today's medications summary
                if !viewModel.todayMedications.isEmpty {
                    let taken = viewModel.todayMedications.filter { $0.isTaken }.count
                    let total = viewModel.todayMedications.count

                    HStack(spacing: AppSpacing.sm) {
                        // Progress indicator
                        HStack(spacing: 4) {
                            ForEach(0..<total, id: \.self) { index in
                                Circle()
                                    .fill(index < taken ? AppColors.success : AppColors.divider)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Text("\(taken)/\(total) taken")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Next medication
                    if let next = viewModel.nextMedication {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Next: \(next.medication.medicationName)")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.textPrimary)

                            Text("\(next.medication.dosage) at \(next.displayTime)")
                                .font(AppTypography.subheadline)
                                .foregroundColor(next.isOverdue ? AppColors.error : AppColors.textSecondary)
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                } else {
                    Text("No medications scheduled")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                // View all button
                Button(action: { showMedicationLog = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View All Medications")
                            .font(AppTypography.buttonTextSmall)
                    }
                    .foregroundColor(AppColors.primary)
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Log")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                QuickActionButton(
                    icon: "drop.fill",
                    title: "Blood Sugar",
                    color: AppColors.primary,
                    action: { showBloodSugarLog = true }
                )

                QuickActionButton(
                    icon: "pills.fill",
                    title: "Medication",
                    color: AppColors.secondary,
                    action: { showMedicationLog = true }
                )

                QuickActionButton(
                    icon: "fork.knife",
                    title: "Meal",
                    color: AppColors.accent,
                    action: { showMealLog = true }
                )

                QuickActionButton(
                    icon: "figure.walk",
                    title: "Exercise",
                    color: AppColors.success,
                    action: { showExerciseLog = true }
                )
            }
        }
        .sheet(isPresented: $showMealLog) {
            MealLogSheet(viewModel: viewModel)
        }
    }

    // MARK: - Recent Logs

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Activity")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            if viewModel.recentMetrics.isEmpty {
                GlowingCard(glowColor: AppColors.divider, glowIntensity: .none) {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)

                        Text("No activity yet")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)

                        Text("Start logging to see your health data here")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, AppSpacing.lg)
                }
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.recentMetrics.prefix(5)) { metric in
                        HealthMetricRow(metric: metric, viewModel: viewModel)
                    }
                }
            }
        }
    }

    // MARK: - Encouragement Section

    private var encouragementSection: some View {
        GlowingCard(
            glowColor: AppColors.accent,
            glowIntensity: .subtle
        ) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.accent)

                Text(viewModel.encouragementMessage())
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }
        }
    }
}

// MARK: - Supporting Views

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

private struct HealthMetricRow: View {
    let metric: HealthMetric
    let viewModel: HealthViewModel

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Icon
            Image(systemName: metric.type.iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.displayTitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)

                Text(metric.recordedAt.relativeDescription)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            // Value
            Text(valueText)
                .font(AppTypography.bodyBold)
                .foregroundColor(valueColor)
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
    }

    private var iconColor: Color {
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

    private var valueText: String {
        switch metric.type {
        case .bloodSugar:
            return metric.formattedValue
        case .medication:
            return "✓"
        case .meal:
            return "🍽️"
        case .exercise:
            return "\(Int(metric.value))m"
        default:
            return metric.formattedValue
        }
    }

    private var valueColor: Color {
        switch metric.type {
        case .bloodSugar:
            return viewModel.bloodSugarColor(for: metric.bloodSugarReading)
        default:
            return AppColors.success
        }
    }
}

// Quick meal logging sheet
private struct MealLogSheet: View {
    let viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

    var body: some View {
        NavigationView {
            List(mealTypes, id: \.self) { mealType in
                Button(action: {
                    Task {
                        await viewModel.logMeal(type: mealType)
                        dismiss()
                    }
                }) {
                    HStack {
                        Text(mealType)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        HealthDashboardView()
    }
}
