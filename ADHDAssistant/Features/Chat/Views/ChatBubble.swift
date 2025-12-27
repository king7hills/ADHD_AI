//
//  ChatBubble.swift
//  ADHDAssistant
//
//  Message bubble component for chat interface
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    let showTimestamp: Bool

    @State private var showCopyConfirmation = false

    init(message: ChatMessage, showTimestamp: Bool = false) {
        self.message = message
        self.showTimestamp = showTimestamp
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            if message.isAssistant {
                assistantAvatar
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: AppSpacing.xs) {
                // Message content
                messageContent
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm + 2)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
                    .contextMenu {
                        Button(action: copyMessage) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }

                // Timestamp
                if showTimestamp {
                    Text(message.formattedTime)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.xs)
                }
            }

            if message.isUser {
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontalPadding)
        .overlay(
            Group {
                if showCopyConfirmation {
                    Text("Copied!")
                        .font(AppTypography.caption)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.success)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .animation(.spring(response: 0.3), value: showCopyConfirmation)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var messageContent: some View {
        switch message.content {
        case .text(let text), .motivation(let text):
            Text(text)
                .font(AppTypography.body)
                .foregroundColor(textColor)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

        case .taskSuggestion(let items):
            taskSuggestionView(items: items)

        case .healthReminder(let item):
            healthReminderView(item: item)

        case .error(let errorMessage):
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColors.error)
                Text(errorMessage)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.error)
            }
        }
    }

    private var assistantAvatar: some View {
        Circle()
            .fill(AppColors.primary.gradient)
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    private var bubbleBackground: some View {
        Group {
            if message.isUser {
                AppColors.primary
            } else if case .error = message.content {
                AppColors.error.opacity(0.1)
            } else {
                AppColors.surface
            }
        }
    }

    private var textColor: Color {
        if message.isUser {
            return .white
        } else if case .error = message.content {
            return AppColors.error
        } else {
            return AppColors.textPrimary
        }
    }

    @ViewBuilder
    private func taskSuggestionView(items: [TaskSuggestionItem]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Here are some tasks I suggest:")
                .font(AppTypography.bodyBold)
                .foregroundColor(AppColors.textPrimary)

            ForEach(items) { item in
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)

                        Text("\(Int(item.estimatedDuration / 60)) min • \(item.difficulty)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(AppSpacing.sm)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            }
        }
    }

    @ViewBuilder
    private func healthReminderView(item: HealthReminderItem) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: item.urgency == "high" ? "exclamationmark.circle.fill" : "heart.circle.fill")
                .foregroundColor(item.urgency == "high" ? AppColors.warning : AppColors.primary)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.type.capitalized)
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)

                Text(item.message)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func copyMessage() {
        UIPasteboard.general.string = message.displayText

        // Show confirmation
        showCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopyConfirmation = false
        }
    }
}

// MARK: - Preview

#Preview("Chat Bubbles") {
    ScrollView {
        VStack(spacing: AppSpacing.md) {
            ChatBubble(message: .sampleUser, showTimestamp: true)

            ChatBubble(message: .sampleAssistant, showTimestamp: true)

            ChatBubble(message: .sampleMotivation, showTimestamp: true)

            ChatBubble(message: .sampleTaskSuggestion, showTimestamp: false)

            ChatBubble(message: .sampleHealthReminder, showTimestamp: false)

            ChatBubble(message: .error("Failed to process your request"), showTimestamp: true)
        }
        .padding(.vertical, AppSpacing.lg)
    }
    .background(AppColors.background)
}

#Preview("Conversation") {
    ScrollView {
        VStack(spacing: AppSpacing.md) {
            ForEach(ChatMessage.sampleConversation) { message in
                ChatBubble(message: message, showTimestamp: false)
            }
        }
        .padding(.vertical, AppSpacing.lg)
    }
    .background(AppColors.background)
}
