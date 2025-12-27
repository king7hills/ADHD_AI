//
//  HapticManager.swift
//  ADHDAssistant
//
//  Core Utilities - Haptic Feedback Manager
//

import UIKit
import SwiftUI

/// Centralized manager for haptic feedback throughout the app
final class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    private init() {}

    // MARK: - Impact Feedback

    /// Triggers a light impact feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Triggers a light impact feedback
    func light() {
        impact(.light)
    }

    /// Triggers a medium impact feedback
    func medium() {
        impact(.medium)
    }

    /// Triggers a heavy impact feedback
    func heavy() {
        impact(.heavy)
    }

    /// Triggers a soft impact feedback (iOS 13+)
    @available(iOS 13.0, *)
    func soft() {
        impact(.soft)
    }

    /// Triggers a rigid impact feedback (iOS 13+)
    @available(iOS 13.0, *)
    func rigid() {
        impact(.rigid)
    }

    // MARK: - Notification Feedback

    /// Triggers a success notification feedback
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Triggers a warning notification feedback
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Triggers an error notification feedback
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Triggers selection changed feedback (like in a picker)
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Custom Patterns

    /// Triggers a celebration pattern based on achievement tier
    func celebration(_ tier: CelebrationTier) {
        switch tier {
        case .bronze:
            celebrationBronze()
        case .silver:
            celebrationSilver()
        case .gold:
            celebrationGold()
        }
    }

    /// Bronze celebration pattern - simple success
    private func celebrationBronze() {
        success()
    }

    /// Silver celebration pattern - double success with impact
    private func celebrationSilver() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.medium()
        }
    }

    /// Gold celebration pattern - triple burst with crescendo
    private func celebrationGold() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            self.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            self.success()
        }
    }

    /// Task completion pattern
    func taskComplete() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.light()
        }
    }

    /// Streak milestone pattern
    func streakMilestone(_ days: Int) {
        if days >= 30 {
            celebrationGold()
        } else if days >= 14 {
            celebrationSilver()
        } else if days >= 7 {
            celebrationBronze()
        } else {
            success()
        }
    }

    /// Timer tick pattern (for last 10 seconds)
    func timerTick() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
    }

    /// Timer complete pattern
    func timerComplete() {
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.heavy()
        }
    }

    /// Level up pattern
    func levelUp() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.heavy()
        }
    }

    /// Achievement unlocked pattern
    func achievementUnlocked() {
        celebrationGold()
    }

    /// Button press pattern
    func buttonPress() {
        light()
    }

    /// Toggle switch pattern
    func toggleSwitch() {
        if #available(iOS 13.0, *) {
            rigid()
        } else {
            medium()
        }
    }

    /// Delete action pattern
    func delete() {
        if #available(iOS 13.0, *) {
            rigid()
        } else {
            medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.error()
        }
    }

    /// Swipe action pattern
    func swipeAction() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
    }

    /// Pull to refresh pattern
    func pullToRefresh() {
        medium()
    }

    /// Notification received pattern
    func notificationReceived() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.light()
        }
    }

    // MARK: - ADHD-Specific Patterns

    /// Focus mode start pattern - calming
    func focusModeStart() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if #available(iOS 13.0, *) {
                self.soft()
            } else {
                self.light()
            }
        }
    }

    /// Break time pattern - gentle reminder
    func breakTime() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.light()
        }
    }

    /// Urgent reminder pattern - attention grabbing
    func urgentReminder() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.heavy()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.warning()
        }
    }

    /// Dopamine hit pattern - reward for completing task
    func dopamineHit() {
        celebrationGold()
    }

    /// Gentle nudge pattern - non-intrusive reminder
    func gentleNudge() {
        if #available(iOS 13.0, *) {
            soft()
        } else {
            light()
        }
    }

    /// Transition pattern - smooth state change
    func transition() {
        selectionChanged()
    }

    // MARK: - Helper Types

    enum CelebrationTier {
        case bronze
        case silver
        case gold
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds haptic feedback on tap
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            HapticManager.shared.impact(style)
        }
    }

    /// Adds success haptic feedback on tap
    func successHaptic() -> some View {
        self.onTapGesture {
            HapticManager.shared.success()
        }
    }
}

// MARK: - Preview Provider

#Preview("Haptic Manager Demo") {
    HapticManagerDemo()
}

private struct HapticManagerDemo: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Haptic Feedback Demo")
                    .font(.title.bold())
                    .padding(.top)

                Text("Tap buttons to feel different haptic patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Impact Feedback
                Section {
                    Text("Impact Feedback")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        HapticButton(title: "Light", color: .blue) {
                            HapticManager.shared.light()
                        }
                        HapticButton(title: "Medium", color: .blue) {
                            HapticManager.shared.medium()
                        }
                        HapticButton(title: "Heavy", color: .blue) {
                            HapticManager.shared.heavy()
                        }
                        if #available(iOS 13.0, *) {
                            HapticButton(title: "Soft", color: .blue) {
                                HapticManager.shared.soft()
                            }
                            HapticButton(title: "Rigid", color: .blue) {
                                HapticManager.shared.rigid()
                            }
                        }
                    }
                }

                Divider()
                    .padding(.vertical)

                // Notification Feedback
                Section {
                    Text("Notification Feedback")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        HapticButton(title: "Success", color: .green) {
                            HapticManager.shared.success()
                        }
                        HapticButton(title: "Warning", color: .orange) {
                            HapticManager.shared.warning()
                        }
                        HapticButton(title: "Error", color: .red) {
                            HapticManager.shared.error()
                        }
                    }
                }

                Divider()
                    .padding(.vertical)

                // Celebration Patterns
                Section {
                    Text("Celebration Patterns")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        HapticButton(title: "Bronze 🥉", color: Color(hex: "#CD7F32")) {
                            HapticManager.shared.celebration(.bronze)
                        }
                        HapticButton(title: "Silver 🥈", color: Color(hex: "#C0C0C0")) {
                            HapticManager.shared.celebration(.silver)
                        }
                        HapticButton(title: "Gold 🥇", color: Color(hex: "#FFD700")) {
                            HapticManager.shared.celebration(.gold)
                        }
                    }
                }

                Divider()
                    .padding(.vertical)

                // Custom Patterns
                Section {
                    Text("Custom Patterns")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        HapticButton(title: "Task Complete ✅", color: .green) {
                            HapticManager.shared.taskComplete()
                        }
                        HapticButton(title: "Level Up ⬆️", color: .purple) {
                            HapticManager.shared.levelUp()
                        }
                        HapticButton(title: "Timer Complete ⏰", color: .blue) {
                            HapticManager.shared.timerComplete()
                        }
                        HapticButton(title: "Achievement 🏆", color: Color(hex: "#FFD700")) {
                            HapticManager.shared.achievementUnlocked()
                        }
                    }
                }

                Divider()
                    .padding(.vertical)

                // ADHD-Specific Patterns
                Section {
                    Text("ADHD-Specific Patterns")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        HapticButton(title: "Focus Mode Start 🎯", color: .indigo) {
                            HapticManager.shared.focusModeStart()
                        }
                        HapticButton(title: "Break Time ☕️", color: .cyan) {
                            HapticManager.shared.breakTime()
                        }
                        HapticButton(title: "Gentle Nudge 👉", color: .mint) {
                            HapticManager.shared.gentleNudge()
                        }
                        HapticButton(title: "Dopamine Hit 🎉", color: .pink) {
                            HapticManager.shared.dopamineHit()
                        }
                        HapticButton(title: "Urgent Reminder ⚠️", color: .orange) {
                            HapticManager.shared.urgentReminder()
                        }
                    }
                }

                Divider()
                    .padding(.vertical)

                // Other Patterns
                Section {
                    Text("Other Patterns")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        HapticButton(title: "Selection Changed", color: .gray) {
                            HapticManager.shared.selectionChanged()
                        }
                        HapticButton(title: "Delete", color: .red) {
                            HapticManager.shared.delete()
                        }
                        HapticButton(title: "Swipe Action", color: .blue) {
                            HapticManager.shared.swipeAction()
                        }
                        HapticButton(title: "Toggle Switch", color: .green) {
                            HapticManager.shared.toggleSwitch()
                        }
                    }
                }
            }
            .padding(.bottom)
        }
    }
}

private struct HapticButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
}

// Helper for hex colors in preview
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
