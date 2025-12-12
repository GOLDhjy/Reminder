//
//  TimerTaskSheet.swift
//  Reminder
//
//  Created by Codex on 2025/2/8.
//

import SwiftUI
import SwiftData

// MARK: - Timer Preset
struct TimerPreset {
    let title: String
    let duration: Int
    let icon: String
}

struct TimerTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let reminder: Reminder?

    init(reminder: Reminder? = nil) {
        self.reminder = reminder
    }

    @State private var title: String = "计时任务"
    @State private var notes: String = ""
    @State private var durationMinutes: Double = 10
    @State private var selectedPreset: TimerPreset?

    private let presetDurations: [Int] = [5, 10, 15, 20, 25, 30, 45, 60]
    private let timerPresets: [TimerPreset] = [
        TimerPreset(title: "煮面", duration: 5, icon: "fork.knife"),
        TimerPreset(title: "煮鸡蛋", duration: 8, icon: "circle.fill"),
        TimerPreset(title: "煲汤", duration: 45, icon: "pot.fill"),
        TimerPreset(title: "蒸蛋", duration: 10, icon: "leaf.fill"),
        TimerPreset(title: "焖饭", duration: 20, icon: "bowl.fill"),
        TimerPreset(title: "烤面包", duration: 3, icon: "square.3.layers.3d"),
        TimerPreset(title: "泡茶", duration: 3, icon: "leaf"),
        TimerPreset(title: "咖啡", duration: 5, icon: "cup.and.saucer.fill"),
        TimerPreset(title: "运动间歇", duration: 15, icon: "figure.run"),
        TimerPreset(title: "番茄工作法", duration: 25, icon: "timer"),
        TimerPreset(title: "休息一下", duration: 5, icon: "figure.seated.side"),
        TimerPreset(title: "眼保健操", duration: 3, icon: "eye.fill"),
        TimerPreset(title: "提醒关火", duration: 30, icon: "flame.fill"),
        TimerPreset(title: "面膜时间", duration: 15, icon: "face.smiling"),
        TimerPreset(title: "自定义", duration: 10, icon: "slider.horizontal.3")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    SectionCard(title: "提醒内容") {
                        VStack(alignment: .leading, spacing: 12) {
                            // 预设场景选择 - 使用网格布局
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(timerPresets, id: \.title) { preset in
                                    TimerPresetCard(
                                        title: preset.title,
                                        icon: preset.icon,
                                        duration: preset.duration,
                                        isSelected: selectedPreset?.title == preset.title,
                                        color: AppColors.timer
                                    ) {
                                        selectPreset(preset)
                                    }
                                }
                            }

                            TextField("做什么？例如：煮饭、焖汤", text: $title)
                                .padding(12)
                                .background(AppColors.cardElevated)
                                .cornerRadius(12)
#if os(iOS)
                                .textInputAutocapitalization(.sentences)
#endif

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
                                                        .fill(minutes == Int(durationMinutes) ? AppColors.timer.opacity(0.15) : AppColors.cardElevated)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(minutes == Int(durationMinutes) ? AppColors.timer : AppColors.shadow.opacity(0.4), lineWidth: 1)
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
                                .tint(AppColors.timer)
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
        .onAppear {
            if let reminder = reminder {
                // 编辑模式：加载现有数据
                title = reminder.title
                notes = reminder.notes ?? ""
                // 计算持续时间（从创建时间到触发时间）
                durationMinutes = reminder.timeOfDay.timeIntervalSince(reminder.startDate) / 60
                selectedPreset = nil  // 编辑模式下不选择预设
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
                Button(reminder == nil ? "开始计时" : "保存修改") {
                    if reminder == nil {
                        createTimerReminder()
                    } else {
                        updateTimerReminder()
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }

        // Bottom primary button for clarity
        .safeAreaInset(edge: .bottom) {
            Button {
                if reminder == nil {
                    createTimerReminder()
                } else {
                    updateTimerReminder()
                }
            } label: {
                Text(reminder == nil ? "开始计时" : "保存修改")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.timer)
                    )
                    .padding(.horizontal, 20)
                    .shadow(color: AppColors.timer.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
    }

    private func selectPreset(_ preset: TimerPreset) {
        selectedPreset = preset
        title = preset.title
        durationMinutes = Double(preset.duration)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.timer.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "timer")
                    .foregroundColor(AppColors.timer)
                    .font(.title2.weight(.semibold))
            }
            Text(reminder == nil ? "计时任务" : "编辑计时任务")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(reminder == nil ? "几分钟后提醒你，适合做饭/泡面/运动间隔" : "修改计时任务的设置")
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
            title: cleanTitle.isEmpty ? "计时任务" : cleanTitle,
            type: .timer,
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

    private func updateTimerReminder() {
        guard let reminder = reminder else { return }

        let dueDate = normalizedDueDate(minutesFromNow: durationMinutes)
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // 更新提醒
        reminder.title = cleanTitle.isEmpty ? "计时任务" : cleanTitle
        reminder.notes = notes.isEmpty ? nil : notes
        reminder.timeOfDay = dueDate
        reminder.startDate = Date() // 从现在开始计时
        reminder.endDate = dueDate
        reminder.updatedAt = Date()

        // 如果提醒是活跃的，重新调度通知
        if reminder.isActive {
            Task {
                NotificationManager.shared.cancelNotification(for: reminder)
                try? await NotificationManager.shared.scheduleNotification(for: reminder)
            }
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to update timer reminder: \(error)")
        }
    }

    private func normalizedDueDate(minutesFromNow: Double) -> Date {
        let calendar = Calendar.current
        let rawDate = Date().addingTimeInterval(minutesFromNow * 60)
        return calendar.date(bySetting: .second, value: 0, of: rawDate) ?? rawDate
    }
}

// MARK: - Timer Preset Card
struct TimerPresetCard: View {
    let title: String
    let icon: String
    let duration: Int
    let isSelected: Bool
    let color: Color
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

                // 标题和时长
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(duration)分钟")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
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

// MARK: - Timer Preset Chip
struct TimerPresetChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .foregroundColor(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
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


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)
    TimerTaskSheet()
        .modelContainer(container)
}
