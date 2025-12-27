//
//  MealReminderCard.swift
//  ADHDAssistant
//
//  Card showing meal tracking status and reminders
//

import SwiftUI

struct MealReminderCard: View {
    @ObservedObject var viewModel: HealthViewModel
    @State private var showMealLog = false
    @State private var selectedMealType: String = "Meal"

    var body: some View {
        GlowingCard(
            glowColor: mealStatusColor,
            glowIntensity: shouldRemind ? .medium : .subtle
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accent)

                    Text("Meals")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    // Meals logged today
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.success)

                        Text("\(viewModel.mealsLoggedToday)")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                // Meal status
                mealStatusSection

                Divider()

                // Quick meal type selector
                mealTypesSection

                // Log meal button
                logMealButton
            }
        }
        .sheet(isPresented: $showMealLog) {
            MealLogDetailSheet(
                viewModel: viewModel,
                mealType: selectedMealType
            )
        }
    }

    // MARK: - Meal Status Section

    private var mealStatusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let lastMeal = viewModel.lastMealTime {
                HStack(spacing: AppSpacing.xs) {
                    Text("Last meal:")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)

                    Text(lastMeal.timeAgoString)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(timeSinceLastMealColor)
                }

                // Time indicator
                if shouldRemind {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12))

                        Text(reminderMessage)
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(AppColors.warning)
                }
            } else {
                Text("No meals logged today")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            // Suggested meal time
            if let suggestedMeal = suggestedMealType {
                Text("Suggested: \(suggestedMeal)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
            }
        }
    }

    // MARK: - Meal Types Section

    private var mealTypesSection: some View {
        HStack(spacing: AppSpacing.sm) {
            MealTypeButton(
                title: "Breakfast",
                icon: "sunrise.fill",
                isSelected: selectedMealType == "Breakfast",
                action: { selectedMealType = "Breakfast" }
            )

            MealTypeButton(
                title: "Lunch",
                icon: "sun.max.fill",
                isSelected: selectedMealType == "Lunch",
                action: { selectedMealType = "Lunch" }
            )

            MealTypeButton(
                title: "Dinner",
                icon: "moon.stars.fill",
                isSelected: selectedMealType == "Dinner",
                action: { selectedMealType = "Dinner" }
            )

            MealTypeButton(
                title: "Snack",
                icon: "leaf.fill",
                isSelected: selectedMealType == "Snack",
                action: { selectedMealType = "Snack" }
            )
        }
    }

    // MARK: - Log Meal Button

    private var logMealButton: some View {
        Button(action: logQuickMeal) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Log \(selectedMealType)")
                    .font(AppTypography.buttonTextSmall)
            }
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: - Computed Properties

    private var hoursSinceLastMeal: Double? {
        guard let lastMeal = viewModel.lastMealTime else { return nil }
        return abs(lastMeal.timeIntervalSinceNow) / 3600
    }

    private var shouldRemind: Bool {
        guard let hours = hoursSinceLastMeal else { return true }
        return hours >= 4 // Remind if more than 4 hours since last meal
    }

    private var reminderMessage: String {
        guard let hours = hoursSinceLastMeal else {
            return "Time to eat!"
        }

        if hours >= 6 {
            return "It's been a while since your last meal"
        } else if hours >= 4 {
            return "Consider having a meal soon"
        } else {
            return "Doing great!"
        }
    }

    private var mealStatusColor: Color {
        if shouldRemind {
            return AppColors.warning
        } else {
            return AppColors.accent
        }
    }

    private var timeSinceLastMealColor: Color {
        guard let hours = hoursSinceLastMeal else {
            return AppColors.textSecondary
        }

        if hours >= 6 {
            return AppColors.error
        } else if hours >= 4 {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }

    private var suggestedMealType: String? {
        let hour = Date().hour

        switch hour {
        case 6..<11:
            return "Breakfast"
        case 11..<14:
            return "Lunch"
        case 17..<21:
            return "Dinner"
        default:
            return nil
        }
    }

    // MARK: - Actions

    private func logQuickMeal() {
        Task {
            await viewModel.logMeal(type: selectedMealType)
        }
    }
}

// MARK: - Supporting Views

private struct MealTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : AppColors.accent)

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColors.accent : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall)
                    .stroke(isSelected ? AppColors.accent : AppColors.divider, lineWidth: 1)
            )
        }
    }
}

// Detailed meal logging sheet
private struct MealLogDetailSheet: View {
    let viewModel: HealthViewModel
    let mealType: String
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String = ""
    @State private var includesCarbs = false
    @State private var includesProtein = false
    @State private var includesVegetables = false

    var body: some View {
        NavigationView {
            Form {
                Section("Meal Type") {
                    HStack {
                        Image(systemName: mealIcon)
                            .foregroundColor(AppColors.accent)

                        Text(mealType)
                            .font(AppTypography.bodyBold)
                    }
                }

                Section("What did you eat?") {
                    TextField("Describe your meal...", text: $notes, axis: .vertical)
                        .font(AppTypography.body)
                        .lineLimit(3...8)
                }

                Section("Meal Components") {
                    Toggle(isOn: $includesCarbs) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.orange)
                            Text("Carbohydrates")
                        }
                    }

                    Toggle(isOn: $includesProtein) {
                        HStack {
                            Image(systemName: "fish.fill")
                                .foregroundColor(.blue)
                            Text("Protein")
                        }
                    }

                    Toggle(isOn: $includesVegetables) {
                        HStack {
                            Image(systemName: "carrot.fill")
                                .foregroundColor(.green)
                            Text("Vegetables")
                        }
                    }
                }

                Section {
                    Button(action: saveMeal) {
                        Text("Log Meal")
                            .font(AppTypography.buttonText)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Log \(mealType)")
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

    private var mealIcon: String {
        switch mealType {
        case "Breakfast": return "sunrise.fill"
        case "Lunch": return "sun.max.fill"
        case "Dinner": return "moon.stars.fill"
        case "Snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    private func saveMeal() {
        var components: [String] = []
        if includesCarbs { components.append("carbs") }
        if includesProtein { components.append("protein") }
        if includesVegetables { components.append("vegetables") }

        let detailedNotes = notes.isEmpty ?
            (components.isEmpty ? mealType : "\(mealType) - \(components.joined(separator: ", "))") :
            "\(mealType) - \(notes)"

        Task {
            await viewModel.logMeal(type: mealType, notes: detailedNotes)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MealReminderCard(viewModel: HealthViewModel())
    }
    .padding()
    .background(AppColors.background)
}
