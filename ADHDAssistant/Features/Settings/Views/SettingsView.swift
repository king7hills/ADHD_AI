//
//  SettingsView.swift
//  ADHDAssistant
//
//  Created on 2025-12-27.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingEditProfile = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                profileSection

                // Notifications Section
                notificationsSection

                // Health Section
                if AppConfiguration.FeatureFlags.diabetesSupport {
                    healthSection
                }

                // Intervention Style Section
                interventionStyleSection

                // Appearance Section
                appearanceSection

                // Data Management Section
                dataManagementSection

                // About Section
                aboutSection

                // Debug Section (Development only)
                #if DEBUG
                if AppConfiguration.Debug.verboseLogging {
                    debugSection
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .confirmationDialog(
                "Clear All Data",
                isPresented: $viewModel.showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All Data", role: .destructive) {
                    Task {
                        await viewModel.clearAllData()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your tasks, goals, health data, and achievements. This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            HStack(spacing: AppSpacing.md) {
                // Avatar
                Circle()
                    .fill(AppColors.primary.gradient)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(viewModel.userProfile?.name?.prefix(1).uppercased() ?? "?")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userProfile?.name ?? "User")
                        .font(.headline)

                    if viewModel.userProfile?.hasDiabetes == true {
                        Label("Diabetes tracking enabled", systemImage: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    showingEditProfile = true
                } label: {
                    Text("Edit")
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        } header: {
            Text("Profile")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $viewModel.notificationsEnabled) {
                Label("Push Notifications", systemImage: "bell.fill")
            }
            .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                if newValue {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }
            }

            if viewModel.notificationsEnabled {
                Picker("Default Reminder", selection: $viewModel.defaultReminderMinutes) {
                    Text("15 minutes before").tag(15)
                    Text("30 minutes before").tag(30)
                    Text("1 hour before").tag(60)
                    Text("2 hours before").tag(120)
                }
                .onChange(of: viewModel.defaultReminderMinutes) { _, _ in
                    viewModel.updateNotificationSettings()
                }

                Toggle(isOn: $viewModel.quietHoursEnabled) {
                    Label("Quiet Hours", systemImage: "moon.fill")
                }
                .onChange(of: viewModel.quietHoursEnabled) { _, _ in
                    viewModel.updateNotificationSettings()
                }

                if viewModel.quietHoursEnabled {
                    DatePicker(
                        "Start",
                        selection: $viewModel.quietHoursStart,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: viewModel.quietHoursStart) { _, _ in
                        viewModel.updateNotificationSettings()
                    }

                    DatePicker(
                        "End",
                        selection: $viewModel.quietHoursEnd,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: viewModel.quietHoursEnd) { _, _ in
                        viewModel.updateNotificationSettings()
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if viewModel.quietHoursEnabled {
                Text("Notifications will be silenced during quiet hours")
            }
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        Section {
            Toggle(isOn: $viewModel.healthTrackingEnabled) {
                Label("Health Tracking", systemImage: "heart.fill")
            }
            .onChange(of: viewModel.healthTrackingEnabled) { _, _ in
                viewModel.updateHealthSettings()
            }

            if viewModel.healthTrackingEnabled {
                NavigationLink {
                    HealthSettingsDetailView()
                } label: {
                    Label("Health Preferences", systemImage: "slider.horizontal.3")
                }

                NavigationLink {
                    HealthDataView()
                } label: {
                    Label("View Health Data", systemImage: "chart.line.uptrend.xyaxis")
                }
            }
        } header: {
            Text("Health & Diabetes Management")
        } footer: {
            if viewModel.healthTrackingEnabled {
                Text("Track blood glucose, medications, and receive smart reminders for diabetes management")
            }
        }
    }

    // MARK: - Intervention Style Section

    private var interventionStyleSection: some View {
        Section {
            Picker("Intervention Style", selection: $viewModel.interventionStyle) {
                ForEach(InterventionStyle.allCases, id: \.self) { style in
                    VStack(alignment: .leading) {
                        Text(style.displayName)
                        Text(style.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(style)
                }
            }
            .pickerStyle(.navigationLink)
            .onChange(of: viewModel.interventionStyle) { _, newValue in
                viewModel.updateInterventionStyle(newValue)
            }
        } header: {
            Text("AI Assistant Behavior")
        } footer: {
            Text("Customize how the AI assistant communicates with you")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $viewModel.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.appearanceMode) { _, newValue in
                viewModel.updateAppearanceMode(newValue)
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        Section {
            Button {
                Task {
                    if let url = await viewModel.exportData() {
                        exportURL = url
                        showingShareSheet = true
                    }
                }
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                viewModel.showingResetConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
        } header: {
            Text("Data Management")
        } footer: {
            Text("Export your data as JSON or clear all stored information")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.fullVersion)
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://adhdassistant.app/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://adhdassistant.app/terms")!) {
                HStack {
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://adhdassistant.app/support")!) {
                HStack {
                    Text("Support")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    private var debugSection: some View {
        Section {
            Button {
                viewModel.resetOnboarding()
            } label: {
                Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
            }

            NavigationLink {
                DebugView()
            } label: {
                Label("Debug Info", systemImage: "ladybug")
            }
        } header: {
            Text("Debug")
        }
    }
    #endif
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var hasDiabetes: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                } header: {
                    Text("Personal Information")
                }

                Section {
                    Toggle("I have diabetes", isOn: $hasDiabetes)
                } header: {
                    Text("Health Conditions")
                } footer: {
                    Text("Enable diabetes-specific features and tracking")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updateProfile(name: name, hasDiabetes: hasDiabetes)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = viewModel.userProfile?.name ?? ""
                hasDiabetes = viewModel.userProfile?.hasDiabetes ?? false
            }
        }
    }
}

// MARK: - Placeholder Views

struct HealthSettingsDetailView: View {
    var body: some View {
        List {
            Section {
                Text("Blood Glucose Targets")
                Text("Medication Reminders")
                Text("Alert Thresholds")
            }
        }
        .navigationTitle("Health Preferences")
    }
}

struct HealthDataView: View {
    var body: some View {
        List {
            Section {
                Text("Recent Measurements")
                Text("Trends")
                Text("Insights")
            }
        }
        .navigationTitle("Health Data")
    }
}

struct DebugView: View {
    var body: some View {
        List {
            Section("App Info") {
                Text("Bundle ID: \(AppConfiguration.Info.bundleIdentifier)")
                Text("Environment: \(AppConfiguration.environment.rawValue)")
            }

            Section("Feature Flags") {
                Toggle("Diabetes Support", isOn: .constant(AppConfiguration.FeatureFlags.diabetesSupport))
                Toggle("Celebrations", isOn: .constant(AppConfiguration.FeatureFlags.celebrationsEnabled))
                Toggle("AI Chat", isOn: .constant(AppConfiguration.FeatureFlags.aiChatEnabled))
            }
        }
        .navigationTitle("Debug")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(\.dependencies, DependencyContainer.preview)
}
