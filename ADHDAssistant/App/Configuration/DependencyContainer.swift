//
//  DependencyContainer.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import Foundation
import SwiftUI

/// Dependency injection container for app services
@MainActor
class DependencyContainer: ObservableObject {

    // MARK: - Shared Instance

    static let shared = DependencyContainer()
    static let preview = DependencyContainer(isPreview: true)

    // MARK: - Properties

    private let isPreview: Bool

    // MARK: - Core Data

    lazy var coreDataStack: CoreDataStack = {
        CoreDataStack(modelName: AppConfiguration.Storage.coreDataModelName, inMemory: isPreview)
    }()

    // MARK: - Repositories

    lazy var taskRepository: TaskRepository = {
        TaskRepository(context: coreDataStack.viewContext)
    }()

    lazy var goalRepository: GoalRepository = {
        GoalRepository(context: coreDataStack.viewContext)
    }()

    lazy var healthRepository: HealthRepository = {
        HealthRepository(context: coreDataStack.viewContext)
    }()

    lazy var memoryStore: MemoryStore = {
        MemoryStore(context: coreDataStack.viewContext)
    }()

    // MARK: - Gamification Services

    lazy var pointsService: PointsService = {
        PointsService()
    }()

    lazy var streakService: StreakService = {
        StreakService()
    }()

    lazy var achievementService: AchievementService = {
        AchievementService(
            pointsService: pointsService,
            streakService: streakService
        )
    }()

    lazy var celebrationService: CelebrationService = {
        CelebrationService()
    }()

    lazy var gamificationCoordinator: GamificationCoordinator = {
        GamificationCoordinator(
            pointsService: pointsService,
            streakService: streakService,
            achievementService: achievementService,
            celebrationService: celebrationService
        )
    }()

    // MARK: - AI Services

    lazy var modelManager: ModelManager = {
        ModelManager()
    }()

    lazy var agentCoordinator: AgentCoordinator = {
        AgentCoordinator(
            modelManager: modelManager,
            memoryStore: memoryStore,
            taskRepository: taskRepository,
            goalRepository: goalRepository,
            healthRepository: healthRepository
        )
    }()

    // MARK: - Utilities

    lazy var hapticManager: HapticManager = {
        HapticManager()
    }()

    // MARK: - Initialization

    private init(isPreview: Bool = false) {
        self.isPreview = isPreview

        if isPreview {
            setupMockData()
        }
    }

    // MARK: - Mock Data Setup

    private func setupMockData() {
        guard isPreview else { return }

        // Create sample tasks
        let sampleTask = Task(context: coreDataStack.viewContext)
        sampleTask.id = UUID()
        sampleTask.title = "Complete expense report"
        sampleTask.taskDescription = "Submit Q4 expense report to accounting"
        sampleTask.priority = "high"
        sampleTask.status = "pending"
        sampleTask.deadline = Date().addingTimeInterval(3600)
        sampleTask.estimatedDuration = 1800 // 30 minutes
        sampleTask.createdAt = Date()
        sampleTask.updatedAt = Date()

        let completedTask = Task(context: coreDataStack.viewContext)
        completedTask.id = UUID()
        completedTask.title = "Morning medication"
        completedTask.taskDescription = "Take prescribed medication with breakfast"
        completedTask.priority = "high"
        completedTask.status = "completed"
        completedTask.completedAt = Date()
        completedTask.createdAt = Date().addingTimeInterval(-7200)
        completedTask.updatedAt = Date()

        // Create sample goal
        let sampleGoal = Goal(context: coreDataStack.viewContext)
        sampleGoal.id = UUID()
        sampleGoal.title = "Establish morning routine"
        sampleGoal.goalDescription = "Complete morning tasks consistently for 21 days"
        sampleGoal.category = "health"
        sampleGoal.targetValue = 21
        sampleGoal.currentValue = 7
        sampleGoal.startDate = Date().addingTimeInterval(-604800) // 7 days ago
        sampleGoal.targetDate = Date().addingTimeInterval(1209600) // 14 days from now
        sampleGoal.createdAt = Date().addingTimeInterval(-604800)
        sampleGoal.updatedAt = Date()

        // Create sample health metric
        let sampleMetric = HealthMetric(context: coreDataStack.viewContext)
        sampleMetric.id = UUID()
        sampleMetric.type = "blood_glucose"
        sampleMetric.value = 120
        sampleMetric.unit = "mg/dL"
        sampleMetric.timestamp = Date()
        sampleMetric.notes = "After breakfast"

        // Create sample achievement
        let sampleAchievement = Achievement(context: coreDataStack.viewContext)
        sampleAchievement.id = UUID()
        sampleAchievement.title = "First Steps"
        sampleAchievement.achievementDescription = "Completed your first task"
        sampleAchievement.category = "tasks"
        sampleAchievement.iconName = "star.fill"
        sampleAchievement.pointsRewarded = 50
        sampleAchievement.isUnlocked = true
        sampleAchievement.unlockedAt = Date()

        try? coreDataStack.viewContext.save()
    }

    // MARK: - Cleanup

    func reset() {
        // Reset user defaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Clear Core Data
        let entities = coreDataStack.persistentContainer.managedObjectModel.entities
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try? coreDataStack.viewContext.execute(deleteRequest)
            }
        }

        try? coreDataStack.viewContext.save()
    }
}

// MARK: - Environment Key

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
