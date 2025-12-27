//
//  ExerciseTrackerView.swift
//  ADHDAssistant
//
//  Exercise tracking and progress monitoring
//

import SwiftUI

struct ExerciseTrackerView: View {
    @ObservedObject var viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedActivityType: ExerciseActivityType = .walked
    @State private var selectedDuration: Int = 15
    @State private var notes: String = ""
    @State private var showCelebration = false

    let durations = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Progress ring showing today's goal
                    progressSection

                    // Activity type selection
                    activityTypeSection

                    // Duration selector
                    durationSection

                    // Optional notes
                    notesSection

                    // Log button
                    logButton

                    // This week's history
                    weekHistorySection

                    // Encouragement
                    encouragementSection
                }
                .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                .padding(.vertical, AppSpacing.screenVerticalPadding)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Exercise")
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

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Today's Goal")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)

            // Progress ring
            ProgressRing(
                progress: viewModel.exerciseProgress,
                lineWidth: 16,
                size: 180,
                ringColor: progressColor,
                showPercentage: false,
                centerIcon: "figure.walk"
            )
            .overlay(
                VStack(spacing: 4) {
                    Spacer()
                        .frame(height: 60)

                    Text("\(viewModel.todayExerciseMinutes)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .monospacedDigit()

                    Text("/ \(viewModel.exerciseGoal) min")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            )

            // Status message
            Text(progressMessage)
                .font(AppTypography.body)
                .foregroundColor(progressColor)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Activity Type Section

    private var activityTypeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Activity Type")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                ForEach(ExerciseActivityType.allCases, id: \.self) { type in
                    ActivityTypeButton(
                        type: type,
                        isSelected: selectedActivityType == type,
                        action: {
                            selectedActivityType = type
                            HapticManager.shared.impact(.light)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Duration")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            // Duration chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(durations, id: \.self) { duration in
                        DurationChip(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            action: {
                                selectedDuration = duration
                                HapticManager.shared.impact(.light)
                            }
                        )
                    }
                }
            }

            // Custom duration
            HStack {
                Text("Custom:")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                Stepper(
                    "\(selectedDuration) min",
                    value: $selectedDuration,
                    in: 1...180,
                    step: 5
                )
                .font(AppTypography.bodyBold)
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Notes (Optional)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            TextField("How did it feel?", text: $notes, axis: .vertical)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
                .lineLimit(2...4)
        }
    }

    // MARK: - Log Button

    private var logButton: some View {
        Button(action: logExercise) {
            HStack {
                if showCelebration {
                    Image(systemName: "checkmark.circle.fill")
                        .transition(.scale)
                }

                Text("Log Exercise")
                    .font(AppTypography.buttonText)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.buttonPaddingVertical)
            .background(AppColors.success)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        }
        .animation(.spring(), value: showCelebration)
    }

    // MARK: - Week History Section

    private var weekHistorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("This Week")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            // Week view with days
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
                    DayExerciseIndicator(date: date)
                }
            }

            // This week's total
            HStack {
                Text("Weekly total:")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Text("\(viewModel.todayExerciseMinutes) min")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.success)
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
        }
    }

    // MARK: - Encouragement Section

    private var encouragementSection: some View {
        GlowingCard(
            glowColor: AppColors.success,
            glowIntensity: .subtle
        ) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.success)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep Moving!")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Exercise helps regulate blood sugar levels")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Computed Properties

    private var progressColor: Color {
        let progress = viewModel.exerciseProgress

        if progress >= 1.0 {
            return AppColors.success
        } else if progress >= 0.5 {
            return AppColors.primary
        } else {
            return AppColors.warning
        }
    }

    private var progressMessage: String {
        let remaining = viewModel.exerciseGoal - viewModel.todayExerciseMinutes

        if remaining <= 0 {
            return "Goal reached! Excellent work! 🎉"
        } else if remaining <= 10 {
            return "Almost there! Just \(remaining) more minutes!"
        } else {
            return "\(remaining) minutes to go today"
        }
    }

    // MARK: - Actions

    private func logExercise() {
        let activityNotes = notes.isEmpty ? selectedActivityType.rawValue : notes

        Task {
            await viewModel.logExercise(
                type: selectedActivityType.rawValue,
                duration: selectedDuration,
                notes: activityNotes
            )

            showCelebration = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Exercise Activity Types

enum ExerciseActivityType: String, CaseIterable {
    case walked = "Walked"
    case stretched = "Stretched"
    case workout = "Workout"
    case yoga = "Yoga"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case dancing = "Dancing"
    case other = "Other"

    var icon: String {
        switch self {
        case .walked: return "figure.walk"
        case .stretched: return "figure.flexibility"
        case .workout: return "figure.strengthtraining.traditional"
        case .yoga: return "figure.mind.and.body"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .dancing: return "figure.dance"
        case .other: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .walked: return AppColors.primary
        case .stretched: return AppColors.secondary
        case .workout: return AppColors.accent
        case .yoga: return Color(hex: "#8B5CF6")
        case .cycling: return AppColors.info
        case .swimming: return Color(hex: "#06B6D4")
        case .dancing: return Color(hex: "#EC4899")
        case .other: return AppColors.success
        }
    }
}

// MARK: - Supporting Views

private struct ActivityTypeButton: View {
    let type: ExerciseActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : type.color)

                Text(type.rawValue)
                    .font(AppTypography.subheadline)
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(isSelected ? type.color : AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    .stroke(type.color, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

private struct DurationChip: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(duration) min")
                .font(AppTypography.bodyBold)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.success : AppColors.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppColors.success : AppColors.divider, lineWidth: 1)
                )
        }
    }
}

private struct DayExerciseIndicator: View {
    let date: Date

    var body: some View {
        VStack(spacing: 4) {
            Text(date.shortWeekdayName)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)

            Circle()
                .fill(isToday ? AppColors.success : AppColors.divider)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(isToday ? "✓" : "\(date.day)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isToday ? .white : AppColors.textSecondary)
                )
        }
        .frame(maxWidth: .infinity)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Preview

#Preview {
    ExerciseTrackerView(viewModel: HealthViewModel())
}
