//
//  AppDelegate.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import UIKit
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure notification center
        UNUserNotificationCenter.current().delegate = self

        // Register for remote notifications
        registerForRemoteNotifications(application)

        // Register background tasks
        registerBackgroundTasks()

        // Configure appearance
        configureAppearance()

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    // MARK: - Remote Notifications

    private func registerForRemoteNotifications(_ application: UIApplication) {
        Task {
            do {
                let settings = await UNUserNotificationCenter.current().notificationSettings()

                if settings.authorizationStatus == .notDetermined {
                    // Don't request permissions here - let the app do it at appropriate time
                    return
                }

                if settings.authorizationStatus == .authorized {
                    await MainActor.run {
                        application.registerForRemoteNotifications()
                    }
                }
            }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()

        if AppConfiguration.Debug.verboseLogging {
            print("📱 Device Token: \(token)")
        }

        // Store token for backend registration
        UserDefaults.standard.set(token, forKey: UserDefaultsKeys.deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        if AppConfiguration.Debug.verboseLogging {
            print("❌ Failed to register for remote notifications: \(error)")
        }
    }

    // MARK: - Background Tasks

    private func registerBackgroundTasks() {
        // Register task reminder refresh
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.adhdassistant.refresh",
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        // Register database cleanup
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.adhdassistant.cleanup",
            using: nil
        ) { task in
            self.handleDatabaseCleanup(task: task as! BGProcessingTask)
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        Task {
            do {
                // Update task statuses and send notifications for upcoming tasks
                let dependencies = DependencyContainer.shared
                let overdueTasks = try await dependencies.taskRepository.fetchOverdueTasks()

                // Schedule notifications for overdue tasks
                for task in overdueTasks where task.status != "completed" {
                    await scheduleTaskNotification(for: task)
                }

                task.setTaskCompleted(success: true)
            } catch {
                if AppConfiguration.Debug.verboseLogging {
                    print("❌ Background refresh failed: \(error)")
                }
                task.setTaskCompleted(success: false)
            }
        }

        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
    }

    private func handleDatabaseCleanup(task: BGProcessingTask) {
        Task {
            do {
                // Clean up old completed tasks and memories
                let dependencies = DependencyContainer.shared
                let calendar = Calendar.current
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!

                // Archive old completed tasks
                try await dependencies.taskRepository.archiveCompletedTasks(before: thirtyDaysAgo)

                // Clean up old conversation history
                try await dependencies.memoryStore.cleanupOldMemories(before: thirtyDaysAgo)

                task.setTaskCompleted(success: true)
            } catch {
                if AppConfiguration.Debug.verboseLogging {
                    print("❌ Database cleanup failed: \(error)")
                }
                task.setTaskCompleted(success: false)
            }
        }

        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.adhdassistant.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            if AppConfiguration.Debug.verboseLogging {
                print("❌ Could not schedule background refresh: \(error)")
            }
        }
    }

    // MARK: - Notification Scheduling

    private func scheduleTaskNotification(for task: Task) async {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title ?? "You have a task to complete"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": task.id?.uuidString ?? ""]

        // Badge with overdue count
        let dependencies = DependencyContainer.shared
        let overdueCount = (try? await dependencies.taskRepository.fetchOverdueTasks().count) ?? 0
        content.badge = NSNumber(value: overdueCount)

        // Immediate notification for overdue tasks
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: task.id?.uuidString ?? UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Appearance Configuration

    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification actions
        switch response.actionIdentifier {
        case "COMPLETE_ACTION":
            handleCompleteTaskAction(userInfo: userInfo)

        case "SNOOZE_ACTION":
            handleSnoozeAction(userInfo: userInfo)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            handleNotificationTap(userInfo: userInfo)

        default:
            break
        }

        completionHandler()
    }

    // MARK: - Notification Actions

    private func handleCompleteTaskAction(userInfo: [AnyHashable: Any]) {
        guard let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            return
        }

        Task {
            let dependencies = DependencyContainer.shared
            if let task = try? await dependencies.taskRepository.fetchTask(by: taskId) {
                task.status = "completed"
                task.completedAt = Date()
                try? await dependencies.taskRepository.update(task)

                // Award points
                await dependencies.gamificationCoordinator.handleTaskCompletion(task)
            }
        }
    }

    private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
        guard let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            return
        }

        Task {
            let dependencies = DependencyContainer.shared
            if let task = try? await dependencies.taskRepository.fetchTask(by: taskId) {
                // Reschedule for 30 minutes later
                let newDeadline = Date().addingTimeInterval(30 * 60)
                task.deadline = newDeadline
                try? await dependencies.taskRepository.update(task)

                // Schedule new notification
                await scheduleTaskNotification(for: task)
            }
        }
    }

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Post notification for deep linking
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenTaskFromNotification"),
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - Scene Delegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Handle deep links or shortcuts
        if let userActivity = connectionOptions.userActivities.first {
            handleUserActivity(userActivity)
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcut(shortcutItem)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let handled = handleShortcut(shortcutItem)
        completionHandler(handled)
    }

    // MARK: - Deep Link Handling

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            // Handle universal links
            NotificationCenter.default.post(
                name: NSNotification.Name("HandleDeepLink"),
                object: url
            )
        }
    }

    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        NotificationCenter.default.post(
            name: NSNotification.Name("HandleShortcut"),
            object: shortcutItem
        )
        return true
    }
}
