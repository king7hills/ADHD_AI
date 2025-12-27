//
//  ContentView.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Properties

    @State private var selectedTab = 0
    @State private var overdueBadgeCount = 0

    @EnvironmentObject private var taskRepository: TaskRepository
    @EnvironmentObject private var gamificationCoordinator: GamificationCoordinator

    // Deep link handling
    @State private var navigationPath = NavigationPath()
    @State private var taskToOpen: UUID?

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(0)

            // Tasks Tab
            NavigationStack {
                TaskListView()
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .badge(overdueBadgeCount > 0 ? overdueBadgeCount : 0)
            .tag(1)

            // Chat Tab
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(2)

            // Health Tab
            if AppConfiguration.FeatureFlags.diabetesSupport {
                NavigationStack {
                    HealthDashboardView()
                }
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
                .tag(3)
            }

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(AppColors.primary)
        .onAppear {
            updateBadgeCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TasksUpdated"))) { _ in
            updateBadgeCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenTaskFromNotification"))) { notification in
            handleTaskNotification(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HandleDeepLink"))) { notification in
            handleDeepLink(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HandleShortcut"))) { notification in
            handleShortcut(notification)
        }
    }

    // MARK: - Badge Count

    private func updateBadgeCount() {
        Task {
            do {
                let overdueTasks = try await taskRepository.fetchOverdueTasks()
                let count = overdueTasks.filter { $0.status != "completed" }.count

                await MainActor.run {
                    overdueBadgeCount = count
                }
            } catch {
                if AppConfiguration.Debug.verboseLogging {
                    print("❌ Failed to fetch overdue tasks: \(error)")
                }
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleTaskNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            return
        }

        // Switch to tasks tab and open the task
        selectedTab = 1
        taskToOpen = taskId

        // Post notification to task list to open specific task
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenTask"),
            object: taskId
        )
    }

    private func handleDeepLink(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }

        // Parse deep link URL
        // Examples:
        // adhdassistant://task/[id]
        // adhdassistant://chat
        // adhdassistant://health

        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard let host = components?.host else { return }

        switch host {
        case "task":
            if let taskIdString = components?.path.replacingOccurrences(of: "/", with: ""),
               let taskId = UUID(uuidString: taskIdString) {
                selectedTab = 1
                taskToOpen = taskId
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenTask"),
                    object: taskId
                )
            } else {
                selectedTab = 1
            }

        case "chat":
            selectedTab = 2

        case "health":
            selectedTab = 3

        case "dashboard":
            selectedTab = 0

        case "settings":
            selectedTab = 4

        default:
            break
        }
    }

    private func handleShortcut(_ notification: Notification) {
        guard let shortcut = notification.object as? UIApplicationShortcutItem else { return }

        switch shortcut.type {
        case "com.adhdassistant.quicktask":
            selectedTab = 1
            // Post notification to show quick add sheet
            NotificationCenter.default.post(name: NSNotification.Name("ShowQuickAddTask"), object: nil)

        case "com.adhdassistant.chat":
            selectedTab = 2

        case "com.adhdassistant.loggluocose":
            selectedTab = 3
            // Post notification to show glucose logging sheet
            NotificationCenter.default.post(name: NSNotification.Name("ShowGlucoseLog"), object: nil)

        default:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(DependencyContainer.preview.taskRepository)
        .environmentObject(DependencyContainer.preview.goalRepository)
        .environmentObject(DependencyContainer.preview.healthRepository)
        .environmentObject(DependencyContainer.preview.gamificationCoordinator)
        .environmentObject(DependencyContainer.preview.agentCoordinator)
        .environmentObject(DependencyContainer.preview.modelManager)
}
