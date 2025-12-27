//
//  UpcomingTasksPreview.swift
//  ADHDAssistant
//
//  Dashboard - Upcoming Tasks Preview Component
//

import SwiftUI

/// Shows next 3-5 upcoming tasks in a compact format
struct UpcomingTasksPreview: View {
    var tasks: [Task]
    var maxTasks: Int = 5
    var onTaskTap: ((Task) -> Void)?
    var onViewAllTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Text("Coming Up")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                if tasks.count > maxTasks {
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        onViewAllTap?()
                    }) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(AppTypography.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }

            // Task list
            if displayTasks.isEmpty {
                EmptyUpcomingView()
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(displayTasks) { task in
                        UpcomingTaskRow(task: task, onTap: {
                            onTaskTap?(task)
                        })
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .cardShadow()
    }

    private var displayTasks: [Task] {
        Array(tasks.prefix(maxTasks))
    }
}

/// Individual upcoming task row
private struct UpcomingTaskRow: View {
    var task: Task
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            onTap()
        }) {
            HStack(spacing: AppSpacing.md) {
                // Priority indicator
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)

                // Task details
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.xs) {
                        // Time until task
                        if let scheduledTime = task.scheduledTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(timeUntilString(scheduledTime))
                            }
                            .font(AppTypography.caption)
                            .foregroundColor(timeUntilColor(scheduledTime))
                        }

                        // Duration estimate
                        Text("•")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)

                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text(task.estimatedDurationFormatted)
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low:
            return AppColors.info
        case .medium:
            return AppColors.primary
        case .high:
            return AppColors.warning
        case .critical:
            return AppColors.error
        }
    }

    private func timeUntilString(_ scheduledTime: Date) -> String {
        let interval = scheduledTime.timeIntervalSinceNow

        if interval < 0 {
            return "Overdue"
        } else if interval < 60 {
            return "Now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "in \(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "in \(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "in \(days)d"
        }
    }

    private func timeUntilColor(_ scheduledTime: Date) -> Color {
        let interval = scheduledTime.timeIntervalSinceNow

        if interval < 0 {
            return AppColors.error
        } else if interval < 900 { // 15 minutes
            return AppColors.warning
        } else {
            return AppColors.textSecondary
        }
    }
}

/// Empty state when no upcoming tasks
private struct EmptyUpcomingView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(AppColors.success.opacity(0.5))

            Text("All caught up!")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text("No upcoming tasks scheduled")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }
}

// MARK: - Preview Provider

#Preview("Upcoming Tasks") {
    ScrollView {
        VStack(spacing: 24) {
            // With tasks
            UpcomingTasksPreview(
                tasks: [
                    Task(
                        title: "Review morning medications",
                        estimatedDuration: 300,
                        scheduledTime: Date().addingTimeInterval(900),
                        priority: .high
                    ),
                    Task(
                        title: "Morning exercise routine",
                        estimatedDuration: 1800,
                        scheduledTime: Date().addingTimeInterval(3600),
                        priority: .medium
                    ),
                    Task(
                        title: "Prepare healthy lunch",
                        estimatedDuration: 1200,
                        scheduledTime: Date().addingTimeInterval(10800),
                        priority: .medium
                    ),
                    Task(
                        title: "Client meeting",
                        estimatedDuration: 3600,
                        scheduledTime: Date().addingTimeInterval(14400),
                        priority: .critical
                    ),
                    Task(
                        title: "Evening walk",
                        estimatedDuration: 1800,
                        scheduledTime: Date().addingTimeInterval(28800),
                        priority: .low
                    ),
                    Task(
                        title: "Extra task",
                        estimatedDuration: 900,
                        scheduledTime: Date().addingTimeInterval(32400),
                        priority: .low
                    )
                ],
                onTaskTap: { task in
                    print("Tapped: \(task.title)")
                },
                onViewAllTap: {
                    print("View all tapped")
                }
            )

            // Empty state
            UpcomingTasksPreview(
                tasks: [],
                onViewAllTap: {
                    print("View all tapped")
                }
            )
        }
        .padding()
    }
    .background(AppColors.background)
}
