//
//  PulseAnimation.swift
//  ADHDAssistant
//
//  Design System - Reusable Pulse Animation Modifiers
//

import SwiftUI

// MARK: - Pulse Animation Modifier

/// A reusable pulse animation modifier that can be applied to any view
struct PulseModifier: ViewModifier {
    var speed: Double = 1.0
    var minScale: CGFloat = 0.95
    var maxScale: CGFloat = 1.05
    var minOpacity: Double = 0.8
    var maxOpacity: Double = 1.0
    var isAnimating: Bool = true

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .opacity(isPulsing ? maxOpacity : minOpacity)
            .onAppear {
                guard isAnimating else { return }
                startPulsing()
            }
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    startPulsing()
                } else {
                    isPulsing = false
                }
            }
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

extension View {
    /// Applies a continuous pulse animation to the view
    func pulse(
        speed: Double = 1.0,
        minScale: CGFloat = 0.95,
        maxScale: CGFloat = 1.05,
        minOpacity: Double = 0.8,
        maxOpacity: Double = 1.0,
        isAnimating: Bool = true
    ) -> some View {
        modifier(PulseModifier(
            speed: speed,
            minScale: minScale,
            maxScale: maxScale,
            minOpacity: minOpacity,
            maxOpacity: maxOpacity,
            isAnimating: isAnimating
        ))
    }

    /// Applies a subtle pulse animation (minimal movement)
    func subtlePulse(isAnimating: Bool = true) -> some View {
        pulse(
            speed: 1.5,
            minScale: 0.98,
            maxScale: 1.02,
            minOpacity: 0.9,
            maxOpacity: 1.0,
            isAnimating: isAnimating
        )
    }

    /// Applies a strong pulse animation (more noticeable)
    func strongPulse(isAnimating: Bool = true) -> some View {
        pulse(
            speed: 0.8,
            minScale: 0.9,
            maxScale: 1.1,
            minOpacity: 0.7,
            maxOpacity: 1.0,
            isAnimating: isAnimating
        )
    }

    /// Applies a fast pulse animation
    func fastPulse(isAnimating: Bool = true) -> some View {
        pulse(
            speed: 0.5,
            minScale: 0.95,
            maxScale: 1.05,
            minOpacity: 0.85,
            maxOpacity: 1.0,
            isAnimating: isAnimating
        )
    }
}

// MARK: - Glow Pulse Modifier

/// A pulse animation that affects glow/shadow rather than scale
struct GlowPulseModifier: ViewModifier {
    var color: Color = .blue
    var minRadius: CGFloat = 5
    var maxRadius: CGFloat = 15
    var speed: Double = 1.0
    var isAnimating: Bool = true

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isPulsing ? 0.6 : 0.3),
                radius: isPulsing ? maxRadius : minRadius
            )
            .onAppear {
                guard isAnimating else { return }
                startPulsing()
            }
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    startPulsing()
                } else {
                    isPulsing = false
                }
            }
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}

extension View {
    /// Applies a pulsing glow effect to the view
    func glowPulse(
        color: Color = .blue,
        minRadius: CGFloat = 5,
        maxRadius: CGFloat = 15,
        speed: Double = 1.0,
        isAnimating: Bool = true
    ) -> some View {
        modifier(GlowPulseModifier(
            color: color,
            minRadius: minRadius,
            maxRadius: maxRadius,
            speed: speed,
            isAnimating: isAnimating
        ))
    }
}

// MARK: - Ring Pulse Modifier

/// A pulse animation that creates expanding rings around the view
struct RingPulseModifier: ViewModifier {
    var color: Color = .blue
    var ringCount: Int = 3
    var speed: Double = 2.0
    var isAnimating: Bool = true

    @State private var animationProgress: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack {
            // Pulse rings
            if isAnimating {
                ForEach(0..<ringCount, id: \.self) { index in
                    Circle()
                        .stroke(color.opacity(ringOpacity(for: index)), lineWidth: 2)
                        .scaleEffect(ringScale(for: index))
                }
            }

            // Original content
            content
        }
        .onAppear {
            guard isAnimating else { return }
            startPulsing()
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startPulsing()
            } else {
                animationProgress = 0
            }
        }
    }

    private func startPulsing() {
        withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
    }

    private func ringScale(for index: Int) -> CGFloat {
        let delay = Double(index) / Double(ringCount)
        let progress = (animationProgress + CGFloat(delay)).truncatingRemainder(dividingBy: 1.0)
        return 1.0 + progress * 0.5
    }

    private func ringOpacity(for index: Int) -> Double {
        let delay = Double(index) / Double(ringCount)
        let progress = (animationProgress + CGFloat(delay)).truncatingRemainder(dividingBy: 1.0)
        return Double(1.0 - progress)
    }
}

extension View {
    /// Applies expanding ring pulse animation
    func ringPulse(
        color: Color = .blue,
        ringCount: Int = 3,
        speed: Double = 2.0,
        isAnimating: Bool = true
    ) -> some View {
        modifier(RingPulseModifier(
            color: color,
            ringCount: ringCount,
            speed: speed,
            isAnimating: isAnimating
        ))
    }
}

// MARK: - Breath Animation

/// A breathing animation (smooth in and out)
struct BreathModifier: ViewModifier {
    var minScale: CGFloat = 0.9
    var maxScale: CGFloat = 1.0
    var duration: Double = 4.0
    var isAnimating: Bool = true

    @State private var isBreathing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? maxScale : minScale)
            .onAppear {
                guard isAnimating else { return }
                startBreathing()
            }
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    startBreathing()
                } else {
                    isBreathing = false
                }
            }
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }
}

extension View {
    /// Applies a gentle breathing animation (like meditation apps)
    func breath(
        minScale: CGFloat = 0.9,
        maxScale: CGFloat = 1.0,
        duration: Double = 4.0,
        isAnimating: Bool = true
    ) -> some View {
        modifier(BreathModifier(
            minScale: minScale,
            maxScale: maxScale,
            duration: duration,
            isAnimating: isAnimating
        ))
    }
}

// MARK: - Shimmer Effect

/// A shimmer/shine animation that sweeps across the view
struct ShimmerModifier: ViewModifier {
    var speed: Double = 2.0
    var angle: Double = 45
    var isAnimating: Bool = true

    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isAnimating {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.3), location: 0.5),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .rotationEffect(.degrees(angle))
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                        .blendMode(.overlay)
                    }
                }
            )
            .onAppear {
                guard isAnimating else { return }
                startShimmer()
            }
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    startShimmer()
                } else {
                    phase = 0
                }
            }
    }

    private func startShimmer() {
        withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
            phase = 1.0
        }
    }
}

extension View {
    /// Applies a shimmer effect that sweeps across the view
    func shimmer(
        speed: Double = 2.0,
        angle: Double = 45,
        isAnimating: Bool = true
    ) -> some View {
        modifier(ShimmerModifier(
            speed: speed,
            angle: angle,
            isAnimating: isAnimating
        ))
    }
}

// MARK: - Preview Provider

#Preview("Pulse Animations") {
    ScrollView {
        VStack(spacing: 40) {
            Text("Pulse Animation Modifiers")
                .font(.title2.bold())

            // Basic pulse
            VStack(spacing: 16) {
                Text("Basic Pulse")
                    .font(.headline)

                HStack(spacing: 20) {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 60, height: 60)
                        .subtlePulse()

                    Circle()
                        .fill(AppColors.secondary)
                        .frame(width: 60, height: 60)
                        .pulse()

                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 60, height: 60)
                        .strongPulse()
                }
            }

            Divider()

            // Glow pulse
            VStack(spacing: 16) {
                Text("Glow Pulse")
                    .font(.headline)

                HStack(spacing: 30) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.gold)
                        .glowPulse(color: AppColors.gold, maxRadius: 20)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .glowPulse(color: .orange, maxRadius: 25, speed: 0.8)
                }
            }

            Divider()

            // Ring pulse
            VStack(spacing: 16) {
                Text("Ring Pulse")
                    .font(.headline)

                HStack(spacing: 50) {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 40, height: 40)
                        .ringPulse(color: AppColors.success)

                    Circle()
                        .fill(AppColors.error)
                        .frame(width: 40, height: 40)
                        .ringPulse(color: AppColors.error, speed: 1.5)
                }
            }

            Divider()

            // Breath animation
            VStack(spacing: 16) {
                Text("Breath Animation")
                    .font(.headline)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .breath(duration: 3.0)
            }

            Divider()

            // Shimmer effect
            VStack(spacing: 16) {
                Text("Shimmer Effect")
                    .font(.headline)

                Text("Loading...")
                    .font(.title3.bold())
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shimmer(speed: 1.5)
            }

            Divider()

            // Combined effects
            VStack(spacing: 16) {
                Text("Combined Effects")
                    .font(.headline)

                ZStack {
                    Circle()
                        .fill(AppColors.gold)
                        .frame(width: 80, height: 80)
                        .ringPulse(color: AppColors.gold.opacity(0.5))

                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .pulse(minScale: 0.95, maxScale: 1.05)
                }
            }
        }
        .padding()
    }
}

#Preview("Interactive Pulse") {
    InteractivePulseDemo()
}

private struct InteractivePulseDemo: View {
    @State private var isAnimating = true
    @State private var selectedEffect = "Basic Pulse"

    let effects = [
        "Basic Pulse",
        "Subtle Pulse",
        "Strong Pulse",
        "Glow Pulse",
        "Ring Pulse",
        "Breath",
        "Shimmer"
    ]

    var body: some View {
        VStack(spacing: 32) {
            Text("Interactive Pulse Demo")
                .font(.title2.bold())

            // Demo view
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.card)
                    .frame(width: 200, height: 200)
                    .shadow(radius: 5)

                if selectedEffect == "Basic Pulse" {
                    Image(systemName: "star.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.gold)
                        .pulse(isAnimating: isAnimating)
                } else if selectedEffect == "Subtle Pulse" {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                        .subtlePulse(isAnimating: isAnimating)
                } else if selectedEffect == "Strong Pulse" {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.warning)
                        .strongPulse(isAnimating: isAnimating)
                } else if selectedEffect == "Glow Pulse" {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                        .glowPulse(color: .orange, maxRadius: 30, isAnimating: isAnimating)
                } else if selectedEffect == "Ring Pulse" {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 80, height: 80)
                        .ringPulse(color: AppColors.primary, isAnimating: isAnimating)
                } else if selectedEffect == "Breath" {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .breath(isAnimating: isAnimating)
                } else if selectedEffect == "Shimmer" {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.primary)
                        .frame(width: 150, height: 100)
                        .shimmer(isAnimating: isAnimating)
                }
            }

            // Controls
            VStack(spacing: 16) {
                Text("Effect Type")
                    .font(.headline)

                Picker("Effect", selection: $selectedEffect) {
                    ForEach(effects, id: \.self) { effect in
                        Text(effect).tag(effect)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Animate", isOn: $isAnimating)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}
