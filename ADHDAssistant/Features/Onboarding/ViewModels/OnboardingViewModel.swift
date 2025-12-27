//
//  OnboardingViewModel.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep = 0
    @Published var totalSteps = 6

    // Profile
    @Published var userName = ""
    @Published var hasDiabetes = false

    // Goals
    @Published var selectedGoals: Set<OnboardingGoal> = []

    // Preferences
    @Published var interventionStyle: InterventionStyle = .balanced
    @Published var enableNotifications = true
    @Published var enableHealthTracking = false

    // State
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let dependencies: DependencyContainer
    private let onComplete: () -> Void

    // MARK: - Computed Properties

    var canProceed: Bool {
        switch currentStep {
        case 0: // Welcome
            return true
        case 1: // Name
            return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: // Goals
            return !selectedGoals.isEmpty
        case 3: // Health
            return true
        case 4: // Notifications
            return true
        case 5: // Preferences
            return true
        default:
            return false
        }
    }

    var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }

    // MARK: - Initialization

    init(dependencies: DependencyContainer, onComplete: @escaping () -> Void) {
        self.dependencies = dependencies
        self.onComplete = onComplete
    }

    // MARK: - Navigation

    func nextStep() {
        guard canProceed else { return }

        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }

    func previousStep() {
        guard currentStep > 0 else { return }

        withAnimation {
            currentStep -= 1
        }
    }

    func skipToEnd() {
        // Set reasonable defaults
        if userName.isEmpty {
            userName = "User"
        }

        if selectedGoals.isEmpty {
            selectedGoals = [.taskManagement]
        }

        completeOnboarding()
    }

    // MARK: - Goal Selection

    func toggleGoal(_ goal: OnboardingGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    // MARK: - Completion

    func completeOnboarding() {
        isLoading = true

        Task {
            do {
                // Create user profile
                try await createUserProfile()

                // Create initial goals
                try await createInitialGoals()

                // Configure preferences
                savePreferences()

                // Request notification permissions if enabled
                if enableNotifications {
                    await requestNotificationPermission()
                }

                // Mark onboarding as complete
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)

                // Show completion celebration
                await showCompletionCelebration()

                // Call completion handler
                await MainActor.run {
                    isLoading = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to complete setup: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Profile Creation

    private func createUserProfile() async throws {
        let context = dependencies.coreDataStack.viewContext

        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.name = userName
        profile.hasDiabetes = hasDiabetes
        profile.createdAt = Date()
        profile.updatedAt = Date()

        try context.save()
    }

    // MARK: - Initial Goals

    private func createInitialGoals() async throws {
        let context = dependencies.coreDataStack.viewContext

        for onboardingGoal in selectedGoals {
            let goal = Goal(context: context)
            goal.id = UUID()
            goal.title = onboardingGoal.defaultTitle
            goal.goalDescription = onboardingGoal.defaultDescription
            goal.category = onboardingGoal.category
            goal.targetValue = onboardingGoal.defaultTargetValue
            goal.currentValue = 0
            goal.startDate = Date()
            goal.targetDate = Calendar.current.date(byAdding: .day, value: 21, to: Date())
            goal.createdAt = Date()
            goal.updatedAt = Date()
        }

        try context.save()
    }

    // MARK: - Preferences

    private func savePreferences() {
        let defaults = UserDefaults.standard

        defaults.set(interventionStyle.rawValue, forKey: UserDefaultsKeys.interventionStyle)
        defaults.set(enableHealthTracking, forKey: UserDefaultsKeys.healthTrackingEnabled)
        defaults.set(enableNotifications, forKey: UserDefaultsKeys.notificationsEnabled)

        // Set default reminder time
        defaults.set(
            AppConfiguration.Notifications.defaultReminderMinutes,
            forKey: UserDefaultsKeys.defaultReminderMinutes
        )
    }

    // MARK: - Notifications

    private func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            // Don't fail onboarding if notifications fail
            if AppConfiguration.Debug.verboseLogging {
                print("❌ Failed to request notification permission: \(error)")
            }
        }
    }

    // MARK: - Celebration

    private func showCompletionCelebration() async {
        if AppConfiguration.FeatureFlags.celebrationsEnabled {
            await dependencies.celebrationService.celebrate(
                .majorAchievement,
                message: "Welcome to ADHD Assistant!"
            )
        }
    }
}

// MARK: - Onboarding Goal

enum OnboardingGoal: String, CaseIterable, Identifiable {
    case taskManagement
    case timeManagement
    case habitBuilding
    case healthTracking
    case focusImprovement
    case emotionalRegulation

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .taskManagement: return "checklist"
        case .timeManagement: return "clock.fill"
        case .habitBuilding: return "repeat.circle.fill"
        case .healthTracking: return "heart.fill"
        case .focusImprovement: return "target"
        case .emotionalRegulation: return "brain.head.profile"
        }
    }

    var title: String {
        switch self {
        case .taskManagement: return "Task Management"
        case .timeManagement: return "Time Management"
        case .habitBuilding: return "Habit Building"
        case .healthTracking: return "Health Tracking"
        case .focusImprovement: return "Focus & Attention"
        case .emotionalRegulation: return "Emotional Balance"
        }
    }

    var description: String {
        switch self {
        case .taskManagement:
            return "Break down tasks and stay organized"
        case .timeManagement:
            return "Better estimate and use your time"
        case .habitBuilding:
            return "Build consistent daily routines"
        case .healthTracking:
            return "Track health metrics and medications"
        case .focusImprovement:
            return "Reduce distractions and improve concentration"
        case .emotionalRegulation:
            return "Manage emotions and reduce overwhelm"
        }
    }

    var defaultTitle: String {
        switch self {
        case .taskManagement:
            return "Stay organized with tasks"
        case .timeManagement:
            return "Improve time awareness"
        case .habitBuilding:
            return "Build morning routine"
        case .healthTracking:
            return "Track daily health"
        case .focusImprovement:
            return "Maintain focus sessions"
        case .emotionalRegulation:
            return "Practice emotional check-ins"
        }
    }

    var defaultDescription: String {
        switch self {
        case .taskManagement:
            return "Complete daily tasks consistently"
        case .timeManagement:
            return "Estimate task duration accurately"
        case .habitBuilding:
            return "Complete morning routine for 21 days"
        case .healthTracking:
            return "Log health metrics daily"
        case .focusImprovement:
            return "Complete focused work sessions"
        case .emotionalRegulation:
            return "Regular emotional awareness practice"
        }
    }

    var category: String {
        switch self {
        case .taskManagement: return "productivity"
        case .timeManagement: return "productivity"
        case .habitBuilding: return "habits"
        case .healthTracking: return "health"
        case .focusImprovement: return "productivity"
        case .emotionalRegulation: return "wellness"
        }
    }

    var defaultTargetValue: Double {
        switch self {
        case .taskManagement: return 50 // 50 tasks
        case .timeManagement: return 21 // 21 days
        case .habitBuilding: return 21 // 21 days
        case .healthTracking: return 30 // 30 days
        case .focusImprovement: return 40 // 40 sessions
        case .emotionalRegulation: return 30 // 30 check-ins
        }
    }
}
