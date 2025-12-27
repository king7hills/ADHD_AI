//
//  TimerDisplay.swift
//  ADHDAssistant
//
//  Design System - Timer Display Component
//

import SwiftUI

/// A large, readable timer display with color-coded states and animations
struct TimerDisplay: View {
    var seconds: Int
    var totalSeconds: Int
    var style: TimerStyle = .countdown
    var size: DisplaySize = .medium
    var showProgress: Bool = false

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: size.spacing) {
            // Timer text
            Text(formattedTime)
                .font(size.font)
                .foregroundColor(timerColor)
                .monospacedDigit()
                .scaleEffect(isPulsing ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPulsing)

            // Optional progress bar
            if showProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.divider)
                            .frame(height: 8)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(timerColor)
                            .frame(width: geometry.size.width * progressPercentage, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Time status label
            if style == .countdown {
                Text(timeStatusLabel)
                    .font(size.labelFont)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .onAppear {
            updatePulseState()
        }
        .onChange(of: seconds) { _, _ in
            updatePulseState()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Computed Properties

    private var formattedTime: String {
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60
        let secs = absoluteSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private var timerColor: Color {
        if seconds < 0 {
            // Overtime
            return AppColors.error
        } else if totalSeconds > 0 {
            let percentage = Double(seconds) / Double(totalSeconds)
            if percentage > 0.5 {
                return AppColors.success
            } else if percentage > 0.2 {
                return AppColors.warning
            } else {
                return AppColors.error
            }
        } else {
            return AppColors.primary
        }
    }

    private var progressPercentage: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        let percentage = Double(seconds) / Double(totalSeconds)
        return max(0, min(1, CGFloat(percentage)))
    }

    private var timeStatusLabel: String {
        if seconds < 0 {
            return "Overtime"
        } else if seconds < 60 {
            return "Finishing soon"
        } else if seconds < 300 {
            return "Less than 5 minutes"
        } else {
            return "Time remaining"
        }
    }

    private var accessibilityLabel: String {
        let timeString = formattedTime
        if seconds < 0 {
            return "Overtime: \(timeString)"
        } else {
            return "Time remaining: \(timeString)"
        }
    }

    private func updatePulseState() {
        if seconds < 0 {
            // Pulse when overtime
            isPulsing = true
        } else if totalSeconds > 0 && Double(seconds) / Double(totalSeconds) < 0.1 {
            // Pulse when less than 10% time remaining
            isPulsing = true
        } else {
            isPulsing = false
        }
    }

    // MARK: - Types

    enum TimerStyle {
        case countdown
        case countup
    }

    enum DisplaySize {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small: return AppTypography.timerDisplay
            case .medium: return Font.system(size: 48, weight: .semibold, design: .rounded).monospacedDigit()
            case .large: return AppTypography.timerDisplayLarge
            }
        }

        var labelFont: Font {
            switch self {
            case .small: return AppTypography.caption
            case .medium: return AppTypography.subheadline
            case .large: return AppTypography.callout
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return AppSpacing.xs
            case .medium: return AppSpacing.sm
            case .large: return AppSpacing.md
            }
        }
    }
}

/// Compact timer display for list items
struct CompactTimerDisplay: View {
    var seconds: Int
    var showIcon: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(timerColor)
            }

            Text(formattedTime)
                .font(AppTypography.footnote)
                .foregroundColor(timerColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(timerColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var formattedTime: String {
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60
        let secs = absoluteSeconds % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }

    private var timerColor: Color {
        if seconds < 0 {
            return AppColors.error
        } else if seconds < 60 {
            return AppColors.warning
        } else {
            return AppColors.primary
        }
    }
}

/// Circular timer display with progress ring
struct CircularTimerDisplay: View {
    var seconds: Int
    var totalSeconds: Int
    var size: CGFloat = 200
    var lineWidth: CGFloat = 12

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(AppColors.divider, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: progressPercentage)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center time display
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .monospacedDigit()
                    .scaleEffect(isPulsing ? 1.05 : 1.0)

                if seconds >= 0 {
                    Text("remaining")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("overtime")
                        .font(.system(size: size * 0.08, weight: .semibold))
                        .foregroundColor(AppColors.error)
                }
            }
        }
        .onAppear {
            updatePulseState()
        }
        .onChange(of: seconds) { _, _ in
            updatePulseState()
        }
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPulsing)
    }

    private var formattedTime: String {
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60
        let secs = absoluteSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private var progressPercentage: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        let percentage = Double(max(0, seconds)) / Double(totalSeconds)
        return max(0, min(1, CGFloat(percentage)))
    }

    private var timerColor: Color {
        if seconds < 0 {
            return AppColors.error
        } else if totalSeconds > 0 {
            let percentage = Double(seconds) / Double(totalSeconds)
            if percentage > 0.5 {
                return AppColors.success
            } else if percentage > 0.2 {
                return AppColors.warning
            } else {
                return AppColors.error
            }
        } else {
            return AppColors.primary
        }
    }

    private func updatePulseState() {
        if seconds < 0 || (totalSeconds > 0 && Double(seconds) / Double(totalSeconds) < 0.1) {
            isPulsing = true
        } else {
            isPulsing = false
        }
    }
}

// MARK: - Preview Provider

#Preview("Timer Displays") {
    ScrollView {
        VStack(spacing: 32) {
            Text("Timer Display Components")
                .font(.title2.bold())

            // Standard timer displays
            VStack(spacing: 20) {
                Text("Standard Sizes")
                    .font(.headline)

                TimerDisplay(seconds: 1500, totalSeconds: 1500, size: .small)
                TimerDisplay(seconds: 750, totalSeconds: 1500, size: .medium)
                TimerDisplay(seconds: 150, totalSeconds: 1500, size: .large, showProgress: true)
            }

            Divider()

            // Different time states
            VStack(spacing: 20) {
                Text("Different States")
                    .font(.headline)

                VStack(spacing: 16) {
                    TimerDisplay(seconds: 1800, totalSeconds: 1800, showProgress: true)
                    Text("Plenty of time (green)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)

                    TimerDisplay(seconds: 450, totalSeconds: 1800, showProgress: true)
                    Text("Getting low (yellow)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)

                    TimerDisplay(seconds: 90, totalSeconds: 1800, showProgress: true)
                    Text("Almost done (red)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)

                    TimerDisplay(seconds: -30, totalSeconds: 1800, showProgress: true)
                    Text("Overtime (red + pulsing)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Divider()

            // Compact displays
            VStack(spacing: 20) {
                Text("Compact Timer")
                    .font(.headline)

                VStack(spacing: 12) {
                    CompactTimerDisplay(seconds: 3665)
                    CompactTimerDisplay(seconds: 125)
                    CompactTimerDisplay(seconds: 30)
                    CompactTimerDisplay(seconds: -15)
                }
            }

            Divider()

            // Circular timer
            VStack(spacing: 20) {
                Text("Circular Timer")
                    .font(.headline)

                HStack(spacing: 24) {
                    CircularTimerDisplay(seconds: 1200, totalSeconds: 1500, size: 140, lineWidth: 10)
                    CircularTimerDisplay(seconds: 300, totalSeconds: 1500, size: 140, lineWidth: 10)
                }

                CircularTimerDisplay(seconds: -30, totalSeconds: 1500, size: 160, lineWidth: 12)
            }
        }
        .padding()
    }
}

#Preview("Interactive Timer") {
    InteractiveTimerDemo()
}

private struct InteractiveTimerDemo: View {
    @State private var seconds: Int = 1500
    @State private var isRunning = false
    let totalSeconds = 1500

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 32) {
            Text("Interactive Timer Demo")
                .font(.title2.bold())

            CircularTimerDisplay(
                seconds: seconds,
                totalSeconds: totalSeconds,
                size: 220,
                lineWidth: 14
            )

            TimerDisplay(
                seconds: seconds,
                totalSeconds: totalSeconds,
                size: .large,
                showProgress: true
            )

            HStack(spacing: 16) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    seconds = totalSeconds
                    isRunning = false
                }
                .buttonStyle(.bordered)

                Button("-5 min") {
                    seconds = max(-300, seconds - 300)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onReceive(timer) { _ in
            if isRunning && seconds > -300 {
                seconds -= 1
            }
        }
    }
}
