//
//  DailyGreeting.swift
//  ADHDAssistant
//
//  Dashboard - Daily Greeting Component
//

import SwiftUI

/// Time-appropriate greeting with motivational message
struct DailyGreeting: View {
    var userName: String
    var currentDate: Date = Date()

    @State private var motivationIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Time-based greeting
            Text(timeBasedGreeting)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            // User's name
            Text(userName)
                .font(AppTypography.largeTitle)
                .foregroundColor(AppColors.primary)

            // Date
            Text(formattedDate)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            // Motivational message
            Text(motivationalMessage)
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
                .italic()
                .padding(.top, AppSpacing.xs)
        }
        .onAppear {
            // Randomize motivation message
            motivationIndex = Int.random(in: 0..<motivationalMessages.count)
        }
    }

    // MARK: - Computed Properties

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)

        switch hour {
        case 5..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<22:
            return "Good evening,"
        default:
            return "Hello,"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentDate)
    }

    private var motivationalMessage: String {
        motivationalMessages[motivationIndex]
    }

    private let motivationalMessages = [
        "Let's make today productive!",
        "One task at a time, you've got this!",
        "Small steps lead to big progress.",
        "Focus on what matters most today.",
        "You're building great habits!",
        "Every completed task is a victory.",
        "Today is full of possibilities.",
        "Progress, not perfection.",
        "You're doing better than you think!",
        "Let's tackle your goals together.",
        "Consistency is your superpower.",
        "Make today count!"
    ]
}

/// Compact greeting for navigation bars
struct CompactGreeting: View {
    var userName: String
    var showDate: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(timeBasedGreeting)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                Text(userName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            if showDate {
                Text(formattedDate)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<22:
            return "Good evening,"
        default:
            return "Hello,"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview Provider

#Preview("Daily Greeting") {
    VStack(spacing: 40) {
        DailyGreeting(userName: "Alex")
            .padding()
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

        DailyGreeting(userName: "Jordan Smith")
            .padding()
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

        Divider()

        VStack(spacing: 16) {
            Text("Compact Greetings")
                .font(.headline)

            CompactGreeting(userName: "Alex")
            CompactGreeting(userName: "Jordan", showDate: true)
        }
    }
    .padding()
    .background(AppColors.background)
}
