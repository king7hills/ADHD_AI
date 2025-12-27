# Project Setup Guide

Step-by-step instructions for setting up the ADHD Executive Function Assistant iOS project.

---

## Prerequisites

### Development Environment
- **macOS**: Sonoma 14.0 or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9+
- **iOS Deployment Target**: 18.0+

### Hardware for Testing
- iPhone with 3GB+ RAM (iPhone XS or newer recommended)
- Physical device required for on-device AI inference
- Simulator works but runs models significantly slower

### Accounts
- Apple Developer account (for push notifications, Live Activities)
- Access to LEAP Model Library (for downloading LFM2 models)

---

## Step 1: Create Xcode Project

### Option A: Using Xcode

1. Open Xcode
2. File → New → Project
3. Select **iOS App**
4. Configure:
   - Product Name: `ADHDAssistant`
   - Team: Your Apple Developer team
   - Organization Identifier: `com.yourorg`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we'll add Core Data manually)
5. Create project

### Option B: Using Command Line

```bash
mkdir ADHDAssistant
cd ADHDAssistant
swift package init --type executable --name ADHDAssistant
```

---

## Step 2: Configure Swift Package Manager

Create or update `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ADHDAssistant",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ADHDAssistant",
            targets: ["ADHDAssistant"]
        ),
    ],
    dependencies: [
        // LEAP SDK for on-device AI
        .package(
            url: "https://github.com/Liquid4All/leap-ios.git",
            from: "0.7.7"
        ),

        // Testing
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.15.0"
        ),
    ],
    targets: [
        .target(
            name: "ADHDAssistant",
            dependencies: [
                .product(name: "LeapSDK", package: "leap-ios"),
            ]
        ),
        .testTarget(
            name: "ADHDAssistantTests",
            dependencies: [
                "ADHDAssistant",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
```

---

## Step 3: Create Folder Structure

Run this script from the project root to create the folder structure:

```bash
#!/bin/bash

# Create main folder structure
mkdir -p ADHDAssistant/{App/Configuration,Core/{Models,Extensions,Utilities,Constants}}
mkdir -p ADHDAssistant/Services/{AI,Agents,Notifications,Calendar,Persistence,ScreenTime,Gamification}
mkdir -p ADHDAssistant/Features/{Onboarding,Dashboard,Tasks,Goals,Chat,Health,Calendar,Achievements,Settings}/{Views,ViewModels}
mkdir -p ADHDAssistant/DesignSystem/{Components,Animations,Theme}
mkdir -p ADHDAssistant/{Widgets,LiveActivity,Resources/Models}

# Create placeholder files
touch ADHDAssistant/App/ADHDAssistantApp.swift
touch ADHDAssistant/App/AppDelegate.swift
touch ADHDAssistant/App/Configuration/AppConfiguration.swift

# Core Models
touch ADHDAssistant/Core/Models/{Task,Goal,UserProfile,Achievement,HealthMetric}.swift
touch ADHDAssistant/Core/Extensions/{Date+Extensions,String+Extensions,View+Extensions}.swift
touch ADHDAssistant/Core/Utilities/{TimeEstimator,HapticManager}.swift
touch ADHDAssistant/Core/Constants/AppConstants.swift

# Services
touch ADHDAssistant/Services/AI/{LFMService,ModelManager,PromptTemplates}.swift
touch ADHDAssistant/Services/Agents/{AgentCoordinator,TaskBreakdownAgent,CalendarAgent,BehaviorMonitorAgent,HealthAgent,MotivationAgent}.swift
touch ADHDAssistant/Services/Notifications/{NotificationService,LiveActivityService,NotificationScheduler}.swift
touch ADHDAssistant/Services/Calendar/{CalendarService,CalendarSync}.swift
touch ADHDAssistant/Services/Persistence/{TaskRepository,GoalRepository,MemoryStore,CoreDataStack}.swift
touch ADHDAssistant/Services/ScreenTime/{ScreenTimeService,AppUsageMonitor}.swift
touch ADHDAssistant/Services/Gamification/{PointsService,AchievementService,StreakService,CelebrationService}.swift

# Design System
touch ADHDAssistant/DesignSystem/Components/{PulsingButton,ProgressRing,ConfettiView,TimerDisplay,GlowingCard}.swift
touch ADHDAssistant/DesignSystem/Animations/{CelebrationAnimations,PulseAnimation,ConfettiAnimation}.swift
touch ADHDAssistant/DesignSystem/Theme/{Colors,Typography,Spacing}.swift

echo "Folder structure created successfully!"
```

---

## Step 4: Add LEAP SDK

### Via Xcode

1. File → Add Package Dependencies
2. Enter: `https://github.com/Liquid4All/leap-ios.git`
3. Select version: `0.7.7` or later
4. Add `LeapSDK` to your app target
5. Optionally add `LeapModelDownloader` for runtime model downloads

### Download Model Files

1. Visit [LEAP Model Library](https://leap.liquid.ai/models)
2. Download the following models:
   - `lfm2-350m.bundle` (smallest, fastest)
   - `lfm2-700m.bundle` (balanced)
   - `lfm2-1.2b.bundle` (most capable, optional)
3. Add to `ADHDAssistant/Resources/Models/`
4. Ensure "Copy Bundle Resources" includes the model files

---

## Step 5: Configure App Capabilities

In Xcode, select your target → Signing & Capabilities → Add:

### Required Capabilities

1. **Push Notifications**
   - Enables remote notifications

2. **Background Modes**
   - Background fetch
   - Remote notifications
   - Background processing

3. **HealthKit** (if integrating Apple Health)
   - Read: Blood Glucose, Activity

4. **App Groups** (for widgets and Live Activities)
   - Create group: `group.com.yourorg.adhdassistant`

### Info.plist Entries

```xml
<!-- Screen Time API -->
<key>NSFamilyControlsUsageDescription</key>
<string>ADHDAssistant monitors app usage to help you stay focused and avoid distractions.</string>

<!-- Notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>

<!-- Calendar Access -->
<key>NSCalendarsUsageDescription</key>
<string>ADHDAssistant needs calendar access to schedule tasks and avoid conflicts.</string>

<!-- HealthKit (if used) -->
<key>NSHealthShareUsageDescription</key>
<string>ADHDAssistant can read health data to provide personalized reminders.</string>
```

---

## Step 6: Core Data Setup

### Create Data Model

1. File → New → File → Data Model
2. Name: `ADHDAssistant.xcdatamodeld`
3. Add entities:

#### Task Entity
| Attribute | Type |
|-----------|------|
| id | UUID |
| title | String |
| taskDescription | String (optional) |
| estimatedDuration | Double |
| actualDuration | Double (optional) |
| scheduledTime | Date (optional) |
| completedAt | Date (optional) |
| status | String |
| priority | Int16 |
| pointsValue | Int32 |
| aiGenerated | Boolean |
| createdAt | Date |

#### Goal Entity
| Attribute | Type |
|-----------|------|
| id | UUID |
| title | String |
| goalDescription | String |
| category | String |
| targetDate | Date (optional) |
| progress | Double |
| isActive | Boolean |
| createdAt | Date |

#### HealthMetric Entity
| Attribute | Type |
|-----------|------|
| id | UUID |
| type | String |
| value | Double |
| unit | String |
| recordedAt | Date |
| notes | String (optional) |

#### Achievement Entity
| Attribute | Type |
|-----------|------|
| id | String |
| title | String |
| achievementDescription | String |
| tier | String |
| unlockedAt | Date (optional) |
| progress | Double |
| requirement | Int32 |

---

## Step 7: Initial App Structure

### ADHDAssistantApp.swift

```swift
import SwiftUI
import LeapSDK

@main
struct ADHDAssistantApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var coordinator = AgentCoordinator()
    @StateObject private var modelManager = ModelManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .environmentObject(modelManager)
                .task {
                    await modelManager.loadModels()
                }
        }
    }
}
```

### AppDelegate.swift

```swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure notifications
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermissions()

        // Register background tasks
        registerBackgroundTasks()

        return true
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound, .criticalAlert]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    private func registerBackgroundTasks() {
        // Register for background processing
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Handle notification actions
    }
}
```

---

## Step 8: Basic Model Manager

```swift
// Services/AI/ModelManager.swift

import Foundation
import LeapSDK

@MainActor
final class ModelManager: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var loadedModels: Set<ModelSize> = []
    @Published private(set) var error: Error?

    private var runners: [ModelSize: ModelRunner] = [:]

    enum ModelSize: String, CaseIterable {
        case small = "lfm2-350m"
        case medium = "lfm2-700m"
        case large = "lfm2-1.2b"

        var bundleName: String { rawValue }
    }

    func loadModels() async {
        isLoading = true
        defer { isLoading = false }

        // Start with smallest model for quick availability
        for size in [ModelSize.small, .medium] {
            do {
                try await loadModel(size)
            } catch {
                self.error = error
                print("Failed to load \(size.rawValue): \(error)")
            }
        }
    }

    private func loadModel(_ size: ModelSize) async throws {
        guard let modelURL = Bundle.main.url(
            forResource: size.bundleName,
            withExtension: "bundle"
        ) else {
            throw ModelError.modelNotFound(size.rawValue)
        }

        let runner = try await Leap.load(
            options: .init(bundlePath: modelURL.path())
        )
        runners[size] = runner
        loadedModels.insert(size)
    }

    func runner(for size: ModelSize) -> ModelRunner? {
        return runners[size]
    }

    enum ModelError: Error {
        case modelNotFound(String)
        case loadFailed(String)
    }
}
```

---

## Step 9: Verify Setup

### Create a Test View

```swift
// Features/Dashboard/Views/DashboardView.swift

import SwiftUI
import LeapSDK

struct DashboardView: View {
    @EnvironmentObject var modelManager: ModelManager
    @State private var testResponse = ""
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Model Status
                HStack {
                    Circle()
                        .fill(modelManager.loadedModels.isEmpty ? .red : .green)
                        .frame(width: 12, height: 12)
                    Text(modelManager.isLoading ? "Loading models..." : "Models ready")
                }

                // Test Button
                Button("Test AI") {
                    Task {
                        await testAI()
                    }
                }
                .disabled(modelManager.loadedModels.isEmpty || isGenerating)

                // Response
                if !testResponse.isEmpty {
                    Text(testResponse)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("ADHD Assistant")
        }
    }

    private func testAI() async {
        guard let runner = modelManager.runner(for: .small) else { return }

        isGenerating = true
        defer { isGenerating = false }

        let conversation = Conversation(modelRunner: runner, history: [])
        let message = ChatMessage(
            role: .user,
            content: [.text("Give me one small task to do right now.")]
        )

        var response = ""
        for await chunk in conversation.generateResponse(message: message) {
            if case .chunk(let text) = chunk {
                response += text
            }
        }
        testResponse = response
    }
}
```

---

## Step 10: Run and Verify

1. Connect a physical iOS device
2. Select your device as the run destination
3. Build and run (⌘R)
4. Verify:
   - App launches without crashes
   - Model status shows "Models ready"
   - Test AI button generates a response

---

## Troubleshooting

### Model Loading Fails
- Ensure model `.bundle` files are in the target's "Copy Bundle Resources"
- Check device has sufficient RAM (3GB+)
- Try loading only the smallest model first

### Build Errors with LEAP SDK
- Verify Swift version is 5.9+
- Ensure iOS deployment target is 18.0+
- Clean build folder (⇧⌘K) and rebuild

### Notifications Not Working
- Verify push notification capability is added
- Check notification permissions in Settings
- Test on physical device (not simulator)

---

## Next Steps

After setup is complete:

1. **Implement Core Models** - Start with `Task.swift` and `Goal.swift`
2. **Build Design System** - Create the `PulsingButton` component
3. **Create Dashboard** - Main hub with active task display
4. **Add First Agent** - Task Breakdown Agent

See [MASTER_PLAN.md](../MASTER_PLAN.md) for the full implementation roadmap.
