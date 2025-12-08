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
    @State private var userEditedTitle = false
    @State private var autoTitle: String? = ""

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
        _userEditedTitle = State(initialValue: true)
    }

    var body: some View {
#if os(iOS)
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard

                        typeGridSection
                        titleSection
                        repeatChipsSection
                        timeCardSection
                        notesSection
                        quickTemplatesSection

                        saveButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
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
            .sheet(isPresented: $showingTimePicker) {
                TimePickerView(selectedTime: $selectedTime)
            }
            .sheet(isPresented: $showingRepeatOptions) {
                RepeatRulePickerView(selectedRule: $selectedRepeatRule)
            }
        }
#else
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text(navigationTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)

            Form {
                basicInfoSection
                timeSettingsSection
                repeatSettingsSection
                quickTemplatesSection
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .listRowBackground(AppColors.cardBackground)
            .background(AppColors.formBackground)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

            Spacer()

            // Buttons
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button(isEditing ? "更新" : "保存") {
                    if isEditing {
                        updateReminder()
                    } else {
                        saveReminder()
                    }
                }
                .disabled(title.isEmpty)
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(selectedTime: $selectedTime)
        }
        .sheet(isPresented: $showingRepeatOptions) {
            RepeatRulePickerView(selectedRule: $selectedRepeatRule)
        }
#endif
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
            ),
            ReminderTemplate(
                title: "做饭计时",
                description: "比如煮面、炖汤 20 分钟",
                type: .cooking,
                time: Date(),
                repeatRule: .never,
                notes: "记得关火"
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
        return AppColors.colorForType(type)
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

// MARK: - iOS Styled Sections
private extension AddReminderView {
    var headerCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.18))
                    .frame(width: 72, height: 72)
                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                Image(systemName: "leaf.fill")
                    .foregroundColor(AppColors.primary)
                    .font(.title2.weight(.bold))
            }
            Text(navigationTitle)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text("设置任务名称、重复规则和时间")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardElevated)
        )
        .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)
    }

    var typeGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("任务类型")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                        applyAutoTitleIfNeeded(for: type)
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.headline)
                                .foregroundColor(AppColors.colorForType(type))
                            Text(type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedType == type ? AppColors.colorForType(type).opacity(0.15) : AppColors.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedType == type ? AppColors.colorForType(type) : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                }
            }
        }
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("任务名称")
                .font(.headline)
                .foregroundColor(.primary)

            TextField("例如：运动一下", text: $title)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .onChange(of: title) { newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        userEditedTitle = false
                    } else if trimmed != autoTitle {
                        userEditedTitle = true
                    }
                }
        }
    }

    var repeatChipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("重复规则")
                .font(.headline)
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RepeatRule.allCases, id: \.self) { rule in
                        Button {
                            selectedRepeatRule = rule
                            showingRepeatOptions = (rule != .never && rule != .daily && {
                                if case .weekly = rule { return false }
                                if case .monthly = rule { return false }
                                if case .yearly = rule { return false }
                                return true
                            }())
                        } label: {
                            Text(rule.shortDescription)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(rule == selectedRepeatRule ? AppColors.primary.opacity(0.15) : AppColors.cardBackground)
                                )
                                .overlay(
                                    Capsule().stroke(rule == selectedRepeatRule ? AppColors.primary : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showingRepeatOptions = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(AppColors.cardBackground)
                            )
                            .overlay(
                                Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var timeCardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("提醒时间")
                .font(.headline)
                .foregroundColor(.primary)

            Button {
                showingTimePicker = true
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppColors.primary)
                    Text(selectedTime, style: .time)
                        .font(.title2).fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardElevated)
                )
                .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("开始日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }

                Divider().frame(height: 44)

                Toggle("结束日期", isOn: $hasEndDate)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))

                if hasEndDate {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }

    var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.headline)
                .foregroundColor(.primary)

            TextField("补充说明（可选）", text: $notes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        }
    }

    var saveButton: some View {
        Button {
            if isEditing { updateReminder() } else { saveReminder() }
        } label: {
            Text(isEditing ? "保存修改" : "种下控桩")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.primary)
                )
                .shadow(color: AppColors.primary.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .padding(.top, 8)
        .buttonStyle(.plain)
        .disabled(title.isEmpty)
        .opacity(title.isEmpty ? 0.5 : 1)
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
#if os(iOS)
        NavigationStack {
            VStack {
                DatePicker(
                    "选择时间",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("选择时间")
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
        }
#else
        VStack(spacing: 30) {
            Text("选择时间")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)

            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.stepperField)
            .labelsHidden()
            .frame(maxWidth: 300)
            .padding(.horizontal, 40)

            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("确定") {
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 200)
#endif
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
#if os(iOS)
        NavigationStack {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
#else
        VStack(spacing: 20) {
            Text("选择重复规则")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)

            ScrollView {
                VStack(spacing: 16) {
                    // 预设选项
                    VStack(spacing: 8) {
                        Text("预设选项")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        ForEach([RepeatRule.never, RepeatRule.daily], id: \.self) { rule in
                            Button(action: {
                                selectedRule = rule
                                dismiss()
                            }) {
                                HStack {
                                    Text(rule.description)
                                        .font(.body)
                                    Spacer()
                                    if selectedRule == rule {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedRule == rule ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedRule == rule ? 2 : 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // 每周选项
                    VStack(spacing: 8) {
                        Text("每周")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                        Button(action: {
                            selectedRule = .weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
                            dismiss()
                        }) {
                            HStack {
                                Text("工作日（周一到周五）")
                                    .font(.body)
                                Spacer()
                                if selectedRule == .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedRule == .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]) ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedRule == .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]) ? 2 : 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            selectedRule = .weekly([.saturday, .sunday])
                            dismiss()
                        }) {
                            HStack {
                                Text("周末（周六和周日）")
                                    .font(.body)
                                Spacer()
                                if selectedRule == .weekly([.saturday, .sunday]) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedRule == .weekly([.saturday, .sunday]) ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedRule == .weekly([.saturday, .sunday]) ? 2 : 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // 每月选项
                    VStack(spacing: 8) {
                        Text("每月")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                        Menu {
                            ForEach(1...31, id: \.self) { day in
                                Button("\(day)日") {
                                    selectedRule = .monthly(day)
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                Text("每月第几天")
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(maxHeight: 350)

            Divider()
                .padding(.vertical, 10)

            // 取消按钮
            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: 450, height: 520)
#endif
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
