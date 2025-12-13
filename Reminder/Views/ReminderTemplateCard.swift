//
//  ReminderTemplateCard.swift
//  Reminder
//
//  Created by Codex on 2025/2/8.
//

import SwiftUI

// MARK: - Reminder Template
struct ReminderTemplate {
    let title: String
    let icon: String
    let type: ReminderType
    let time: Date?
    let repeatRule: RepeatRule?

    init(title: String, icon: String, type: ReminderType, time: Date? = nil, repeatRule: RepeatRule? = nil) {
        self.title = title
        self.icon = icon
        self.type = type
        self.time = time
        self.repeatRule = repeatRule
    }
}

// MARK: - Reminder Template Card
struct ReminderTemplateCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.15) : AppColors.cardElevated)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? color : .primary)
                }

                // 标题
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.08) : AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color.opacity(0.5) : AppColors.shadow.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Type Selection Card
struct TypeSelectionCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.15) : AppColors.cardElevated)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? color : .primary)
                }

                // 标题
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.08) : AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color.opacity(0.5) : AppColors.shadow.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        ReminderTemplateCard(
            title: "喝水",
            icon: "drop.fill",
            color: AppColors.water,
            isSelected: true
        ) {

        }

        TypeSelectionCard(
            title: "运动",
            icon: "figure.run",
            color: AppColors.exercise,
            isSelected: false
        ) {

        }
    }
    .padding()
    .background(AppColors.formBackground)
}