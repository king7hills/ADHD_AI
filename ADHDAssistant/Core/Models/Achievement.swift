//
//  Achievement.swift
//  ADHDAssistant
//
//  Achievement and gamification model
//

import Foundation
import SwiftUI

/// Achievement tiers for progression
enum AchievementTier: String, Codable, CaseIterable {
    case bronze
    case silver
    case gold

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }

    var pointsRequired: Int {
        switch self {
        case .bronze: return 50
        case .silver: return 100
        case .gold: return 250
        }
    }

    var sortOrder: Int {
        switch self {
        case .bronze: return 2
        case .silver: return 1
        case .gold: return 0
        }
    }
}

/// Celebration animation styles
enum CelebrationStyle: String, Codable, CaseIterable {
    case confetti
    case checkmarkBurst
    case starShimmer
    case fireworks
    case rainbowWave
    case partyPopper
    case epicConfetti
    case victoryDance
    case goldenShower

    var displayName: String {
        switch self {
        case .confetti: return "Confetti"
        case .checkmarkBurst: return "Checkmark Burst"
        case .starShimmer: return "Star Shimmer"
        case .fireworks: return "Fireworks"
        case .rainbowWave: return "Rainbow Wave"
        case .partyPopper: return "Party Popper"
        case .epicConfetti: return "Epic Confetti"
        case .victoryDance: return "Victory Dance"
        case .goldenShower: return "Golden Shower"
        }
    }

    var intensity: Int {
        switch self {
        case .confetti, .checkmarkBurst: return 1
        case .starShimmer, .partyPopper: return 2
        case .fireworks, .rainbowWave: return 3
        case .epicConfetti, .victoryDance, .goldenShower: return 4
        }
    }
}

/// Achievement model for gamification
struct Achievement: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var iconName: String
    var tier: AchievementTier
    var unlockedAt: Date?
    var progress: Double // 0.0 to 1.0
    var currentCount: Int
    var requirement: Int
    var rewardCelebration: CelebrationStyle
    var category: String // e.g., "tasks", "streak", "health", "points"
    var isSecret: Bool // Hidden until unlocked

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        iconName: String,
        tier: AchievementTier,
        unlockedAt: Date? = nil,
        progress: Double = 0.0,
        currentCount: Int = 0,
        requirement: Int,
        rewardCelebration: CelebrationStyle = .confetti,
        category: String,
        isSecret: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.tier = tier
        self.unlockedAt = unlockedAt
        self.progress = progress
        self.currentCount = currentCount
        self.requirement = requirement
        self.rewardCelebration = rewardCelebration
        self.category = category
        self.isSecret = isSecret
    }

    // MARK: - Computed Properties

    /// Whether the achievement is unlocked
    var isUnlocked: Bool {
        unlockedAt != nil
    }

    /// Whether the achievement is ready to unlock
    var canUnlock: Bool {
        currentCount >= requirement && !isUnlocked
    }

    /// Points awarded for this achievement
    var pointsAwarded: Int {
        tier.pointsRequired
    }

    /// Formatted progress string
    var progressString: String {
        "\(currentCount)/\(requirement)"
    }

    // MARK: - Methods

    /// Update progress and check if unlocked
    mutating func updateProgress(newCount: Int) -> Bool {
        currentCount = newCount
        progress = min(Double(currentCount) / Double(requirement), 1.0)

        if canUnlock {
            unlock()
            return true
        }
        return false
    }

    /// Unlock the achievement
    mutating func unlock() {
        guard !isUnlocked else { return }
        unlockedAt = Date()
        progress = 1.0
        currentCount = requirement
    }

    /// Reset achievement (for testing or reset functionality)
    mutating func reset() {
        unlockedAt = nil
        progress = 0.0
        currentCount = 0
    }
}

// MARK: - Predefined Achievements

extension Achievement {
    /// All available achievements in the app
    static let allAchievements: [Achievement] = [
        // Task Completion Achievements
        Achievement(
            title: "First Steps",
            description: "Complete your first task",
            iconName: "checkmark.circle.fill",
            tier: .bronze,
            requirement: 1,
            rewardCelebration: .checkmarkBurst,
            category: "tasks"
        ),
        Achievement(
            title: "Task Master",
            description: "Complete 10 tasks",
            iconName: "list.bullet.circle.fill",
            tier: .bronze,
            requirement: 10,
            rewardCelebration: .confetti,
            category: "tasks"
        ),
        Achievement(
            title: "Productivity Champion",
            description: "Complete 50 tasks",
            iconName: "trophy.fill",
            tier: .silver,
            requirement: 50,
            rewardCelebration: .fireworks,
            category: "tasks"
        ),
        Achievement(
            title: "Task Legend",
            description: "Complete 100 tasks",
            iconName: "star.circle.fill",
            tier: .gold,
            requirement: 100,
            rewardCelebration: .epicConfetti,
            category: "tasks"
        ),

        // Streak Achievements
        Achievement(
            title: "On a Roll",
            description: "Maintain a 3-day streak",
            iconName: "flame.fill",
            tier: .bronze,
            requirement: 3,
            rewardCelebration: .starShimmer,
            category: "streak"
        ),
        Achievement(
            title: "Week Warrior",
            description: "Maintain a 7-day streak",
            iconName: "bolt.fill",
            tier: .silver,
            requirement: 7,
            rewardCelebration: .rainbowWave,
            category: "streak"
        ),
        Achievement(
            title: "Unstoppable",
            description: "Maintain a 30-day streak",
            iconName: "sparkles",
            tier: .gold,
            requirement: 30,
            rewardCelebration: .victoryDance,
            category: "streak"
        ),

        // Health Achievements
        Achievement(
            title: "Health Conscious",
            description: "Log 7 consecutive days of health metrics",
            iconName: "heart.fill",
            tier: .bronze,
            requirement: 7,
            rewardCelebration: .checkmarkBurst,
            category: "health"
        ),
        Achievement(
            title: "Wellness Guardian",
            description: "Log 30 days of health metrics",
            iconName: "heart.text.square.fill",
            tier: .silver,
            requirement: 30,
            rewardCelebration: .fireworks,
            category: "health"
        ),

        // Points Achievements
        Achievement(
            title: "Point Collector",
            description: "Earn 500 total points",
            iconName: "dollarsign.circle.fill",
            tier: .bronze,
            requirement: 500,
            rewardCelebration: .confetti,
            category: "points"
        ),
        Achievement(
            title: "Point Hoarder",
            description: "Earn 2,000 total points",
            iconName: "star.square.fill",
            tier: .silver,
            requirement: 2000,
            rewardCelebration: .partyPopper,
            category: "points"
        ),
        Achievement(
            title: "Point Legend",
            description: "Earn 5,000 total points",
            iconName: "crown.fill",
            tier: .gold,
            requirement: 5000,
            rewardCelebration: .goldenShower,
            category: "points"
        ),

        // Goal Achievements
        Achievement(
            title: "Goal Setter",
            description: "Create your first goal",
            iconName: "target",
            tier: .bronze,
            requirement: 1,
            rewardCelebration: .checkmarkBurst,
            category: "goals"
        ),
        Achievement(
            title: "Goal Achiever",
            description: "Complete 5 goals",
            iconName: "flag.fill",
            tier: .silver,
            requirement: 5,
            rewardCelebration: .fireworks,
            category: "goals"
        ),
        Achievement(
            title: "Dream Chaser",
            description: "Complete 20 goals",
            iconName: "medal.fill",
            tier: .gold,
            requirement: 20,
            rewardCelebration: .epicConfetti,
            category: "goals"
        ),

        // Time Management
        Achievement(
            title: "Punctual Pro",
            description: "Complete 10 tasks on time",
            iconName: "clock.fill",
            tier: .bronze,
            requirement: 10,
            rewardCelebration: .starShimmer,
            category: "time"
        ),

        // Special/Secret Achievements
        Achievement(
            title: "Night Owl",
            description: "Complete a task after 10 PM",
            iconName: "moon.stars.fill",
            tier: .bronze,
            requirement: 1,
            rewardCelebration: .starShimmer,
            category: "special",
            isSecret: true
        ),
        Achievement(
            title: "Early Bird",
            description: "Complete a task before 6 AM",
            iconName: "sunrise.fill",
            tier: .bronze,
            requirement: 1,
            rewardCelebration: .rainbowWave,
            category: "special",
            isSecret: true
        ),
        Achievement(
            title: "Speed Demon",
            description: "Complete a task in under 5 minutes",
            iconName: "hare.fill",
            tier: .silver,
            requirement: 1,
            rewardCelebration: .fireworks,
            category: "special",
            isSecret: true
        ),
        Achievement(
            title: "Perfect Week",
            description: "Complete all scheduled tasks for 7 days",
            iconName: "calendar.badge.checkmark",
            tier: .gold,
            requirement: 1,
            rewardCelebration: .victoryDance,
            category: "special",
            isSecret: true
        ),

        // AI Interaction
        Achievement(
            title: "AI Assistant",
            description: "Complete 10 AI-suggested tasks",
            iconName: "brain.head.profile",
            tier: .silver,
            requirement: 10,
            rewardCelebration: .partyPopper,
            category: "ai"
        )
    ]

    /// Get achievements by category
    static func achievements(forCategory category: String) -> [Achievement] {
        allAchievements.filter { $0.category == category }
    }

    /// Get achievements by tier
    static func achievements(forTier tier: AchievementTier) -> [Achievement] {
        allAchievements.filter { $0.tier == tier }
    }

    /// Get unlockable achievements (not secret or already unlocked)
    static var unlockableAchievements: [Achievement] {
        allAchievements.filter { !$0.isSecret }
    }
}

// MARK: - Sample Data

#if DEBUG
extension Achievement {
    static let sampleUnlocked = Achievement(
        title: "First Steps",
        description: "Complete your first task",
        iconName: "checkmark.circle.fill",
        tier: .bronze,
        unlockedAt: Date().addingTimeInterval(-86400),
        progress: 1.0,
        currentCount: 1,
        requirement: 1,
        rewardCelebration: .checkmarkBurst,
        category: "tasks"
    )

    static let sampleInProgress = Achievement(
        title: "Task Master",
        description: "Complete 10 tasks",
        iconName: "list.bullet.circle.fill",
        tier: .bronze,
        progress: 0.7,
        currentCount: 7,
        requirement: 10,
        rewardCelebration: .confetti,
        category: "tasks"
    )

    static let sampleLocked = Achievement(
        title: "Task Legend",
        description: "Complete 100 tasks",
        iconName: "star.circle.fill",
        tier: .gold,
        progress: 0.12,
        currentCount: 12,
        requirement: 100,
        rewardCelebration: .epicConfetti,
        category: "tasks"
    )
}
#endif
