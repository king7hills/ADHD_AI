//
//  TaskRow.swift
//  ADHDAssistant
//
//  Reusable row component for displaying tasks in lists
//

import SwiftUI

struct TaskRow: View {
    let task: Task
    let showDate: Bool
    let onToggleComplete: () -> Void

    @State private var isCompleted: Bool

    init(task: Task, showDate: Bool = true, onToggleComplete: @escaping () -> Void) {
        self.task = task
        self.showDate = showDate
        self.onToggleComplete = onToggleComplete
        self._isCompleted = State(initialValue: task.isCompleted)
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Completion checkbox
            Button(action: handleToggle) {
                DoneButton(
                    isCompleted: $isCompleted,
                    style: .small,
                    onCelebrate: nil
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Task content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Title
                Text(task.title)
                    .font(AppTypography.taskTitle)
                    .foregroundColor(isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                    .strikethrough(isCompleted, color: AppColors.textTertiary)
                    .lineLimit(2)

                // Metadata row
                HStack(spacing: AppSpacing.sm) {
                    // Duration badge
                    if task.estimatedDuration > 0 {
                        DurationBadge(duration: task.estimatedDuration)
                    }

                    // Priority indicator
                    if task.priority != .medium {
                        PriorityIndicator(priority: task.priority)
                    }

                    // Overdue indicator
                    if task.isOverdue {
                        OverdueIndicator()
                    }

                    // Scheduled time
                    if showDate, let scheduledTime = task.scheduledTime {
                        ScheduledTimeBadge(time: scheduledTime)
                    }

                    // Subtask count
                    if !task.subtasks.isEmpty {
                        SubtaskCountBadge(
                            completed: task.subtasks.filter { $0.isCompleted }.count,
                            total: task.subtasks.count
                        )
                    }

                    Spacer()
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
        .shadow(color: AppColors.shadow, radius: 2, x: 0, y: 1)
    }

    private func handleToggle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCompleted.toggle()
        }
        HapticManager.shared.impact(.medium)
        onToggleComplete()
    }
}

// MARK: - Supporting Badge Views

private struct DurationBadge: View {
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "clock")
                .font(.system(size: AppSpacing.iconSizeXS))
            Text(formatDuration(duration))
                .font(AppTypography.caption)
        }
        .foregroundColor(AppColors.textSecondary)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60

        if hours > 0 {
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

private struct PriorityIndicator: View {
    let priority: Priority

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(priorityColor)
                .frame(width: 6, height: 6)
            Text(priority.displayName)
                .font(AppTypography.caption)
                .foregroundColor(priorityColor)
        }
    }

    private var priorityColor: Color {
        switch priority {
        case .critical:
            return AppColors.error
        case .high:
            return AppColors.warning
        case .medium:
            return AppColors.info
        case .low:
            return AppColors.textTertiary
        }
    }
}

private struct OverdueIndicator: View {
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: AppSpacing.iconSizeXS))
            Text("Overdue")
                .font(AppTypography.caption)
        }
        .foregroundColor(AppColors.error)
    }
}

private struct ScheduledTimeBadge: View {
    let time: Date

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "calendar")
                .font(.system(size: AppSpacing.iconSizeXS))
            Text(formatTime(time))
                .font(AppTypography.caption)
        }
        .foregroundColor(AppColors.textSecondary)
    }

    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

private struct SubtaskCountBadge: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "checklist")
                .font(.system(size: AppSpacing.iconSizeXS))
            Text("\(completed)/\(total)")
                .font(AppTypography.caption)
        }
        .foregroundColor(completed == total ? AppColors.success : AppColors.textSecondary)
    }
}

// MARK: - Preview Provider

#Preview("Task Row States") {
    ScrollView {
        VStack(spacing: AppSpacing.md) {
            TaskRow(
                task: Task(
                    title: "Review morning medications",
                    estimatedDuration: 300,
                    scheduledTime: Date(),
                    priority: .high
                ),
                onToggleComplete: {}
            )

            TaskRow(
                task: Task(
                    title: "Complete project proposal with detailed analysis",
                    estimatedDuration: 3600,
                    scheduledTime: Date().addingTimeInterval(-3600),
                    status: .active,
                    priority: .critical,
                    subtasks: [
                        Subtask(title: "Research", isCompleted: true),
                        Subtask(title: "Write draft"),
                        Subtask(title: "Review")
                    ]
                ),
                onToggleComplete: {}
            )

            TaskRow(
                task: Task(
                    title: "Quick task",
                    estimatedDuration: 600,
                    status: .completed,
                    priority: .low
                ),
                onToggleComplete: {}
            )

            TaskRow(
                task: Task(
                    title: "Prepare healthy lunch",
                    estimatedDuration: 1200,
                    scheduledTime: Date().addingTimeInterval(7200),
                    priority: .medium,
                    subtasks: [
                        Subtask(title: "Choose recipe", isCompleted: true),
                        Subtask(title: "Gather ingredients"),
                        Subtask(title: "Cook meal")
                    ]
                ),
                onToggleComplete: {}
            )
        }
        .padding()
    }
    .background(AppColors.background)
}
