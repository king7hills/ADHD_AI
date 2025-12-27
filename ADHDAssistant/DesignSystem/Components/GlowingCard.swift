//
//  GlowingCard.swift
//  ADHDAssistant
//
//  Design System - Card Component with Glow Effect
//

import SwiftUI

/// A card container with subtle glow effect based on priority or state
struct GlowingCard<Content: View>: View {
    var glowColor: Color = AppColors.primary
    var glowIntensity: GlowIntensity = .medium
    var cornerRadius: CGFloat = AppSpacing.cornerRadiusMedium
    var padding: CGFloat = AppSpacing.cardPadding
    var backgroundColor: Color = AppColors.card
    var isPressed: Bool = false
    @ViewBuilder let content: Content

    @State private var isAnimating = false

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: glowColor.opacity(glowIntensity.shadowOpacity),
                radius: glowIntensity.shadowRadius,
                x: 0,
                y: 2
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    enum GlowIntensity {
        case none
        case subtle
        case medium
        case strong

        var shadowOpacity: Double {
            switch self {
            case .none: return 0
            case .subtle: return 0.15
            case .medium: return 0.25
            case .strong: return 0.4
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .none: return 0
            case .subtle: return 8
            case .medium: return 12
            case .strong: return 20
            }
        }
    }
}

/// Interactive card with press state and tap handling
struct InteractiveCard<Content: View>: View {
    var glowColor: Color = AppColors.primary
    var glowIntensity: GlowingCard<Content>.GlowIntensity = .medium
    var cornerRadius: CGFloat = AppSpacing.cornerRadiusMedium
    var padding: CGFloat = AppSpacing.cardPadding
    var backgroundColor: Color = AppColors.card
    var onTap: (() -> Void)?
    @ViewBuilder let content: Content

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            onTap?()
        }) {
            GlowingCard(
                glowColor: glowColor,
                glowIntensity: glowIntensity,
                cornerRadius: cornerRadius,
                padding: padding,
                backgroundColor: backgroundColor,
                isPressed: isPressed,
                content: { content }
            )
        }
        .buttonStyle(PressButtonStyle(isPressed: $isPressed))
    }
}

/// Priority-based card with automatic color selection
struct PriorityCard<Content: View>: View {
    var priority: Priority = .medium
    var cornerRadius: CGFloat = AppSpacing.cornerRadiusMedium
    var padding: CGFloat = AppSpacing.cardPadding
    var showPriorityBadge: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showPriorityBadge {
                HStack {
                    Spacer()
                    PriorityBadge(priority: priority)
                }
                .padding(.bottom, AppSpacing.sm)
            }

            content
        }
        .padding(padding)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(priority.color.opacity(0.3), lineWidth: priority == .high ? 2 : 1)
        )
        .shadow(
            color: priority.color.opacity(priority.glowOpacity),
            radius: priority.glowRadius,
            x: 0,
            y: 2
        )
    }

    enum Priority {
        case low
        case medium
        case high
        case urgent

        var color: Color {
            switch self {
            case .low: return AppColors.info
            case .medium: return AppColors.primary
            case .high: return AppColors.warning
            case .urgent: return AppColors.error
            }
        }

        var glowOpacity: Double {
            switch self {
            case .low: return 0.1
            case .medium: return 0.2
            case .high: return 0.3
            case .urgent: return 0.4
            }
        }

        var glowRadius: CGFloat {
            switch self {
            case .low: return 6
            case .medium: return 10
            case .high: return 14
            case .urgent: return 18
            }
        }

        var label: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
    }
}

/// Animated pulsing card for attention-grabbing
struct PulsingCard<Content: View>: View {
    var glowColor: Color = AppColors.primary
    var cornerRadius: CGFloat = AppSpacing.cornerRadiusMedium
    var padding: CGFloat = AppSpacing.cardPadding
    var pulseSpeed: Double = 2.0
    @ViewBuilder let content: Content

    @State private var isPulsing = false

    var body: some View {
        content
            .padding(padding)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: glowColor.opacity(isPulsing ? 0.4 : 0.2),
                radius: isPulsing ? 16 : 8,
                x: 0,
                y: 2
            )
            .onAppear {
                withAnimation(.easeInOut(duration: pulseSpeed).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Supporting Views

private struct PriorityBadge: View {
    let priority: PriorityCard<AnyView>.Priority

    var body: some View {
        Text(priority.label)
            .font(AppTypography.badgeText)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color)
            .clipShape(Capsule())
    }
}

// MARK: - Button Styles

private struct PressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview Provider

#Preview("Glowing Cards") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Glowing Card Components")
                .font(.title2.bold())

            // Basic glowing cards
            VStack(spacing: 16) {
                Text("Glow Intensities")
                    .font(.headline)

                GlowingCard(glowColor: AppColors.primary, glowIntensity: .none) {
                    CardContent(title: "No Glow", subtitle: "Clean minimal card")
                }

                GlowingCard(glowColor: AppColors.primary, glowIntensity: .subtle) {
                    CardContent(title: "Subtle Glow", subtitle: "Gentle highlight")
                }

                GlowingCard(glowColor: AppColors.primary, glowIntensity: .medium) {
                    CardContent(title: "Medium Glow", subtitle: "Standard emphasis")
                }

                GlowingCard(glowColor: AppColors.primary, glowIntensity: .strong) {
                    CardContent(title: "Strong Glow", subtitle: "Maximum attention")
                }
            }

            Divider()

            // Different colors
            VStack(spacing: 16) {
                Text("Different Colors")
                    .font(.headline)

                GlowingCard(glowColor: AppColors.success, glowIntensity: .medium) {
                    CardContent(title: "Success", subtitle: "Completed task", icon: "checkmark.circle.fill")
                }

                GlowingCard(glowColor: AppColors.warning, glowIntensity: .medium) {
                    CardContent(title: "Warning", subtitle: "Needs attention", icon: "exclamationmark.triangle.fill")
                }

                GlowingCard(glowColor: AppColors.error, glowIntensity: .medium) {
                    CardContent(title: "Error", subtitle: "Urgent action required", icon: "xmark.circle.fill")
                }
            }

            Divider()

            // Priority cards
            VStack(spacing: 16) {
                Text("Priority Cards")
                    .font(.headline)

                PriorityCard(priority: .low, showPriorityBadge: true) {
                    CardContent(title: "Low Priority", subtitle: "Can wait")
                }

                PriorityCard(priority: .medium, showPriorityBadge: true) {
                    CardContent(title: "Medium Priority", subtitle: "Normal importance")
                }

                PriorityCard(priority: .high, showPriorityBadge: true) {
                    CardContent(title: "High Priority", subtitle: "Important task")
                }

                PriorityCard(priority: .urgent, showPriorityBadge: true) {
                    CardContent(title: "Urgent", subtitle: "Do this now!")
                }
            }

            Divider()

            // Interactive card
            VStack(spacing: 16) {
                Text("Interactive Card")
                    .font(.headline)

                InteractiveCard(glowColor: AppColors.accent, glowIntensity: .medium) {
                    CardContent(title: "Tap Me", subtitle: "This card is interactive", icon: "hand.tap.fill")
                } onTap: {
                    print("Card tapped!")
                }
            }

            Divider()

            // Pulsing card
            VStack(spacing: 16) {
                Text("Pulsing Card")
                    .font(.headline)

                PulsingCard(glowColor: AppColors.warning, pulseSpeed: 1.5) {
                    CardContent(
                        title: "Attention!",
                        subtitle: "This card pulses to grab attention",
                        icon: "bell.fill"
                    )
                }
            }
        }
        .padding()
        .background(AppColors.background)
    }
}

// MARK: - Preview Helpers

private struct CardContent: View {
    var title: String
    var subtitle: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }
}

#Preview("Interactive Demo") {
    InteractiveCardDemo()
}

private struct InteractiveCardDemo: View {
    @State private var selectedPriority: PriorityCard<AnyView>.Priority = .medium
    @State private var tapCount = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("Interactive Card Demo")
                .font(.title2.bold())

            InteractiveCard(
                glowColor: selectedPriority.color,
                glowIntensity: .strong
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tapped \(tapCount) times")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Tap to increment")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } onTap: {
                tapCount += 1
            }

            Text("Priority Level")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Low") { selectedPriority = .low }
                    .buttonStyle(.bordered)
                Button("Medium") { selectedPriority = .medium }
                    .buttonStyle(.bordered)
                Button("High") { selectedPriority = .high }
                    .buttonStyle(.bordered)
                Button("Urgent") { selectedPriority = .urgent }
                    .buttonStyle(.bordered)
            }

            PriorityCard(priority: selectedPriority, showPriorityBadge: true) {
                Text("Current priority: \(selectedPriority.label)")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding()
    }
}
