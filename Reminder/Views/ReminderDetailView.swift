//
//  ReminderDetailView.swift
//  Reminder
//
//  Created by 黄金溢 on 2025/12/6.
//

import SwiftUI
import SwiftData

struct ReminderDetailView: View {
    @Bindable var reminder: Reminder
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: reminder.type.icon)
                            .font(.system(size: 40))
                            .foregroundColor(colorForType(reminder.type))

                        Spacer()

                        // Status Badge
                        HStack {
                            Circle()
                                .fill(reminder.isActive ? Color.green : Color.gray)
                                .frame(width: 12, height: 12)
                            Text(reminder.isActive ? "进行中" : "已暂停")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(reminder.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let notes = reminder.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Time Information
                Group {
                    SectionHeader(title: "时间信息", icon: "clock")

                    VStack(spacing: 12) {
                        InfoRow(
                            title: "提醒时间",
                            value: reminder.timeOfDay.formatted(date: .omitted, time: .shortened)
                        )

                        InfoRow(
                            title: "开始日期",
                            value: reminder.startDate.formatted(date: .abbreviated, time: .omitted)
                        )

                        if let endDate = reminder.endDate {
                            InfoRow(
                                title: "结束日期",
                                value: endDate.formatted(date: .abbreviated, time: .omitted)
                            )
                        }

                        if let nextTrigger = reminder.nextTriggerDate {
                            InfoRow(
                                title: "下次提醒",
                                value: nextTrigger.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                    }
                }

                // Repeat Information
                Group {
                    SectionHeader(title: "重复设置", icon: "repeat")

                    VStack(spacing: 12) {
                        InfoRow(
                            title: "重复规则",
                            value: reminder.repeatRule.description
                        )

                        if reminder.excludeHolidays {
                            InfoRow(
                                title: "节假日",
                                value: "排除节假日"
                            )
                        }
                    }
                }

                // Statistics
                Group {
                    SectionHeader(title: "统计信息", icon: "chart.bar")

                    VStack(spacing: 12) {
                        InfoRow(
                            title: "创建时间",
                            value: reminder.createdAt.formatted(date: .abbreviated, time: .shortened)
                        )

                        InfoRow(
                            title: "最后更新",
                            value: reminder.updatedAt.formatted(date: .abbreviated, time: .shortened)
                        )

                        if let lastTriggered = reminder.lastTriggered {
                            InfoRow(
                                title: "最后触发",
                                value: lastTriggered.formatted(date: .abbreviated, time: .shortened)
                            )
                        }

                        InfoRow(
                            title: "提醒次数",
                            value: "\(reminder.logs.count)"
                        )
                    }
                }

                // Recent Logs
                if !reminder.logs.isEmpty {
                    Group {
                        SectionHeader(title: "最近记录", icon: "list.bullet")

                        LazyVStack(spacing: 8) {
                            ForEach(reminder.logs.suffix(5), id: \.id) { log in
                                LogRow(log: log)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppColors.formBackground)
        .navigationTitle("提醒详情")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(reminder.isActive ? "暂停提醒" : "启用提醒") {
                        toggleReminder()
                    }

                    Button("编辑") {
                        isEditing = true
                    }

                    Button("删除", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
#else
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(reminder.isActive ? "暂停提醒" : "启用提醒") {
                    toggleReminder()
                }

                Button("编辑") {
                    isEditing = true
                }

                Button("删除", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
#endif
        .sheet(isPresented: $isEditing) {
            EditReminderView(reminder: reminder)
        }
        .alert("删除提醒", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteReminder()
            }
        } message: {
            Text("确定要删除这个提醒吗？此操作无法撤销。")
        }
    }

    private func toggleReminder() {
        reminder.isActive.toggle()
        reminder.updatedAt = Date()

        Task {
            if reminder.isActive {
                try? await NotificationManager.shared.scheduleNotification(for: reminder)
            } else {
                NotificationManager.shared.cancelNotification(for: reminder)
            }
        }
    }

    private func deleteReminder() {
        NotificationManager.shared.cancelNotification(for: reminder)
        modelContext.delete(reminder)
        dismiss()
    }

    private func colorForType(_ type: ReminderType) -> Color {
        switch type {
        case .water: return .blue
        case .meal: return .orange
        case .rest: return .green
        case .sleep: return .purple
        case .medicine: return .red
        case .exercise: return .mint
        case .custom: return .gray
        }
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.top, 10)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct LogRow: View {
    let log: ReminderLog

    var body: some View {
        HStack {
            Image(systemName: iconForAction(log.action))
                .foregroundColor(colorForAction(log.action))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.action.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let notes = log.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }

    private func iconForAction(_ action: ReminderLog.LogAction) -> String {
        switch action {
        case .triggered: return "bell"
        case .acknowledged: return "checkmark.circle"
        case .snoozed: return "clock.arrow.circlepath"
        case .skipped: return "xmark.circle"
        case .completed: return "checkmark.circle.fill"
        }
    }

    private func colorForAction(_ action: ReminderLog.LogAction) -> Color {
        switch action {
        case .triggered: return .blue
        case .acknowledged: return .gray
        case .snoozed: return .orange
        case .skipped: return .red
        case .completed: return .green
        }
    }
}

// MARK: - Edit Reminder View
struct EditReminderView: View {
    @Bindable var reminder: Reminder
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("基本信息")) {
                    TextField("提醒标题", text: $reminder.title)
#if os(iOS)
                        .textInputAutocapitalization(.words)
#endif

                    Picker("提醒类型", selection: $reminder.type) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    TextField("备注", text: .init(
                        get: { reminder.notes ?? "" },
                        set: { reminder.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3)
                }

                // Time Settings
                Section(header: Text("时间设置")) {
                    DatePicker("提醒时间", selection: $reminder.timeOfDay, displayedComponents: .hourAndMinute)
                    DatePicker("开始日期", selection: $reminder.startDate, displayedComponents: .date)

                    Toggle("设置结束日期", isOn: .init(
                        get: { reminder.endDate != nil },
                        set: { isOn in
                            if isOn {
                                reminder.endDate = Date()
                            } else {
                                reminder.endDate = nil
                            }
                        }
                    ))

                    if reminder.endDate != nil {
                        DatePicker("结束日期", selection: .init(
                            get: { reminder.endDate ?? Date() },
                            set: { reminder.endDate = $0 }
                        ), displayedComponents: .date)
                    }
                }

                // Repeat Settings
                Section(header: Text("重复设置")) {
                    Picker("重复规则", selection: $reminder.repeatRule) {
                        Text("不重复").tag(RepeatRule.never)
                        Text("每天").tag(RepeatRule.daily)
                        Text("工作日").tag(RepeatRule.weekly([.monday, .tuesday, .wednesday, .thursday, .friday]))
                        Text("周末").tag(RepeatRule.weekly([.saturday, .sunday]))
                        Text("每月1日").tag(RepeatRule.monthly(1))
                        Text("每年1月1日").tag(RepeatRule.yearly(1, 1))
                    }

                    Toggle("排除节假日", isOn: $reminder.excludeHolidays)
                }
            }
            .navigationTitle("编辑提醒")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                }
            }
#else
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("取消") {
                        dismiss()
                    }
                    Button("保存") {
                        saveChanges()
                    }
                }
            }
#endif
        }
    }

    private func saveChanges() {
        reminder.updatedAt = Date()

        Task {
            do {
                try modelContext.save()

                if reminder.isActive {
                    try await NotificationManager.shared.scheduleNotification(for: reminder)
                }

                dismiss()
            } catch {
                print("Failed to save changes: \(error)")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)
    let reminder = Reminder(title: "测试提醒", type: .water, timeOfDay: Date())
    ReminderDetailView(reminder: reminder)
        .modelContainer(container)
}