//
//  TaskDetailViewModel.swift
//  ADHDAssistant
//
//  ViewModel for managing task detail state and editing operations
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TaskDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var task: Task
    @Published var isEditMode: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var error: Error?

    // Editable fields
    @Published var editedTitle: String
    @Published var editedDescription: String
    @Published var editedEstimatedDuration: TimeInterval
    @Published var editedScheduledTime: Date?
    @Published var editedPriority: Priority
    @Published var editedSubtasks: [Subtask]
    @Published var editedRecurrence: RecurrenceRule?
    @Published var editedTags: [String]
    @Published var editedStartTrigger: String

    // UI State
    @Published var showRecurrenceSheet: Bool = false
    @Published var showGoalPicker: Bool = false
    @Published var newSubtaskTitle: String = ""

    // MARK: - Properties

    private let repository: TaskRepositoryProtocol
    private let gamificationCoordinator: GamificationCoordinator
    private var cancellables = Set<AnyCancellable>()

    var onTaskUpdated: ((Task) -> Void)?
    var onTaskDeleted: (() -> Void)?

    // MARK: - Initialization

    init(
        task: Task,
        repository: TaskRepositoryProtocol = TaskRepository(),
        gamificationCoordinator: GamificationCoordinator = GamificationCoordinator()
    ) {
        self.task = task
        self.repository = repository
        self.gamificationCoordinator = gamificationCoordinator

        // Initialize editable fields
        self.editedTitle = task.title
        self.editedDescription = task.description ?? ""
        self.editedEstimatedDuration = task.estimatedDuration
        self.editedScheduledTime = task.scheduledTime
        self.editedPriority = task.priority
        self.editedSubtasks = task.subtasks
        self.editedRecurrence = task.recurrence
        self.editedTags = task.tags
        self.editedStartTrigger = task.startTrigger ?? ""
    }

    // MARK: - Edit Mode Management

    func enterEditMode() {
        isEditMode = true
        resetEditedFields()
    }

    func cancelEdit() {
        isEditMode = false
        resetEditedFields()
    }

    private func resetEditedFields() {
        editedTitle = task.title
        editedDescription = task.description ?? ""
        editedEstimatedDuration = task.estimatedDuration
        editedScheduledTime = task.scheduledTime
        editedPriority = task.priority
        editedSubtasks = task.subtasks
        editedRecurrence = task.recurrence
        editedTags = task.tags
        editedStartTrigger = task.startTrigger ?? ""
    }

    // MARK: - Validation

    var isValid: Bool {
        !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        editedEstimatedDuration > 0
    }

    var validationError: String? {
        if editedTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Title cannot be empty"
        }
        if editedEstimatedDuration <= 0 {
            return "Duration must be greater than 0"
        }
        return nil
    }

    // MARK: - Save Operations

    func saveChanges() async -> Bool {
        guard isValid else {
            error = NSError(domain: "TaskDetailViewModel", code: 1, userInfo: [
                NSLocalizedDescriptionKey: validationError ?? "Invalid task data"
            ])
            return false
        }

        isSaving = true
        error = nil

        var updatedTask = task
        updatedTask.title = editedTitle.trimmingCharacters(in: .whitespaces)
        updatedTask.description = editedDescription.isEmpty ? nil : editedDescription.trimmingCharacters(in: .whitespaces)
        updatedTask.estimatedDuration = editedEstimatedDuration
        updatedTask.scheduledTime = editedScheduledTime
        updatedTask.priority = editedPriority
        updatedTask.subtasks = editedSubtasks
        updatedTask.recurrence = editedRecurrence
        updatedTask.tags = editedTags
        updatedTask.startTrigger = editedStartTrigger.isEmpty ? nil : editedStartTrigger.trimmingCharacters(in: .whitespaces)

        do {
            let savedTask = try await repository.update(updatedTask)
            self.task = savedTask
            self.isEditMode = false
            onTaskUpdated?(savedTask)
            HapticManager.shared.success()
            isSaving = false
            return true
        } catch {
            self.error = error
            HapticManager.shared.error()
            isSaving = false
            return false
        }
    }

    func deleteTask() async {
        isSaving = true
        error = nil

        do {
            try await repository.delete(task)
            onTaskDeleted?()
            HapticManager.shared.success()
            isSaving = false
        } catch {
            self.error = error
            HapticManager.shared.error()
            isSaving = false
        }
    }

    // MARK: - Task Actions

    func completeTask() {
        var updatedTask = task
        let completedOnTime = !task.isOverdue
        let completedEarly = task.scheduledTime.map { $0 > Date() } ?? false

        updatedTask.complete()

        Task {
            do {
                let savedTask = try await repository.update(updatedTask)
                self.task = savedTask

                // Process gamification
                let result = gamificationCoordinator.processEvent(
                    .taskCompleted(savedTask, completedOnTime: completedOnTime, completedEarly: completedEarly)
                )

                if result.hasRewards {
                    HapticManager.shared.success()
                } else {
                    HapticManager.shared.impact(.medium)
                }

                onTaskUpdated?(savedTask)

                // Create next occurrence if recurring
                if let nextTask = savedTask.createNextOccurrence() {
                    _ = try await repository.create(nextTask)
                }
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func uncompleteTask() {
        var updatedTask = task
        updatedTask.status = .created
        updatedTask.completedAt = nil

        Task {
            do {
                let savedTask = try await repository.update(updatedTask)
                self.task = savedTask
                onTaskUpdated?(savedTask)
                HapticManager.shared.impact(.medium)
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    func startTask() {
        var updatedTask = task
        updatedTask.start()

        Task {
            do {
                let savedTask = try await repository.update(updatedTask)
                self.task = savedTask
                onTaskUpdated?(savedTask)
                HapticManager.shared.impact(.medium)
            } catch {
                self.error = error
                HapticManager.shared.error()
            }
        }
    }

    // MARK: - Subtask Management

    func addSubtask(_ title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let newSubtask = Subtask(title: trimmedTitle)
        editedSubtasks.append(newSubtask)
        newSubtaskTitle = ""

        if !isEditMode {
            saveSubtasksImmediately()
        }
    }

    func deleteSubtask(at offsets: IndexSet) {
        editedSubtasks.remove(atOffsets: offsets)

        if !isEditMode {
            saveSubtasksImmediately()
        }
    }

    func moveSubtask(from source: IndexSet, to destination: Int) {
        editedSubtasks.move(fromOffsets: source, toOffset: destination)

        if !isEditMode {
            saveSubtasksImmediately()
        }
    }

    func toggleSubtask(_ subtask: Subtask) {
        if let index = editedSubtasks.firstIndex(where: { $0.id == subtask.id }) {
            editedSubtasks[index].isCompleted.toggle()
            if editedSubtasks[index].isCompleted {
                editedSubtasks[index].completedAt = Date()

                // Award points for subtask completion
                gamificationCoordinator.processEvent(.subtaskCompleted(task))
            } else {
                editedSubtasks[index].completedAt = nil
            }

            saveSubtasksImmediately()
        }
    }

    private func saveSubtasksImmediately() {
        var updatedTask = task
        updatedTask.subtasks = editedSubtasks

        Task {
            do {
                let savedTask = try await repository.update(updatedTask)
                self.task = savedTask
                onTaskUpdated?(savedTask)
                HapticManager.shared.impact(.light)
            } catch {
                self.error = error
            }
        }
    }

    // MARK: - Tag Management

    func addTag(_ tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespaces)
        guard !trimmedTag.isEmpty, !editedTags.contains(trimmedTag) else { return }

        editedTags.append(trimmedTag)
    }

    func removeTag(_ tag: String) {
        editedTags.removeAll { $0 == tag }
    }

    // MARK: - Duration Presets

    let durationPresets: [(label: String, duration: TimeInterval)] = [
        ("5 min", 300),
        ("10 min", 600),
        ("15 min", 900),
        ("30 min", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200)
    ]

    func setDurationPreset(_ duration: TimeInterval) {
        editedEstimatedDuration = duration
    }

    // MARK: - Computed Properties

    var isCompleted: Bool {
        task.isCompleted
    }

    var completionPercentage: Double {
        task.completionPercentage
    }

    var formattedDuration: String {
        let hours = Int(editedEstimatedDuration) / 3600
        let minutes = Int(editedEstimatedDuration) / 60 % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var hasScheduledTime: Bool {
        editedScheduledTime != nil
    }

    var hasRecurrence: Bool {
        editedRecurrence != nil
    }

    var subtaskProgress: String {
        let completed = editedSubtasks.filter { $0.isCompleted }.count
        let total = editedSubtasks.count
        return "\(completed)/\(total)"
    }
}
