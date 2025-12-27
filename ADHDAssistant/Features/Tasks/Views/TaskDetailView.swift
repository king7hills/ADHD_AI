//
//  TaskDetailView.swift
//  ADHDAssistant
//
//  Detailed view for viewing and editing a task
//

import SwiftUI

struct TaskDetailView: View {
    @StateObject private var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: TaskDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                if viewModel.isEditMode {
                    editModeContent
                } else {
                    viewModeContent
                }
            }
            .padding(AppSpacing.screenHorizontalPadding)
            .padding(.bottom, 100) // Space for bottom button
        }
        .background(AppColors.background)
        .navigationTitle(viewModel.isEditMode ? "Edit Task" : "Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isEditMode {
                    Button("Save") {
                        Task {
                            let success = await viewModel.saveChanges()
                            if success {
                                HapticManager.shared.success()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                } else {
                    Button("Edit") {
                        viewModel.enterEditMode()
                    }
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isEditMode {
                    Button("Cancel") {
                        viewModel.cancelEdit()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionButton
        }
        .alert("Delete Task", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTask()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }

    // MARK: - View Mode Content

    private var viewModeContent: some View {
        VStack(spacing: AppSpacing.lg) {
            // Title
            Text(viewModel.task.title)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Metadata Card
            metadataCard

            // Description
            if let description = viewModel.task.description, !description.isEmpty {
                descriptionSection(description)
            }

            // Scheduled Time
            if let scheduledTime = viewModel.task.scheduledTime {
                scheduledTimeSection(scheduledTime)
            }

            // Priority
            prioritySection(isEditMode: false)

            // Duration
            durationSection(isEditMode: false)

            // Subtasks
            if !viewModel.task.subtasks.isEmpty {
                subtasksSection(isEditMode: false)
            }

            // Recurrence
            if let recurrence = viewModel.task.recurrence {
                recurrenceSection(recurrence)
            }

            // Tags
            if !viewModel.task.tags.isEmpty {
                tagsSection(isEditMode: false)
            }

            // Start Trigger
            if let trigger = viewModel.task.startTrigger, !trigger.isEmpty {
                startTriggerSection(trigger)
            }

            // Parent Goal Link (placeholder for now)
            if viewModel.task.parentGoalId != nil {
                parentGoalSection
            }

            // Delete Button
            Button(role: .destructive) {
                viewModel.showDeleteConfirmation = true
            } label: {
                Text("Delete Task")
                    .font(AppTypography.buttonText)
                    .foregroundColor(AppColors.error)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.error.opacity(0.1))
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
        }
    }

    // MARK: - Edit Mode Content

    private var editModeContent: some View {
        VStack(spacing: AppSpacing.lg) {
            // Title Editor
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Title")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                TextField("Task title", text: $viewModel.editedTitle)
                    .font(AppTypography.body)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
            }

            // Description Editor
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Description")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                TextEditor(text: $viewModel.editedDescription)
                    .font(AppTypography.body)
                    .frame(minHeight: 100)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
            }

            // Duration Picker
            durationSection(isEditMode: true)

            // Scheduled Time Picker
            scheduledTimeEditor

            // Priority Picker
            prioritySection(isEditMode: true)

            // Subtasks
            subtasksSection(isEditMode: true)

            // Recurrence
            recurrenceEditor

            // Tags
            tagsSection(isEditMode: true)

            // Start Trigger
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Start Trigger (Optional)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                TextField("e.g., After breakfast", text: $viewModel.editedStartTrigger)
                    .font(AppTypography.body)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
        }
    }

    // MARK: - Metadata Card

    private var metadataCard: some View {
        HStack(spacing: AppSpacing.lg) {
            // Status
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Status")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(viewModel.task.status.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
            }

            Divider()

            // Points
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Points")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text("\(viewModel.task.totalPoints)")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.accent)
            }

            if !viewModel.task.subtasks.isEmpty {
                Divider()

                // Progress
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Progress")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text(viewModel.subtaskProgress)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
        .cardShadow()
    }

    // MARK: - Section Views

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Description")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(description)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }

    private func scheduledTimeSection(_ time: Date) -> some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(AppColors.primary)
            Text("Scheduled:")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(time, style: .date)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            Text(time, style: .time)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }

    private var scheduledTimeEditor: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Toggle(isOn: Binding(
                get: { viewModel.hasScheduledTime },
                set: { if !$0 { viewModel.editedScheduledTime = nil } }
            )) {
                Text("Schedule Task")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .tint(AppColors.primary)

            if viewModel.hasScheduledTime {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { viewModel.editedScheduledTime ?? Date() },
                        set: { viewModel.editedScheduledTime = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
        }
    }

    private func prioritySection(isEditMode: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Priority")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            if isEditMode {
                Picker("Priority", selection: $viewModel.editedPriority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                HStack {
                    Circle()
                        .fill(priorityColor(viewModel.task.priority))
                        .frame(width: 12, height: 12)
                    Text(viewModel.task.priority.displayName)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.card)
                .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
        }
    }

    private func durationSection(isEditMode: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Estimated Duration")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            if isEditMode {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.durationPresets, id: \.duration) { preset in
                            Button {
                                viewModel.setDurationPreset(preset.duration)
                            } label: {
                                Text(preset.label)
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(viewModel.editedEstimatedDuration == preset.duration ? .white : AppColors.textPrimary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(viewModel.editedEstimatedDuration == preset.duration ? AppColors.primary : AppColors.surface)
                                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppColors.primary)
                    Text(viewModel.formattedDuration)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.card)
                .cornerRadius(AppSpacing.cornerRadiusMedium)
            }
        }
    }

    private func subtasksSection(isEditMode: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Subtasks (\(viewModel.subtaskProgress))")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                ForEach($viewModel.editedSubtasks) { $subtask in
                    if isEditMode {
                        SubtaskRow(
                            subtask: $subtask,
                            onDelete: {
                                if let index = viewModel.editedSubtasks.firstIndex(where: { $0.id == subtask.id }) {
                                    viewModel.deleteSubtask(at: IndexSet(integer: index))
                                }
                            },
                            onToggle: {
                                viewModel.toggleSubtask(subtask)
                            }
                        )
                    } else {
                        SimpleSubtaskRow(
                            subtask: $subtask,
                            onToggle: {
                                viewModel.toggleSubtask(subtask)
                            }
                        )
                    }
                }

                // Add subtask field
                if isEditMode {
                    HStack {
                        TextField("Add subtask", text: $viewModel.newSubtaskTitle)
                            .font(AppTypography.body)
                            .onSubmit {
                                viewModel.addSubtask(viewModel.newSubtaskTitle)
                            }

                        Button {
                            viewModel.addSubtask(viewModel.newSubtaskTitle)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppColors.primary)
                                .font(.system(size: AppSpacing.iconSizeLarge))
                        }
                        .disabled(viewModel.newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cornerRadiusSmall)
                }
            }
        }
    }

    private func recurrenceSection(_ recurrence: RecurrenceRule) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Recurrence")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(AppColors.primary)
                Text(recurrence.frequency.displayName)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card)
            .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
    }

    private var recurrenceEditor: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Toggle(isOn: Binding(
                get: { viewModel.hasRecurrence },
                set: { if !$0 { viewModel.editedRecurrence = nil } }
            )) {
                Text("Recurring Task")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .tint(AppColors.primary)

            if viewModel.hasRecurrence {
                Text("Recurrence settings")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private func tagsSection(isEditMode: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Tags")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(viewModel.editedTags, id: \.self) { tag in
                    TagChip(tag: tag, isEditable: isEditMode) {
                        viewModel.removeTag(tag)
                    }
                }
            }
        }
    }

    private func startTriggerSection(_ trigger: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Start Trigger")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(AppColors.accent)
                Text(trigger)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card)
            .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
    }

    private var parentGoalSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Linked Goal")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack {
                Image(systemName: "target")
                    .foregroundColor(AppColors.secondary)
                Text("View Goal")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
    }

    // MARK: - Bottom Action Button

    private var bottomActionButton: some View {
        Group {
            if !viewModel.isEditMode {
                Button {
                    if viewModel.isCompleted {
                        viewModel.uncompleteTask()
                    } else {
                        viewModel.completeTask()
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill")
                        Text(viewModel.isCompleted ? "Mark Incomplete" : "Done?")
                    }
                    .font(AppTypography.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isCompleted ? AppColors.textSecondary : AppColors.success)
                    .cornerRadius(AppSpacing.cornerRadiusMedium)
                }
                .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.background)
            }
        }
    }

    // MARK: - Helper Functions

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .critical: return AppColors.error
        case .high: return AppColors.warning
        case .medium: return AppColors.info
        case .low: return AppColors.textTertiary
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: String
    let isEditable: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(tag)
                .font(AppTypography.caption)

            if isEditable {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical: AppSpacing.xs)
        .background(AppColors.primary.opacity(0.1))
        .foregroundColor(AppColors.primary)
        .cornerRadius(AppSpacing.cornerRadiusSmall)
    }
}

// MARK: - Flow Layout

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

#Preview("Task Detail") {
    NavigationStack {
        TaskDetailView(viewModel: TaskDetailViewModel(task: Task.sample))
    }
}

#Preview("Task Detail - Completed") {
    NavigationStack {
        TaskDetailView(viewModel: TaskDetailViewModel(
            task: Task(
                title: "Completed task",
                description: "This task has been completed",
                estimatedDuration: 900,
                status: .completed,
                priority: .high
            )
        ))
    }
}
