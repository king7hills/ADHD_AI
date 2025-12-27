//
//  ConfettiAnimation.swift
//  ADHDAssistant
//
//  Design System - Confetti Particle Animation
//

import SwiftUI

/// Confetti particle animation for celebrations
struct ConfettiView: View {
    var style: ConfettiStyle = .standard
    var duration: Double = 3.0
    var onComplete: (() -> Void)?

    @State private var particles: [ConfettiParticle] = []
    @State private var isActive = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiPiece(particle: particle)
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }

    private func generateParticles() {
        let count = style.particleCount
        particles = (0..<count).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: -20...UIScreen.main.bounds.width + 20),
                y: -50,
                color: style.colors.randomElement() ?? .blue,
                size: CGFloat.random(in: style.sizeRange),
                shape: ConfettiShape.allCases.randomElement() ?? .circle,
                rotation: Double.random(in: 0...360),
                velocityX: CGFloat.random(in: -50...50),
                velocityY: CGFloat.random(in: 100...300),
                angularVelocity: Double.random(in: -360...360)
            )
        }
    }

    private func startAnimation() {
        isActive = true

        // Animate each particle
        for (index, _) in particles.enumerated() {
            let delay = Double.random(in: 0...0.3)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: duration)) {
                    particles[index].y = UIScreen.main.bounds.height + 100
                    particles[index].x += particles[index].velocityX * 0.5
                    particles[index].rotation += particles[index].angularVelocity * duration
                    particles[index].opacity = 0
                }
            }
        }

        // Complete callback
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            onComplete?()
        }
    }

    enum ConfettiStyle {
        case standard
        case celebration
        case achievement
        case rainbow

        var particleCount: Int {
            switch self {
            case .standard: return 30
            case .celebration: return 50
            case .achievement: return 40
            case .rainbow: return 60
            }
        }

        var colors: [Color] {
            switch self {
            case .standard:
                return [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.accent,
                    AppColors.success
                ]
            case .celebration:
                return [
                    Color(hex: "#FF6B6B"),
                    Color(hex: "#4ECDC4"),
                    Color(hex: "#45B7D1"),
                    Color(hex: "#FFA07A"),
                    Color(hex: "#98D8C8"),
                    Color(hex: "#FFD93D")
                ]
            case .achievement:
                return [
                    AppColors.gold,
                    Color(hex: "#FFD700"),
                    Color(hex: "#FFA500"),
                    Color(hex: "#FF8C00")
                ]
            case .rainbow:
                return [
                    Color(hex: "#FF0000"),
                    Color(hex: "#FF7F00"),
                    Color(hex: "#FFFF00"),
                    Color(hex: "#00FF00"),
                    Color(hex: "#0000FF"),
                    Color(hex: "#4B0082"),
                    Color(hex: "#9400D3")
                ]
            }
        }

        var sizeRange: ClosedRange<CGFloat> {
            switch self {
            case .standard: return 6...12
            case .celebration: return 8...16
            case .achievement: return 10...20
            case .rainbow: return 6...14
            }
        }
    }
}

// MARK: - Confetti Particle Model

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var shape: ConfettiShape
    var rotation: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
    var angularVelocity: Double
    var opacity: Double = 1.0
}

enum ConfettiShape: CaseIterable {
    case circle
    case square
    case triangle
    case star
    case heart

    @ViewBuilder
    func view(size: CGFloat, color: Color) -> some View {
        switch self {
        case .circle:
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        case .square:
            Rectangle()
                .fill(color)
                .frame(width: size, height: size)
        case .triangle:
            Triangle()
                .fill(color)
                .frame(width: size, height: size)
        case .star:
            Star()
                .fill(color)
                .frame(width: size, height: size)
        case .heart:
            Heart()
                .fill(color)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Confetti Piece View

private struct ConfettiPiece: View {
    let particle: ConfettiParticle

    var body: some View {
        particle.shape.view(size: particle.size, color: particle.color)
            .rotationEffect(.degrees(particle.rotation))
            .opacity(particle.opacity)
            .position(x: particle.x, y: particle.y)
    }
}

// MARK: - Custom Shapes

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4

        for i in 0..<5 {
            let angle = Double(i) * (2 * .pi / 5) - .pi / 2
            let outerPoint = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )

            let innerAngle = angle + .pi / 5
            let innerPoint = CGPoint(
                x: center.x + innerRadius * cos(innerAngle),
                y: center.y + innerRadius * sin(innerAngle)
            )

            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint)
        }
        path.closeSubpath()
        return path
    }
}

private struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height * 0.3))

        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.25),
            control1: CGPoint(x: width * 0.5, y: 0),
            control2: CGPoint(x: 0, y: height * 0.1)
        )

        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: 0, y: height * 0.5),
            control2: CGPoint(x: width * 0.5, y: height * 0.75)
        )

        path.addCurve(
            to: CGPoint(x: width, y: height * 0.25),
            control1: CGPoint(x: width * 0.5, y: height * 0.75),
            control2: CGPoint(x: width, y: height * 0.5)
        )

        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.3),
            control1: CGPoint(x: width, y: height * 0.1),
            control2: CGPoint(x: width * 0.5, y: 0)
        )

        return path
    }
}

// MARK: - Confetti Cannon (Bottom-up burst)

struct ConfettiCannon: View {
    var style: ConfettiView.ConfettiStyle = .celebration
    var onComplete: (() -> Void)?

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiPiece(particle: particle)
            }
        }
        .onAppear {
            generateCannonParticles()
            startCannonAnimation()
        }
    }

    private func generateCannonParticles() {
        let count = style.particleCount
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        particles = (0..<count).map { _ in
            let angle = Double.random(in: -45...45) * (.pi / 180)
            let velocity = CGFloat.random(in: 300...600)

            return ConfettiParticle(
                x: screenWidth / 2,
                y: screenHeight,
                color: style.colors.randomElement() ?? .blue,
                size: CGFloat.random(in: style.sizeRange),
                shape: ConfettiShape.allCases.randomElement() ?? .circle,
                rotation: Double.random(in: 0...360),
                velocityX: sin(angle) * velocity,
                velocityY: -cos(angle) * velocity,
                angularVelocity: Double.random(in: -720...720)
            )
        }
    }

    private func startCannonAnimation() {
        for (index, _) in particles.enumerated() {
            let duration = Double.random(in: 1.5...2.5)

            withAnimation(.easeOut(duration: duration)) {
                particles[index].x += particles[index].velocityX * 0.01 * CGFloat(duration * 100)
                particles[index].y += particles[index].velocityY * 0.01 * CGFloat(duration * 100)
                particles[index].rotation += particles[index].angularVelocity * duration
                particles[index].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete?()
        }
    }
}

// MARK: - Preview Provider

#Preview("Confetti Styles") {
    ZStack {
        AppColors.background
            .ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Confetti Animations")
                .font(.title.bold())
                .foregroundColor(AppColors.textPrimary)

            Text("Animations will auto-play")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }

        ConfettiView(style: .rainbow, duration: 4.0)
    }
}

#Preview("Confetti Cannon") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            Spacer()
            Text("🎉")
                .font(.system(size: 80))
            Spacer()
        }

        ConfettiCannon(style: .celebration)
    }
}

#Preview("Interactive Confetti") {
    InteractiveConfettiDemo()
}

private struct InteractiveConfettiDemo: View {
    @State private var showConfetti = false
    @State private var selectedStyle: ConfettiView.ConfettiStyle = .standard

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Text("Interactive Confetti")
                    .font(.title2.bold())

                Text("Select a style:")
                    .font(.headline)

                VStack(spacing: 12) {
                    Button("Standard") {
                        selectedStyle = .standard
                        triggerConfetti()
                    }
                    .buttonStyle(.bordered)

                    Button("Celebration") {
                        selectedStyle = .celebration
                        triggerConfetti()
                    }
                    .buttonStyle(.bordered)

                    Button("Achievement") {
                        selectedStyle = .achievement
                        triggerConfetti()
                    }
                    .buttonStyle(.bordered)

                    Button("Rainbow") {
                        selectedStyle = .rainbow
                        triggerConfetti()
                    }
                    .buttonStyle(.bordered)

                    Button("Cannon 🎊") {
                        selectedStyle = .celebration
                        triggerCannon()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            if showConfetti {
                if selectedStyle == .celebration {
                    ConfettiCannon(style: selectedStyle) {
                        showConfetti = false
                    }
                } else {
                    ConfettiView(style: selectedStyle) {
                        showConfetti = false
                    }
                }
            }
        }
    }

    private func triggerConfetti() {
        showConfetti = true
        HapticManager.shared.celebration(.gold)
    }

    private func triggerCannon() {
        showConfetti = true
        HapticManager.shared.celebration(.gold)
    }
}
