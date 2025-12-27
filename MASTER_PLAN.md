# ADHD Executive Function Assistant - Master Plan

## Project Vision

An on-device AI-powered executive function assistant designed specifically for individuals with ADHD. The app leverages Liquid AI's LFM2 models running locally on the device to provide real-time task management, behavioral intervention, and gamified positive reinforcement—applying the same dopamine-driven engagement patterns used by social media, but redirected toward life-improving outcomes.

### Primary Users
- **Girlfriend**: General ADHD support for time management and task completion
- **Mom**: Type 2 diabetes management with medication reminders, blood sugar checks, meal timing, and exercise scheduling

---

## Technology Stack

### On-Device AI: Liquid AI LFM2 Models

Based on research, we will utilize the **LEAP SDK** with LFM2 models optimized for mobile:

| Model | Parameters | Use Case |
|-------|-----------|----------|
| **LFM2-350M** | 350M | Quick responses, notifications, simple task parsing |
| **LFM2-700M** | 700M | Task breakdown, time estimation, context understanding |
| **LFM2-1.2B** | 1.2B | Complex planning, multi-turn conversations, behavior analysis |

**Key Advantages:**
- 2x faster decode/prefill vs Qwen3 on CPU
- Hybrid architecture with Linear Input-Varying (LIV) operators
- Runs offline—no network required
- Optimized for agentic tasks, data extraction, and multi-turn conversations
- Apache 2.0 license (free for companies under $10M revenue)

**SDK Integration:**
```swift
// LEAP SDK for iOS
dependencies: [
    .package(url: "https://github.com/Liquid4All/leap-ios.git", from: "0.7.7")
]
```

### Platform Requirements
- **iOS**: 18.0+ (required by LEAP SDK)
- **Device**: iPhone with 3GB+ RAM
- **Future**: Kotlin/Android via LEAP Android SDK

---

## Architecture Overview

### MVVM + Clean Architecture with Modular Design

```
ADHDAssistant/
├── App/
│   ├── ADHDAssistantApp.swift          # App entry point
│   ├── AppDelegate.swift                # Push notifications, background tasks
│   └── Configuration/
│       └── AppConfiguration.swift       # Environment configs
│
├── Core/                                 # Shared core module
│   ├── Models/
│   │   ├── Task.swift                   # Task domain model
│   │   ├── Goal.swift                   # Goal domain model
│   │   ├── UserProfile.swift            # User settings & preferences
│   │   ├── Achievement.swift            # Gamification achievements
│   │   └── HealthMetric.swift           # Diabetes/health tracking
│   │
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── View+Extensions.swift
│   │
│   ├── Utilities/
│   │   ├── TimeEstimator.swift          # ML-enhanced time estimation
│   │   └── HapticManager.swift          # Tactile feedback
│   │
│   └── Constants/
│       └── AppConstants.swift
│
├── Services/                             # Business logic layer
│   ├── AI/
│   │   ├── LFMService.swift             # LEAP SDK wrapper
│   │   ├── ModelManager.swift           # Model loading/switching
│   │   └── PromptTemplates.swift        # System prompts for agents
│   │
│   ├── Agents/                          # AI Agent System
│   │   ├── AgentCoordinator.swift       # Orchestrates all agents
│   │   ├── TaskBreakdownAgent.swift     # Breaks goals into steps
│   │   ├── CalendarAgent.swift          # Calendar management
│   │   ├── BehaviorMonitorAgent.swift   # Detects doomscrolling
│   │   ├── HealthAgent.swift            # Diabetes/health reminders
│   │   └── MotivationAgent.swift        # Encouragement & nudges
│   │
│   ├── Notifications/
│   │   ├── NotificationService.swift    # Push notification handling
│   │   ├── LiveActivityService.swift    # iOS Live Activities
│   │   └── NotificationScheduler.swift  # Smart timing
│   │
│   ├── Calendar/
│   │   ├── CalendarService.swift        # EventKit integration
│   │   └── CalendarSync.swift           # External calendar sync
│   │
│   ├── Persistence/
│   │   ├── TaskRepository.swift         # Task CRUD operations
│   │   ├── GoalRepository.swift         # Goal management
│   │   ├── MemoryStore.swift            # AI context memory
│   │   └── CoreDataStack.swift          # Core Data setup
│   │
│   ├── ScreenTime/
│   │   ├── ScreenTimeService.swift      # Screen Time API
│   │   └── AppUsageMonitor.swift        # Track app usage
│   │
│   └── Gamification/
│       ├── PointsService.swift          # Points tracking
│       ├── AchievementService.swift     # Unlock achievements
│       ├── StreakService.swift          # Daily streaks
│       └── CelebrationService.swift     # Animation triggers
│
├── Features/                             # Feature modules (Views + ViewModels)
│   │
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   ├── OnboardingView.swift
│   │   │   ├── GoalSetupView.swift
│   │   │   └── ProfileSetupView.swift
│   │   └── ViewModels/
│   │       └── OnboardingViewModel.swift
│   │
│   ├── Dashboard/
│   │   ├── Views/
│   │   │   ├── DashboardView.swift       # Main hub
│   │   │   ├── ActiveTaskCard.swift      # Current task display
│   │   │   ├── DoneButton.swift          # Pulsing completion button
│   │   │   └── StreakWidget.swift        # Streak display
│   │   └── ViewModels/
│   │       └── DashboardViewModel.swift
│   │
│   ├── Tasks/
│   │   ├── Views/
│   │   │   ├── TaskListView.swift
│   │   │   ├── TaskDetailView.swift
│   │   │   ├── TaskCreationSheet.swift
│   │   │   └── SubtaskRow.swift
│   │   └── ViewModels/
│   │       ├── TaskListViewModel.swift
│   │       └── TaskDetailViewModel.swift
│   │
│   ├── Goals/
│   │   ├── Views/
│   │   │   ├── GoalsView.swift
│   │   │   ├── GoalDetailView.swift
│   │   │   └── GoalProgressCard.swift
│   │   └── ViewModels/
│   │       └── GoalsViewModel.swift
│   │
│   ├── Chat/
│   │   ├── Views/
│   │   │   ├── ChatView.swift            # AI conversation
│   │   │   ├── ChatBubble.swift
│   │   │   └── SuggestionChips.swift
│   │   └── ViewModels/
│   │       └── ChatViewModel.swift
│   │
│   ├── Health/                           # Diabetes management
│   │   ├── Views/
│   │   │   ├── HealthDashboardView.swift
│   │   │   ├── BloodSugarLogView.swift
│   │   │   ├── MealReminderCard.swift
│   │   │   └── ExerciseTrackerView.swift
│   │   └── ViewModels/
│   │       └── HealthViewModel.swift
│   │
│   ├── Calendar/
│   │   ├── Views/
│   │   │   ├── CalendarView.swift
│   │   │   └── EventDetailView.swift
│   │   └── ViewModels/
│   │       └── CalendarViewModel.swift
│   │
│   ├── Achievements/
│   │   ├── Views/
│   │   │   ├── AchievementsView.swift
│   │   │   ├── AchievementCard.swift
│   │   │   └── CelebrationOverlay.swift
│   │   └── ViewModels/
│   │       └── AchievementsViewModel.swift
│   │
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   ├── NotificationPrefsView.swift
│       │   └── HealthSettingsView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
├── DesignSystem/                         # Reusable UI components
│   ├── Components/
│   │   ├── PulsingButton.swift           # The "Done?" button
│   │   ├── ProgressRing.swift
│   │   ├── ConfettiView.swift
│   │   ├── TimerDisplay.swift
│   │   └── GlowingCard.swift
│   │
│   ├── Animations/
│   │   ├── CelebrationAnimations.swift
│   │   ├── PulseAnimation.swift
│   │   └── ConfettiAnimation.swift
│   │
│   └── Theme/
│       ├── Colors.swift
│       ├── Typography.swift
│       └── Spacing.swift
│
├── Widgets/                              # iOS Widgets
│   ├── CurrentTaskWidget.swift
│   ├── StreakWidget.swift
│   └── HealthReminderWidget.swift
│
├── LiveActivity/                         # Dynamic Island & Lock Screen
│   ├── TaskLiveActivity.swift
│   └── HealthLiveActivity.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    └── Models/                           # LFM2 model bundles
        ├── lfm2-350m.bundle
        └── lfm2-700m.bundle
```

---

## Agent System Design

### Multi-Agent Architecture

The app employs specialized AI agents, each with focused responsibilities, coordinated by a central orchestrator.

```
┌─────────────────────────────────────────────────────────────┐
│                    Agent Coordinator                         │
│  - Routes requests to appropriate agents                    │
│  - Maintains shared context/memory                          │
│  - Handles agent-to-agent communication                     │
└─────────────────────────────────────────────────────────────┘
           │           │           │           │
    ┌──────┴───┐ ┌─────┴────┐ ┌────┴────┐ ┌────┴─────┐
    │ Task     │ │ Calendar │ │ Behavior│ │ Health   │
    │ Breakdown│ │ Agent    │ │ Monitor │ │ Agent    │
    │ Agent    │ │          │ │ Agent   │ │          │
    └──────────┘ └──────────┘ └─────────┘ └──────────┘
```

### Agent Specifications

#### 1. Task Breakdown Agent
**Model**: LFM2-700M or LFM2-1.2B
**Purpose**: Convert high-level goals into actionable micro-tasks

**Input Example**:
```json
{
  "goal": "Be healthier",
  "context": {
    "user_has_diabetes": true,
    "available_time": "30 min mornings",
    "current_fitness_level": "sedentary"
  }
}
```

**Output Example**:
```json
{
  "breakdown": [
    {
      "task": "Morning 5-min stretch",
      "estimated_duration": 5,
      "frequency": "daily",
      "best_time": "7:00 AM",
      "difficulty": "easy"
    },
    {
      "task": "Take morning medication",
      "estimated_duration": 2,
      "frequency": "daily",
      "best_time": "7:30 AM",
      "critical": true
    }
  ]
}
```

#### 2. Calendar Agent
**Model**: LFM2-350M
**Purpose**: Manage scheduling, conflicts, and time blocks

**Capabilities**:
- Integrate with iOS Calendar (EventKit)
- Detect scheduling conflicts
- Suggest optimal task timing based on energy patterns
- Auto-schedule broken-down tasks
- Buffer time between tasks (ADHD-friendly)

#### 3. Behavior Monitor Agent
**Model**: LFM2-350M
**Purpose**: Detect counterproductive behaviors and intervene

**Monitoring**:
- Screen Time API for app usage
- Time spent on social media apps
- Patterns of task avoidance
- Time since last completed task

**Interventions**:
- Gentle notification: "Hey, you've been on Instagram for 20 minutes. Ready to knock out that 5-minute task?"
- Live Activity persistence showing current task
- Suggest "just one small thing" to rebuild momentum

#### 4. Health Agent (Diabetes Focus)
**Model**: LFM2-700M
**Purpose**: Health management specific to Type 2 diabetes

**Features**:
- Blood sugar check reminders (customizable intervals)
- Meal timing alerts
- Medication reminders with confirmation
- Exercise prompts
- Pattern recognition for blood sugar trends
- Emergency contact integration for critical levels

#### 5. Motivation Agent
**Model**: LFM2-350M
**Purpose**: Provide encouragement and dopamine hits

**Capabilities**:
- Celebrate completed tasks with varied responses
- Recognize streaks and milestones
- Provide ADHD-aware encouragement (no toxic positivity)
- Adapt tone based on user preference
- Time-appropriate messages (energetic morning, calm evening)

---

## State Management

### Task State Machine

```
                    ┌──────────────┐
                    │   Created    │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
              ┌─────│   Scheduled  │─────┐
              │     └──────┬───────┘     │
              │            │             │
       ┌──────▼─────┐ ┌────▼────┐ ┌──────▼──────┐
       │  Snoozed   │ │ Active  │ │   Skipped   │
       └──────┬─────┘ └────┬────┘ └─────────────┘
              │            │
              └────────────┼────────────┐
                           │            │
                    ┌──────▼───────┐ ┌──▼───────────┐
                    │  Completed   │ │ Partially    │
                    │              │ │ Completed    │
                    └──────────────┘ └──────────────┘
```

### Context & Memory System

```swift
struct AIContext {
    // Short-term (current session)
    var currentTask: Task?
    var recentConversation: [Message]
    var sessionStartTime: Date

    // Medium-term (rolling window)
    var completedTasksToday: [Task]
    var missedTasksToday: [Task]
    var currentStreak: Int
    var todaysMood: MoodLevel?

    // Long-term (persistent)
    var userProfile: UserProfile
    var taskCompletionPatterns: [TimeOfDay: CompletionRate]
    var averageEstimationAccuracy: Double
    var preferredInterventionStyle: InterventionStyle
    var healthMetrics: [HealthMetric]
}
```

---

## Gamification System

### Points Economy

| Action | Points |
|--------|--------|
| Complete micro-task | 10 |
| Complete full task | 25 |
| Complete on-time | +10 bonus |
| Log health metric | 15 |
| Maintain daily streak | 50 × streak_day |
| Beat time estimate | 20 |
| First task of day | 25 |

### Achievement System

**Tier 1 (Bronze)** - Unlocks basic celebrations
- "First Step": Complete your first task
- "On a Roll": 3-day streak
- "Early Bird": Complete a task before 9 AM

**Tier 2 (Silver)** - Unlocks enhanced animations
- "Week Warrior": 7-day streak
- "Time Lord": Beat estimates 5 times
- "Health Hero": Log health metrics 7 days straight

**Tier 3 (Gold)** - Unlocks premium celebrations
- "Unstoppable": 30-day streak
- "Master Estimator": 80% estimation accuracy over 20 tasks
- "Life Changer": Complete 100 total tasks

### Celebration Animations (Unlockable)

```swift
enum CelebrationStyle: String, CaseIterable {
    // Tier 1 (Default)
    case confetti
    case checkmarkBurst
    case starShimmer

    // Tier 2 (Unlockable)
    case fireworks
    case rainbowWave
    case partyPopper

    // Tier 3 (Premium)
    case epicConfetti
    case victoryDance
    case goldenShower
}
```

### The "Done?" Button

The signature UI element—a pulsing, attention-grabbing button that rewards completion:

```swift
struct DoneButton: View {
    @State private var isPulsing = true
    @Binding var isCompleted: Bool
    let onComplete: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isCompleted = true
            }
            onComplete()
        }) {
            Text(isCompleted ? "Done!" : "Done?")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(isCompleted ? Color.green : Color.blue)
                        .shadow(color: .blue.opacity(0.5), radius: isPulsing ? 20 : 10)
                )
                .scaleEffect(isPulsing ? 1.05 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                isPulsing.toggle()
            }
        }
    }
}
```

---

## Notification Strategy

### Notification Hierarchy

1. **Critical** (Always break through)
   - Medication reminders
   - Blood sugar check alerts
   - Emergency health alerts

2. **High Priority** (Live Activity persistence)
   - Active task reminders
   - Upcoming scheduled tasks
   - Behavior interventions

3. **Standard** (Respects Focus modes)
   - Streak maintenance
   - Achievement unlocks
   - Daily summaries

### Live Activities

Persistent lock screen presence for current tasks:

```swift
struct TaskActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var taskName: String
        var estimatedMinutes: Int
        var elapsedMinutes: Int
        var isOvertime: Bool
    }

    var taskId: UUID
    var category: String
}
```

---

## Data Models

### Core Entities

```swift
// Task.swift
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var parentGoalId: UUID?
    var estimatedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var scheduledTime: Date?
    var completedAt: Date?
    var status: TaskStatus
    var priority: Priority
    var subtasks: [Subtask]
    var recurrence: RecurrenceRule?
    var tags: [String]
    var aiGenerated: Bool
    var pointsValue: Int
}

// Goal.swift
struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var category: GoalCategory
    var targetDate: Date?
    var tasks: [Task]
    var progress: Double
    var createdAt: Date
    var isActive: Bool
}

// HealthMetric.swift (for diabetes management)
struct HealthMetric: Identifiable, Codable {
    let id: UUID
    var type: HealthMetricType
    var value: Double
    var unit: String
    var recordedAt: Date
    var notes: String?

    enum HealthMetricType: String, Codable {
        case bloodSugar
        case medication
        case meal
        case exercise
        case weight
    }
}

// Achievement.swift
struct Achievement: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var iconName: String
    var tier: AchievementTier
    var unlockedAt: Date?
    var progress: Double
    var requirement: Int
    var rewardCelebration: CelebrationStyle?
}
```

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Project setup with Swift Package Manager
- [ ] Core data models and persistence layer
- [ ] LEAP SDK integration and model loading
- [ ] Basic MVVM architecture scaffolding
- [ ] Design system components

### Phase 2: Core Features (Weeks 3-4)
- [ ] Dashboard view with active task display
- [ ] Task creation and management
- [ ] Basic AI chat interface
- [ ] Task Breakdown Agent implementation
- [ ] "Done?" button with basic animation

### Phase 3: Agents & Intelligence (Weeks 5-6)
- [ ] Calendar Agent with EventKit integration
- [ ] Behavior Monitor Agent with Screen Time API
- [ ] Context and memory system
- [ ] Time estimation learning

### Phase 4: Health Features (Week 7)
- [ ] Health dashboard for diabetes management
- [ ] Blood sugar logging
- [ ] Medication reminders
- [ ] Health Agent implementation

### Phase 5: Gamification (Week 8)
- [ ] Points system implementation
- [ ] Achievement tracking
- [ ] Celebration animations
- [ ] Streak management

### Phase 6: Notifications & Persistence (Week 9)
- [ ] Push notification system
- [ ] Live Activities implementation
- [ ] Widgets for home screen
- [ ] Background task scheduling

### Phase 7: Polish & Testing (Weeks 10-11)
- [ ] UI/UX refinement
- [ ] Performance optimization
- [ ] Accessibility features
- [ ] Beta testing with target users

### Phase 8: Android Port (Weeks 12+)
- [ ] Kotlin project setup
- [ ] LEAP Android SDK integration
- [ ] Feature parity implementation

---

## Technical Considerations

### Privacy & Security
- All AI processing happens on-device
- Health data stored locally with encryption
- No user data sent to external servers
- Optional iCloud sync (encrypted)
- Biometric authentication for sensitive data

### Performance
- Lazy model loading based on need
- Background model warm-up
- Efficient token streaming for responsive UI
- Battery-conscious scheduling of AI tasks

### Accessibility
- VoiceOver support throughout
- Dynamic Type support
- High contrast mode
- Reduced motion alternatives for animations

### Testing Strategy
- Unit tests for all ViewModels
- Integration tests for agent system
- UI tests for critical user flows
- Performance tests for AI inference

---

## File Naming Conventions

- **Views**: `{Feature}View.swift` (e.g., `DashboardView.swift`)
- **ViewModels**: `{Feature}ViewModel.swift`
- **Models**: `{Entity}.swift`
- **Services**: `{Domain}Service.swift`
- **Agents**: `{Purpose}Agent.swift`
- **Extensions**: `{Type}+Extensions.swift`

---

## Dependencies

```swift
// Package.swift dependencies
dependencies: [
    // AI
    .package(url: "https://github.com/Liquid4All/leap-ios.git", from: "0.7.7"),

    // Persistence
    // Core Data (built-in)

    // UI
    // SwiftUI (built-in)

    // Testing
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
]
```

---

## Success Metrics

### User Engagement
- Daily active usage
- Task completion rate
- Average session duration
- Streak maintenance rate

### Health Outcomes (Mom)
- Blood sugar logging consistency
- Medication adherence
- Exercise frequency

### ADHD Management
- Tasks completed vs. created ratio
- Time estimation accuracy improvement
- Reduction in app switch frequency
- Doomscrolling intervention success rate

---

## Resources

### Liquid AI Documentation
- [LEAP iOS SDK](https://github.com/Liquid4All/leap-ios)
- [LFM2 Models](https://www.liquid.ai/models)
- [Cookbook Examples](https://github.com/Liquid4All/cookbook)

### Apple Frameworks
- [EventKit](https://developer.apple.com/documentation/eventkit)
- [Screen Time API](https://developer.apple.com/documentation/screentime)
- [ActivityKit (Live Activities)](https://developer.apple.com/documentation/activitykit)
- [UserNotifications](https://developer.apple.com/documentation/usernotifications)

---

## Next Steps

1. **Set up Xcode project** with the defined folder structure
2. **Integrate LEAP SDK** and verify model loading
3. **Build Core module** with data models
4. **Create Design System** with PulsingButton component
5. **Implement Dashboard** as the first feature module

---

*This master plan serves as the living blueprint for the ADHD Executive Function Assistant. Each section can be assigned to different agents or development phases.*
