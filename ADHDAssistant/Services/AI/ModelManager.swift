//
//  ModelManager.swift
//  ADHDAssistant
//
//  Manages AI model loading, unloading, and memory pressure handling
//

import Foundation
import Combine

// MARK: - Model Size

enum ModelSize: String, Codable, CaseIterable {
    case small = "small_350m"
    case medium = "medium_700m"
    case large = "large_1.2b"

    var lfmModelSize: LFMModelSize {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }

    var memoryRequirementMB: Int {
        lfmModelSize.estimatedMemoryMB
    }

    var displayName: String {
        switch self {
        case .small: return "Small (350M)"
        case .medium: return "Medium (700M)"
        case .large: return "Large (1.2B)"
        }
    }
}

// MARK: - Task Type

enum TaskType: String {
    case taskBreakdown
    case scheduling
    case behaviorAnalysis
    case healthReminder
    case motivation
    case quickResponse

    /// Recommended model size for this task type
    var recommendedModel: ModelSize {
        switch self {
        case .taskBreakdown:
            return .large // Complex reasoning needs larger model
        case .scheduling:
            return .small // Quick decisions
        case .behaviorAnalysis:
            return .medium // Pattern recognition
        case .healthReminder:
            return .small // Simple reminders
        case .motivation:
            return .medium // Varied, contextual responses
        case .quickResponse:
            return .small // Speed over complexity
        }
    }
}

// MARK: - Memory Pressure Level

enum MemoryPressureLevel {
    case normal
    case warning
    case critical

    var shouldUnloadModels: Bool {
        self == .critical
    }

    var maxModelSize: ModelSize? {
        switch self {
        case .normal:
            return nil // No restriction
        case .warning:
            return .medium // Limit to medium or smaller
        case .critical:
            return .small // Only small models
        }
    }
}

// MARK: - Model Manager

@MainActor
final class ModelManager: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var loadedModels: Set<ModelSize> = []
    @Published private(set) var currentMemoryPressure: MemoryPressureLevel = .normal
    @Published private(set) var isLoading = false

    // MARK: - Private Properties

    private var modelServices: [ModelSize: LFMService] = [:]
    private var lastUsed: [ModelSize: Date] = [:]
    private var loadingTasks: [ModelSize: Task<Void, Never>] = [:]

    // Configuration
    private let maxConcurrentModels = 2
    private let modelTimeoutMinutes = 10.0
    private var cleanupTimer: Timer?

    // MARK: - Initialization

    init() {
        setupMemoryPressureMonitoring()
        startCleanupTimer()
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    // MARK: - Model Access

    /// Get or load a model service for the given size
    func getModel(size: ModelSize) async throws -> LFMService {
        // Check if already loaded
        if let service = modelServices[size], service.isModelLoaded {
            lastUsed[size] = Date()
            return service
        }

        // Load the model
        try await loadModel(size)

        guard let service = modelServices[size] else {
            throw ModelManagerError.loadFailed(size)
        }

        return service
    }

    /// Get the appropriate model for a task type
    func getModelForTask(_ taskType: TaskType) async throws -> LFMService {
        var modelSize = taskType.recommendedModel

        // Adjust for memory pressure
        if let maxSize = currentMemoryPressure.maxModelSize,
           modelSize.memoryRequirementMB > maxSize.memoryRequirementMB {
            modelSize = maxSize
        }

        return try await getModel(size: modelSize)
    }

    // MARK: - Model Loading

    private func loadModel(_ size: ModelSize) async throws {
        // Prevent duplicate loading
        if loadingTasks[size] != nil {
            // Wait for existing load task
            await loadingTasks[size]?.value
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Check memory pressure
        if currentMemoryPressure == .critical {
            await unloadAllModels()
        } else if loadedModels.count >= maxConcurrentModels {
            await unloadLeastRecentlyUsed()
        }

        // Create loading task
        let task = Task {
            do {
                let service = modelServices[size] ?? LFMService()
                try await service.loadModel(size.lfmModelSize)

                modelServices[size] = service
                loadedModels.insert(size)
                lastUsed[size] = Date()

                print("✓ ModelManager: Loaded \(size.displayName)")
            } catch {
                print("✗ ModelManager: Failed to load \(size.displayName) - \(error)")
            }

            loadingTasks[size] = nil
        }

        loadingTasks[size] = task
        await task.value
    }

    /// Unload a specific model
    func unloadModel(_ size: ModelSize) async {
        guard let service = modelServices[size] else { return }

        await service.unloadModel()
        modelServices[size] = nil
        loadedModels.remove(size)
        lastUsed[size] = nil

        print("✓ ModelManager: Unloaded \(size.displayName)")
    }

    /// Unload all models
    func unloadAllModels() async {
        for size in loadedModels {
            await unloadModel(size)
        }
    }

    /// Unload the least recently used model
    private func unloadLeastRecentlyUsed() async {
        guard !loadedModels.isEmpty else { return }

        let leastRecent = loadedModels.min { size1, size2 in
            let date1 = lastUsed[size1] ?? .distantPast
            let date2 = lastUsed[size2] ?? .distantPast
            return date1 < date2
        }

        if let modelToUnload = leastRecent {
            await unloadModel(modelToUnload)
        }
    }

    // MARK: - Memory Management

    private func setupMemoryPressureMonitoring() {
        // TODO: Integrate with iOS memory pressure notifications
        // NotificationCenter.default.addObserver(
        //     self,
        //     selector: #selector(handleMemoryWarning),
        //     name: UIApplication.didReceiveMemoryWarningNotification,
        //     object: nil
        // )

        // For now, simulate memory pressure monitoring
        Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkMemoryPressure()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // Check every 30s
            }
        }
    }

    private func checkMemoryPressure() {
        // TODO: Implement actual memory pressure detection
        // For now, base it on number of loaded models
        let totalMemoryMB = loadedModels.reduce(0) { $0 + $1.memoryRequirementMB }

        if totalMemoryMB > 3000 {
            currentMemoryPressure = .critical
            Task {
                await handleMemoryPressure(.critical)
            }
        } else if totalMemoryMB > 2000 {
            currentMemoryPressure = .warning
        } else {
            currentMemoryPressure = .normal
        }
    }

    private func handleMemoryPressure(_ level: MemoryPressureLevel) async {
        switch level {
        case .normal:
            break

        case .warning:
            // Unload largest models first if we have multiple
            if loadedModels.count > 1, loadedModels.contains(.large) {
                await unloadModel(.large)
            }

        case .critical:
            // Unload all but the smallest model
            let modelsToUnload = loadedModels.filter { $0 != .small }
            for model in modelsToUnload {
                await unloadModel(model)
            }
        }
    }

    // MARK: - Cleanup

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(
            withTimeInterval: 60, // Check every minute
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.cleanupUnusedModels()
            }
        }
    }

    private func cleanupUnusedModels() async {
        let now = Date()
        let timeout = modelTimeoutMinutes * 60

        for (size, lastUseDate) in lastUsed {
            if now.timeIntervalSince(lastUseDate) > timeout {
                print("⏱ ModelManager: Cleaning up unused \(size.displayName)")
                await unloadModel(size)
            }
        }
    }

    // MARK: - Status

    func getStatus() -> ModelManagerStatus {
        ModelManagerStatus(
            loadedModels: Array(loadedModels),
            totalMemoryMB: loadedModels.reduce(0) { $0 + $1.memoryRequirementMB },
            memoryPressure: currentMemoryPressure,
            isLoading: isLoading
        )
    }
}

// MARK: - Model Manager Status

struct ModelManagerStatus {
    let loadedModels: [ModelSize]
    let totalMemoryMB: Int
    let memoryPressure: MemoryPressureLevel
    let isLoading: Bool

    var canLoadMore: Bool {
        memoryPressure != .critical && loadedModels.count < 2
    }

    var statusDescription: String {
        let modelNames = loadedModels.map { $0.displayName }.joined(separator: ", ")
        return "Loaded: \(modelNames.isEmpty ? "None" : modelNames) | Memory: \(totalMemoryMB)MB"
    }
}

// MARK: - Errors

enum ModelManagerError: LocalizedError {
    case loadFailed(ModelSize)
    case memoryPressure
    case noModelAvailable

    var errorDescription: String? {
        switch self {
        case .loadFailed(let size):
            return "Failed to load \(size.displayName) model"
        case .memoryPressure:
            return "Cannot load model due to memory pressure"
        case .noModelAvailable:
            return "No suitable model is available"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ModelManager {
    static var preview: ModelManager {
        let manager = ModelManager()
        Task { @MainActor in
            try? await manager.loadModel(.small)
        }
        return manager
    }
}
#endif
