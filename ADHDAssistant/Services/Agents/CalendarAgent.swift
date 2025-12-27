//
//  CalendarAgent.swift
//  ADHDAssistant
//
//  Specialized agent for ADHD-friendly scheduling with buffer time
//

import Foundation
import EventKit

@MainActor
final class CalendarAgent: BaseAgent {
    // MARK: - BaseAgent Protocol

    let capabilities: Set<AgentCapability> = [.scheduling, .conflictResolution, .contextAwareness]
    let priority: AgentPriority = .high

    var modelRunner: LFMServiceProtocol {
        modelService ?? MockLFMService()
    }

    // MARK: - Properties

    private let modelManager: ModelManager
    private var modelService: LFMService?
    private var eventStore: EKEventStore?

    // ADHD-friendly scheduling parameters
    private let minimumBufferMinutes = 15.0
    private let transitionBufferMultiplier = 1.5
    private let timeEstimateInflationFactor = 1.3 // Add 30% to estimates

    // Energy patterns (customizable per user)
    private let energyPatterns: [TimeOfDay: EnergyLevel] = [
        .earlyMorning: .low,
        .morning: .high,
        .midday: .medium,
        .afternoon: .medium,
        .evening: .low,
        .night: .veryLow,
        .lateNight: .veryLow
    ]

    // MARK: - Initialization

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
        // TODO: Initialize EventKit when implementing calendar integration
        // self.eventStore = EKEventStore()
    }

    // MARK: - BaseAgent Implementation

    func process(context: AIContext) async throws -> AgentResponse {
        guard let taskTitle = context.customContext["task_to_schedule"],
              let durationStr = context.customContext["duration"],
              let durationMinutes = Double(durationStr) else {
            throw AgentError.invalidContext
        }

        let duration = TimeInterval(durationMinutes * 60)
        let preferredTime = context.customContext["preferred_time"]
            .flatMap { ISO8601DateFormatter().date(from: $0) }

        do {
            // Get smaller model for quick scheduling decisions
            let service = try await modelManager.getModelForTask(.scheduling)
            self.modelService = service

            // Find best time slot
            let scheduledEvent = try await scheduleTask(
                title: taskTitle,
                duration: duration,
                preferredTime: preferredTime,
                context: context
            )

            return AgentResponse(
                agentType: "calendar",
                success: true,
                data: .scheduledEvents([scheduledEvent]),
                metadata: [
                    "task": taskTitle,
                    "scheduled_time": ISO8601DateFormatter().string(from: scheduledEvent.startTime),
                    "has_conflict": "\(scheduledEvent.hasConflict)",
                    "buffer_before": "\(Int(scheduledEvent.bufferBefore / 60))",
                    "buffer_after": "\(Int(scheduledEvent.bufferAfter / 60))"
                ]
            )
        } catch {
            throw AgentError.processingFailed("Scheduling failed: \(error.localizedDescription)")
        }
    }

    func warmUp() async throws {
        modelService = try await modelManager.getModel(size: .small)
        // TODO: Request calendar access
        // requestCalendarAccess()
    }

    func coolDown() async throws {
        modelService = nil
    }

    // MARK: - Scheduling Logic

    private func scheduleTask(
        title: String,
        duration: TimeInterval,
        preferredTime: Date?,
        context: AIContext
    ) async throws -> ScheduledEventData {
        // Inflate duration estimate for ADHD time blindness
        let realisticDuration = duration * timeEstimateInflationFactor

        // Determine buffers
        let bufferBefore = calculateBufferBefore(context: context)
        let bufferAfter = calculateBufferAfter(duration: realisticDuration, context: context)

        // Find best time
        let startTime = try await findBestTimeSlot(
            duration: realisticDuration,
            preferredTime: preferredTime,
            bufferBefore: bufferBefore,
            bufferAfter: bufferAfter,
            context: context
        )

        // Check for conflicts
        let hasConflict = await checkForConflicts(
            startTime: startTime,
            duration: realisticDuration,
            bufferBefore: bufferBefore,
            bufferAfter: bufferAfter
        )

        return ScheduledEventData(
            title: title,
            startTime: startTime,
            duration: realisticDuration,
            bufferBefore: bufferBefore,
            bufferAfter: bufferAfter,
            hasConflict: hasConflict
        )
    }

    // MARK: - Time Slot Finding

    private func findBestTimeSlot(
        duration: TimeInterval,
        preferredTime: Date?,
        bufferBefore: TimeInterval,
        bufferAfter: TimeInterval,
        context: AIContext
    ) async throws -> Date {
        // If preferred time is given, try that first
        if let preferred = preferredTime {
            let hasConflict = await checkForConflicts(
                startTime: preferred,
                duration: duration,
                bufferBefore: bufferBefore,
                bufferAfter: bufferAfter
            )

            if !hasConflict {
                return preferred
            }
        }

        // Find next available slot based on energy patterns
        return await findNextEnergyOptimalSlot(
            duration: duration,
            context: context
        )
    }

    private func findNextEnergyOptimalSlot(
        duration: TimeInterval,
        context: AIContext
    ) async -> Date {
        let calendar = Calendar.current
        var searchDate = Date()

        // Search for next 7 days
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: searchDate) else {
                continue
            }

            // Try each hour of the day
            for hour in 7..<22 { // 7 AM to 10 PM
                guard let potentialTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) else {
                    continue
                }

                // Skip times in the past
                if potentialTime < Date() {
                    continue
                }

                // Check energy level for this time
                let timeOfDay = TimeOfDay(from: potentialTime)
                let energyLevel = energyPatterns[timeOfDay] ?? .medium

                // For demanding tasks, prefer high energy times
                let isGoodMatch = energyLevel == .high || energyLevel == .medium

                if isGoodMatch {
                    let hasConflict = await checkForConflicts(
                        startTime: potentialTime,
                        duration: duration,
                        bufferBefore: minimumBufferMinutes * 60,
                        bufferAfter: minimumBufferMinutes * 60
                    )

                    if !hasConflict {
                        return potentialTime
                    }
                }
            }
        }

        // Fallback: next hour
        return calendar.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
    }

    // MARK: - Conflict Detection

    private func checkForConflicts(
        startTime: Date,
        duration: TimeInterval,
        bufferBefore: TimeInterval,
        bufferAfter: TimeInterval
    ) async -> Bool {
        // TODO: Implement actual EventKit conflict checking
        /*
        guard let eventStore = eventStore else { return false }

        let startWithBuffer = startTime.addingTimeInterval(-bufferBefore)
        let endWithBuffer = startTime.addingTimeInterval(duration + bufferAfter)

        let predicate = eventStore.predicateForEvents(
            withStart: startWithBuffer,
            end: endWithBuffer,
            calendars: nil
        )

        let existingEvents = eventStore.events(matching: predicate)
        return !existingEvents.isEmpty
        */

        // Mock implementation: simulate 20% chance of conflict
        return Double.random(in: 0...1) < 0.2
    }

    // MARK: - Buffer Calculation

    private func calculateBufferBefore(context: AIContext) -> TimeInterval {
        var buffer = minimumBufferMinutes * 60

        // Add more buffer if energy is low (needs transition time)
        if let energy = context.currentEnergy {
            switch energy {
            case .veryLow, .low:
                buffer *= 1.5
            case .veryHigh:
                buffer *= 0.8 // Can transition faster when energized
            default:
                break
            }
        }

        // Add more buffer in afternoon/evening (fatigue builds)
        switch context.timeOfDay {
        case .afternoon, .evening, .night:
            buffer *= 1.2
        default:
            break
        }

        return buffer
    }

    private func calculateBufferAfter(duration: TimeInterval, context: AIContext) -> TimeInterval {
        // Longer tasks need more recovery time
        let baseBuffer = minimumBufferMinutes * 60

        if duration > 3600 { // More than 1 hour
            return baseBuffer * 1.5
        } else if duration > 1800 { // More than 30 min
            return baseBuffer * 1.2
        } else {
            return baseBuffer
        }
    }

    // MARK: - AI-Assisted Scheduling

    func getSchedulingSuggestion(
        task: String,
        duration: TimeInterval,
        context: AIContext
    ) async throws -> String {
        guard let service = modelService else {
            throw AgentError.modelUnavailable
        }

        let systemPrompt = PromptTemplates.calendarSchedulingSystem
        let userPrompt = PromptTemplates.scheduleTask(
            task: task,
            preferredTime: "flexible",
            duration: duration,
            userContext: PromptTemplates.injectUserContext(context)
        )

        return try await service.generate(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            parameters: .precise
        )
    }

    // MARK: - EventKit Integration (Placeholder)

    private func requestCalendarAccess() {
        // TODO: Implement when adding EventKit
        /*
        eventStore?.requestAccess(to: .event) { granted, error in
            if granted {
                print("✓ CalendarAgent: Calendar access granted")
            } else {
                print("✗ CalendarAgent: Calendar access denied")
            }
        }
        */
    }

    func addEventToCalendar(_ event: ScheduledEventData) async throws {
        // TODO: Implement actual calendar event creation
        /*
        guard let eventStore = eventStore else {
            throw CalendarError.noAccess
        }

        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = event.title
        ekEvent.startDate = event.startTime
        ekEvent.endDate = event.startTime.addingTimeInterval(event.duration)
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(ekEvent, span: .thisEvent)
        */

        print("✓ CalendarAgent: Mock event added - \(event.title) at \(event.startTime)")
    }

    // MARK: - Utility

    func getUpcomingSchedule(days: Int = 7) async -> [ScheduledEventData] {
        // TODO: Implement actual calendar reading
        /*
        guard let eventStore = eventStore else { return [] }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)!

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
        return events.map { event in
            ScheduledEventData(
                title: event.title,
                startTime: event.startDate,
                duration: event.endDate.timeIntervalSince(event.startDate),
                bufferBefore: 900, // 15 min
                bufferAfter: 900,  // 15 min
                hasConflict: false
            )
        }
        */

        // Mock implementation
        return []
    }
}

// MARK: - Calendar Error

enum CalendarError: LocalizedError {
    case noAccess
    case eventCreationFailed
    case conflictDetected

    var errorDescription: String? {
        switch self {
        case .noAccess:
            return "Calendar access not granted"
        case .eventCreationFailed:
            return "Failed to create calendar event"
        case .conflictDetected:
            return "Scheduling conflict detected"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension CalendarAgent {
    static func preview(modelManager: ModelManager = ModelManager()) -> CalendarAgent {
        CalendarAgent(modelManager: modelManager)
    }
}
#endif
