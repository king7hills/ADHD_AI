//
//  AgentCoordinator.swift
//  ADHDAssistant
//
//  Coordinates all AI agents and routes requests to appropriate specialists
//

import Foundation
import Combine

// MARK: - Agent Request Types

enum AgentRequest {
    case breakdownGoal(goal: String, deadline: Date?)
    case scheduleTask(task: String, preferredTime: Date?, duration: TimeInterval)
    case checkBehavior
    case healthCheck
    case motivate(trigger: MotivationTrigger)
    case analyzePattern(timeRange: TimeInterval)
    case quickAdvice(question: String)
}

// MARK: - Agent Coordinator

@MainActor
final class AgentCoordinator: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isProcessing = false
    @Published private(set) var lastResponse: AgentResponse?
    @Published private(set) var activeAgents: Set<String> = []

    // MARK: - Dependencies

    private let modelManager: ModelManager
    private var sharedContext: AIContext

    // MARK: - Agents

    private lazy var taskBreakdownAgent: TaskBreakdownAgent = {
        TaskBreakdownAgent(modelManager: modelManager)
    }()

    private lazy var calendarAgent: CalendarAgent = {
        CalendarAgent(modelManager: modelManager)
    }()

    private lazy var behaviorMonitorAgent: BehaviorMonitorAgent = {
        BehaviorMonitorAgent(modelManager: modelManager)
    }()

    private lazy var healthAgent: HealthAgent = {
        HealthAgent(modelManager: modelManager)
    }()

    private lazy var motivationAgent: MotivationAgent = {
        MotivationAgent(modelManager: modelManager)
    }()

    // MARK: - Request Queue

    private var requestQueue: [AgentRequest] = []
    private var isProcessingQueue = false

    // MARK: - Initialization

    init(modelManager: ModelManager, initialContext: AIContext = AIContext()) {
        self.modelManager = modelManager
        self.sharedContext = initialContext
    }

    // MARK: - Context Management

    func updateContext(_ context: AIContext) {
        self.sharedContext = context
    }

    func updateContext(transform: (inout AIContext) -> Void) {
        transform(&sharedContext)
    }

    func getContext() -> AIContext {
        sharedContext
    }

    // MARK: - Request Processing

    func process(_ request: AgentRequest) async throws -> AgentResponse {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await routeRequest(request)
            lastResponse = response

            // Update context based on response
            updateContextFromResponse(response)

            return response
        } catch {
            let errorResponse = AgentResponse(
                agentType: "coordinator",
                success: false,
                data: .error(ErrorData(
                    code: "processing_failed",
                    message: error.localizedDescription,
                    details: nil
                ))
            )
            lastResponse = errorResponse
            throw error
        }
    }

    /// Process multiple requests in sequence
    func processBatch(_ requests: [AgentRequest]) async throws -> [AgentResponse] {
        var responses: [AgentResponse] = []

        for request in requests {
            let response = try await process(request)
            responses.append(response)
        }

        return responses
    }

    /// Queue a request for asynchronous processing
    func queueRequest(_ request: AgentRequest) {
        requestQueue.append(request)
        Task {
            await processQueue()
        }
    }

    private func processQueue() async {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true
        defer { isProcessingQueue = false }

        while !requestQueue.isEmpty {
            let request = requestQueue.removeFirst()
            try? await process(request)
        }
    }

    // MARK: - Request Routing

    private func routeRequest(_ request: AgentRequest) async throws -> AgentResponse {
        switch request {
        case .breakdownGoal(let goal, let deadline):
            return try await processTaskBreakdown(goal: goal, deadline: deadline)

        case .scheduleTask(let task, let preferredTime, let duration):
            return try await processScheduling(
                task: task,
                preferredTime: preferredTime,
                duration: duration
            )

        case .checkBehavior:
            return try await processBehaviorCheck()

        case .healthCheck:
            return try await processHealthCheck()

        case .motivate(let trigger):
            return try await processMotivation(trigger: trigger)

        case .analyzePattern(let timeRange):
            return try await processPatternAnalysis(timeRange: timeRange)

        case .quickAdvice(let question):
            return try await processQuickAdvice(question: question)
        }
    }

    // MARK: - Specialized Processing

    private func processTaskBreakdown(goal: String, deadline: Date?) async throws -> AgentResponse {
        activeAgents.insert("task_breakdown")
        defer { activeAgents.remove("task_breakdown") }

        // Update context with goal info
        sharedContext.customContext["current_goal"] = goal
        if let deadline = deadline {
            sharedContext.customContext["deadline"] = ISO8601DateFormatter().string(from: deadline)
        }

        return try await taskBreakdownAgent.process(context: sharedContext)
    }

    private func processScheduling(
        task: String,
        preferredTime: Date?,
        duration: TimeInterval
    ) async throws -> AgentResponse {
        activeAgents.insert("calendar")
        defer { activeAgents.remove("calendar") }

        sharedContext.customContext["task_to_schedule"] = task
        sharedContext.customContext["duration"] = "\(Int(duration / 60))"
        if let time = preferredTime {
            sharedContext.customContext["preferred_time"] = ISO8601DateFormatter().string(from: time)
        }

        return try await calendarAgent.process(context: sharedContext)
    }

    private func processBehaviorCheck() async throws -> AgentResponse {
        activeAgents.insert("behavior_monitor")
        defer { activeAgents.remove("behavior_monitor") }

        return try await behaviorMonitorAgent.process(context: sharedContext)
    }

    private func processHealthCheck() async throws -> AgentResponse {
        activeAgents.insert("health")
        defer { activeAgents.remove("health") }

        return try await healthAgent.process(context: sharedContext)
    }

    private func processMotivation(trigger: MotivationTrigger) async throws -> AgentResponse {
        activeAgents.insert("motivation")
        defer { activeAgents.remove("motivation") }

        sharedContext.customContext["motivation_trigger"] = trigger.rawValue

        return try await motivationAgent.process(context: sharedContext)
    }

    private func processPatternAnalysis(timeRange: TimeInterval) async throws -> AgentResponse {
        // Pattern analysis involves multiple agents
        activeAgents.insert("pattern_analysis")
        defer { activeAgents.remove("pattern_analysis") }

        // Coordinate between behavior and health agents
        let behaviorResponse = try await behaviorMonitorAgent.process(context: sharedContext)
        let healthResponse = try await healthAgent.process(context: sharedContext)

        // Combine insights
        return AgentResponse(
            agentType: "pattern_analysis",
            success: true,
            data: .intervention(InterventionData(
                level: "info",
                message: "Pattern analysis complete",
                suggestedAction: "Review behavior and health insights"
            )),
            metadata: [
                "behavior_status": "\(behaviorResponse.success)",
                "health_status": "\(healthResponse.success)",
                "time_range": "\(Int(timeRange / 3600))h"
            ]
        )
    }

    private func processQuickAdvice(question: String) async throws -> AgentResponse {
        // Use motivation agent for quick, encouraging responses
        activeAgents.insert("quick_advice")
        defer { activeAgents.remove("quick_advice") }

        sharedContext.customContext["question"] = question

        return try await motivationAgent.process(context: sharedContext)
    }

    // MARK: - Agent Communication

    /// Coordinate between multiple agents for complex requests
    func coordinateAgents(
        _ agentTypes: [AgentCapability],
        for context: AIContext
    ) async throws -> [AgentResponse] {
        var responses: [AgentResponse] = []

        for capability in agentTypes {
            let response = try await routeToAgent(capability: capability, context: context)
            responses.append(response)

            // Allow agents to inform each other
            if case .tasks(let tasks) = response.data {
                // Task breakdown can inform scheduling
                if agentTypes.contains(.scheduling) {
                    sharedContext.customContext["generated_tasks"] = "\(tasks.count)"
                }
            }
        }

        return responses
    }

    private func routeToAgent(
        capability: AgentCapability,
        context: AIContext
    ) async throws -> AgentResponse {
        switch capability {
        case .taskBreakdown:
            return try await taskBreakdownAgent.process(context: context)
        case .scheduling:
            return try await calendarAgent.process(context: context)
        case .behaviorMonitoring:
            return try await behaviorMonitorAgent.process(context: context)
        case .healthManagement:
            return try await healthAgent.process(context: context)
        case .motivation:
            return try await motivationAgent.process(context: context)
        default:
            throw AgentError.processingFailed("Capability not implemented: \(capability)")
        }
    }

    // MARK: - Context Updates

    private func updateContextFromResponse(_ response: AgentResponse) {
        switch response.data {
        case .tasks(let tasks):
            // Update recent tasks
            let taskTitles = tasks.map { $0.title }
            sharedContext.recentTasks = Array(taskTitles.prefix(5))

        case .motivation:
            // Update motivation metadata
            sharedContext.customContext["last_motivation"] = ISO8601DateFormatter().string(from: Date())

        case .healthReminder:
            // Track health reminder delivery
            sharedContext.customContext["last_health_reminder"] = ISO8601DateFormatter().string(from: Date())

        default:
            break
        }
    }

    // MARK: - Agent Status

    func getAgentStatus() -> AgentStatus {
        AgentStatus(
            isProcessing: isProcessing,
            activeAgents: Array(activeAgents),
            queuedRequests: requestQueue.count,
            lastResponseTime: lastResponse?.timestamp,
            modelStatus: modelManager.getStatus()
        )
    }

    // MARK: - Warm-up

    func warmUpAgents() async throws {
        // Pre-load commonly used agents
        try await taskBreakdownAgent.warmUp()
        try await motivationAgent.warmUp()
        print("✓ AgentCoordinator: Agents warmed up")
    }

    func coolDownAgents() async throws {
        try await taskBreakdownAgent.coolDown()
        try await calendarAgent.coolDown()
        try await behaviorMonitorAgent.coolDown()
        try await healthAgent.coolDown()
        try await motivationAgent.coolDown()
        print("✓ AgentCoordinator: Agents cooled down")
    }
}

// MARK: - Agent Status

struct AgentStatus {
    let isProcessing: Bool
    let activeAgents: [String]
    let queuedRequests: Int
    let lastResponseTime: Date?
    let modelStatus: ModelManagerStatus

    var description: String {
        """
        Processing: \(isProcessing)
        Active: \(activeAgents.joined(separator: ", "))
        Queued: \(queuedRequests)
        Models: \(modelStatus.statusDescription)
        """
    }
}

// MARK: - Convenience Extensions

extension AgentCoordinator {
    /// Quick task breakdown without deadline
    func breakdownGoal(_ goal: String) async throws -> AgentResponse {
        try await process(.breakdownGoal(goal: goal, deadline: nil))
    }

    /// Quick motivation without specific trigger
    func motivate() async throws -> AgentResponse {
        try await process(.motivate(trigger: .encouragement))
    }

    /// Check if user needs health reminder
    func checkHealth() async throws -> AgentResponse {
        try await process(.healthCheck)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AgentCoordinator {
    static var preview: AgentCoordinator {
        let modelManager = ModelManager()
        let context = AIContext(
            currentEnergy: .medium,
            timeOfDay: .morning,
            currentStreak: 3
        )
        return AgentCoordinator(modelManager: modelManager, initialContext: context)
    }
}
#endif
