//
//  CelebrationAnimations.swift
//  ADHDAssistant
//
//  Design System - Celebration Overlay and Animations
//

import SwiftUI

/// Celebration style enum
enum CelebrationStyle {
    case bronze
    case silver
    case gold
    case streak
    case levelUp
    case achievement
    case taskComplete
    case custom(emoji: String, message: String)

    var emoji: String {
        switch self {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .streak: return "🔥"
        case .levelUp: return "⬆️"
        case .achievement: return "🏆"
        case .taskComplete: return "✅"
        case .custom(let emoji, _): return emoji
        }
    }

    var message: String {
        switch self {
        case .bronze: return "Bronze Achievement!"
        case .silver: return "Silver Achievement!"
        case .gold: return "Gold Achievement!"
        case .streak: return "Streak Milestone!"
        case .levelUp: return "Level Up!"
        case .achievement: return "Achievement Unlocked!"
        case .taskComplete: return "Task Completed!"
        case .custom(_, let message): return message
        }
    }

    var confettiStyle: ConfettiView.ConfettiStyle {
        switch self {
        case .bronze: return .standard
        case .silver: return .celebration
        case .gold: return .achievement
        case .streak: return .celebration
        case .levelUp: return .rainbow
        case .achievement: return .achievement
        case .taskComplete: return .standard
        case .custom: return .celebration
        }
    }

    var primaryColor: Color {
        switch self {
        case .bronze: return AppColors.bronze
        case .silver: return AppColors.silver
        case .gold: return AppColors.gold
        case .streak: return Color(hex: "#FF4500")
        case .levelUp: return AppColors.secondary
        case .achievement: return AppColors.gold
        case .taskComplete: return AppColors.success
        case .custom: return AppColors.primary
        }
    }
}

/// Main celebration overlay view
struct CelebrationOverlay: View {
    var style: CelebrationStyle
    var duration: Double = 3.0
    var onComplete: (() -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -10
    @State private var showConfetti = false
    @State private var bounceOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(opacity)

            // Confetti layer
            if showConfetti {
                ConfettiView(
                    style: style.confettiStyle,
                    duration: duration,
                    onComplete: onComplete
                )
            }

            // Main content
            VStack(spacing: 24) {
                // Emoji with bounce animation
                Text(style.emoji)
                    .font(.system(size: 120))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .offset(y: bounceOffset)

                // Message
                Text(style.message)
                    .font(AppTypography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(opacity)

                // Decorative elements
                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(style.primaryColor)
                            .frame(width: 8, height: 8)
                    }
                }
                .opacity(opacity)
            }
            .scaleEffect(scale)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Haptic feedback
        triggerHaptics()

        // Show confetti immediately
        showConfetti = true

        // Entrance animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
            rotation = 0
        }

        // Bounce animation
        withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true).delay(0.3)) {
            bounceOffset = -20
        }

        // Exit animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration - 0.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
                scale = 1.2
            }
        }
    }

    private func triggerHaptics() {
        switch style {
        case .bronze:
            HapticManager.shared.celebration(.bronze)
        case .silver:
            HapticManager.shared.celebration(.silver)
        case .gold, .achievement:
            HapticManager.shared.celebration(.gold)
        default:
            HapticManager.shared.success()
        }
    }
}

/// Compact celebration animation for smaller wins
struct CompactCelebration: View {
    var emoji: String = "🎉"
    var message: String
    var color: Color = AppColors.success
    var onComplete: (() -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 60))

            Text(message)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.card)
                .shadow(color: color.opacity(0.3), radius: 20)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            HapticManager.shared.success()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete?()
                }
            }
        }
    }
}

/// Points animation for gamification
struct PointsAnimation: View {
    var points: Int
    var tier: CelebrationStyle
    var onComplete: (() -> Void)?

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = 0
    @State private var glow: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Points with tier emoji
            HStack(spacing: 12) {
                Text(tier.emoji)
                    .font(.system(size: 50))

                Text("+\(points)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(tier.primaryColor)
                    .monospacedDigit()
            }
            .shadow(color: tier.primaryColor.opacity(glow ? 0.6 : 0.3), radius: glow ? 20 : 10)

            Text("Points")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offsetY)
        .onAppear {
            HapticManager.shared.success()

            // Scale in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)) {
                glow = true
            }

            // Float up and fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    offsetY = -100
                    opacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete?()
                }
            }
        }
    }
}

/// Shake animation for errors or attention
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    /// Applies shake animation
    func shake(trigger: Int) -> some View {
        modifier(ShakeModifier(shakes: trigger))
    }
}

private struct ShakeModifier: ViewModifier {
    let shakes: Int

    @State private var attempts = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
            .onChange(of: shakes) { _, _ in
                withAnimation(.default) {
                    attempts += 1
                }
            }
    }
}

/// Pop animation for button feedback
extension View {
    func popEffect(trigger: Bool) -> some View {
        self.scaleEffect(trigger ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: trigger)
    }
}

// MARK: - Preview Provider

#Preview("Celebration Overlays") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        VStack {
            Text("Celebration will auto-play")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }

        CelebrationOverlay(style: .gold, duration: 4.0)
    }
}

#Preview("All Celebration Styles") {
    AllCelebrationsPreview()
}

private struct AllCelebrationsPreview: View {
    @State private var selectedStyle: CelebrationStyle = .gold
    @State private var showCelebration = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Celebration Styles")
                .font(.title2.bold())

            ScrollView {
                VStack(spacing: 12) {
                    Button("Bronze") {
                        selectedStyle = .bronze
                        showCelebration = true
                    }
                    .buttonStyle(.bordered)

                    Button("Silver") {
                        selectedStyle = .silver
                        showCelebration = true
                    }
                    .buttonStyle(.bordered)

                    Button("Gold") {
                        selectedStyle = .gold
                        showCelebration = true
                    }
                    .buttonStyle(.bordered)

                    Button("Streak") {
                        selectedStyle = .streak
                        showCelebration = true
                    }
                    .buttonStyle(.bordered)

                    Button("Level Up") {
                        selectedStyle = .levelUp
                        showCelebration = true
                    }
                    .buttonStyle(.bordered)

                    Button("Achievement") {
                        selectedStyle = .achievement
                        showCelebration = true
                    }
                    .buttonStyle(.bordered)

                    Button("Task Complete") {
                        selectedStyle = .taskComplete
                        showCelebration = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .overlay(
            Group {
                if showCelebration {
                    CelebrationOverlay(style: selectedStyle) {
                        showCelebration = false
                    }
                }
            }
        )
    }
}

#Preview("Compact Celebrations") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        CompactCelebration(
            emoji: "🎉",
            message: "Great job!",
            color: AppColors.success
        )
    }
}

#Preview("Points Animation") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        PointsAnimation(points: 50, tier: .gold)
    }
}

#Preview("Interactive Demo") {
    InteractiveCelebrationDemo()
}

private struct InteractiveCelebrationDemo: View {
    @State private var showCelebration = false
    @State private var showPoints = false
    @State private var showCompact = false
    @State private var shakeCount = 0

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Text("Interactive Celebration Demo")
                    .font(.title2.bold())

                VStack(spacing: 16) {
                    Button("Full Celebration") {
                        showCelebration = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Points +50") {
                        showPoints = true
                    }
                    .buttonStyle(.bordered)

                    Button("Compact Toast") {
                        showCompact = true
                    }
                    .buttonStyle(.bordered)

                    Button("Shake Effect") {
                        HapticManager.shared.error()
                        shakeCount += 1
                    }
                    .buttonStyle(.bordered)
                    .shake(trigger: shakeCount)
                }
                .frame(maxWidth: 300)
            }
            .padding()

            if showCelebration {
                CelebrationOverlay(style: .achievement) {
                    showCelebration = false
                }
            }

            if showPoints {
                PointsAnimation(points: 50, tier: .gold) {
                    showPoints = false
                }
            }

            if showCompact {
                VStack {
                    CompactCelebration(
                        emoji: "✨",
                        message: "Task completed!",
                        color: AppColors.success
                    ) {
                        showCompact = false
                    }
                    Spacer()
                }
                .padding(.top, 100)
            }
        }
    }
}
