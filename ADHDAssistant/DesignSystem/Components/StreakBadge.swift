//
//  StreakBadge.swift
//  ADHDAssistant
//
//  Design System - Streak Badge Component
//

import SwiftUI

/// A badge displaying streak count with animated flame effect
struct StreakBadge: View {
    var streakCount: Int
    var size: BadgeSize = .medium
    var showLabel: Bool = true
    var animated: Bool = true

    @State private var isFlickering = false
    @State private var rotation: Double = 0

    var body: some View {
        HStack(spacing: size.spacing) {
            // Flame icon with animation
            ZStack {
                // Glow effect for long streaks
                if isOnFire {
                    Image(systemName: "flame.fill")
                        .font(.system(size: size.iconSize))
                        .foregroundColor(flameColor.opacity(0.3))
                        .scaleEffect(isFlickering ? 1.4 : 1.2)
                        .blur(radius: 4)
                }

                // Main flame
                Image(systemName: "flame.fill")
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(flameColor)
                    .scaleEffect(isFlickering ? 1.05 : 1.0)
                    .rotationEffect(.degrees(isFlickering ? rotation : 0))
            }

            // Streak count
            Text("\(streakCount)")
                .font(size.font)
                .fontWeight(.bold)
                .foregroundColor(flameColor)
                .monospacedDigit()

            // Optional "day" label
            if showLabel {
                Text(streakCount == 1 ? "day" : "days")
                    .font(size.labelFont)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .overlay(
            Capsule()
                .strokeBorder(flameColor.opacity(0.3), lineWidth: isOnFire ? 2 : 1)
        )
        .shadow(
            color: isOnFire ? flameColor.opacity(0.3) : Color.clear,
            radius: isOnFire ? 8 : 0
        )
        .onAppear {
            if animated {
                startFlickering()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streakCount) day streak")
    }

    // MARK: - Computed Properties

    private var flameColor: Color {
        switch streakCount {
        case 0:
            return AppColors.textTertiary
        case 1...3:
            return Color(hex: "#FFA500") // Orange
        case 4...6:
            return Color(hex: "#FF6B00") // Deep orange
        case 7...13:
            return Color(hex: "#FF4500") // Red-orange
        case 14...29:
            return Color(hex: "#FF0000") // Red
        default:
            return Color(hex: "#FFD700") // Gold - legendary
        }
    }

    private var backgroundColor: Color {
        if streakCount == 0 {
            return AppColors.surface
        } else if isOnFire {
            return flameColor.opacity(0.15)
        } else {
            return flameColor.opacity(0.1)
        }
    }

    private var isOnFire: Bool {
        streakCount >= 7
    }

    private func startFlickering() {
        if streakCount > 0 {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isFlickering = true
            }

            // Subtle rotation for "on fire" state
            if isOnFire {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    rotation = 3
                }
            }
        }
    }

    // MARK: - Types

    enum BadgeSize {
        case small
        case medium
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }

        var font: Font {
            switch self {
            case .small: return AppTypography.footnote
            case .medium: return AppTypography.headline
            case .large: return AppTypography.title3
            }
        }

        var labelFont: Font {
            switch self {
            case .small: return AppTypography.caption
            case .medium: return AppTypography.footnote
            case .large: return AppTypography.subheadline
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
}

/// Compact streak indicator for toolbars and headers
struct CompactStreakIndicator: View {
    var streakCount: Int

    @State private var isFlickering = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundColor(flameColor)
                .scaleEffect(isFlickering ? 1.1 : 1.0)

            Text("\(streakCount)")
                .font(AppTypography.captionBold)
                .foregroundColor(flameColor)
                .monospacedDigit()
        }
        .onAppear {
            if streakCount > 0 {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isFlickering = true
                }
            }
        }
    }

    private var flameColor: Color {
        switch streakCount {
        case 0: return AppColors.textTertiary
        case 1...6: return Color(hex: "#FFA500")
        case 7...13: return Color(hex: "#FF4500")
        default: return Color(hex: "#FFD700")
        }
    }
}

/// Large streak display for achievements and milestones
struct StreakMilestone: View {
    var streakCount: Int
    var milestone: Int
    var showProgress: Bool = true

    @State private var isAnimating = false
    @State private var particles: [FlameParticle] = []

    var body: some View {
        VStack(spacing: 16) {
            // Large flame with particles
            ZStack {
                // Particle effects for major milestones
                if streakCount >= 7 {
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }

                // Main flame
                Image(systemName: "flame.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(flameColor)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .shadow(color: flameColor.opacity(0.5), radius: 20)
            }
            .frame(height: 120)

            // Streak count
            VStack(spacing: 4) {
                Text("\(streakCount)")
                    .font(AppTypography.pointsDisplay)
                    .foregroundColor(AppColors.textPrimary)

                Text(streakCount == 1 ? "Day Streak" : "Day Streak")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }

            // Progress to next milestone
            if showProgress && streakCount < milestone {
                VStack(spacing: 8) {
                    ProgressView(value: Double(streakCount), total: Double(milestone))
                        .tint(flameColor)

                    Text("\(milestone - streakCount) days to \(milestone)-day milestone")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal)
            } else if streakCount >= milestone {
                Text("🎉 \(milestone)-day milestone achieved!")
                    .font(AppTypography.headline)
                    .foregroundColor(flameColor)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.card)
                .shadow(color: flameColor.opacity(0.2), radius: 16)
        )
        .onAppear {
            startAnimations()
        }
    }

    private var flameColor: Color {
        switch streakCount {
        case 0: return AppColors.textTertiary
        case 1...6: return Color(hex: "#FFA500")
        case 7...13: return Color(hex: "#FF4500")
        case 14...29: return Color(hex: "#FF0000")
        default: return Color(hex: "#FFD700")
        }
    }

    private func startAnimations() {
        // Flickering animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isAnimating = true
        }

        // Generate particles for long streaks
        if streakCount >= 7 {
            generateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<6).map { i in
            let angle = Double(i) * 60.0
            let distance: CGFloat = 40
            return FlameParticle(
                x: cos(angle * .pi / 180) * distance,
                y: sin(angle * .pi / 180) * distance,
                size: CGFloat.random(in: 4...8),
                color: flameColor.opacity(0.6),
                opacity: 0.0
            )
        }

        // Animate particles
        withAnimation(.easeOut(duration: 1.5).repeatForever()) {
            particles = particles.map { particle in
                var p = particle
                p.opacity = 0.8
                return p
            }
        }
    }

    private struct FlameParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var color: Color
        var opacity: Double
    }
}

// MARK: - Preview Provider

#Preview("Streak Badges") {
    ScrollView {
        VStack(spacing: 32) {
            Text("Streak Badge Components")
                .font(.title2.bold())

            // Different sizes
            VStack(spacing: 16) {
                Text("Sizes")
                    .font(.headline)

                StreakBadge(streakCount: 5, size: .small)
                StreakBadge(streakCount: 5, size: .medium)
                StreakBadge(streakCount: 5, size: .large)
            }

            Divider()

            // Different streak lengths
            VStack(spacing: 16) {
                Text("Streak Progression")
                    .font(.headline)

                StreakBadge(streakCount: 0)
                StreakBadge(streakCount: 1)
                StreakBadge(streakCount: 3)
                StreakBadge(streakCount: 7)
                StreakBadge(streakCount: 14)
                StreakBadge(streakCount: 30)
            }

            Divider()

            // Without labels
            VStack(spacing: 16) {
                Text("Compact (No Labels)")
                    .font(.headline)

                HStack(spacing: 12) {
                    StreakBadge(streakCount: 3, showLabel: false)
                    StreakBadge(streakCount: 7, showLabel: false)
                    StreakBadge(streakCount: 14, showLabel: false)
                }
            }

            Divider()

            // Compact indicators
            VStack(spacing: 16) {
                Text("Compact Indicators")
                    .font(.headline)

                HStack(spacing: 16) {
                    CompactStreakIndicator(streakCount: 0)
                    CompactStreakIndicator(streakCount: 3)
                    CompactStreakIndicator(streakCount: 7)
                    CompactStreakIndicator(streakCount: 15)
                    CompactStreakIndicator(streakCount: 30)
                }
            }

            Divider()

            // Milestone display
            VStack(spacing: 16) {
                Text("Streak Milestones")
                    .font(.headline)

                StreakMilestone(streakCount: 5, milestone: 7)
                StreakMilestone(streakCount: 7, milestone: 7)
                StreakMilestone(streakCount: 22, milestone: 30)
            }
        }
        .padding()
    }
}

#Preview("Interactive Streak") {
    InteractiveStreakDemo()
}

private struct InteractiveStreakDemo: View {
    @State private var streakCount: Int = 0

    var body: some View {
        VStack(spacing: 32) {
            Text("Interactive Streak Demo")
                .font(.title2.bold())

            StreakMilestone(streakCount: streakCount, milestone: 30)

            StreakBadge(streakCount: streakCount, size: .large)

            HStack(spacing: 16) {
                Button("Reset") {
                    withAnimation {
                        streakCount = 0
                    }
                }
                .buttonStyle(.bordered)

                Button("-1") {
                    withAnimation {
                        streakCount = max(0, streakCount - 1)
                    }
                }
                .buttonStyle(.bordered)

                Button("+1") {
                    withAnimation {
                        streakCount += 1
                    }
                    if streakCount % 7 == 0 && streakCount > 0 {
                        HapticManager.shared.celebration(.gold)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("+7") {
                    withAnimation {
                        streakCount += 7
                    }
                }
                .buttonStyle(.bordered)
            }

            Text(streakMessage)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }

    private var streakMessage: String {
        switch streakCount {
        case 0:
            return "Start your streak today!"
        case 1:
            return "Great start! Keep it going!"
        case 2...6:
            return "You're building momentum!"
        case 7:
            return "🔥 One week streak! You're on fire!"
        case 8...13:
            return "Amazing consistency!"
        case 14:
            return "🔥🔥 Two week streak! Incredible!"
        case 15...29:
            return "You're unstoppable!"
        case 30:
            return "🏆 ONE MONTH STREAK! LEGENDARY!"
        default:
            return "🌟 You are a habit master!"
        }
    }
}
