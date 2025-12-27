//
//  ADHDAssistantApp.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import SwiftUI

@main
struct ADHDAssistantApp: App {

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dependencies = DependencyContainer.shared
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(dependencies.agentCoordinator)
                        .environmentObject(dependencies.modelManager)
                        .environmentObject(dependencies.gamificationCoordinator)
                        .environmentObject(dependencies.taskRepository)
                        .environmentObject(dependencies.goalRepository)
                        .environmentObject(dependencies.healthRepository)
                        .environment(\.dependencies, dependencies)
                } else {
                    OnboardingView(
                        viewModel: OnboardingViewModel(
                            dependencies: dependencies,
                            onComplete: {
                                hasCompletedOnboarding = true
                            }
                        )
                    )
                }
            }
            .task {
                await loadModels()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
        }
    }

    // MARK: - Model Loading

    private func loadModels() async {
        if AppConfiguration.Debug.verboseLogging {
            print("🚀 Loading AI models...")
        }

        do {
            try await dependencies.modelManager.loadModel()

            if AppConfiguration.Debug.verboseLogging {
                print("✅ Models loaded successfully")
            }
        } catch {
            if AppConfiguration.Debug.verboseLogging {
                print("❌ Failed to load models: \(error)")
            }
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            handleAppBecameActive()

        case .inactive:
            handleAppBecameInactive()

        case .background:
            handleAppEnteredBackground()

        @unknown default:
            break
        }
    }

    private func handleAppBecameActive() {
        if AppConfiguration.Debug.verboseLogging {
            print("📱 App became active")
        }

        // Update streak status
        Task {
            await dependencies.streakService.updateStreak()
        }

        // Check for overdue tasks
        Task {
            await updateBadgeCount()
        }

        // Request notification permissions if needed
        Task {
            await requestNotificationPermissionsIfNeeded()
        }
    }

    private func handleAppBecameInactive() {
        if AppConfiguration.Debug.verboseLogging {
            print("📱 App became inactive")
        }
    }

    private func handleAppEnteredBackground() {
        if AppConfiguration.Debug.verboseLogging {
            print("📱 App entered background")
        }

        // Save context
        dependencies.coreDataStack.saveContext()

        // Schedule background refresh
        appDelegate.scheduleBackgroundRefresh()
    }

    // MARK: - Badge Management

    private func updateBadgeCount() async {
        do {
            let overdueTasks = try await dependencies.taskRepository.fetchOverdueTasks()
            let count = overdueTasks.filter { $0.status != "completed" }.count

            await MainActor.run {
                UNUserNotificationCenter.current().setBadgeCount(count)
            }
        } catch {
            if AppConfiguration.Debug.verboseLogging {
                print("❌ Failed to update badge count: \(error)")
            }
        }
    }

    // MARK: - Notification Permissions

    private func requestNotificationPermissionsIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            // Don't auto-request - let user trigger from settings
            return
        }

        // Register notification categories
        await registerNotificationCategories()
    }

    private func registerNotificationCategories() async {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 30m",
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([taskCategory])
    }
}
