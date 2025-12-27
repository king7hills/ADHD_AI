//
//  ChatViewModel.swift
//  ADHDAssistant
//
//  ViewModel for chat interface with AI agent coordination
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var suggestions: [ChatSuggestion] = []
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let agentCoordinator: AgentCoordinator
    private var aiContext: AIContext

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()
    private var streamingMessageId: UUID?

    // MARK: - Initialization

    init(agentCoordinator: AgentCoordinator, initialContext: AIContext? = nil) {
        self.agentCoordinator = agentCoordinator
        self.aiContext = initialContext ?? AIContext(
            timeOfDay: TimeOfDay(from: Date()),
            customContext: [:]
        )

        // Generate initial suggestions
        generateSuggestions()

        // Add welcome message
        addWelcomeMessage()
    }

    // MARK: - Message Management

    func sendMessage(_ text: String? = nil) {
        let messageText = text ?? inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !messageText.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage.user(messageText)
        messages.append(userMessage)

        // Clear input
        inputText = ""

        // Update AI context with user message
        updateContextWithMessage(messageText)

        // Process the message
        Task {
            await processUserMessage(messageText)
        }
    }

    private func processUserMessage(_ text: String) async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            // Determine intent and route to appropriate agent
            let intent = detectIntent(from: text)

            let response = try await routeToAgent(for: intent, userMessage: text)

            // Add AI response to messages
            await addAIResponse(from: response)

            // Update suggestions based on conversation
            generateSuggestions()

        } catch {
            handleError(error)
        }
    }

    private func addAIResponse(from response: AgentResponse) {
        let message: ChatMessage

        switch response.data {
        case .tasks(let taskData):
            let items = taskData.map { data in
                TaskSuggestionItem(
                    title: data.title,
                    estimatedDuration: data.estimatedDuration,
                    difficulty: data.difficulty.rawValue
                )
            }
            message = ChatMessage(
                role: .assistant,
                content: .taskSuggestion(items),
                metadata: response.metadata
            )

        case .motivation(let motivationData):
            message = ChatMessage.motivation(motivationData.message)

        case .healthReminder(let healthData):
            let item = HealthReminderItem(
                message: healthData.message,
                type: healthData.type,
                urgency: healthData.urgency
            )
            message = ChatMessage(
                role: .assistant,
                content: .healthReminder(item),
                metadata: response.metadata
            )

        case .intervention(let interventionData):
            let text = interventionData.suggestedAction.map {
                "\(interventionData.message)\n\n\($0)"
            } ?? interventionData.message

            message = ChatMessage.assistant(text)

        case .error(let errorData):
            message = ChatMessage.error(errorData.message)

        case .scheduledEvents:
            message = ChatMessage.assistant("I've scheduled the tasks for you.")
        }

        messages.append(message)
    }

    // MARK: - Intent Detection

    private enum UserIntent {
        case taskBreakdown
        case motivation
        case healthCheck
        case whatNext
        case overwhelmed
        case celebrate
        case general
    }

    private func detectIntent(from text: String) -> UserIntent {
        let lowercased = text.lowercased()

        // Task-related intents
        if lowercased.contains("break down") ||
           lowercased.contains("break it down") ||
           lowercased.contains("breakdown") ||
           lowercased.contains("split") ||
           lowercased.contains("divide") {
            return .taskBreakdown
        }

        // Next action intents
        if lowercased.contains("what should i do") ||
           lowercased.contains("what next") ||
           lowercased.contains("what's next") ||
           lowercased.contains("priority") ||
           lowercased.contains("what now") {
            return .whatNext
        }

        // Overwhelmed/struggling intents
        if lowercased.contains("overwhelm") ||
           lowercased.contains("stuck") ||
           lowercased.contains("struggling") ||
           lowercased.contains("can't focus") ||
           lowercased.contains("too much") {
            return .overwhelmed
        }

        // Motivation intents
        if lowercased.contains("motivate") ||
           lowercased.contains("encourage") ||
           lowercased.contains("inspire") ||
           lowercased.contains("help me start") {
            return .motivation
        }

        // Health intents
        if lowercased.contains("health") ||
           lowercased.contains("medication") ||
           lowercased.contains("blood sugar") ||
           lowercased.contains("reminder") {
            return .healthCheck
        }

        // Celebration intents
        if lowercased.contains("celebrate") ||
           lowercased.contains("completed") ||
           lowercased.contains("finished") ||
           lowercased.contains("done") {
            return .celebrate
        }

        return .general
    }

    private func routeToAgent(for intent: UserIntent, userMessage: String) async throws -> AgentResponse {
        // Update context
        aiContext.customContext["user_message"] = userMessage
        aiContext.customContext["intent"] = "\(intent)"

        switch intent {
        case .taskBreakdown:
            return try await agentCoordinator.process(.breakdownGoal(goal: userMessage, deadline: nil))

        case .motivation, .overwhelmed:
            let trigger: MotivationTrigger = intent == .overwhelmed ? .lowMotivation : .encouragement
            return try await agentCoordinator.process(.motivate(trigger: trigger))

        case .healthCheck:
            return try await agentCoordinator.process(.healthCheck)

        case .whatNext:
            return try await agentCoordinator.process(.quickAdvice(question: userMessage))

        case .celebrate:
            return try await agentCoordinator.process(.motivate(trigger: .celebration))

        case .general:
            return try await agentCoordinator.process(.quickAdvice(question: userMessage))
        }
    }

    // MARK: - Suggestions

    func generateSuggestions() {
        // Get context-aware suggestions
        let timeOfDay = TimeOfDay(from: Date())
        let hasActiveTasks = !aiContext.recentTasks.isEmpty
        let userMood = aiContext.currentEnergy == .veryLow ? MoodLevel.struggling : nil

        suggestions = SuggestionProvider.suggestionsFor(
            timeOfDay: timeOfDay,
            hasActiveTasks: hasActiveTasks,
            userMood: userMood
        )
    }

    // MARK: - Context Management

    private func updateContextWithMessage(_ message: String) {
        // Update AI context
        aiContext.lastProductiveActivity = Date()
        aiContext.customContext["last_user_message"] = message

        // Sync with agent coordinator
        agentCoordinator.updateContext(aiContext)
    }

    func updateContext(_ context: AIContext) {
        self.aiContext = context
        agentCoordinator.updateContext(context)
        generateSuggestions()
    }

    // MARK: - History Management

    func clearHistory() {
        messages.removeAll()
        addWelcomeMessage()
        generateSuggestions()
    }

    private func addWelcomeMessage() {
        let timeOfDay = TimeOfDay(from: Date())
        let greeting: String

        switch timeOfDay {
        case .earlyMorning:
            greeting = "Good morning! Starting early today. What can I help you with?"
        case .morning:
            greeting = "Good morning! Ready to tackle the day? What's on your mind?"
        case .midday:
            greeting = "Hey there! How's your day going? What can I help with?"
        case .afternoon:
            greeting = "Good afternoon! What would you like to work on?"
        case .evening:
            greeting = "Good evening! How can I support you right now?"
        case .night:
            greeting = "Hey! Still going strong. What do you need?"
        case .lateNight:
            greeting = "Hi! How can I help you tonight?"
        }

        messages.append(ChatMessage.assistant(greeting))
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        messages.append(ChatMessage.error("I encountered an issue: \(error.localizedDescription). Please try again."))

        // Auto-clear error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.errorMessage = nil
        }
    }

    // MARK: - Streaming Support (Placeholder)

    func processAIResponse(streaming: Bool = false) async {
        // Future enhancement: streaming text responses
        // This would update a message character by character
        isGenerating = true

        defer { isGenerating = false }

        // Simulate streaming delay
        if streaming {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ChatViewModel {
    static var preview: ChatViewModel {
        let modelManager = ModelManager()
        let coordinator = AgentCoordinator(modelManager: modelManager)
        let viewModel = ChatViewModel(agentCoordinator: coordinator)

        // Add sample messages
        viewModel.messages = [
            ChatMessage.assistant("Hi! How can I help you today?"),
            ChatMessage.user("I'm feeling overwhelmed"),
            ChatMessage.assistant("I understand. Let's break things down into smaller steps. How about we start with just one simple task?"),
            ChatMessage.user("What should I do first?"),
            ChatMessage(
                role: .assistant,
                content: .taskSuggestion([
                    TaskSuggestionItem(title: "Review medications", estimatedDuration: 300, difficulty: "easy"),
                    TaskSuggestionItem(title: "Plan lunch", estimatedDuration: 600, difficulty: "medium")
                ])
            )
        ]

        return viewModel
    }

    static var emptyPreview: ChatViewModel {
        let modelManager = ModelManager()
        let coordinator = AgentCoordinator(modelManager: modelManager)
        return ChatViewModel(agentCoordinator: coordinator)
    }
}
#endif
