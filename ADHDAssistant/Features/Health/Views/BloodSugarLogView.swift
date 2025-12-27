//
//  BloodSugarLogView.swift
//  ADHDAssistant
//
//  Blood sugar logging interface with context and validation
//

import SwiftUI

struct BloodSugarLogView: View {
    @ObservedObject var viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var bloodSugarValue: String = ""
    @State private var selectedContext: BloodSugarReading.MealTiming = .random
    @State private var notes: String = ""
    @State private var showCelebration = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Large number input
                    numberInputSection

                    // Context selection
                    contextSection

                    // Color indicator
                    levelIndicator

                    // Recent readings for reference
                    recentReadingsSection

                    // Optional notes
                    notesSection

                    // Save button
                    saveButton
                }
                .padding(.horizontal, AppSpacing.screenHorizontalPadding)
                .padding(.vertical, AppSpacing.screenVerticalPadding)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Log Blood Sugar")
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

    // MARK: - Number Input Section

    private var numberInputSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Blood Sugar Reading")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)

            // Large number input
            HStack(spacing: AppSpacing.xs) {
                TextField("000", text: $bloodSugarValue)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(currentLevelColor)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($isInputFocused)
                    .monospacedDigit()

                Text("mg/dL")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.lg)

            // Quick value buttons
            HStack(spacing: AppSpacing.sm) {
                QuickValueButton(value: 80, currentValue: $bloodSugarValue)
                QuickValueButton(value: 100, currentValue: $bloodSugarValue)
                QuickValueButton(value: 120, currentValue: $bloodSugarValue)
                QuickValueButton(value: 150, currentValue: $bloodSugarValue)
            }
        }
        .onAppear {
            // Auto-focus the input field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    // MARK: - Context Section

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("When did you take this reading?")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(BloodSugarReading.MealTiming.allCases, id: \.self) { timing in
                    ContextButton(
                        timing: timing,
                        isSelected: selectedContext == timing,
                        action: {
                            selectedContext = timing
                            HapticManager.shared.impact(.light)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Level Indicator

    private var levelIndicator: some View {
        Group {
            if let value = Double(bloodSugarValue), value > 0 {
                let reading = BloodSugarReading(
                    value: value,
                    timing: selectedContext
                )

                GlowingCard(
                    glowColor: viewModel.bloodSugarColor(for: reading),
                    glowIntensity: reading.requiresAttention ? .strong : .medium
                ) {
                    HStack(spacing: AppSpacing.md) {
                        Circle()
                            .fill(viewModel.bloodSugarColor(for: reading))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(reading.level.displayName)
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.textPrimary)

                            Text(levelDescription(for: reading))
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        if reading.requiresAttention {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.bloodSugarColor(for: reading))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Readings

    private var recentReadingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Readings")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            let recentBloodSugar = viewModel.recentMetrics
                .filter { $0.type == .bloodSugar }
                .prefix(3)

            if recentBloodSugar.isEmpty {
                Text("No recent readings")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textTertiary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(recentBloodSugar), id: \.id) { metric in
                        if let reading = metric.bloodSugarReading {
                            RecentReadingRow(
                                reading: reading,
                                date: metric.recordedAt,
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Notes (Optional)")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            TextField("How are you feeling?", text: $notes, axis: .vertical)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
                .lineLimit(3...6)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: saveReading) {
            HStack {
                if showCelebration {
                    Image(systemName: "checkmark.circle.fill")
                        .transition(.scale)
                }

                Text("Save Reading")
                    .font(AppTypography.buttonText)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.buttonPaddingVertical)
            .background(isValidInput ? AppColors.primary : AppColors.divider)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        }
        .disabled(!isValidInput)
        .animation(.spring(), value: showCelebration)
    }

    // MARK: - Helpers

    private var isValidInput: Bool {
        guard let value = Double(bloodSugarValue) else { return false }
        return value > 0 && value < 600 // Reasonable range
    }

    private var currentLevelColor: Color {
        guard let value = Double(bloodSugarValue), value > 0 else {
            return AppColors.textPrimary
        }

        let reading = BloodSugarReading(value: value, timing: selectedContext)
        return viewModel.bloodSugarColor(for: reading)
    }

    private func levelDescription(for reading: BloodSugarReading) -> String {
        switch reading.level {
        case .low:
            return "Below normal range - consider eating"
        case .normal:
            return "Within healthy range"
        case .elevated:
            return "Slightly elevated - monitor closely"
        case .high:
            return "Above normal range - consult your doctor"
        }
    }

    private func saveReading() {
        guard let value = Double(bloodSugarValue) else { return }

        Task {
            let notesText = notes.isEmpty ? nil : notes
            await viewModel.logBloodSugar(
                value: value,
                context: selectedContext,
                notes: notesText
            )

            // Show celebration
            showCelebration = true

            // Dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

private struct QuickValueButton: View {
    let value: Int
    @Binding var currentValue: String

    var body: some View {
        Button(action: {
            currentValue = "\(value)"
            HapticManager.shared.impact(.light)
        }) {
            Text("\(value)")
                .font(AppTypography.bodyBold)
                .foregroundColor(currentValue == "\(value)" ? .white : AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(currentValue == "\(value)" ? AppColors.primary : AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall)
                        .stroke(AppColors.primary, lineWidth: 1)
                )
        }
    }
}

private struct ContextButton: View {
    let timing: BloodSugarReading.MealTiming
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)

                Text(timing.displayName)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }
            .padding(AppSpacing.md)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall)
                    .stroke(isSelected ? AppColors.primary : AppColors.divider, lineWidth: 1)
            )
        }
    }
}

private struct RecentReadingRow: View {
    let reading: BloodSugarReading
    let date: Date
    let viewModel: HealthViewModel

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(reading.value))")
                    .font(AppTypography.title3)
                    .foregroundColor(viewModel.bloodSugarColor(for: reading))

                Text("mg/dL")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(width: 60, alignment: .leading)

            // Context and time
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.timing.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)

                Text(date.shortTimeAgoString)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            // Level indicator
            Circle()
                .fill(viewModel.bloodSugarColor(for: reading))
                .frame(width: 8, height: 8)
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
    }
}

// MARK: - Preview

#Preview {
    BloodSugarLogView(viewModel: HealthViewModel())
}
