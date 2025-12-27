//
//  OnboardingView.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import SwiftUI

struct OnboardingView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: OnboardingViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.primary.opacity(0.1), AppColors.accent.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStep()
                        .tag(0)

                    NameStep(viewModel: viewModel)
                        .tag(1)

                    GoalsStep(viewModel: viewModel)
                        .tag(2)

                    HealthStep(viewModel: viewModel)
                        .tag(3)

                    NotificationsStep(viewModel: viewModel)
                        .tag(4)

                    PreferencesStep(viewModel: viewModel)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

                // Navigation buttons
                navigationButtons
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if viewModel.currentStep > 0 {
                    Button("Skip") {
                        viewModel.skipToEnd()
                    }
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.horizontal)

            ProgressView(value: viewModel.progress)
                .tint(AppColors.primary)
                .padding(.horizontal)
        }
        .padding(.top, AppSpacing.md)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: AppSpacing.md) {
            // Back button
            if viewModel.currentStep > 0 {
                Button {
                    viewModel.previousStep()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }
            }

            // Next/Complete button
            Button {
                viewModel.nextStep()
            } label: {
                HStack {
                    Text(viewModel.currentStep == viewModel.totalSteps - 1 ? "Complete" : "Next")
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canProceed ? AppColors.primary : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            }
            .disabled(!viewModel.canProceed)
        }
        .padding()
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // App icon/logo
            Circle()
                .fill(AppColors.primary.gradient)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }

            VStack(spacing: AppSpacing.md) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("ADHD Assistant")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppColors.primary)

                Text("Your personal AI companion for executive function support")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            Spacer()

            // Features list
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FeatureRow(icon: "brain", title: "AI-Powered Support", description: "On-device AI assistant")
                FeatureRow(icon: "checklist", title: "Task Management", description: "Break down complex tasks")
                FeatureRow(icon: "trophy.fill", title: "Gamification", description: "Build streaks and earn achievements")
                FeatureRow(icon: "heart.fill", title: "Health Tracking", description: "Optional diabetes management")
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .padding()

            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColors.primary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Name Step

struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.md) {
                Text("What should we call you?")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Choose a name for your profile")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            TextField("Enter your name", text: $viewModel.userName)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                .padding(.horizontal)
                .focused($isNameFieldFocused)

            Spacer()
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

// MARK: - Goals Step

struct GoalsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            VStack(spacing: AppSpacing.md) {
                Text("What do you want help with?")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Select one or more areas to focus on")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            ScrollView {
                LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                    ForEach(OnboardingGoal.allCases) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: viewModel.selectedGoals.contains(goal),
                            action: { viewModel.toggleGoal(goal) }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct GoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primary : Color(.systemGray5))
                        .frame(width: 60, height: 60)

                    Image(systemName: goal.icon)
                        .font(.title)
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

                VStack(spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                            .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Health Step

struct HealthStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.md) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.accent)

                Text("Health Tracking")
                    .font(.largeTitle.bold())

                Text("Optional diabetes management features")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            VStack(spacing: AppSpacing.lg) {
                Toggle(isOn: $viewModel.hasDiabetes) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("I have diabetes")
                            .font(.headline)

                        Text("Enable blood glucose tracking and medication reminders")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(AppColors.primary)

                if viewModel.hasDiabetes {
                    Toggle(isOn: $viewModel.enableHealthTracking) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enable health tracking")
                                .font(.headline)

                            Text("Track blood glucose, medications, and get smart reminders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(AppColors.primary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .padding(.horizontal)

            Spacer()
        }
    }
}

// MARK: - Notifications Step

struct NotificationsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.md) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary)

                Text("Stay on Track")
                    .font(.largeTitle.bold())

                Text("Get timely reminders for tasks and health")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                NotificationFeature(
                    icon: "clock.fill",
                    title: "Task Reminders",
                    description: "Never miss a deadline"
                )

                NotificationFeature(
                    icon: "pills.fill",
                    title: "Medication Alerts",
                    description: "Take medications on time"
                )

                NotificationFeature(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Updates",
                    description: "Celebrate your achievements"
                )

                Toggle(isOn: $viewModel.enableNotifications) {
                    Text("Enable notifications")
                        .font(.headline)
                }
                .tint(AppColors.primary)
                .padding(.top)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .padding(.horizontal)

            Text("You can customize notification settings anytime")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()
        }
    }
}

struct NotificationFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColors.primary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preferences Step

struct PreferencesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.md) {
                Text("Customize Your Experience")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Choose how the AI assistant communicates")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            VStack(spacing: AppSpacing.md) {
                ForEach(InterventionStyle.allCases, id: \.self) { style in
                    InterventionStyleCard(
                        style: style,
                        isSelected: viewModel.interventionStyle == style,
                        action: { viewModel.interventionStyle = style }
                    )
                }
            }
            .padding(.horizontal)

            Text("You can change this anytime in Settings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()
        }
    }
}

struct InterventionStyleCard: View {
    let style: InterventionStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primary : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 16, height: 16)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.headline)

                    Text(style.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                            .stroke(isSelected ? AppColors.primary : Color(.systemGray5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Setting up your assistant...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(AppSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .fill(Color(.systemBackground))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(
            dependencies: DependencyContainer.preview,
            onComplete: {}
        )
    )
}
