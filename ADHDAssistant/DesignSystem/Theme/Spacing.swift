//
//  Spacing.swift
//  ADHDAssistant
//
//  Design System - Spacing and Layout
//

import SwiftUI

/// App-wide spacing system with consistent values
struct AppSpacing {

    // MARK: - Base Spacing Scale

    /// Extra extra small spacing (2pt)
    static let xxs: CGFloat = 2

    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4

    /// Small spacing (8pt)
    static let sm: CGFloat = 8

    /// Medium spacing (16pt) - most common spacing
    static let md: CGFloat = 16

    /// Large spacing (24pt)
    static let lg: CGFloat = 24

    /// Extra large spacing (32pt)
    static let xl: CGFloat = 32

    /// Extra extra large spacing (48pt)
    static let xxl: CGFloat = 48

    /// Triple extra large spacing (64pt)
    static let xxxl: CGFloat = 64

    // MARK: - Component-Specific Spacing

    /// Standard card padding
    static let cardPadding: CGFloat = 16

    /// Large card padding for emphasis
    static let cardPaddingLarge: CGFloat = 24

    /// Button internal padding (vertical)
    static let buttonPaddingVertical: CGFloat = 12

    /// Button internal padding (horizontal)
    static let buttonPaddingHorizontal: CGFloat = 24

    /// Compact button padding
    static let buttonPaddingCompact: CGFloat = 8

    /// Spacing between list items
    static let listItemSpacing: CGFloat = 12

    /// Spacing between list sections
    static let listSectionSpacing: CGFloat = 24

    /// Spacing for inline elements (badges, tags)
    static let inlineSpacing: CGFloat = 6

    /// Icon and text spacing
    static let iconTextSpacing: CGFloat = 8

    /// Chip/badge internal padding
    static let chipPadding: CGFloat = 8

    // MARK: - Layout Spacing

    /// Standard horizontal screen padding
    static let screenHorizontalPadding: CGFloat = 20

    /// Standard vertical screen padding
    static let screenVerticalPadding: CGFloat = 16

    /// Safe area bottom padding for buttons
    static let safeAreaBottomPadding: CGFloat = 16

    /// Minimum touch target size (44x44pt recommended by Apple)
    static let minTouchTarget: CGFloat = 44

    /// Standard divider spacing
    static let dividerSpacing: CGFloat = 16

    // MARK: - Corner Radius

    /// Extra small corner radius (4pt)
    static let cornerRadiusXS: CGFloat = 4

    /// Small corner radius (8pt)
    static let cornerRadiusSmall: CGFloat = 8

    /// Medium corner radius (12pt) - standard for cards
    static let cornerRadiusMedium: CGFloat = 12

    /// Large corner radius (16pt)
    static let cornerRadiusLarge: CGFloat = 16

    /// Extra large corner radius (24pt)
    static let cornerRadiusXL: CGFloat = 24

    /// Circular corner radius (very large, creates circles)
    static let cornerRadiusCircular: CGFloat = 999

    // MARK: - Border Width

    /// Thin border
    static let borderThin: CGFloat = 1

    /// Medium border
    static let borderMedium: CGFloat = 2

    /// Thick border for emphasis
    static let borderThick: CGFloat = 3

    // MARK: - Shadow

    /// Shadow radius for cards
    static let shadowRadius: CGFloat = 8

    /// Shadow radius for elevated elements
    static let shadowRadiusElevated: CGFloat = 16

    /// Shadow offset
    static let shadowOffset: CGSize = CGSize(width: 0, height: 2)

    /// Elevated shadow offset
    static let shadowOffsetElevated: CGSize = CGSize(width: 0, height: 4)

    // MARK: - Icon Sizes

    /// Extra small icon (12pt)
    static let iconSizeXS: CGFloat = 12

    /// Small icon (16pt)
    static let iconSizeSmall: CGFloat = 16

    /// Medium icon (20pt) - standard size
    static let iconSizeMedium: CGFloat = 20

    /// Large icon (24pt)
    static let iconSizeLarge: CGFloat = 24

    /// Extra large icon (32pt)
    static let iconSizeXL: CGFloat = 32

    /// Extra extra large icon (48pt)
    static let iconSizeXXL: CGFloat = 48

    // MARK: - Progress Indicators

    /// Progress ring line width
    static let progressLineWidth: CGFloat = 8

    /// Progress ring line width (large)
    static let progressLineWidthLarge: CGFloat = 12

    /// Progress bar height
    static let progressBarHeight: CGFloat = 6

    /// Progress bar height (large)
    static let progressBarHeightLarge: CGFloat = 10
}

// MARK: - Spacing Modifiers

extension View {
    /// Applies standard card padding
    func cardPadding() -> some View {
        self.padding(AppSpacing.cardPadding)
    }

    /// Applies large card padding
    func cardPaddingLarge() -> some View {
        self.padding(AppSpacing.cardPaddingLarge)
    }

    /// Applies screen horizontal padding
    func screenPadding() -> some View {
        self.padding(.horizontal, AppSpacing.screenHorizontalPadding)
    }

    /// Applies standard corner radius
    func standardCornerRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
    }

    /// Applies card-style shadow
    func cardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.08),
            radius: AppSpacing.shadowRadius,
            x: AppSpacing.shadowOffset.width,
            y: AppSpacing.shadowOffset.height
        )
    }

    /// Applies elevated shadow
    func elevatedShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.12),
            radius: AppSpacing.shadowRadiusElevated,
            x: AppSpacing.shadowOffsetElevated.width,
            y: AppSpacing.shadowOffsetElevated.height
        )
    }

    /// Ensures minimum touch target size
    func minTouchTarget() -> some View {
        self.frame(minWidth: AppSpacing.minTouchTarget, minHeight: AppSpacing.minTouchTarget)
    }
}

// MARK: - Layout Helpers

extension AppSpacing {
    /// Returns spacing for a given scale factor
    static func scaled(_ multiplier: CGFloat) -> CGFloat {
        return md * multiplier
    }

    /// Stack spacing based on size
    enum StackSpacing {
        case compact
        case normal
        case relaxed
        case loose

        var value: CGFloat {
            switch self {
            case .compact: return AppSpacing.sm
            case .normal: return AppSpacing.md
            case .relaxed: return AppSpacing.lg
            case .loose: return AppSpacing.xl
            }
        }
    }

    /// Grid spacing based on size
    enum GridSpacing {
        case tight
        case normal
        case relaxed

        var horizontal: CGFloat {
            switch self {
            case .tight: return AppSpacing.sm
            case .normal: return AppSpacing.md
            case .relaxed: return AppSpacing.lg
            }
        }

        var vertical: CGFloat {
            switch self {
            case .tight: return AppSpacing.sm
            case .normal: return AppSpacing.md
            case .relaxed: return AppSpacing.lg
            }
        }
    }
}

// MARK: - Preview Provider

#Preview("Spacing Showcase") {
    ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            SpacingSection(title: "Base Spacing Scale") {
                SpacingSwatch(name: "XXS (2pt)", spacing: AppSpacing.xxs)
                SpacingSwatch(name: "XS (4pt)", spacing: AppSpacing.xs)
                SpacingSwatch(name: "SM (8pt)", spacing: AppSpacing.sm)
                SpacingSwatch(name: "MD (16pt)", spacing: AppSpacing.md)
                SpacingSwatch(name: "LG (24pt)", spacing: AppSpacing.lg)
                SpacingSwatch(name: "XL (32pt)", spacing: AppSpacing.xl)
                SpacingSwatch(name: "XXL (48pt)", spacing: AppSpacing.xxl)
            }

            SpacingSection(title: "Corner Radius") {
                CornerRadiusSwatch(name: "XS", radius: AppSpacing.cornerRadiusXS)
                CornerRadiusSwatch(name: "Small", radius: AppSpacing.cornerRadiusSmall)
                CornerRadiusSwatch(name: "Medium", radius: AppSpacing.cornerRadiusMedium)
                CornerRadiusSwatch(name: "Large", radius: AppSpacing.cornerRadiusLarge)
                CornerRadiusSwatch(name: "XL", radius: AppSpacing.cornerRadiusXL)
            }

            SpacingSection(title: "Icon Sizes") {
                HStack(spacing: AppSpacing.lg) {
                    IconSizeSwatch(name: "XS", size: AppSpacing.iconSizeXS)
                    IconSizeSwatch(name: "Small", size: AppSpacing.iconSizeSmall)
                    IconSizeSwatch(name: "Medium", size: AppSpacing.iconSizeMedium)
                    IconSizeSwatch(name: "Large", size: AppSpacing.iconSizeLarge)
                    IconSizeSwatch(name: "XL", size: AppSpacing.iconSizeXL)
                }
            }

            SpacingSection(title: "Card Examples") {
                VStack(spacing: AppSpacing.md) {
                    Text("Standard Card Padding")
                        .cardPadding()
                        .background(Color.blue.opacity(0.1))
                        .standardCornerRadius()

                    Text("Large Card Padding")
                        .cardPaddingLarge()
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLarge))

                    Text("Card with Shadow")
                        .cardPadding()
                        .background(Color.white)
                        .standardCornerRadius()
                        .cardShadow()
                }
            }
        }
        .padding()
    }
    .background(Color(UIColor.systemBackground))
}

// MARK: - Preview Helpers

private struct SpacingSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content

            Divider()
        }
    }
}

private struct SpacingSwatch: View {
    let name: String
    let spacing: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)

            Rectangle()
                .fill(Color.blue)
                .frame(width: spacing, height: 20)

            Text("\(Int(spacing))pt")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct CornerRadiusSwatch: View {
    let name: String
    let radius: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.blue)
                .frame(width: 80, height: 60)

            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(radius))pt")
                .font(.caption2)
                .foregroundColor(.tertiary)
        }
    }
}

private struct IconSizeSwatch: View {
    let name: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.blue)

            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(size))pt")
                .font(.caption2)
                .foregroundColor(.tertiary)
        }
    }
}
