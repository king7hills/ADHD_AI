//
//  AppConstants.swift
//  ADHDAssistant
//
//  Application-wide constants and configuration values
//

import Foundation

/// Application-wide constants
struct AppConstants {
    // MARK: - App Information

    struct App {
        static let name = "ADHD Assistant"
        static let bundleIdentifier = "com.adhdassistant.app"
        static let version = "1.0.0"
        static let buildNumber = "1"
    }

    // MARK: - Task Configuration

    struct Task {
        /// Minimum task duration in seconds (5 minutes)
        static let minDuration: TimeInterval = 300

        /// Maximum task duration in seconds (4 hours)
        static let maxDuration: TimeInterval = 14400

        /// Default task duration in seconds (30 minutes)
        static let defaultDuration: TimeInterval = 1800

        /// Recommended task duration for ADHD users (15 minutes)
        static let recommendedDuration: TimeInterval = 900

        /// Maximum number of subtasks per task
        static let maxSubtasks = 20

        /// Default snooze duration in seconds (15 minutes)
        static let defaultSnoozeDuration: TimeInterval = 900

        /// Task overdue threshold in seconds (5 minutes past scheduled time)
        static let overdueThreshold: TimeInterval = 300

        /// Maximum conversation history for task context
        static let maxConversationHistory = 50
    }

    // MARK: - Points and Gamification

    struct Points {
        /// Base points for completing a task
        static let taskCompletion = 10

        /// Bonus points for completing on time
        static let onTimeBonus = 5

        /// Bonus points for completing ahead of schedule
        static let earlyBonus = 10

        /// Points for completing all daily tasks
        static let dailyCompletionBonus = 50

        /// Points for maintaining streak (per day)
        static let streakPointsPerDay = 5

        /// Points for completing a goal
        static let goalCompletion = 100

        /// Points for logging health metrics
        static let healthMetricLog = 3

        /// Points for completing AI-suggested task
        static let aiSuggestedTaskBonus = 5

        /// Minimum points to unlock bronze achievement
        static let bronzeThreshold = 50

        /// Minimum points to unlock silver achievement
        static let silverThreshold = 100

        /// Minimum points to unlock gold achievement
        static let goldThreshold = 250
    }

    // MARK: - Streak Thresholds

    struct Streak {
        /// Minimum streak to be considered "active"
        static let activeThreshold = 3

        /// Streak considered "strong"
        static let strongThreshold = 7

        /// Streak considered "legendary"
        static let legendaryThreshold = 30

        /// Maximum hours without activity before breaking streak
        static let maxInactivityHours: TimeInterval = 36 * 3600 // 36 hours

        /// Grace period for maintaining streak (end of day + grace)
        static let gracePeriodHours: TimeInterval = 4 * 3600 // 4 hours
    }

    // MARK: - AI and Model Configuration

    struct AI {
        /// Default AI model name for Claude
        static let defaultModel = "claude-3-5-sonnet-20241022"

        /// Alternative model for faster responses
        static let fastModel = "claude-3-5-haiku-20241022"

        /// Maximum tokens for AI responses
        static let maxTokens = 2048

        /// Temperature for AI responses (0.0 - 1.0)
        static let temperature = 0.7

        /// Maximum conversation messages to include in context
        static let maxContextMessages = 10

        /// AI response timeout in seconds
        static let responseTimeout: TimeInterval = 30

        /// Minimum confidence for AI suggestions (0.0 - 1.0)
        static let minSuggestionConfidence = 0.7

        /// Maximum AI suggestions per request
        static let maxSuggestions = 5
    }

    // MARK: - Notification Identifiers

    struct Notifications {
        /// Task reminder notification
        static let taskReminder = "task_reminder"

        /// Task due soon notification
        static let taskDueSoon = "task_due_soon"

        /// Task overdue notification
        static let taskOverdue = "task_overdue"

        /// Medication reminder notification
        static let medicationReminder = "medication_reminder"

        /// Health check reminder
        static let healthCheckReminder = "health_check_reminder"

        /// Streak about to break warning
        static let streakWarning = "streak_warning"

        /// Daily summary notification
        static let dailySummary = "daily_summary"

        /// Achievement unlocked notification
        static let achievementUnlocked = "achievement_unlocked"

        /// Motivational check-in
        static let motivationalCheckIn = "motivational_checkin"

        /// Weekly review reminder
        static let weeklyReview = "weekly_review"

        /// Category for critical health notifications
        static let healthCriticalCategory = "HEALTH_CRITICAL"

        /// Category for task notifications
        static let taskCategory = "TASK"

        /// Category for achievement notifications
        static let achievementCategory = "ACHIEVEMENT"
    }

    // MARK: - UserDefaults Keys

    struct UserDefaultsKeys {
        /// User profile key
        static let userProfile = "user_profile"

        /// Tasks array key
        static let tasks = "tasks"

        /// Goals array key
        static let goals = "goals"

        /// Health metrics array key
        static let healthMetrics = "health_metrics"

        /// Achievements array key
        static let achievements = "achievements"

        /// AI context key
        static let aiContext = "ai_context"

        /// Current streak key
        static let currentStreak = "current_streak"

        /// Longest streak key
        static let longestStreak = "longest_streak"

        /// Total points key
        static let totalPoints = "total_points"

        /// Current level key
        static let currentLevel = "current_level"

        /// Last active date key
        static let lastActiveDate = "last_active_date"

        /// Onboarding completed key
        static let onboardingCompleted = "onboarding_completed"

        /// Notifications enabled key
        static let notificationsEnabled = "notifications_enabled"

        /// Theme preference key
        static let themePreference = "theme_preference"

        /// API key (stored securely in Keychain, this is just the key name)
        static let apiKeyIdentifier = "anthropic_api_key"

        /// App launch count
        static let appLaunchCount = "app_launch_count"

        /// Last app version
        static let lastAppVersion = "last_app_version"
    }

    // MARK: - Time Constants

    struct Time {
        /// Seconds in a minute
        static let secondsPerMinute: TimeInterval = 60

        /// Seconds in an hour
        static let secondsPerHour: TimeInterval = 3600

        /// Seconds in a day
        static let secondsPerDay: TimeInterval = 86400

        /// Seconds in a week
        static let secondsPerWeek: TimeInterval = 604800

        /// Default reminder time before task (15 minutes)
        static let defaultReminderBefore: TimeInterval = 900

        /// Quick reminder time (5 minutes)
        static let quickReminderTime: TimeInterval = 300

        /// Long reminder time (1 hour)
        static let longReminderTime: TimeInterval = 3600

        /// Session timeout (30 minutes of inactivity)
        static let sessionTimeout: TimeInterval = 1800

        /// Cache expiration time (1 hour)
        static let cacheExpiration: TimeInterval = 3600
    }

    // MARK: - UI Constants

    struct UI {
        /// Default animation duration
        static let defaultAnimationDuration = 0.3

        /// Quick animation duration
        static let quickAnimationDuration = 0.15

        /// Slow animation duration
        static let slowAnimationDuration = 0.5

        /// Haptic feedback intensity (0.0 - 1.0)
        static let hapticIntensity = 0.7

        /// Celebration animation duration
        static let celebrationDuration = 2.0

        /// Default corner radius
        static let cornerRadius = 12.0

        /// Small corner radius
        static let smallCornerRadius = 8.0

        /// Large corner radius
        static let largeCornerRadius = 20.0

        /// Default padding
        static let defaultPadding = 16.0

        /// Small padding
        static let smallPadding = 8.0

        /// Large padding
        static let largePadding = 24.0

        /// Icon size
        static let iconSize = 24.0

        /// Large icon size
        static let largeIconSize = 48.0
    }

    // MARK: - Health Metrics

    struct Health {
        /// Blood sugar normal range (mg/dL)
        static let bloodSugarNormalRange = 70.0...140.0

        /// Blood sugar critical low (mg/dL)
        static let bloodSugarCriticalLow = 70.0

        /// Blood sugar critical high (mg/dL)
        static let bloodSugarCriticalHigh = 250.0

        /// Medication adherence target (percentage)
        static let medicationAdherenceTarget = 0.9

        /// Minimum exercise minutes per day
        static let minExerciseMinutes = 30.0

        /// Recommended water intake (oz per day)
        static let recommendedWaterIntake = 64.0

        /// Blood pressure normal systolic max
        static let normalSystolicMax = 120

        /// Blood pressure normal diastolic max
        static let normalDiastolicMax = 80
    }

    // MARK: - Analytics

    struct Analytics {
        /// Event name for task completion
        static let taskCompletedEvent = "task_completed"

        /// Event name for goal completion
        static let goalCompletedEvent = "goal_completed"

        /// Event name for achievement unlocked
        static let achievementUnlockedEvent = "achievement_unlocked"

        /// Event name for health metric logged
        static let healthMetricLoggedEvent = "health_metric_logged"

        /// Event name for AI interaction
        static let aiInteractionEvent = "ai_interaction"

        /// Event name for streak milestone
        static let streakMilestoneEvent = "streak_milestone"
    }

    // MARK: - API Configuration

    struct API {
        /// Base URL for Claude API
        static let claudeBaseURL = "https://api.anthropic.com/v1"

        /// API version header
        static let apiVersion = "2023-06-01"

        /// Request timeout in seconds
        static let requestTimeout: TimeInterval = 30

        /// Maximum retry attempts
        static let maxRetryAttempts = 3

        /// Retry delay in seconds
        static let retryDelay: TimeInterval = 2
    }

    // MARK: - Feature Flags

    struct FeatureFlags {
        /// Enable AI suggestions
        static let aiSuggestionsEnabled = true

        /// Enable health tracking
        static let healthTrackingEnabled = true

        /// Enable achievements
        static let achievementsEnabled = true

        /// Enable analytics
        static let analyticsEnabled = false

        /// Enable debug mode
        #if DEBUG
        static let debugMode = true
        #else
        static let debugMode = false
        #endif

        /// Enable beta features
        static let betaFeaturesEnabled = false
    }

    // MARK: - Limits

    struct Limits {
        /// Maximum tasks per day
        static let maxTasksPerDay = 50

        /// Maximum goals active at once
        static let maxActiveGoals = 10

        /// Maximum tags per task
        static let maxTagsPerTask = 10

        /// Maximum title length
        static let maxTitleLength = 100

        /// Maximum description length
        static let maxDescriptionLength = 500

        /// Maximum notes length
        static let maxNotesLength = 1000
    }
}
