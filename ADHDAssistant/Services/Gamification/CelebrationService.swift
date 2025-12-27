//
//  CelebrationService.swift
//  ADHDAssistant
//
//  Service for managing celebration animations and haptic feedback
//

import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Celebration Configuration

struct CelebrationConfig {
    let style: CelebrationStyle
    let duration: TimeInterval
    let hapticEnabled: Bool
    let soundEnabled: Bool
    let message: String?

    init(
        style: CelebrationStyle,
        duration: TimeInterval = 2.0,
        hapticEnabled: Bool = true,
        soundEnabled: Bool = true,
        message: String? = nil
    ) {
        self.style = style
        self.duration = duration
        self.hapticEnabled = hapticEnabled
        self.soundEnabled = soundEnabled
        self.message = message
    }
}

// MARK: - Active Celebration

struct ActiveCelebration: Identifiable {
    let id: UUID
    let config: CelebrationConfig
    let startTime: Date

    init(
        id: UUID = UUID(),
        config: CelebrationConfig,
        startTime: Date = Date()
    ) {
        self.id = id
        self.config = config
        self.startTime = startTime
    }

    var isExpired: Bool {
        Date().timeIntervalSince(startTime) > config.duration
    }
}

// MARK: - Haptic Manager

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    #if canImport(UIKit)
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func playWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    func playCustomPattern(for celebration: CelebrationStyle) {
        switch celebration.intensity {
        case 1:
            playSuccess()
        case 2:
            playSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playImpact(style: .light)
            }
        case 3:
            playSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playImpact(style: .medium)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playImpact(style: .light)
            }
        case 4:
            playSuccess()
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    self.playImpact(style: .heavy)
                }
            }
        default:
            playSuccess()
        }
    }
    #else
    func playSuccess() {}
    func playWarning() {}
    func playError() {}
    func playImpact(style: Int = 0) {}
    func playSelection() {}
    func playCustomPattern(for celebration: CelebrationStyle) {}
    #endif
}

// MARK: - Celebration Service

class CelebrationService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var unlockedStyles: [CelebrationStyle]
    @Published private(set) var activeCelebration: ActiveCelebration?
    @Published var celebrationsEnabled: Bool

    // MARK: - Properties

    private let userDefaultsKeys: UserDefaultsKeys
    private let hapticManager: HapticManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        userDefaultsKeys: UserDefaultsKeys = .shared,
        hapticManager: HapticManager = .shared
    ) {
        self.userDefaultsKeys = userDefaultsKeys
        self.hapticManager = hapticManager
        self.celebrationsEnabled = userDefaultsKeys.celebrationsEnabled

        // Load unlocked celebration styles
        self.unlockedStyles = userDefaultsKeys.unlockedCelebrations

        // Ensure at least confetti is unlocked
        if unlockedStyles.isEmpty {
            unlockedStyles = [.confetti]
            saveUnlockedStyles()
        }
    }

    // MARK: - Play Celebrations

    /// Play a specific celebration style
    func playCelebration(
        style: CelebrationStyle,
        message: String? = nil,
        duration: TimeInterval? = nil
    ) {
        guard celebrationsEnabled else { return }

        let config = CelebrationConfig(
            style: style,
            duration: duration ?? getDefaultDuration(for: style),
            hapticEnabled: userDefaultsKeys.hapticFeedbackEnabled,
            soundEnabled: true,
            message: message
        )

        let celebration = ActiveCelebration(config: config)
        activeCelebration = celebration

        // Play haptics
        if config.hapticEnabled {
            hapticManager.playCustomPattern(for: style)
        }

        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) { [weak self] in
            if self?.activeCelebration?.id == celebration.id {
                self?.dismissCelebration()
            }
        }
    }

    /// Play a random celebration from unlocked pool
    func playRandomCelebration(message: String? = nil) {
        guard let style = unlockedStyles.randomElement() else {
            playCelebration(style: .confetti, message: message)
            return
        }

        playCelebration(style: style, message: message)
    }

    /// Play celebration for task completion
    func celebrateTaskCompletion(task: Task) {
        let style: CelebrationStyle

        switch task.priority {
        case .low:
            style = .checkmarkBurst
        case .medium:
            style = unlockedStyles.contains(.starShimmer) ? .starShimmer : .confetti
        case .high:
            style = unlockedStyles.contains(.fireworks) ? .fireworks : .confetti
        case .critical:
            style = unlockedStyles.contains(.epicConfetti) ? .epicConfetti : .fireworks
        }

        let message = "Great job! \(task.title) completed!"
        playCelebration(style: style, message: message)
    }

    /// Play celebration for achievement unlock
    func celebrateAchievement(_ achievement: Achievement) {
        playCelebration(
            style: achievement.rewardCelebration,
            message: "Achievement Unlocked: \(achievement.title)!",
            duration: 3.0
        )
    }

    /// Play celebration for goal completion
    func celebrateGoalCompletion(goal: Goal) {
        let style: CelebrationStyle = unlockedStyles.contains(.victoryDance) ? .victoryDance : .epicConfetti
        playCelebration(
            style: style,
            message: "Goal Achieved: \(goal.title)!",
            duration: 3.0
        )
    }

    /// Play celebration for streak milestone
    func celebrateStreak(days: Int) {
        let style: CelebrationStyle

        switch days {
        case 3:
            style = .starShimmer
        case 7:
            style = unlockedStyles.contains(.rainbowWave) ? .rainbowWave : .fireworks
        case 30:
            style = unlockedStyles.contains(.victoryDance) ? .victoryDance : .epicConfetti
        default:
            style = .confetti
        }

        playCelebration(
            style: style,
            message: "\(days) day streak! Keep it up!",
            duration: 2.5
        )
    }

    /// Manually dismiss active celebration
    func dismissCelebration() {
        activeCelebration = nil
    }

    // MARK: - Unlock Styles

    /// Unlock a new celebration style
    func unlockStyle(_ style: CelebrationStyle) {
        guard !unlockedStyles.contains(style) else { return }

        unlockedStyles.append(style)
        saveUnlockedStyles()

        // Play the newly unlocked celebration
        playCelebration(
            style: style,
            message: "New celebration unlocked: \(style.displayName)!",
            duration: 3.0
        )
    }

    /// Check if a style is unlocked
    func isUnlocked(_ style: CelebrationStyle) -> Bool {
        unlockedStyles.contains(style)
    }

    /// Get all locked styles
    func getLockedStyles() -> [CelebrationStyle] {
        CelebrationStyle.allCases.filter { !unlockedStyles.contains($0) }
    }

    // MARK: - Helper Methods

    private func getDefaultDuration(for style: CelebrationStyle) -> TimeInterval {
        switch style.intensity {
        case 1: return 1.5
        case 2: return 2.0
        case 3: return 2.5
        case 4: return 3.0
        default: return 2.0
        }
    }

    private func saveUnlockedStyles() {
        userDefaultsKeys.unlockedCelebrations = unlockedStyles
    }

    // MARK: - Settings

    /// Toggle celebrations on/off
    func setCelebrationsEnabled(_ enabled: Bool) {
        celebrationsEnabled = enabled
        userDefaultsKeys.celebrationsEnabled = enabled

        if !enabled {
            dismissCelebration()
        }
    }

    /// Get celebration preview
    func previewCelebration(_ style: CelebrationStyle) {
        playCelebration(
            style: style,
            message: "Preview: \(style.displayName)",
            duration: 2.0
        )
    }
}

// MARK: - Celebration Purchase Options

struct CelebrationUnlock {
    let style: CelebrationStyle
    let pointCost: Int
    let requiresAchievement: Achievement?

    static let unlockOptions: [CelebrationUnlock] = [
        CelebrationUnlock(
            style: .confetti,
            pointCost: 0,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .checkmarkBurst,
            pointCost: 50,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .starShimmer,
            pointCost: 100,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .partyPopper,
            pointCost: 150,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .fireworks,
            pointCost: 200,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .rainbowWave,
            pointCost: 300,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .epicConfetti,
            pointCost: 500,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .victoryDance,
            pointCost: 750,
            requiresAchievement: nil
        ),
        CelebrationUnlock(
            style: .goldenShower,
            pointCost: 1000,
            requiresAchievement: nil
        )
    ]

    static func getCost(for style: CelebrationStyle) -> Int {
        unlockOptions.first { $0.style == style }?.pointCost ?? 0
    }
}

// MARK: - Mock Service for Testing

class MockCelebrationService: ObservableObject {
    @Published var unlockedStyles: [CelebrationStyle] = [.confetti]
    @Published var activeCelebration: ActiveCelebration?
    @Published var celebrationsEnabled: Bool = true

    func playCelebration(style: CelebrationStyle, message: String? = nil, duration: TimeInterval? = nil) {
        let config = CelebrationConfig(style: style, message: message)
        activeCelebration = ActiveCelebration(config: config)

        DispatchQueue.main.asyncAfter(deadline: .now() + (duration ?? 2.0)) { [weak self] in
            self?.activeCelebration = nil
        }
    }

    func playRandomCelebration(message: String? = nil) {
        playCelebration(style: unlockedStyles.randomElement() ?? .confetti, message: message)
    }

    func celebrateTaskCompletion(task: Task) {
        playCelebration(style: .confetti, message: "Task completed!")
    }

    func celebrateAchievement(_ achievement: Achievement) {
        playCelebration(style: achievement.rewardCelebration, message: "Achievement unlocked!")
    }

    func celebrateGoalCompletion(goal: Goal) {
        playCelebration(style: .epicConfetti, message: "Goal achieved!")
    }

    func celebrateStreak(days: Int) {
        playCelebration(style: .fireworks, message: "\(days) day streak!")
    }

    func dismissCelebration() {
        activeCelebration = nil
    }

    func unlockStyle(_ style: CelebrationStyle) {
        if !unlockedStyles.contains(style) {
            unlockedStyles.append(style)
        }
    }

    func isUnlocked(_ style: CelebrationStyle) -> Bool {
        unlockedStyles.contains(style)
    }
}
