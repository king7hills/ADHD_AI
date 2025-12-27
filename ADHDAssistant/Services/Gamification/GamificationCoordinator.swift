//
//  GamificationCoordinator.swift
//  ADHDAssistant
//
//  Coordinator that ties all gamification services together
//

import Foundation
import Combine
import SwiftUI

// MARK: - Game Event

enum GameEvent {
    // Task Events
    case taskCompleted(Task, completedOnTime: Bool, completedEarly: Bool)
    case taskCreated(Task)
    case taskSkipped(Task)
    case subtaskCompleted(Task)

    // Goal Events
    case goalCreated(Goal)
    case goalCompleted(Goal)
    case goalMilestoneReached(Goal)

    // Health Events
    case healthMetricLogged(HealthMetric)
    case healthStreakMaintained(days: Int)

    // Streak Events
    case dailyCompletionRecorded
    case streakMilestone(days: Int)
    case streakBroken
    case streakRecovered

    // Achievement Events
    case achievementUnlocked(Achievement)

    // Special Events
    case perfectDay
    case nightOwlActivity
    case earlyBirdActivity
    case speedCompletion
    case perfectWeek

    // AI Events
    case aiTaskCompleted(Task)
    case aiSuggestionAccepted
}

// MARK: - Gamification Result

struct GamificationResult {
    let pointsAwarded: [PointEvent]
    let achievementsUnlocked: [Achievement]
    let celebrationTriggered: Bool
    let newStreak: Int?
    let messages: [String]

    var totalPoints: Int {
        pointsAwarded.reduce(0) { $0 + $1.totalPoints }
    }

    var hasRewards: Bool {
        !pointsAwarded.isEmpty || !achievementsUnlocked.isEmpty
    }

    var summary: String {
        var parts: [String] = []

        if totalPoints > 0 {
            parts.append("+\(totalPoints) points")
        }

        if !achievementsUnlocked.isEmpty {
            let count = achievementsUnlocked.count
            parts.append("\(count) achievement\(count == 1 ? "" : "s")")
        }

        if let streak = newStreak, streak > 0 {
            parts.append("\(streak) day streak")
        }

        return parts.isEmpty ? "No rewards" : parts.joined(separator: ", ")
    }
}

// MARK: - Gamification Coordinator

class GamificationCoordinator: ObservableObject {
    // MARK: - Services

    @Published var pointsService: PointsService
    @Published var streakService: StreakService
    @Published var achievementService: AchievementService
    @Published var celebrationService: CelebrationService

    // MARK: - Published State

    @Published private(set) var lastResult: GamificationResult?
    @Published private(set) var isProcessing: Bool = false

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        pointsService: PointsService = PointsService(),
        streakService: StreakService = StreakService(),
        achievementService: AchievementService = AchievementService(),
        celebrationService: CelebrationService = CelebrationService()
    ) {
        self.pointsService = pointsService
        self.streakService = streakService
        self.achievementService = achievementService
        self.celebrationService = celebrationService
    }

    // MARK: - Process Events

    /// Process a single game event
    @discardableResult
    func processEvent(_ event: GameEvent) -> GamificationResult {
        isProcessing = true
        defer { isProcessing = false }

        var pointEvents: [PointEvent] = []
        var achievementsUnlocked: [Achievement] = []
        var celebrationTriggered = false
        var newStreak: Int? = nil
        var messages: [String] = []

        switch event {
        case .taskCompleted(let task, let onTime, let early):
            let result = handleTaskCompletion(task: task, onTime: onTime, early: early)
            pointEvents.append(contentsOf: result.points)
            achievementsUnlocked.append(contentsOf: result.achievements)
            celebrationTriggered = result.celebrate
            messages.append(contentsOf: result.messages)

        case .taskCreated(let task):
            messages.append("Task created: \(task.title)")

        case .taskSkipped:
            messages.append("Task skipped")

        case .subtaskCompleted(let task):
            let points = pointsService.awardPoints(for: .subtaskCompleted)
            pointEvents.append(points)
            messages.append("Subtask completed")

        case .goalCreated(let goal):
            let result = handleGoalCreated(goal: goal)
            pointEvents.append(contentsOf: result.points)
            achievementsUnlocked.append(contentsOf: result.achievements)
            messages.append(contentsOf: result.messages)

        case .goalCompleted(let goal):
            let result = handleGoalCompleted(goal: goal)
            pointEvents.append(contentsOf: result.points)
            achievementsUnlocked.append(contentsOf: result.achievements)
            celebrationTriggered = result.celebrate
            messages.append(contentsOf: result.messages)

        case .healthMetricLogged(let metric):
            let result = handleHealthMetric(metric: metric)
            pointEvents.append(contentsOf: result.points)
            achievementsUnlocked.append(contentsOf: result.achievements)
            messages.append(contentsOf: result.messages)

        case .dailyCompletionRecorded:
            let result = handleDailyCompletion()
            pointEvents.append(contentsOf: result.points)
            achievementsUnlocked.append(contentsOf: result.achievements)
            newStreak = result.newStreak
            celebrationTriggered = result.celebrate
            messages.append(contentsOf: result.messages)

        case .streakMilestone(let days):
            celebrationService.celebrateStreak(days: days)
            celebrationTriggered = true

        case .achievementUnlocked(let achievement):
            achievementsUnlocked.append(achievement)
            celebrationService.celebrateAchievement(achievement)
            celebrationTriggered = true

        case .perfectDay:
            let result = handlePerfectDay()
            pointEvents.append(contentsOf: result.points)
            achievementsUnlocked.append(contentsOf: result.achievements)
            celebrationTriggered = result.celebrate
            messages.append(contentsOf: result.messages)

        case .nightOwlActivity:
            let achievements = achievementService.trackEvent(.nightOwlTask)
            achievementsUnlocked.append(contentsOf: achievements)

        case .earlyBirdActivity:
            let achievements = achievementService.trackEvent(.earlyBirdTask)
            achievementsUnlocked.append(contentsOf: achievements)

        case .speedCompletion:
            let achievements = achievementService.trackEvent(.speedTask)
            achievementsUnlocked.append(contentsOf: achievements)

        case .perfectWeek:
            let achievements = achievementService.trackEvent(.perfectWeek)
            achievementsUnlocked.append(contentsOf: achievements)
            celebrationTriggered = true

        case .aiTaskCompleted(let task):
            let result = handleTaskCompletion(task: task, onTime: false, early: false)
            pointEvents.append(contentsOf: result.points)
            achievementsUnlocked.append(contentsOf: result.achievements)
            let aiAchievements = achievementService.trackEvent(.aiTaskCompleted)
            achievementsUnlocked.append(contentsOf: aiAchievements)

        default:
            break
        }

        // Award points for newly unlocked achievements
        for achievement in achievementsUnlocked {
            let points = pointsService.awardAchievement(tier: achievement.tier)
            pointEvents.append(points)

            // Celebrate achievement
            celebrationService.celebrateAchievement(achievement)
            celebrationTriggered = true
        }

        let result = GamificationResult(
            pointsAwarded: pointEvents,
            achievementsUnlocked: achievementsUnlocked,
            celebrationTriggered: celebrationTriggered,
            newStreak: newStreak,
            messages: messages
        )

        lastResult = result
        return result
    }

    /// Process multiple events at once
    @discardableResult
    func processEvents(_ events: [GameEvent]) -> GamificationResult {
        var allPoints: [PointEvent] = []
        var allAchievements: [Achievement] = []
        var anyCelebration = false
        var latestStreak: Int? = nil
        var allMessages: [String] = []

        for event in events {
            let result = processEvent(event)
            allPoints.append(contentsOf: result.pointsAwarded)
            allAchievements.append(contentsOf: result.achievementsUnlocked)
            anyCelebration = anyCelebration || result.celebrationTriggered
            latestStreak = result.newStreak ?? latestStreak
            allMessages.append(contentsOf: result.messages)
        }

        let combinedResult = GamificationResult(
            pointsAwarded: allPoints,
            achievementsUnlocked: allAchievements,
            celebrationTriggered: anyCelebration,
            newStreak: latestStreak,
            messages: allMessages
        )

        lastResult = combinedResult
        return combinedResult
    }

    // MARK: - Event Handlers

    private func handleTaskCompletion(
        task: Task,
        onTime: Bool,
        early: Bool
    ) -> (points: [PointEvent], achievements: [Achievement], celebrate: Bool, messages: [String]) {
        var points: [PointEvent] = []
        var achievements: [Achievement] = []
        var messages: [String] = []

        // Award points with streak multiplier
        let streakMultiplier = streakService.getStreakMultiplier()
        let taskPoints = pointsService.awardTaskCompletion(
            task: task,
            completedOnTime: onTime,
            completedEarly: early,
            streakMultiplier: streakMultiplier
        )
        points.append(contentsOf: taskPoints)

        // Track achievements
        var achievementEvents: [AchievementEvent] = [.taskCompleted]

        if onTime {
            achievementEvents.append(.taskCompletedOnTime)
        }

        // Check for special achievements
        if isNightOwl(task) {
            achievementEvents.append(.nightOwlTask)
        } else if isEarlyBird(task) {
            achievementEvents.append(.earlyBirdTask)
        }

        if isSpeedCompletion(task) {
            achievementEvents.append(.speedTask)
        }

        let newAchievements = achievementService.trackEvents(achievementEvents)
        achievements.append(contentsOf: newAchievements)

        // Celebrate
        celebrationService.celebrateTaskCompletion(task: task)

        messages.append("Task completed: \(task.title)")

        return (points, achievements, true, messages)
    }

    private func handleGoalCreated(
        goal: Goal
    ) -> (points: [PointEvent], achievements: [Achievement], messages: [String]) {
        let points = pointsService.awardGoalCreated()
        let achievements = achievementService.trackEvent(.goalCreated)

        return ([points], achievements, ["Goal created: \(goal.title)"])
    }

    private func handleGoalCompleted(
        goal: Goal
    ) -> (points: [PointEvent], achievements: [Achievement], celebrate: Bool, messages: [String]) {
        let points = pointsService.awardGoalCompleted()
        let achievements = achievementService.trackEvent(.goalCompleted)

        celebrationService.celebrateGoalCompletion(goal: goal)

        return ([points], achievements, true, ["Goal completed: \(goal.title)"])
    }

    private func handleHealthMetric(
        metric: HealthMetric
    ) -> (points: [PointEvent], achievements: [Achievement], messages: [String]) {
        let points = pointsService.awardHealthMetric()
        let achievements = achievementService.trackEvent(.healthMetricLogged)

        return ([points], achievements, ["Health metric logged: \(metric.type.displayName)"])
    }

    private func handleDailyCompletion(
    ) -> (points: [PointEvent], achievements: [Achievement], newStreak: Int?, celebrate: Bool, messages: [String]) {
        var points: [PointEvent] = []
        var achievements: [Achievement] = []
        var messages: [String] = []

        // Record daily completion
        if streakService.recordDailyCompletion() {
            let currentStreak = streakService.currentStreak

            // Award streak points
            let streakPoints = pointsService.awardDailyStreak(currentStreak: currentStreak)
            points.append(streakPoints)

            // Check for streak milestones
            let streakAchievements = achievementService.trackEvent(.streakDay(currentStreak))
            achievements.append(contentsOf: streakAchievements)

            // Check for point achievements
            let pointAchievements = achievementService.trackEvent(.pointsMilestone(pointsService.totalPoints))
            achievements.append(contentsOf: pointAchievements)

            messages.append("Daily streak: \(currentStreak) days")

            // Celebrate milestones
            let celebrate = currentStreak % 7 == 0 || currentStreak == 3 || currentStreak == 30
            if celebrate {
                celebrationService.celebrateStreak(days: currentStreak)
            }

            return (points, achievements, currentStreak, celebrate, messages)
        }

        return (points, achievements, nil, false, messages)
    }

    private func handlePerfectDay(
    ) -> (points: [PointEvent], achievements: [Achievement], celebrate: Bool, messages: [String]) {
        let points = pointsService.awardPerfectDay()
        let achievements = achievementService.trackEvent(.perfectWeek)

        celebrationService.playRandomCelebration(message: "Perfect Day! All tasks completed!")

        return ([points], achievements, true, ["Perfect day achieved!"])
    }

    // MARK: - Helper Methods

    private func isNightOwl(_ task: Task) -> Bool {
        guard let completedAt = task.completedAt else { return false }
        let hour = Calendar.current.component(.hour, from: completedAt)
        return hour >= 22 || hour < 6
    }

    private func isEarlyBird(_ task: Task) -> Bool {
        guard let completedAt = task.completedAt else { return false }
        let hour = Calendar.current.component(.hour, from: completedAt)
        return hour >= 4 && hour < 6
    }

    private func isSpeedCompletion(_ task: Task) -> Bool {
        guard let actualDuration = task.actualDuration else { return false }
        return actualDuration < 300 // 5 minutes
    }

    // MARK: - Public Utilities

    /// Get current gamification status
    func getCurrentStatus() -> GamificationStatus {
        GamificationStatus(
            totalPoints: pointsService.totalPoints,
            todaysPoints: pointsService.todaysPoints,
            currentStreak: streakService.currentStreak,
            longestStreak: streakService.longestStreak,
            achievementsUnlocked: achievementService.unlockedAchievements.count,
            totalAchievements: achievementService.achievements.count,
            streakMultiplier: streakService.getStreakMultiplier(),
            unlockedCelebrations: celebrationService.unlockedStyles.count
        )
    }

    /// Reset all gamification data
    func resetAll() {
        UserDefaultsKeys.shared.resetGamification()
        achievementService.resetAllAchievements()
        lastResult = nil
    }
}

// MARK: - Gamification Status

struct GamificationStatus {
    let totalPoints: Int
    let todaysPoints: Int
    let currentStreak: Int
    let longestStreak: Int
    let achievementsUnlocked: Int
    let totalAchievements: Int
    let streakMultiplier: Double
    let unlockedCelebrations: Int

    var achievementProgress: Double {
        guard totalAchievements > 0 else { return 0 }
        return Double(achievementsUnlocked) / Double(totalAchievements)
    }

    var achievementPercentage: Int {
        Int(achievementProgress * 100)
    }
}

// MARK: - Mock Coordinator for Testing

class MockGamificationCoordinator: ObservableObject {
    @Published var pointsService: MockPointsService = MockPointsService()
    @Published var streakService: MockStreakService = MockStreakService()
    @Published var achievementService: MockAchievementService = MockAchievementService()
    @Published var celebrationService: MockCelebrationService = MockCelebrationService()

    @Published var lastResult: GamificationResult?
    @Published var isProcessing: Bool = false

    func processEvent(_ event: GameEvent) -> GamificationResult {
        let result = GamificationResult(
            pointsAwarded: [],
            achievementsUnlocked: [],
            celebrationTriggered: false,
            newStreak: nil,
            messages: ["Event processed"]
        )
        lastResult = result
        return result
    }

    func processEvents(_ events: [GameEvent]) -> GamificationResult {
        let result = GamificationResult(
            pointsAwarded: [],
            achievementsUnlocked: [],
            celebrationTriggered: false,
            newStreak: nil,
            messages: ["\(events.count) events processed"]
        )
        lastResult = result
        return result
    }

    func getCurrentStatus() -> GamificationStatus {
        GamificationStatus(
            totalPoints: pointsService.totalPoints,
            todaysPoints: pointsService.todaysPoints,
            currentStreak: streakService.currentStreak,
            longestStreak: streakService.longestStreak,
            achievementsUnlocked: achievementService.unlockedAchievements.count,
            totalAchievements: achievementService.achievements.count,
            streakMultiplier: 1.0,
            unlockedCelebrations: celebrationService.unlockedStyles.count
        )
    }
}
