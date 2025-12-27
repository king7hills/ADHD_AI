//
//  StreakService.swift
//  ADHDAssistant
//
//  Service for managing daily streaks and streak-related features
//

import Foundation
import Combine

// MARK: - Streak Status

struct StreakStatus {
    let currentStreak: Int
    let longestStreak: Int
    let lastStreakDate: Date?
    let freePassesRemaining: Int
    let streakFreezeActive: Bool
    let isStreakAtRisk: Bool
    let daysUntilFreePassReset: Int

    var streakDescription: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if currentStreak == 1 {
            return "1 day streak"
        } else {
            return "\(currentStreak) day streak"
        }
    }

    var canUseFreePass: Bool {
        freePassesRemaining > 0 && isStreakAtRisk
    }

    var streakLevel: StreakLevel {
        switch currentStreak {
        case 0: return .none
        case 1...2: return .starting
        case 3...6: return .building
        case 7...13: return .solid
        case 14...29: return .strong
        case 30...89: return .impressive
        default: return .legendary
        }
    }
}

enum StreakLevel {
    case none
    case starting
    case building
    case solid
    case strong
    case impressive
    case legendary

    var displayName: String {
        switch self {
        case .none: return "No Streak"
        case .starting: return "Starting"
        case .building: return "Building"
        case .solid: return "Solid"
        case .strong: return "Strong"
        case .impressive: return "Impressive"
        case .legendary: return "Legendary"
        }
    }

    var emoji: String {
        switch self {
        case .none: return "💤"
        case .starting: return "🔥"
        case .building: return "🔥🔥"
        case .solid: return "🔥🔥🔥"
        case .strong: return "✨🔥✨"
        case .impressive: return "🌟🔥🌟"
        case .legendary: return "👑🔥👑"
        }
    }
}

// MARK: - Streak Service

class StreakService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var currentStreak: Int
    @Published private(set) var longestStreak: Int
    @Published private(set) var freePassesRemaining: Int
    @Published private(set) var streakFreezeActive: Bool = false
    @Published private(set) var lastStreakDate: Date?

    // MARK: - Properties

    private let userDefaultsKeys: UserDefaultsKeys
    private let streakFreezeCost = 50 // points
    private let recoveryBonusDays = 1 // grace period for recovery

    // MARK: - Initialization

    init(userDefaultsKeys: UserDefaultsKeys = .shared) {
        self.userDefaultsKeys = userDefaultsKeys

        // Load saved streak data
        self.currentStreak = userDefaultsKeys.currentStreak
        self.longestStreak = userDefaultsKeys.longestStreak
        self.lastStreakDate = userDefaultsKeys.lastStreakDate
        self.freePassesRemaining = userDefaultsKeys.freePassesRemaining

        // Check and reset weekly free passes
        userDefaultsKeys.checkAndResetDailyData()
        self.freePassesRemaining = userDefaultsKeys.freePassesRemaining

        // Check if streak is at risk
        checkStreakStatus()
    }

    // MARK: - Streak Status

    func getStatus() -> StreakStatus {
        let isAtRisk = isStreakAtRisk()
        let daysUntilReset = daysUntilFreePassReset()

        return StreakStatus(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastStreakDate: lastStreakDate,
            freePassesRemaining: freePassesRemaining,
            streakFreezeActive: streakFreezeActive,
            isStreakAtRisk: isAtRisk,
            daysUntilFreePassReset: daysUntilReset
        )
    }

    /// Check if the current streak is at risk of breaking
    func isStreakAtRisk() -> Bool {
        guard let lastDate = lastStreakDate else {
            return currentStreak > 0
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastStreakDay = calendar.startOfDay(for: lastDate)

        let daysDifference = calendar.dateComponents([.day], from: lastStreakDay, to: today).day ?? 0

        // At risk if more than 1 day has passed without activity
        return daysDifference > 1 && !streakFreezeActive
    }

    /// Check if streak should be broken
    private func checkStreakStatus() {
        guard let lastDate = lastStreakDate else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastStreakDay = calendar.startOfDay(for: lastDate)

        let daysDifference = calendar.dateComponents([.day], from: lastStreakDay, to: today).day ?? 0

        // Break streak if more than 2 days without activity and no freeze
        if daysDifference > 2 && !streakFreezeActive {
            breakStreak()
        }
    }

    // MARK: - Daily Completion

    /// Record daily completion (call when user completes at least one task)
    func recordDailyCompletion() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if already recorded today
        if let lastDate = lastStreakDate {
            let lastStreakDay = calendar.startOfDay(for: lastDate)

            if lastStreakDay == today {
                // Already recorded today
                return false
            }

            let daysDifference = calendar.dateComponents([.day], from: lastStreakDay, to: today).day ?? 0

            if daysDifference == 1 {
                // Consecutive day - increment streak
                incrementStreak()
                return true
            } else if daysDifference == 2 && freePassesRemaining > 0 {
                // Missed one day but can use free pass
                useFreePass()
                incrementStreak()
                return true
            } else {
                // Streak broken, start new
                startNewStreak()
                return true
            }
        } else {
            // First time or starting new streak
            startNewStreak()
            return true
        }
    }

    private func incrementStreak() {
        currentStreak += 1

        if currentStreak > longestStreak {
            longestStreak = currentStreak
            userDefaultsKeys.longestStreak = longestStreak
        }

        lastStreakDate = Date()

        // Deactivate freeze if active
        if streakFreezeActive {
            streakFreezeActive = false
        }

        saveStreak()
    }

    private func startNewStreak() {
        currentStreak = 1
        lastStreakDate = Date()

        if streakFreezeActive {
            streakFreezeActive = false
        }

        saveStreak()
    }

    private func breakStreak() {
        currentStreak = 0
        lastStreakDate = nil

        if streakFreezeActive {
            streakFreezeActive = false
        }

        saveStreak()
    }

    // MARK: - Free Pass System

    /// Use a free pass to maintain streak
    func useFreePass() -> Bool {
        guard freePassesRemaining > 0 else { return false }

        freePassesRemaining -= 1
        userDefaultsKeys.freePassesRemaining = freePassesRemaining

        return true
    }

    /// Days until next free pass reset (weekly)
    func daysUntilFreePassReset() -> Int {
        guard let lastReset = userDefaultsKeys.lastFreePassResetDate else {
            return 7
        }

        let calendar = Calendar.current
        let daysSinceReset = calendar.dateComponents([.day], from: lastReset, to: Date()).day ?? 0
        let daysUntilReset = max(7 - daysSinceReset, 0)

        return daysUntilReset
    }

    // MARK: - Streak Freeze

    /// Purchase a streak freeze with points
    func purchaseStreakFreeze(pointsService: PointsService) -> Bool {
        guard !streakFreezeActive else {
            return false // Already have freeze active
        }

        guard pointsService.canAfford(cost: streakFreezeCost) else {
            return false // Not enough points
        }

        if pointsService.spendPoints(streakFreezeCost, reason: "Streak Freeze") {
            streakFreezeActive = true
            return true
        }

        return false
    }

    /// Get cost of streak freeze
    func getStreakFreezeCost() -> Int {
        streakFreezeCost
    }

    // MARK: - Recovery Bonus

    /// Check if user is eligible for recovery bonus
    func canRecoverStreak() -> Bool {
        guard currentStreak == 0 else { return false }
        guard let lastDate = lastStreakDate else { return false }

        let calendar = Calendar.current
        let daysSinceBreak = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

        // Allow recovery within grace period
        return daysSinceBreak <= recoveryBonusDays
    }

    /// Attempt to recover broken streak
    func recoverStreak(pointsService: PointsService) -> Bool {
        guard canRecoverStreak() else { return false }

        let recoveryCost = 100 // points
        guard pointsService.canAfford(cost: recoveryCost) else { return false }

        if pointsService.spendPoints(recoveryCost, reason: "Streak Recovery") {
            // Restore previous streak (estimate based on longest)
            currentStreak = min(longestStreak, 7)
            lastStreakDate = Date()
            saveStreak()
            return true
        }

        return false
    }

    // MARK: - Persistence

    private func saveStreak() {
        userDefaultsKeys.currentStreak = currentStreak
        userDefaultsKeys.longestStreak = longestStreak
        userDefaultsKeys.lastStreakDate = lastStreakDate
    }

    // MARK: - Utility Methods

    /// Get multiplier based on current streak
    func getStreakMultiplier() -> Double {
        switch currentStreak {
        case 0...2: return 1.0
        case 3...6: return 1.1
        case 7...13: return 1.25
        case 14...29: return 1.5
        case 30...89: return 1.75
        default: return 2.0
        }
    }

    /// Get streak level for display
    func getStreakLevel() -> StreakLevel {
        switch currentStreak {
        case 0: return .none
        case 1...2: return .starting
        case 3...6: return .building
        case 7...13: return .solid
        case 14...29: return .strong
        case 30...89: return .impressive
        default: return .legendary
        }
    }

    /// Get encouragement message based on streak
    func getEncouragementMessage() -> String {
        let level = getStreakLevel()

        switch level {
        case .none:
            return "Start your streak today! Complete at least one task."
        case .starting:
            return "Great start! Keep going to build your streak."
        case .building:
            return "You're building momentum! \(7 - currentStreak) more days to reach Solid level."
        case .solid:
            return "Solid streak! You're doing great! \(14 - currentStreak) more days to reach Strong level."
        case .strong:
            return "Strong streak! You're on fire! \(30 - currentStreak) more days to reach Impressive level."
        case .impressive:
            return "Impressive dedication! \(90 - currentStreak) more days to reach Legendary status."
        case .legendary:
            return "Legendary! You're unstoppable! Keep up the amazing work!"
        }
    }
}

// MARK: - Mock Service for Testing

class MockStreakService: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var freePassesRemaining: Int = 1
    @Published var streakFreezeActive: Bool = false
    @Published var lastStreakDate: Date?

    func getStatus() -> StreakStatus {
        StreakStatus(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastStreakDate: lastStreakDate,
            freePassesRemaining: freePassesRemaining,
            streakFreezeActive: streakFreezeActive,
            isStreakAtRisk: false,
            daysUntilFreePassReset: 7
        )
    }

    func recordDailyCompletion() -> Bool {
        currentStreak += 1
        lastStreakDate = Date()
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        return true
    }

    func useFreePass() -> Bool {
        guard freePassesRemaining > 0 else { return false }
        freePassesRemaining -= 1
        return true
    }

    func purchaseStreakFreeze(pointsService: PointsService) -> Bool {
        streakFreezeActive = true
        return true
    }

    func getStreakMultiplier() -> Double {
        switch currentStreak {
        case 0...2: return 1.0
        case 3...6: return 1.1
        case 7...13: return 1.25
        default: return 1.5
        }
    }

    func getStreakLevel() -> StreakLevel {
        switch currentStreak {
        case 0: return .none
        case 1...2: return .starting
        case 3...6: return .building
        case 7...13: return .solid
        default: return .strong
        }
    }
}
