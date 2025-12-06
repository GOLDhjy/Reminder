//
//  ContentView.swift
//  Reminder
//
//  Created by 黄金溢 on 2025/12/6.
//

import SwiftUI
import SwiftData

extension Optional {
    var isNil: Bool {
        return self == nil
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reminder.createdAt, order: .forward) private var reminders: [Reminder]
    @State private var showingAddReminder = false
    @State private var showingSettings = false
    @State private var selectedType: ReminderType?

    var body: some View {
        NavigationSplitView {
            List {
                // Filter Section
                if !selectedType.isNil {
                    Section(header: Text("筛选：\(selectedType?.rawValue ?? "全部")")) {
                        Button("清除筛选") {
                            selectedType = nil
                        }
                        .foregroundColor(.blue)
                    }
                }

                // Active Reminders
                if !activeReminders.isEmpty {
                    Section(header: Text("进行中的提醒 (\(activeReminders.count))")) {
                        ForEach(activeReminders) { reminder in
                            ReminderRow(reminder: reminder) {
                                editReminder(reminder)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("删除", role: .destructive) {
                                    deleteReminder(reminder)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button(reminder.isActive ? "暂停" : "启用") {
                                    toggleReminder(reminder)
                                }
                                .tint(reminder.isActive ? .orange : .green)
                            }
                        }
                    }
                }

                // Completed/Inactive Reminders
                if !inactiveReminders.isEmpty {
                    Section(header: Text("已暂停/完成 (\(inactiveReminders.count))")) {
                        ForEach(inactiveReminders) { reminder in
                            ReminderRow(reminder: reminder) {
                                editReminder(reminder)
                            }
                            .opacity(0.7)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("删除", role: .destructive) {
                                    deleteReminder(reminder)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button(reminder.isActive ? "暂停" : "启用") {
                                    toggleReminder(reminder)
                                }
                                .tint(reminder.isActive ? .orange : .green)
                            }
                        }
                    }
                }

                // Empty state
                if reminders.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "bell")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("还没有提醒")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("点击右上角的 + 添加您的第一个提醒")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(AppConstants.appName)
            .toolbar {
#if os(iOS)
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingSettings = true }) {
                            Label("设置", systemImage: "gear")
                        }

                        Menu("快速添加") {
                            ForEach(ReminderType.allCases.filter({ $0 != .custom }), id: \.self) { type in
                                Button(action: { quickAddReminder(type: type) }) {
                                    Label(type.rawValue, systemImage: type.icon)
                                }
                            }
                        }

                        Menu("筛选") {
                            Button("全部") {
                                selectedType = nil
                            }
                            Divider()
                            ForEach(ReminderType.allCases, id: \.self) { type in
                                Button(action: { selectedType = type }) {
                                    Label(type.rawValue, systemImage: type.icon)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button(action: { showingAddReminder = true }) {
                        Label("添加提醒", systemImage: "plus")
                    }
                }
#else
                ToolbarItemGroup {
                    Button(action: { showingSettings = true }) {
                        Label("设置", systemImage: "gear")
                    }

                    Menu("快速添加") {
                        ForEach(ReminderType.allCases.filter({ $0 != .custom }), id: \.self) { type in
                            Button(action: { quickAddReminder(type: type) }) {
                                Label(type.rawValue, systemImage: type.icon)
                            }
                        }
                    }

                    Menu("筛选") {
                        Button("全部") {
                            selectedType = nil
                        }
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Button(action: { selectedType = type }) {
                                Label(type.rawValue, systemImage: type.icon)
                            }
                        }
                    }

                    Button(action: { showingAddReminder = true }) {
                        Label("添加提醒", systemImage: "plus")
                    }
                }
#endif
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 300, ideal: 350)
#endif
        } detail: {
            if let selectedReminder = reminders.first {
                ReminderDetailView(reminder: selectedReminder)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    Text("选择一个提醒查看详情")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var activeReminders: [Reminder] {
        let filtered = reminders.filter { $0.isActive }
        let typeFiltered = if let selectedType = selectedType {
            filtered.filter { $0.type == selectedType }
        } else {
            filtered
        }
        // Sort by next trigger date (computed property)
        return typeFiltered.sorted { reminder1, reminder2 in
            let date1 = reminder1.nextTriggerDate ?? Date.distantFuture
            let date2 = reminder2.nextTriggerDate ?? Date.distantFuture
            return date1 < date2
        }
    }

    private var inactiveReminders: [Reminder] {
        let filtered = reminders.filter { !$0.isActive }
        if let selectedType = selectedType {
            return filtered.filter { $0.type == selectedType }
        }
        return filtered
    }

    private func quickAddReminder(type: ReminderType) {
        let defaultTime: Date = {
            let calendar = Calendar.current
            let now = Date()
            switch type {
            case .water:
                // Every 2 hours starting from current time
                return now
            case .meal:
                // Default to lunch time
                return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
            case .rest:
                // Every hour
                return now
            case .sleep:
                // Default to 10 PM
                return calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now) ?? now
            case .medicine:
                // Default to morning
                return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
            case .custom:
                return now
            }
        }()

        let repeatRule: RepeatRule = type == .medicine ? .daily : .daily
        let reminder = Reminder(
            title: type.rawValue,
            type: type,
            timeOfDay: defaultTime,
            repeatRule: repeatRule
        )

        modelContext.insert(reminder)
        saveAndSchedule(reminder: reminder)
    }

    private func toggleReminder(_ reminder: Reminder) {
        reminder.isActive.toggle()
        reminder.updatedAt = Date()
        saveAndSchedule(reminder: reminder)
    }

    private func deleteReminder(_ reminder: Reminder) {
        // Cancel notification first
        NotificationManager.shared.cancelNotification(for: reminder)

        // Delete from database
        modelContext.delete(reminder)
    }

    private func editReminder(_ reminder: Reminder) {
        // This would present the edit view
        // Implementation depends on navigation structure
    }

    private func saveAndSchedule(reminder: Reminder) {
        do {
            try modelContext.save()
            Task {
                if reminder.isActive {
                    try await NotificationManager.shared.scheduleNotification(for: reminder)
                } else {
                    NotificationManager.shared.cancelNotification(for: reminder)
                }
            }
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
}

// MARK: - Reminder Row View
struct ReminderRow: View {
    let reminder: Reminder
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: reminder.type.icon)
                    .font(.title2)
                    .foregroundColor(colorForType(reminder.type))
                    .frame(width: 30)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack {
                        // Time
                        Text(reminder.timeOfDay, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Repeat rule
                        Text("•")
                            .foregroundColor(.secondary)

                        Text(reminder.repeatRule.description)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        // Next trigger
                        if let nextTrigger = reminder.nextTriggerDate {
                            Text(nextTrigger, style: .relative)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                // Status indicator
                Circle()
                    .fill(reminder.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func colorForType(_ type: ReminderType) -> Color {
        switch type {
        case .water: return .blue
        case .meal: return .orange
        case .rest: return .green
        case .sleep: return .purple
        case .medicine: return .red
        case .custom: return .gray
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)
    ContentView()
        .modelContainer(container)
}