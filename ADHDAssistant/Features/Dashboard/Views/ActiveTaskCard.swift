//
//  ActiveTaskCard.swift
//  ADHDAssistant
//
//  Dashboard - Active Task Card Component
//

import SwiftUI

/// Prominent card showing current active task with actions
struct ActiveTaskCard: View {
    var task: Task
    var onStart: () -> Void
    var onComplete: () -> Void
    var onSnooze: ((TimeInterval) -> Void)?
    var onSkip: () -> Void

    @State private var showSnoozeOptions = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var isCompleted = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GlowingCard(
            glowColor: priorityColor,
            glowIntensity: task.status == .active ? .strong : .medium,
            cornerRadius: AppSpacing.cornerRadiusLarge,
            padding: AppSpacing.cardPaddingLarge
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header with priority badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Current Task")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)

                        Text(task.title)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    PriorityBadge(priority: task.priority)
                }

                // Description
                if let description = task.description {
                    Text(description)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }

                // Start trigger if available
                if let startTrigger = task.startTrigger {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.accent)

                        Text(startTrigger)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                            .italic()
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                }

                Divider()

                // Task metadata
                HStack(spacing: AppSpacing.md) {
                    // Time estimate / timer
                    HStack(spacing: 6) {
                        Image(systemName: task.status == .active ? "clock.fill" : "timer")
                            .font(.system(size: 16))
                            .foregroundColor(timerColor)

                        if task.status == .active {
                            Text(formattedElapsedTime)
                                .font(AppTypography.headline)
                                .foregroundColor(timerColor)
                                .monospacedDigit()
                        } else {
                            Text(task.estimatedDurationFormatted)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    // Scheduled time
                    if let scheduledTime = task.scheduledTime {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                            Text(scheduledTimeString(scheduledTime))
                                .font(AppTypography.footnote)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    // Points value
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.accent)
                        Text("\(task.totalPoints)")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textPrimary)
                            .monospacedDigit()
                    }
                }

                // Subtasks progress if any
                if !task.subtasks.isEmpty {
                    SubtasksProgressView(
                        completed: task.subtasks.filter { $0.isCompleted }.count,
                        total: task.subtasks.count,
                        percentage: task.completionPercentage
                    )
                }

                // Action buttons
                HStack(spacing: AppSpacing.md) {
                    if task.status == .active {
                        // Done button
                        PulsingButton(
                            isCompleted: $isCompleted,
                            size: .large,
                            onCelebrate: {
                                HapticManager.shared.celebration(.gold)
                                onComplete()
                            }
                        )

                        Spacer()

                        // Secondary actions
                        Button(action: {
                            showSnoozeOptions.toggle()
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 44, height: 44)
                                .background(AppColors.surface)
                                .clipShape(Circle())
                        }

                        Button(action: {
                            HapticManager.shared.impact(.medium)
                            onSkip()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(AppColors.surface)
                                .clipShape(Circle())
                        }
                    } else {
                        // Start button
                        Button(action: {
                            HapticManager.shared.impact(.medium)
                            onStart()
                        }) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16))
                                Text("Start Task")
                                    .font(AppTypography.buttonText)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.buttonPaddingVertical)
                            .background(AppColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
                        }

                        Button(action: {
                            HapticManager.shared.impact(.light)
                            onSkip()
                        }) {
                            Text("Skip")
                                .font(AppTypography.buttonText)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            if task.status == .active {
                timeElapsed += 1
            }
        }
        .confirmationDialog("Snooze for...", isPresented: $showSnoozeOptions) {
            Button("15 minutes") {
                onSnooze?(900)
            }
            Button("30 minutes") {
                onSnooze?(1800)
            }
            Button("1 hour") {
                onSnooze?(3600)
            }
            Button("Later today") {
                onSnooze?(14400)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Computed Properties

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

    private var timerColor: Color {
        if timeElapsed > task.estimatedDuration {
            return AppColors.error
        } else if timeElapsed > task.estimatedDuration * 0.8 {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }

    private var formattedElapsedTime: String {
        let hours = Int(timeElapsed) / 3600
        let minutes = Int(timeElapsed) / 60 % 60
        let seconds = Int(timeElapsed) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func scheduledTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Priority badge for tasks
private struct PriorityBadge: View {
    var priority: Priority

    var body: some View {
        Text(priority.displayName)
            .font(AppTypography.badgeText)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(priorityColor)
            .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch priority {
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
}

/// Subtasks progress indicator
private struct SubtasksProgressView: View {
    var completed: Int
    var total: Int
    var percentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.system(size: 14))
                    Text("Subtasks")
                        .font(AppTypography.caption)
                }
                .foregroundColor(AppColors.textSecondary)

                Spacer()

                Text("\(completed)/\(total)")
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.divider)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.success)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
    }
}

// MARK: - Preview Provider

#Preview("Active Task Card") {
    ScrollView {
        VStack(spacing: 24) {
            // Not started
            ActiveTaskCard(
                task: Task(
                    title: "Review morning medications",
                    description: "Take metformin and check blood sugar levels",
                    estimatedDuration: 300,
                    scheduledTime: Date().addingTimeInterval(900),
                    status: .scheduled,
                    priority: .high,
                    subtasks: [
                        Subtask(title: "Take metformin"),
                        Subtask(title: "Check blood sugar"),
                        Subtask(title: "Log in health app")
                    ],
                    pointsValue: 15,
                    startTrigger: "After breakfast"
                ),
                onStart: { print("Start") },
                onComplete: { print("Complete") },
                onSnooze: { interval in print("Snooze: \(interval)") },
                onSkip: { print("Skip") }
            )

            // Active task
            ActiveTaskCard(
                task: Task(
                    title: "Morning exercise routine",
                    description: "30-minute walk or light cardio",
                    estimatedDuration: 1800,
                    scheduledTime: Date(),
                    status: .active,
                    priority: .medium,
                    pointsValue: 20
                ),
                onStart: { print("Start") },
                onComplete: { print("Complete") },
                onSnooze: { interval in print("Snooze: \(interval)") },
                onSkip: { print("Skip") }
            )

            // Critical task
            ActiveTaskCard(
                task: Task(
                    title: "Important client meeting",
                    description: "Discuss project timeline and deliverables",
                    estimatedDuration: 3600,
                    scheduledTime: Date().addingTimeInterval(1800),
                    status: .scheduled,
                    priority: .critical,
                    pointsValue: 50,
                    startTrigger: "15 minutes before meeting"
                ),
                onStart: { print("Start") },
                onComplete: { print("Complete") },
                onSnooze: { interval in print("Snooze: \(interval)") },
                onSkip: { print("Skip") }
            )
        }
        .padding()
    }
    .background(AppColors.background)
}
