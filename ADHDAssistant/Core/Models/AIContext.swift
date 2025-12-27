//
//  AIContext.swift
//  ADHDAssistant
//
//  Context management for AI assistant conversations and behavior
//

import Foundation

/// User's current mood level
enum MoodLevel: String, Codable, CaseIterable {
    case great
    case good
    case okay
    case struggling
    case overwhelmed

    var displayName: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .great: return "🌟"
        case .good: return "😊"
        case .okay: return "😐"
        case .struggling: return "😔"
        case .overwhelmed: return "😰"
        }
    }

    var sortOrder: Int {
        switch self {
        case .great: return 0
        case .good: return 1
        case .okay: return 2
        case .struggling: return 3
        case .overwhelmed: return 4
        }
    }

    /// Suggested intervention intensity based on mood
    var suggestedInterventionIntensity: Double {
        switch self {
        case .great, .good: return 0.5
        case .okay: return 0.7
        case .struggling: return 0.85
        case .overwhelmed: return 1.0
        }
    }
}

/// Pattern of task completion for learning user behavior
struct TaskCompletionPattern: Codable, Hashable {
    var timeOfDay: TimeOfDay
    var dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    var taskType: String
    var successRate: Double // 0.0 to 1.0
    var averageDuration: TimeInterval
    var sampleSize: Int

    init(
        timeOfDay: TimeOfDay,
        dayOfWeek: Int,
        taskType: String,
        successRate: Double,
        averageDuration: TimeInterval,
        sampleSize: Int
    ) {
        self.timeOfDay = timeOfDay
        self.dayOfWeek = dayOfWeek
        self.taskType = taskType
        self.successRate = successRate
        self.averageDuration = averageDuration
        self.sampleSize = sampleSize
    }

    /// Whether this pattern is statistically significant
    var isSignificant: Bool {
        sampleSize >= 5
    }

    /// Quality score for this pattern (0.0 to 1.0)
    var qualityScore: Double {
        let recencyWeight = min(Double(sampleSize) / 20.0, 1.0)
        return successRate * recencyWeight
    }
}

/// Conversation message for context
struct ConversationMessage: Codable, Hashable, Identifiable {
    let id: UUID
    var role: Role
    var content: String
    var timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
        case system

        var displayName: String {
            rawValue.capitalized
        }
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

/// AI Context for maintaining conversation and behavioral state
struct AIContext: Codable, Hashable {
    // MARK: - Short Term Context (current session)

    var currentTask: Task?
    var recentConversation: [ConversationMessage]
    var sessionStartTime: Date
    var lastInteractionTime: Date

    // MARK: - Medium Term Context (today/recent)

    var completedTasksToday: [UUID]
    var missedTasksToday: [UUID]
    var currentStreak: Int
    var todaysMood: MoodLevel?
    var todaysHealthMetrics: [UUID]

    // MARK: - Long Term Context (persistent patterns)

    var userProfileId: UUID?
    var taskCompletionPatterns: [TaskCompletionPattern]
    var averageEstimationAccuracy: Double
    var preferredInterventionStyle: InterventionStyle
    var totalTasksCompleted: Int
    var totalTasksCreated: Int

    // MARK: - Metadata

    var lastUpdatedAt: Date
    var contextVersion: Int

    init(
        currentTask: Task? = nil,
        recentConversation: [ConversationMessage] = [],
        sessionStartTime: Date = Date(),
        lastInteractionTime: Date = Date(),
        completedTasksToday: [UUID] = [],
        missedTasksToday: [UUID] = [],
        currentStreak: Int = 0,
        todaysMood: MoodLevel? = nil,
        todaysHealthMetrics: [UUID] = [],
        userProfileId: UUID? = nil,
        taskCompletionPatterns: [TaskCompletionPattern] = [],
        averageEstimationAccuracy: Double = 1.0,
        preferredInterventionStyle: InterventionStyle = .moderate,
        totalTasksCompleted: Int = 0,
        totalTasksCreated: Int = 0,
        lastUpdatedAt: Date = Date(),
        contextVersion: Int = 1
    ) {
        self.currentTask = currentTask
        self.recentConversation = recentConversation
        self.sessionStartTime = sessionStartTime
        self.lastInteractionTime = lastInteractionTime
        self.completedTasksToday = completedTasksToday
        self.missedTasksToday = missedTasksToday
        self.currentStreak = currentStreak
        self.todaysMood = todaysMood
        self.todaysHealthMetrics = todaysHealthMetrics
        self.userProfileId = userProfileId
        self.taskCompletionPatterns = taskCompletionPatterns
        self.averageEstimationAccuracy = averageEstimationAccuracy
        self.preferredInterventionStyle = preferredInterventionStyle
        self.totalTasksCompleted = totalTasksCompleted
        self.totalTasksCreated = totalTasksCreated
        self.lastUpdatedAt = lastUpdatedAt
        self.contextVersion = contextVersion
    }

    // MARK: - Computed Properties

    /// Session duration in seconds
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }

    /// Time since last interaction
    var timeSinceLastInteraction: TimeInterval {
        Date().timeIntervalSince(lastInteractionTime)
    }

    /// Completion rate for today
    var todaysCompletionRate: Double {
        let totalTasks = completedTasksToday.count + missedTasksToday.count
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasksToday.count) / Double(totalTasks)
    }

    /// Overall completion rate
    var overallCompletionRate: Double {
        guard totalTasksCreated > 0 else { return 0.0 }
        return Double(totalTasksCompleted) / Double(totalTasksCreated)
    }

    /// Whether the session is still active (less than 30 minutes since last interaction)
    var isSessionActive: Bool {
        timeSinceLastInteraction < 1800
    }

    /// Number of messages in conversation
    var conversationLength: Int {
        recentConversation.count
    }

    /// Recent conversation (last 10 messages)
    var recentMessages: [ConversationMessage] {
        Array(recentConversation.suffix(10))
    }

    // MARK: - Methods

    /// Update context with new information
    mutating func updateContext(
        currentTask: Task? = nil,
        mood: MoodLevel? = nil,
        completedTask: UUID? = nil,
        missedTask: UUID? = nil
    ) {
        if let task = currentTask {
            self.currentTask = task
        }

        if let mood = mood {
            self.todaysMood = mood
        }

        if let taskId = completedTask {
            if !completedTasksToday.contains(taskId) {
                completedTasksToday.append(taskId)
            }
            totalTasksCompleted += 1
        }

        if let taskId = missedTask {
            if !missedTasksToday.contains(taskId) {
                missedTasksToday.append(taskId)
            }
        }

        lastInteractionTime = Date()
        lastUpdatedAt = Date()
    }

    /// Add a message to the conversation
    mutating func addMessage(role: ConversationMessage.Role, content: String) {
        let message = ConversationMessage(role: role, content: content)
        recentConversation.append(message)

        // Keep only last 50 messages to prevent excessive memory usage
        if recentConversation.count > 50 {
            recentConversation = Array(recentConversation.suffix(50))
        }

        lastInteractionTime = Date()
        lastUpdatedAt = Date()
    }

    /// Clear conversation history
    mutating func clearConversation() {
        recentConversation.removeAll()
        lastUpdatedAt = Date()
    }

    /// Start a new session
    mutating func startNewSession() {
        sessionStartTime = Date()
        lastInteractionTime = Date()
        currentTask = nil
        recentConversation.removeAll()
        lastUpdatedAt = Date()
    }

    /// Reset daily context (call at start of new day)
    mutating func resetDailyContext() {
        completedTasksToday.removeAll()
        missedTasksToday.removeAll()
        todaysMood = nil
        todaysHealthMetrics.removeAll()
        lastUpdatedAt = Date()
    }

    /// Add or update a task completion pattern
    mutating func updatePattern(_ pattern: TaskCompletionPattern) {
        if let index = taskCompletionPatterns.firstIndex(where: {
            $0.timeOfDay == pattern.timeOfDay &&
            $0.dayOfWeek == pattern.dayOfWeek &&
            $0.taskType == pattern.taskType
        }) {
            taskCompletionPatterns[index] = pattern
        } else {
            taskCompletionPatterns.append(pattern)
        }
        lastUpdatedAt = Date()
    }

    /// Get best time for a specific task type
    func bestTimeForTask(type: String) -> TimeOfDay? {
        let relevantPatterns = taskCompletionPatterns.filter { $0.taskType == type && $0.isSignificant }
        return relevantPatterns.max(by: { $0.qualityScore < $1.qualityScore })?.timeOfDay
    }

    /// Update estimation accuracy
    mutating func updateEstimationAccuracy(newAccuracy: Double) {
        // Weighted average with more weight on recent accuracy
        averageEstimationAccuracy = (averageEstimationAccuracy * 0.7) + (newAccuracy * 0.3)
        lastUpdatedAt = Date()
    }

    /// Generate a summary of the context
    func summarize() -> String {
        var summary = "Session Summary:\n"
        summary += "- Session duration: \(Int(sessionDuration / 60)) minutes\n"
        summary += "- Tasks completed today: \(completedTasksToday.count)\n"
        summary += "- Tasks missed today: \(missedTasksToday.count)\n"
        summary += "- Current streak: \(currentStreak) days\n"

        if let mood = todaysMood {
            summary += "- Today's mood: \(mood.displayName)\n"
        }

        summary += "- Overall completion rate: \(String(format: "%.1f%%", overallCompletionRate * 100))\n"

        return summary
    }

    /// Convert context to prompt-friendly format
    func toPromptContext() -> String {
        var context = ""

        // User state
        if let mood = todaysMood {
            context += "User is feeling \(mood.displayName.lowercased()) today.\n"
        }

        // Today's progress
        context += "Today's progress: \(completedTasksToday.count) tasks completed, \(missedTasksToday.count) tasks missed.\n"

        // Current streak
        if currentStreak > 0 {
            context += "Currently on a \(currentStreak)-day streak.\n"
        }

        // Current task
        if let task = currentTask {
            context += "Currently working on: \(task.title)\n"
        }

        // Completion patterns
        let significantPatterns = taskCompletionPatterns.filter { $0.isSignificant }
        if !significantPatterns.isEmpty {
            context += "User performs best during: "
            let bestTimes = significantPatterns.sorted { $0.qualityScore > $1.qualityScore }
                .prefix(3)
                .map { $0.timeOfDay.displayName }
            context += bestTimes.joined(separator: ", ") + ".\n"
        }

        // Estimation accuracy
        if averageEstimationAccuracy != 1.0 {
            let accuracy = averageEstimationAccuracy
            if accuracy < 0.8 {
                context += "User tends to underestimate task duration.\n"
            } else if accuracy > 1.2 {
                context += "User tends to overestimate task duration.\n"
            }
        }

        return context
    }
}

// MARK: - Sample Data

#if DEBUG
extension AIContext {
    static let sample = AIContext(
        currentTask: Task.sample,
        recentConversation: [
            ConversationMessage(role: .user, content: "What should I work on next?"),
            ConversationMessage(role: .assistant, content: "Based on your schedule, I recommend starting with 'Review morning medications' - it's a high priority task scheduled for soon."),
            ConversationMessage(role: .user, content: "I'm feeling a bit overwhelmed today."),
            ConversationMessage(role: .assistant, content: "I understand. Let's break things down into smaller steps. How about we start with just one simple task?")
        ],
        completedTasksToday: [UUID(), UUID(), UUID()],
        missedTasksToday: [UUID()],
        currentStreak: 7,
        todaysMood: .okay,
        taskCompletionPatterns: [
            TaskCompletionPattern(
                timeOfDay: .morning,
                dayOfWeek: 2,
                taskType: "health",
                successRate: 0.85,
                averageDuration: 900,
                sampleSize: 12
            ),
            TaskCompletionPattern(
                timeOfDay: .afternoon,
                dayOfWeek: 2,
                taskType: "work",
                successRate: 0.72,
                averageDuration: 2400,
                sampleSize: 8
            )
        ],
        averageEstimationAccuracy: 0.92,
        preferredInterventionStyle: .moderate,
        totalTasksCompleted: 145,
        totalTasksCreated: 178
    )
}
#endif
