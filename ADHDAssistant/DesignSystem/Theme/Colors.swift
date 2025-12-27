//
//  Colors.swift
//  ADHDAssistant
//
//  Design System - Color Palette
//

import SwiftUI

/// App-wide color palette with support for light and dark modes
struct AppColors {

    // MARK: - Primary Palette

    /// Main brand color - used for primary actions and highlights
    static let primary = Color("Primary", fallback: Color(hex: "#3B82F6"))

    /// Secondary brand color - used for supporting elements
    static let secondary = Color("Secondary", fallback: Color(hex: "#8B5CF6"))

    /// Accent color - used for important UI elements and calls-to-action
    static let accent = Color("Accent", fallback: Color(hex: "#F59E0B"))

    // MARK: - Semantic Colors

    /// Success state color
    static let success = Color("Success", fallback: Color(hex: "#10B981"))

    /// Warning state color
    static let warning = Color("Warning", fallback: Color(hex: "#F59E0B"))

    /// Error state color
    static let error = Color("Error", fallback: Color(hex: "#EF4444"))

    /// Informational color
    static let info = Color("Info", fallback: Color(hex: "#3B82F6"))

    // MARK: - Background Colors

    /// Main background color
    static let background = Color("Background", fallback: Color(light: .white, dark: Color(hex: "#0F0F0F")))

    /// Surface color for cards and panels
    static let surface = Color("Surface", fallback: Color(light: Color(hex: "#F9FAFB"), dark: Color(hex: "#1A1A1A")))

    /// Card background color
    static let card = Color("Card", fallback: Color(light: .white, dark: Color(hex: "#1F1F1F")))

    // MARK: - Text Colors

    /// Primary text color
    static let textPrimary = Color("TextPrimary", fallback: Color(light: Color(hex: "#111827"), dark: Color(hex: "#F9FAFB")))

    /// Secondary text color
    static let textSecondary = Color("TextSecondary", fallback: Color(light: Color(hex: "#6B7280"), dark: Color(hex: "#9CA3AF")))

    /// Tertiary text color
    static let textTertiary = Color("TextTertiary", fallback: Color(light: Color(hex: "#9CA3AF"), dark: Color(hex: "#6B7280")))

    // MARK: - Tier Colors

    /// Bronze tier color
    static let bronze = Color(hex: "#CD7F32")

    /// Silver tier color
    static let silver = Color(hex: "#C0C0C0")

    /// Gold tier color
    static let gold = Color(hex: "#FFD700")

    // MARK: - Health Colors

    /// Normal blood sugar level color
    static let bloodSugarNormal = Color(hex: "#10B981")

    /// Low blood sugar level color
    static let bloodSugarLow = Color(hex: "#3B82F6")

    /// High blood sugar level color
    static let bloodSugarHigh = Color(hex: "#EF4444")

    // MARK: - Utility Colors

    /// Shadow color
    static let shadow = Color.black.opacity(0.1)

    /// Divider color
    static let divider = Color("Divider", fallback: Color(light: Color(hex: "#E5E7EB"), dark: Color(hex: "#374151")))

    /// Overlay color for modals
    static let overlay = Color.black.opacity(0.4)
}

// MARK: - Color Extensions

extension Color {
    /// Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Initialize color with different values for light and dark mode
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }

    /// Fallback initializer - tries to load from asset catalog first
    init(_ name: String, fallback: Color) {
        if let _ = UIColor(named: name) {
            self.init(name)
        } else {
            self = fallback
        }
    }
}

// MARK: - Preview Provider

#Preview("Color Palette") {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            ColorSection(title: "Primary Palette") {
                ColorSwatch(name: "Primary", color: AppColors.primary)
                ColorSwatch(name: "Secondary", color: AppColors.secondary)
                ColorSwatch(name: "Accent", color: AppColors.accent)
            }

            ColorSection(title: "Semantic Colors") {
                ColorSwatch(name: "Success", color: AppColors.success)
                ColorSwatch(name: "Warning", color: AppColors.warning)
                ColorSwatch(name: "Error", color: AppColors.error)
                ColorSwatch(name: "Info", color: AppColors.info)
            }

            ColorSection(title: "Backgrounds") {
                ColorSwatch(name: "Background", color: AppColors.background)
                ColorSwatch(name: "Surface", color: AppColors.surface)
                ColorSwatch(name: "Card", color: AppColors.card)
            }

            ColorSection(title: "Text Colors") {
                ColorSwatch(name: "Text Primary", color: AppColors.textPrimary)
                ColorSwatch(name: "Text Secondary", color: AppColors.textSecondary)
                ColorSwatch(name: "Text Tertiary", color: AppColors.textTertiary)
            }

            ColorSection(title: "Tier Colors") {
                ColorSwatch(name: "Bronze", color: AppColors.bronze)
                ColorSwatch(name: "Silver", color: AppColors.silver)
                ColorSwatch(name: "Gold", color: AppColors.gold)
            }

            ColorSection(title: "Health Colors") {
                ColorSwatch(name: "Normal", color: AppColors.bloodSugarNormal)
                ColorSwatch(name: "Low", color: AppColors.bloodSugarLow)
                ColorSwatch(name: "High", color: AppColors.bloodSugarHigh)
            }
        }
        .padding()
    }
    .background(AppColors.background)
}

// MARK: - Preview Helpers

private struct ColorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                content
            }
        }
    }
}

private struct ColorSwatch: View {
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.divider, lineWidth: 1)
                )

            Text(name)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// Temporary spacing reference
private struct AppSpacing {
    static let lg: CGFloat = 24
}
