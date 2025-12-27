//
//  MemoryStore.swift
//  ADHDAssistant
//
//  Lightweight persistence for AI context and behavioral patterns
//

import Foundation
import Combine

// MARK: - Memory Store Protocol

protocol MemoryStoreProtocol {
    func saveContext(_ context: AIContext) throws
    func loadContext() -> AIContext
    func clearContext()

    func saveConversationMessage(_ message: ConversationMessage)
    func loadRecentConversation(limit: Int) -> [ConversationMessage]
    func clearConversation()

    func savePattern(_ pattern: TaskCompletionPattern)
    func loadPatterns() -> [TaskCompletionPattern]
    func clearPatterns()

    func updateDailyStats(completedTasks: [UUID], missedTasks: [UUID], mood: MoodLevel?)
    func getDailyStats() -> (completed: [UUID], missed: [UUID], mood: MoodLevel?)

    var contextPublisher: AnyPublisher<AIContext, Never> { get }
}

// MARK: - Memory Store Implementation

class MemoryStore: MemoryStoreProtocol, ObservableObject {
    // MARK: - Singleton

    static let shared = MemoryStore()

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let contextSubject = CurrentValueSubject<AIContext, Never>(AIContext())

    var contextPublisher: AnyPublisher<AIContext, Never> {
        contextSubject.eraseToAnyPublisher()
    }

    @Published private(set) var currentContext: AIContext

    // MARK: - Keys

    private enum Keys {
        static let aiContext = "memoryStore.aiContext"
        static let conversationHistory = "memoryStore.conversationHistory"
        static let completionPatterns = "memoryStore.completionPatterns"
        static let dailyCompletedTasks = "memoryStore.dailyCompletedTasks"
        static let dailyMissedTasks = "memoryStore.dailyMissedTasks"
        static let dailyMood = "memoryStore.dailyMood"
        static let lastResetDate = "memoryStore.lastResetDate"
    }

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.currentContext = AIContext()

        // Load existing context
        self.currentContext = loadContext()
        contextSubject.send(currentContext)

        // Check if we need to reset daily data
        checkAndResetDailyData()
    }

    // MARK: - AI Context Management

    func saveContext(_ context: AIContext) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(context)
            userDefaults.set(data, forKey: Keys.aiContext)

            currentContext = context
            contextSubject.send(context)
        } catch {
            throw MemoryStoreError.encodingFailed(error)
        }
    }

    func loadContext() -> AIContext {
        guard let data = userDefaults.data(forKey: Keys.aiContext) else {
            return AIContext()
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let context = try decoder.decode(AIContext.self, from: data)
            return context
        } catch {
            print("Failed to decode AI context: \(error)")
            return AIContext()
        }
    }

    func clearContext() {
        userDefaults.removeObject(forKey: Keys.aiContext)
        currentContext = AIContext()
        contextSubject.send(currentContext)
    }

    // MARK: - Conversation Management

    func saveConversationMessage(_ message: ConversationMessage) {
        var messages = loadRecentConversation(limit: 50)
        messages.append(message)

        // Keep only last 50 messages
        if messages.count > 50 {
            messages = Array(messages.suffix(50))
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(messages) {
            userDefaults.set(data, forKey: Keys.conversationHistory)
        }

        // Update context
        var updatedContext = currentContext
        updatedContext.recentConversation = messages
        try? saveContext(updatedContext)
    }

    func loadRecentConversation(limit: Int = 10) -> [ConversationMessage] {
        guard let data = userDefaults.data(forKey: Keys.conversationHistory) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let messages = try decoder.decode([ConversationMessage].self, from: data)
            return Array(messages.suffix(limit))
        } catch {
            print("Failed to decode conversation: \(error)")
            return []
        }
    }

    func clearConversation() {
        userDefaults.removeObject(forKey: Keys.conversationHistory)

        var updatedContext = currentContext
        updatedContext.clearConversation()
        try? saveContext(updatedContext)
    }

    // MARK: - Pattern Management

    func savePattern(_ pattern: TaskCompletionPattern) {
        var patterns = loadPatterns()

        // Update existing or add new
        if let index = patterns.firstIndex(where: {
            $0.timeOfDay == pattern.timeOfDay &&
            $0.dayOfWeek == pattern.dayOfWeek &&
            $0.taskType == pattern.taskType
        }) {
            patterns[index] = pattern
        } else {
            patterns.append(pattern)
        }

        // Keep only significant patterns (limit to 100)
        patterns = patterns.filter { $0.isSignificant }
        if patterns.count > 100 {
            patterns = patterns.sorted { $0.qualityScore > $1.qualityScore }
            patterns = Array(patterns.prefix(100))
        }

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(patterns) {
            userDefaults.set(data, forKey: Keys.completionPatterns)
        }

        // Update context
        var updatedContext = currentContext
        updatedContext.taskCompletionPatterns = patterns
        try? saveContext(updatedContext)
    }

    func loadPatterns() -> [TaskCompletionPattern] {
        guard let data = userDefaults.data(forKey: Keys.completionPatterns) else {
            return []
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode([TaskCompletionPattern].self, from: data)
        } catch {
            print("Failed to decode patterns: \(error)")
            return []
        }
    }

    func clearPatterns() {
        userDefaults.removeObject(forKey: Keys.completionPatterns)

        var updatedContext = currentContext
        updatedContext.taskCompletionPatterns = []
        try? saveContext(updatedContext)
    }

    // MARK: - Daily Stats Management

    func updateDailyStats(completedTasks: [UUID], missedTasks: [UUID], mood: MoodLevel?) {
        checkAndResetDailyData()

        let encoder = JSONEncoder()

        if let data = try? encoder.encode(completedTasks) {
            userDefaults.set(data, forKey: Keys.dailyCompletedTasks)
        }

        if let data = try? encoder.encode(missedTasks) {
            userDefaults.set(data, forKey: Keys.dailyMissedTasks)
        }

        if let mood = mood {
            userDefaults.set(mood.rawValue, forKey: Keys.dailyMood)
        }

        // Update context
        var updatedContext = currentContext
        updatedContext.completedTasksToday = completedTasks
        updatedContext.missedTasksToday = missedTasks
        updatedContext.todaysMood = mood
        try? saveContext(updatedContext)
    }

    func getDailyStats() -> (completed: [UUID], missed: [UUID], mood: MoodLevel?) {
        checkAndResetDailyData()

        let decoder = JSONDecoder()

        let completed: [UUID]
        if let data = userDefaults.data(forKey: Keys.dailyCompletedTasks),
           let tasks = try? decoder.decode([UUID].self, from: data) {
            completed = tasks
        } else {
            completed = []
        }

        let missed: [UUID]
        if let data = userDefaults.data(forKey: Keys.dailyMissedTasks),
           let tasks = try? decoder.decode([UUID].self, from: data) {
            missed = tasks
        } else {
            missed = []
        }

        let mood: MoodLevel?
        if let moodRaw = userDefaults.string(forKey: Keys.dailyMood) {
            mood = MoodLevel(rawValue: moodRaw)
        } else {
            mood = nil
        }

        return (completed, missed, mood)
    }

    // MARK: - Daily Reset

    private func checkAndResetDailyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastReset = userDefaults.object(forKey: Keys.lastResetDate) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastReset)

            // If it's a new day, reset
            if today > lastResetDay {
                resetDailyData()
            }
        } else {
            // First run
            userDefaults.set(today, forKey: Keys.lastResetDate)
        }
    }

    private func resetDailyData() {
        userDefaults.removeObject(forKey: Keys.dailyCompletedTasks)
        userDefaults.removeObject(forKey: Keys.dailyMissedTasks)
        userDefaults.removeObject(forKey: Keys.dailyMood)
        userDefaults.set(Date(), forKey: Keys.lastResetDate)

        var updatedContext = currentContext
        updatedContext.resetDailyContext()
        try? saveContext(updatedContext)
    }

    // MARK: - Build AI Context

    func buildAIContext(
        currentTask: Task? = nil,
        taskRepository: TaskRepositoryProtocol? = nil,
        healthRepository: HealthRepositoryProtocol? = nil
    ) async -> AIContext {
        var context = loadContext()

        // Update current task
        context.currentTask = currentTask

        // Load daily stats
        let (completed, missed, mood) = getDailyStats()
        context.completedTasksToday = completed
        context.missedTasksToday = missed
        context.todaysMood = mood

        // Load conversation
        context.recentConversation = loadRecentConversation(limit: 10)

        // Load patterns
        context.taskCompletionPatterns = loadPatterns()

        // Update session info
        context.lastInteractionTime = Date()

        // Get today's health metrics if repository provided
        if let healthRepo = healthRepository {
            let todaysMetrics = (try? await healthRepo.fetchToday()) ?? []
            context.todaysHealthMetrics = todaysMetrics.map { $0.id }
        }

        return context
    }
}

// MARK: - Memory Store Errors

enum MemoryStoreError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

// MARK: - Mock Memory Store for Testing

class MockMemoryStore: MemoryStoreProtocol {
    private var context: AIContext = AIContext()
    private var conversation: [ConversationMessage] = []
    private var patterns: [TaskCompletionPattern] = []
    private var dailyCompleted: [UUID] = []
    private var dailyMissed: [UUID] = []
    private var dailyMood: MoodLevel?

    private let contextSubject = CurrentValueSubject<AIContext, Never>(AIContext())

    var contextPublisher: AnyPublisher<AIContext, Never> {
        contextSubject.eraseToAnyPublisher()
    }

    func saveContext(_ context: AIContext) throws {
        self.context = context
        contextSubject.send(context)
    }

    func loadContext() -> AIContext {
        context
    }

    func clearContext() {
        context = AIContext()
        contextSubject.send(context)
    }

    func saveConversationMessage(_ message: ConversationMessage) {
        conversation.append(message)
        if conversation.count > 50 {
            conversation = Array(conversation.suffix(50))
        }
    }

    func loadRecentConversation(limit: Int) -> [ConversationMessage] {
        Array(conversation.suffix(limit))
    }

    func clearConversation() {
        conversation = []
    }

    func savePattern(_ pattern: TaskCompletionPattern) {
        if let index = patterns.firstIndex(where: {
            $0.timeOfDay == pattern.timeOfDay &&
            $0.dayOfWeek == pattern.dayOfWeek &&
            $0.taskType == pattern.taskType
        }) {
            patterns[index] = pattern
        } else {
            patterns.append(pattern)
        }
    }

    func loadPatterns() -> [TaskCompletionPattern] {
        patterns
    }

    func clearPatterns() {
        patterns = []
    }

    func updateDailyStats(completedTasks: [UUID], missedTasks: [UUID], mood: MoodLevel?) {
        dailyCompleted = completedTasks
        dailyMissed = missedTasks
        dailyMood = mood
    }

    func getDailyStats() -> (completed: [UUID], missed: [UUID], mood: MoodLevel?) {
        (dailyCompleted, dailyMissed, dailyMood)
    }
}
