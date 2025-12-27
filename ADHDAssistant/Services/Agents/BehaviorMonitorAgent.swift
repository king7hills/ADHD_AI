//
//  BehaviorMonitorAgent.swift
//  ADHDAssistant
//
//  Monitors behavior patterns and provides supportive interventions
//

import Foundation

// MARK: - Intervention Level

enum InterventionLevel: String, Codable {
    case gentle = "gentle"
    case moderate = "moderate"
    case assertive = "assertive"
    case critical = "critical"

    var priority: Int {
        switch self {
        case .gentle: return 1
        case .moderate: return 2
        case .assertive: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Detected Pattern

struct DetectedPattern {
    let type: PatternType
    let duration: TimeInterval
    let severity: InterventionLevel
    let context: String

    enum PatternType {
        case excessiveScreenTime(app: String?)
        case taskAvoidance
        case hyperfocus(activity: String)
        case skippedSelfCare(type: SelfCareType)
        case analysisParalysis
        case distractionCycle

        var description: String {
            switch self {
            case .excessiveScreenTime(let app):
                return app != nil ? "Scrolling on \(app!)" : "Extended screen time"
            case .taskAvoidance:
                return "Task avoidance pattern"
            case .hyperfocus(let activity):
                return "Hyperfocus on \(activity)"
            case .skippedSelfCare(let type):
                return "Skipped \(type.rawValue)"
            case .analysisParalysis:
                return "Over-planning without action"
            case .distractionCycle:
                return "Frequent task switching"
            }
        }
    }

    enum SelfCareType: String {
        case meal = "meal"
        case hydration = "hydration"
        case movement = "movement"
        case medication = "medication"
        case rest = "rest"
    }
}

// MARK: - Behavior Monitor Agent

@MainActor
final class BehaviorMonitorAgent: BaseAgent {
    // MARK: - BaseAgent Protocol

    let capabilities: Set<AgentCapability> = [.behaviorMonitoring, .patternRecognition]
    let priority: AgentPriority = .medium

    var modelRunner: LFMServiceProtocol {
        modelService ?? MockLFMService()
    }

    // MARK: - Properties

    private let modelManager: ModelManager
    private var modelService: LFMService?

    // Pattern detection thresholds
    private let screenTimeThresholdMinutes = 45.0
    private let taskAvoidanceThresholdHours = 2.0
    private let hyperfocusThresholdHours = 3.0
    private let selfCareReminderHours = 4.0

    // Tracking
    private var lastInterventionTime: Date?
    private var interventionCount = 0
    private let maxInterventionsPerHour = 3

    // MARK: - Initialization

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    // MARK: - BaseAgent Implementation

    func process(context: AIContext) async throws -> AgentResponse {
        do {
            // Get medium model for pattern recognition
            let service = try await modelManager.getModelForTask(.behaviorAnalysis)
            self.modelService = service

            // Detect patterns
            let detectedPatterns = detectPatterns(context: context)

            // Determine most critical pattern
            guard let primaryPattern = detectedPatterns.max(by: { $0.severity.priority < $1.severity.priority }) else {
                // No concerning patterns detected
                return AgentResponse(
                    agentType: "behavior_monitor",
                    success: true,
                    data: .intervention(InterventionData(
                        level: "info",
                        message: "All good! Keep up the great work.",
                        suggestedAction: nil
                    ))
                )
            }

            // Check if we should intervene (rate limiting)
            if shouldIntervene(level: primaryPattern.severity) {
                let intervention = try await generateIntervention(
                    pattern: primaryPattern,
                    context: context,
                    service: service
                )

                lastInterventionTime = Date()
                interventionCount += 1

                return AgentResponse(
                    agentType: "behavior_monitor",
                    success: true,
                    data: .intervention(intervention),
                    metadata: [
                        "pattern_type": primaryPattern.type.description,
                        "duration": "\(Int(primaryPattern.duration / 60))",
                        "intervention_level": primaryPattern.severity.rawValue
                    ]
                )
            } else {
                // Too many interventions recently, stay quiet
                return AgentResponse(
                    agentType: "behavior_monitor",
                    success: true,
                    data: .intervention(InterventionData(
                        level: "silent",
                        message: "",
                        suggestedAction: nil
                    ))
                )
            }
        } catch {
            throw AgentError.processingFailed("Behavior monitoring failed: \(error.localizedDescription)")
        }
    }

    func warmUp() async throws {
        modelService = try await modelManager.getModel(size: .medium)
    }

    func coolDown() async throws {
        modelService = nil
    }

    // MARK: - Pattern Detection

    private func detectPatterns(context: AIContext) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        // Check screen time
        if let screenTime = context.screenTimeToday,
           screenTime > screenTimeThresholdMinutes * 60 {
            patterns.append(DetectedPattern(
                type: .excessiveScreenTime(app: nil),
                duration: screenTime,
                severity: determineScreenTimeSeverity(screenTime),
                context: "Screen time today"
            ))
        }

        // Check task avoidance
        if let lastActivity = context.lastProductiveActivity {
            let timeSince = Date().timeIntervalSince(lastActivity)
            if timeSince > taskAvoidanceThresholdHours * 3600 {
                patterns.append(DetectedPattern(
                    type: .taskAvoidance,
                    duration: timeSince,
                    severity: determineAvoidanceSeverity(timeSince),
                    context: "No productive activity detected"
                ))
            }
        }

        // Check meal timing (self-care)
        if let lastMeal = context.lastMealTime {
            let timeSince = Date().timeIntervalSince(lastMeal)
            if timeSince > selfCareReminderHours * 3600 {
                patterns.append(DetectedPattern(
                    type: .skippedSelfCare(type: .meal),
                    duration: timeSince,
                    severity: .moderate,
                    context: "Long time since last meal"
                ))
            }
        }

        // Check low completion rate (potential analysis paralysis)
        if context.recentCompletions == 0 && !context.recentTasks.isEmpty {
            patterns.append(DetectedPattern(
                type: .analysisParalysis,
                duration: 0,
                severity: .gentle,
                context: "Tasks created but not completed"
            ))
        }

        return patterns
    }

    // MARK: - Severity Assessment

    private func determineScreenTimeSeverity(_ duration: TimeInterval) -> InterventionLevel {
        let hours = duration / 3600

        if hours > 4 {
            return .assertive
        } else if hours > 2 {
            return .moderate
        } else {
            return .gentle
        }
    }

    private func determineAvoidanceSeverity(_ duration: TimeInterval) -> InterventionLevel {
        let hours = duration / 3600

        if hours > 6 {
            return .assertive
        } else if hours > 4 {
            return .moderate
        } else {
            return .gentle
        }
    }

    // MARK: - Intervention Logic

    private func shouldIntervene(level: InterventionLevel) -> Bool {
        // Always intervene for critical
        if level == .critical {
            return true
        }

        // Check rate limiting
        if let lastIntervention = lastInterventionTime {
            let timeSince = Date().timeIntervalSince(lastIntervention)

            // Reset counter after an hour
            if timeSince > 3600 {
                interventionCount = 0
            }

            // Don't overwhelm with interventions
            if interventionCount >= maxInterventionsPerHour {
                return false
            }

            // Gentle interventions need more spacing
            if level == .gentle && timeSince < 1800 {
                return false
            }
        }

        return true
    }

    private func generateIntervention(
        pattern: DetectedPattern,
        context: AIContext,
        service: LFMService
    ) async throws -> InterventionData {
        let systemPrompt = PromptTemplates.behaviorInterventionSystem

        let userPrompt = PromptTemplates.behaviorIntervention(
            pattern: pattern.type.description,
            duration: formatDuration(pattern.duration),
            context: PromptTemplates.injectUserContext(context)
        )

        let aiResponse = try await service.generate(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            parameters: .creative
        )

        // Parse response for message and suggested action
        let (message, action) = parseInterventionResponse(aiResponse)

        return InterventionData(
            level: pattern.severity.rawValue,
            message: message,
            suggestedAction: action
        )
    }

    private func parseInterventionResponse(_ response: String) -> (message: String, action: String?) {
        // Look for suggested action in response
        let lines = response.components(separatedBy: .newlines)

        var message = ""
        var action: String?

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.lowercased().contains("suggest") || trimmed.lowercased().contains("try") {
                // This might be the suggested action
                action = trimmed
                // Everything before is the message
                message = lines[..<index].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        // If no clear action found, treat entire response as message
        if message.isEmpty {
            message = response.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return (message, action)
    }

    // MARK: - Specific Intervention Generators

    func generateScreenTimeIntervention(
        duration: TimeInterval,
        app: String? = nil,
        context: AIContext
    ) -> InterventionData {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        let appContext = app != nil ? " on \(app!)" : ""

        let messages: [InterventionLevel: (String, String)] = [
            .gentle: (
                "Hey, I noticed you've been scrolling\(appContext) for about \(minutes) minutes. No judgment! How about a quick 5-minute task to reset?",
                "Pick one tiny task from your list and crush it"
            ),
            .moderate: (
                "You've been\(appContext) for over \(hours) hour\(hours > 1 ? "s" : ""). I know it's easy to get pulled in. Let's redirect that energy?",
                "Stand up, stretch, then tackle one micro-task"
            ),
            .assertive: (
                "Real talk: \(hours)+ hours\(appContext). I know your brain is seeking dopamine, but let's find it in a task completion instead. You've got this.",
                "Set a 2-minute timer. Close the app. Do ONE thing. Then decide what's next."
            )
        ]

        let severity = determineScreenTimeSeverity(duration)
        let (message, action) = messages[severity] ?? messages[.gentle]!

        return InterventionData(
            level: severity.rawValue,
            message: message,
            suggestedAction: action
        )
    }

    func generateTaskAvoidanceIntervention(
        timeSince: TimeInterval,
        context: AIContext
    ) -> InterventionData {
        let hours = Int(timeSince / 3600)

        let messages: [InterventionLevel: (String, String)] = [
            .gentle: (
                "It's been a couple hours since your last task. Totally normal to need breaks! Ready for something tiny?",
                "Just 5 minutes on the easiest task you can find"
            ),
            .moderate: (
                "I see it's been \(hours) hours. The activation energy is real, friend. Let's lower the barrier together.",
                "Don't think, just open your task list and pick literally anything"
            ),
            .assertive: (
                "\(hours) hours is a long time, and I bet you're feeling it. No shame - starting is genuinely hard with ADHD. But you CAN do this.",
                "One breath. Then one task. That's it. The momentum will follow."
            )
        ]

        let severity = determineAvoidanceSeverity(timeSince)
        let (message, action) = messages[severity] ?? messages[.gentle]!

        return InterventionData(
            level: severity.rawValue,
            message: message,
            suggestedAction: action
        )
    }

    // MARK: - Utility

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") \(minutes) min"
        } else {
            return "\(minutes) minutes"
        }
    }

    // MARK: - Screen Time Integration (Placeholder)

    func requestScreenTimeAccess() {
        // TODO: Implement Screen Time API integration
        /*
        if #available(iOS 15.0, *) {
            // Request Family Controls authorization
            // Then monitor screen time
        }
        */
        print("ℹ️ BehaviorMonitorAgent: Screen Time API integration pending")
    }

    func getCurrentScreenTime() async -> TimeInterval? {
        // TODO: Implement actual Screen Time reading
        /*
        if #available(iOS 15.0, *) {
            // Fetch today's screen time using Family Controls
            // Return total duration
        }
        */

        // Mock implementation
        return Double.random(in: 1800...7200) // 30 min to 2 hours
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension BehaviorMonitorAgent {
    static func preview(modelManager: ModelManager = ModelManager()) -> BehaviorMonitorAgent {
        BehaviorMonitorAgent(modelManager: modelManager)
    }
}
#endif
