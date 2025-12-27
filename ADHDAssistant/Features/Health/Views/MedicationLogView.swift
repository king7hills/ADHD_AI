//
//  MedicationLogView.swift
//  ADHDAssistant
//
//  Medication tracking and reminder interface
//

import SwiftUI

struct MedicationLogView: View {
    @ObservedObject var viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showAddMedication = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header stats
                    adherenceCard

                    // Today's medications
                    todayMedicationsSection

                    // Add medication button
                    addMedicationButton
                }
                .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                .padding(.vertical, AppSpacing.screenVerticalPadding)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddMedication) {
                AddMedicationSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Adherence Card

    private var adherenceCard: some View {
        GlowingCard(
            glowColor: adherenceColor,
            glowIntensity: .medium
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 24))
                        .foregroundColor(adherenceColor)

                    Text("Today's Adherence")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Text("\(Int(viewModel.medicationAdherenceRate * 100))%")
                        .font(AppTypography.title2)
                        .foregroundColor(adherenceColor)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusXS)
                            .fill(AppColors.divider)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusXS)
                            .fill(adherenceColor)
                            .frame(
                                width: geometry.size.width * viewModel.medicationAdherenceRate,
                                height: 8
                            )
                    }
                }
                .frame(height: 8)

                if !viewModel.todayMedications.isEmpty {
                    let taken = viewModel.todayMedications.filter { $0.isTaken }.count
                    let total = viewModel.todayMedications.count

                    Text("\(taken) of \(total) medications taken")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Today's Medications

    private var todayMedicationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Today's Schedule")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            if viewModel.todayMedications.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.todayMedications) { medication in
                        MedicationRow(
                            medication: medication,
                            onToggle: {
                                Task {
                                    await viewModel.toggleMedication(medication)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GlowingCard(glowColor: AppColors.divider, glowIntensity: .none) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "pills")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.textTertiary)

                Text("No medications scheduled")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                Text("Add your medications to track them here")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, AppSpacing.lg)
        }
    }

    // MARK: - Add Medication Button

    private var addMedicationButton: some View {
        Button(action: { showAddMedication = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))

                Text("Add Medication")
                    .font(AppTypography.buttonText)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.buttonPaddingVertical)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        }
    }

    // MARK: - Helpers

    private var adherenceColor: Color {
        let rate = viewModel.medicationAdherenceRate
        if rate >= 0.8 {
            return AppColors.success
        } else if rate >= 0.5 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }
}

// MARK: - Supporting Views

private struct MedicationRow: View {
    let medication: MedicationStatus
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.md) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            medication.isTaken ? AppColors.success : statusColor,
                            lineWidth: 2
                        )
                        .frame(width: 32, height: 32)

                    if medication.isTaken {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Medication info
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.medication.medicationName)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                        .strikethrough(medication.isTaken)

                    HStack(spacing: AppSpacing.xs) {
                        Text(medication.medication.dosage)
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)

                        Text("•")
                            .foregroundColor(AppColors.textTertiary)

                        Text(medication.displayTime)
                            .font(AppTypography.subheadline)
                            .foregroundColor(statusTextColor)
                    }

                    if medication.isOverdue {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))

                            Text("Overdue")
                                .font(AppTypography.caption)
                        }
                        .foregroundColor(AppColors.error)
                    } else if medication.isTaken, let actualTime = medication.medication.actualTime {
                        Text("Taken at \(actualTime.shortTimeString)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.success)
                    }
                }

                Spacer()

                // Status indicator
                if medication.isOverdue && !medication.isTaken {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(AppColors.error)
                }
            }
            .padding(AppSpacing.md)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                    .stroke(borderColor, lineWidth: medication.isOverdue ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var statusColor: Color {
        if medication.isOverdue {
            return AppColors.error
        } else {
            return AppColors.primary
        }
    }

    private var statusTextColor: Color {
        if medication.isOverdue {
            return AppColors.error
        } else {
            return AppColors.textSecondary
        }
    }

    private var backgroundColor: Color {
        if medication.isTaken {
            return AppColors.success.opacity(0.05)
        } else if medication.isOverdue {
            return AppColors.error.opacity(0.05)
        } else {
            return AppColors.card
        }
    }

    private var borderColor: Color {
        if medication.isTaken {
            return AppColors.success.opacity(0.3)
        } else if medication.isOverdue {
            return AppColors.error
        } else {
            return AppColors.divider
        }
    }
}

// Add Medication Sheet
private struct AddMedicationSheet: View {
    let viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var medicationName: String = ""
    @State private var dosage: String = ""
    @State private var selectedHour = 8
    @State private var selectedMinute = 0

    var body: some View {
        NavigationView {
            Form {
                Section("Medication Details") {
                    TextField("Name (e.g., Metformin)", text: $medicationName)
                        .font(AppTypography.body)

                    TextField("Dosage (e.g., 500mg)", text: $dosage)
                        .font(AppTypography.body)
                }

                Section("Scheduled Time") {
                    Picker("Hour", selection: $selectedHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }

                    Picker("Minute", selection: $selectedMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: ":%02d", minute)).tag(minute)
                        }
                    }
                }

                Section {
                    Button(action: saveMedication) {
                        Text("Add Medication")
                            .font(AppTypography.buttonText)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(canSave ? AppColors.primary : AppColors.divider)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                    }
                    .disabled(!canSave)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        !medicationName.isEmpty && !dosage.isEmpty
    }

    private func saveMedication() {
        let calendar = Calendar.current
        let now = Date()

        guard let scheduledTime = calendar.date(
            bySettingHour: selectedHour,
            minute: selectedMinute,
            second: 0,
            of: now
        ) else { return }

        Task {
            await viewModel.logMedication(
                name: medicationName,
                dosage: dosage,
                scheduledTime: scheduledTime
            )

            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    MedicationLogView(viewModel: HealthViewModel())
}
