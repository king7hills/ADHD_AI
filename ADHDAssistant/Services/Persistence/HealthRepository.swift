//
//  HealthRepository.swift
//  ADHDAssistant
//
//  Repository for HealthMetric entity persistence and retrieval
//

import Foundation
import CoreData
import Combine

// MARK: - Protocol

protocol HealthRepositoryProtocol {
    func create(_ metric: HealthMetric) async throws -> HealthMetric
    func update(_ metric: HealthMetric) async throws -> HealthMetric
    func delete(_ metric: HealthMetric) async throws
    func fetch(by id: UUID) async throws -> HealthMetric?
    func fetchAll() async throws -> [HealthMetric]
    func fetchByType(_ type: HealthMetricType) async throws -> [HealthMetric]
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [HealthMetric]
    func fetchToday() async throws -> [HealthMetric]
    func calculateAverage(for type: HealthMetricType, days: Int) async throws -> Double?
    func fetchTrends(for type: HealthMetricType, days: Int) async throws -> [HealthTrend]

    var metricsPublisher: AnyPublisher<[HealthMetric], Never> { get }
}

// MARK: - Health Trend Model

struct HealthTrend {
    let date: Date
    let averageValue: Double
    let minValue: Double
    let maxValue: Double
    let count: Int
}

// MARK: - Health Repository Implementation

class HealthRepository: HealthRepositoryProtocol {
    // MARK: - Properties

    private let coreDataStack: CoreDataStack
    private let metricsSubject = CurrentValueSubject<[HealthMetric], Never>([])

    var metricsPublisher: AnyPublisher<[HealthMetric], Never> {
        metricsSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack

        // Subscribe to Core Data changes
        coreDataStack.didSavePublisher
            .sink { [weak self] _ in
                Task {
                    try? await self?.refreshMetrics()
                }
            }
            .store(in: &cancellables)

        // Initial load
        Task {
            try? await refreshMetrics()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - CRUD Operations

    func create(_ metric: HealthMetric) async throws -> HealthMetric {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let entity = HealthMetricEntity(context: context)
            entity.populate(from: metric)

            try context.save()

            // Refresh metrics
            Task {
                try? await self.refreshMetrics()
            }

            return metric
        }
    }

    func update(_ metric: HealthMetric) async throws -> HealthMetric {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {
            let fetchRequest = HealthMetricEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", metric.id as CVarArg)

            guard let entity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.entityNotFound
            }

            entity.populate(from: metric)

            try context.save()

            // Refresh metrics
            Task {
                try? await self.refreshMetrics()
            }

            return metric
        }
    }

    func delete(_ metric: HealthMetric) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {
            let fetchRequest = HealthMetricEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", metric.id as CVarArg)

            guard let entity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.entityNotFound
            }

            context.delete(entity)
            try context.save()

            // Refresh metrics
            Task {
                try? await self.refreshMetrics()
            }
        }
    }

    // MARK: - Fetch Operations

    func fetch(by id: UUID) async throws -> HealthMetric? {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = HealthMetricEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let entity = try context.fetch(fetchRequest).first else {
                return nil
            }

            return entity.toHealthMetric()
        }
    }

    func fetchAll() async throws -> [HealthMetric] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = HealthMetricEntity.fetchRequest()
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \HealthMetricEntity.recordedAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toHealthMetric() }
        }
    }

    func fetchByType(_ type: HealthMetricType) async throws -> [HealthMetric] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = HealthMetricEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "type == %@", type.rawValue)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \HealthMetricEntity.recordedAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toHealthMetric() }
        }
    }

    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [HealthMetric] {
        let context = coreDataStack.viewContext

        return try await context.perform {
            let fetchRequest = HealthMetricEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "recordedAt >= %@ AND recordedAt <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \HealthMetricEntity.recordedAt, ascending: false)
            ]

            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { $0.toHealthMetric() }
        }
    }

    func fetchToday() async throws -> [HealthMetric] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        return try await fetchByDateRange(from: startOfDay, to: endOfDay)
    }

    // MARK: - Analytics

    func calculateAverage(for type: HealthMetricType, days: Int) async throws -> Double? {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return nil
        }

        let metrics = try await fetchByDateRange(from: startDate, to: Date())
        let filteredMetrics = metrics.filter { $0.type == type }

        guard !filteredMetrics.isEmpty else { return nil }

        let sum = filteredMetrics.reduce(0.0) { $0 + $1.value }
        return sum / Double(filteredMetrics.count)
    }

    func fetchTrends(for type: HealthMetricType, days: Int) async throws -> [HealthTrend] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        let metrics = try await fetchByDateRange(from: startDate, to: Date())
        let filteredMetrics = metrics.filter { $0.type == type }

        // Group by day
        var dayGroups: [Date: [HealthMetric]] = [:]

        for metric in filteredMetrics {
            let dayStart = calendar.startOfDay(for: metric.recordedAt)
            dayGroups[dayStart, default: []].append(metric)
        }

        // Calculate trends
        return dayGroups.map { date, metrics in
            let values = metrics.map { $0.value }
            let sum = values.reduce(0.0, +)
            let avg = sum / Double(values.count)
            let min = values.min() ?? 0
            let max = values.max() ?? 0

            return HealthTrend(
                date: date,
                averageValue: avg,
                minValue: min,
                maxValue: max,
                count: metrics.count
            )
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Helper Methods

    private func refreshMetrics() async throws {
        let metrics = try await fetchToday()
        metricsSubject.send(metrics)
    }
}

// MARK: - Mock Repository for Testing

class MockHealthRepository: HealthRepositoryProtocol {
    private var metrics: [HealthMetric] = []
    private let metricsSubject = CurrentValueSubject<[HealthMetric], Never>([])

    var metricsPublisher: AnyPublisher<[HealthMetric], Never> {
        metricsSubject.eraseToAnyPublisher()
    }

    init(initialMetrics: [HealthMetric] = []) {
        self.metrics = initialMetrics
        metricsSubject.send(metrics)
    }

    func create(_ metric: HealthMetric) async throws -> HealthMetric {
        metrics.append(metric)
        metricsSubject.send(metrics)
        return metric
    }

    func update(_ metric: HealthMetric) async throws -> HealthMetric {
        if let index = metrics.firstIndex(where: { $0.id == metric.id }) {
            metrics[index] = metric
            metricsSubject.send(metrics)
        }
        return metric
    }

    func delete(_ metric: HealthMetric) async throws {
        metrics.removeAll { $0.id == metric.id }
        metricsSubject.send(metrics)
    }

    func fetch(by id: UUID) async throws -> HealthMetric? {
        metrics.first { $0.id == id }
    }

    func fetchAll() async throws -> [HealthMetric] {
        metrics.sorted { $0.recordedAt > $1.recordedAt }
    }

    func fetchByType(_ type: HealthMetricType) async throws -> [HealthMetric] {
        metrics.filter { $0.type == type }.sorted { $0.recordedAt > $1.recordedAt }
    }

    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [HealthMetric] {
        metrics.filter { $0.recordedAt >= startDate && $0.recordedAt <= endDate }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    func fetchToday() async throws -> [HealthMetric] {
        let calendar = Calendar.current
        return metrics.filter { calendar.isDateInToday($0.recordedAt) }
    }

    func calculateAverage(for type: HealthMetricType, days: Int) async throws -> Double? {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return nil
        }

        let relevantMetrics = metrics.filter {
            $0.type == type && $0.recordedAt >= startDate
        }

        guard !relevantMetrics.isEmpty else { return nil }

        let sum = relevantMetrics.reduce(0.0) { $0 + $1.value }
        return sum / Double(relevantMetrics.count)
    }

    func fetchTrends(for type: HealthMetricType, days: Int) async throws -> [HealthTrend] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }

        let filteredMetrics = metrics.filter {
            $0.type == type && $0.recordedAt >= startDate
        }

        var dayGroups: [Date: [HealthMetric]] = [:]

        for metric in filteredMetrics {
            let dayStart = calendar.startOfDay(for: metric.recordedAt)
            dayGroups[dayStart, default: []].append(metric)
        }

        return dayGroups.map { date, metrics in
            let values = metrics.map { $0.value }
            let sum = values.reduce(0.0, +)
            let avg = sum / Double(values.count)
            let min = values.min() ?? 0
            let max = values.max() ?? 0

            return HealthTrend(
                date: date,
                averageValue: avg,
                minValue: min,
                maxValue: max,
                count: metrics.count
            )
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Core Data Entity Extension

extension HealthMetricEntity {
    func populate(from metric: HealthMetric) {
        self.id = metric.id
        self.type = metric.type.rawValue
        self.value = metric.value
        self.unit = metric.unit
        self.recordedAt = metric.recordedAt
        self.notes = metric.notes

        // Encode complex types as JSON
        let encoder = JSONEncoder()

        if let bloodSugar = metric.bloodSugarReading,
           let data = try? encoder.encode(bloodSugar) {
            self.bloodSugarData = data
        }

        if let medication = metric.medicationLog,
           let data = try? encoder.encode(medication) {
            self.medicationData = data
        }

        if let bloodPressure = metric.bloodPressureReading,
           let data = try? encoder.encode(bloodPressure) {
            self.bloodPressureData = data
        }
    }

    func toHealthMetric() -> HealthMetric? {
        guard let id = self.id,
              let typeRaw = self.type,
              let type = HealthMetricType(rawValue: typeRaw),
              let unit = self.unit,
              let recordedAt = self.recordedAt else {
            return nil
        }

        let decoder = JSONDecoder()

        let bloodSugar = try? decoder.decode(BloodSugarReading.self, from: bloodSugarData ?? Data())
        let medication = try? decoder.decode(MedicationLog.self, from: medicationData ?? Data())
        let bloodPressure = try? decoder.decode(BloodPressureReading.self, from: bloodPressureData ?? Data())

        return HealthMetric(
            id: id,
            type: type,
            value: value,
            unit: unit,
            recordedAt: recordedAt,
            notes: notes,
            bloodSugarReading: bloodSugar,
            medicationLog: medication,
            bloodPressureReading: bloodPressure
        )
    }
}

// MARK: - HealthMetricEntity Mock (for repositories without actual Core Data)

@objc(HealthMetricEntity)
class HealthMetricEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var type: String?
    @NSManaged var value: Double
    @NSManaged var unit: String?
    @NSManaged var recordedAt: Date?
    @NSManaged var notes: String?
    @NSManaged var bloodSugarData: Data?
    @NSManaged var medicationData: Data?
    @NSManaged var bloodPressureData: Data?
}
