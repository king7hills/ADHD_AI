//
//  UserDefaultsKeys.swift
//  ADHDAssistant
//
//  Type-safe UserDefaults access with property wrappers
//

import Foundation
import Combine

// MARK: - UserDefaults Property Wrapper

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    let userDefaults: UserDefaults

    init(
        _ key: String,
        defaultValue: Value,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: Value {
        get {
            userDefaults.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }

    var projectedValue: UserDefault<Value> {
        self
    }

    func reset() {
        userDefaults.removeObject(forKey: key)
    }
}

// MARK: - Codable UserDefaults Property Wrapper

@propertyWrapper
struct CodableUserDefault<Value: Codable> {
    let key: String
    let defaultValue: Value
    let userDefaults: UserDefaults

    init(
        _ key: String,
        defaultValue: Value,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    var wrappedValue: Value {
        get {
            guard let data = userDefaults.data(forKey: key) else {
                return defaultValue
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                return try decoder.decode(Value.self, from: data)
            } catch {
                print("Failed to decode \(key): \(error)")
                return defaultValue
            }
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601

            do {
                let data = try encoder.encode(newValue)
                userDefaults.set(data, forKey: key)
            } catch {
                print("Failed to encode \(key): \(error)")
            }
        }
    }

    var projectedValue: CodableUserDefault<Value> {
        self
    }

    func reset() {
        userDefaults.removeObject(forKey: key)
    }
}

// MARK: - Optional UserDefaults Property Wrapper

@propertyWrapper
struct OptionalUserDefault<Value> {
    let key: String
    let userDefaults: UserDefaults

    init(
        _ key: String,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = key
        self.userDefaults = userDefaults
    }

    var wrappedValue: Value? {
        get {
            userDefaults.object(forKey: key) as? Value
        }
        set {
            if let value = newValue {
                userDefaults.set(value, forKey: key)
            } else {
                userDefaults.removeObject(forKey: key)
            }
        }
    }

    var projectedValue: OptionalUserDefault<Value> {
        self
    }

    func reset() {
        userDefaults.removeObject(forKey: key)
    }
}

// MARK: - UserDefaults Keys Manager

/// Centralized UserDefaults keys and values
class UserDefaultsKeys {
    static let shared = UserDefaultsKeys()

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - User Preferences

    @UserDefault("userDefaults.hasCompletedOnboarding", defaultValue: false)
    var hasCompletedOnboarding: Bool

    @UserDefault("userDefaults.preferredInterventionStyle", defaultValue: "moderate")
    var preferredInterventionStyleRaw: String

    var preferredInterventionStyle: InterventionStyle {
        get {
            InterventionStyle(rawValue: preferredInterventionStyleRaw) ?? .moderate
        }
        set {
            preferredInterventionStyleRaw = newValue.rawValue
        }
    }

    @UserDefault("userDefaults.notificationsEnabled", defaultValue: true)
    var notificationsEnabled: Bool

    @UserDefault("userDefaults.hapticFeedbackEnabled", defaultValue: true)
    var hapticFeedbackEnabled: Bool

    @UserDefault("userDefaults.celebrationsEnabled", defaultValue: true)
    var celebrationsEnabled: Bool

    // MARK: - Gamification

    @UserDefault("userDefaults.totalPoints", defaultValue: 0)
    var totalPoints: Int

    @UserDefault("userDefaults.currentStreak", defaultValue: 0)
    var currentStreak: Int

    @UserDefault("userDefaults.longestStreak", defaultValue: 0)
    var longestStreak: Int

    @OptionalUserDefault("userDefaults.lastStreakDate")
    var lastStreakDate: Date?

    @UserDefault("userDefaults.freePassesRemaining", defaultValue: 1)
    var freePassesRemaining: Int

    @OptionalUserDefault("userDefaults.lastFreePassResetDate")
    var lastFreePassResetDate: Date?

    @UserDefault("userDefaults.streakFreezeCount", defaultValue: 0)
    var streakFreezeCount: Int

    @CodableUserDefault("userDefaults.unlockedAchievements", defaultValue: [])
    var unlockedAchievementIds: [UUID]

    @CodableUserDefault("userDefaults.unlockedCelebrations", defaultValue: [CelebrationStyle.confetti.rawValue])
    var unlockedCelebrationStyles: [String]

    var unlockedCelebrations: [CelebrationStyle] {
        get {
            unlockedCelebrationStyles.compactMap { CelebrationStyle(rawValue: $0) }
        }
        set {
            unlockedCelebrationStyles = newValue.map { $0.rawValue }
        }
    }

    @UserDefault("userDefaults.todaysPoints", defaultValue: 0)
    var todaysPoints: Int

    @OptionalUserDefault("userDefaults.lastPointsResetDate")
    var lastPointsResetDate: Date?

    // MARK: - Statistics

    @UserDefault("userDefaults.totalTasksCompleted", defaultValue: 0)
    var totalTasksCompleted: Int

    @UserDefault("userDefaults.totalTasksCreated", defaultValue: 0)
    var totalTasksCreated: Int

    @UserDefault("userDefaults.totalHealthMetricsLogged", defaultValue: 0)
    var totalHealthMetricsLogged: Int

    @UserDefault("userDefaults.totalGoalsCreated", defaultValue: 0)
    var totalGoalsCreated: Int

    @UserDefault("userDefaults.totalGoalsCompleted", defaultValue: 0)
    var totalGoalsCompleted: Int

    // MARK: - AI Context

    @OptionalUserDefault("userDefaults.lastAIInteraction")
    var lastAIInteraction: Date?

    @UserDefault("userDefaults.averageEstimationAccuracy", defaultValue: 1.0)
    var averageEstimationAccuracy: Double

    @UserDefault("userDefaults.totalAITasksCreated", defaultValue: 0)
    var totalAITasksCreated: Int

    @UserDefault("userDefaults.totalAITasksCompleted", defaultValue: 0)
    var totalAITasksCompleted: Int

    // MARK: - Health Tracking

    @OptionalUserDefault("userDefaults.lastBloodSugarReading")
    var lastBloodSugarReading: Double?

    @OptionalUserDefault("userDefaults.lastBloodSugarDate")
    var lastBloodSugarDate: Date?

    @UserDefault("userDefaults.healthTrackingEnabled", defaultValue: true)
    var healthTrackingEnabled: Bool

    @CodableUserDefault("userDefaults.medications", defaultValue: [])
    var medications: [String]

    // MARK: - App State

    @OptionalUserDefault("userDefaults.lastAppVersion")
    var lastAppVersion: String?

    @UserDefault("userDefaults.appLaunchCount", defaultValue: 0)
    var appLaunchCount: Int

    @OptionalUserDefault("userDefaults.firstLaunchDate")
    var firstLaunchDate: Date?

    @OptionalUserDefault("userDefaults.lastLaunchDate")
    var lastLaunchDate: Date?

    // MARK: - Feature Flags

    @UserDefault("userDefaults.aiAssistantEnabled", defaultValue: true)
    var aiAssistantEnabled: Bool

    @UserDefault("userDefaults.advancedGamificationEnabled", defaultValue: false)
    var advancedGamificationEnabled: Bool

    @UserDefault("userDefaults.healthIntegrationEnabled", defaultValue: true)
    var healthIntegrationEnabled: Bool

    // MARK: - Display Preferences

    @UserDefault("userDefaults.showCompletedTasks", defaultValue: false)
    var showCompletedTasks: Bool

    @UserDefault("userDefaults.groupTasksByDate", defaultValue: true)
    var groupTasksByDate: Bool

    @UserDefault("userDefaults.sortTasksByPriority", defaultValue: true)
    var sortTasksByPriority: Bool

    @UserDefault("userDefaults.showSubtaskProgress", defaultValue: true)
    var showSubtaskProgress: Bool

    // MARK: - Methods

    /// Reset all gamification data
    func resetGamification() {
        totalPoints = 0
        currentStreak = 0
        longestStreak = 0
        lastStreakDate = nil
        freePassesRemaining = 1
        lastFreePassResetDate = nil
        streakFreezeCount = 0
        unlockedAchievementIds = []
        unlockedCelebrationStyles = [CelebrationStyle.confetti.rawValue]
        todaysPoints = 0
        lastPointsResetDate = nil
    }

    /// Reset all statistics
    func resetStatistics() {
        totalTasksCompleted = 0
        totalTasksCreated = 0
        totalHealthMetricsLogged = 0
        totalGoalsCreated = 0
        totalGoalsCompleted = 0
        totalAITasksCreated = 0
        totalAITasksCompleted = 0
    }

    /// Reset all user data (except app state)
    func resetAllUserData() {
        resetGamification()
        resetStatistics()

        // AI Context
        lastAIInteraction = nil
        averageEstimationAccuracy = 1.0

        // Health
        lastBloodSugarReading = nil
        lastBloodSugarDate = nil
        medications = []

        // Preferences (keep default values)
        hasCompletedOnboarding = false
        preferredInterventionStyleRaw = "moderate"
        notificationsEnabled = true
        hapticFeedbackEnabled = true
        celebrationsEnabled = true
    }

    /// Check and reset daily data if needed
    func checkAndResetDailyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Reset daily points
        if let lastReset = lastPointsResetDate {
            let lastResetDay = calendar.startOfDay(for: lastReset)
            if today > lastResetDay {
                todaysPoints = 0
                lastPointsResetDate = today
            }
        } else {
            lastPointsResetDate = today
        }

        // Reset weekly free passes
        if let lastReset = lastFreePassResetDate {
            let weeksSinceReset = calendar.dateComponents([.weekOfYear], from: lastReset, to: Date()).weekOfYear ?? 0
            if weeksSinceReset >= 1 {
                freePassesRemaining = 1
                lastFreePassResetDate = Date()
            }
        } else {
            lastFreePassResetDate = Date()
        }
    }

    /// Increment app launch count
    func recordAppLaunch() {
        if firstLaunchDate == nil {
            firstLaunchDate = Date()
        }
        lastLaunchDate = Date()
        appLaunchCount += 1
    }
}

// MARK: - Convenience Extensions

extension UserDefaults {
    /// Clear all app-specific data
    func clearAllAppData() {
        let domain = Bundle.main.bundleIdentifier!
        removePersistentDomain(forName: domain)
        synchronize()
    }
}
