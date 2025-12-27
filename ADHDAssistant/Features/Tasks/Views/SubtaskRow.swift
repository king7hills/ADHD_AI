//
//  SubtaskRow.swift
//  ADHDAssistant
//
//  Reusable row component for displaying and editing subtasks
//

import SwiftUI

struct SubtaskRow: View {
    @Binding var subtask: Subtask
    let onDelete: () -> Void
    let onToggle: () -> Void

    @State private var isEditing: Bool = false
    @State private var editedTitle: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Drag handle (for reordering)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: AppSpacing.iconSizeSmall))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: AppSpacing.minTouchTarget, height: AppSpacing.minTouchTarget)

            // Checkbox
            Button(action: handleToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppSpacing.iconSizeMedium))
                    .foregroundColor(subtask.isCompleted ? AppColors.success : AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())

            // Editable title
            if isEditing {
                TextField("Subtask title", text: $editedTitle, onCommit: saveEdit)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .focused($isFocused)
            } else {
                Text(subtask.title)
                    .font(AppTypography.body)
                    .foregroundColor(subtask.isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                    .strikethrough(subtask.isCompleted, color: AppColors.textTertiary)
                    .lineLimit(2)
                    .onTapGesture {
                        startEditing()
                    }
            }

            Spacer()

            // Delete button
            Button(action: handleDelete) {
                Image(systemName: "trash")
                    .font(.system(size: AppSpacing.iconSizeSmall))
                    .foregroundColor(AppColors.error)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: AppSpacing.minTouchTarget, height: AppSpacing.minTouchTarget)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cornerRadiusSmall)
    }

    private func handleToggle() {
        HapticManager.shared.impact(.light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onToggle()
        }
    }

    private func handleDelete() {
        HapticManager.shared.impact(.medium)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onDelete()
        }
    }

    private func startEditing() {
        editedTitle = subtask.title
        isEditing = true
        isFocused = true
    }

    private func saveEdit() {
        guard !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            cancelEdit()
            return
        }

        subtask.title = editedTitle.trimmingCharacters(in: .whitespaces)
        isEditing = false
        isFocused = false
    }

    private func cancelEdit() {
        editedTitle = subtask.title
        isEditing = false
        isFocused = false
    }
}

// MARK: - Alternative Simplified Subtask Row

struct SimpleSubtaskRow: View {
    @Binding var subtask: Subtask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: handleToggle) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppSpacing.iconSizeSmall))
                    .foregroundColor(subtask.isCompleted ? AppColors.success : AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())

            Text(subtask.title)
                .font(AppTypography.subheadline)
                .foregroundColor(subtask.isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                .strikethrough(subtask.isCompleted, color: AppColors.textTertiary)
        }
    }

    private func handleToggle() {
        HapticManager.shared.impact(.light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onToggle()
        }
    }
}

// MARK: - Preview Provider

#Preview("Subtask Row") {
    VStack(spacing: AppSpacing.md) {
        SubtaskRow(
            subtask: .constant(Subtask(title: "Take metformin", isCompleted: false)),
            onDelete: {},
            onToggle: {}
        )

        SubtaskRow(
            subtask: .constant(Subtask(title: "Record in health log", isCompleted: true)),
            onDelete: {},
            onToggle: {}
        )

        SubtaskRow(
            subtask: .constant(Subtask(title: "Check blood pressure and log results in app", isCompleted: false)),
            onDelete: {},
            onToggle: {}
        )

        Divider()
            .padding(.vertical, AppSpacing.md)

        Text("Simple Variant")
            .font(AppTypography.headline)
            .foregroundColor(AppColors.textPrimary)

        SimpleSubtaskRow(
            subtask: .constant(Subtask(title: "Gather ingredients", isCompleted: false)),
            onToggle: {}
        )

        SimpleSubtaskRow(
            subtask: .constant(Subtask(title: "Choose recipe", isCompleted: true)),
            onToggle: {}
        )
    }
    .padding()
    .background(AppColors.background)
}
