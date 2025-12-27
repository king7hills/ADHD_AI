//
//  PointsService.swift
//  ADHDAssistant
//
//  Service for managing gamification points
//

import Foundation
import Combine

// MARK: - Point Event

struct PointEvent: Identifiable {
    let id: UUID
    let points: Int
    let reason: String
    let timestamp: Date
    let multiplier: Double
    let breakdown: String

    init(
        id: UUID = UUID(),
        points: Int,
        reason: String,
        timestamp: Date = Date(),
        multiplier: Double = 1.0,
        breakdown: String = ""
    ) {
        self.id = id
        self.points = points
        self.reason = reason
        self.timestamp = timestamp
        self.multiplier = multiplier
        self.breakdown = breakdown
    }

    var totalPoints: Int {
        Int(Double(points) * multiplier)
    }
}

// MARK: - Point Reason

enum PointReason {
    case taskCompleted(priority: Priority)
    case taskCompletedOnTime
    case taskCompletedEarly
    case subtaskCompleted
    case goalCreated
    case goalCompleted
    case healthMetricLogged
    case dailyStreakMaintained
    case weeklyStreakMaintained
    case achievementUnlocked(tier: AchievementTier)
    case perfectDay
    case custom(String, Int)

    var basePoints: Int {
        switch self {
        case .taskCompleted(let priority):
            switch priority {
            case .low: return 10
            case .medium: return 15
            case .high: return 25
            case .critical: return 40
            }
        case .taskCompletedOnTime: return 5
        case .taskCompletedEarly: return 10
        case .subtaskCompleted: return 3
        case .goalCreated: return 20
        case .goalCompleted: return 100
        case .healthMetricLogged: return 5
        case .dailyStreakMaintained: return 10
        case .weeklyStreakMaintained: return 50
        case .achievementUnlocked(let tier):
            return tier.pointsRequired
        case .perfectDay: return 100
        case .custom(_, let points): return points
        }
    }

    var description: String {
        switch self {
        case .taskCompleted(let priority):
            return "Completed \(priority.displayName.lowercased()) priority task"
        case .taskCompletedOnTime:
            return "Completed task on time"
        case .taskCompletedEarly:
            return "Completed task early"
        case .subtaskCompleted:
            return "Completed subtask"
        case .goalCreated:
            return "Created a new goal"
        case .goalCompleted:
            return "Completed a goal"
        case .healthMetricLogged:
            return "Logged health metric"
        case .dailyStreakMaintained:
            return "Maintained daily streak"
        case .weeklyStreakMaintained:
            return "Maintained 7-day streak"
        case .achievementUnlocked(let tier):
            return "Unlocked \(tier.displayName) achievement"
        case .perfectDay:
            return "Perfect day - all tasks completed"
        case .custom(let desc, _):
            return desc
        }
    }
}

// MARK: - Points Service

class PointsService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var totalPoints: Int
    @Published private(set) var todaysPoints: Int
    @Published private(set) var recentEvents: [PointEvent] = []

    // MARK: - Properties

    private let userDefaultsKeys: UserDefaultsKeys
    private let maxRecentEvents = 20

    // MARK: - Initialization

    init(userDefaultsKeys: UserDefaultsKeys = .shared) {
        self.userDefaultsKeys = userDefaultsKeys

        // Load saved points
        self.totalPoints = userDefaultsKeys.totalPoints
        self.todaysPoints = userDefaultsKeys.todaysPoints

        // Check and reset daily data
        userDefaultsKeys.checkAndResetDailyData()

        // Reload in case it was reset
        self.todaysPoints = userDefaultsKeys.todaysPoints
    }

    // MARK: - Award Points

    /// Award points for a specific reason
    @discardableResult
    func awardPoints(
        for reason: PointReason,
        multiplier: Double = 1.0,
        additionalBreakdown: String? = nil
    ) -> PointEvent {
        let basePoints = reason.basePoints
        let finalMultiplier = multiplier

        var breakdown = "Base: \(basePoints) points"
        if finalMultiplier != 1.0 {
            breakdown += "\nMultiplier: \(String(format: "%.1fx", finalMultiplier))"
        }
        if let additional = additionalBreakdown {
            breakdown += "\n\(additional)"
        }

        let event = PointEvent(
            points: basePoints,
            reason: reason.description,
            multiplier: finalMultiplier,
            breakdown: breakdown
        )

        addPoints(event.totalPoints, event: event)

        return event
    }

    /// Award points for completing a task
    @discardableResult
    func awardTaskCompletion(
        task: Task,
        completedOnTime: Bool = false,
        completedEarly: Bool = false,
        streakMultiplier: Double = 1.0
    ) -> [PointEvent] {
        var events: [PointEvent] = []

        // Base task completion
        let taskEvent = awardPoints(
            for: .taskCompleted(priority: task.priority),
            multiplier: streakMultiplier,
            additionalBreakdown: streakMultiplier > 1.0 ? "Streak bonus: \(String(format: "%.0f%%", (streakMultiplier - 1.0) * 100))" : nil
        )
        events.append(taskEvent)

        // Bonus for on-time completion
        if completedOnTime {
            let bonusEvent = awardPoints(for: .taskCompletedOnTime)
            events.append(bonusEvent)
        }

        // Bonus for early completion
        if completedEarly {
            let bonusEvent = awardPoints(for: .taskCompletedEarly)
            events.append(bonusEvent)
        }

        // Points for completed subtasks
        let completedSubtasks = task.subtasks.filter { $0.isCompleted }.count
        if completedSubtasks > 0 {
            for _ in 0..<completedSubtasks {
                let subtaskEvent = awardPoints(for: .subtaskCompleted)
                events.append(subtaskEvent)
            }
        }

        return events
    }

    /// Award points for health metric logging
    @discardableResult
    func awardHealthMetric() -> PointEvent {
        awardPoints(for: .healthMetricLogged)
    }

    /// Award points for goal activities
    @discardableResult
    func awardGoalCreated() -> PointEvent {
        awardPoints(for: .goalCreated)
    }

    @discardableResult
    func awardGoalCompleted() -> PointEvent {
        awardPoints(for: .goalCompleted)
    }

    /// Award points for streak maintenance
    @discardableResult
    func awardDailyStreak(currentStreak: Int) -> PointEvent {
        let multiplier = calculateStreakMultiplier(currentStreak)
        return awardPoints(
            for: .dailyStreakMaintained,
            multiplier: multiplier,
            additionalBreakdown: currentStreak > 1 ? "Current streak: \(currentStreak) days" : nil
        )
    }

    @discardableResult
    func awardWeeklyStreak() -> PointEvent {
        awardPoints(for: .weeklyStreakMaintained)
    }

    /// Award points for achievement unlock
    @discardableResult
    func awardAchievement(tier: AchievementTier) -> PointEvent {
        awardPoints(for: .achievementUnlocked(tier: tier))
    }

    /// Award points for perfect day
    @discardableResult
    func awardPerfectDay() -> PointEvent {
        awardPoints(for: .perfectDay)
    }

    /// Award custom points
    @discardableResult
    func awardCustomPoints(reason: String, points: Int) -> PointEvent {
        awardPoints(for: .custom(reason, points))
    }

    // MARK: - Private Methods

    private func addPoints(_ points: Int, event: PointEvent) {
        totalPoints += points
        todaysPoints += points

        // Save to UserDefaults
        userDefaultsKeys.totalPoints = totalPoints
        userDefaultsKeys.todaysPoints = todaysPoints

        // Add to recent events
        recentEvents.insert(event, at: 0)
        if recentEvents.count > maxRecentEvents {
            recentEvents = Array(recentEvents.prefix(maxRecentEvents))
        }
    }

    private func calculateStreakMultiplier(_ streak: Int) -> Double {
        switch streak {
        case 0...2: return 1.0
        case 3...6: return 1.1
        case 7...13: return 1.25
        case 14...29: return 1.5
        case 30...89: return 1.75
        default: return 2.0
        }
    }

    // MARK: - Utility Methods

    /// Get today's points progress towards a goal
    func todaysProgress(goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(Double(todaysPoints) / Double(goal), 1.0)
    }

    /// Check if user has enough points for purchase
    func canAfford(cost: Int) -> Bool {
        totalPoints >= cost
    }

    /// Spend points (returns true if successful)
    @discardableResult
    func spendPoints(_ amount: Int, reason: String) -> Bool {
        guard canAfford(cost: amount) else { return false }

        totalPoints -= amount
        userDefaultsKeys.totalPoints = totalPoints

        // Record negative event
        let event = PointEvent(
            points: -amount,
            reason: "Spent: \(reason)",
            breakdown: "Cost: \(amount) points"
        )

        recentEvents.insert(event, at: 0)
        if recentEvents.count > maxRecentEvents {
            recentEvents = Array(recentEvents.prefix(maxRecentEvents))
        }

        return true
    }

    /// Reset daily points (called automatically at midnight)
    func resetDailyPoints() {
        todaysPoints = 0
        userDefaultsKeys.todaysPoints = 0
        userDefaultsKeys.lastPointsResetDate = Date()
    }

    /// Get streak bonus multiplier for display
    func getStreakMultiplier(streak: Int) -> Double {
        calculateStreakMultiplier(streak)
    }

    /// Get formatted points string
    func formattedPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
}

// MARK: - Mock Service for Testing

class MockPointsService: ObservableObject {
    @Published var totalPoints: Int = 0
    @Published var todaysPoints: Int = 0
    @Published var recentEvents: [PointEvent] = []

    func awardPoints(for reason: PointReason, multiplier: Double = 1.0, additionalBreakdown: String? = nil) -> PointEvent {
        let points = Int(Double(reason.basePoints) * multiplier)
        totalPoints += points
        todaysPoints += points

        let event = PointEvent(
            points: reason.basePoints,
            reason: reason.description,
            multiplier: multiplier
        )
        recentEvents.insert(event, at: 0)
        return event
    }

    func awardTaskCompletion(task: Task, completedOnTime: Bool = false, completedEarly: Bool = false, streakMultiplier: Double = 1.0) -> [PointEvent] {
        let event = awardPoints(for: .taskCompleted(priority: task.priority), multiplier: streakMultiplier)
        return [event]
    }

    func awardHealthMetric() -> PointEvent {
        awardPoints(for: .healthMetricLogged)
    }

    func awardGoalCreated() -> PointEvent {
        awardPoints(for: .goalCreated)
    }

    func awardGoalCompleted() -> PointEvent {
        awardPoints(for: .goalCompleted)
    }

    func spendPoints(_ amount: Int, reason: String) -> Bool {
        guard totalPoints >= amount else { return false }
        totalPoints -= amount
        return true
    }

    func getStreakMultiplier(streak: Int) -> Double {
        switch streak {
        case 0...2: return 1.0
        case 3...6: return 1.1
        case 7...13: return 1.25
        default: return 1.5
        }
    }
}
