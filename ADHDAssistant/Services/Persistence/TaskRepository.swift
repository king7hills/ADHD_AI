//
//  TaskRepository.swift
//  ADHDAssistant
//
//  Repository for Task entity persistence and retrieval
//

import Foundation
import CoreData
import Combine

// MARK: - Protocol

protocol TaskRepositoryProtocol {
    func create(_ task: Task) async throws -> Task
    func update(_ task: Task) async throws -> Task
    func delete(_ task: Task) async throws
    func fetch(by id: UUID) async throws -> Task?
    func fetchAll() async throws -> [Task]
    func fetchByStatus(_ status: TaskStatus) async throws -> [Task]
    func fetchForDate(_ date: Date) async throws -> [Task]
    func fetchOverdue() async throws -> [Task]
    func search(query: String) async throws -> [Task]
    func fetchByGoal(_ goalId: UUID) async throws -> [Task]

    var tasksPublisher: AnyPublisher<[Task], Never> { get }
}

// MARK: - Task Repository Implementation

class TaskRepository: TaskRepositoryProtocol {
    // MARK: - Properties

    private let coreDataStack: CoreDataStack
    private let tasksSubject = CurrentValueSubject<[Task], Never>([])

    var tasksPublisher: AnyPublisher<[Task], Never> {
        tasksSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack

        // Subscribe to Core Data changes
        coreDataStack.didSavePublisher
            .sink { [weak self] _ in
                Task {
                    try? await self?.refreshTasks()
                }
            }
            .store(in: &cancellables)

        // Initial load
        Task {
            try? await refreshTasks()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - CRUD Operations

    func create(_ task: Task) async throws -> Task {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let entity = TaskEntity(context: context)
            entity.populate(from: task)

            try context.save()

            // Refresh tasks
            Task {
                try? await self.refreshTasks()
            }

            return task
        }
    }

    func update(_ task: Task) async throws -> Task {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            guard let entity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.entityNotFound
            }

            entity.populate(from: task)

            try context.save()

            // Refresh tasks
            Task {
                try? await self.refreshTasks()
            }

            return task
        }
    }

    func delete(_ task: Task) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)

            guard let entity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.entityNotFound
            }

            context.delete(entity)
            try context.save()

            // Refresh tasks
            Task {
                try? await self.refreshTasks()
            }
        }
    }

    // MARK: - Fetch Operations

    func fetch(by id: UUID) async throws -> Task? {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }

            return entity.toTask()
        }
    }

    func fetchAll() async throws -> [Task] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.scheduledTime, ascending: true),
                NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toTask() }
        }
    }

    func fetchByStatus(_ status: TaskStatus) async throws -> [Task] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "status == %@", status.rawValue)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.scheduledTime, ascending: true)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toTask() }
        }
    }

    func fetchForDate(_ date: Date) async throws -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "scheduledTime >= %@ AND scheduledTime < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.scheduledTime, ascending: true)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toTask() }
        }
    }

    func fetchOverdue() async throws -> [Task] {
        let now = Date()
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()

            // Tasks that are scheduled before now and not completed
            let statusPredicate = NSPredicate(
                format: "NOT (status IN %@)",
                [TaskStatus.completed.rawValue, TaskStatus.partiallyCompleted.rawValue, TaskStatus.skipped.rawValue]
            )
            let timePredicate = NSPredicate(format: "scheduledTime < %@", now as NSDate)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, timePredicate])

            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.scheduledTime, ascending: true)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toTask() }
        }
    }

    func search(query: String) async throws -> [Task] {
        guard !query.isEmpty else {
            return try await fetchAll()
        }

        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()

            // Search in title, description, and tags
            let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
            let descriptionPredicate = NSPredicate(format: "taskDescription CONTAINS[cd] %@", query)
            let tagsPredicate = NSPredicate(format: "tagsString CONTAINS[cd] %@", query)

            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                titlePredicate,
                descriptionPredicate,
                tagsPredicate
            ])

            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toTask() }
        }
    }

    func fetchByGoal(_ goalId: UUID) async throws -> [Task] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = TaskEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "parentGoalId == %@", goalId as CVarArg)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.scheduledTime, ascending: true),
                NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toTask() }
        }
    }

    // MARK: - Helper Methods

    private func refreshTasks() async throws {
        let tasks = try await fetchAll()
        tasksSubject.send(tasks)
    }
}

// MARK: - Mock Repository for Testing

class MockTaskRepository: TaskRepositoryProtocol {
    private var tasks: [Task] = []
    private let tasksSubject = CurrentValueSubject<[Task], Never>([])

    var tasksPublisher: AnyPublisher<[Task], Never> {
        tasksSubject.eraseToAnyPublisher()
    }

    init(initialTasks: [Task] = []) {
        self.tasks = initialTasks
        tasksSubject.send(tasks)
    }

    func create(_ task: Task) async throws -> Task {
        tasks.append(task)
        tasksSubject.send(tasks)
        return task
    }

    func update(_ task: Task) async throws -> Task {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            tasksSubject.send(tasks)
        }
        return task
    }

    func delete(_ task: Task) async throws {
        tasks.removeAll { $0.id == task.id }
        tasksSubject.send(tasks)
    }

    func fetch(by id: UUID) async throws -> Task? {
        tasks.first { $0.id == id }
    }

    func fetchAll() async throws -> [Task] {
        tasks.sorted { ($0.scheduledTime ?? Date.distantFuture) < ($1.scheduledTime ?? Date.distantFuture) }
    }

    func fetchByStatus(_ status: TaskStatus) async throws -> [Task] {
        tasks.filter { $0.status == status }
    }

    func fetchForDate(_ date: Date) async throws -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            guard let scheduledTime = task.scheduledTime else { return false }
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }
    }

    func fetchOverdue() async throws -> [Task] {
        tasks.filter { $0.isOverdue }
    }

    func search(query: String) async throws -> [Task] {
        guard !query.isEmpty else { return try await fetchAll() }

        return tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query) ||
            (task.description?.localizedCaseInsensitiveContains(query) ?? false) ||
            task.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
        }
    }

    func fetchByGoal(_ goalId: UUID) async throws -> [Task] {
        tasks.filter { $0.parentGoalId == goalId }
    }
}

// MARK: - Core Data Entity Extension

extension TaskEntity {
    func populate(from task: Task) {
        self.id = task.id
        self.title = task.title
        self.taskDescription = task.description
        self.parentGoalId = task.parentGoalId
        self.estimatedDuration = task.estimatedDuration
        self.actualDuration = task.actualDuration ?? 0
        self.scheduledTime = task.scheduledTime
        self.completedAt = task.completedAt
        self.status = task.status.rawValue
        self.priority = task.priority.rawValue
        self.tagsString = task.tags.joined(separator: ",")
        self.aiGenerated = task.aiGenerated
        self.pointsValue = Int32(task.pointsValue)
        self.createdAt = task.createdAt
        self.startTrigger = task.startTrigger

        // Encode complex types as JSON
        let encoder = JSONEncoder()
        if let subtasksData = try? encoder.encode(task.subtasks) {
            self.subtasksData = subtasksData
        }
        if let recurrenceData = try? encoder.encode(task.recurrence) {
            self.recurrenceData = recurrenceData
        }
    }

    func toTask() -> Task? {
        guard let id = self.id,
              let title = self.title,
              let statusRaw = self.status,
              let status = TaskStatus(rawValue: statusRaw),
              let priorityRaw = self.priority,
              let priority = Priority(rawValue: priorityRaw),
              let createdAt = self.createdAt else {
            return nil
        }

        let decoder = JSONDecoder()
        let subtasks = (try? decoder.decode([Subtask].self, from: subtasksData ?? Data())) ?? []
        let recurrence = try? decoder.decode(RecurrenceRule.self, from: recurrenceData ?? Data())
        let tags = tagsString?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []

        return Task(
            id: id,
            title: title,
            description: taskDescription,
            parentGoalId: parentGoalId,
            estimatedDuration: estimatedDuration,
            actualDuration: actualDuration > 0 ? actualDuration : nil,
            scheduledTime: scheduledTime,
            completedAt: completedAt,
            status: status,
            priority: priority,
            subtasks: subtasks,
            recurrence: recurrence,
            tags: tags,
            aiGenerated: aiGenerated,
            pointsValue: Int(pointsValue),
            createdAt: createdAt,
            startTrigger: startTrigger
        )
    }
}

// MARK: - TaskEntity Mock (for repositories without actual Core Data)

@objc(TaskEntity)
class TaskEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var taskDescription: String?
    @NSManaged var parentGoalId: UUID?
    @NSManaged var estimatedDuration: TimeInterval
    @NSManaged var actualDuration: TimeInterval
    @NSManaged var scheduledTime: Date?
    @NSManaged var completedAt: Date?
    @NSManaged var status: String?
    @NSManaged var priority: String?
    @NSManaged var subtasksData: Data?
    @NSManaged var recurrenceData: Data?
    @NSManaged var tagsString: String?
    @NSManaged var aiGenerated: Bool
    @NSManaged var pointsValue: Int32
    @NSManaged var createdAt: Date?
    @NSManaged var startTrigger: String?
}
