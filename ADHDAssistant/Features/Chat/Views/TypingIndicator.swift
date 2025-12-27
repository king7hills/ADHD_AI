//
//  TypingIndicator.swift
//  ADHDAssistant
//
//  Animated typing indicator for AI responses
//

import SwiftUI

struct TypingIndicator: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(AppColors.textSecondary.opacity(dotCount >= 1 ? 1.0 : 0.3))
                .frame(width: 8, height: 8)
                .scaleEffect(dotCount >= 1 ? 1.0 : 0.6)

            Circle()
                .fill(AppColors.textSecondary.opacity(dotCount >= 2 ? 1.0 : 0.3))
                .frame(width: 8, height: 8)
                .scaleEffect(dotCount >= 2 ? 1.0 : 0.6)

            Circle()
                .fill(AppColors.textSecondary.opacity(dotCount >= 3 ? 1.0 : 0.3))
                .frame(width: 8, height: 8)
                .scaleEffect(dotCount >= 3 ? 1.0 : 0.6)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// MARK: - Preview

#Preview("Typing Indicator") {
    VStack(spacing: AppSpacing.lg) {
        TypingIndicator()

        // Show in context
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        )

                    Text("Assistant")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                TypingIndicator()
            }

            Spacer()
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}
