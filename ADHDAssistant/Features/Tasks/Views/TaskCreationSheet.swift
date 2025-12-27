//
//  TaskCreationSheet.swift
//  ADHDAssistant
//
//  Sheet view for creating new tasks with quick and full modes
//

import SwiftUI

struct TaskCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isFullMode: Bool = false

    // Task fields
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var estimatedDuration: TimeInterval = 900 // Default 15 minutes
    @State private var scheduledTime: Date?
    @State private var hasScheduledTime: Bool = false
    @State private var priority: Priority = .medium
    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskTitle: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var startTrigger: String = ""
    @State private var selectedGoalId: UUID?
    @State private var recurrence: RecurrenceRule?
    @State private var hasRecurrence: Bool = false

    // UI state
    @State private var showGoalPicker: Bool = false
    @State private var showAIAssist: Bool = false

    let onCreate: (Task) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Mode Toggle
                    modeToggle

                    if isFullMode {
                        fullModeContent
                    } else {
                        quickModeContent
                    }
                }
                .padding(AppSpacing.screenHorizontalPadding)
            }
            .background(AppColors.background)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("Mode", selection: $isFullMode) {
            Text("Quick").tag(false)
            Text("Full").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Quick Mode Content

    private var quickModeContent: some View {
        VStack(spacing: AppSpacing.lg) {
            // Title Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("What needs to be done?")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                TextField("e.g., Review morning medications", text: $title)
                    .font(AppTypography.body)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                    .submitLabel(.done)
            }

            // Quick Duration Presets
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("How long will it take?")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(durationPresets, id: \.duration) { preset in
                            DurationPresetButton(
                                label: preset.label,
                                isSelected: estimatedDuration == preset.duration
                            ) {
                                estimatedDuration = preset.duration
                            }
                        }
                    }
                }
            }

            // Quick Schedule Toggle
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Toggle(isOn: $hasScheduledTime) {
                    Text("Schedule for later?")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .tint(AppColors.primary)

                if hasScheduledTime {
                    DatePicker(
                        "Time",
                        selection: Binding(
                            get: { scheduledTime ?? Date() },
                            set: { scheduledTime = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                }
            }

            Spacer()

            // Encouragement
            Text("Great! You're breaking it down into manageable steps.")
                .font(AppTypography.callout)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(AppColors.success.opacity(0.1))
                .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
    }

    // MARK: - Full Mode Content

    private var fullModeContent: some View {
        VStack(spacing: AppSpacing.lg) {
            // Title
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Title")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                TextField("Task title", text: $title)
                    .font(AppTypography.body)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
            }

            // Description
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Description (Optional)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                TextEditor(text: $description)
                    .font(AppTypography.body)
                    .frame(minHeight: 80)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
            }

            // Duration Presets
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Estimated Duration")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(durationPresets, id: \.duration) { preset in
                            DurationPresetButton(
                                label: preset.label,
                                isSelected: estimatedDuration == preset.duration
                            ) {
                                estimatedDuration = preset.duration
                            }
                        }
                    }
                }
            }

            // Priority
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Priority")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Schedule
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Toggle(isOn: $hasScheduledTime) {
                    Text("Schedule Task")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .tint(AppColors.primary)

                if hasScheduledTime {
                    DatePicker(
                        "Time",
                        selection: Binding(
                            get: { scheduledTime ?? Date() },
                            set: { scheduledTime = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                }
            }

            // Subtasks
            subtasksSection

            // AI Assist Button
            aiAssistButton

            // Start Trigger
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Start Trigger (Optional)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                TextField("e.g., After breakfast", text: $startTrigger)
                    .font(AppTypography.body)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
            }

            // Goal Linking
            goalLinkingSection

            // Recurrence
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Toggle(isOn: $hasRecurrence) {
                    Text("Recurring Task")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .tint(AppColors.primary)

                if hasRecurrence {
                    Text("Recurrence settings would go here")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Tags
            tagsSection
        }
    }

    // MARK: - Subtasks Section

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Subtasks (Optional)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            ForEach(subtasks) { subtask in
                HStack {
                    Image(systemName: "circle")
                        .font(.system(size: AppSpacing.iconSizeSmall))
                        .foregroundColor(AppColors.textSecondary)

                    Text(subtask.title)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Button {
                        subtasks.removeAll { $0.id == subtask.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.error)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cornerRadiusSmall)
            }

            // Add subtask field
            HStack {
                TextField("Add subtask", text: $newSubtaskTitle)
                    .font(AppTypography.body)
                    .onSubmit {
                        addSubtask()
                    }

                Button {
                    addSubtask()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: AppSpacing.iconSizeLarge))
                }
                .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cornerRadiusSmall)
        }
    }

    // MARK: - AI Assist Button

    private var aiAssistButton: some View {
        Button {
            showAIAssist = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("AI Assist: Break Down into Subtasks")
                    .font(AppTypography.buttonText)
            }
            .foregroundColor(AppColors.secondary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.secondary.opacity(0.1))
            .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
    }

    // MARK: - Goal Linking Section

    private var goalLinkingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Link to Goal (Optional)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Button {
                showGoalPicker = true
            } label: {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(AppColors.secondary)
                    Text(selectedGoalId == nil ? "Select Goal" : "Goal Selected")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Tags (Optional)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            // Existing tags
            if !tags.isEmpty {
                FlowLayout(spacing: AppSpacing.sm) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: AppSpacing.xs) {
                            Text(tag)
                                .font(AppTypography.caption)

                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.primary.opacity(0.1))
                        .foregroundColor(AppColors.primary)
                        .cornerRadius(AppSpacing.cornerRadiusSmall)
                    }
                }
            }

            // Add tag field
            HStack {
                TextField("Add tag", text: $newTag)
                    .font(AppTypography.body)
                    .onSubmit {
                        addTag()
                    }

                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: AppSpacing.iconSizeLarge))
                }
                .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cornerRadiusSmall)
        }
    }

    // MARK: - Helper Functions

    private func addSubtask() {
        let trimmedTitle = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let newSubtask = Subtask(title: trimmedTitle)
        subtasks.append(newSubtask)
        newSubtaskTitle = ""
    }

    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }

        tags.append(trimmedTag)
        newTag = ""
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && estimatedDuration > 0
    }

    private func createTask() {
        let newTask = Task(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            parentGoalId: selectedGoalId,
            estimatedDuration: estimatedDuration,
            scheduledTime: hasScheduledTime ? scheduledTime : nil,
            status: hasScheduledTime ? .scheduled : .created,
            priority: priority,
            subtasks: subtasks,
            recurrence: hasRecurrence ? recurrence : nil,
            tags: tags,
            startTrigger: startTrigger.isEmpty ? nil : startTrigger.trimmingCharacters(in: .whitespaces)
        )

        onCreate(newTask)
        HapticManager.shared.success()
        dismiss()
    }

    // MARK: - Duration Presets

    private let durationPresets: [(label: String, duration: TimeInterval)] = [
        ("5 min", 300),
        ("10 min", 600),
        ("15 min", 900),
        ("30 min", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200)
    ]
}

// MARK: - Duration Preset Button

private struct DurationPresetButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.subheadline)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.primary : AppColors.surface)
                .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout (reused from TaskDetailView)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows.rows {
            var x = bounds.minX
            for index in row {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            y += spacing
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (rows: [[Int]], height: CGFloat) {
        var rows: [[Int]] = [[]]
        var currentRow = 0
        var currentX: CGFloat = 0
        var totalHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && !rows[currentRow].isEmpty {
                totalHeight += rows[currentRow].map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
                totalHeight += spacing
                currentRow += 1
                rows.append([])
                currentX = 0
            }

            rows[currentRow].append(index)
            currentX += size.width + spacing
        }

        if let lastRowHeight = rows.last?.compactMap({ subviews[$0].sizeThatFits(.unspecified).height }).max() {
            totalHeight += lastRowHeight
        }

        return (rows, totalHeight)
    }
}

// MARK: - Preview Provider

#Preview("Quick Mode") {
    TaskCreationSheet { task in
        print("Created task: \(task.title)")
    }
}

#Preview("Full Mode") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Color.clear
                .sheet(isPresented: $showSheet) {
                    TaskCreationSheet { task in
                        print("Created task: \(task.title)")
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Simulate switching to full mode
                        }
                    }
                }
        }
    }

    return PreviewWrapper()
}
