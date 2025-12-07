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
    @State private var showingTimerSheet = false
    @State private var showingCreateOptions = false

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
                            ReminderRow(
                                reminder: reminder,
                                onTap: { editReminder(reminder) },
                                onToggle: { toggleReminder(reminder) }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
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
                        SectionHeaderRow(
                            icon: "bell.fill",
                            title: "进行中的提醒",
                            count: activeReminders.count,
                            tint: AppColors.primary
                        )
                    }
                }

                // Completed/Inactive Reminders
                if !inactiveReminders.isEmpty {
                    Section {
                        ForEach(inactiveReminders) { reminder in
                            ReminderRow(
                                reminder: reminder,
                                onTap: { editReminder(reminder) },
                                onToggle: { toggleReminder(reminder) }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
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
                        SectionHeaderRow(
                            icon: "pause.circle.fill",
                            title: "已暂停/完成",
                            count: inactiveReminders.count,
                            tint: AppColors.custom
                        )
                    }
                }

                // Empty state section
                if reminders.isEmpty {
                    Section {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.1))
                                    .frame(width: 110, height: 110)
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.primary)
                            }

                            VStack(spacing: 10) {
                                Text("开始使用\(AppConstants.appName)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("创建您的第一个提醒，让我们帮您更好地管理生活")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            #if os(iOS)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            #else
            .listStyle(.automatic)
            #endif
            .navigationTitle(AppConstants.appName)
            .toolbar {
#if os(iOS)
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingTimerSheet = true }) {
                            Label("定时任务", systemImage: "timer")
                        }

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

                    Button(action: { showingTimerSheet = true }) {
                        Label("定时任务", systemImage: "timer")
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
            .sheet(isPresented: $showingTimerSheet) {
                TimerTaskSheet()
            }
            .sheet(item: $editingReminder) { reminder in
                AddReminderView(reminder: reminder)
            }
            .sheet(isPresented: $showingCreateOptions) {
                CreateChooserSheet(
                    onSelectTimer: {
                        showingCreateOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingTimerSheet = true
                        }
                    },
                    onSelectReminder: {
                        showingCreateOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingAddReminder = true
                        }
                    }
                )
            }

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
        // Bottom primary action
        .safeAreaInset(edge: .bottom) {
            Button {
                showingCreateOptions = true
            } label: {
                Text("＋ 新建提醒")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppColors.primary)
                    )
                    .padding(.horizontal, 20)
                    .shadow(color: AppColors.primary.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)
            .padding(.top, 6)
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
            case .cooking:
                // Default to current time for immediate cooking timers
                return now
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
    let onToggle: () -> Void

    // 计算距离下次提醒的剩余时间
    private func timeUntil(_ date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)

        if interval <= 0 {
            return "现在"
        }

        let totalSeconds = Int(interval)
        let hours = (totalSeconds % (24 * 60 * 60)) / (60 * 60)
        let minutes = (totalSeconds % (60 * 60)) / 60

        if hours > 0 {
            return "\(hours)小时\(minutes)分后"
        }
        return "\(minutes)分钟后"
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { reminder.isActive },
            set: { _ in onToggle() }
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.colorForType(reminder.type).opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: reminder.type.icon)
                        .foregroundColor(AppColors.colorForType(reminder.type))
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(reminder.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(reminder.repeatRule.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(reminder.timeOfDay, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let nextTrigger = reminder.nextTriggerDate {
                        Text(timeUntil(nextTrigger))
                            .font(.caption2)
                            .foregroundColor(AppColors.colorForType(reminder.type))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.colorForType(reminder.type).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Toggle("", isOn: toggleBinding)
                    .labelsHidden()
                    .tint(AppColors.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .onTapGesture {
            onTap()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    // Deprecated placeholder to avoid unused struct - kept empty intentionally
    var body: some View { EmptyView() }
}

// MARK: - Create Chooser Sheet
private struct CreateChooserSheet: View {
    let onSelectTimer: () -> Void
    let onSelectReminder: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            Text("创建类型")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                CreateOptionCard(
                    title: "定时任务",
                    subtitle: "倒计时提醒",
                    systemImage: "timer",
                    tint: AppColors.warning,
                    action: onSelectTimer
                )

                CreateOptionCard(
                    title: "添加提醒",
                    subtitle: "自定义时间",
                    systemImage: "plus.circle",
                    tint: AppColors.primary,
                    action: onSelectReminder
                )
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.bottom, 20)
        .background(AppColors.background)
        .presentationDetents([.medium, .fraction(0.55)])
    }
}

private struct CreateOptionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tint.opacity(0.18))
                        .frame(width: 46, height: 46)
                    Image(systemName: systemImage)
                        .foregroundColor(tint)
                        .font(.title2.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct SectionHeaderRow: View {
    let icon: String
    let title: String
    let count: Int
    let tint: Color

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(tint)
            }

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(tint)
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardElevated)
        )
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)
    ContentView()
        .modelContainer(container)
}
