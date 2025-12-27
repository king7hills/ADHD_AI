# Agent System Specifications

This document provides detailed specifications for each AI agent in the ADHD Executive Function Assistant.

---

## Agent Coordinator

The central orchestrator that routes requests and maintains shared state.

### Responsibilities
1. Route incoming requests to appropriate specialized agents
2. Maintain shared context across all agents
3. Handle agent-to-agent communication
4. Manage model loading/unloading for memory efficiency
5. Aggregate responses when multiple agents contribute

### Implementation

```swift
// Services/Agents/AgentCoordinator.swift

import Foundation
import LeapSDK

@MainActor
final class AgentCoordinator: ObservableObject {
    // MARK: - Agents
    private lazy var taskBreakdownAgent = TaskBreakdownAgent(modelRunner: largeModelRunner)
    private lazy var calendarAgent = CalendarAgent(modelRunner: smallModelRunner)
    private lazy var behaviorMonitorAgent = BehaviorMonitorAgent(modelRunner: smallModelRunner)
    private lazy var healthAgent = HealthAgent(modelRunner: mediumModelRunner)
    private lazy var motivationAgent = MotivationAgent(modelRunner: smallModelRunner)

    // MARK: - Model Runners
    private var smallModelRunner: ModelRunner?   // LFM2-350M
    private var mediumModelRunner: ModelRunner?  // LFM2-700M
    private var largeModelRunner: ModelRunner?   // LFM2-1.2B

    // MARK: - Shared State
    @Published private(set) var context: AIContext
    @Published private(set) var isProcessing = false

    // MARK: - Request Routing

    enum AgentRequest {
        case breakdownGoal(Goal)
        case scheduleTask(Task)
        case checkBehavior
        case healthReminder(HealthMetricType)
        case motivate(trigger: MotivationTrigger)
        case chat(message: String)
    }

    func process(_ request: AgentRequest) async throws -> AgentResponse {
        isProcessing = true
        defer { isProcessing = false }

        switch request {
        case .breakdownGoal(let goal):
            return try await taskBreakdownAgent.breakdown(goal, context: context)

        case .scheduleTask(let task):
            return try await calendarAgent.schedule(task, context: context)

        case .checkBehavior:
            return try await behaviorMonitorAgent.evaluate(context: context)

        case .healthReminder(let type):
            return try await healthAgent.generateReminder(for: type, context: context)

        case .motivate(let trigger):
            return try await motivationAgent.encourage(trigger: trigger, context: context)

        case .chat(let message):
            return try await routeChat(message)
        }
    }

    private func routeChat(_ message: String) async throws -> AgentResponse {
        // Analyze intent and route to appropriate agent
        let intent = try await analyzeIntent(message)
        // Route based on intent...
    }
}
```

---

## Task Breakdown Agent

Converts high-level goals into ADHD-friendly micro-tasks.

### Model
- **Primary**: LFM2-1.2B (for complex breakdowns)
- **Fallback**: LFM2-700M (for simpler tasks)

### System Prompt

```
You are a task breakdown specialist for users with ADHD. Your role is to take broad goals and break them into small, concrete, immediately actionable steps.

CRITICAL RULES:
1. Each task should take 5-15 minutes maximum
2. Tasks must be specific and unambiguous
3. Start with the easiest task to build momentum
4. Include "start triggers" (e.g., "Open the app", "Stand up")
5. Never use vague language like "think about" or "consider"
6. Provide time estimates for each task
7. Group related tasks but keep each one atomic

USER CONTEXT:
- Has ADHD and struggles with task initiation
- May have health conditions requiring specific reminders
- Responds well to small wins and immediate feedback

OUTPUT FORMAT (JSON):
{
  "tasks": [
    {
      "title": "Brief, action-oriented title",
      "description": "One sentence of what to do",
      "duration_minutes": 5,
      "difficulty": "easy|medium|hard",
      "start_trigger": "Physical action to begin",
      "dependencies": [],
      "category": "health|work|personal|home"
    }
  ],
  "suggested_order": [0, 1, 2],
  "momentum_builder": "Index of easiest task to start with"
}
```

### Input Schema

```swift
struct TaskBreakdownRequest: Codable {
    let goal: String
    let deadline: Date?
    let userContext: UserContext

    struct UserContext: Codable {
        let hasHealthConditions: [String]
        let availableTimeSlots: [TimeSlot]
        let energyLevel: EnergyLevel
        let currentStreak: Int
        let preferredTaskDuration: Int // minutes
    }
}
```

### Output Schema

```swift
struct TaskBreakdownResponse: Codable {
    let tasks: [GeneratedTask]
    let suggestedOrder: [Int]
    let momentumBuilder: Int
    let estimatedTotalTime: Int

    struct GeneratedTask: Codable {
        let title: String
        let description: String
        let durationMinutes: Int
        let difficulty: Difficulty
        let startTrigger: String
        let dependencies: [Int]
        let category: TaskCategory
    }
}
```

### Example Interaction

**Input:**
```json
{
  "goal": "Start exercising regularly",
  "deadline": null,
  "userContext": {
    "hasHealthConditions": ["type2_diabetes"],
    "availableTimeSlots": [{"start": "07:00", "end": "07:30"}],
    "energyLevel": "low",
    "currentStreak": 0,
    "preferredTaskDuration": 10
  }
}
```

**Output:**
```json
{
  "tasks": [
    {
      "title": "Put workout clothes by bed tonight",
      "description": "Set out comfortable clothes you'll exercise in tomorrow",
      "durationMinutes": 2,
      "difficulty": "easy",
      "startTrigger": "Walk to your closet now",
      "dependencies": [],
      "category": "health"
    },
    {
      "title": "5-minute morning stretch",
      "description": "Do 5 gentle stretches right after waking up",
      "durationMinutes": 5,
      "difficulty": "easy",
      "startTrigger": "Stand up and reach your arms overhead",
      "dependencies": [0],
      "category": "health"
    },
    {
      "title": "Walk around the block once",
      "description": "One lap around your block at any pace",
      "durationMinutes": 10,
      "difficulty": "easy",
      "startTrigger": "Put on your shoes and step outside",
      "dependencies": [1],
      "category": "health"
    }
  ],
  "suggestedOrder": [0, 1, 2],
  "momentumBuilder": 0,
  "estimatedTotalTime": 17
}
```

---

## Calendar Agent

Manages scheduling with ADHD-aware timing strategies.

### Model
- **Primary**: LFM2-350M (fast, simple operations)

### System Prompt

```
You are a calendar management assistant specialized in ADHD-friendly scheduling.

SCHEDULING RULES:
1. Always add 50% buffer time to task estimates
2. Never schedule back-to-back tasks without transition time
3. Place difficult tasks during the user's peak energy times
4. Group similar tasks together when possible
5. Leave "white space" - don't overschedule
6. Morning routines should be consistent daily
7. Health-critical tasks (medication, blood sugar) are non-negotiable

CONFLICT RESOLUTION:
- Health tasks > Work deadlines > Personal tasks
- Never move medication or health check reminders
- Suggest alternatives rather than removing tasks

OUTPUT FORMAT (JSON):
{
  "scheduled_time": "ISO8601 datetime",
  "conflicts": [],
  "adjustments_made": [],
  "warnings": []
}
```

### Key Methods

```swift
protocol CalendarAgentProtocol {
    /// Schedule a single task
    func schedule(_ task: Task, context: AIContext) async throws -> ScheduleResult

    /// Find optimal time for a task
    func findOptimalTime(for task: Task, within range: DateInterval) async throws -> Date?

    /// Detect and resolve conflicts
    func resolveConflicts(for date: Date) async throws -> [ConflictResolution]

    /// Generate daily schedule
    func generateDailyPlan(for date: Date, tasks: [Task]) async throws -> DailyPlan
}
```

---

## Behavior Monitor Agent

Detects counterproductive patterns and triggers interventions.

### Model
- **Primary**: LFM2-350M

### Monitoring Data Sources

1. **Screen Time API** (iOS)
   - App usage duration
   - Pickup frequency
   - Category time breakdown

2. **App State** (Internal)
   - Time since last task completion
   - Tasks currently overdue
   - Pattern of snoozes/skips

3. **Time Patterns**
   - Current time of day
   - Day of week
   - Proximity to deadlines

### Intervention Levels

```swift
enum InterventionLevel: Int, Comparable {
    case gentle = 1      // Subtle reminder
    case moderate = 2    // Notification with suggestion
    case assertive = 3   // Live Activity + vibration
    case critical = 4    // Full-screen alert (health only)
}
```

### System Prompt

```
You are a supportive behavior intervention assistant for someone with ADHD.

DETECTION PATTERNS:
- Social media usage > 15 minutes during scheduled task time
- No task completion in > 2 hours during active hours
- Repeated task snoozing (3+ times same task)
- App switching frequency > 10/minute (hyperfocus break needed)

INTERVENTION STYLE:
- Never shame or guilt
- Acknowledge the difficulty of the moment
- Offer one tiny action as an alternative
- Use gentle humor when appropriate
- Reference their goals and why they matter

MESSAGE EXAMPLES:
- Gentle: "Quick check-in: How's that [task] going? Tap here if you need a smaller step."
- Moderate: "Hey, noticed some scrolling time. Totally okay! Ready to tackle [task] for just 5 minutes?"
- Assertive: "Let's do this together. [Task] is waiting. Just the first tiny step - [start trigger]"

OUTPUT FORMAT (JSON):
{
  "should_intervene": true,
  "level": "gentle|moderate|assertive",
  "message": "The intervention message",
  "suggested_action": "One tiny step",
  "task_reference": "task_id if applicable"
}
```

---

## Health Agent

Specialized for health condition management, particularly Type 2 diabetes.

### Model
- **Primary**: LFM2-700M

### Reminder Types

```swift
enum HealthReminderType {
    case bloodSugarCheck(interval: TimeInterval)
    case medication(name: String, time: Date)
    case mealTime(type: MealType)
    case exercise(duration: TimeInterval)
    case hydration
    case restReminder
}
```

### System Prompt

```
You are a health management assistant focused on Type 2 diabetes care.

CRITICAL PRIORITIES:
1. Medication timing is non-negotiable
2. Blood sugar checks should never be skipped
3. Meal timing affects blood sugar stability
4. Exercise is beneficial but should be timed appropriately

REMINDER STYLE:
- Clear and direct for critical reminders
- Warm and encouraging for routine checks
- Celebrate consistency and streaks
- Provide context on why each action matters

BLOOD SUGAR CONTEXT:
- Normal fasting: 80-130 mg/dL
- Post-meal (2hr): <180 mg/dL
- Low (hypoglycemia): <70 mg/dL - URGENT
- High (hyperglycemia): >180 mg/dL - Note pattern

OUTPUT FORMAT (JSON):
{
  "reminder_type": "blood_sugar|medication|meal|exercise",
  "urgency": "routine|important|critical",
  "message": "The reminder message",
  "action_required": "What they need to do",
  "follow_up_in_minutes": 30,
  "log_required": true
}
```

### Pattern Recognition

```swift
struct HealthPatternAnalysis {
    let averageBloodSugar: Double
    let trend: Trend // rising, falling, stable
    let problematicTimes: [TimeOfDay]
    let medicationAdherence: Double // percentage
    let exerciseCorrelation: Double // blood sugar impact
    let recommendations: [String]
}
```

---

## Motivation Agent

Provides encouragement and celebrates achievements.

### Model
- **Primary**: LFM2-350M

### Trigger Types

```swift
enum MotivationTrigger {
    case taskCompleted(Task)
    case streakMilestone(days: Int)
    case achievementUnlocked(Achievement)
    case comingBackAfterBreak(daysMissed: Int)
    case difficultTaskAttempted
    case morningStarted
    case endOfDaySummary
}
```

### System Prompt

```
You are a supportive motivation coach for someone with ADHD.

TONE GUIDELINES:
- Authentic, not cheesy or over-the-top
- Acknowledge that things are hard
- Celebrate small wins genuinely
- Match energy to time of day (energetic morning, calm evening)
- Vary your responses - never repeat the same phrase

NEVER SAY:
- "You've got this!" (overused)
- Anything guilt-inducing
- Generic motivational quotes
- Comparisons to others

DO SAY:
- Specific acknowledgment of what they accomplished
- Recognition of the effort, not just the result
- Brief, punchy encouragement
- Occasional gentle humor

OUTPUT FORMAT (JSON):
{
  "message": "The motivation message",
  "tone": "celebratory|supportive|gentle|energetic",
  "celebration_style": "confetti|none|subtle",
  "points_earned": 25,
  "bonus_reason": "Reason for any bonus points"
}
```

### Response Variations

For task completion, maintain a pool of 50+ unique responses:

```swift
let completionResponses = [
    "Done and dusted. That's \(points) points.",
    "Look at you go. \(taskName) is history.",
    "Checked off. Your future self thanks you.",
    "That's the stuff. \(points) points earned.",
    "Boom. Next?",
    // ... 45+ more variations
]
```

---

## Agent Communication Protocol

### Inter-Agent Messages

```swift
struct AgentMessage {
    let fromAgent: AgentType
    let toAgent: AgentType
    let messageType: MessageType
    let payload: [String: Any]
    let priority: Priority
    let timestamp: Date

    enum MessageType {
        case taskCreated
        case taskCompleted
        case scheduleUpdated
        case behaviorAlert
        case healthEvent
        case contextUpdate
    }
}
```

### Shared Context Updates

When any agent modifies shared context:

```swift
protocol ContextAwareAgent {
    var coordinator: AgentCoordinator { get }

    func updateContext(_ update: ContextUpdate) async

    func onContextChanged(_ context: AIContext) async
}
```

---

## Error Handling

### Agent Failures

```swift
enum AgentError: Error {
    case modelNotLoaded
    case inferenceTimeout
    case invalidResponse
    case contextTooLarge
    case rateLimited

    var fallbackBehavior: FallbackBehavior {
        switch self {
        case .modelNotLoaded:
            return .useDefaultResponse
        case .inferenceTimeout:
            return .retryWithSmallerModel
        case .invalidResponse:
            return .retryOnce
        case .contextTooLarge:
            return .truncateAndRetry
        case .rateLimited:
            return .queueForLater
        }
    }
}
```

---

## Testing Agents

### Mock Model Runner

```swift
class MockModelRunner: ModelRunnerProtocol {
    var mockResponses: [String: String] = [:]

    func generate(prompt: String) async throws -> String {
        return mockResponses[prompt] ?? "{}"
    }
}
```

### Agent Test Example

```swift
func testTaskBreakdownAgent() async throws {
    let mockRunner = MockModelRunner()
    mockRunner.mockResponses["breakdown:exercise"] = """
    {"tasks":[{"title":"Put on shoes","durationMinutes":2}]}
    """

    let agent = TaskBreakdownAgent(modelRunner: mockRunner)
    let result = try await agent.breakdown(
        Goal(title: "Exercise more"),
        context: .mock
    )

    XCTAssertFalse(result.tasks.isEmpty)
    XCTAssertEqual(result.tasks[0].title, "Put on shoes")
}
```
