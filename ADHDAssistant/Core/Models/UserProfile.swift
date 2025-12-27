//
//  UserProfile.swift
//  ADHDAssistant
//
//  User profile and preferences model
//

import Foundation

/// Health conditions that may affect task planning
enum HealthCondition: Codable, Hashable {
    case type2Diabetes
    case type1Diabetes
    case hypertension
    case other(String)

    var displayName: String {
        switch self {
        case .type2Diabetes: return "Type 2 Diabetes"
        case .type1Diabetes: return "Type 1 Diabetes"
        case .hypertension: return "Hypertension"
        case .other(let condition): return condition
        }
    }

    var requiresHealthMonitoring: Bool {
        switch self {
        case .type2Diabetes, .type1Diabetes, .hypertension:
            return true
        case .other:
            return false
        }
    }

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .type2Diabetes:
            try container.encode("type2Diabetes", forKey: .type)
        case .type1Diabetes:
            try container.encode("type1Diabetes", forKey: .type)
        case .hypertension:
            try container.encode("hypertension", forKey: .type)
        case .other(let value):
            try container.encode("other", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "type2Diabetes":
            self = .type2Diabetes
        case "type1Diabetes":
            self = .type1Diabetes
        case "hypertension":
            self = .hypertension
        case "other":
            let value = try container.decode(String.self, forKey: .value)
            self = .other(value)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown health condition type"
            )
        }
    }
}

/// Time of day preferences for energy and focus
enum TimeOfDay: String, Codable, CaseIterable {
    case earlyMorning = "early_morning"  // 5 AM - 8 AM
    case morning                         // 8 AM - 12 PM
    case midday                          // 12 PM - 2 PM
    case afternoon                       // 2 PM - 5 PM
    case evening                         // 5 PM - 8 PM
    case night                           // 8 PM - 11 PM

    var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning (5-8 AM)"
        case .morning: return "Morning (8 AM-12 PM)"
        case .midday: return "Midday (12-2 PM)"
        case .afternoon: return "Afternoon (2-5 PM)"
        case .evening: return "Evening (5-8 PM)"
        case .night: return "Night (8-11 PM)"
        }
    }

    var timeRange: ClosedRange<Int> {
        switch self {
        case .earlyMorning: return 5...8
        case .morning: return 8...12
        case .midday: return 12...14
        case .afternoon: return 14...17
        case .evening: return 17...20
        case .night: return 20...23
        }
    }

    /// Get current time of day
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        return TimeOfDay.allCases.first { $0.timeRange.contains(hour) } ?? .morning
    }
}

/// Style of AI intervention for task management
enum InterventionStyle: String, Codable, CaseIterable {
    case gentle
    case moderate
    case assertive

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .gentle:
            return "Soft reminders and encouragement"
        case .moderate:
            return "Balanced guidance with clear prompts"
        case .assertive:
            return "Direct and firm accountability"
        }
    }

    var reminderFrequency: TimeInterval {
        switch self {
        case .gentle: return 1800 // 30 minutes
        case .moderate: return 900 // 15 minutes
        case .assertive: return 300 // 5 minutes
        }
    }
}

/// Notification and intervention preferences
struct NotificationPreferences: Codable, Hashable {
    var enabled: Bool
    var criticalAlertsEnabled: Bool
    var quietHoursStart: Date? // Time component only
    var quietHoursEnd: Date? // Time component only
    var preferredInterventionStyle: InterventionStyle
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var showPreviews: Bool

    init(
        enabled: Bool = true,
        criticalAlertsEnabled: Bool = false,
        quietHoursStart: Date? = nil,
        quietHoursEnd: Date? = nil,
        preferredInterventionStyle: InterventionStyle = .moderate,
        soundEnabled: Bool = true,
        hapticEnabled: Bool = true,
        showPreviews: Bool = true
    ) {
        self.enabled = enabled
        self.criticalAlertsEnabled = criticalAlertsEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.preferredInterventionStyle = preferredInterventionStyle
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
        self.showPreviews = showPreviews
    }

    /// Check if current time is within quiet hours
    var isInQuietHours: Bool {
        guard let quietStart = quietHoursStart,
              let quietEnd = quietHoursEnd else {
            return false
        }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        let quietStartHour = calendar.component(.hour, from: quietStart)
        let quietStartMinute = calendar.component(.minute, from: quietStart)
        let quietEndHour = calendar.component(.hour, from: quietEnd)
        let quietEndMinute = calendar.component(.minute, from: quietEnd)

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = quietStartHour * 60 + quietStartMinute
        let endMinutes = quietEndHour * 60 + quietEndMinute

        if startMinutes <= endMinutes {
            // Normal case: quiet hours don't cross midnight
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Quiet hours cross midnight
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
}

/// User profile and preferences
struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String?
    var hasHealthConditions: [HealthCondition]
    var preferredTaskDuration: TimeInterval // Preferred task length in seconds
    var peakEnergyTimes: [TimeOfDay]
    var notificationPreferences: NotificationPreferences
    var createdAt: Date
    var lastUpdatedAt: Date
    var timezone: String // TimeZone identifier
    var totalPoints: Int
    var currentStreak: Int
    var longestStreak: Int
    var level: Int

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        hasHealthConditions: [HealthCondition] = [],
        preferredTaskDuration: TimeInterval = 1800, // Default 30 minutes
        peakEnergyTimes: [TimeOfDay] = [.morning],
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        createdAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        timezone: String = TimeZone.current.identifier,
        totalPoints: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        level: Int = 1
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.hasHealthConditions = hasHealthConditions
        self.preferredTaskDuration = preferredTaskDuration
        self.peakEnergyTimes = peakEnergyTimes
        self.notificationPreferences = notificationPreferences
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.timezone = timezone
        self.totalPoints = totalPoints
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.level = level
    }

    // MARK: - Computed Properties

    /// Whether user has any health conditions requiring monitoring
    var requiresHealthMonitoring: Bool {
        hasHealthConditions.contains { $0.requiresHealthMonitoring }
    }

    /// Whether current time is a peak energy time
    var isCurrentlyPeakEnergy: Bool {
        peakEnergyTimes.contains(TimeOfDay.current)
    }

    /// Preferred task duration formatted
    var preferredTaskDurationFormatted: String {
        let hours = Int(preferredTaskDuration) / 3600
        let minutes = Int(preferredTaskDuration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Points needed for next level
    var pointsForNextLevel: Int {
        level * 100
    }

    /// Progress to next level (0.0 to 1.0)
    var levelProgress: Double {
        let pointsInCurrentLevel = totalPoints % pointsForNextLevel
        return Double(pointsInCurrentLevel) / Double(pointsForNextLevel)
    }

    // MARK: - Methods

    /// Add points and check for level up
    mutating func addPoints(_ points: Int) -> Bool {
        totalPoints += points
        let leveledUp = checkAndUpdateLevel()
        lastUpdatedAt = Date()
        return leveledUp
    }

    /// Check if user leveled up and update
    private mutating func checkAndUpdateLevel() -> Bool {
        let newLevel = (totalPoints / 100) + 1
        if newLevel > level {
            level = newLevel
            return true
        }
        return false
    }

    /// Increment streak
    mutating func incrementStreak() {
        currentStreak += 1
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        lastUpdatedAt = Date()
    }

    /// Break streak
    mutating func breakStreak() {
        currentStreak = 0
        lastUpdatedAt = Date()
    }

    /// Update notification preferences
    mutating func updateNotificationPreferences(_ preferences: NotificationPreferences) {
        notificationPreferences = preferences
        lastUpdatedAt = Date()
    }

    /// Add health condition
    mutating func addHealthCondition(_ condition: HealthCondition) {
        if !hasHealthConditions.contains(condition) {
            hasHealthConditions.append(condition)
            lastUpdatedAt = Date()
        }
    }

    /// Remove health condition
    mutating func removeHealthCondition(_ condition: HealthCondition) {
        hasHealthConditions.removeAll { $0 == condition }
        lastUpdatedAt = Date()
    }

    /// Add peak energy time
    mutating func addPeakEnergyTime(_ time: TimeOfDay) {
        if !peakEnergyTimes.contains(time) {
            peakEnergyTimes.append(time)
            lastUpdatedAt = Date()
        }
    }

    /// Remove peak energy time
    mutating func removePeakEnergyTime(_ time: TimeOfDay) {
        peakEnergyTimes.removeAll { $0 == time }
        lastUpdatedAt = Date()
    }
}

// MARK: - Sample Data

#if DEBUG
extension UserProfile {
    static let sample = UserProfile(
        name: "Alex Johnson",
        email: "alex@example.com",
        hasHealthConditions: [.type2Diabetes],
        preferredTaskDuration: 1200, // 20 minutes
        peakEnergyTimes: [.morning, .afternoon],
        notificationPreferences: NotificationPreferences(
            enabled: true,
            criticalAlertsEnabled: true,
            preferredInterventionStyle: .moderate
        ),
        totalPoints: 450,
        currentStreak: 7,
        longestStreak: 14,
        level: 5
    )

    static let sampleWithQuietHours = UserProfile(
        name: "Jordan Smith",
        email: "jordan@example.com",
        hasHealthConditions: [.hypertension],
        preferredTaskDuration: 1800, // 30 minutes
        peakEnergyTimes: [.earlyMorning, .evening],
        notificationPreferences: NotificationPreferences(
            enabled: true,
            criticalAlertsEnabled: false,
            quietHoursStart: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)),
            quietHoursEnd: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)),
            preferredInterventionStyle: .gentle
        ),
        totalPoints: 1250,
        currentStreak: 21,
        longestStreak: 30,
        level: 13
    )
}
#endif
