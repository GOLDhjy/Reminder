//
//  TimerTaskSheet.swift
//  Reminder
//
//  Created by Codex on 2025/2/8.
//

import SwiftUI
import SwiftData

struct TimerTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = "定时任务"
    @State private var notes: String = ""
    @State private var selectedType: ReminderType = .cooking
    @State private var durationMinutes: Double = 10
    @State private var userEditedTitle: Bool = false
    @State private var autoTitle: String? = "定时任务"

    private let presetDurations: [Int] = [5, 10, 15, 20, 25, 30, 45, 60]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    SectionCard(title: "提醒内容") {
                        VStack(alignment: .leading, spacing: 12) {
                        TextField("做什么？例如：煮饭、焖汤", text: $title)
                            .padding(12)
                            .background(AppColors.cardElevated)
                            .cornerRadius(12)
#if os(iOS)
                            .textInputAutocapitalization(.sentences)
#endif
                            .onChange(of: title) { newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    userEditedTitle = false
                                } else if trimmed != autoTitle {
                                    userEditedTitle = true
                                }
                            }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ReminderType.allCases, id: \.self) { type in
                                    TagChip(title: type.rawValue, systemImage: type.icon, isSelected: selectedType == type, color: AppColors.colorForType(type)) {
                                        selectedType = type
                                        applyAutoTitleIfNeeded(for: type)
                                    }
                                }
                            }
                        }

                            TextField("备注（可选）", text: $notes, axis: .vertical)
                                .lineLimit(3)
                                .padding(12)
                                .background(AppColors.cardElevated)
                                .cornerRadius(12)
                        }
                    }

                    SectionCard(title: "计时长度") {
                        VStack(alignment: .leading, spacing: 14) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(presetDurations, id: \.self) { minutes in
                                        Button(action: {
                                            durationMinutes = Double(minutes)
                                        }) {
                                            Text("\(minutes) 分钟")
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .fill(minutes == Int(durationMinutes) ? AppColors.primary.opacity(0.15) : AppColors.cardElevated)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(minutes == Int(durationMinutes) ? AppColors.primary : AppColors.shadow.opacity(0.4), lineWidth: 1)
                                                )
                                        }
                                        .foregroundColor(.primary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Slider(value: $durationMinutes, in: 1...120, step: 1) {
                                    Text("自定义分钟数")
                                }
                                .tint(AppColors.primary)
                                Text("将在 \(Int(durationMinutes)) 分钟后提醒你。")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.secondary)
                                Text("适合煮饭、炖汤、番茄钟等快速提醒。")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .background(AppColors.formBackground)
            }
        }
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("开始计时") {
                    createTimerReminder()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }

        // Bottom primary button for clarity
        .safeAreaInset(edge: .bottom) {
            Button {
                createTimerReminder()
            } label: {
                Text("开始计时")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.primary)
                    )
                    .padding(.horizontal, 20)
                    .shadow(color: AppColors.primary.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "timer")
                    .foregroundColor(AppColors.primary)
                    .font(.title2.weight(.semibold))
            }
            Text("定时任务")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("几分钟后提醒你，适合做饭/泡面/运动间隔")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColors.cardElevated)
    }

    private func createTimerReminder() {
        let dueDate = normalizedDueDate(minutesFromNow: durationMinutes)
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let reminder = Reminder(
            title: cleanTitle.isEmpty ? "定时任务" : cleanTitle,
            type: selectedType,
            timeOfDay: dueDate,
            repeatRule: .never,
            notes: notes.isEmpty ? nil : notes
        )

        // Ensure it's a one-off timer
        reminder.startDate = dueDate
        reminder.endDate = dueDate
        reminder.excludeHolidays = false
        reminder.isActive = true

        modelContext.insert(reminder)

        do {
            try modelContext.save()

            Task {
                try? await NotificationManager.shared.scheduleNotification(for: reminder)
            }

            dismiss()
        } catch {
            print("Failed to save timer reminder: \(error)")
        }
    }

    private func normalizedDueDate(minutesFromNow: Double) -> Date {
        let calendar = Calendar.current
        let rawDate = Date().addingTimeInterval(minutesFromNow * 60)
        return calendar.date(bySetting: .second, value: 0, of: rawDate) ?? rawDate
    }

    private func applyAutoTitleIfNeeded(for type: ReminderType) {
        let newTitle = type.rawValue
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userEditedTitle && (trimmed.isEmpty || trimmed == autoTitle) {
            title = newTitle
            autoTitle = newTitle
        } else {
            autoTitle = newTitle
        }
    }
}

// MARK: - Section Card
private struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Tag Chip
private struct TagChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.gray.opacity(0.25), lineWidth: 1)
            )
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)
    TimerTaskSheet()
        .modelContainer(container)
}
