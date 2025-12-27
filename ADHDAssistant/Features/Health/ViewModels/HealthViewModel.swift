//
//  HealthViewModel.swift
//  ADHDAssistant
//
//  ViewModel for Health Feature - Diabetes Management
//

import Foundation
import SwiftUI
import Combine

/// Trend direction for blood sugar readings
enum BloodSugarTrend {
    case rising
    case falling
    case stable

    var icon: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var description: String {
        switch self {
        case .rising: return "Rising"
        case .falling: return "Falling"
        case .stable: return "Stable"
        }
    }
}

/// Status of a medication for today
struct MedicationStatus: Identifiable, Hashable {
    let id = UUID()
    var medication: MedicationLog
    var isTaken: Bool
    var isOverdue: Bool

    var displayTime: String {
        medication.scheduledTime.shortTimeString
    }
}

/// ViewModel for the Health Feature
@MainActor
class HealthViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var latestBloodSugar: HealthMetric?
    @Published private(set) var todayMedications: [MedicationStatus] = []
    @Published private(set) var recentMetrics: [HealthMetric] = []
    @Published private(set) var bloodSugarTrend: BloodSugarTrend = .stable
    @Published private(set) var healthStreak: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // Exercise tracking
    @Published private(set) var todayExerciseMinutes: Int = 0
    @Published private(set) var exerciseGoal: Int = 30

    // Meal tracking
    @Published private(set) var lastMealTime: Date?
    @Published private(set) var mealsLoggedToday: Int = 0

    // MARK: - Dependencies

    private let healthRepository: HealthRepositoryProtocol
    private let gamificationCoordinator: GamificationCoordinator
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        healthRepository: HealthRepositoryProtocol = HealthRepository(),
        gamificationCoordinator: GamificationCoordinator = GamificationCoordinator()
    ) {
        self.healthRepository = healthRepository
        self.gamificationCoordinator = gamificationCoordinator

        setupSubscriptions()

        // Initial data load
        Task {
            await fetchHealthData()
        }
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to repository changes
        healthRepository.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.updateFromMetrics(metrics)
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Fetching

    func fetchHealthData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch today's metrics
            let todayMetrics = try await healthRepository.fetchToday()
            recentMetrics = Array(todayMetrics.prefix(10))

            // Update latest blood sugar
            let bloodSugarMetrics = todayMetrics.filter { $0.type == .bloodSugar }
            latestBloodSugar = bloodSugarMetrics.first

            // Calculate blood sugar trend
            await calculateBloodSugarTrend()

            // Update medications
            await updateMedications()

            // Calculate exercise
            calculateExerciseMinutes(from: todayMetrics)

            // Calculate meals
            calculateMeals(from: todayMetrics)

            // Calculate health streak
            await calculateHealthStreak()

            isLoading = false
        } catch {
            errorMessage = "Failed to load health data: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Blood Sugar Logging

    func logBloodSugar(value: Double, context: BloodSugarReading.MealTiming, notes: String? = nil) async {
        let reading = BloodSugarReading(
            value: value,
            timing: context,
            recordedAt: Date()
        )

        let metric = HealthMetric.bloodSugar(reading: reading, notes: notes)

        do {
            _ = try await healthRepository.create(metric)

            // Award points through gamification
            gamificationCoordinator.processEvent(.healthMetricLogged(metric))

            // Update UI
            latestBloodSugar = metric
            await fetchHealthData()

            // Provide haptic feedback
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to log blood sugar: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }

    // MARK: - Medication Logging

    func logMedication(name: String, dosage: String = "Standard", scheduledTime: Date? = nil) async {
        let scheduled = scheduledTime ?? Date()
        var medicationLog = MedicationLog(
            medicationName: name,
            dosage: dosage,
            taken: false,
            scheduledTime: scheduled
        )

        medicationLog.markTaken()

        let metric = HealthMetric.medication(log: medicationLog)

        do {
            _ = try await healthRepository.create(metric)

            // Award points
            gamificationCoordinator.processEvent(.healthMetricLogged(metric))

            // Update medications list
            await updateMedications()
            await fetchHealthData()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to log medication: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }

    func toggleMedication(_ medication: MedicationStatus) async {
        var updatedLog = medication.medication

        if !medication.isTaken {
            updatedLog.markTaken()
        } else {
            updatedLog.taken = false
            updatedLog.actualTime = nil
        }

        let metric = HealthMetric.medication(log: updatedLog)

        do {
            _ = try await healthRepository.create(metric)

            if !medication.isTaken {
                gamificationCoordinator.processEvent(.healthMetricLogged(metric))
                HapticManager.shared.success()
            } else {
                HapticManager.shared.impact(.light)
            }

            await updateMedications()
        } catch {
            errorMessage = "Failed to update medication: \(error.localizedDescription)"
        }
    }

    // MARK: - Meal Logging

    func logMeal(type: String, notes: String? = nil) async {
        let mealDescription = notes ?? type
        let metric = HealthMetric.meal(description: mealDescription, recordedAt: Date())

        do {
            _ = try await healthRepository.create(metric)

            // Award points
            gamificationCoordinator.processEvent(.healthMetricLogged(metric))

            lastMealTime = Date()
            mealsLoggedToday += 1
            await fetchHealthData()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to log meal: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }

    // MARK: - Exercise Logging

    func logExercise(type: String, duration: Int, notes: String? = nil) async {
        let exerciseNotes = notes ?? type
        let metric = HealthMetric.exercise(
            minutes: Double(duration),
            recordedAt: Date(),
            notes: exerciseNotes
        )

        do {
            _ = try await healthRepository.create(metric)

            // Award points
            gamificationCoordinator.processEvent(.healthMetricLogged(metric))

            todayExerciseMinutes += duration
            await fetchHealthData()

            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to log exercise: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }

    // MARK: - Calculations

    private func calculateBloodSugarTrend() async {
        do {
            let metrics = try await healthRepository.fetchByType(.bloodSugar)
            let recent = Array(metrics.prefix(3))

            guard recent.count >= 2,
                  let latest = recent.first,
                  let previous = recent[1].bloodSugarReading else {
                bloodSugarTrend = .stable
                return
            }

            let latestValue = latest.value
            let previousValue = previous.value
            let difference = latestValue - previousValue

            if difference > 20 {
                bloodSugarTrend = .rising
            } else if difference < -20 {
                bloodSugarTrend = .falling
            } else {
                bloodSugarTrend = .stable
            }
        } catch {
            bloodSugarTrend = .stable
        }
    }

    private func updateMedications() async {
        // In a real app, this would fetch from a medication schedule
        // For now, we'll create sample medications
        let calendar = Calendar.current
        let now = Date()

        // Create typical diabetes medication schedule
        let medicationSchedule: [(name: String, dosage: String, hour: Int, minute: Int)] = [
            ("Metformin", "500mg", 8, 0),
            ("Metformin", "500mg", 20, 0)
        ]

        var statuses: [MedicationStatus] = []

        do {
            let todayMedicationMetrics = try await healthRepository.fetchToday()
                .filter { $0.type == .medication }

            for schedule in medicationSchedule {
                guard let scheduledTime = calendar.date(
                    bySettingHour: schedule.hour,
                    minute: schedule.minute,
                    second: 0,
                    of: now
                ) else { continue }

                // Check if this medication was taken today
                let takenMedication = todayMedicationMetrics.first { metric in
                    guard let log = metric.medicationLog else { return false }
                    return log.medicationName == schedule.name &&
                           calendar.isDate(log.scheduledTime, equalTo: scheduledTime, toGranularity: .hour)
                }

                let medicationLog = takenMedication?.medicationLog ?? MedicationLog(
                    medicationName: schedule.name,
                    dosage: schedule.dosage,
                    taken: false,
                    scheduledTime: scheduledTime
                )

                let status = MedicationStatus(
                    medication: medicationLog,
                    isTaken: medicationLog.taken,
                    isOverdue: medicationLog.isOverdue
                )

                statuses.append(status)
            }

            todayMedications = statuses.sorted { $0.medication.scheduledTime < $1.medication.scheduledTime }
        } catch {
            print("Error updating medications: \(error)")
        }
    }

    private func calculateExerciseMinutes(from metrics: [HealthMetric]) {
        let exerciseMetrics = metrics.filter { $0.type == .exercise }
        todayExerciseMinutes = Int(exerciseMetrics.reduce(0) { $0 + $1.value })
    }

    private func calculateMeals(from metrics: [HealthMetric]) {
        let mealMetrics = metrics.filter { $0.type == .meal }
        mealsLoggedToday = mealMetrics.count
        lastMealTime = mealMetrics.first?.recordedAt
    }

    private func calculateHealthStreak() async {
        // Calculate consecutive days of health logging
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        do {
            while true {
                let startOfDay = calendar.startOfDay(for: currentDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    break
                }

                let dayMetrics = try await healthRepository.fetchByDateRange(
                    from: startOfDay,
                    to: endOfDay
                )

                // Consider day "logged" if there's at least one blood sugar reading
                let hasBloodSugar = dayMetrics.contains { $0.type == .bloodSugar }

                if hasBloodSugar {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }

                // Limit to reasonable streak calculation
                if streak > 365 {
                    break
                }
            }

            healthStreak = streak

            // Award streak achievement
            if streak > 0 {
                gamificationCoordinator.processEvent(.healthStreakMaintained(days: streak))
            }
        } catch {
            print("Error calculating health streak: \(error)")
        }
    }

    private func updateFromMetrics(_ metrics: [HealthMetric]) {
        recentMetrics = Array(metrics.prefix(10))

        // Update latest blood sugar
        let bloodSugarMetrics = metrics.filter { $0.type == .bloodSugar }
        if let latest = bloodSugarMetrics.first {
            latestBloodSugar = latest
        }

        // Update calculations
        calculateExerciseMinutes(from: metrics)
        calculateMeals(from: metrics)
    }

    // MARK: - Computed Properties

    var exerciseProgress: Double {
        guard exerciseGoal > 0 else { return 0 }
        return min(Double(todayExerciseMinutes) / Double(exerciseGoal), 1.0)
    }

    var nextMedication: MedicationStatus? {
        todayMedications.first { !$0.isTaken }
    }

    var medicationAdherenceRate: Double {
        guard !todayMedications.isEmpty else { return 0 }
        let taken = todayMedications.filter { $0.isTaken }.count
        return Double(taken) / Double(todayMedications.count)
    }

    var shouldLogBloodSugar: Bool {
        guard let latest = latestBloodSugar else { return true }
        let hoursSinceLastReading = abs(latest.recordedAt.timeIntervalSinceNow) / 3600
        return hoursSinceLastReading >= 2 // Suggest logging every 2 hours
    }

    // MARK: - Helpers

    func bloodSugarColor(for reading: BloodSugarReading?) -> Color {
        guard let reading = reading else { return AppColors.textSecondary }

        switch reading.level {
        case .low:
            return AppColors.bloodSugarLow
        case .normal:
            return AppColors.bloodSugarNormal
        case .elevated:
            return Color(hex: "#F59E0B") // Orange/Warning
        case .high:
            return AppColors.bloodSugarHigh
        }
    }

    func encouragementMessage() -> String {
        let messages = [
            "Great job tracking your health!",
            "You're doing amazing!",
            "Keep up the healthy habits!",
            "Consistency is key!",
            "Proud of your dedication!",
            "One day at a time!",
            "You've got this!",
            "Health is wealth!"
        ]

        if healthStreak > 7 {
            return "🔥 \(healthStreak) day streak! You're on fire!"
        } else if healthStreak > 0 {
            return messages.randomElement() ?? "Keep going!"
        } else {
            return "Let's start your health journey!"
        }
    }
}

// MARK: - Mock ViewModel for Previews

#if DEBUG
class MockHealthViewModel: ObservableObject {
    @Published var latestBloodSugar: HealthMetric? = .sampleBloodSugar
    @Published var todayMedications: [MedicationStatus] = [
        MedicationStatus(
            medication: MedicationLog(
                medicationName: "Metformin",
                dosage: "500mg",
                taken: true,
                scheduledTime: Date().addHours(-2),
                actualTime: Date().addHours(-2)
            ),
            isTaken: true,
            isOverdue: false
        ),
        MedicationStatus(
            medication: MedicationLog(
                medicationName: "Metformin",
                dosage: "500mg",
                taken: false,
                scheduledTime: Date().addHours(2)
            ),
            isTaken: false,
            isOverdue: false
        )
    ]
    @Published var recentMetrics: [HealthMetric] = [.sampleBloodSugar, .sampleMedication]
    @Published var bloodSugarTrend: BloodSugarTrend = .stable
    @Published var healthStreak: Int = 5
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var todayExerciseMinutes: Int = 20
    @Published var exerciseGoal: Int = 30
    @Published var lastMealTime: Date? = Date().addHours(-2)
    @Published var mealsLoggedToday: Int = 2

    var exerciseProgress: Double { 0.67 }
    var nextMedication: MedicationStatus? { todayMedications.last }
    var medicationAdherenceRate: Double { 0.5 }
    var shouldLogBloodSugar: Bool { false }

    func fetchHealthData() async {}
    func logBloodSugar(value: Double, context: BloodSugarReading.MealTiming, notes: String? = nil) async {}
    func logMedication(name: String, dosage: String = "Standard", scheduledTime: Date? = nil) async {}
    func toggleMedication(_ medication: MedicationStatus) async {}
    func logMeal(type: String, notes: String? = nil) async {}
    func logExercise(type: String, duration: Int, notes: String? = nil) async {}
    func bloodSugarColor(for reading: BloodSugarReading?) -> Color { AppColors.bloodSugarNormal }
    func encouragementMessage() -> String { "Great job tracking your health!" }
}
#endif
