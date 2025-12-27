//
//  HealthAgent.swift
//  ADHDAssistant
//
//  Specialized agent for Type 2 diabetes management with ADHD considerations
//

import Foundation
import HealthKit

// MARK: - Health Reminder

struct HealthReminder: Codable {
    let type: ReminderType
    let message: String
    let urgency: UrgencyLevel
    let dueTime: Date?
    let context: String

    enum ReminderType: String, Codable {
        case bloodSugarCheck = "blood_sugar_check"
        case medication = "medication"
        case meal = "meal"
        case exercise = "exercise"
        case hydration = "hydration"
        case doctorAppointment = "doctor_appointment"

        var displayName: String {
            switch self {
            case .bloodSugarCheck: return "Blood Sugar Check"
            case .medication: return "Medication"
            case .meal: return "Meal Time"
            case .exercise: return "Movement"
            case .hydration: return "Hydration"
            case .doctorAppointment: return "Appointment"
            }
        }
    }

    enum UrgencyLevel: String, Codable, Comparable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"

        static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
            let order: [UrgencyLevel] = [.low, .medium, .high, .critical]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }
}

// MARK: - Health Pattern

struct HealthPattern {
    let type: PatternType
    let trend: Trend
    let confidence: Double
    let recommendation: String

    enum PatternType {
        case bloodSugarFluctuation
        case medicationAdherence
        case mealTiming
        case exerciseConsistency
    }

    enum Trend {
        case improving
        case stable
        case concerning
        case critical
    }
}

// MARK: - Health Agent

@MainActor
final class HealthAgent: BaseAgent {
    // MARK: - BaseAgent Protocol

    let capabilities: Set<AgentCapability> = [.healthManagement, .patternRecognition]
    let priority: AgentPriority = .critical  // Health is critical priority

    var modelRunner: LFMServiceProtocol {
        modelService ?? MockLFMService()
    }

    // MARK: - Properties

    private let modelManager: ModelManager
    private var modelService: LFMService?
    private var healthStore: HKHealthStore?

    // Health monitoring thresholds
    private let bloodSugarCheckIntervalHours = 4.0
    private let medicationReminderIntervalHours = 12.0  // Twice daily
    private let mealIntervalHours = 5.0
    private let exerciseGoalMinutesPerDay = 30.0

    // Tracking
    private var lastReminderSent: [HealthReminder.ReminderType: Date] = [:]
    private var reminderHistory: [HealthReminder] = []

    // MARK: - Initialization

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
        // TODO: Initialize HealthKit when implementing
        // if HKHealthStore.isHealthDataAvailable() {
        //     self.healthStore = HKHealthStore()
        // }
    }

    // MARK: - BaseAgent Implementation

    func process(context: AIContext) async throws -> AgentResponse {
        do {
            // Get model for health reminder generation
            let service = try await modelManager.getModelForTask(.healthReminder)
            self.modelService = service

            // Check what health reminders are needed
            let reminders = await checkHealthStatus(context: context)

            // Get most urgent reminder
            guard let primaryReminder = reminders.max(by: { $0.urgency < $1.urgency }) else {
                // No reminders needed
                return AgentResponse(
                    agentType: "health",
                    success: true,
                    data: .healthReminder(HealthReminderData(
                        type: "none",
                        message: "All health checks are up to date! Great job!",
                        urgency: "low",
                        dueTime: nil
                    ))
                )
            }

            // Generate AI-enhanced reminder message if needed
            let enhancedMessage = try await enhanceReminderMessage(
                reminder: primaryReminder,
                context: context,
                service: service
            )

            // Track reminder
            trackReminder(primaryReminder)

            return AgentResponse(
                agentType: "health",
                success: true,
                data: .healthReminder(HealthReminderData(
                    type: primaryReminder.type.rawValue,
                    message: enhancedMessage,
                    urgency: primaryReminder.urgency.rawValue,
                    dueTime: primaryReminder.dueTime
                )),
                metadata: [
                    "reminder_type": primaryReminder.type.displayName,
                    "urgency": primaryReminder.urgency.rawValue,
                    "adhd_aware": "true"
                ]
            )
        } catch {
            throw AgentError.processingFailed("Health monitoring failed: \(error.localizedDescription)")
        }
    }

    func warmUp() async throws {
        modelService = try await modelManager.getModel(size: .small)
        // TODO: Request HealthKit permissions
        // requestHealthKitAccess()
    }

    func coolDown() async throws {
        modelService = nil
    }

    // MARK: - Health Status Checking

    private func checkHealthStatus(context: AIContext) async -> [HealthReminder] {
        var reminders: [HealthReminder] = []

        // Check blood sugar monitoring
        if let lastCheck = context.lastBloodSugarCheck {
            let timeSince = Date().timeIntervalSince(lastCheck)
            if timeSince > bloodSugarCheckIntervalHours * 3600 {
                let urgency = determineBloodSugarUrgency(timeSince: timeSince)
                reminders.append(HealthReminder(
                    type: .bloodSugarCheck,
                    message: "Time for a blood sugar check",
                    urgency: urgency,
                    dueTime: Date(),
                    context: "Last check: \(formatTimeSince(timeSince)) ago"
                ))
            }
        } else {
            // No check recorded today
            reminders.append(HealthReminder(
                type: .bloodSugarCheck,
                message: "Haven't seen a blood sugar check today",
                urgency: .medium,
                dueTime: Date(),
                context: "First check of the day"
            ))
        }

        // Check medication
        if !context.medicationTaken {
            let timeOfDay = context.timeOfDay
            let urgency = determineMedicationUrgency(timeOfDay: timeOfDay)
            reminders.append(HealthReminder(
                type: .medication,
                message: "Medication reminder",
                urgency: urgency,
                dueTime: Date(),
                context: "Daily medication not yet taken"
            ))
        }

        // Check meal timing
        if let lastMeal = context.lastMealTime {
            let timeSince = Date().timeIntervalSince(lastMeal)
            if timeSince > mealIntervalHours * 3600 {
                let urgency = determineMealUrgency(timeSince: timeSince)
                reminders.append(HealthReminder(
                    type: .meal,
                    message: "Time to eat something",
                    urgency: urgency,
                    dueTime: Date(),
                    context: "Last meal: \(formatTimeSince(timeSince)) ago"
                ))
            }
        }

        // Check exercise/movement
        let exerciseToday = await getExerciseMinutesToday()
        if exerciseToday < exerciseGoalMinutesPerDay {
            reminders.append(HealthReminder(
                type: .exercise,
                message: "Movement reminder",
                urgency: .low,
                dueTime: Date(),
                context: "\(Int(exerciseToday)) of \(Int(exerciseGoalMinutesPerDay)) minutes today"
            ))
        }

        return reminders
    }

    // MARK: - Urgency Determination

    private func determineBloodSugarUrgency(timeSince: TimeInterval) -> HealthReminder.UrgencyLevel {
        let hours = timeSince / 3600

        if hours > 8 {
            return .critical
        } else if hours > 6 {
            return .high
        } else if hours > 4 {
            return .medium
        } else {
            return .low
        }
    }

    private func determineMedicationUrgency(timeOfDay: TimeOfDay) -> HealthReminder.UrgencyLevel {
        // Medication is more urgent at typical dosing times
        switch timeOfDay {
        case .morning:
            return .high  // Morning dose
        case .evening:
            return .high  // Evening dose
        case .night, .lateNight:
            return .critical  // Very late, might be missed
        default:
            return .medium
        }
    }

    private func determineMealUrgency(timeSince: TimeInterval) -> HealthReminder.UrgencyLevel {
        let hours = timeSince / 3600

        if hours > 8 {
            return .critical  // Dangerously long without food
        } else if hours > 6 {
            return .high
        } else if hours > 5 {
            return .medium
        } else {
            return .low
        }
    }

    // MARK: - Message Enhancement

    private func enhanceReminderMessage(
        reminder: HealthReminder,
        context: AIContext,
        service: LFMService
    ) async throws -> String {
        // For critical urgency, use direct message
        if reminder.urgency == .critical {
            return generateCriticalMessage(reminder: reminder)
        }

        // For lower urgency, use AI to create supportive message
        let systemPrompt = PromptTemplates.healthReminderSystem

        let userPrompt = PromptTemplates.healthReminder(
            type: reminder.type.displayName,
            lastAction: reminder.context,
            urgency: reminder.urgency.rawValue
        )

        let aiMessage = try await service.generate(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            parameters: .balanced
        )

        return aiMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateCriticalMessage(reminder: HealthReminder) -> String {
        switch reminder.type {
        case .bloodSugarCheck:
            return "⚠️ It's been over 8 hours since your last blood sugar check. Please check now."
        case .medication:
            return "⚠️ Important: Time to take your medication. Don't skip this one."
        case .meal:
            return "⚠️ You haven't eaten in a long time. Your blood sugar needs attention - please eat something soon."
        case .exercise:
            return "Consider some gentle movement today for your health."
        case .hydration:
            return "⚠️ Remember to drink water - especially important for managing blood sugar."
        case .doctorAppointment:
            return "⚠️ You have a doctor's appointment today. Don't miss it!"
        }
    }

    // MARK: - Pattern Recognition

    func analyzeHealthPatterns(days: Int = 7) async -> [HealthPattern] {
        // TODO: Implement actual health data analysis using HealthKit
        /*
        guard let healthStore = healthStore else { return [] }

        // Analyze blood sugar trends
        // Analyze medication adherence
        // Analyze meal timing consistency
        // Analyze exercise patterns
        */

        // Mock implementation
        return [
            HealthPattern(
                type: .medicationAdherence,
                trend: .stable,
                confidence: 0.85,
                recommendation: "Medication adherence is good - keep it up!"
            )
        ]
    }

    // MARK: - Tracking

    private func trackReminder(_ reminder: HealthReminder) {
        lastReminderSent[reminder.type] = Date()
        reminderHistory.append(reminder)

        // Keep only last 50 reminders
        if reminderHistory.count > 50 {
            reminderHistory.removeFirst()
        }
    }

    func getReminderHistory(type: HealthReminder.ReminderType? = nil) -> [HealthReminder] {
        if let type = type {
            return reminderHistory.filter { $0.type == type }
        }
        return reminderHistory
    }

    // MARK: - HealthKit Integration (Placeholder)

    private func requestHealthKitAccess() {
        // TODO: Implement when adding HealthKit
        /*
        guard let healthStore = healthStore else { return }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("✓ HealthAgent: HealthKit access granted")
            } else {
                print("✗ HealthAgent: HealthKit access denied")
            }
        }
        */
    }

    private func getExerciseMinutesToday() async -> Double {
        // TODO: Implement actual HealthKit query
        /*
        guard let healthStore = healthStore else { return 0 }

        let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        // Query and sum exercise minutes
        */

        // Mock implementation
        return Double.random(in: 0...45)
    }

    func logBloodSugar(_ value: Double, unit: String = "mg/dL") async {
        // TODO: Save to HealthKit
        /*
        guard let healthStore = healthStore else { return }

        let bloodGlucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        let quantity = HKQuantity(unit: HKUnit(from: "mg/dL"), doubleValue: value)
        let sample = HKQuantitySample(type: bloodGlucoseType, quantity: quantity, start: Date(), end: Date())

        try? await healthStore.save(sample)
        */

        print("✓ HealthAgent: Logged blood sugar - \(value) \(unit)")
    }

    func logMedication(name: String, dosage: String) async {
        // TODO: Save medication adherence
        print("✓ HealthAgent: Logged medication - \(name) \(dosage)")
    }

    // MARK: - Utility

    private func formatTimeSince(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension HealthAgent {
    static func preview(modelManager: ModelManager = ModelManager()) -> HealthAgent {
        HealthAgent(modelManager: modelManager)
    }
}
#endif
