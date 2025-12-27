//
//  DashboardViewModel.swift
//  ADHDAssistant
//
//  Dashboard ViewModel - Manages dashboard state and logic
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var activeTask: Task?
    @Published private(set) var upcomingTasks: [Task] = []
    @Published private(set) var todayStats: DailyStats = DailyStats()
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var userProfile: UserProfile?

    // MARK: - Dependencies

    private let taskRepository: TaskRepositoryProtocol
    private let gamificationCoordinator: GamificationCoordinator
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        taskRepository: TaskRepositoryProtocol = TaskRepository(),
        gamificationCoordinator: GamificationCoordinator = GamificationCoordinator()
    ) {
        self.taskRepository = taskRepository
        self.gamificationCoordinator = gamificationCoordinator

        setupSubscriptions()
        loadUserProfile()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to task updates
        taskRepository.tasksPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshTasks()
                }
            }
            .store(in: &cancellables)
    }

    private func loadUserProfile() {
        // Load from UserDefaults or default
        let name = UserDefaults.standard.string(forKey: "userName") ?? "User"
        let totalPoints = UserDefaults.standard.integer(forKey: "totalPoints")
        let currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        let longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
        let level = UserDefaults.standard.integer(forKey: "userLevel")

        self.userProfile = UserProfile(
            name: name,
            totalPoints: totalPoints,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            level: max(level, 1)
        )
    }

    // MARK: - Public Methods

    /// Load dashboard data
    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load all tasks for today
            let allTasks = try await taskRepository.fetchForDate(Date())

            // Identify active task (highest priority incomplete task)
            activeTask = allTasks
                .filter { !$0.status.isTerminal && $0.status != .snoozed }
                .sorted { task1, task2 in
                    // Sort by priority, then by scheduled time
                    if task1.priority.sortOrder != task2.priority.sortOrder {
                        return task1.priority.sortOrder < task2.priority.sortOrder
                    }
                    return (task1.scheduledTime ?? Date.distantFuture) < (task2.scheduledTime ?? Date.distantFuture)
                }
                .first

            // Get upcoming tasks (next 5)
            upcomingTasks = allTasks
                .filter { !$0.status.isTerminal && $0.id != activeTask?.id }
                .sorted { ($0.scheduledTime ?? Date.distantFuture) < ($1.scheduledTime ?? Date.distantFuture) }
                .prefix(5)
                .map { $0 }

            // Calculate today's stats
            await calculateTodayStats(from: allTasks)

            isLoading = false
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Refresh data (for pull-to-refresh)
    func refreshData() async {
        await loadDashboard()
    }

    /// Complete the active task
    func completeTask(_ task: Task) async {
        do {
            var updatedTask = task
            updatedTask.complete()

            _ = try await taskRepository.update(updatedTask)

            // Award points and trigger gamification
            let onTime = !task.isOverdue
            let early = (task.scheduledTime ?? Date()) > Date()

            let result = gamificationCoordinator.processEvent(
                .taskCompleted(updatedTask, completedOnTime: onTime, completedEarly: early)
            )

            // Update user profile with new points
            if let profile = userProfile {
                var updated = profile
                _ = updated.addPoints(result.totalPoints)
                userProfile = updated
                saveUserProfile(updated)
            }

            // Reload dashboard
            await loadDashboard()
        } catch {
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
        }
    }

    /// Snooze task for a duration
    func snoozeTask(_ task: Task, duration: TimeInterval) async {
        do {
            var updatedTask = task
            let snoozeUntil = Date().addingTimeInterval(duration)
            updatedTask.snooze(until: snoozeUntil)

            _ = try await taskRepository.update(updatedTask)

            // Reload dashboard
            await loadDashboard()
        } catch {
            errorMessage = "Failed to snooze task: \(error.localizedDescription)"
        }
    }

    /// Skip task
    func skipTask(_ task: Task) async {
        do {
            var updatedTask = task
            updatedTask.skip()

            _ = try await taskRepository.update(updatedTask)

            // Process skip event
            _ = gamificationCoordinator.processEvent(.taskSkipped(updatedTask))

            // Reload dashboard
            await loadDashboard()
        } catch {
            errorMessage = "Failed to skip task: \(error.localizedDescription)"
        }
    }

    /// Start a task
    func startTask(_ task: Task) async {
        do {
            var updatedTask = task
            updatedTask.start()

            _ = try await taskRepository.update(updatedTask)

            // Reload dashboard
            await loadDashboard()
        } catch {
            errorMessage = "Failed to start task: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    private func calculateTodayStats(from tasks: [Task]) async {
        let completedTasks = tasks.filter { $0.isCompleted }
        let totalTasks = tasks.filter { !$0.status.isTerminal || $0.isCompleted }

        // Get today's points from gamification service
        let gamificationStatus = gamificationCoordinator.getCurrentStatus()

        // Calculate daily goal progress (based on tasks completed)
        let dailyGoalProgress: Double
        if totalTasks.isEmpty {
            dailyGoalProgress = 0.0
        } else {
            dailyGoalProgress = Double(completedTasks.count) / Double(totalTasks.count)
        }

        todayStats = DailyStats(
            tasksCompleted: completedTasks.count,
            totalTasks: totalTasks.count,
            pointsEarned: gamificationStatus.todaysPoints,
            streakCount: gamificationStatus.currentStreak,
            dailyGoalProgress: dailyGoalProgress
        )
    }

    private func saveUserProfile(_ profile: UserProfile) {
        UserDefaults.standard.set(profile.name, forKey: "userName")
        UserDefaults.standard.set(profile.totalPoints, forKey: "totalPoints")
        UserDefaults.standard.set(profile.currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(profile.longestStreak, forKey: "longestStreak")
        UserDefaults.standard.set(profile.level, forKey: "userLevel")
    }

    private func refreshTasks() async {
        // Silently refresh tasks without showing loading state
        do {
            let allTasks = try await taskRepository.fetchForDate(Date())

            activeTask = allTasks
                .filter { !$0.status.isTerminal && $0.status != .snoozed }
                .sorted { task1, task2 in
                    if task1.priority.sortOrder != task2.priority.sortOrder {
                        return task1.priority.sortOrder < task2.priority.sortOrder
                    }
                    return (task1.scheduledTime ?? Date.distantFuture) < (task2.scheduledTime ?? Date.distantFuture)
                }
                .first

            upcomingTasks = allTasks
                .filter { !$0.status.isTerminal && $0.id != activeTask?.id }
                .sorted { ($0.scheduledTime ?? Date.distantFuture) < ($1.scheduledTime ?? Date.distantFuture) }
                .prefix(5)
                .map { $0 }

            await calculateTodayStats(from: allTasks)
        } catch {
            // Silent failure for background refresh
        }
    }
}

// MARK: - Daily Stats Model

struct DailyStats {
    var tasksCompleted: Int = 0
    var totalTasks: Int = 0
    var pointsEarned: Int = 0
    var streakCount: Int = 0
    var dailyGoalProgress: Double = 0.0

    var completionPercentage: Int {
        guard totalTasks > 0 else { return 0 }
        return Int((Double(tasksCompleted) / Double(totalTasks)) * 100)
    }

    var hasCompletedAll: Bool {
        totalTasks > 0 && tasksCompleted == totalTasks
    }
}

// MARK: - Mock ViewModel for Previews

class MockDashboardViewModel: ObservableObject {
    @Published var activeTask: Task?
    @Published var upcomingTasks: [Task] = []
    @Published var todayStats: DailyStats = DailyStats()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?

    init() {
        // Sample data
        self.userProfile = UserProfile.sample
        self.activeTask = Task.sample
        self.upcomingTasks = [
            Task.sampleWithRecurrence,
            Task.aiGeneratedSample
        ]
        self.todayStats = DailyStats(
            tasksCompleted: 5,
            totalTasks: 8,
            pointsEarned: 125,
            streakCount: 7,
            dailyGoalProgress: 0.625
        )
    }

    func loadDashboard() async {}
    func refreshData() async {}
    func completeTask(_ task: Task) async {}
    func snoozeTask(_ task: Task, duration: TimeInterval) async {}
    func skipTask(_ task: Task) async {}
    func startTask(_ task: Task) async {}
}
