//
//  ChatView.swift
//  ADHDAssistant
//
//  Main conversational AI interface
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var showClearConfirmation = false

    private let scrollViewID = "chatScrollView"

    init(viewModel: ChatViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    init(agentCoordinator: AgentCoordinator, context: AIContext? = nil) {
        self._viewModel = StateObject(wrappedValue: ChatViewModel(
            agentCoordinator: agentCoordinator,
            initialContext: context
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Message list
            messageList

            // Suggestions (only show when not generating)
            if !viewModel.isGenerating && !viewModel.suggestions.isEmpty {
                SuggestionChips(suggestions: viewModel.suggestions) { suggestion in
                    viewModel.sendMessage(suggestion)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Input field
            ChatInputView(
                text: $viewModel.inputText,
                isEnabled: !viewModel.isGenerating,
                onSend: {
                    viewModel.sendMessage()
                },
                onVoiceInput: {
                    // Placeholder for future voice input
                    print("Voice input tapped")
                }
            )
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showClearConfirmation = true }) {
                        Label("Clear History", systemImage: "trash")
                    }

                    Button(action: { viewModel.generateSuggestions() }) {
                        Label("Refresh Suggestions", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .alert("Clear Chat History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("This will delete all messages in this conversation. This action cannot be undone.")
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.md) {
                    // Messages
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message, showTimestamp: false)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: message.isUser ? .trailing : .leading)
                                    .combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Typing indicator
                    if viewModel.isGenerating {
                        HStack {
                            TypingIndicatorBubble()
                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .id("typingIndicator")
                    }

                    // Bottom spacer for keyboard
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, AppSpacing.md)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isGenerating) { _, isGenerating in
                if isGenerating {
                    scrollToBottom(proxy: proxy)
                }
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    // MARK: - Helper Views

    private struct TypingIndicatorBubble: View {
        var body: some View {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                // Assistant avatar
                Circle()
                    .fill(AppColors.primary.gradient)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    )

                TypingIndicator()
            }
        }
    }

    // MARK: - Helper Methods

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        let target = viewModel.isGenerating ? "typingIndicator" : "bottom"

        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(target, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }
}

// MARK: - Preview

#Preview("Chat with Messages") {
    NavigationStack {
        ChatView(viewModel: .preview)
    }
}

#Preview("Empty Chat") {
    NavigationStack {
        ChatView(viewModel: .emptyPreview)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ChatView(viewModel: .preview)
    }
    .preferredColorScheme(.dark)
}

#Preview("Full Context") {
    struct FullPreview: View {
        @StateObject private var viewModel: ChatViewModel

        init() {
            let modelManager = ModelManager()
            let coordinator = AgentCoordinator(modelManager: modelManager)
            _viewModel = StateObject(wrappedValue: ChatViewModel(agentCoordinator: coordinator))
        }

        var body: some View {
            NavigationStack {
                ChatView(viewModel: viewModel)
            }
        }
    }

    return FullPreview()
}
