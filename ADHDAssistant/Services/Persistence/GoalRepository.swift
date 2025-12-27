//
//  GoalRepository.swift
//  ADHDAssistant
//
//  Repository for Goal entity persistence and retrieval
//

import Foundation
import CoreData
import Combine

// MARK: - Protocol

protocol GoalRepositoryProtocol {
    func create(_ goal: Goal) async throws -> Goal
    func update(_ goal: Goal) async throws -> Goal
    func delete(_ goal: Goal) async throws
    func fetch(by id: UUID) async throws -> Goal?
    func fetchAll() async throws -> [Goal]
    func fetchActive() async throws -> [Goal]
    func fetchCompleted(taskRepository: TaskRepositoryProtocol) async throws -> [Goal]
    func linkTask(_ taskId: UUID, to goalId: UUID) async throws
    func unlinkTask(_ taskId: UUID, from goalId: UUID) async throws
    func calculateProgress(for goalId: UUID, taskRepository: TaskRepositoryProtocol) async throws -> Double

    var goalsPublisher: AnyPublisher<[Goal], Never> { get }
}

// MARK: - Goal Repository Implementation

class GoalRepository: GoalRepositoryProtocol {
    // MARK: - Properties

    private let coreDataStack: CoreDataStack
    private let goalsSubject = CurrentValueSubject<[Goal], Never>([])

    var goalsPublisher: AnyPublisher<[Goal], Never> {
        goalsSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack

        // Subscribe to Core Data changes
        coreDataStack.didSavePublisher
            .sink { [weak self] _ in
                Task {
                    try? await self?.refreshGoals()
                }
            }
            .store(in: &cancellables)

        // Initial load
        Task {
            try? await refreshGoals()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - CRUD Operations

    func create(_ goal: Goal) async throws -> Goal {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let entity = GoalEntity(context: context)
            entity.populate(from: goal)

            try context.save()

            // Refresh goals
            Task {
                try? await self.refreshGoals()
            }

            return goal
        }
    }

    func update(_ goal: Goal) async throws -> Goal {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = GoalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)

            guard let entity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.entityNotFound
            }

            entity.populate(from: goal)

            try context.save()

            // Refresh goals
            Task {
                try? await self.refreshGoals()
            }

            return goal
        }
    }

    func delete(_ goal: Goal) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            let fetchRequest = GoalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)

            guard let entity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.entityNotFound
            }

            context.delete(entity)
            try context.save()

            // Refresh goals
            Task {
                try? await self.refreshGoals()
            }
        }
    }

    // MARK: - Fetch Operations

    func fetch(by id: UUID) async throws -> Goal? {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = GoalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }

            return entity.toGoal()
        }
    }

    func fetchAll() async throws -> [Goal] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = GoalEntity.fetchRequest()
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \GoalEntity.isActive, ascending: false),
                NSSortDescriptor(keyPath: \GoalEntity.targetDate, ascending: true),
                NSSortDescriptor(keyPath: \GoalEntity.createdAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toGoal() }
        }
    }

    func fetchActive() async throws -> [Goal] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = GoalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isActive == YES")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \GoalEntity.targetDate, ascending: true),
                NSSortDescriptor(keyPath: \GoalEntity.createdAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toGoal() }
        }
    }

    func fetchCompleted(taskRepository: TaskRepositoryProtocol) async throws -> [Goal] {
        let goals = try await fetchAll()
        let allTasks = try await taskRepository.fetchAll()

        let completedTaskIds = Set(allTasks.filter { $0.status == .completed }.map { $0.id })

        return goals.filter { goal in
            !goal.taskIds.isEmpty && goal.isCompleted(completedTaskIds: completedTaskIds)
        }
    }

    // MARK: - Task Linking

    func linkTask(_ taskId: UUID, to goalId: UUID) async throws {
        guard var goal = try await fetch(by: goalId) else {
            throw CoreDataError.entityNotFound
        }

        goal.addTask(taskId)
        _ = try await update(goal)
    }

    func unlinkTask(_ taskId: UUID, from goalId: UUID) async throws {
        guard var goal = try await fetch(by: goalId) else {
            throw CoreDataError.entityNotFound
        }

        goal.removeTask(taskId)
        _ = try await update(goal)
    }

    // MARK: - Progress Tracking

    func calculateProgress(for goalId: UUID, taskRepository: TaskRepositoryProtocol) async throws -> Double {
        guard let goal = try await fetch(by: goalId) else {
            return 0.0
        }

        let goalTasks = try await taskRepository.fetchByGoal(goalId)
        let completedTaskIds = Set(goalTasks.filter { $0.status == .completed }.map { $0.id })

        return goal.progress(completedTaskIds: completedTaskIds)
    }

    // MARK: - Helper Methods

    private func refreshGoals() async throws {
        let goals = try await fetchAll()
        goalsSubject.send(goals)
    }
}

// MARK: - Mock Repository for Testing

class MockGoalRepository: GoalRepositoryProtocol {
    private var goals: [Goal] = []
    private let goalsSubject = CurrentValueSubject<[Goal], Never>([])

    var goalsPublisher: AnyPublisher<[Goal], Never> {
        goalsSubject.eraseToAnyPublisher()
    }

    init(initialGoals: [Goal] = []) {
        self.goals = initialGoals
        goalsSubject.send(goals)
    }

    func create(_ goal: Goal) async throws -> Goal {
        goals.append(goal)
        goalsSubject.send(goals)
        return goal
    }

    func update(_ goal: Goal) async throws -> Goal {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            goalsSubject.send(goals)
        }
        return goal
    }

    func delete(_ goal: Goal) async throws {
        goals.removeAll { $0.id == goal.id }
        goalsSubject.send(goals)
    }

    func fetch(by id: UUID) async throws -> Goal? {
        goals.first { $0.id == id }
    }

    func fetchAll() async throws -> [Goal] {
        goals.sorted { g1, g2 in
            if g1.isActive != g2.isActive {
                return g1.isActive
            }
            return (g1.targetDate ?? Date.distantFuture) < (g2.targetDate ?? Date.distantFuture)
        }
    }

    func fetchActive() async throws -> [Goal] {
        goals.filter { $0.isActive }
    }

    func fetchCompleted(taskRepository: TaskRepositoryProtocol) async throws -> [Goal] {
        let allTasks = try await taskRepository.fetchAll()
        let completedTaskIds = Set(allTasks.filter { $0.status == .completed }.map { $0.id })

        return goals.filter { goal in
            !goal.taskIds.isEmpty && goal.isCompleted(completedTaskIds: completedTaskIds)
        }
    }

    func linkTask(_ taskId: UUID, to goalId: UUID) async throws {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].addTask(taskId)
            goalsSubject.send(goals)
        }
    }

    func unlinkTask(_ taskId: UUID, from goalId: UUID) async throws {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].removeTask(taskId)
            goalsSubject.send(goals)
        }
    }

    func calculateProgress(for goalId: UUID, taskRepository: TaskRepositoryProtocol) async throws -> Double {
        guard let goal = goals.first(where: { $0.id == goalId }) else {
            return 0.0
        }

        let goalTasks = try await taskRepository.fetchByGoal(goalId)
        let completedTaskIds = Set(goalTasks.filter { $0.status == .completed }.map { $0.id })

        return goal.progress(completedTaskIds: completedTaskIds)
    }
}

// MARK: - Core Data Entity Extension

extension GoalEntity {
    func populate(from goal: Goal) {
        self.id = goal.id
        self.title = goal.title
        self.goalDescription = goal.description
        self.category = goal.category.rawValue
        self.targetDate = goal.targetDate
        self.createdAt = goal.createdAt
        self.isActive = goal.isActive
        self.notes = goal.notes

        // Encode task IDs as JSON array
        let encoder = JSONEncoder()
        if let taskIdsData = try? encoder.encode(goal.taskIds) {
            self.taskIdsData = taskIdsData
        }

        // Encode milestones as JSON
        if let milestonesData = try? encoder.encode(goal.milestones) {
            self.milestonesData = milestonesData
        }
    }

    func toGoal() -> Goal? {
        guard let id = self.id,
              let title = self.title,
              let categoryRaw = self.category,
              let category = GoalCategory(rawValue: categoryRaw),
              let createdAt = self.createdAt else {
            return nil
        }

        let decoder = JSONDecoder()
        let taskIds = (try? decoder.decode([UUID].self, from: taskIdsData ?? Data())) ?? []
        let milestones = (try? decoder.decode([Goal.Milestone].self, from: milestonesData ?? Data())) ?? []

        return Goal(
            id: id,
            title: title,
            description: goalDescription,
            category: category,
            targetDate: targetDate,
            taskIds: taskIds,
            createdAt: createdAt,
            isActive: isActive,
            milestones: milestones,
            notes: notes
        )
    }
}

// MARK: - GoalEntity Mock (for repositories without actual Core Data)

@objc(GoalEntity)
class GoalEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var goalDescription: String?
    @NSManaged var category: String?
    @NSManaged var targetDate: Date?
    @NSManaged var taskIdsData: Data?
    @NSManaged var createdAt: Date?
    @NSManaged var isActive: Bool
    @NSManaged var milestonesData: Data?
    @NSManaged var notes: String?
}
