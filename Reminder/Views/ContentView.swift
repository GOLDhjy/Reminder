//
//  ContentView.swift
//  Reminder
//
//  Created by 黄金溢 on 2025/12/6.
//

import SwiftUI
import SwiftData
import Combine

extension Optional {
    var isNil: Bool {
        return self == nil
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: NotificationManager
    @Query(sort: \Reminder.createdAt, order: .reverse) private var reminders: [Reminder]
    @State private var showingAddReminder = false
    @State private var showingAddTodo = false
    @State private var showingSettings = false
    @State private var selectedType: ReminderType?
    @State private var editingReminder: Reminder?
    @State private var todoEditReminder: Reminder?
    @State private var timerEditReminder: Reminder?
    @State private var showingTimerSheet = false
    @State private var showingCreateOptions = false
    @State private var isQuickEditMode = false

    private let useCustomList = true
    private let cleanupTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        wrapWithSheets(rootView)
            .overlay(alignment: .top) {
                if let banner = notificationManager.inAppBanner {
                    InAppBannerView(banner: banner) {
                        notificationManager.dismissInAppBanner()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: notificationManager.inAppBanner?.id)
            .task {
                cleanupExpiredOneTimeReminders()
            }
            .onChange(of: reminders) {
                cleanupExpiredOneTimeReminders()
            }
            .onReceive(cleanupTicker) { _ in
                cleanupExpiredOneTimeReminders()
            }
      }

    private var splitView: some View {
        NavigationSplitView {
            listContent
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    private var rootView: some View {
#if os(iOS)
        NavigationStack {
            listContent
            .navigationTitle(AppConstants.appName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingMenuiOS
                }
            }
        }
#else
        splitView
            .navigationTitle(AppConstants.appName)
            .navigationBarTitleDisplayMode(.large)
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 300, ideal: 350)
#endif
            .toolbar {
                toolbarItemsMac
            }
#endif
    }

#if os(iOS)
    @ViewBuilder
    private var iOSRoot: some View {
        if useCustomList {
            NavigationStack {
                listContent
                    .navigationTitle(AppConstants.appName)
                    .navigationBarTitleDisplayMode(.large)
            }
        } else {
            NavigationStack {
                splitView
            }
        }
    }
#else
    @ViewBuilder
    private var macRoot: some View {
        splitView
            .navigationTitle(AppConstants.appName)
            .navigationBarTitleDisplayMode(.large)
    }
#endif

    private var detailView: some View {
        Group {
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

    private var trailingMenuiOS: some View {
        Menu {
            Button {
                isQuickEditMode.toggle()
            } label: {
                Label(isQuickEditMode ? "退出编辑模式" : "编辑模式", systemImage: isQuickEditMode ? "checkmark.circle" : "pencil")
            }

            Button(action: { showingSettings = true }) {
                Label("设置", systemImage: "gear")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .tint(AppColors.primary)
    }

#if os(macOS)
    @ToolbarContentBuilder
    private var toolbarItemsMac: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: { showingSettings = true }) {
                Label("设置", systemImage: "gear")
            }

            Menu("快速添加") {
                ForEach(ReminderType.allCases.filter({ $0 != .custom && $0 != .todo && $0 != .timer }), id: \.self) { type in
                    Button(action: { quickAddReminder(type: type) }) {
                        Label(type.rawValue, systemImage: type.icon)
                    }
                }
            }

            Button(action: { showingAddReminder = true }) {
                Label("添加提醒", systemImage: "plus")
            }
        }
    }
#endif

    private func wrapWithSheets<Content: View>(_ content: Content) -> some View {
        content
            .sheet(isPresented: $showingAddReminder) {
                CreateReminderView()
            }
            .sheet(isPresented: $showingAddTodo) {
                CreateReminderView(initialMode: .todo)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingTimerSheet) {
                TimerTaskSheet()
            }
            .sheet(item: $editingReminder) { reminder in
                CreateReminderView(reminder: reminder)
            }
            .sheet(item: $timerEditReminder) { reminder in
                TimerTaskSheet(reminder: reminder)
            }
            .sheet(item: $todoEditReminder) { reminder in
                CreateReminderView(reminder: reminder)
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
                    },
                    onSelectTodo: {
                        showingCreateOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingAddTodo = true
                        }
                    }
                )
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

    // MARK: - List Variants
    @ViewBuilder
    private var listContent: some View {
#if os(iOS)
        if useCustomList {
            customListContent
        } else {
            legacyListContent
        }
#else
        legacyListContent
#endif
    }

    private var legacyListContent: some View {
        List {
            legacyFilterSection
            legacyTodoSection
            legacyActiveRemindersSection
            legacyInactiveRemindersSection
            legacyEmptyStateSection
        }
#if os(iOS)
        .listStyle(.plain)
        .listRowBackground(AppColors.formBackground)
        .scrollContentBackground(.hidden)
        .background(AppColors.formBackground)
#else
        .listStyle(.automatic)
#endif

        // Add bottom padding to avoid button overlap
        .padding(.bottom, 100)
    }

    @ViewBuilder
    private var legacyFilterSection: some View {
        if !selectedType.isNil {
            Section(header: Text("筛选：\(selectedType?.rawValue ?? "全部")")) {
                Button("清除筛选") {
                    selectedType = nil
                }
                .foregroundColor(AppColors.primary)
            }
        }
    }

    @ViewBuilder
    private var legacyTodoSection: some View {
        if !activeTodoReminders.isEmpty {
            Section {
                ForEach(activeTodoReminders) { reminder in
                    ReminderRow(
                        reminder: reminder,
                        onTap: { todoEditReminder = reminder },
                        onToggle: { deleteReminder(reminder) },
                        isQuickEditMode: isQuickEditMode,
                        onDelete: { deleteReminder(reminder) }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("删除", role: .destructive) {
                            deleteReminder(reminder)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button("完成") {
                            deleteReminder(reminder)
                        }
                        .tint(AppColors.todo)
                    }
                }
            } header: {
                SectionHeaderRow(
                    icon: "checkmark.circle.fill",
                    title: "待办事项",
                    count: activeTodoReminders.count,
                    tint: AppColors.todo
                )
            }
        }
    }

    @ViewBuilder
    private var legacyActiveRemindersSection: some View {
        if !activeTimedReminders.isEmpty {
            Section {
                ForEach(activeTimedReminders) { reminder in
                    let secondaryAction: (() -> Void)? = reminder.type == .timer ? { finishTimerTask(reminder) } : nil
                    ReminderRow(
                        reminder: reminder,
                        onTap: { editReminder(reminder) },
                        onToggle: { toggleReminder(reminder) },
                        onSecondaryAction: secondaryAction,
                        isQuickEditMode: isQuickEditMode,
                        onDelete: { deleteReminder(reminder) }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("删除", role: .destructive) {
                            deleteReminder(reminder)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button(reminder.type == .timer ? timerPrimaryActionTitle(for: reminder) : (reminder.isActive ? "暂停" : "启用")) {
                            toggleReminder(reminder)
                        }
                        .tint(reminder.isActive ? .orange : .green)
                    }
                }
            } header: {
                SectionHeaderRow(
                    icon: "bell.fill",
                    title: "进行中的提醒",
                    count: activeTimedReminders.count,
                    tint: AppColors.primary
                )
            }
        }
    }

    @ViewBuilder
    private var legacyInactiveRemindersSection: some View {
        if !inactiveTimedReminders.isEmpty {
            Section {
                ForEach(inactiveTimedReminders) { reminder in
                    let secondaryAction: (() -> Void)? = reminder.type == .timer ? { finishTimerTask(reminder) } : nil
                    ReminderRow(
                        reminder: reminder,
                        onTap: { editReminder(reminder) },
                        onToggle: { toggleReminder(reminder) },
                        onSecondaryAction: secondaryAction,
                        isQuickEditMode: isQuickEditMode,
                        onDelete: { deleteReminder(reminder) }
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
                        Button(reminder.type == .timer ? timerPrimaryActionTitle(for: reminder) : (reminder.isActive ? "暂停" : "启用")) {
                            toggleReminder(reminder)
                        }
                        .tint(reminder.isActive ? .orange : .green)
                    }
                }
            } header: {
                SectionHeaderRow(
                    icon: "pause.circle.fill",
                    title: "已暂停/完成",
                    count: inactiveTimedReminders.count,
                    tint: AppColors.custom
                )
            }
        }
    }

    @ViewBuilder
    private var legacyEmptyStateSection: some View {
        if reminders.isEmpty {
            Section {
                emptyStateCard
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private var customListContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // TODO 部分
                if !activeTodoReminders.isEmpty {
                    sectionBlock(
                        icon: "checkmark.circle.fill",
                        title: "待办事项",
                        tint: AppColors.todo,
                        reminders: activeTodoReminders
                    )
                }

                // 活跃的定时提醒
                if !activeTimedReminders.isEmpty {
                    sectionBlock(
                        icon: "bell.fill",
                        title: "进行中的提醒",
                        tint: AppColors.primary,
                        reminders: activeTimedReminders
                    )
                }

                // 已暂停的提醒
                if !inactiveTimedReminders.isEmpty {
                    sectionBlock(
                        icon: "pause.circle.fill",
                        title: "已暂停/完成",
                        tint: AppColors.custom,
                        reminders: inactiveTimedReminders
                    )
                }

                if reminders.isEmpty {
                    emptyStateCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)  // Add bottom padding to avoid button overlap
        }
        .background(AppColors.formBackground.ignoresSafeArea())
    }

    private var filterCard: some View {
        HStack {
            Text("筛选：\(selectedType?.rawValue ?? "全部")")
                .foregroundColor(.primary)
            Spacer()
            Button("清除筛选") {
                selectedType = nil
            }
            .foregroundColor(AppColors.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
        )
    }

    private func sectionBlock(icon: String, title: String, tint: Color, reminders: [Reminder]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderRow(
                icon: icon,
                title: title,
                count: reminders.count,
                tint: tint
            )

            VStack(spacing: 8) {
                ForEach(reminders) { reminder in
                    sectionRowView(for: reminder)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionRowView(for reminder: Reminder) -> some View {
        let secondaryAction: (() -> Void)? = reminder.type == .timer ? { finishTimerTask(reminder) } : nil

        ReminderRow(
            reminder: reminder,
            onTap: { handleSectionTap(reminder) },
            onToggle: { handleSectionToggle(reminder) },
            onSecondaryAction: secondaryAction,
            isQuickEditMode: isQuickEditMode,
            onDelete: { deleteReminder(reminder) }
        )
        .contextMenu {
            sectionContextMenu(for: reminder)
        }
    }

    private func handleSectionTap(_ reminder: Reminder) {
        if reminder.type == .todo {
            todoEditReminder = reminder
        } else if reminder.type == .timer {
            timerEditReminder = reminder
        } else {
            editReminder(reminder)
        }
    }

    private func handleSectionToggle(_ reminder: Reminder) {
        if reminder.type == .todo {
            deleteReminder(reminder)
        } else {
            toggleReminder(reminder)
        }
    }

    @ViewBuilder
    private func sectionContextMenu(for reminder: Reminder) -> some View {
        if reminder.type == .todo {
            Button("编辑") {
                todoEditReminder = reminder
            }
            Button("完成") {
                deleteReminder(reminder)
            }
        } else if reminder.type == .timer {
            Button(timerPrimaryActionTitle(for: reminder)) {
                toggleReminder(reminder)
            }
            if reminder.isActive || reminder.timerPausedRemaining != nil {
                Button("结束") {
                    finishTimerTask(reminder)
                }
            }
            Button("编辑计时") {
                timerEditReminder = reminder
            }
        } else {
            Button(reminder.isActive ? "暂停" : "启用") {
                toggleReminder(reminder)
            }
            Button("编辑") {
                editReminder(reminder)
            }
        }
        Button("删除", role: .destructive) {
            deleteReminder(reminder)
        }
    }

    private var emptyStateCard: some View {
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
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
        )
    }

    // TODO 事项（活跃的）
    private var activeTodoReminders: [Reminder] {
        let filtered = reminders.filter { $0.type == .todo && $0.isActive }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    // 有时间的提醒（活跃的）
    private var activeTimedReminders: [Reminder] {
        let filtered = reminders.filter { $0.isActive && $0.type != .todo }
        let typeFiltered = if let selectedType = selectedType {
            filtered.filter { $0.type == selectedType }
        } else {
            filtered
        }
        return typeFiltered.sorted { reminder1, reminder2 in
            let date1 = reminder1.nextTriggerDate ?? Date.distantFuture
            let date2 = reminder2.nextTriggerDate ?? Date.distantFuture
            return date1 < date2
        }
    }

    // 有时间的提醒（已暂停/完成的）
    private var inactiveTimedReminders: [Reminder] {
        let filtered = reminders.filter { !$0.isActive && $0.type != .todo }
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
            case .todo:
                // Should not reach here since we filter out todo in quickAddReminder
                return now
            case .timer:
                // Should not reach here since we filter out timer in quickAddReminder
                return now
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
        // 如果是 TODO 类型，完成时直接删除
        if reminder.type == .todo && reminder.isActive {
            deleteReminder(reminder)
            return
        }

        if reminder.type == .timer {
            if reminder.isActive {
                reminder.pauseTimer()
            } else if reminder.timerPausedRemaining != nil {
                reminder.resumeTimer()
            } else {
                reminder.restartTimer()
            }
            saveAndSchedule(reminder: reminder)
            return
        }

        let willActivate = !reminder.isActive
        reminder.isActive.toggle()
        reminder.updatedAt = Date()

        // If re-activating a一次性提醒，推到未来的合适时间
        if willActivate, case .never = reminder.repeatRule {
            normalizeOneTimeReminder(reminder)
        }

        saveAndSchedule(reminder: reminder)
    }

    private func finishTimerTask(_ reminder: Reminder) {
        reminder.finishTimer()
        saveAndSchedule(reminder: reminder)
    }

    private func timerPrimaryActionTitle(for reminder: Reminder) -> String {
        if reminder.isActive {
            return "暂停"
        }
        if reminder.timerPausedRemaining != nil {
            return "继续"
        }
        return "重新开始"
    }

    private func normalizeOneTimeReminder(_ reminder: Reminder) {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let targetToday = calendar.date(
            bySettingHour: calendar.component(.hour, from: reminder.timeOfDay),
            minute: calendar.component(.minute, from: reminder.timeOfDay),
            second: 0,
            of: today
        ) ?? now

        if targetToday > now {
            reminder.startDate = targetToday
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: targetToday) {
            reminder.startDate = tomorrow
        } else {
            reminder.startDate = now
        }
        reminder.endDate = nil
    }

    private func cleanupExpiredOneTimeReminders() {
        let expired = reminders.filter { reminder in
            guard reminder.isActive else { return false }
            // Skip TODO types - they don't have trigger dates
            guard reminder.type != .todo else { return false }
            guard case .never = reminder.repeatRule else { return false }
            return reminder.nextTriggerDate == nil
        }

        guard !expired.isEmpty else { return }

        if let firstTimer = expired.first(where: { $0.type == .timer }) {
            notificationManager.presentInAppBanner(
                title: firstTimer.title,
                message: "计时结束了！",
                kind: .timer,
                reminderID: firstTimer.id
            )
        }

        for reminder in expired {
            reminder.isActive = false
            if reminder.type == .timer {
                reminder.timerPausedRemaining = nil
            }
            reminder.notificationID = nil
            reminder.updatedAt = Date()
        }

        try? modelContext.save()
    }

    private func deleteReminder(_ reminder: Reminder) {
        // Cancel notification first
        NotificationManager.shared.cancelNotification(for: reminder)

        // Delete from database
        modelContext.delete(reminder)
        try? modelContext.save()
    }

    private func editReminder(_ reminder: Reminder) {
        editingReminder = reminder
    }

    private func saveAndSchedule(reminder: Reminder) {
        do {
            try modelContext.save()
            // 对于 TODO 类型，不需要调度通知
            if reminder.type != .todo {
                Task {
                    if reminder.isActive {
                        try await NotificationManager.shared.scheduleNotification(for: reminder)
                    } else {
                        NotificationManager.shared.cancelNotification(for: reminder)
                    }
                }
            }
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
}

// MARK: - Simple TODO Row
struct SimpleTodoRow: View {
    let reminder: Reminder
    let onComplete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)

                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("创建于 \(reminder.createdAt, format: .dateTime.month().day().hour().minute())")
                    .font(.caption2)
                    .foregroundColor(AppColors.todo)
            }

            Spacer()

            Button(action: onComplete) {
                Image(systemName: "square")
                    .foregroundColor(AppColors.todo)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reminder Card View
struct ReminderRow: View {
    let reminder: Reminder
    let onTap: () -> Void
    let onToggle: () -> Void
    let onSecondaryAction: (() -> Void)?
    let isQuickEditMode: Bool
    let onDelete: (() -> Void)?

    init(
        reminder: Reminder,
        onTap: @escaping () -> Void,
        onToggle: @escaping () -> Void,
        onSecondaryAction: (() -> Void)? = nil,
        isQuickEditMode: Bool = false,
        onDelete: (() -> Void)? = nil
    ) {
        self.reminder = reminder
        self.onTap = onTap
        self.onToggle = onToggle
        self.onSecondaryAction = onSecondaryAction
        self.isQuickEditMode = isQuickEditMode
        self.onDelete = onDelete
    }

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

    private func formattedTimerDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(1, Int((seconds / 60).rounded()))
        if totalMinutes < 60 {
            return "\(totalMinutes)分钟"
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours)小时"
        }
        return "\(hours)小时\(minutes)分钟"
    }

    private func formattedCountdown(_ seconds: TimeInterval) -> String {
        let clamped = max(0, Int(seconds))
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    @ViewBuilder
    private func timerBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.monospacedDigit())
            .foregroundColor(AppColors.timer)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.timer.opacity(0.12))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var timerStatusBadge: some View {
        if reminder.timerPausedRemaining != nil, let remaining = reminder.timerPausedRemaining {
            timerBadge("暂停 \(formattedCountdown(remaining))")
        } else if reminder.isActive {
            let target = reminder.endDate ?? reminder.timeOfDay
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = target.timeIntervalSince(context.date)
                if remaining > 0 {
                    timerBadge(formattedCountdown(remaining))
                } else {
                    timerBadge("已完成")
                }
            }
        } else {
            timerBadge("已完成")
        }
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
                HStack(spacing: 4) {
                    if reminder.type == .timer {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundColor(AppColors.timer)
                    }
                    Text(reminder.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                    // 如果是 TODO 类型，显示不同的信息
                    if reminder.type == .todo {
                        if let notes = reminder.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Text("创建于 \(reminder.createdAt, format: .dateTime.month().day())")
                            .font(.caption2)
                            .foregroundColor(AppColors.todo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.todo.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        if reminder.type == .timer {
                            HStack(spacing: 8) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("计时 \(formattedTimerDuration(reminder.timerDurationSeconds))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let endDate = reminder.endDate {
                                    Text("·")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(endDate, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            timerStatusBadge
                        } else {
                            // 原有的时间提醒显示逻辑
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
                    }
                }

                Spacer()

                // 根据类型显示不同的控件
                if isQuickEditMode {
                    HStack(spacing: 10) {
                        Button(action: onTap) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("编辑")

                        Button(role: .destructive) {
                            onDelete?()
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("删除")
                    }
                } else if reminder.type == .todo {
                    // TODO 类型显示勾选框
                    Button(action: onToggle) {
                        Image(systemName: "square")
                            .foregroundColor(AppColors.todo)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                } else if reminder.type == .timer {
                    HStack(spacing: 10) {
                        Button(action: onToggle) {
                            Image(systemName: reminder.isActive ? "pause.circle.fill" : (reminder.timerPausedRemaining != nil ? "play.circle.fill" : "arrow.clockwise.circle.fill"))
                                .foregroundColor(AppColors.timer)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        if reminder.isActive || reminder.timerPausedRemaining != nil {
                            Button(action: { onSecondaryAction?() }) {
                                Image(systemName: "stop.circle.fill")
                                    .foregroundColor(AppColors.timer)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("结束计时")
                        }
                    }
                } else {
                    // 其他类型显示 Toggle
                    Toggle("", isOn: toggleBinding)
                        .labelsHidden()
                        .tint(AppColors.primary)
                }
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
    let onSelectTodo: () -> Void

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
                    title: "计时任务",
                    subtitle: "倒计时提醒",
                    systemImage: "timer",
                    tint: AppColors.timer,
                    action: onSelectTimer
                )

                CreateOptionCard(
                    title: "时间提醒",
                    subtitle: "自定义时间",
                    systemImage: "plus.circle",
                    tint: AppColors.primary,
                    action: onSelectReminder
                )

                CreateOptionCard(
                    title: "待办事项",
                    subtitle: "无时间提醒的任务",
                    systemImage: "checkmark.circle",
                    tint: AppColors.todo,
                    action: onSelectTodo
                )
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.bottom, 20)
        .background(AppColors.background)
        .presentationDetents([.medium, .fraction(0.65)])
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
