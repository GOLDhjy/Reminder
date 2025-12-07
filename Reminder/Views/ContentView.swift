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
    @State private var editingReminder: Reminder?
    @State private var centralButtonScale: CGFloat = 1.0

    var body: some View {
        NavigationSplitView {
            ZStack(alignment: .bottom) {
            List {
                // Filter Section
                if !selectedType.isNil {
                    Section(header: Text("筛选：\(selectedType?.rawValue ?? "全部")")) {
                        Button("清除筛选") {
                            selectedType = nil
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }

                // Active Reminders with better spacing
                if !activeReminders.isEmpty {
                    Section {
                        ForEach(activeReminders) { reminder in
                            ReminderRow(reminder: reminder) {
                                editReminder(reminder)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
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
                    } header: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            Text("进行中的提醒")
                                .font(.headline)
                            Spacer()
                            Text("\(activeReminders.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 4)
                    }
                }

                // Completed/Inactive Reminders
                if !inactiveReminders.isEmpty {
                    Section {
                        ForEach(inactiveReminders) { reminder in
                            ReminderRow(reminder: reminder) {
                                editReminder(reminder)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
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
                    } header: {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.gray)
                            Text("已暂停/完成")
                                .font(.headline)
                            Spacer()
                            Text("\(inactiveReminders.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 4)
                    }
                }

                // Empty state section
                if reminders.isEmpty {
                    Section {
                        VStack(spacing: 24) {
                            // Animated icon
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "bell.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(AppColors.primary)
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)

                            VStack(spacing: 12) {
                                Text("开始使用\(AppConstants.appName)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("创建您的第一个提醒，让我们帮您更好地管理生活")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }

                            // Central floating button hint
                            Button(action: {
                                showingAddReminder = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    Text("创建第一个提醒")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(AppColors.primary)
                                        .shadow(color: AppColors.primaryShadow, radius: 8, x: 0, y: 4)
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(centralButtonScale)
                            .onAppear {
                                if reminders.isEmpty {
                                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                        centralButtonScale = 1.05
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 50)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.automatic)
            #endif
            .navigationTitle(AppConstants.appName)
            .toolbar {
#if os(iOS)
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingSettings = true }) {
                            Label("设置", systemImage: "gear")
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
            .sheet(item: $editingReminder) { reminder in
                AddReminderView(reminder: reminder)
            }

            // Floating Add Button for iOS
            #if os(iOS)
            if !reminders.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddReminder = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: AppColors.primaryShadow, radius: 10, x: 0, y: 5)

                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(showingAddReminder ? 45 : 0))
                            }
                        }
                        .scaleEffect(showingAddReminder ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingAddReminder)
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            #endif

#if os(macOS)
            .navigationSplitViewColumnWidth(min: 300, ideal: 350)
#endif
            }
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
            case .exercise:
                // Default to evening
                return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
            case .custom:
                return now
            }
        }()

        let repeatRule: RepeatRule = type == .medicine || type == .exercise ? .daily : .daily
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
        editingReminder = reminder
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

// MARK: - Reminder Card View
struct ReminderRow: View {
    let reminder: Reminder
    let onTap: () -> Void

    // 计算距离下次提醒的剩余时间
    private func timeUntil(_ date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)

        if interval <= 0 {
            return "现在"
        }

        let totalSeconds = Int(interval)
        let days = totalSeconds / (24 * 60 * 60)
        let hours = (totalSeconds % (24 * 60 * 60)) / (60 * 60)
        let minutes = (totalSeconds % (60 * 60)) / 60

        var components: [String] = []

        if days > 0 {
            components.append("\(days)天")
        }
        if hours > 0 {
            components.append("\(hours)小时")
        }
        if minutes > 0 {
            components.append("\(minutes)分钟")
        }

        if components.isEmpty {
            return "1分钟内"
        }

        return components.joined() + "后"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(AppColors.colorForType(reminder.type).opacity(0.15))
                            .frame(width: 50, height: 50)

                        Image(systemName: reminder.type.icon)
                            .font(.title3)
                            .foregroundColor(AppColors.colorForType(reminder.type))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        // Title with status
                        HStack {
                            Text(reminder.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Spacer()

                            // Status badge
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(reminder.isActive ? AppColors.colorForType(reminder.type) : AppColors.custom)
                                    .frame(width: 6, height: 6)

                                Text(reminder.isActive ? "进行中" : "已暂停")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(reminder.isActive ? AppColors.colorForType(reminder.type) : AppColors.custom)
                            }
                        }

                        // Time and repeat info
                        HStack(spacing: 12) {
                            // Time
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(reminder.timeOfDay, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Repeat rule
                            Label(reminder.repeatRule.description, systemImage: "repeat")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Next trigger with prominence
                            if let nextTrigger = reminder.nextTriggerDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "bell")
                                        .font(.caption)
                                    Text(timeUntil(nextTrigger))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.colorForType(reminder.type).opacity(0.1))
                                .foregroundColor(AppColors.colorForType(reminder.type))
                                .clipShape(Capsule())
                            }
                        }

                        // Notes if available
                        if let notes = reminder.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Bottom accent line
                Rectangle()
                    .fill(AppColors.colorForType(reminder.type))
                    .frame(height: 3)
                    .opacity(reminder.isActive ? 0.8 : 0.3)
            }
            #if os(iOS)
            .background(Color(.systemBackground))
            #else
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppColors.shadow, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)
    ContentView()
        .modelContainer(container)
}