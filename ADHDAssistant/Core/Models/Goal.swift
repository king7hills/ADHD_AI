//
//  Goal.swift
//  ADHDAssistant
//
//  Goal model for organizing and tracking long-term objectives
//

import Foundation

/// Categories for goal organization
enum GoalCategory: String, Codable, CaseIterable {
    case health
    case work
    case personal
    case home
    case fitness
    case finance
    case learning

    var displayName: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .health: return "heart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .home: return "house.fill"
        case .fitness: return "figure.run"
        case .finance: return "dollarsign.circle.fill"
        case .learning: return "book.fill"
        }
    }

    var colorName: String {
        switch self {
        case .health: return "healthRed"
        case .work: return "workBlue"
        case .personal: return "personalPurple"
        case .home: return "homeOrange"
        case .fitness: return "fitnessGreen"
        case .finance: return "financeGold"
        case .learning: return "learningTeal"
        }
    }
}

/// Goal model for long-term objective tracking
struct Goal: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    var category: GoalCategory
    var targetDate: Date?
    var taskIds: [UUID] // References to associated tasks
    var createdAt: Date
    var isActive: Bool
    var milestones: [Milestone]
    var notes: String?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        category: GoalCategory,
        targetDate: Date? = nil,
        taskIds: [UUID] = [],
        createdAt: Date = Date(),
        isActive: Bool = true,
        milestones: [Milestone] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.targetDate = targetDate
        self.taskIds = taskIds
        self.createdAt = createdAt
        self.isActive = isActive
        self.milestones = milestones
        self.notes = notes
    }

    // MARK: - Nested Types

    /// Milestone within a goal
    struct Milestone: Identifiable, Codable, Hashable {
        let id: UUID
        var title: String
        var targetDate: Date?
        var isCompleted: Bool
        var completedAt: Date?

        init(
            id: UUID = UUID(),
            title: String,
            targetDate: Date? = nil,
            isCompleted: Bool = false,
            completedAt: Date? = nil
        ) {
            self.id = id
            self.title = title
            self.targetDate = targetDate
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

    // MARK: - Computed Properties

    /// Calculate progress based on completed tasks
    func progress(completedTaskIds: Set<UUID>) -> Double {
        guard !taskIds.isEmpty else { return 0.0 }
        let completedCount = taskIds.filter { completedTaskIds.contains($0) }.count
        return Double(completedCount) / Double(taskIds.count)
    }

    /// Whether the goal is past its target date
    var isOverdue: Bool {
        guard let targetDate = targetDate else { return false }
        return Date() > targetDate && !isCompleted(completedTaskIds: [])
    }

    /// Whether all associated tasks are completed
    func isCompleted(completedTaskIds: Set<UUID>) -> Bool {
        guard !taskIds.isEmpty else { return false }
        return taskIds.allSatisfy { completedTaskIds.contains($0) }
    }

    /// Days remaining until target date (negative if overdue)
    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day
    }

    /// Milestone completion percentage
    var milestoneProgress: Double {
        guard !milestones.isEmpty else { return 0.0 }
        let completedCount = milestones.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(milestones.count)
    }

    // MARK: - Methods

    /// Add a task to the goal
    mutating func addTask(_ taskId: UUID) {
        if !taskIds.contains(taskId) {
            taskIds.append(taskId)
        }
    }

    /// Remove a task from the goal
    mutating func removeTask(_ taskId: UUID) {
        taskIds.removeAll { $0 == taskId }
    }

    /// Update progress (placeholder for future analytics)
    mutating func updateProgress(completedTaskIds: Set<UUID>) {
        // Progress is computed, but this method can be used for
        // future analytics or caching optimizations
    }

    /// Add a milestone
    mutating func addMilestone(_ milestone: Milestone) {
        milestones.append(milestone)
    }

    /// Remove a milestone
    mutating func removeMilestone(withId id: UUID) {
        milestones.removeAll { $0.id == id }
    }

    /// Toggle milestone completion
    mutating func toggleMilestone(withId id: UUID) {
        if let index = milestones.firstIndex(where: { $0.id == id }) {
            if milestones[index].isCompleted {
                milestones[index].uncomplete()
            } else {
                milestones[index].complete()
            }
        }
    }

    /// Archive the goal (mark as inactive)
    mutating func archive() {
        isActive = false
    }

    /// Reactivate the goal
    mutating func reactivate() {
        isActive = true
    }

    /// Extend target date
    mutating func extendTargetDate(by days: Int) {
        if let targetDate = targetDate {
            self.targetDate = Calendar.current.date(byAdding: .day, value: days, to: targetDate)
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension Goal {
    static let healthGoalSample = Goal(
        title: "Manage Type 2 Diabetes",
        description: "Maintain healthy blood sugar levels and develop sustainable habits",
        category: .health,
        targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
        taskIds: [],
        milestones: [
            Milestone(
                title: "Complete first week of glucose monitoring",
                targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            ),
            Milestone(
                title: "Establish consistent meal schedule",
                targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())
            ),
            Milestone(
                title: "Achieve target A1C level",
                targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
            )
        ]
    )

    static let fitnessGoalSample = Goal(
        title: "Build Regular Exercise Habit",
        description: "Exercise 3 times per week for 30 minutes",
        category: .fitness,
        targetDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
        taskIds: [],
        milestones: [
            Milestone(
                title: "Complete first week of daily walks",
                targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                isCompleted: true,
                completedAt: Date().addingTimeInterval(-86400)
            ),
            Milestone(
                title: "Reach 10,000 steps per day consistently",
                targetDate: Calendar.current.date(byAdding: .day, value: 21, to: Date())
            )
        ]
    )

    static let workGoalSample = Goal(
        title: "Complete Project Alpha",
        description: "Deliver the new feature set for Q1",
        category: .work,
        targetDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        taskIds: [],
        isActive: true,
        milestones: [
            Milestone(title: "Requirements gathering", isCompleted: true),
            Milestone(title: "Design phase", isCompleted: true),
            Milestone(title: "Implementation"),
            Milestone(title: "Testing and QA"),
            Milestone(title: "Deployment")
        ]
    )

    static let learningGoalSample = Goal(
        title: "Learn SwiftUI",
        description: "Master SwiftUI fundamentals and build production apps",
        category: .learning,
        targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
        taskIds: [],
        milestones: [
            Milestone(title: "Complete SwiftUI basics course"),
            Milestone(title: "Build first app"),
            Milestone(title: "Learn advanced animations"),
            Milestone(title: "Publish app to App Store")
        ]
    )
}
#endif
