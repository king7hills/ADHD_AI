//
//  ProgressRing.swift
//  ADHDAssistant
//
//  Design System - Circular Progress Ring Component
//

import SwiftUI

/// A circular progress indicator with customizable appearance and optional center content
struct ProgressRing: View {
    var progress: Double // 0.0 to 1.0
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var ringColor: Color = AppColors.primary
    var backgroundColor: Color = AppColors.divider
    var showPercentage: Bool = true
    var centerIcon: String? = nil
    var isIndeterminate: Bool = false

    @State private var animatedProgress: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    backgroundColor,
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)

            if isIndeterminate {
                // Indeterminate progress
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            } else {
                // Determinate progress
                Circle()
                    .trim(from: 0, to: min(animatedProgress, 1.0))
                    .stroke(
                        ringColor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
            }

            // Center content
            if !isIndeterminate {
                centerContent
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int(progress * 100))%")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }

    @ViewBuilder
    private var centerContent: some View {
        VStack(spacing: 4) {
            if let icon = centerIcon {
                Image(systemName: icon)
                    .font(.system(size: size * 0.25, weight: .medium))
                    .foregroundColor(ringColor)
            }

            if showPercentage {
                Text("\(Int(animatedProgress * 100))")
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .monospacedDigit()

                if centerIcon == nil {
                    Text("%")
                        .font(.system(size: size * 0.12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

/// A gradient progress ring with multiple colors
struct GradientProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var gradientColors: [Color] = [AppColors.primary, AppColors.accent]
    var backgroundColor: Color = AppColors.divider
    var showPercentage: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    backgroundColor,
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center content
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .monospacedDigit()

                    Text("%")
                        .font(.system(size: size * 0.1, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

/// Multi-segment progress ring for tracking multiple goals
struct MultiSegmentProgressRing: View {
    var segments: [ProgressSegment]
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var backgroundColor: Color = AppColors.divider
    var spacing: CGFloat = 2

    struct ProgressSegment: Identifiable {
        let id = UUID()
        let progress: Double
        let color: Color
        let label: String?
    }

    @State private var animatedSegments: [Double] = []

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    backgroundColor,
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)

            // Draw each segment
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                Circle()
                    .trim(
                        from: startAngle(for: index),
                        to: endAngle(for: index)
                    )
                    .stroke(
                        segment.color,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
            }

            // Center total percentage
            VStack(spacing: 2) {
                Text("\(Int(totalProgress * 100))")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .monospacedDigit()

                Text("total")
                    .font(.system(size: size * 0.08, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .onAppear {
            animatedSegments = Array(repeating: 0, count: segments.count)
            withAnimation(.easeOut(duration: 0.8)) {
                animatedSegments = segments.map { $0.progress }
            }
        }
    }

    private var totalProgress: Double {
        let animated = animatedSegments.isEmpty ? segments.map { $0.progress } : animatedSegments
        return animated.reduce(0, +) / Double(max(segments.count, 1))
    }

    private func startAngle(for index: Int) -> Double {
        let segmentSize = 1.0 / Double(segments.count)
        let gapSize = spacing / (CGFloat.pi * size)
        return Double(index) * segmentSize + (index == 0 ? 0 : Double(gapSize))
    }

    private func endAngle(for index: Int) -> Double {
        let segmentSize = 1.0 / Double(segments.count)
        let progress = index < animatedSegments.count ? animatedSegments[index] : segments[index].progress
        let gapSize = spacing / (CGFloat.pi * size)
        return Double(index) * segmentSize + (segmentSize * progress) - Double(gapSize)
    }
}

// MARK: - Preview Provider

#Preview("Progress Ring Styles") {
    ScrollView {
        VStack(spacing: 40) {
            Text("Progress Ring Components")
                .font(.title2.bold())

            // Basic progress rings
            VStack(spacing: 20) {
                Text("Basic Progress Rings")
                    .font(.headline)

                HStack(spacing: 30) {
                    VStack(spacing: 8) {
                        ProgressRing(progress: 0.25, size: 100)
                        Text("25%")
                            .font(.caption)
                    }

                    VStack(spacing: 8) {
                        ProgressRing(progress: 0.50, size: 100)
                        Text("50%")
                            .font(.caption)
                    }

                    VStack(spacing: 8) {
                        ProgressRing(progress: 0.75, size: 100)
                        Text("75%")
                            .font(.caption)
                    }
                }
            }

            Divider()

            // Progress rings with icons
            VStack(spacing: 20) {
                Text("With Icons")
                    .font(.headline)

                HStack(spacing: 30) {
                    ProgressRing(
                        progress: 0.65,
                        size: 100,
                        ringColor: AppColors.success,
                        centerIcon: "checkmark.circle.fill"
                    )

                    ProgressRing(
                        progress: 0.30,
                        size: 100,
                        ringColor: AppColors.warning,
                        centerIcon: "flame.fill"
                    )

                    ProgressRing(
                        progress: 0.85,
                        size: 100,
                        ringColor: AppColors.primary,
                        centerIcon: "star.fill"
                    )
                }
            }

            Divider()

            // Gradient progress rings
            VStack(spacing: 20) {
                Text("Gradient Progress Rings")
                    .font(.headline)

                HStack(spacing: 30) {
                    GradientProgressRing(
                        progress: 0.40,
                        size: 100,
                        gradientColors: [AppColors.primary, AppColors.secondary]
                    )

                    GradientProgressRing(
                        progress: 0.70,
                        size: 100,
                        gradientColors: [AppColors.warning, AppColors.error]
                    )
                }
            }

            Divider()

            // Indeterminate
            VStack(spacing: 20) {
                Text("Indeterminate")
                    .font(.headline)

                ProgressRing(
                    progress: 0,
                    size: 100,
                    isIndeterminate: true
                )
            }

            Divider()

            // Multi-segment
            VStack(spacing: 20) {
                Text("Multi-Segment Ring")
                    .font(.headline)

                MultiSegmentProgressRing(
                    segments: [
                        .init(progress: 0.8, color: AppColors.success, label: "Tasks"),
                        .init(progress: 0.6, color: AppColors.primary, label: "Goals"),
                        .init(progress: 0.4, color: AppColors.warning, label: "Habits")
                    ],
                    size: 120
                )

                HStack(spacing: 16) {
                    LegendItem(color: AppColors.success, label: "Tasks (80%)")
                    LegendItem(color: AppColors.primary, label: "Goals (60%)")
                    LegendItem(color: AppColors.warning, label: "Habits (40%)")
                }
            }

            // Different sizes
            VStack(spacing: 20) {
                Text("Different Sizes")
                    .font(.headline)

                HStack(spacing: 20) {
                    ProgressRing(progress: 0.6, lineWidth: 6, size: 60)
                    ProgressRing(progress: 0.6, lineWidth: 8, size: 80)
                    ProgressRing(progress: 0.6, lineWidth: 10, size: 100)
                    ProgressRing(progress: 0.6, lineWidth: 12, size: 120)
                }
            }
        }
        .padding()
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview("Interactive Demo") {
    InteractiveProgressRingDemo()
}

private struct InteractiveProgressRingDemo: View {
    @State private var progress: Double = 0.0

    var body: some View {
        VStack(spacing: 40) {
            ProgressRing(
                progress: progress,
                lineWidth: 16,
                size: 200,
                ringColor: progressColor
            )

            VStack(spacing: 12) {
                Text("Progress: \(Int(progress * 100))%")
                    .font(.headline)

                Slider(value: $progress, in: 0...1)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("0%") { withAnimation { progress = 0.0 } }
                    Button("25%") { withAnimation { progress = 0.25 } }
                    Button("50%") { withAnimation { progress = 0.50 } }
                    Button("75%") { withAnimation { progress = 0.75 } }
                    Button("100%") { withAnimation { progress = 1.0 } }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var progressColor: Color {
        if progress < 0.33 {
            return AppColors.error
        } else if progress < 0.66 {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }
}
