//
//  AddReminderView.swift
//  Reminder
//
//  Created by 黄金溢 on 2025/12/6.
//

import SwiftUI
import SwiftData

struct AddReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var reminder: Reminder?

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedType: ReminderType = .custom
    @State private var selectedTime = Date()
    @State private var selectedRepeatRule: RepeatRule = .daily
    @State private var excludeHolidays = false
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var selectedWeekdays: Set<Weekday> = []

    @State private var showingTimePicker = false
    @State private var showingRepeatOptions = false

    private var isEditing: Bool {
        reminder != nil
    }

    private var navigationTitle: String {
        isEditing ? "编辑提醒" : "添加提醒"
    }

    init() {
        self.reminder = nil
    }

    init(reminder: Reminder) {
        self.reminder = reminder

        // Initialize state with existing reminder values
        _title = State(initialValue: reminder.title)
        _notes = State(initialValue: reminder.notes ?? "")
        _selectedType = State(initialValue: reminder.type)
        _selectedTime = State(initialValue: reminder.timeOfDay)
        _selectedRepeatRule = State(initialValue: reminder.repeatRule)
        _excludeHolidays = State(initialValue: reminder.excludeHolidays)
        _startDate = State(initialValue: reminder.startDate)

        if let endDate = reminder.endDate {
            _hasEndDate = State(initialValue: true)
            _endDate = State(initialValue: endDate)
        }

        if case .weekly(let weekdays) = reminder.repeatRule {
            _selectedWeekdays = State(initialValue: Set(weekdays))
        }
    }

    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                timeSettingsSection
                repeatSettingsSection
                quickTemplatesSection
            }
            .navigationTitle(navigationTitle)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "更新" : "保存") {
                        if isEditing {
                            updateReminder()
                        } else {
                            saveReminder()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
#else
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("取消") {
                        dismiss()
                    }
                    Button("保存") {
                        saveReminder()
                    }
                    .disabled(title.isEmpty)
                }
            }
#endif
            .sheet(isPresented: $showingTimePicker) {
                TimePickerView(selectedTime: $selectedTime)
            }
            .sheet(isPresented: $showingRepeatOptions) {
                RepeatRulePickerView(selectedRule: $selectedRepeatRule)
            }
        }
    }

    private var quickTemplates: [ReminderTemplate] {
        [
            ReminderTemplate(
                title: "喝水提醒",
                description: "每2小时提醒一次",
                type: .water,
                time: Date(),
                repeatRule: .daily,
                notes: "保持水分，有益健康"
            ),
            ReminderTemplate(
                title: "午休提醒",
                description: "工作日中午休息",
                type: .rest,
                time: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()) ?? Date(),
                repeatRule: .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]),
                notes: "适当休息，提高效率"
            ),
            ReminderTemplate(
                title: "睡觉提醒",
                description: "每晚10点提醒",
                type: .sleep,
                time: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
                repeatRule: .daily,
                notes: "早睡早起，身体好"
            ),
            ReminderTemplate(
                title: "吃药提醒",
                description: "每天早晚各一次",
                type: .medicine,
                time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                repeatRule: .daily,
                notes: "按时服药，遵医嘱"
            )
        ]
    }

    private func applyTemplate(_ template: ReminderTemplate) {
        title = template.title
        selectedType = template.type
        selectedTime = template.time
        selectedRepeatRule = template.repeatRule
        notes = template.notes
    }

    private func saveReminder() {
        let reminder = Reminder(
            title: title,
            type: selectedType,
            timeOfDay: selectedTime,
            repeatRule: selectedRepeatRule,
            notes: notes.isEmpty ? nil : notes
        )
        reminder.startDate = startDate
        reminder.excludeHolidays = excludeHolidays

        if hasEndDate {
            reminder.endDate = endDate
        }

        modelContext.insert(reminder)

        do {
            try modelContext.save()

            // Schedule notification
            Task {
                try await NotificationManager.shared.scheduleNotification(for: reminder)
            }

            dismiss()
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }

    private func updateReminder() {
        guard let reminder = reminder else { return }

        // Update properties
        reminder.title = title
        reminder.notes = notes.isEmpty ? nil : notes
        reminder.type = selectedType
        reminder.timeOfDay = selectedTime
        reminder.repeatRule = selectedRepeatRule
        reminder.excludeHolidays = excludeHolidays
        reminder.startDate = startDate
        reminder.updatedAt = Date()

        if hasEndDate {
            reminder.endDate = endDate
        } else {
            reminder.endDate = nil
        }

        do {
            try modelContext.save()

            // Reschedule notification
            Task {
                if reminder.isActive {
                    try await NotificationManager.shared.scheduleNotification(for: reminder)
                } else {
                    NotificationManager.shared.cancelNotification(for: reminder)
                }
            }

            dismiss()
        } catch {
            print("Failed to update reminder: \(error)")
        }
    }

    private var basicInfoSection: some View {
        Section(header: Text("基本信息")) {
            // Title
            TextField("提醒标题", text: $title)
#if os(iOS)
                .textInputAutocapitalization(.words)
#endif

            // Type Selection
            Picker("提醒类型", selection: $selectedType) {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(colorForType(type))
                        Text(type.rawValue)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())

            // Notes
            TextField("备注（可选）", text: $notes, axis: .vertical)
                .lineLimit(3)
        }
    }

    private var timeSettingsSection: some View {
        Section(header: Text("时间设置")) {
            // Time Picker
            HStack {
                Text("提醒时间")
                Spacer()
                Button(selectedTime.formatted(date: .omitted, time: .shortened)) {
                    showingTimePicker = true
                }
                .foregroundColor(.blue)
            }

            // Start Date
            DatePicker("开始日期", selection: $startDate, displayedComponents: .date)

            // End Date (Optional)
            Toggle("设置结束日期", isOn: $hasEndDate)
            if hasEndDate {
                DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
            }
        }
    }

    private var repeatSettingsSection: some View {
        Section(header: Text("重复设置")) {
            // Repeat Rule
            HStack {
                Text("重复规则")
                Spacer()
                Button(selectedRepeatRule.description) {
                    showingRepeatOptions = true
                }
                .foregroundColor(.blue)
            }

            // Holiday Exclusion
            Toggle("排除节假日", isOn: $excludeHolidays)
        }
    }

    private var quickTemplatesSection: some View {
        Section(header: Text("快速模板")) {
            ForEach(quickTemplates, id: \.title) { template in
                Button(action: {
                    applyTemplate(template)
                }) {
                    HStack {
                        Image(systemName: template.type.icon)
                            .foregroundColor(colorForType(template.type))
                        VStack(alignment: .leading) {
                            Text(template.title)
                                .font(.headline)
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
            }
        }
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

// MARK: - Reminder Template
struct ReminderTemplate {
    let title: String
    let description: String
    let type: ReminderType
    let time: Date
    let repeatRule: RepeatRule
    let notes: String
}

// MARK: - Time Picker View
struct TimePickerView: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择时间",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
#if os(iOS)
                .datePickerStyle(.wheel)
                .labelsHidden()
#else
                .datePickerStyle(.field)
                .labelsHidden()
#endif
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("选择时间")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        dismiss()
                    }
                }
            }
#else
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("取消") {
                        dismiss()
                    }
                    Button("确定") {
                        dismiss()
                    }
                }
            }
#endif
        }
    }
}

// MARK: - Repeat Rule Picker View
struct RepeatRulePickerView: View {
    @Binding var selectedRule: RepeatRule
    @Environment(\.dismiss) private var dismiss

    @State private var customWeeklySelection: Set<Weekday> = []
    @State private var monthlyDay = 1
    @State private var yearlyMonth = 1
    @State private var yearlyDay = 1

    
    var body: some View {
        NavigationView {
            Form {
                Section("预设选项") {
                    ForEach([RepeatRule.never, RepeatRule.daily], id: \.self) { rule in
                        Button(action: {
                            selectedRule = rule
                            dismiss()
                        }) {
                            HStack {
                                Text(rule.description)
                                Spacer()
                                if selectedRule == rule {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section(header: Text("每周")) {
                    Button(action: {
                        selectedRule = .weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
                        dismiss()
                    }) {
                        HStack {
                            Text("工作日（周一到周五）")
                            Spacer()
                            if selectedRule == .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    Button(action: {
                        selectedRule = .weekly([.saturday, .sunday])
                        dismiss()
                    }) {
                        HStack {
                            Text("周末（周六和周日）")
                            Spacer()
                            if selectedRule == .weekly([.saturday, .sunday]) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section("每月") {
                    Menu("每月第几天") {
                        ForEach(1...31, id: \.self) { day in
                            Button("\(day)日") {
                                selectedRule = .monthly(day)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("重复规则")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
#else
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
#endif
        }
    }
}

// MARK: - Weekly Repeat View
struct WeeklyRepeatView: View {
    @Binding var selectedWeekdays: Set<Weekday>
    let onComplete: (Set<Weekday>) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(Weekday.allCases, id: \.self) { weekday in
                Button(action: {
                    if selectedWeekdays.contains(weekday) {
                        selectedWeekdays.remove(weekday)
                    } else {
                        selectedWeekdays.insert(weekday)
                    }
                }) {
                    HStack {
                        Text(weekday.name)
                        Spacer()
                        if selectedWeekdays.contains(weekday) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("选择星期")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("确定") {
                    onComplete(selectedWeekdays)
                }
                .disabled(selectedWeekdays.isEmpty)
            }
        }
#else
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("取消") {
                    dismiss()
                }
                Button("确定") {
                    onComplete(selectedWeekdays)
                }
                .disabled(selectedWeekdays.isEmpty)
            }
        }
#endif
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)
    AddReminderView()
        .modelContainer(container)
}