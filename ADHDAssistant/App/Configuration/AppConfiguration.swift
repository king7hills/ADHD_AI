//
//  AppConfiguration.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import Foundation

/// Environment configuration for the app
enum AppEnvironment: String {
    case development
    case staging
    case production

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

/// Application configuration and feature flags
struct AppConfiguration {

    // MARK: - Environment

    static let environment = AppEnvironment.current

    // MARK: - Feature Flags

    struct FeatureFlags {
        /// Enable diabetes health tracking features
        static let diabetesSupport = true

        /// Enable achievement celebrations
        static let celebrationsEnabled = true

        /// Enable AI chat assistant
        static let aiChatEnabled = true

        /// Enable voice input for tasks
        static let voiceInputEnabled = true

        /// Enable widget support
        static let widgetsEnabled = true

        /// Enable live activities
        static let liveActivitiesEnabled = true

        /// Enable analytics tracking
        static let analyticsEnabled = environment == .production

        /// Enable experimental features
        static let experimentalFeatures = environment == .development
    }

    // MARK: - API Configuration

    struct API {
        /// API base URL (placeholder - configure based on backend)
        static let baseURL: String = {
            switch environment {
            case .development:
                return "https://dev-api.adhdassistant.app"
            case .staging:
                return "https://staging-api.adhdassistant.app"
            case .production:
                return "https://api.adhdassistant.app"
            }
        }()

        /// API timeout in seconds
        static let timeout: TimeInterval = 30

        /// API key (placeholder - should be stored securely)
        static let apiKey: String? = nil
    }

    // MARK: - Model Configuration

    struct Models {
        /// LFM model name for on-device inference
        static let lfmModelName = "llama-3.2-1B-instruct-q4f16_1-MLC"

        /// Maximum conversation history to maintain
        static let maxConversationHistory = 20

        /// Context window size
        static let contextWindowSize = 2048

        /// Temperature for text generation
        static let temperature: Float = 0.7

        /// Top-P sampling parameter
        static let topP: Float = 0.9

        /// Maximum tokens to generate
        static let maxTokens = 512
    }

    // MARK: - Gamification Settings

    struct Gamification {
        /// Points awarded for completing a task
        static let taskCompletionPoints = 10

        /// Bonus points for completing on time
        static let onTimeBonus = 5

        /// Bonus points for maintaining streak
        static let streakBonus = 3

        /// Days required to establish a habit
        static let habitFormationDays = 21

        /// Maximum streak to track
        static let maxStreakDays = 365
    }

    // MARK: - Notification Settings

    struct Notifications {
        /// Default reminder time before task deadline (in minutes)
        static let defaultReminderMinutes = 30

        /// Enable smart reminders based on user patterns
        static let smartRemindersEnabled = true

        /// Quiet hours start time (24-hour format)
        static let quietHoursStart = 22 // 10 PM

        /// Quiet hours end time (24-hour format)
        static let quietHoursEnd = 8 // 8 AM
    }

    // MARK: - Health Settings

    struct Health {
        /// Enable HealthKit integration
        static let healthKitEnabled = true

        /// Blood glucose target range (mg/dL)
        static let glucoseTargetLow: Double = 70
        static let glucoseTargetHigh: Double = 180

        /// Alert threshold for low blood sugar (mg/dL)
        static let glucoseLowThreshold: Double = 70

        /// Alert threshold for high blood sugar (mg/dL)
        static let glucoseHighThreshold: Double = 250
    }

    // MARK: - Debug Settings

    struct Debug {
        /// Enable verbose logging
        static let verboseLogging = environment == .development

        /// Enable performance monitoring
        static let performanceMonitoring = true

        /// Enable memory leak detection
        static let memoryLeakDetection = environment == .development

        /// Show FPS counter
        static let showFPSCounter = false

        /// Enable network request logging
        static let logNetworkRequests = environment == .development

        /// Reset onboarding on launch
        static let resetOnboarding = false

        /// Mock data for previews
        static let useMockData = false
    }

    // MARK: - App Information

    struct Info {
        static let appName = "ADHD Assistant"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.adhdassistant.app"
    }

    // MARK: - Storage

    struct Storage {
        /// Maximum image cache size in MB
        static let maxImageCacheSize = 100

        /// Maximum audio recording duration in seconds
        static let maxAudioDuration: TimeInterval = 300 // 5 minutes

        /// Core Data model name
        static let coreDataModelName = "ADHDAssistant"
    }
}
