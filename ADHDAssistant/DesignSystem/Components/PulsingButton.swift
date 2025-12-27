//
//  PulsingButton.swift
//  ADHDAssistant
//
//  Design System - Pulsing Done Button Component
//

import SwiftUI

/// A dynamic button that pulses when not completed and celebrates when marked as done
struct PulsingButton: View {
    @Binding var isCompleted: Bool

    var size: ButtonSize = .medium
    var primaryColor: Color = AppColors.primary
    var completedColor: Color = AppColors.success
    var onCelebrate: (() -> Void)?

    @State private var isPulsing = false
    @State private var isPressed = false
    @State private var showCheckmark = false

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isCompleted ? completedColor : primaryColor)
                    .frame(width: size.diameter, height: size.diameter)
                    .opacity(isPressed ? 0.8 : 1.0)

                // Glow effect when not completed
                if !isCompleted {
                    Circle()
                        .fill(primaryColor.opacity(0.3))
                        .frame(width: size.diameter, height: size.diameter)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0 : 0.6)
                }

                // Icon
                Group {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: size.iconSize, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCheckmark ? 1.0 : 0.5)
                            .opacity(showCheckmark ? 1.0 : 0)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: size.iconSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCompleted)
            .animation(.easeInOut(duration: 0.3), value: showCheckmark)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isCompleted ? "Task completed" : "Mark task as complete")
        .accessibilityHint(isCompleted ? "Tap to mark as incomplete" : "Tap to complete task")
        .accessibilityAddTraits(isCompleted ? .isSelected : [])
        .onAppear {
            startPulsing()
        }
        .onChange(of: isCompleted) { _, newValue in
            if newValue {
                showCheckmark = true
            } else {
                showCheckmark = false
                startPulsing()
            }
        }
    }

    private func handleTap() {
        // Haptic feedback
        if !isCompleted {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.impact(.light)
        }

        // Press animation
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }

        // Toggle completion
        withAnimation {
            isCompleted.toggle()
        }

        // Trigger celebration if completed
        if isCompleted {
            onCelebrate?()
        }
    }

    private func startPulsing() {
        guard !isCompleted else {
            isPulsing = false
            return
        }

        isPulsing = false
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }

    enum ButtonSize {
        case small
        case medium
        case large

        var diameter: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
    }
}

/// Alternative done button with circle fill animation
struct DoneButton: View {
    @Binding var isCompleted: Bool

    var style: DoneButtonStyle = .default
    var onCelebrate: (() -> Void)?

    @State private var isPulsing = false
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(
                        isCompleted ? style.completedColor : style.primaryColor,
                        lineWidth: style.lineWidth
                    )
                    .frame(width: style.size, height: style.size)

                // Inner fill
                if isCompleted {
                    Circle()
                        .fill(style.completedColor)
                        .frame(width: style.size - style.lineWidth * 2, height: style.size - style.lineWidth * 2)
                        .transition(.scale.combined(with: .opacity))
                }

                // Checkmark
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: style.iconSize, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }

                // Pulse ring when not completed
                if !isCompleted && isPulsing {
                    Circle()
                        .strokeBorder(
                            style.primaryColor.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: style.size, height: style.size)
                        .scaleEffect(scale)
                        .opacity(2 - scale)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isCompleted ? "Task completed" : "Mark task as complete")
        .onAppear {
            startPulsing()
        }
        .onChange(of: isCompleted) { _, newValue in
            if !newValue {
                startPulsing()
            }
        }
    }

    private func handleTap() {
        if !isCompleted {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isCompleted = true
            }
            onCelebrate?()
        } else {
            HapticManager.shared.impact(.light)
            withAnimation(.easeInOut(duration: 0.2)) {
                isCompleted = false
            }
        }
    }

    private func startPulsing() {
        guard !isCompleted else { return }

        scale = 1.0
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            scale = 1.8
        }
        isPulsing = true
    }

    struct DoneButtonStyle {
        var size: CGFloat
        var lineWidth: CGFloat
        var iconSize: CGFloat
        var primaryColor: Color
        var completedColor: Color

        static let `default` = DoneButtonStyle(
            size: 44,
            lineWidth: 3,
            iconSize: 20,
            primaryColor: AppColors.primary,
            completedColor: AppColors.success
        )

        static let small = DoneButtonStyle(
            size: 32,
            lineWidth: 2,
            iconSize: 14,
            primaryColor: AppColors.primary,
            completedColor: AppColors.success
        )

        static let large = DoneButtonStyle(
            size: 56,
            lineWidth: 4,
            iconSize: 26,
            primaryColor: AppColors.primary,
            completedColor: AppColors.success
        )
    }
}

// MARK: - Preview Provider

#Preview("Pulsing Button") {
    VStack(spacing: 40) {
        Text("Pulsing Button Styles")
            .font(.title2.bold())

        // Different sizes
        HStack(spacing: 30) {
            VStack(spacing: 8) {
                PulsingButton(isCompleted: .constant(false), size: .small)
                Text("Small")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                PulsingButton(isCompleted: .constant(false), size: .medium)
                Text("Medium")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                PulsingButton(isCompleted: .constant(false), size: .large)
                Text("Large")
                    .font(.caption)
            }
        }

        Divider()

        // States
        HStack(spacing: 30) {
            VStack(spacing: 8) {
                PulsingButton(
                    isCompleted: .constant(false),
                    onCelebrate: { print("Celebrate!") }
                )
                Text("Not Complete")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                PulsingButton(
                    isCompleted: .constant(true),
                    onCelebrate: { print("Celebrate!") }
                )
                Text("Completed")
                    .font(.caption)
            }
        }

        Divider()

        Text("Done Button Styles")
            .font(.title2.bold())

        HStack(spacing: 30) {
            VStack(spacing: 8) {
                DoneButton(isCompleted: .constant(false), style: .small)
                Text("Small")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                DoneButton(isCompleted: .constant(false))
                Text("Default")
                    .font(.caption)
            }

            VStack(spacing: 8) {
                DoneButton(isCompleted: .constant(false), style: .large)
                Text("Large")
                    .font(.caption)
            }
        }

        HStack(spacing: 30) {
            VStack(spacing: 8) {
                DoneButton(isCompleted: .constant(true))
                Text("Completed")
                    .font(.caption)
            }
        }
    }
    .padding()
}

#Preview("Interactive Demo") {
    InteractivePulsingButtonDemo()
}

private struct InteractivePulsingButtonDemo: View {
    @State private var isCompleted1 = false
    @State private var isCompleted2 = false
    @State private var showCelebration = false

    var body: some View {
        VStack(spacing: 40) {
            Text("Tap to Toggle")
                .font(.title2.bold())

            PulsingButton(
                isCompleted: $isCompleted1,
                size: .large,
                onCelebrate: {
                    showCelebration = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showCelebration = false
                    }
                }
            )

            if showCelebration {
                Text("🎉 Completed!")
                    .font(.headline)
                    .foregroundColor(AppColors.success)
                    .transition(.scale.combined(with: .opacity))
            }

            Divider()

            DoneButton(
                isCompleted: $isCompleted2,
                style: .large,
                onCelebrate: {
                    print("Task completed!")
                }
            )

            Text(isCompleted2 ? "Task Complete!" : "Task Pending")
                .font(.subheadline)
                .foregroundColor(isCompleted2 ? AppColors.success : AppColors.textSecondary)
        }
        .padding()
        .animation(.spring(), value: showCelebration)
    }
}
