//
//  DashboardView.swift
//  ADHDAssistant
//
//  Main Dashboard View - Hub of the app
//

import SwiftUI

/// Main dashboard view showing overview and current task
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    @State private var showTaskDetails = false
    @State private var selectedTask: Task?

    init(viewModel: DashboardViewModel = DashboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.background
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.activeTask == nil {
                    // Initial loading state
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Greeting section
                            if let profile = viewModel.userProfile {
                                DailyGreeting(userName: profile.name)
                                    .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                            }

                            // Streak badge
                            HStack {
                                StreakBadge(
                                    streakCount: viewModel.todayStats.streakCount,
                                    size: .medium,
                                    showLabel: true
                                )

                                Spacer()

                                // Level indicator
                                if let profile = viewModel.userProfile {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppColors.accent)

                                        Text("Level \(profile.level)")
                                            .font(AppTypography.subheadline)
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColors.card)
                                    .clipShape(Capsule())
                                    .cardShadow()
                                }
                            }
                            .padding(.horizontal, AppSpacing.screenHorizontalPadding)

                            // Quick stats
                            QuickStatsView(
                                tasksCompleted: viewModel.todayStats.tasksCompleted,
                                totalTasks: viewModel.todayStats.totalTasks,
                                pointsEarned: viewModel.todayStats.pointsEarned,
                                streakCount: viewModel.todayStats.streakCount,
                                dailyGoalProgress: viewModel.todayStats.dailyGoalProgress
                            )
                            .padding(.horizontal, AppSpacing.screenHorizontalPadding)

                            // Active task card
                            if let activeTask = viewModel.activeTask {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    ActiveTaskCard(
                                        task: activeTask,
                                        onStart: {
                                            Task {
                                                await viewModel.startTask(activeTask)
                                            }
                                        },
                                        onComplete: {
                                            Task {
                                                await viewModel.completeTask(activeTask)
                                            }
                                        },
                                        onSnooze: { duration in
                                            Task {
                                                await viewModel.snoozeTask(activeTask, duration: duration)
                                            }
                                        },
                                        onSkip: {
                                            Task {
                                                await viewModel.skipTask(activeTask)
                                            }
                                        }
                                    )
                                }
                                .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                            } else {
                                // No active task state
                                NoActiveTaskView()
                                    .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                            }

                            // Upcoming tasks preview
                            UpcomingTasksPreview(
                                tasks: viewModel.upcomingTasks,
                                onTaskTap: { task in
                                    selectedTask = task
                                    showTaskDetails = true
                                },
                                onViewAllTap: {
                                    // Navigate to Tasks view
                                    // This would be handled by the parent navigation
                                }
                            )
                            .padding(.horizontal, AppSpacing.screenHorizontalPadding)

                            // Motivational quote or tip
                            MotivationalTipCard()
                                .padding(.horizontal, AppSpacing.screenHorizontalPadding)

                            // Bottom spacing
                            Spacer()
                                .frame(height: AppSpacing.xl)
                        }
                        .padding(.vertical, AppSpacing.screenVerticalPadding)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Navigate to settings or profile
                    }) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                // Clear error
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

/// No active task state view
private struct NoActiveTaskView: View {
    var body: some View {
        GlowingCard(
            glowColor: AppColors.success,
            glowIntensity: .subtle,
            cornerRadius: AppSpacing.cornerRadiusLarge,
            padding: AppSpacing.cardPaddingLarge
        ) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.success)

                Text("All Caught Up!")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Text("No active tasks right now. Great work!")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    // Navigate to create task
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Task")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.buttonPaddingVertical)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
                }
                .padding(.top, AppSpacing.sm)
            }
        }
    }
}

/// Motivational tip card
private struct MotivationalTipCard: View {
    @State private var currentTipIndex: Int = 0

    private let tips = [
        ("💡", "Break large tasks into smaller, manageable steps"),
        ("⏰", "Use timers to maintain focus and prevent burnout"),
        ("🎯", "Prioritize tasks by importance, not urgency"),
        ("🧘", "Take short breaks between tasks to recharge"),
        ("📝", "Write down tasks to free up mental space"),
        ("🌟", "Celebrate small wins to build momentum"),
        ("🔄", "Review and adjust your goals regularly"),
        ("💪", "Consistency beats perfection every time")
    ]

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(tips[currentTipIndex].0)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Tip")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)

                Text(tips[currentTipIndex].1)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: {
                withAnimation {
                    currentTipIndex = (currentTipIndex + 1) % tips.count
                }
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .cardShadow()
        .onAppear {
            // Randomize initial tip
            currentTipIndex = Int.random(in: 0..<tips.count)
        }
    }
}

// MARK: - Preview Provider

#Preview("Dashboard View") {
    DashboardView(viewModel: DashboardViewModel())
}

#Preview("Dashboard with Mock Data") {
    DashboardView(viewModel: DashboardViewModel(
        taskRepository: MockTaskRepository(initialTasks: [
            Task(
                title: "Review morning medications",
                description: "Take metformin and check blood sugar",
                estimatedDuration: 300,
                scheduledTime: Date().addingTimeInterval(900),
                status: .scheduled,
                priority: .high,
                subtasks: [
                    Subtask(title: "Take metformin"),
                    Subtask(title: "Check blood sugar")
                ],
                pointsValue: 15,
                startTrigger: "After breakfast"
            ),
            Task(
                title: "Morning exercise",
                estimatedDuration: 1800,
                scheduledTime: Date().addingTimeInterval(3600),
                status: .scheduled,
                priority: .medium,
                pointsValue: 20
            ),
            Task(
                title: "Prepare lunch",
                estimatedDuration: 1200,
                scheduledTime: Date().addingTimeInterval(10800),
                status: .scheduled,
                priority: .medium,
                pointsValue: 15
            ),
            Task(
                title: "Completed task",
                estimatedDuration: 900,
                scheduledTime: Date().addingTimeInterval(-3600),
                status: .completed,
                priority: .low,
                pointsValue: 10
            )
        ])
    ))
}

#Preview("Dashboard - No Tasks") {
    DashboardView(viewModel: DashboardViewModel(
        taskRepository: MockTaskRepository(initialTasks: [])
    ))
}
