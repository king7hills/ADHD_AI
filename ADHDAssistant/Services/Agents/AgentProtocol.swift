//
//  AgentProtocol.swift
//  ADHDAssistant
//
//  Base protocol for all AI agents in the system
//

import Foundation

// MARK: - Agent Capabilities

/// Defines the capabilities each agent possesses
enum AgentCapability: String, Codable, CaseIterable {
    case taskBreakdown = "task_breakdown"
    case scheduling = "scheduling"
    case behaviorMonitoring = "behavior_monitoring"
    case healthManagement = "health_management"
    case motivation = "motivation"
    case conflictResolution = "conflict_resolution"
    case contextAwareness = "context_awareness"
    case patternRecognition = "pattern_recognition"
}

// MARK: - Agent Priority

/// Priority levels for agent processing
enum AgentPriority: Int, Comparable {
    case critical = 0
    case high = 1
    case medium = 2
    case low = 3

    static func < (lhs: AgentPriority, rhs: AgentPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - AI Context

/// Shared context that agents use for decision-making
struct AIContext: Codable {
    // User state
    var currentEnergy: EnergyLevel?
    var timeOfDay: TimeOfDay
    var recentTasks: [String]
    var currentStreak: Int

    // Health context
    var lastBloodSugarCheck: Date?
    var lastMealTime: Date?
    var medicationTaken: Bool

    // Behavioral context
    var screenTimeToday: TimeInterval?
    var lastProductiveActivity: Date?
    var recentCompletions: Int

    // Additional metadata
    var customContext: [String: String]

    init(
        currentEnergy: EnergyLevel? = nil,
        timeOfDay: TimeOfDay = .morning,
        recentTasks: [String] = [],
        currentStreak: Int = 0,
        lastBloodSugarCheck: Date? = nil,
        lastMealTime: Date? = nil,
        medicationTaken: Bool = false,
        screenTimeToday: TimeInterval? = nil,
        lastProductiveActivity: Date? = nil,
        recentCompletions: Int = 0,
        customContext: [String: String] = [:]
    ) {
        self.currentEnergy = currentEnergy
        self.timeOfDay = timeOfDay
        self.recentTasks = recentTasks
        self.currentStreak = currentStreak
        self.lastBloodSugarCheck = lastBloodSugarCheck
        self.lastMealTime = lastMealTime
        self.medicationTaken = medicationTaken
        self.screenTimeToday = screenTimeToday
        self.lastProductiveActivity = lastProductiveActivity
        self.recentCompletions = recentCompletions
        self.customContext = customContext
    }
}

// MARK: - Supporting Types

enum EnergyLevel: String, Codable {
    case veryLow = "very_low"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
}

enum TimeOfDay: String, Codable {
    case earlyMorning = "early_morning"    // 4am-7am
    case morning = "morning"                // 7am-11am
    case midday = "midday"                  // 11am-2pm
    case afternoon = "afternoon"            // 2pm-5pm
    case evening = "evening"                // 5pm-8pm
    case night = "night"                    // 8pm-11pm
    case lateNight = "late_night"          // 11pm-4am

    init(from date: Date = Date()) {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 4..<7:
            self = .earlyMorning
        case 7..<11:
            self = .morning
        case 11..<14:
            self = .midday
        case 14..<17:
            self = .afternoon
        case 17..<20:
            self = .evening
        case 20..<23:
            self = .night
        default:
            self = .lateNight
        }
    }
}

// MARK: - Agent Protocol

/// Base protocol that all AI agents must conform to
protocol BaseAgent {
    /// The capabilities this agent provides
    var capabilities: Set<AgentCapability> { get }

    /// Priority level for this agent's processing
    var priority: AgentPriority { get }

    /// Reference to the model runner for AI inference
    var modelRunner: LFMServiceProtocol { get }

    /// Process a request with the given context
    /// - Parameter context: The current AI context with user state
    /// - Returns: Agent-specific response
    /// - Throws: AgentError if processing fails
    func process(context: AIContext) async throws -> AgentResponse

    /// Optional: Warm up the agent (load models, prepare resources)
    func warmUp() async throws

    /// Optional: Cool down the agent (unload models, free resources)
    func coolDown() async throws
}

// MARK: - Default Implementations

extension BaseAgent {
    /// Default warm-up does nothing
    func warmUp() async throws {
        // Agents can override if they need startup logic
    }

    /// Default cool-down does nothing
    func coolDown() async throws {
        // Agents can override if they need cleanup logic
    }
}

// MARK: - Agent Response

/// Unified response structure from any agent
struct AgentResponse: Codable {
    let agentType: String
    let timestamp: Date
    let success: Bool
    let data: ResponseData
    let metadata: [String: String]

    init(
        agentType: String,
        success: Bool,
        data: ResponseData,
        metadata: [String: String] = [:]
    ) {
        self.agentType = agentType
        self.timestamp = Date()
        self.success = success
        self.data = data
        self.metadata = metadata
    }
}

// MARK: - Response Data Types

enum ResponseData: Codable {
    case tasks([TaskData])
    case scheduledEvents([ScheduledEventData])
    case intervention(InterventionData)
    case healthReminder(HealthReminderData)
    case motivation(MotivationData)
    case error(ErrorData)

    enum CodingKeys: String, CodingKey {
        case type
        case tasks
        case events
        case intervention
        case healthReminder
        case motivation
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "tasks":
            let tasks = try container.decode([TaskData].self, forKey: .tasks)
            self = .tasks(tasks)
        case "events":
            let events = try container.decode([ScheduledEventData].self, forKey: .events)
            self = .scheduledEvents(events)
        case "intervention":
            let intervention = try container.decode(InterventionData.self, forKey: .intervention)
            self = .intervention(intervention)
        case "healthReminder":
            let reminder = try container.decode(HealthReminderData.self, forKey: .healthReminder)
            self = .healthReminder(reminder)
        case "motivation":
            let motivation = try container.decode(MotivationData.self, forKey: .motivation)
            self = .motivation(motivation)
        case "error":
            let error = try container.decode(ErrorData.self, forKey: .error)
            self = .error(error)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .tasks(let tasks):
            try container.encode("tasks", forKey: .type)
            try container.encode(tasks, forKey: .tasks)
        case .scheduledEvents(let events):
            try container.encode("events", forKey: .type)
            try container.encode(events, forKey: .events)
        case .intervention(let intervention):
            try container.encode("intervention", forKey: .type)
            try container.encode(intervention, forKey: .intervention)
        case .healthReminder(let reminder):
            try container.encode("healthReminder", forKey: .type)
            try container.encode(reminder, forKey: .healthReminder)
        case .motivation(let motivation):
            try container.encode("motivation", forKey: .type)
            try container.encode(motivation, forKey: .motivation)
        case .error(let error):
            try container.encode("error", forKey: .type)
            try container.encode(error, forKey: .error)
        }
    }
}

// MARK: - Data Structures

struct TaskData: Codable {
    let title: String
    let estimatedDuration: TimeInterval
    let startTrigger: String
    let difficulty: TaskDifficulty
    let order: Int
}

enum TaskDifficulty: String, Codable {
    case veryEasy = "very_easy"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
}

struct ScheduledEventData: Codable {
    let title: String
    let startTime: Date
    let duration: TimeInterval
    let bufferBefore: TimeInterval
    let bufferAfter: TimeInterval
    let hasConflict: Bool
}

struct InterventionData: Codable {
    let level: String
    let message: String
    let suggestedAction: String?
}

struct HealthReminderData: Codable {
    let type: String
    let message: String
    let urgency: String
    let dueTime: Date?
}

struct MotivationData: Codable {
    let message: String
    let trigger: String
    let tone: String
}

struct ErrorData: Codable {
    let code: String
    let message: String
    let details: String?
}

// MARK: - Agent Errors

enum AgentError: LocalizedError {
    case processingFailed(String)
    case modelUnavailable
    case invalidContext
    case timeout
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .processingFailed(let reason):
            return "Agent processing failed: \(reason)"
        case .modelUnavailable:
            return "Required AI model is not available"
        case .invalidContext:
            return "Invalid or incomplete context provided"
        case .timeout:
            return "Agent processing timed out"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
