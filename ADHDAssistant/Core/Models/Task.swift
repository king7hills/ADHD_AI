//
//  Task.swift
//  ADHDAssistant
//
//  Core task model for ADHD Executive Function Assistant
//

import Foundation

/// Represents the current status of a task
enum TaskStatus: String, Codable, CaseIterable {
    case created
    case scheduled
    case active
    case snoozed
    case completed
    case partiallyCompleted
    case skipped

    var displayName: String {
        switch self {
        case .created: return "Created"
        case .scheduled: return "Scheduled"
        case .active: return "Active"
        case .snoozed: return "Snoozed"
        case .completed: return "Completed"
        case .partiallyCompleted: return "Partially Completed"
        case .skipped: return "Skipped"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .partiallyCompleted, .skipped:
            return true
        default:
            return false
        }
    }
}

/// Task priority levels
enum Priority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case critical

    var displayName: String {
        rawValue.capitalized
    }

    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    var pointsMultiplier: Double {
        switch self {
        case .critical: return 2.0
        case .high: return 1.5
        case .medium: return 1.0
        case .low: return 0.75
        }
    }
}

/// Subtask within a main task
struct Subtask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    mutating func complete() {
        isCompleted = true
        completedAt = Date()
    }

    mutating func uncomplete() {
        isCompleted = false
        completedAt = nil
    }
}

/// Recurrence pattern for repeating tasks
struct RecurrenceRule: Codable, Hashable {
    enum Frequency: String, Codable {
        case daily
        case weekly
        case monthly

        var displayName: String {
            rawValue.capitalized
        }
    }

    var frequency: Frequency
    var interval: Int // Every N days/weeks/months
    var daysOfWeek: [Int]? // 1 = Sunday, 7 = Saturday (for weekly tasks)
    var endDate: Date?

    init(frequency: Frequency, interval: Int = 1, daysOfWeek: [Int]? = nil, endDate: Date? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
    }

    /// Generate next occurrence date from a given date
    func nextOccurrence(after date: Date) -> Date? {
        guard endDate == nil || date < endDate! else {
            return nil
        }

        let calendar = Calendar.current
        var nextDate: Date?

        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
                // Find next matching day of week
                var searchDate = date
                for _ in 0..<7 {
                    searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                    let weekday = calendar.component(.weekday, from: searchDate)
                    if daysOfWeek.contains(weekday) {
                        nextDate = searchDate
                        break
                    }
                }
            } else {
                nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: date)
            }
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: interval, to: date)
        }

        if let endDate = endDate, let nextDate = nextDate, nextDate > endDate {
            return nil
        }

        return nextDate
    }
}

/// Main Task model
struct Task: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    var parentGoalId: UUID?
    var estimatedDuration: TimeInterval // in seconds
    var actualDuration: TimeInterval?
    var scheduledTime: Date?
    var completedAt: Date?
    var status: TaskStatus
    var priority: Priority
    var subtasks: [Subtask]
    var recurrence: RecurrenceRule?
    var tags: [String]
    var aiGenerated: Bool
    var pointsValue: Int
    var createdAt: Date
    var startTrigger: String? // Optional context for when to start this task

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        parentGoalId: UUID? = nil,
        estimatedDuration: TimeInterval = 900, // Default 15 minutes
        actualDuration: TimeInterval? = nil,
        scheduledTime: Date? = nil,
        completedAt: Date? = nil,
        status: TaskStatus = .created,
        priority: Priority = .medium,
        subtasks: [Subtask] = [],
        recurrence: RecurrenceRule? = nil,
        tags: [String] = [],
        aiGenerated: Bool = false,
        pointsValue: Int = 10,
        createdAt: Date = Date(),
        startTrigger: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.parentGoalId = parentGoalId
        self.estimatedDuration = estimatedDuration
        self.actualDuration = actualDuration
        self.scheduledTime = scheduledTime
        self.completedAt = completedAt
        self.status = status
        self.priority = priority
        self.subtasks = subtasks
        self.recurrence = recurrence
        self.tags = tags
        self.aiGenerated = aiGenerated
        self.pointsValue = pointsValue
        self.createdAt = createdAt
        self.startTrigger = startTrigger
    }

    // MARK: - Computed Properties

    /// Whether the task is past its scheduled time
    var isOverdue: Bool {
        guard let scheduledTime = scheduledTime else { return false }
        return Date() > scheduledTime && !status.isTerminal
    }

    /// Whether the task has been completed
    var isCompleted: Bool {
        status == .completed
    }

    /// Time remaining until scheduled time (negative if overdue)
    var remainingTime: TimeInterval? {
        guard let scheduledTime = scheduledTime else { return nil }
        return scheduledTime.timeIntervalSinceNow
    }

    /// Percentage of subtasks completed (0.0 to 1.0)
    var completionPercentage: Double {
        guard !subtasks.isEmpty else { return status == .completed ? 1.0 : 0.0 }
        let completedCount = subtasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(subtasks.count)
    }

    /// Total points for this task including priority multiplier
    var totalPoints: Int {
        Int(Double(pointsValue) * priority.pointsMultiplier)
    }

    /// Formatted duration string
    var estimatedDurationFormatted: String {
        let hours = Int(estimatedDuration) / 3600
        let minutes = Int(estimatedDuration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Methods

    /// Mark task as completed
    mutating func complete(at date: Date = Date()) {
        status = .completed
        completedAt = date

        // Mark all subtasks as completed
        for index in subtasks.indices {
            if !subtasks[index].isCompleted {
                subtasks[index].complete()
            }
        }
    }

    /// Mark task as partially completed (some subtasks done)
    mutating func partiallyComplete(at date: Date = Date()) {
        status = .partiallyCompleted
        completedAt = date
    }

    /// Skip this task
    mutating func skip(at date: Date = Date()) {
        status = .skipped
        completedAt = date
    }

    /// Start working on the task
    mutating func start() {
        status = .active
    }

    /// Snooze the task for later
    mutating func snooze(until time: Date) {
        status = .snoozed
        scheduledTime = time
    }

    /// Add a subtask
    mutating func addSubtask(_ subtask: Subtask) {
        subtasks.append(subtask)
    }

    /// Remove a subtask by ID
    mutating func removeSubtask(withId id: UUID) {
        subtasks.removeAll { $0.id == id }
    }

    /// Toggle subtask completion
    mutating func toggleSubtask(withId id: UUID) {
        if let index = subtasks.firstIndex(where: { $0.id == id }) {
            subtasks[index].isCompleted.toggle()
            if subtasks[index].isCompleted {
                subtasks[index].completedAt = Date()
            } else {
                subtasks[index].completedAt = nil
            }
        }
    }

    /// Record actual duration spent on task
    mutating func recordDuration(_ duration: TimeInterval) {
        actualDuration = duration
    }

    /// Calculate estimation accuracy (returns nil if not yet completed with actual duration)
    var estimationAccuracy: Double? {
        guard let actualDuration = actualDuration, actualDuration > 0 else { return nil }
        return estimatedDuration / actualDuration
    }

    /// Create next occurrence for recurring task
    func createNextOccurrence() -> Task? {
        guard let recurrence = recurrence,
              let nextDate = recurrence.nextOccurrence(after: scheduledTime ?? Date()) else {
            return nil
        }

        return Task(
            title: title,
            description: description,
            parentGoalId: parentGoalId,
            estimatedDuration: estimatedDuration,
            scheduledTime: nextDate,
            status: .scheduled,
            priority: priority,
            subtasks: subtasks.map { Subtask(title: $0.title) }, // Reset subtasks
            recurrence: recurrence,
            tags: tags,
            aiGenerated: aiGenerated,
            pointsValue: pointsValue,
            startTrigger: startTrigger
        )
    }
}

// MARK: - Sample Data

#if DEBUG
extension Task {
    static let sample = Task(
        title: "Review morning medications",
        description: "Check and take morning medications including metformin",
        estimatedDuration: 300, // 5 minutes
        scheduledTime: Date().addingTimeInterval(3600),
        status: .scheduled,
        priority: .high,
        subtasks: [
            Subtask(title: "Take metformin"),
            Subtask(title: "Record in health log")
        ],
        tags: ["health", "medication"],
        pointsValue: 15
    )

    static let sampleWithRecurrence = Task(
        title: "Daily exercise",
        description: "30-minute walk or light exercise",
        estimatedDuration: 1800, // 30 minutes
        scheduledTime: Date().addingTimeInterval(7200),
        status: .scheduled,
        priority: .medium,
        recurrence: RecurrenceRule(frequency: .daily, interval: 1),
        tags: ["fitness", "health"],
        pointsValue: 20
    )

    static let aiGeneratedSample = Task(
        title: "Prepare healthy lunch",
        description: "AI suggested: Low-carb meal with vegetables and protein",
        estimatedDuration: 1200, // 20 minutes
        scheduledTime: Date().addingTimeInterval(10800),
        status: .created,
        priority: .medium,
        subtasks: [
            Subtask(title: "Choose recipe"),
            Subtask(title: "Gather ingredients"),
            Subtask(title: "Cook meal")
        ],
        tags: ["health", "nutrition", "cooking"],
        aiGenerated: true,
        pointsValue: 15
    )
}
#endif
