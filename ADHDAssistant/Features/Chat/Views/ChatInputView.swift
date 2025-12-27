//
//  ChatInputView.swift
//  ADHDAssistant
//
//  Text input component for chat interface
//

import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    let placeholder: String
    let isEnabled: Bool
    let onSend: () -> Void
    let onVoiceInput: (() -> Void)?

    @FocusState private var isFocused: Bool
    @State private var textHeight: CGFloat = 36

    private let maxHeight: CGFloat = 120
    private let minHeight: CGFloat = 36

    init(
        text: Binding<String>,
        placeholder: String = "Message...",
        isEnabled: Bool = true,
        onSend: @escaping () -> Void,
        onVoiceInput: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isEnabled = isEnabled
        self.onSend = onSend
        self.onVoiceInput = onVoiceInput
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            // Voice input button (optional)
            if let voiceAction = onVoiceInput {
                Button(action: voiceAction) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.surface)
                        .clipShape(Circle())
                }
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1.0 : 0.5)
            }

            // Text input field
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                }

                TextEditor(text: $text)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.sm + 2)
                    .padding(.vertical, AppSpacing.xs + 2)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .disabled(!isEnabled)
                    .onChange(of: text) { _, _ in
                        updateTextHeight()
                    }
            }
            .frame(height: textHeight)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    .strokeBorder(
                        isFocused ? AppColors.primary.opacity(0.5) : AppColors.divider,
                        lineWidth: isFocused ? 2 : 1
                    )
            )

            // Send button
            Button(action: handleSend) {
                Image(systemName: canSend ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.system(size: 28))
                    .foregroundColor(canSend ? AppColors.primary : AppColors.textTertiary)
            }
            .disabled(!canSend)
            .animation(.spring(response: 0.3), value: canSend)
        }
        .padding(.horizontal, AppSpacing.screenHorizontalPadding)
        .padding(.vertical, AppSpacing.sm)
        .background(
            AppColors.background
                .ignoresSafeArea(.keyboard)
        )
    }

    // MARK: - Computed Properties

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isEnabled
    }

    // MARK: - Actions

    private func handleSend() {
        guard canSend else { return }
        onSend()
        text = ""
        textHeight = minHeight
        isFocused = false
    }

    private func updateTextHeight() {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.text = text

        let size = textView.sizeThatFits(CGSize(
            width: UIScreen.main.bounds.width - 120,
            height: CGFloat.greatestFiniteMagnitude
        ))

        let newHeight = max(minHeight, min(size.height + 16, maxHeight))
        if newHeight != textHeight {
            withAnimation(.easeOut(duration: 0.2)) {
                textHeight = newHeight
            }
        }
    }
}

// MARK: - Preview

#Preview("Chat Input States") {
    VStack(spacing: AppSpacing.xxl) {
        Spacer()

        // Empty state
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Empty State")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            ChatInputView(
                text: .constant(""),
                onSend: {},
                onVoiceInput: {}
            )
        }

        // With text
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("With Text")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            ChatInputView(
                text: .constant("What should I work on next?"),
                onSend: {},
                onVoiceInput: {}
            )
        }

        // Multi-line
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Multi-line Text")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            ChatInputView(
                text: .constant("This is a longer message that spans multiple lines to demonstrate how the text input expands"),
                onSend: {},
                onVoiceInput: {}
            )
        }

        // Disabled
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Disabled State")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            ChatInputView(
                text: .constant(""),
                isEnabled: false,
                onSend: {},
                onVoiceInput: {}
            )
        }

        // Without voice button
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("No Voice Button")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            ChatInputView(
                text: .constant("Message without voice input"),
                onSend: {}
            )
        }
    }
    .padding()
    .background(AppColors.background)
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var message = ""

        var body: some View {
            VStack {
                Spacer()

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        ChatBubble(message: .sampleUser)
                        ChatBubble(message: .sampleAssistant)
                    }
                    .padding()
                }

                ChatInputView(
                    text: $message,
                    onSend: {
                        print("Sending: \(message)")
                    },
                    onVoiceInput: {
                        print("Voice input tapped")
                    }
                )
            }
            .background(AppColors.background)
        }
    }

    return InteractivePreview()
}
