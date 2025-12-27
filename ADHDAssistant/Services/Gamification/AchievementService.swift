//
//  AchievementService.swift
//  ADHDAssistant
//
//  Service for managing achievements and tracking progress
//

import Foundation
import Combine

// MARK: - Achievement Progress

struct AchievementProgress {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    let currentCount: Int
    let requirement: Int
    let isRecentlyUnlocked: Bool

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var progressDescription: String {
        if isUnlocked {
            return "Unlocked"
        } else {
            return "\(currentCount)/\(requirement)"
        }
    }
}

// MARK: - Achievement Event

enum AchievementEvent {
    case taskCompleted
    case taskCompletedOnTime
    case healthMetricLogged
    case goalCreated
    case goalCompleted
    case streakDay(Int)
    case pointsMilestone(Int)
    case aiTaskCompleted
    case nightOwlTask
    case earlyBirdTask
    case speedTask
    case perfectWeek

    var trackingCategory: String {
        switch self {
        case .taskCompleted, .taskCompletedOnTime, .aiTaskCompleted, .nightOwlTask, .earlyBirdTask, .speedTask:
            return "tasks"
        case .healthMetricLogged:
            return "health"
        case .goalCreated, .goalCompleted:
            return "goals"
        case .streakDay:
            return "streak"
        case .pointsMilestone:
            return "points"
        case .perfectWeek:
            return "special"
        }
    }
}

// MARK: - Achievement Service

class AchievementService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var achievements: [Achievement]
    @Published private(set) var unlockedAchievements: [Achievement] = []
    @Published private(set) var recentlyUnlocked: [Achievement] = []

    // MARK: - Properties

    private let userDefaultsKeys: UserDefaultsKeys
    private var eventCounters: [String: Int] = [:]
    private let recentUnlockWindow: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    init(userDefaultsKeys: UserDefaultsKeys = .shared) {
        self.userDefaultsKeys = userDefaultsKeys

        // Load all achievements
        self.achievements = Achievement.allAchievements

        // Load unlocked achievement IDs
        let unlockedIds = Set(userDefaultsKeys.unlockedAchievementIds)

        // Mark achievements as unlocked
        for index in achievements.indices {
            if unlockedIds.contains(achievements[index].id) {
                achievements[index].unlock()
            }
        }

        // Update unlocked achievements list
        updateUnlockedList()

        // Initialize event counters from UserDefaults
        loadEventCounters()
    }

    // MARK: - Track Progress

    /// Track an event and check for achievement unlocks
    func trackEvent(_ event: AchievementEvent) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        switch event {
        case .taskCompleted:
            newlyUnlocked.append(contentsOf: incrementCounter("tasks_completed", in: "tasks"))

        case .taskCompletedOnTime:
            newlyUnlocked.append(contentsOf: incrementCounter("tasks_on_time", in: "time"))

        case .healthMetricLogged:
            newlyUnlocked.append(contentsOf: incrementCounter("health_logged", in: "health"))

        case .goalCreated:
            newlyUnlocked.append(contentsOf: incrementCounter("goals_created", in: "goals"))

        case .goalCompleted:
            newlyUnlocked.append(contentsOf: incrementCounter("goals_completed", in: "goals"))

        case .streakDay(let days):
            newlyUnlocked.append(contentsOf: updateCounter("streak_days", value: days, in: "streak"))

        case .pointsMilestone(let points):
            newlyUnlocked.append(contentsOf: updateCounter("total_points", value: points, in: "points"))

        case .aiTaskCompleted:
            newlyUnlocked.append(contentsOf: incrementCounter("ai_tasks_completed", in: "ai"))

        case .nightOwlTask:
            newlyUnlocked.append(contentsOf: incrementCounter("night_owl", in: "special"))

        case .earlyBirdTask:
            newlyUnlocked.append(contentsOf: incrementCounter("early_bird", in: "special"))

        case .speedTask:
            newlyUnlocked.append(contentsOf: incrementCounter("speed_demon", in: "special"))

        case .perfectWeek:
            newlyUnlocked.append(contentsOf: incrementCounter("perfect_week", in: "special"))
        }

        // Save counters
        saveEventCounters()

        return newlyUnlocked
    }

    /// Track multiple events at once
    func trackEvents(_ events: [AchievementEvent]) -> [Achievement] {
        var allUnlocked: [Achievement] = []

        for event in events {
            let unlocked = trackEvent(event)
            allUnlocked.append(contentsOf: unlocked)
        }

        return allUnlocked
    }

    // MARK: - Counter Management

    private func incrementCounter(_ key: String, in category: String) -> [Achievement] {
        let currentValue = eventCounters[key, default: 0]
        let newValue = currentValue + 1
        eventCounters[key] = newValue

        return checkAchievements(for: category, value: newValue)
    }

    private func updateCounter(_ key: String, value: Int, in category: String) -> [Achievement] {
        eventCounters[key] = value
        return checkAchievements(for: category, value: value)
    }

    private func checkAchievements(for category: String, value: Int) -> [Achievement] {
        var unlocked: [Achievement] = []

        for index in achievements.indices {
            guard achievements[index].category == category,
                  !achievements[index].isUnlocked else {
                continue
            }

            if achievements[index].updateProgress(newCount: value) {
                // Achievement unlocked!
                unlocked.append(achievements[index])
                markAsRecentlyUnlocked(achievements[index])
            }
        }

        if !unlocked.isEmpty {
            saveUnlockedAchievements()
            updateUnlockedList()
        }

        return unlocked
    }

    // MARK: - Achievement Queries

    /// Get all achievements for a specific category
    func achievements(forCategory category: String) -> [AchievementProgress] {
        achievements
            .filter { $0.category == category }
            .map { makeProgress(for: $0) }
    }

    /// Get all unlocked achievements
    func getUnlockedAchievements() -> [AchievementProgress] {
        unlockedAchievements.map { makeProgress(for: $0) }
    }

    /// Get achievements in progress (not unlocked, not secret)
    func getInProgressAchievements() -> [AchievementProgress] {
        achievements
            .filter { !$0.isUnlocked && !$0.isSecret && $0.progress > 0 }
            .sorted { $0.progress > $1.progress }
            .map { makeProgress(for: $0) }
    }

    /// Get recently unlocked achievements
    func getRecentlyUnlocked() -> [AchievementProgress] {
        recentlyUnlocked.map { makeProgress(for: $0) }
    }

    /// Get specific achievement progress
    func getProgress(for achievementId: UUID) -> AchievementProgress? {
        guard let achievement = achievements.first(where: { $0.id == achievementId }) else {
            return nil
        }
        return makeProgress(for: achievement)
    }

    /// Get achievements by tier
    func achievements(forTier tier: AchievementTier) -> [AchievementProgress] {
        achievements
            .filter { $0.tier == tier }
            .map { makeProgress(for: $0) }
    }

    // MARK: - Helper Methods

    private func makeProgress(for achievement: Achievement) -> AchievementProgress {
        let isRecent = recentlyUnlocked.contains { $0.id == achievement.id }

        return AchievementProgress(
            achievement: achievement,
            isUnlocked: achievement.isUnlocked,
            progress: achievement.progress,
            currentCount: achievement.currentCount,
            requirement: achievement.requirement,
            isRecentlyUnlocked: isRecent
        )
    }

    private func markAsRecentlyUnlocked(_ achievement: Achievement) {
        recentlyUnlocked.append(achievement)

        // Auto-remove after window expires
        DispatchQueue.main.asyncAfter(deadline: .now() + recentUnlockWindow) { [weak self] in
            self?.recentlyUnlocked.removeAll { $0.id == achievement.id }
        }
    }

    private func updateUnlockedList() {
        unlockedAchievements = achievements.filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? Date.distantPast) > ($1.unlockedAt ?? Date.distantPast) }
    }

    // MARK: - Persistence

    private func saveUnlockedAchievements() {
        let unlockedIds = achievements.filter { $0.isUnlocked }.map { $0.id }
        userDefaultsKeys.unlockedAchievementIds = unlockedIds
    }

    private func loadEventCounters() {
        // Load from UserDefaults or initialize defaults
        eventCounters["tasks_completed"] = userDefaultsKeys.totalTasksCompleted
        eventCounters["goals_created"] = userDefaultsKeys.totalGoalsCreated
        eventCounters["goals_completed"] = userDefaultsKeys.totalGoalsCompleted
        eventCounters["total_points"] = userDefaultsKeys.totalPoints
        eventCounters["streak_days"] = userDefaultsKeys.currentStreak
        eventCounters["ai_tasks_completed"] = userDefaultsKeys.totalAITasksCompleted
        eventCounters["health_logged"] = userDefaultsKeys.totalHealthMetricsLogged
    }

    private func saveEventCounters() {
        // Save to UserDefaults (main counters are already saved by other services)
        // This is primarily for syncing
    }

    // MARK: - Testing & Debug

    /// Unlock a specific achievement (for testing)
    func unlockAchievement(_ achievementId: UUID) -> Bool {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }),
              !achievements[index].isUnlocked else {
            return false
        }

        achievements[index].unlock()
        markAsRecentlyUnlocked(achievements[index])
        saveUnlockedAchievements()
        updateUnlockedList()

        return true
    }

    /// Reset all achievements (for testing)
    func resetAllAchievements() {
        for index in achievements.indices {
            achievements[index].reset()
        }

        recentlyUnlocked.removeAll()
        updateUnlockedList()
        saveUnlockedAchievements()
        eventCounters.removeAll()
    }

    // MARK: - Statistics

    /// Get achievement statistics
    func getStatistics() -> AchievementStatistics {
        let total = achievements.count
        let unlocked = unlockedAchievements.count
        let progress = Double(unlocked) / Double(total)

        let byTier = Dictionary(grouping: unlockedAchievements) { $0.tier }
        let bronze = byTier[.bronze]?.count ?? 0
        let silver = byTier[.silver]?.count ?? 0
        let gold = byTier[.gold]?.count ?? 0

        return AchievementStatistics(
            totalAchievements: total,
            unlockedCount: unlocked,
            completionRate: progress,
            bronzeCount: bronze,
            silverCount: silver,
            goldCount: gold
        )
    }
}

// MARK: - Achievement Statistics

struct AchievementStatistics {
    let totalAchievements: Int
    let unlockedCount: Int
    let completionRate: Double
    let bronzeCount: Int
    let silverCount: Int
    let goldCount: Int

    var completionPercentage: Int {
        Int(completionRate * 100)
    }

    var remainingCount: Int {
        totalAchievements - unlockedCount
    }
}

// MARK: - Mock Service for Testing

class MockAchievementService: ObservableObject {
    @Published var achievements: [Achievement] = Achievement.allAchievements
    @Published var unlockedAchievements: [Achievement] = []
    @Published var recentlyUnlocked: [Achievement] = []

    func trackEvent(_ event: AchievementEvent) -> [Achievement] {
        []
    }

    func trackEvents(_ events: [AchievementEvent]) -> [Achievement] {
        []
    }

    func achievements(forCategory category: String) -> [AchievementProgress] {
        achievements
            .filter { $0.category == category }
            .map { AchievementProgress(
                achievement: $0,
                isUnlocked: $0.isUnlocked,
                progress: $0.progress,
                currentCount: $0.currentCount,
                requirement: $0.requirement,
                isRecentlyUnlocked: false
            )}
    }

    func getUnlockedAchievements() -> [AchievementProgress] {
        unlockedAchievements.map { AchievementProgress(
            achievement: $0,
            isUnlocked: true,
            progress: 1.0,
            currentCount: $0.requirement,
            requirement: $0.requirement,
            isRecentlyUnlocked: false
        )}
    }

    func unlockAchievement(_ achievementId: UUID) -> Bool {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else {
            return false
        }
        achievements[index].unlock()
        unlockedAchievements.append(achievements[index])
        return true
    }
}
