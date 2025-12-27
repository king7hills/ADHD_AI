//
//  HealthMetric.swift
//  ADHDAssistant
//
//  Health tracking and monitoring models
//

import Foundation

/// Types of health metrics that can be tracked
enum HealthMetricType: String, Codable, CaseIterable {
    case bloodSugar
    case medication
    case meal
    case exercise
    case weight
    case bloodPressure

    var displayName: String {
        switch self {
        case .bloodSugar: return "Blood Sugar"
        case .medication: return "Medication"
        case .meal: return "Meal"
        case .exercise: return "Exercise"
        case .weight: return "Weight"
        case .bloodPressure: return "Blood Pressure"
        }
    }

    var iconName: String {
        switch self {
        case .bloodSugar: return "drop.fill"
        case .medication: return "pills.fill"
        case .meal: return "fork.knife"
        case .exercise: return "figure.walk"
        case .weight: return "scalemass.fill"
        case .bloodPressure: return "heart.fill"
        }
    }

    var unit: String {
        switch self {
        case .bloodSugar: return "mg/dL"
        case .medication: return ""
        case .meal: return ""
        case .exercise: return "minutes"
        case .weight: return "lbs"
        case .bloodPressure: return "mmHg"
        }
    }
}

/// Blood sugar reading with classification
struct BloodSugarReading: Codable, Hashable {
    var value: Double // in mg/dL
    var timing: MealTiming
    var recordedAt: Date

    enum MealTiming: String, Codable, CaseIterable {
        case fasting
        case beforeMeal
        case afterMeal
        case bedtime
        case random

        var displayName: String {
            switch self {
            case .fasting: return "Fasting"
            case .beforeMeal: return "Before Meal"
            case .afterMeal: return "After Meal"
            case .bedtime: return "Bedtime"
            case .random: return "Random"
            }
        }
    }

    enum Level: String {
        case low
        case normal
        case elevated
        case high

        var displayName: String {
            rawValue.capitalized
        }

        var colorName: String {
            switch self {
            case .low: return "bloodSugarLow"
            case .normal: return "bloodSugarNormal"
            case .elevated: return "bloodSugarElevated"
            case .high: return "bloodSugarHigh"
            }
        }
    }

    init(value: Double, timing: MealTiming, recordedAt: Date = Date()) {
        self.value = value
        self.timing = timing
        self.recordedAt = recordedAt
    }

    /// Classify blood sugar level based on timing and value
    var level: Level {
        switch timing {
        case .fasting:
            if value < 70 { return .low }
            if value <= 100 { return .normal }
            if value <= 125 { return .elevated }
            return .high

        case .beforeMeal:
            if value < 70 { return .low }
            if value <= 130 { return .normal }
            if value <= 180 { return .elevated }
            return .high

        case .afterMeal:
            if value < 70 { return .low }
            if value <= 180 { return .normal }
            if value <= 250 { return .elevated }
            return .high

        case .bedtime:
            if value < 100 { return .low }
            if value <= 140 { return .normal }
            if value <= 180 { return .elevated }
            return .high

        case .random:
            if value < 70 { return .low }
            if value <= 140 { return .normal }
            if value <= 200 { return .elevated }
            return .high
        }
    }

    /// Whether this reading requires attention
    var requiresAttention: Bool {
        level == .low || level == .high
    }

    /// Formatted value string
    var formattedValue: String {
        String(format: "%.0f mg/dL", value)
    }
}

/// Medication log entry
struct MedicationLog: Codable, Hashable {
    var medicationName: String
    var dosage: String
    var taken: Bool
    var scheduledTime: Date
    var actualTime: Date?
    var notes: String?

    init(
        medicationName: String,
        dosage: String,
        taken: Bool = false,
        scheduledTime: Date,
        actualTime: Date? = nil,
        notes: String? = nil
    ) {
        self.medicationName = medicationName
        self.dosage = dosage
        self.taken = taken
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.notes = notes
    }

    /// Whether medication was taken on time (within 30 minutes)
    var takenOnTime: Bool {
        guard let actualTime = actualTime else { return false }
        let timeDifference = abs(actualTime.timeIntervalSince(scheduledTime))
        return timeDifference <= 1800 // 30 minutes
    }

    /// Whether medication is overdue
    var isOverdue: Bool {
        !taken && Date() > scheduledTime
    }

    /// Mark as taken
    mutating func markTaken(at time: Date = Date()) {
        taken = true
        actualTime = time
    }
}

/// Blood pressure reading
struct BloodPressureReading: Codable, Hashable {
    var systolic: Int
    var diastolic: Int
    var heartRate: Int?
    var recordedAt: Date

    enum Classification: String {
        case normal
        case elevated
        case hypertensionStage1
        case hypertensionStage2
        case hypertensiveCrisis

        var displayName: String {
            switch self {
            case .normal: return "Normal"
            case .elevated: return "Elevated"
            case .hypertensionStage1: return "Hypertension Stage 1"
            case .hypertensionStage2: return "Hypertension Stage 2"
            case .hypertensiveCrisis: return "Hypertensive Crisis"
            }
        }

        var requiresAttention: Bool {
            self == .hypertensionStage2 || self == .hypertensiveCrisis
        }
    }

    init(systolic: Int, diastolic: Int, heartRate: Int? = nil, recordedAt: Date = Date()) {
        self.systolic = systolic
        self.diastolic = diastolic
        self.heartRate = heartRate
        self.recordedAt = recordedAt
    }

    /// Classify blood pressure according to AHA guidelines
    var classification: Classification {
        if systolic >= 180 || diastolic >= 120 {
            return .hypertensiveCrisis
        } else if systolic >= 140 || diastolic >= 90 {
            return .hypertensionStage2
        } else if systolic >= 130 || diastolic >= 80 {
            return .hypertensionStage1
        } else if systolic >= 120 && diastolic < 80 {
            return .elevated
        } else {
            return .normal
        }
    }

    /// Formatted reading string
    var formattedValue: String {
        if let heartRate = heartRate {
            return "\(systolic)/\(diastolic) mmHg, \(heartRate) bpm"
        } else {
            return "\(systolic)/\(diastolic) mmHg"
        }
    }
}

/// Main health metric model
struct HealthMetric: Identifiable, Codable, Hashable {
    let id: UUID
    var type: HealthMetricType
    var value: Double
    var unit: String
    var recordedAt: Date
    var notes: String?

    // Type-specific data (stored as JSON-encoded strings)
    var bloodSugarReading: BloodSugarReading?
    var medicationLog: MedicationLog?
    var bloodPressureReading: BloodPressureReading?

    init(
        id: UUID = UUID(),
        type: HealthMetricType,
        value: Double,
        unit: String? = nil,
        recordedAt: Date = Date(),
        notes: String? = nil,
        bloodSugarReading: BloodSugarReading? = nil,
        medicationLog: MedicationLog? = nil,
        bloodPressureReading: BloodPressureReading? = nil
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit ?? type.unit
        self.recordedAt = recordedAt
        self.notes = notes
        self.bloodSugarReading = bloodSugarReading
        self.medicationLog = medicationLog
        self.bloodPressureReading = bloodPressureReading
    }

    // MARK: - Convenience Initializers

    /// Create a blood sugar metric
    static func bloodSugar(reading: BloodSugarReading, notes: String? = nil) -> HealthMetric {
        HealthMetric(
            type: .bloodSugar,
            value: reading.value,
            unit: "mg/dL",
            recordedAt: reading.recordedAt,
            notes: notes,
            bloodSugarReading: reading
        )
    }

    /// Create a medication metric
    static func medication(log: MedicationLog, notes: String? = nil) -> HealthMetric {
        HealthMetric(
            type: .medication,
            value: log.taken ? 1.0 : 0.0,
            unit: "",
            recordedAt: log.actualTime ?? log.scheduledTime,
            notes: notes,
            medicationLog: log
        )
    }

    /// Create a blood pressure metric
    static func bloodPressure(reading: BloodPressureReading, notes: String? = nil) -> HealthMetric {
        HealthMetric(
            type: .bloodPressure,
            value: Double(reading.systolic),
            unit: "mmHg",
            recordedAt: reading.recordedAt,
            notes: notes,
            bloodPressureReading: reading
        )
    }

    /// Create a weight metric
    static func weight(value: Double, recordedAt: Date = Date(), notes: String? = nil) -> HealthMetric {
        HealthMetric(
            type: .weight,
            value: value,
            unit: "lbs",
            recordedAt: recordedAt,
            notes: notes
        )
    }

    /// Create an exercise metric
    static func exercise(minutes: Double, recordedAt: Date = Date(), notes: String? = nil) -> HealthMetric {
        HealthMetric(
            type: .exercise,
            value: minutes,
            unit: "minutes",
            recordedAt: recordedAt,
            notes: notes
        )
    }

    /// Create a meal metric
    static func meal(description: String, recordedAt: Date = Date()) -> HealthMetric {
        HealthMetric(
            type: .meal,
            value: 1.0,
            unit: "",
            recordedAt: recordedAt,
            notes: description
        )
    }

    // MARK: - Computed Properties

    /// Whether this metric requires immediate attention
    var requiresAttention: Bool {
        if let bloodSugar = bloodSugarReading {
            return bloodSugar.requiresAttention
        }
        if let bloodPressure = bloodPressureReading {
            return bloodPressure.classification.requiresAttention
        }
        if let medication = medicationLog {
            return medication.isOverdue
        }
        return false
    }

    /// Formatted value string
    var formattedValue: String {
        if let bloodSugar = bloodSugarReading {
            return bloodSugar.formattedValue
        }
        if let bloodPressure = bloodPressureReading {
            return bloodPressure.formattedValue
        }
        if let medication = medicationLog {
            return "\(medication.medicationName) - \(medication.dosage)"
        }

        if unit.isEmpty {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.1f %@", value, unit)
        }
    }

    /// Display title for the metric
    var displayTitle: String {
        switch type {
        case .medication:
            return medicationLog?.medicationName ?? "Medication"
        case .meal:
            return notes ?? "Meal"
        default:
            return type.displayName
        }
    }
}

// MARK: - Extensions

extension Array where Element == HealthMetric {
    /// Filter metrics by date range
    func filtered(from startDate: Date, to endDate: Date) -> [HealthMetric] {
        filter { $0.recordedAt >= startDate && $0.recordedAt <= endDate }
    }

    /// Filter by type
    func filtered(by type: HealthMetricType) -> [HealthMetric] {
        filter { $0.type == type }
    }

    /// Get metrics from today
    var today: [HealthMetric] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return filtered(from: startOfDay, to: endOfDay)
    }

    /// Average value for numeric metrics
    var averageValue: Double? {
        guard !isEmpty else { return nil }
        return reduce(0.0) { $0 + $1.value } / Double(count)
    }
}

// MARK: - Sample Data

#if DEBUG
extension HealthMetric {
    static let sampleBloodSugar = HealthMetric.bloodSugar(
        reading: BloodSugarReading(
            value: 105,
            timing: .fasting,
            recordedAt: Date()
        ),
        notes: "Morning reading before breakfast"
    )

    static let sampleMedication = HealthMetric.medication(
        log: MedicationLog(
            medicationName: "Metformin",
            dosage: "500mg",
            taken: true,
            scheduledTime: Date().addingTimeInterval(-3600),
            actualTime: Date().addingTimeInterval(-3500)
        )
    )

    static let sampleBloodPressure = HealthMetric.bloodPressure(
        reading: BloodPressureReading(
            systolic: 118,
            diastolic: 76,
            heartRate: 72
        ),
        notes: "Resting measurement"
    )

    static let sampleWeight = HealthMetric.weight(
        value: 175.5,
        notes: "Morning weight"
    )

    static let sampleExercise = HealthMetric.exercise(
        minutes: 30,
        notes: "Morning walk around the neighborhood"
    )
}
#endif
