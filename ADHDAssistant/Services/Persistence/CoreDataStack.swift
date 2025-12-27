//
//  CoreDataStack.swift
//  ADHDAssistant
//
//  Core Data stack for persistent storage
//

import Foundation
import CoreData
import Combine

/// Core Data stack managing persistent storage
class CoreDataStack {
    // MARK: - Singleton

    static let shared = CoreDataStack()

    // MARK: - Properties

    private let modelName: String
    private let inMemory: Bool

    /// Main persistent container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)

        if inMemory {
            // Use in-memory store for testing/previews
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    /// Main view context for UI operations (main thread)
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// Publisher for Core Data changes
    private let didSaveSubject = PassthroughSubject<Notification, Never>()
    var didSavePublisher: AnyPublisher<Notification, Never> {
        didSaveSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    private init(modelName: String = "ADHDAssistant", inMemory: Bool = false) {
        self.modelName = modelName
        self.inMemory = inMemory

        // Observe context saves
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    /// Create instance for testing with in-memory store
    static func preview() -> CoreDataStack {
        CoreDataStack(inMemory: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Context Management

    /// Create a new background context for async operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Perform operation on background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Save Operations

    /// Save view context with error handling
    func saveContext() throws {
        let context = viewContext

        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            // Rollback changes on error
            context.rollback()
            throw CoreDataError.saveFailed(error)
        }
    }

    /// Save context asynchronously
    func saveContextAsync() async throws {
        let context = viewContext

        guard context.hasChanges else { return }

        return try await context.perform {
            do {
                try context.save()
            } catch {
                context.rollback()
                throw CoreDataError.saveFailed(error)
            }
        }
    }

    /// Save background context
    func saveBackgroundContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw CoreDataError.saveFailed(error)
        }
    }

    /// Save background context asynchronously
    func saveBackgroundContextAsync(_ context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }

        return try await context.perform {
            do {
                try context.save()
            } catch {
                context.rollback()
                throw CoreDataError.saveFailed(error)
            }
        }
    }

    // MARK: - Batch Operations

    /// Execute batch delete request
    func batchDelete<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil
    ) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        fetchRequest.predicate = predicate

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult

            // Merge changes into view context
            if let objectIDArray = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [viewContext]
                )
            }
        } catch {
            throw CoreDataError.batchOperationFailed(error)
        }
    }

    /// Execute batch update request
    func batchUpdate<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil,
        propertiesToUpdate: [AnyHashable: Any]
    ) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        fetchRequest.predicate = predicate

        let updateRequest = NSBatchUpdateRequest(entity: T.entity())
        updateRequest.predicate = predicate
        updateRequest.propertiesToUpdate = propertiesToUpdate
        updateRequest.resultType = .updatedObjectIDsResultType

        do {
            let result = try viewContext.execute(updateRequest) as? NSBatchUpdateResult

            // Merge changes into view context
            if let objectIDArray = result?.result as? [NSManagedObjectID] {
                let changes = [NSUpdatedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [viewContext]
                )
            }
        } catch {
            throw CoreDataError.batchOperationFailed(error)
        }
    }

    // MARK: - Reset

    /// Delete all data (for testing or user data reset)
    func deleteAllData() throws {
        let entities = persistentContainer.managedObjectModel.entities

        for entity in entities {
            guard let entityName = entity.name else { continue }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try persistentContainer.persistentStoreCoordinator.execute(
                    deleteRequest,
                    with: viewContext
                )
            } catch {
                throw CoreDataError.resetFailed(error)
            }
        }

        try saveContext()
    }

    // MARK: - Notification Handling

    @objc private func contextDidSave(_ notification: Notification) {
        didSaveSubject.send(notification)
    }
}

// MARK: - Core Data Errors

enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case batchOperationFailed(Error)
    case resetFailed(Error)
    case entityNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .batchOperationFailed(let error):
            return "Failed to execute batch operation: \(error.localizedDescription)"
        case .resetFailed(let error):
            return "Failed to reset data: \(error.localizedDescription)"
        case .entityNotFound:
            return "Core Data entity not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension CoreDataStack {
    /// Create a preview instance with sample data
    static func previewWithSampleData() -> CoreDataStack {
        let stack = CoreDataStack.preview()

        // Add sample data here if needed
        // This can be populated with test entities

        return stack
    }
}
#endif
