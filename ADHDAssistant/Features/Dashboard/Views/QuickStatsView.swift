//
//  QuickStatsView.swift
//  ADHDAssistant
//
//  Dashboard - Quick Stats Display
//

import SwiftUI

/// Compact horizontal stats display showing daily progress
struct QuickStatsView: View {
    var tasksCompleted: Int
    var totalTasks: Int
    var pointsEarned: Int
    var streakCount: Int
    var dailyGoalProgress: Double // 0.0 to 1.0

    @State private var animatePoints = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Tasks completed stat
            StatItem(
                icon: "checkmark.circle.fill",
                value: "\(tasksCompleted)/\(totalTasks)",
                label: "Tasks",
                color: tasksCompleted == totalTasks ? AppColors.success : AppColors.primary
            )

            Divider()
                .frame(height: 40)

            // Points earned stat
            StatItem(
                icon: "star.fill",
                value: "\(pointsEarned)",
                label: "Points",
                color: AppColors.accent,
                animateValue: animatePoints
            )

            Divider()
                .frame(height: 40)

            // Streak stat
            StatItem(
                icon: "flame.fill",
                value: "\(streakCount)",
                label: "Day\(streakCount == 1 ? "" : "s")",
                color: streakColor
            )

            Divider()
                .frame(height: 40)

            // Daily goal progress ring
            VStack(spacing: 4) {
                ProgressRing(
                    progress: dailyGoalProgress,
                    lineWidth: 6,
                    size: 44,
                    ringColor: goalProgressColor,
                    showPercentage: false
                )

                Text("Goal")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .cardShadow()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animatePoints = true
            }
        }
    }

    // MARK: - Computed Properties

    private var streakColor: Color {
        switch streakCount {
        case 0:
            return AppColors.textTertiary
        case 1...6:
            return Color(hex: "#FFA500")
        case 7...13:
            return Color(hex: "#FF4500")
        default:
            return Color(hex: "#FFD700")
        }
    }

    private var goalProgressColor: Color {
        if dailyGoalProgress >= 1.0 {
            return AppColors.success
        } else if dailyGoalProgress >= 0.5 {
            return AppColors.primary
        } else {
            return AppColors.warning
        }
    }
}

/// Individual stat item
private struct StatItem: View {
    var icon: String
    var value: String
    var label: String
    var color: Color
    var animateValue: Bool = false

    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
                .monospacedDigit()
                .scaleEffect(scale)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: animateValue) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.2
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

/// Vertical stats layout for larger displays
struct VerticalStatsView: View {
    var tasksCompleted: Int
    var totalTasks: Int
    var pointsEarned: Int
    var streakCount: Int
    var dailyGoalProgress: Double

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Progress ring with daily goal
            VStack(spacing: AppSpacing.sm) {
                ProgressRing(
                    progress: dailyGoalProgress,
                    lineWidth: 12,
                    size: 120,
                    ringColor: goalProgressColor,
                    showPercentage: true
                )

                Text("Daily Goal")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            Divider()

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                LargeStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(tasksCompleted)",
                    subtitle: "of \(totalTasks) tasks",
                    color: AppColors.success
                )

                LargeStatCard(
                    icon: "star.fill",
                    value: "\(pointsEarned)",
                    subtitle: "points today",
                    color: AppColors.accent
                )

                LargeStatCard(
                    icon: "flame.fill",
                    value: "\(streakCount)",
                    subtitle: "day streak",
                    color: streakColor
                )

                LargeStatCard(
                    icon: "target",
                    value: "\(Int(dailyGoalProgress * 100))%",
                    subtitle: "goal progress",
                    color: goalProgressColor
                )
            }
        }
    }

    private var streakColor: Color {
        switch streakCount {
        case 0:
            return AppColors.textTertiary
        case 1...6:
            return Color(hex: "#FFA500")
        case 7...13:
            return Color(hex: "#FF4500")
        default:
            return Color(hex: "#FFD700")
        }
    }

    private var goalProgressColor: Color {
        if dailyGoalProgress >= 1.0 {
            return AppColors.success
        } else if dailyGoalProgress >= 0.5 {
            return AppColors.primary
        } else {
            return AppColors.warning
        }
    }
}

private struct LargeStatCard: View {
    var icon: String
    var value: String
    var subtitle: String
    var color: Color

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            Text(value)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
                .monospacedDigit()

            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .cardShadow()
    }
}

// MARK: - Preview Provider

#Preview("Quick Stats") {
    VStack(spacing: 32) {
        QuickStatsView(
            tasksCompleted: 5,
            totalTasks: 8,
            pointsEarned: 125,
            streakCount: 7,
            dailyGoalProgress: 0.625
        )

        QuickStatsView(
            tasksCompleted: 3,
            totalTasks: 3,
            pointsEarned: 75,
            streakCount: 14,
            dailyGoalProgress: 1.0
        )

        Divider()

        VerticalStatsView(
            tasksCompleted: 5,
            totalTasks: 8,
            pointsEarned: 125,
            streakCount: 7,
            dailyGoalProgress: 0.625
        )
    }
    .padding()
    .background(AppColors.background)
}
