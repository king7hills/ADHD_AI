//
//  MotivationAgent.swift
//  ADHDAssistant
//
//  Provides genuine, varied encouragement and motivation with ADHD awareness
//

import Foundation

// MARK: - Motivation Trigger

enum MotivationTrigger: String, Codable {
    case taskCompleted = "task_completed"
    case streakMilestone = "streak_milestone"
    case comeBack = "come_back"
    case lowMotivation = "low_motivation"
    case beforeDifficultTask = "before_difficult_task"
    case midDayCheck = "mid_day_check"
    case endOfDay = "end_of_day"
    case struggled = "struggled"
    case encouragement = "encouragement"
    case celebration = "celebration"
}

// MARK: - Celebration Style

enum CelebrationStyle: String {
    case subtle = "subtle"
    case enthusiastic = "enthusiastic"
    case proud = "proud"
    case compassionate = "compassionate"
    case energizing = "energizing"
}

// MARK: - Motivation Agent

@MainActor
final class MotivationAgent: BaseAgent {
    // MARK: - BaseAgent Protocol

    let capabilities: Set<AgentCapability> = [.motivation, .contextAwareness]
    let priority: AgentPriority = .medium

    var modelRunner: LFMServiceProtocol {
        modelService ?? MockLFMService()
    }

    // MARK: - Properties

    private let modelManager: ModelManager
    private var modelService: LFMService?

    // Message variety tracking
    private var recentMessages: [String] = []
    private let maxRecentMessages = 20
    private var messageUsageCount: [String: Int] = [:]

    // MARK: - Initialization

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    // MARK: - BaseAgent Implementation

    func process(context: AIContext) async throws -> AgentResponse {
        do {
            // Get model for creative, varied responses
            let service = try await modelManager.getModelForTask(.motivation)
            self.modelService = service

            // Determine trigger from context
            let trigger = extractTrigger(from: context)

            // Generate motivation message
            let (message, tone) = try await generateMotivation(
                trigger: trigger,
                context: context,
                service: service
            )

            // Track message to avoid repetition
            trackMessage(message)

            return AgentResponse(
                agentType: "motivation",
                success: true,
                data: .motivation(MotivationData(
                    message: message,
                    trigger: trigger.rawValue,
                    tone: tone
                )),
                metadata: [
                    "time_of_day": context.timeOfDay.rawValue,
                    "streak": "\(context.currentStreak)",
                    "energy_level": context.currentEnergy?.rawValue ?? "unknown"
                ]
            )
        } catch {
            throw AgentError.processingFailed("Motivation generation failed: \(error.localizedDescription)")
        }
    }

    func warmUp() async throws {
        modelService = try await modelManager.getModel(size: .medium)
    }

    func coolDown() async throws {
        modelService = nil
    }

    // MARK: - Trigger Detection

    private func extractTrigger(from context: AIContext) -> MotivationTrigger {
        // Check for explicit trigger in context
        if let triggerStr = context.customContext["motivation_trigger"],
           let trigger = MotivationTrigger(rawValue: triggerStr) {
            return trigger
        }

        // Infer trigger from context
        if context.recentCompletions > 0 {
            return .taskCompleted
        }

        if context.currentStreak > 0 && context.currentStreak % 7 == 0 {
            return .streakMilestone
        }

        if let lastActivity = context.lastProductiveActivity,
           Date().timeIntervalSince(lastActivity) > 14400 { // 4 hours
            return .comeBack
        }

        switch context.timeOfDay {
        case .midday:
            return .midDayCheck
        case .evening, .night:
            return .endOfDay
        default:
            return .encouragement
        }
    }

    // MARK: - Message Generation

    private func generateMotivation(
        trigger: MotivationTrigger,
        context: AIContext,
        service: LFMService
    ) async throws -> (message: String, tone: String) {
        // First try predefined messages for variety
        if let (message, tone) = selectPredefinedMessage(trigger: trigger, context: context) {
            return (message, tone)
        }

        // Fall back to AI generation
        let systemPrompt = PromptTemplates.motivationSystem

        let userPrompt = PromptTemplates.motivation(
            trigger: trigger.rawValue,
            context: PromptTemplates.injectUserContext(context),
            timeOfDay: context.timeOfDay.rawValue
        )

        let aiMessage = try await service.generate(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            parameters: .creative
        )

        let tone = determineTone(for: trigger, timeOfDay: context.timeOfDay)

        return (aiMessage.trimmingCharacters(in: .whitespacesAndNewlines), tone)
    }

    // MARK: - Predefined Messages

    private func selectPredefinedMessage(
        trigger: MotivationTrigger,
        context: AIContext
    ) -> (message: String, tone: String)? {
        let pool = getMessagePool(for: trigger, context: context)

        guard !pool.isEmpty else { return nil }

        // Filter out recently used messages
        let available = pool.filter { !recentMessages.contains($0.message) }

        // If all messages have been used recently, use least used
        if available.isEmpty {
            let leastUsed = pool.min { msg1, msg2 in
                let count1 = messageUsageCount[msg1.message] ?? 0
                let count2 = messageUsageCount[msg2.message] ?? 0
                return count1 < count2
            }
            return leastUsed
        }

        // Random selection from available
        return available.randomElement()
    }

    private func getMessagePool(
        for trigger: MotivationTrigger,
        context: AIContext
    ) -> [(message: String, tone: String)] {
        switch trigger {
        case .taskCompleted:
            return taskCompletionMessages

        case .streakMilestone:
            return streakMilestoneMessages(streak: context.currentStreak)

        case .comeBack:
            return comeBackMessages

        case .lowMotivation:
            return lowMotivationMessages

        case .beforeDifficultTask:
            return beforeDifficultTaskMessages

        case .midDayCheck:
            return midDayMessages

        case .endOfDay:
            return endOfDayMessages

        case .struggled:
            return struggledMessages

        case .encouragement, .celebration:
            return generalEncouragementMessages
        }
    }

    // MARK: - Message Pools

    private var taskCompletionMessages: [(message: String, tone: String)] {
        [
            ("Yes! That's what I'm talking about. You did the thing! 🎯", "enthusiastic"),
            ("Look at you go! Another one done. The momentum is building.", "proud"),
            ("Completed! And you know what? Starting was the hardest part, and you crushed it.", "encouraging"),
            ("Boom. Task complete. That dopamine hit is 100% earned.", "celebratory"),
            ("You did it, even though your brain probably fought you on it. That's strength.", "compassionate"),
            ("One down! That's the kind of energy we're looking for.", "energizing"),
            ("Done is better than perfect, and you nailed it. Keep this rolling!", "motivating"),
            ("Another task off the list. You're proving to yourself what you can do.", "proud"),
            ("Finished! Your future self is going to be so grateful for this.", "warm"),
            ("You showed up and did the work. That's the whole game right there.", "affirming")
        ]
    }

    private func streakMilestoneMessages(streak: Int) -> [(message: String, tone: String)] {
        [
            ("\(streak) days! That's not luck, that's you building a habit. Incredible.", "proud"),
            ("Holy consistency, Batman! \(streak) days straight. You're doing the thing!", "enthusiastic"),
            ("\(streak) day streak. Every single one of those days, you chose to show up. Respect.", "affirming"),
            ("Look at this streak: \(streak) days. Your ADHD brain tried to stop you \(streak) times. You won \(streak) times.", "compassionate"),
            ("\(streak) days of showing up. This is what sustainable progress looks like.", "proud")
        ]
    }

    private var comeBackMessages: [(message: String, tone: String)] {
        [
            ("Hey, welcome back! No judgment about the gap. Ready to jump back in?", "warm"),
            ("You're here now, and that's what matters. Let's do this.", "encouraging"),
            ("Look who's back! The break is over when YOU say it is. Fresh start?", "energizing"),
            ("It's been a minute, but you showed up anyway. That takes courage.", "compassionate"),
            ("Welcome back to the arena. One task, one moment, let's get it.", "motivating"),
            ("Back again! Every return is a win against the 'all or nothing' trap.", "wise"),
            ("You came back. That's the pattern we're building - return, not perfection.", "affirming")
        ]
    }

    private var lowMotivationMessages: [(message: String, tone: String)] {
        [
            ("Low motivation is real, and it's okay. What's the tiniest possible task right now?", "compassionate"),
            ("The feeling will follow the action. Pick something stupid-easy and start.", "practical"),
            ("I know it feels impossible to start. Just 2 minutes. That's all we're asking.", "gentle"),
            ("Your brain is lying about how hard this is. Prove it wrong with one tiny step.", "challenging"),
            ("Motivation is overrated. Momentum is what we need. Baby steps count.", "wise"),
            ("Feeling stuck? That's the ADHD talking. Let's outsmart it together.", "supportive"),
            ("You don't need to want to do it. You just need to do it for 5 minutes.", "direct")
        ]
    }

    private var beforeDifficultTaskMessages: [(message: String, tone: String)] {
        [
            ("This one's tough, I know. But you've done hard things before. Deep breath.", "supportive"),
            ("Difficult ≠ Impossible. Break it down, start small, you've got this.", "practical"),
            ("Yeah, this is going to take focus. But that's what the buffers are for. Begin.", "direct"),
            ("The hardest tasks earn the best dopamine. Let's get you that win.", "motivating"),
            ("Big task energy. Start with the easiest piece and build momentum.", "strategic"),
            ("You can do hard things. Not perfectly, but you CAN do them. Start anywhere.", "affirming")
        ]
    }

    private var midDayMessages: [(message: String, tone: String)] {
        [
            ("Halfway through the day! How are we doing? Time for a quick win?", "checking-in"),
            ("Midday check: You're still here, still trying. That counts for everything.", "affirming"),
            ("Afternoon vibes. Energy might be dipping - that's normal. Easy task time?", "understanding"),
            ("How's the day treating you? Remember: done > perfect, always.", "supportive"),
            ("Midday moment. Proud of whatever you've accomplished so far. What's next?", "encouraging")
        ]
    }

    private var endOfDayMessages: [(message: String, tone: String)] {
        [
            ("End of day. Whatever you did today - it was enough. Rest up.", "compassionate"),
            ("Day's done. You showed up, you tried, that's the win. Tomorrow's fresh.", "affirming"),
            ("Closing out the day. Progress isn't linear, but you moved forward. Well done.", "proud"),
            ("Another day navigated with ADHD. That takes strength. Sleep well.", "warm"),
            ("Day complete. Some wins, maybe some struggles, all valid. You did good.", "accepting"),
            ("End of day report: You survived, you tried, you're here. Victory.", "supportive")
        ]
    }

    private var struggledMessages: [(message: String, tone: String)] {
        [
            ("It was hard today. I see that. The effort matters, even without the outcome.", "compassionate"),
            ("Struggling doesn't mean failing. It means you're trying. That's courage.", "affirming"),
            ("Today was rough. Tomorrow is brand new. You get infinite restarts.", "hopeful"),
            ("You fought through it even when it was hard. That's the real strength.", "proud"),
            ("Some days are just harder. Your worth isn't measured by productivity.", "compassionate"),
            ("You struggled and kept going anyway. That's resilience in action.", "affirming")
        ]
    }

    private var generalEncouragementMessages: [(message: String, tone: String)] {
        [
            ("You're doing better than you think. Keep going.", "encouraging"),
            ("One step, one task, one moment. You've got this.", "supportive"),
            ("Your ADHD brain is powerful. Let's channel it.", "empowering"),
            ("Progress over perfection, every single time.", "wise"),
            ("You're not lazy. You're not broken. You're learning to work with your brain.", "affirming"),
            ("Every small win rewires your brain. Keep stacking them.", "scientific"),
            ("The fact that you're here trying? That's already a win.", "compassionate"),
            ("You've overcome every difficult day so far. 100% success rate.", "empowering"),
            ("Done is the goal. Perfect is the trap. Choose done.", "practical"),
            ("Your effort is valuable, regardless of the outcome.", "affirming")
        ]
    }

    // MARK: - Tone Determination

    private func determineTone(for trigger: MotivationTrigger, timeOfDay: TimeOfDay) -> String {
        switch (trigger, timeOfDay) {
        case (.taskCompleted, _):
            return "celebratory"

        case (.streakMilestone, _):
            return "proud"

        case (.comeBack, _):
            return "welcoming"

        case (.lowMotivation, .morning):
            return "gentle-energizing"

        case (.lowMotivation, _):
            return "compassionate"

        case (.beforeDifficultTask, _):
            return "supportive-confident"

        case (.endOfDay, _):
            return "warm-affirming"

        case (.struggled, _):
            return "deeply-compassionate"

        case (_, .earlyMorning):
            return "gentle"

        case (_, .morning):
            return "energizing"

        case (_, .midday), (_, .afternoon):
            return "encouraging"

        case (_, .evening), (_, .night):
            return "calm-supportive"

        case (_, .lateNight):
            return "very-gentle"
        }
    }

    // MARK: - Message Tracking

    private func trackMessage(_ message: String) {
        recentMessages.append(message)
        if recentMessages.count > maxRecentMessages {
            recentMessages.removeFirst()
        }

        messageUsageCount[message, default: 0] += 1
    }

    func resetMessageTracking() {
        recentMessages.removeAll()
        messageUsageCount.removeAll()
    }

    // MARK: - Public API

    /// Get a quick motivation message for a specific trigger
    func quickMotivation(trigger: MotivationTrigger, context: AIContext) -> String {
        if let (message, _) = selectPredefinedMessage(trigger: trigger, context: context) {
            trackMessage(message)
            return message
        }

        return "You're doing great! Keep going! 🌟"
    }

    /// Get a celebration message
    func celebrate(achievement: String, style: CelebrationStyle = .enthusiastic) -> String {
        let celebrations: [CelebrationStyle: [String]] = [
            .subtle: [
                "Nice work on \(achievement). ✓",
                "Got it done. Well executed.",
                "\(achievement) - complete."
            ],
            .enthusiastic: [
                "YES! \(achievement)! Absolutely crushing it! 🎉",
                "Look at you go! \(achievement) is DONE! 🌟",
                "BOOM! \(achievement) complete! That's how it's done! 🎯"
            ],
            .proud: [
                "Seriously proud of you for \(achievement). Well done.",
                "\(achievement). You should feel good about that.",
                "You did it: \(achievement). That took real effort."
            ],
            .compassionate: [
                "\(achievement), even though it was hard. That's strength.",
                "You pushed through and got \(achievement) done. I see you.",
                "\(achievement) - done despite the struggle. That matters."
            ],
            .energizing: [
                "\(achievement) - DONE! Let's keep this momentum! ⚡",
                "That energy! \(achievement) complete! What's next? 🚀",
                "\(achievement) in the books! You're on fire! 🔥"
            ]
        ]

        let messages = celebrations[style] ?? celebrations[.enthusiastic]!
        let message = messages.randomElement()!
        trackMessage(message)
        return message
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension MotivationAgent {
    static func preview(modelManager: ModelManager = ModelManager()) -> MotivationAgent {
        MotivationAgent(modelManager: modelManager)
    }
}
#endif
