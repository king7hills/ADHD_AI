//
//  ChatMessage.swift
//  ADHDAssistant
//
//  Chat message model for conversational interface
//

import Foundation

// MARK: - Message Role

enum MessageRole: String, Codable, Equatable {
    case user
    case assistant
    case system

    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Assistant"
        case .system: return "System"
        }
    }
}

// MARK: - Content Type

enum MessageContentType: Codable, Equatable {
    case text(String)
    case taskSuggestion([TaskSuggestionItem])
    case healthReminder(HealthReminderItem)
    case motivation(String)
    case error(String)

    var textContent: String {
        switch self {
        case .text(let text):
            return text
        case .taskSuggestion(let items):
            return "I've suggested \(items.count) tasks for you."
        case .healthReminder(let item):
            return item.message
        case .motivation(let message):
            return message
        case .error(let message):
            return message
        }
    }
}

// MARK: - Supporting Types

struct TaskSuggestionItem: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let estimatedDuration: TimeInterval
    let difficulty: String

    init(id: UUID = UUID(), title: String, estimatedDuration: TimeInterval, difficulty: String = "medium") {
        self.id = id
        self.title = title
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
    }
}

struct HealthReminderItem: Codable, Equatable, Identifiable {
    let id: UUID
    let message: String
    let type: String
    let urgency: String

    init(id: UUID = UUID(), message: String, type: String, urgency: String = "normal") {
        self.id = id
        self.message = message
        self.type = type
        self.urgency = urgency
    }
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    var content: MessageContentType
    var timestamp: Date
    var isStreaming: Bool
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: MessageContentType,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.metadata = metadata
    }

    // MARK: - Convenience Initializers

    static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: .user, content: .text(text))
    }

    static func assistant(_ text: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: .text(text))
    }

    static func system(_ text: String) -> ChatMessage {
        ChatMessage(role: .system, content: .text(text))
    }

    static func motivation(_ text: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: .motivation(text))
    }

    static func error(_ text: String) -> ChatMessage {
        ChatMessage(role: .system, content: .error(text))
    }

    // MARK: - Computed Properties

    var isUser: Bool {
        role == .user
    }

    var isAssistant: Bool {
        role == .assistant
    }

    var isSystem: Bool {
        role == .system
    }

    var displayText: String {
        content.textContent
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Sample Data

#if DEBUG
extension ChatMessage {
    static let sampleUser = ChatMessage.user("What should I work on next?")

    static let sampleAssistant = ChatMessage.assistant("Based on your schedule, I recommend starting with 'Review morning medications' - it's a high priority task scheduled for soon.")

    static let sampleMotivation = ChatMessage.motivation("You're doing great! That's 3 tasks completed today. Keep up the momentum!")

    static let sampleTaskSuggestion = ChatMessage(
        role: .assistant,
        content: .taskSuggestion([
            TaskSuggestionItem(title: "Review medications", estimatedDuration: 300, difficulty: "easy"),
            TaskSuggestionItem(title: "Plan lunch", estimatedDuration: 600, difficulty: "medium"),
            TaskSuggestionItem(title: "Take a short walk", estimatedDuration: 900, difficulty: "easy")
        ])
    )

    static let sampleHealthReminder = ChatMessage(
        role: .assistant,
        content: .healthReminder(HealthReminderItem(
            message: "Time to check your blood sugar",
            type: "blood_sugar",
            urgency: "high"
        ))
    )

    static let sampleConversation: [ChatMessage] = [
        ChatMessage.user("I'm feeling overwhelmed today"),
        ChatMessage.assistant("I understand. Let's break things down into smaller steps. How about we start with just one simple task?"),
        ChatMessage.user("Okay, what do you suggest?"),
        sampleTaskSuggestion,
        ChatMessage.user("I'll start with the medications"),
        ChatMessage.motivation("Great choice! Starting with the easiest task helps build momentum. You've got this!")
    ]
}
#endif
