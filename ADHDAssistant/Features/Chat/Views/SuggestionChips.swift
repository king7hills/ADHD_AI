//
//  SuggestionChips.swift
//  ADHDAssistant
//
//  Quick prompt suggestions for chat interface
//

import SwiftUI

// MARK: - Suggestion Model

struct ChatSuggestion: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let icon: String
    let category: SuggestionCategory

    enum SuggestionCategory {
        case task
        case motivation
        case health
        case general
    }
}

// MARK: - Suggestion Chips View

struct SuggestionChips: View {
    let suggestions: [ChatSuggestion]
    let onSuggestionTapped: (String) -> Void

    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(suggestions) { suggestion in
                    SuggestionChip(suggestion: suggestion) {
                        onSuggestionTapped(suggestion.text)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontalPadding)
            .padding(.vertical, AppSpacing.xs)
        }
    }
}

// MARK: - Individual Chip

private struct SuggestionChip: View {
    let suggestion: ChatSuggestion
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            action()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 14, weight: .medium))

                Text(suggestion.text)
                    .font(AppTypography.subheadline)
                    .lineLimit(1)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(chipBackground)
            .foregroundColor(chipForeground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(chipBorder, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var chipBackground: Color {
        switch suggestion.category {
        case .task:
            return AppColors.primary.opacity(0.1)
        case .motivation:
            return AppColors.accent.opacity(0.1)
        case .health:
            return AppColors.success.opacity(0.1)
        case .general:
            return AppColors.surface
        }
    }

    private var chipForeground: Color {
        switch suggestion.category {
        case .task:
            return AppColors.primary
        case .motivation:
            return AppColors.accent
        case .health:
            return AppColors.success
        case .general:
            return AppColors.textPrimary
        }
    }

    private var chipBorder: Color {
        switch suggestion.category {
        case .task:
            return AppColors.primary.opacity(0.2)
        case .motivation:
            return AppColors.accent.opacity(0.2)
        case .health:
            return AppColors.success.opacity(0.2)
        case .general:
            return AppColors.divider
        }
    }
}

// MARK: - Default Suggestions

extension ChatSuggestion {
    static let defaultSuggestions: [ChatSuggestion] = [
        ChatSuggestion(
            text: "Break down my next task",
            icon: "list.bullet.indent",
            category: .task
        ),
        ChatSuggestion(
            text: "What should I do now?",
            icon: "questionmark.circle",
            category: .general
        ),
        ChatSuggestion(
            text: "I'm feeling overwhelmed",
            icon: "heart.circle",
            category: .motivation
        ),
        ChatSuggestion(
            text: "Motivate me",
            icon: "bolt.fill",
            category: .motivation
        ),
        ChatSuggestion(
            text: "Check my health reminders",
            icon: "heart.text.square",
            category: .health
        )
    ]

    static let taskFocusedSuggestions: [ChatSuggestion] = [
        ChatSuggestion(
            text: "What's my next priority?",
            icon: "arrow.up.circle",
            category: .task
        ),
        ChatSuggestion(
            text: "Help me start this task",
            icon: "play.circle",
            category: .task
        ),
        ChatSuggestion(
            text: "I'm stuck, what now?",
            icon: "questionmark.circle",
            category: .general
        ),
        ChatSuggestion(
            text: "Quick win suggestions",
            icon: "star.fill",
            category: .task
        )
    ]

    static let motivationalSuggestions: [ChatSuggestion] = [
        ChatSuggestion(
            text: "I need encouragement",
            icon: "heart.fill",
            category: .motivation
        ),
        ChatSuggestion(
            text: "Celebrate my progress",
            icon: "party.popper",
            category: .motivation
        ),
        ChatSuggestion(
            text: "I'm struggling today",
            icon: "cloud.rain",
            category: .motivation
        ),
        ChatSuggestion(
            text: "Remind me why I started",
            icon: "target",
            category: .motivation
        )
    ]

    static let healthFocusedSuggestions: [ChatSuggestion] = [
        ChatSuggestion(
            text: "Time for a break?",
            icon: "cup.and.saucer",
            category: .health
        ),
        ChatSuggestion(
            text: "Check health metrics",
            icon: "heart.text.square",
            category: .health
        ),
        ChatSuggestion(
            text: "Medication reminder",
            icon: "pills",
            category: .health
        ),
        ChatSuggestion(
            text: "How's my energy?",
            icon: "bolt.circle",
            category: .health
        )
    ]
}

// MARK: - Context-Aware Suggestions Provider

struct SuggestionProvider {
    static func suggestionsFor(
        timeOfDay: TimeOfDay,
        hasActiveTasks: Bool,
        userMood: MoodLevel?
    ) -> [ChatSuggestion] {
        // Early morning - gentle, encouraging
        if timeOfDay == .earlyMorning || timeOfDay == .morning {
            return [
                ChatSuggestion(text: "What should I do first?", icon: "sunrise", category: .task),
                ChatSuggestion(text: "Morning health check", icon: "heart.circle", category: .health),
                ChatSuggestion(text: "Easy tasks to start", icon: "leaf", category: .task)
            ]
        }

        // Midday - productivity focused
        if timeOfDay == .midday || timeOfDay == .afternoon {
            if hasActiveTasks {
                return ChatSuggestion.taskFocusedSuggestions
            } else {
                return [
                    ChatSuggestion(text: "What's next on my list?", icon: "list.bullet", category: .task),
                    ChatSuggestion(text: "Quick productivity boost", icon: "bolt.fill", category: .motivation),
                    ChatSuggestion(text: "Time for a break?", icon: "cup.and.saucer", category: .health)
                ]
            }
        }

        // Evening/Night - winding down
        if timeOfDay == .evening || timeOfDay == .night {
            return [
                ChatSuggestion(text: "Review my day", icon: "checkmark.circle", category: .general),
                ChatSuggestion(text: "Tomorrow's priorities", icon: "calendar", category: .task),
                ChatSuggestion(text: "Celebrate today's wins", icon: "star.fill", category: .motivation)
            ]
        }

        // User feeling overwhelmed - supportive suggestions
        if userMood == .overwhelmed || userMood == .struggling {
            return ChatSuggestion.motivationalSuggestions
        }

        // Default suggestions
        return ChatSuggestion.defaultSuggestions
    }
}

// MARK: - Preview

#Preview("Default Suggestions") {
    VStack(spacing: AppSpacing.lg) {
        Text("Default Suggestions")
            .font(AppTypography.headline)
            .foregroundColor(AppColors.textPrimary)

        SuggestionChips(suggestions: ChatSuggestion.defaultSuggestions) { suggestion in
            print("Tapped: \(suggestion)")
        }

        Divider()

        Text("Task Focused")
            .font(AppTypography.headline)
            .foregroundColor(AppColors.textPrimary)

        SuggestionChips(suggestions: ChatSuggestion.taskFocusedSuggestions) { suggestion in
            print("Tapped: \(suggestion)")
        }

        Divider()

        Text("Motivational")
            .font(AppTypography.headline)
            .foregroundColor(AppColors.textPrimary)

        SuggestionChips(suggestions: ChatSuggestion.motivationalSuggestions) { suggestion in
            print("Tapped: \(suggestion)")
        }

        Spacer()
    }
    .background(AppColors.background)
}

#Preview("Context-Aware") {
    VStack(spacing: AppSpacing.lg) {
        Text("Morning Suggestions")
            .font(AppTypography.headline)

        SuggestionChips(
            suggestions: SuggestionProvider.suggestionsFor(
                timeOfDay: .morning,
                hasActiveTasks: false,
                userMood: .good
            )
        ) { _ in }

        Divider()

        Text("Overwhelmed User")
            .font(AppTypography.headline)

        SuggestionChips(
            suggestions: SuggestionProvider.suggestionsFor(
                timeOfDay: .afternoon,
                hasActiveTasks: true,
                userMood: .overwhelmed
            )
        ) { _ in }

        Spacer()
    }
    .padding()
    .background(AppColors.background)
}
