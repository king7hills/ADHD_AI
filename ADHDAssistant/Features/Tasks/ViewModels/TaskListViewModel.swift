//
//  TaskListViewModel.swift
//  ADHDAssistant
//
//  ViewModel for managing task list state and operations
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TaskListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var selectedFilter: TaskFilter = .today
    @Published var searchQuery: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?

    // MARK: - Properties

    private let repository: TaskRepositoryProtocol
    private let gamificationCoordinator: GamificationCoordinator
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        repository: TaskRepositoryProtocol = TaskRepository(),
        gamificationCoordinator: GamificationCoordinator = GamificationCoordinator()
    ) {
        self.repository = repository
        self.gamificationCoordinator = gamificationCoordinator

        setupBindings()
        loadTasks()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Subscribe to repository changes
        repository.tasksPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tasks in
                self?.tasks = tasks
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // Filter tasks when search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // Filter tasks when selected filter changes
        $selectedFilter
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Task Filters

    enum TaskFilter: String, CaseIterable {
        case today = "Today"
        case upcoming = "Upcoming"
        case completed = "Completed"
        case all = "All"

        var iconName: String {
            switch self {
            case .today: return "calendar.badge.clock"
            case .upcoming: return "calendar"
            case .completed: return "checkmark.circle.fill"
            case .all: return "list.bullet"
            }
        }
    }

    // MARK: - Data Loading

    func loadTasks() {
        Task {
            isLoading = true
            error = nil

            do {
                let allTasks = try await repository.fetchAll()
                self.tasks = allTasks
                applyFilters()
            } catch {
                self.error = error
            }

            isLoading = false
        }
    }

    func refresh() async {
        isLoading = true
        error = nil

        do {
            let allTasks = try await repository.fetchAll()
            self.tasks = allTasks
            applyFilters()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Filtering

    private func applyFilters() {
        var filtered = tasks

        // Apply status filter
        switch selectedFilter {
        case .today:
            filtered = filterTodayTasks(filtered)
        case .upcoming:
            filtered = filterUpcomingTasks(filtered)
        case .completed:
            filtered = filtered.filter { $0.status.isTerminal }
        case .all:
            break // Show all tasks
        }

        // Apply search query
        if !searchQuery.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchQuery) ||
                (task.description?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                task.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
            }
        }

        // Sort tasks
        filtered = sortTasks(filtered)

        self.filteredTasks = filtered
    }

    private func filterTodayTasks(_ tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return tasks.filter { task in
            guard !task.status.isTerminal else { return false }

            if let scheduledTime = task.scheduledTime {
                return calendar.isDate(scheduledTime, inSameDayAs: today)
            }

            // Include unscheduled tasks that were created today
            return calendar.isDate(task.createdAt, inSameDayAs: today)
        }
    }

    private func filterUpcomingTasks(_ tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return tasks.filter { task in
            guard !task.status.isTerminal else { return false }

            if let scheduledTime = task.scheduledTime {
                return scheduledTime > today && !calendar.isDate(scheduledTime, inSameDayAs: today)
            }

            return false
        }
    }

    private func sortTasks(_ tasks: [Task]) -> [Task] {
        return tasks.sorted { lhs, rhs in
            // Overdue tasks first
            if lhs.isOverdue != rhs.isOverdue {
                return lhs.isOverdue
            }

            // Then by priority
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }

            // Then by scheduled time
            if let lhsTime = lhs.scheduledTime, let rhsTime = rhs.scheduledTime {
                return lhsTime < rhsTime
            }

            if lhs.scheduledTime != nil {
                return true
            }

            if rhs.scheduledTime != nil {
                return false
            }

            // Finally by creation date
            return lhs.createdAt > rhs.createdAt
        }
    }

    // MARK: - Task Operations

    func createTask(_ task: Task) {
        Task {
            do {
                _ = try await repository.create(task)
                HapticManager.shared.success()
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func updateTask(_ task: Task) {
        Task {
            do {
                _ = try await repository.update(task)
                HapticManager.shared.success()
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func deleteTask(_ task: Task) {
        Task {
            do {
                try await repository.delete(task)
                HapticManager.shared.success()
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func completeTask(_ task: Task) {
        var updatedTask = task
        let completedOnTime = !task.isOverdue
        let completedEarly = task.scheduledTime.map { $0 > Date() } ?? false

        updatedTask.complete()

        Task {
            do {
                _ = try await repository.update(updatedTask)

                // Process gamification
                let result = gamificationCoordinator.processEvent(
                    .taskCompleted(updatedTask, completedOnTime: completedOnTime, completedEarly: completedEarly)
                )

                if result.hasRewards {
                    HapticManager.shared.success()
                } else {
                    HapticManager.shared.impact(.medium)
                }

                // Create next occurrence if recurring
                if let nextTask = updatedTask.createNextOccurrence() {
                    _ = try await repository.create(nextTask)
                }
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func snoozeTask(_ task: Task, until date: Date) {
        var updatedTask = task
        updatedTask.snooze(until: date)

        Task {
            do {
                _ = try await repository.update(updatedTask)
                HapticManager.shared.impact(.medium)
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func skipTask(_ task: Task) {
        var updatedTask = task
        updatedTask.skip()

        Task {
            do {
                _ = try await repository.update(updatedTask)
                gamificationCoordinator.processEvent(.taskSkipped(updatedTask))
                HapticManager.shared.impact(.light)
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func toggleTaskCompletion(_ task: Task) {
        if task.isCompleted {
            var updatedTask = task
            updatedTask.status = .created
            updatedTask.completedAt = nil
            updateTask(updatedTask)
        } else {
            completeTask(task)
        }
    }

    // MARK: - Computed Properties

    var todayTasksCount: Int {
        filterTodayTasks(tasks.filter { !$0.status.isTerminal }).count
    }

    var upcomingTasksCount: Int {
        filterUpcomingTasks(tasks.filter { !$0.status.isTerminal }).count
    }

    var completedTasksCount: Int {
        tasks.filter { $0.status.isTerminal }.count
    }

    var overdueTasksCount: Int {
        tasks.filter { $0.isOverdue }.count
    }

    var isEmpty: Bool {
        filteredTasks.isEmpty
    }

    var emptyStateMessage: String {
        if !searchQuery.isEmpty {
            return "No tasks match '\(searchQuery)'"
        }

        switch selectedFilter {
        case .today:
            return "No tasks scheduled for today.\nTake a moment to plan your day!"
        case .upcoming:
            return "No upcoming tasks.\nYou're all caught up!"
        case .completed:
            return "No completed tasks yet.\nComplete a task to see it here!"
        case .all:
            return "No tasks yet.\nCreate your first task to get started!"
        }
    }

    var emptyStateIcon: String {
        if !searchQuery.isEmpty {
            return "magnifyingglass"
        }

        switch selectedFilter {
        case .today:
            return "sun.max"
        case .upcoming:
            return "calendar"
        case .completed:
            return "checkmark.circle"
        case .all:
            return "list.bullet"
        }
    }
}
