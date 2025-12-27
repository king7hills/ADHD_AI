//
//  SettingsViewModel.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var userProfile: UserProfile?
    @Published var notificationsEnabled = false
    @Published var healthTrackingEnabled = false
    @Published var interventionStyle: InterventionStyle = .balanced
    @Published var appearanceMode: AppearanceMode = .system
    @Published var quietHoursEnabled = false
    @Published var quietHoursStart = Date()
    @Published var quietHoursEnd = Date()
    @Published var defaultReminderMinutes = 30

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingResetConfirmation = false
    @Published var showingExportData = false

    // MARK: - Dependencies

    private let dependencies: DependencyContainer

    // MARK: - Computed Properties

    var appVersion: String {
        AppConfiguration.Info.version
    }

    var buildNumber: String {
        AppConfiguration.Info.buildNumber
    }

    var fullVersion: String {
        "Version \(appVersion) (\(buildNumber))"
    }

    // MARK: - Initialization

    init(dependencies: DependencyContainer = .shared) {
        self.dependencies = dependencies
        loadSettings()
    }

    // MARK: - Settings Management

    func loadSettings() {
        // Load user profile
        Task {
            do {
                userProfile = try await loadUserProfile()
            } catch {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
            }
        }

        // Load notification settings
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsEnabled = settings.authorizationStatus == .authorized
        }

        // Load preferences from UserDefaults
        let defaults = UserDefaults.standard

        healthTrackingEnabled = defaults.bool(forKey: UserDefaultsKeys.healthTrackingEnabled)

        if let styleRaw = defaults.string(forKey: UserDefaultsKeys.interventionStyle),
           let style = InterventionStyle(rawValue: styleRaw) {
            interventionStyle = style
        }

        if let modeRaw = defaults.string(forKey: UserDefaultsKeys.appearanceMode),
           let mode = AppearanceMode(rawValue: modeRaw) {
            appearanceMode = mode
        }

        quietHoursEnabled = defaults.bool(forKey: UserDefaultsKeys.quietHoursEnabled)
        defaultReminderMinutes = defaults.integer(forKey: UserDefaultsKeys.defaultReminderMinutes)

        // Set default if not configured
        if defaultReminderMinutes == 0 {
            defaultReminderMinutes = AppConfiguration.Notifications.defaultReminderMinutes
        }

        // Load quiet hours times
        if let startTime = defaults.object(forKey: UserDefaultsKeys.quietHoursStart) as? Date {
            quietHoursStart = startTime
        } else {
            var components = DateComponents()
            components.hour = AppConfiguration.Notifications.quietHoursStart
            quietHoursStart = Calendar.current.date(from: components) ?? Date()
        }

        if let endTime = defaults.object(forKey: UserDefaultsKeys.quietHoursEnd) as? Date {
            quietHoursEnd = endTime
        } else {
            var components = DateComponents()
            components.hour = AppConfiguration.Notifications.quietHoursEnd
            quietHoursEnd = Calendar.current.date(from: components) ?? Date()
        }
    }

    private func loadUserProfile() async throws -> UserProfile? {
        let context = dependencies.coreDataStack.viewContext
        let fetchRequest = UserProfile.fetchRequest()
        fetchRequest.fetchLimit = 1

        let profiles = try context.fetch(fetchRequest)
        return profiles.first
    }

    // MARK: - Profile Updates

    func updateProfile(name: String, hasDiabetes: Bool) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let profile = userProfile {
                profile.name = name
                profile.hasDiabetes = hasDiabetes
                profile.updatedAt = Date()
                try dependencies.coreDataStack.viewContext.save()
            } else {
                // Create new profile
                let context = dependencies.coreDataStack.viewContext
                let newProfile = UserProfile(context: context)
                newProfile.id = UUID()
                newProfile.name = name
                newProfile.hasDiabetes = hasDiabetes
                newProfile.createdAt = Date()
                newProfile.updatedAt = Date()
                try context.save()
                userProfile = newProfile
            }
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
    }

    // MARK: - Notification Settings

    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            notificationsEnabled = granted

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
        }
    }

    func updateNotificationSettings() {
        let defaults = UserDefaults.standard
        defaults.set(quietHoursEnabled, forKey: UserDefaultsKeys.quietHoursEnabled)
        defaults.set(quietHoursStart, forKey: UserDefaultsKeys.quietHoursStart)
        defaults.set(quietHoursEnd, forKey: UserDefaultsKeys.quietHoursEnd)
        defaults.set(defaultReminderMinutes, forKey: UserDefaultsKeys.defaultReminderMinutes)
    }

    // MARK: - Health Settings

    func updateHealthSettings() {
        UserDefaults.standard.set(healthTrackingEnabled, forKey: UserDefaultsKeys.healthTrackingEnabled)

        if healthTrackingEnabled {
            // Request HealthKit permissions
            Task {
                // TODO: Request HealthKit authorization
            }
        }
    }

    // MARK: - Appearance Settings

    func updateInterventionStyle(_ style: InterventionStyle) {
        interventionStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: UserDefaultsKeys.interventionStyle)
    }

    func updateAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: UserDefaultsKeys.appearanceMode)

        // Apply appearance mode
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = mode.userInterfaceStyle
        }
    }

    // MARK: - Data Management

    func exportData() async -> URL? {
        isLoading = true
        defer { isLoading = false }

        do {
            // Create export data
            let exportData = try await createExportData()

            // Save to temporary file
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            let fileName = "ADHD_Assistant_Export_\(Date().ISO8601Format()).json"
            let fileURL = tempDir.appendingPathComponent(fileName)

            let jsonData = try JSONEncoder().encode(exportData)
            try jsonData.write(to: fileURL)

            return fileURL
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            return nil
        }
    }

    private func createExportData() async throws -> ExportData {
        let context = dependencies.coreDataStack.viewContext

        // Fetch all entities
        let taskRequest = Task.fetchRequest()
        let tasks = try context.fetch(taskRequest)

        let goalRequest = Goal.fetchRequest()
        let goals = try context.fetch(goalRequest)

        let healthRequest = HealthMetric.fetchRequest()
        let healthMetrics = try context.fetch(healthRequest)

        let achievementRequest = Achievement.fetchRequest()
        let achievements = try context.fetch(achievementRequest)

        return ExportData(
            exportDate: Date(),
            profile: userProfile,
            tasks: tasks,
            goals: goals,
            healthMetrics: healthMetrics,
            achievements: achievements
        )
    }

    func clearAllData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            dependencies.reset()
            errorMessage = nil

            // Reload settings
            loadSettings()
        } catch {
            errorMessage = "Failed to clear data: \(error.localizedDescription)"
        }
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.hasCompletedOnboarding)

        // Restart app
        exit(0)
    }
}

// MARK: - Supporting Types

enum InterventionStyle: String, CaseIterable {
    case gentle = "gentle"
    case balanced = "balanced"
    case direct = "direct"

    var displayName: String {
        switch self {
        case .gentle: return "Gentle & Supportive"
        case .balanced: return "Balanced"
        case .direct: return "Direct & Firm"
        }
    }

    var description: String {
        switch self {
        case .gentle:
            return "Empathetic reminders with positive reinforcement"
        case .balanced:
            return "Mix of encouragement and accountability"
        case .direct:
            return "Clear, straightforward task management"
        }
    }
}

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
}

struct ExportData: Codable {
    let exportDate: Date
    let profile: UserProfile?
    let tasks: [Task]
    let goals: [Goal]
    let healthMetrics: [HealthMetric]
    let achievements: [Achievement]
}
