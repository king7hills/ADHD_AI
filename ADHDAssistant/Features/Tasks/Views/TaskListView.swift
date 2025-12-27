//
//  TaskListView.swift
//  ADHDAssistant
//
//  Main view for displaying and managing tasks
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel: TaskListViewModel
    @State private var showCreateSheet: Bool = false
    @State private var selectedTask: Task?
    @State private var showTaskDetail: Bool = false

    init(viewModel: TaskListViewModel = TaskListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Filter Segmented Control
                    filterSegmentedControl
                        .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                        .padding(.top, AppSpacing.sm)

                    // Search Bar
                    searchBar
                        .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                        .padding(.vertical, AppSpacing.sm)

                    // Task List
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        taskList
                    }
                }
                .background(AppColors.background)

                // Floating Action Button
                floatingActionButton
                    .padding(AppSpacing.lg)
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showCreateSheet) {
                TaskCreationSheet { task in
                    viewModel.createTask(task)
                }
            }
            .sheet(item: $selectedTask) { task in
                NavigationStack {
                    TaskDetailView(viewModel: TaskDetailViewModel(task: task))
                }
            }
        }
    }

    // MARK: - Filter Segmented Control

    private var filterSegmentedControl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(TaskListViewModel.TaskFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: viewModel.selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xs)
        }
    }

    private func countForFilter(_ filter: TaskListViewModel.TaskFilter) -> Int {
        switch filter {
        case .today:
            return viewModel.todayTasksCount
        case .upcoming:
            return viewModel.upcomingTasksCount
        case .completed:
            return viewModel.completedTasksCount
        case .all:
            return viewModel.tasks.count
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(.system(size: AppSpacing.iconSizeMedium))

            TextField("Search tasks...", text: $viewModel.searchQuery)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.system(size: AppSpacing.iconSizeMedium))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                // Overdue section
                if viewModel.overdueTasksCount > 0 && viewModel.selectedFilter != .completed {
                    overdueSection
                }

                // Main task list
                ForEach(viewModel.filteredTasks) { task in
                    TaskRow(task: task) {
                        viewModel.toggleTaskCompletion(task)
                    }
                    .onTapGesture {
                        selectedTask = task
                        showTaskDetail = true
                    }
                    .contextMenu {
                        taskContextMenu(for: task)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        taskSwipeActions(for: task)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontalPadding)
            .padding(.vertical, AppSpacing.md)
            .padding(.bottom, 80) // Space for FAB
        }
    }

    // MARK: - Overdue Section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColors.error)
                Text("Overdue Tasks (\(viewModel.overdueTasksCount))")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.error)
            }
            .padding(.horizontal, AppSpacing.md)

            Divider()
                .background(AppColors.error.opacity(0.3))
        }
    }

    // MARK: - Context Menu & Swipe Actions

    @ViewBuilder
    private func taskContextMenu(for task: Task) -> some View {
        if !task.isCompleted {
            Button {
                viewModel.completeTask(task)
            } label: {
                Label("Complete", systemImage: "checkmark.circle")
            }

            Button {
                snoozeTask(task)
            } label: {
                Label("Snooze", systemImage: "clock.arrow.circlepath")
            }

            Button {
                viewModel.skipTask(task)
            } label: {
                Label("Skip", systemImage: "forward")
            }
        }

        Button(role: .destructive) {
            viewModel.deleteTask(task)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    @ViewBuilder
    private func taskSwipeActions(for task: Task) -> some View {
        if !task.isCompleted {
            Button {
                viewModel.completeTask(task)
            } label: {
                Label("Done", systemImage: "checkmark")
            }
            .tint(AppColors.success)

            Button {
                snoozeTask(task)
            } label: {
                Label("Snooze", systemImage: "clock")
            }
            .tint(AppColors.warning)

            Button {
                viewModel.skipTask(task)
            } label: {
                Label("Skip", systemImage: "forward")
            }
            .tint(AppColors.textSecondary)
        }

        Button(role: .destructive) {
            viewModel.deleteTask(task)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func snoozeTask(_ task: Task) {
        // Snooze for 1 hour by default
        let snoozeDate = Date().addingTimeInterval(3600)
        viewModel.snoozeTask(task, until: snoozeDate)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: viewModel.emptyStateIcon)
                .font(.system(size: 72))
                .foregroundColor(AppColors.textTertiary)

            Text(viewModel.emptyStateMessage)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            if viewModel.selectedFilter == .today || viewModel.selectedFilter == .all {
                Button {
                    showCreateSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Task")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                }
            }

            Spacer()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Spacer()
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        Button {
            HapticManager.shared.impact(.medium)
            showCreateSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 56, height: 56)
                    .shadow(color: AppColors.shadow.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Button

private struct FilterButton: View {
    let filter: TaskListViewModel.TaskFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: filter.iconName)
                    .font(.system(size: AppSpacing.iconSizeSmall))

                Text(filter.rawValue)
                    .font(AppTypography.subheadline)

                if count > 0 {
                    Text("\(count)")
                        .font(AppTypography.caption)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white.opacity(0.3) : AppColors.surface)
                        .cornerRadius(AppSpacing.cornerRadiusXS)
                }
            }
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColors.primary : AppColors.surface)
            .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider

#Preview("Task List View") {
    TaskListView(viewModel: TaskListViewModel(
        repository: MockTaskRepository(initialTasks: [
            Task.sample,
            Task.sampleWithRecurrence,
            Task.aiGeneratedSample
        ])
    ))
}

#Preview("Empty State") {
    TaskListView(viewModel: TaskListViewModel(
        repository: MockTaskRepository(initialTasks: [])
    ))
}
