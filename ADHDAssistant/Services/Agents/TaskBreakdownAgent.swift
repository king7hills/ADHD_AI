//
//  TaskBreakdownAgent.swift
//  ADHDAssistant
//
//  Specialized agent for breaking goals into ADHD-friendly micro-tasks
//

import Foundation

@MainActor
final class TaskBreakdownAgent: BaseAgent {
    // MARK: - BaseAgent Protocol

    let capabilities: Set<AgentCapability> = [.taskBreakdown, .contextAwareness]
    let priority: AgentPriority = .high

    var modelRunner: LFMServiceProtocol {
        modelService
    }

    // MARK: - Properties

    private let modelManager: ModelManager
    private var modelService: LFMService?

    // Configuration
    private let minTaskDuration: TimeInterval = 300  // 5 minutes
    private let maxTaskDuration: TimeInterval = 900  // 15 minutes
    private let idealTaskCount = 3...7

    // MARK: - Initialization

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    // MARK: - BaseAgent Implementation

    func process(context: AIContext) async throws -> AgentResponse {
        // Get the goal from context
        guard let goal = context.customContext["current_goal"] else {
            throw AgentError.invalidContext
        }

        do {
            // Get larger model for complex reasoning
            let service = try await modelManager.getModelForTask(.taskBreakdown)
            self.modelService = service

            // Build context-aware prompt
            let systemPrompt = PromptTemplates.taskBreakdownSystem
            let userPrompt = buildUserPrompt(goal: goal, context: context)

            // Generate breakdown
            let response = try await service.generate(
                prompt: userPrompt,
                systemPrompt: systemPrompt,
                parameters: .balanced
            )

            // Parse response into tasks
            let tasks = parseTasks(from: response, context: context)

            // Validate tasks
            let validatedTasks = validateAndAdjustTasks(tasks)

            return AgentResponse(
                agentType: "task_breakdown",
                success: true,
                data: .tasks(validatedTasks),
                metadata: [
                    "goal": goal,
                    "task_count": "\(validatedTasks.count)",
                    "total_estimated_time": "\(calculateTotalTime(validatedTasks))",
                    "energy_level": context.currentEnergy?.rawValue ?? "unknown"
                ]
            )
        } catch {
            throw AgentError.processingFailed("Task breakdown failed: \(error.localizedDescription)")
        }
    }

    func warmUp() async throws {
        // Pre-load the large model
        modelService = try await modelManager.getModel(size: .large)
    }

    func coolDown() async throws {
        modelService = nil
    }

    // MARK: - Prompt Building

    private func buildUserPrompt(goal: String, context: AIContext) -> String {
        let contextInfo = PromptTemplates.injectUserContext(context)

        var prompt = PromptTemplates.taskBreakdown(
            goal: goal,
            userContext: contextInfo
        )

        // Add deadline info if available
        if let deadlineStr = context.customContext["deadline"],
           let deadline = ISO8601DateFormatter().date(from: deadlineStr) {
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
            prompt += "\n\nDeadline: \(daysUntil) days from now"
        }

        // Add energy-aware instructions
        if let energy = context.currentEnergy {
            switch energy {
            case .veryLow, .low:
                prompt += "\n\nNote: User has low energy. Make first tasks VERY easy and quick."
            case .veryHigh:
                prompt += "\n\nNote: User has high energy. Can handle slightly more demanding first task."
            default:
                break
            }
        }

        // Add time-of-day considerations
        switch context.timeOfDay {
        case .earlyMorning, .lateNight:
            prompt += "\n\nNote: Early/late hour. Suggest gentler start, nothing too complex."
        case .morning:
            prompt += "\n\nNote: Morning time. Good for focus work if needed."
        case .afternoon, .evening:
            prompt += "\n\nNote: Later in day. Consider energy fluctuation."
        default:
            break
        }

        return prompt
    }

    // MARK: - Response Parsing

    private func parseTasks(from response: String, context: AIContext) -> [TaskData] {
        var tasks: [TaskData] = []

        // Split response into lines
        let lines = response.components(separatedBy: .newlines)

        var currentTask: String?
        var currentDuration: TimeInterval?
        var currentTrigger: String?
        var taskOrder = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Detect task title (numbered lines)
            if let titleMatch = trimmed.range(of: "^[0-9]+[.)]\\s*(.+)", options: .regularExpression) {
                // Save previous task if exists
                if let task = currentTask {
                    let taskData = createTaskData(
                        title: task,
                        duration: currentDuration,
                        trigger: currentTrigger,
                        order: taskOrder
                    )
                    tasks.append(taskData)
                    taskOrder += 1
                }

                // Start new task
                currentTask = String(trimmed[titleMatch])
                    .replacingOccurrences(of: "^[0-9]+[.)]\\s*", with: "", options: .regularExpression)
                currentDuration = nil
                currentTrigger = nil
            }

            // Extract duration
            if trimmed.contains("min") || trimmed.contains("minute") {
                currentDuration = PromptTemplates.extractDuration(from: trimmed)
            }

            // Extract start trigger
            if trimmed.lowercased().contains("trigger") || trimmed.lowercased().contains("first step") {
                currentTrigger = trimmed
                    .replacingOccurrences(of: "^.*trigger:?\\s*", with: "", options: [.regularExpression, .caseInsensitive])
                    .replacingOccurrences(of: "^.*first step:?\\s*", with: "", options: [.regularExpression, .caseInsensitive])
            }
        }

        // Save last task
        if let task = currentTask {
            let taskData = createTaskData(
                title: task,
                duration: currentDuration,
                trigger: currentTrigger,
                order: taskOrder
            )
            tasks.append(taskData)
        }

        // If parsing failed, create fallback tasks
        if tasks.isEmpty {
            tasks = createFallbackTasks(goal: context.customContext["current_goal"] ?? "Unknown goal")
        }

        return tasks
    }

    private func createTaskData(
        title: String,
        duration: TimeInterval?,
        trigger: String?,
        order: Int
    ) -> TaskData {
        // Estimate duration if not provided
        let estimatedDuration = duration ?? estimateDuration(for: title, order: order)

        // Generate trigger if not provided
        let startTrigger = trigger ?? generateStartTrigger(for: title)

        // Determine difficulty
        let difficulty = assessDifficulty(title: title, duration: estimatedDuration, order: order)

        return TaskData(
            title: title,
            estimatedDuration: estimatedDuration,
            startTrigger: startTrigger,
            difficulty: difficulty,
            order: order
        )
    }

    // MARK: - Task Creation Helpers

    private func estimateDuration(for title: String, order: Int) -> TimeInterval {
        // First task should be quick to build momentum
        if order == 0 {
            return 300 // 5 minutes
        }

        // Look for complexity indicators
        let complexWords = ["organize", "review", "research", "analyze", "plan"]
        let isComplex = complexWords.contains { title.lowercased().contains($0) }

        return isComplex ? 720 : 480 // 12 min vs 8 min
    }

    private func generateStartTrigger(for title: String) -> String {
        // Extract the first action verb
        let verbs = ["open", "create", "write", "find", "grab", "set", "check"]

        for verb in verbs {
            if title.lowercased().contains(verb) {
                return "Immediately \(verb) what you need to start"
            }
        }

        return "Take a breath and begin with the first small step"
    }

    private func assessDifficulty(title: String, duration: TimeInterval, order: Int) -> TaskDifficulty {
        // First task is always very easy
        if order == 0 {
            return .veryEasy
        }

        let titleLower = title.lowercased()

        // Check for difficulty indicators
        if titleLower.contains("complex") || titleLower.contains("difficult") {
            return .hard
        }

        if titleLower.contains("quick") || titleLower.contains("simple") {
            return .easy
        }

        // Base on duration
        if duration <= 300 {
            return .veryEasy
        } else if duration <= 600 {
            return .easy
        } else if duration <= 900 {
            return .medium
        } else {
            return .hard
        }
    }

    // MARK: - Task Validation

    private func validateAndAdjustTasks(_ tasks: [TaskData]) -> [TaskData] {
        var validated = tasks

        // Ensure we have reasonable number of tasks
        if validated.count < idealTaskCount.lowerBound {
            print("⚠️ TaskBreakdownAgent: Only \(validated.count) tasks generated, this is low")
        } else if validated.count > idealTaskCount.upperBound {
            print("⚠️ TaskBreakdownAgent: \(validated.count) tasks generated, consider consolidating")
            // Keep first 7 tasks
            validated = Array(validated.prefix(7))
        }

        // Ensure first task is very easy
        if !validated.isEmpty && validated[0].difficulty != .veryEasy {
            var firstTask = validated[0]
            print("⚠️ TaskBreakdownAgent: Adjusting first task difficulty to very_easy")
            validated[0] = TaskData(
                title: firstTask.title,
                estimatedDuration: min(firstTask.estimatedDuration, 300), // Max 5 min
                startTrigger: firstTask.startTrigger,
                difficulty: .veryEasy,
                order: firstTask.order
            )
        }

        // Validate durations
        validated = validated.map { task in
            if task.estimatedDuration < minTaskDuration || task.estimatedDuration > maxTaskDuration {
                print("⚠️ TaskBreakdownAgent: Adjusting duration for '\(task.title)'")
                return TaskData(
                    title: task.title,
                    estimatedDuration: min(max(task.estimatedDuration, minTaskDuration), maxTaskDuration),
                    startTrigger: task.startTrigger,
                    difficulty: task.difficulty,
                    order: task.order
                )
            }
            return task
        }

        return validated
    }

    // MARK: - Fallback Tasks

    private func createFallbackTasks(goal: String) -> [TaskData] {
        print("⚠️ TaskBreakdownAgent: Using fallback task breakdown")

        return [
            TaskData(
                title: "Gather materials and open workspace",
                estimatedDuration: 300,
                startTrigger: "Open the app or tool you need first",
                difficulty: .veryEasy,
                order: 0
            ),
            TaskData(
                title: "Complete first simple step toward: \(goal)",
                estimatedDuration: 480,
                startTrigger: "Choose the easiest starting point",
                difficulty: .easy,
                order: 1
            ),
            TaskData(
                title: "Continue with main work on: \(goal)",
                estimatedDuration: 600,
                startTrigger: "Build on what you just accomplished",
                difficulty: .medium,
                order: 2
            ),
            TaskData(
                title: "Review and finalize",
                estimatedDuration: 300,
                startTrigger: "Take a quick look at what you've done",
                difficulty: .easy,
                order: 3
            )
        ]
    }

    // MARK: - Utility

    private func calculateTotalTime(_ tasks: [TaskData]) -> Int {
        let total = tasks.reduce(0) { $0 + $1.estimatedDuration }
        return Int(total / 60) // Return minutes
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension TaskBreakdownAgent {
    static func preview(modelManager: ModelManager = ModelManager()) -> TaskBreakdownAgent {
        TaskBreakdownAgent(modelManager: modelManager)
    }
}
#endif
