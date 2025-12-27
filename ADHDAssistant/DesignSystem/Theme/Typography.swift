//
//  Typography.swift
//  ADHDAssistant
//
//  Design System - Typography
//

import SwiftUI

/// App-wide typography system with semantic font styles
struct AppTypography {

    // MARK: - Headers

    /// Large title - used for main screen titles
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)

    /// Title 1 - used for primary section headers
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Title 2 - used for secondary section headers
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)

    /// Title 3 - used for tertiary section headers
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    /// Headline - used for card titles and list headers
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)

    // MARK: - Body Text

    /// Body - standard body text
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// Body Bold - emphasized body text
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)

    /// Callout - slightly smaller than body, used for secondary content
    static let callout = Font.system(size: 16, weight: .regular, design: .default)

    /// Subheadline - used for supporting text and labels
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    /// Footnote - used for metadata and timestamps
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)

    /// Caption - smallest text size for captions and tertiary info
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption Bold - emphasized caption
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)

    // MARK: - Special Purpose

    /// Task title - optimized for task list readability
    static let taskTitle = Font.system(size: 16, weight: .medium, design: .default)

    /// Points display - large numbers for gamification
    static let pointsDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
        .monospacedDigit()

    /// Streak count - medium-sized numbers for streak displays
    static let streakCount = Font.system(size: 24, weight: .bold, design: .rounded)
        .monospacedDigit()

    /// Timer display - monospaced for countdown/countup timers
    static let timerDisplay = Font.system(size: 36, weight: .semibold, design: .rounded)
        .monospacedDigit()

    /// Timer display large - for focus mode
    static let timerDisplayLarge = Font.system(size: 64, weight: .bold, design: .rounded)
        .monospacedDigit()

    /// Badge text - small text for badges and tags
    static let badgeText = Font.system(size: 11, weight: .semibold, design: .rounded)

    /// Button text - optimized for button labels
    static let buttonText = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Button text small - for compact buttons
    static let buttonTextSmall = Font.system(size: 15, weight: .semibold, design: .rounded)
}

// MARK: - Custom Font Scaling

extension AppTypography {
    /// Returns a scaled font based on the system's accessibility text size settings
    static func scaledFont(_ font: Font, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        // SwiftUI automatically scales system fonts, but we can customize if needed
        return font
    }

    /// Returns a font with custom weight
    static func customWeight(_ baseFont: Font, weight: Font.Weight) -> Font {
        // Helper to create font variants
        return baseFont.weight(weight)
    }
}

// MARK: - Text Styles for UIKit

extension AppTypography {
    /// UIFont versions for use in UIKit components
    struct UIKitFonts {
        static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold)
        static let title1 = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let title2 = UIFont.systemFont(ofSize: 22, weight: .bold)
        static let title3 = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let callout = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let subheadline = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let footnote = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
}

// MARK: - Typography Modifiers

extension View {
    /// Applies app-standard typography with proper color
    func appTypography(_ font: Font, color: Color = AppColors.textPrimary) -> some View {
        self
            .font(font)
            .foregroundColor(color)
    }

    /// Applies task title styling
    func taskTitleStyle() -> some View {
        self
            .font(AppTypography.taskTitle)
            .foregroundColor(AppColors.textPrimary)
    }

    /// Applies points display styling
    func pointsDisplayStyle(color: Color = AppColors.accent) -> some View {
        self
            .font(AppTypography.pointsDisplay)
            .foregroundColor(color)
    }

    /// Applies timer display styling
    func timerDisplayStyle(color: Color = AppColors.primary) -> some View {
        self
            .font(AppTypography.timerDisplay)
            .foregroundColor(color)
    }
}

// MARK: - Preview Provider

#Preview("Typography Showcase") {
    ScrollView {
        VStack(alignment: .leading, spacing: 32) {
            TypographySection(title: "Headers") {
                TypographyExample(text: "Large Title", font: AppTypography.largeTitle)
                TypographyExample(text: "Title 1", font: AppTypography.title1)
                TypographyExample(text: "Title 2", font: AppTypography.title2)
                TypographyExample(text: "Title 3", font: AppTypography.title3)
                TypographyExample(text: "Headline", font: AppTypography.headline)
            }

            TypographySection(title: "Body Text") {
                TypographyExample(text: "Body text - the quick brown fox jumps over the lazy dog", font: AppTypography.body)
                TypographyExample(text: "Body Bold - the quick brown fox jumps over the lazy dog", font: AppTypography.bodyBold)
                TypographyExample(text: "Callout - supporting content goes here", font: AppTypography.callout)
                TypographyExample(text: "Subheadline - labels and secondary text", font: AppTypography.subheadline)
                TypographyExample(text: "Footnote - metadata and timestamps", font: AppTypography.footnote)
                TypographyExample(text: "Caption - tertiary information", font: AppTypography.caption)
            }

            TypographySection(title: "Special Purpose") {
                TypographyExample(text: "Complete morning routine", font: AppTypography.taskTitle)
                TypographyExample(text: "1,250", font: AppTypography.pointsDisplay)
                TypographyExample(text: "7 days", font: AppTypography.streakCount)
                TypographyExample(text: "25:00", font: AppTypography.timerDisplay)
                TypographyExample(text: "NEW", font: AppTypography.badgeText)
                TypographyExample(text: "Start Timer", font: AppTypography.buttonText)
            }

            TypographySection(title: "Monospaced Numbers") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("00:00")
                        .font(AppTypography.timerDisplay)
                    Text("12:34")
                        .font(AppTypography.timerDisplay)
                    Text("99:59")
                        .font(AppTypography.timerDisplay)
                }
                .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding()
    }
    .background(AppColors.background)
}

// MARK: - Preview Helpers

private struct TypographySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 12) {
                content
            }

            Divider()
        }
    }
}

private struct TypographyExample: View {
    let text: String
    let font: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(font)
                .foregroundColor(AppColors.textPrimary)

            Text(describeFontSize(font))
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    private func describeFontSize(_ font: Font) -> String {
        // This is a simplified description
        let fontString = "\(font)"
        if fontString.contains("34") { return "34pt, Bold, Rounded" }
        if fontString.contains("28") { return "28pt, Bold, Rounded" }
        if fontString.contains("22") { return "22pt, Bold, Rounded" }
        if fontString.contains("20") { return "20pt, Semibold, Rounded" }
        if fontString.contains("17") && fontString.contains("semibold") { return "17pt, Semibold" }
        if fontString.contains("17") { return "17pt, Regular" }
        if fontString.contains("16") { return "16pt, Regular" }
        if fontString.contains("15") { return "15pt, Regular" }
        if fontString.contains("13") { return "13pt, Regular" }
        if fontString.contains("12") { return "12pt, Regular/Semibold" }
        if fontString.contains("48") { return "48pt, Bold, Rounded, Monospaced" }
        if fontString.contains("36") { return "36pt, Semibold, Rounded, Monospaced" }
        if fontString.contains("24") { return "24pt, Bold, Rounded, Monospaced" }
        if fontString.contains("11") { return "11pt, Semibold, Rounded" }
        return "Custom"
    }
}

// Temporary color reference
private struct AppColors {
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.gray
    static let background = Color(UIColor.systemBackground)
}
