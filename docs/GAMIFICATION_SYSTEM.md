# Gamification System Specification

The gamification system applies positive reinforcement psychology to encourage consistent task completion and healthy habit formation.

---

## Core Philosophy

### ADHD-Optimized Dopamine Loops

Traditional gamification often fails for ADHD users because:
- Delayed rewards lose their motivational power
- Complex point systems are overwhelming
- Abstract achievements don't feel meaningful

Our approach:
1. **Immediate feedback** - Celebration the instant a task is marked done
2. **Simple, visible progress** - One number (points) and one streak count
3. **Tangible rewards** - New animations/sounds that users actually experience
4. **Low-stakes consistency** - Missing a day doesn't destroy progress

---

## Points System

### Earning Points

| Action | Base Points | Notes |
|--------|-------------|-------|
| Complete micro-task | 10 | Tasks < 10 minutes |
| Complete standard task | 25 | Tasks 10-30 minutes |
| Complete major task | 50 | Tasks > 30 minutes |
| Log health metric | 15 | Blood sugar, medication, etc. |
| First task of day | 25 | Bonus for starting momentum |
| Beat time estimate | 20 | Finished faster than estimated |
| Complete on-time | 10 | Finished before scheduled end |

### Streak Multipliers

| Streak Days | Multiplier |
|-------------|-----------|
| 1-2 | 1.0x |
| 3-6 | 1.25x |
| 7-13 | 1.5x |
| 14-29 | 1.75x |
| 30+ | 2.0x |

### Daily Streak Bonus

| Streak | Daily Bonus |
|--------|-------------|
| 3 days | 50 points |
| 7 days | 150 points |
| 14 days | 300 points |
| 30 days | 750 points |
| 60 days | 1500 points |
| 100 days | 3000 points |

### Implementation

```swift
// Services/Gamification/PointsService.swift

final class PointsService: ObservableObject {
    @Published private(set) var totalPoints: Int = 0
    @Published private(set) var todayPoints: Int = 0
    @Published private(set) var currentStreak: Int = 0

    private let persistence: PointsPersistence

    struct PointEvent {
        let action: PointAction
        let basePoints: Int
        let multiplier: Double
        let bonusPoints: Int
        let reason: String?

        var totalPoints: Int {
            Int(Double(basePoints) * multiplier) + bonusPoints
        }
    }

    enum PointAction: String, Codable {
        case taskCompleted
        case healthLogged
        case firstTaskOfDay
        case beatEstimate
        case onTimeCompletion
        case streakBonus
    }

    func awardPoints(for task: Task) -> PointEvent {
        var basePoints = calculateBasePoints(for: task)
        var bonusPoints = 0
        var reasons: [String] = []

        // First task of day bonus
        if isFirstTaskOfDay() {
            bonusPoints += 25
            reasons.append("First task of the day!")
        }

        // Beat estimate bonus
        if let actual = task.actualDuration,
           actual < task.estimatedDuration {
            bonusPoints += 20
            reasons.append("Faster than expected!")
        }

        // On-time bonus
        if task.completedAt != nil,
           let scheduled = task.scheduledTime,
           task.completedAt! <= scheduled.addingTimeInterval(task.estimatedDuration) {
            bonusPoints += 10
            reasons.append("Completed on time!")
        }

        let multiplier = streakMultiplier

        let event = PointEvent(
            action: .taskCompleted,
            basePoints: basePoints,
            multiplier: multiplier,
            bonusPoints: bonusPoints,
            reason: reasons.joined(separator: " ")
        )

        applyPoints(event)
        return event
    }

    private func calculateBasePoints(for task: Task) -> Int {
        switch task.estimatedDuration {
        case ..<600: return 10      // < 10 minutes
        case 600..<1800: return 25  // 10-30 minutes
        default: return 50          // > 30 minutes
        }
    }

    private var streakMultiplier: Double {
        switch currentStreak {
        case 0...2: return 1.0
        case 3...6: return 1.25
        case 7...13: return 1.5
        case 14...29: return 1.75
        default: return 2.0
        }
    }
}
```

---

## Streak System

### Streak Rules

1. **Earning a streak day**: Complete at least 1 task
2. **Maintaining streak**: Complete at least 1 task each calendar day
3. **Grace period**: 1 "free pass" per week (automatically used)
4. **Streak freeze**: Can be purchased with points (500 points = 1 freeze)

### Streak Recovery

If a streak is broken:
- Streak resets to 0
- "Recovery bonus" available: Complete 3 tasks in one day to start at streak of 2
- No shame messaging - just encouragement to start again

### Implementation

```swift
// Services/Gamification/StreakService.swift

final class StreakService: ObservableObject {
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var freePassesRemaining: Int = 1
    @Published private(set) var freezesAvailable: Int = 0

    private let calendar = Calendar.current

    struct StreakStatus {
        let currentStreak: Int
        let isAtRisk: Bool          // No task completed today yet
        let hoursRemaining: Double  // Until day ends
        let usedFreePass: Bool
        let streakProtected: Bool   // Has freeze active
    }

    func checkStreak() -> StreakStatus {
        let now = Date()
        let endOfDay = calendar.endOfDay(for: now)
        let hoursRemaining = endOfDay.timeIntervalSince(now) / 3600

        let hasCompletedToday = hasTaskCompletedToday()
        let isAtRisk = !hasCompletedToday && hoursRemaining < 6

        return StreakStatus(
            currentStreak: currentStreak,
            isAtRisk: isAtRisk,
            hoursRemaining: hoursRemaining,
            usedFreePass: freePassesRemaining == 0,
            streakProtected: freezesAvailable > 0
        )
    }

    func recordDayCompletion() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        if wasYesterdayCompleted() {
            currentStreak += 1
        } else if freePassesRemaining > 0 {
            freePassesRemaining -= 1
            currentStreak += 1
        } else if freezesAvailable > 0 {
            freezesAvailable -= 1
            currentStreak += 1
        } else {
            // Streak broken - check for recovery
            if todayTaskCount() >= 3 {
                currentStreak = 2 // Recovery bonus
            } else {
                currentStreak = 1
            }
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Reset free pass on Mondays
        if calendar.component(.weekday, from: Date()) == 2 {
            freePassesRemaining = 1
        }
    }
}
```

---

## Achievement System

### Achievement Tiers

#### Tier 1: Bronze (0-500 points to unlock)
Basic achievements that unlock standard celebrations.

| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| First Step | Complete 1 task | Confetti animation |
| Getting Started | Complete 5 tasks | Checkmark burst |
| On a Roll | 3-day streak | Star shimmer |
| Early Bird | Task before 9 AM | Morning celebration |
| Night Owl | Task after 9 PM | Calm celebration |
| Health Conscious | Log 1 health metric | Health sparkle |

#### Tier 2: Silver (500-2000 points to unlock)
Intermediate achievements with enhanced animations.

| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| Week Warrior | 7-day streak | Fireworks animation |
| Task Master | Complete 25 tasks | Rainbow wave |
| Time Lord | Beat estimates 5 times | Time warp effect |
| Consistent Care | Health logs 7 days | Health halo |
| Goal Getter | Complete a full goal | Goal celebration |
| Momentum Builder | 3 tasks in 1 hour | Speed burst |

#### Tier 3: Gold (2000+ points to unlock)
Advanced achievements with premium celebrations.

| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| Unstoppable | 30-day streak | Epic confetti rain |
| Century Club | Complete 100 tasks | Grand celebration |
| Master Estimator | 80% accuracy (20+ tasks) | Precision animation |
| Life Changer | Complete 10 goals | Life transformation |
| Health Champion | 30 days health tracking | Wellness victory |
| Perfect Week | All scheduled tasks, 7 days | Perfect score |

### Achievement Display

```swift
// Core/Models/Achievement.swift

struct Achievement: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var iconName: String
    var tier: AchievementTier
    var unlockedAt: Date?
    var progress: Double      // 0.0 to 1.0
    var currentCount: Int
    var requirement: Int
    var rewardCelebration: CelebrationStyle

    var isUnlocked: Bool { unlockedAt != nil }

    var progressText: String {
        if isUnlocked {
            return "Unlocked!"
        } else {
            return "\(currentCount)/\(requirement)"
        }
    }

    enum AchievementTier: String, Codable, CaseIterable {
        case bronze
        case silver
        case gold

        var color: Color {
            switch self {
            case .bronze: return Color(hex: "#CD7F32")
            case .silver: return Color(hex: "#C0C0C0")
            case .gold: return Color(hex: "#FFD700")
            }
        }

        var pointsRequired: Int {
            switch self {
            case .bronze: return 0
            case .silver: return 500
            case .gold: return 2000
            }
        }
    }
}
```

### Achievement Service

```swift
// Services/Gamification/AchievementService.swift

final class AchievementService: ObservableObject {
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var recentlyUnlocked: Achievement?

    private let persistence: AchievementPersistence
    private let celebrationService: CelebrationService

    static let allAchievements: [Achievement] = [
        // Bronze
        Achievement(
            id: "first_step",
            title: "First Step",
            description: "Complete your first task",
            iconName: "figure.walk",
            tier: .bronze,
            currentCount: 0,
            requirement: 1,
            rewardCelebration: .confetti
        ),
        Achievement(
            id: "on_a_roll",
            title: "On a Roll",
            description: "Maintain a 3-day streak",
            iconName: "flame",
            tier: .bronze,
            currentCount: 0,
            requirement: 3,
            rewardCelebration: .starShimmer
        ),
        // ... more achievements
    ]

    func checkProgress(event: GameEvent) async {
        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }

            let newCount = calculateProgress(
                for: achievements[i],
                event: event
            )

            if newCount != achievements[i].currentCount {
                achievements[i].currentCount = newCount
                achievements[i].progress = Double(newCount) / Double(achievements[i].requirement)

                if newCount >= achievements[i].requirement {
                    await unlockAchievement(&achievements[i])
                }
            }
        }
    }

    private func unlockAchievement(_ achievement: inout Achievement) async {
        achievement.unlockedAt = Date()
        recentlyUnlocked = achievement

        await celebrationService.play(achievement.rewardCelebration)

        // Clear after display
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        recentlyUnlocked = nil
    }
}
```

---

## Celebration System

### Celebration Types

```swift
// Services/Gamification/CelebrationService.swift

enum CelebrationStyle: String, Codable, CaseIterable {
    // Tier 1 - Default unlocked
    case confetti
    case checkmarkBurst
    case starShimmer

    // Tier 2 - Unlock with silver achievements
    case fireworks
    case rainbowWave
    case partyPopper

    // Tier 3 - Unlock with gold achievements
    case epicConfetti
    case victoryDance
    case goldenShower

    var tier: Achievement.AchievementTier {
        switch self {
        case .confetti, .checkmarkBurst, .starShimmer:
            return .bronze
        case .fireworks, .rainbowWave, .partyPopper:
            return .silver
        case .epicConfetti, .victoryDance, .goldenShower:
            return .gold
        }
    }

    var duration: TimeInterval {
        switch tier {
        case .bronze: return 1.5
        case .silver: return 2.0
        case .gold: return 3.0
        }
    }
}

@MainActor
final class CelebrationService: ObservableObject {
    @Published private(set) var activeCelebration: CelebrationStyle?
    @Published private(set) var unlockedCelebrations: Set<CelebrationStyle> = [
        .confetti, .checkmarkBurst, .starShimmer  // Default unlocked
    ]

    private let haptics = HapticManager()

    func play(_ style: CelebrationStyle) async {
        guard unlockedCelebrations.contains(style) else {
            // Fall back to a basic celebration
            await play(.confetti)
            return
        }

        activeCelebration = style
        haptics.celebrate(intensity: style.tier)

        try? await Task.sleep(for: .seconds(style.duration))
        activeCelebration = nil
    }

    func unlock(_ style: CelebrationStyle) {
        unlockedCelebrations.insert(style)
    }

    func randomCelebration() -> CelebrationStyle {
        let available = Array(unlockedCelebrations)
        return available.randomElement() ?? .confetti
    }
}
```

### Confetti Animation

```swift
// DesignSystem/Animations/ConfettiAnimation.swift

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let style: CelebrationStyle

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        let count: Int
        switch style {
        case .confetti: count = 50
        case .epicConfetti: count = 150
        case .goldenShower: count = 100
        default: count = 30
        }

        particles = (0..<count).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                color: randomConfettiColor(),
                size: CGFloat.random(in: 8...16),
                duration: Double.random(in: 2...4)
            )
        }
    }

    private func randomConfettiColor() -> Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink
        ]
        return colors.randomElement()!
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var color: Color
    var size: CGFloat
    var duration: Double
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var animate = false

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(animate ? particle.rotation + 360 : particle.rotation))
            .position(
                x: particle.x + (animate ? CGFloat.random(in: -50...50) : 0),
                y: animate ? UIScreen.main.bounds.height + 50 : particle.y
            )
            .onAppear {
                withAnimation(
                    .easeOut(duration: particle.duration)
                ) {
                    animate = true
                }
            }
    }
}
```

---

## The "Done?" Button

The signature interaction element.

```swift
// DesignSystem/Components/PulsingButton.swift

import SwiftUI

struct DoneButton: View {
    @Binding var isCompleted: Bool
    let onComplete: () -> Void

    @State private var isPulsing = true
    @State private var scale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 10

    private let baseColor = Color.blue
    private let completedColor = Color.green

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(currentColor.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .blur(radius: glowRadius)

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [currentColor, currentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: currentColor.opacity(0.5), radius: 10, y: 5)

                // Text
                Text(isCompleted ? "Done!" : "Done?")
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .onAppear(perform: startPulsing)
        .onChange(of: isCompleted) { _, completed in
            if completed {
                stopPulsing()
            }
        }
    }

    private var currentColor: Color {
        isCompleted ? completedColor : baseColor
    }

    private func handleTap() {
        guard !isCompleted else { return }

        // Satisfying haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Quick scale animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            scale = 1.2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                isCompleted = true
            }
        }

        onComplete()
    }

    private func startPulsing() {
        guard !isCompleted else { return }

        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.05
            glowRadius = 20
        }
    }

    private func stopPulsing() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            glowRadius = 10
        }
    }
}

// Preview
#Preview {
    struct PreviewWrapper: View {
        @State var done = false

        var body: some View {
            VStack {
                DoneButton(isCompleted: $done) {
                    print("Task completed!")
                }

                Button("Reset") { done = false }
                    .padding(.top, 40)
            }
        }
    }

    return PreviewWrapper()
}
```

---

## Haptic Feedback

```swift
// Core/Utilities/HapticManager.swift

import UIKit

final class HapticManager {
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    init() {
        // Pre-warm generators
        lightGenerator.prepare()
        mediumGenerator.prepare()
    }

    func taskComplete() {
        notificationGenerator.notificationOccurred(.success)
    }

    func buttonTap() {
        lightGenerator.impactOccurred()
    }

    func celebrate(intensity: Achievement.AchievementTier) {
        switch intensity {
        case .bronze:
            mediumGenerator.impactOccurred()
        case .silver:
            heavyGenerator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.mediumGenerator.impactOccurred()
            }
        case .gold:
            // Victory pattern
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    self.heavyGenerator.impactOccurred()
                }
            }
        }
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}
```

---

## Integration Points

### Task Completion Flow

```
User taps "Done?" button
        │
        ▼
┌─────────────────────────┐
│ Mark task as completed  │
│ in TaskRepository       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ PointsService.award()   │
│ - Calculate base points │
│ - Apply multipliers     │
│ - Check bonuses         │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ StreakService.record()  │
│ - Update daily count    │
│ - Check streak status   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ AchievementService      │
│ .checkProgress()        │
│ - Evaluate all unlocks  │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ CelebrationService      │
│ .play()                 │
│ - Show animation        │
│ - Trigger haptics       │
└─────────────────────────┘
```

### Daily Summary

```swift
struct DailySummary {
    let date: Date
    let tasksCompleted: Int
    let totalTasks: Int
    let pointsEarned: Int
    let streakDay: Int
    let achievementsUnlocked: [Achievement]
    let healthMetricsLogged: Int

    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(tasksCompleted) / Double(totalTasks)
    }

    var grade: Grade {
        switch completionRate {
        case 0.9...: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .okay
        default: return .needsWork
        }
    }

    enum Grade: String {
        case excellent = "🌟"
        case good = "✨"
        case okay = "👍"
        case needsWork = "💪"

        var message: String {
            switch self {
            case .excellent: return "Outstanding day!"
            case .good: return "Great progress!"
            case .okay: return "Solid effort!"
            case .needsWork: return "Tomorrow's a fresh start!"
            }
        }
    }
}
```

---

## Sound Design (Optional Enhancement)

```swift
// Services/Gamification/SoundService.swift

import AVFoundation

final class SoundService {
    private var audioPlayer: AVAudioPlayer?

    enum Sound: String {
        case taskComplete = "task_complete"
        case achievementUnlock = "achievement"
        case streakBonus = "streak"
        case levelUp = "level_up"
        case buttonTap = "tap"
    }

    func play(_ sound: Sound) {
        guard let url = Bundle.main.url(
            forResource: sound.rawValue,
            withExtension: "mp3"
        ) else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Sound playback failed: \(error)")
        }
    }
}
```

---

## A/B Testing Considerations

For future optimization, track:

1. **Celebration preferences** - Which animations lead to higher completion rates
2. **Point values** - Optimal amounts for motivation
3. **Streak forgiveness** - Does the free pass increase retention?
4. **Notification timing** - When do gamification reminders work best?

```swift
struct GamificationEvent: Codable {
    let timestamp: Date
    let eventType: String
    let userId: String  // anonymized
    let celebrationShown: CelebrationStyle
    let pointsAwarded: Int
    let streakDay: Int
    let sessionDuration: TimeInterval
    let subsequentActions: Int  // tasks in next hour
}
```
