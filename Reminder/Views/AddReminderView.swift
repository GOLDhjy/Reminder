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
    var isTodoMode: Bool = false

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
    @State private var customIntervalMinutes = 30
    @State private var useCustomInterval = false
    @State private var lastNonIntervalRule: RepeatRule = .daily

    @State private var showingTimePicker = false
    @State private var showingRepeatOptions = false

    private var isEditing: Bool {
        reminder != nil
    }

    private var navigationTitle: String {
        if isEditing {
            return "编辑提醒"
        } else if isTodoMode {
            return "添加待办事项"
        } else {
            return "添加提醒"
        }
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

        if case .intervalMinutes(let minutes) = reminder.repeatRule {
            _customIntervalMinutes = State(initialValue: minutes)
            _useCustomInterval = State(initialValue: true)
        } else {
            _lastNonIntervalRule = State(initialValue: reminder.repeatRule)
        }

        if let endDate = reminder.endDate {
            _hasEndDate = State(initialValue: true)
            _endDate = State(initialValue: endDate)
        }

        if case .weekly(let weekdays) = reminder.repeatRule {
            _selectedWeekdays = State(initialValue: Set(weekdays))
        }
        _userEditedTitle = State(initialValue: true)
    }

    init(isTodoMode: Bool) {
        self.reminder = nil
        self.isTodoMode = isTodoMode

        if isTodoMode {
            _selectedType = State(initialValue: .todo)
            _selectedRepeatRule = State(initialValue: .never)
        }
    }

    init(reminder: Reminder, isTodoMode: Bool) {
        self.reminder = reminder
        self.isTodoMode = isTodoMode

        // Initialize state with existing reminder values
        _title = State(initialValue: reminder.title)
        _notes = State(initialValue: reminder.notes ?? "")
        _selectedType = State(initialValue: reminder.type)
        _selectedTime = State(initialValue: reminder.timeOfDay)
        _selectedRepeatRule = State(initialValue: reminder.repeatRule)
        _excludeHolidays = State(initialValue: reminder.excludeHolidays)
        _startDate = State(initialValue: reminder.startDate)
        _endDate = State(initialValue: reminder.endDate ?? Date())
        _hasEndDate = State(initialValue: reminder.endDate != nil)
        _userEditedTitle = State(initialValue: true)

        // Handle weekdays for weekly repeat rule
        if case .weekly(let weekdays) = reminder.repeatRule {
            _selectedWeekdays = State(initialValue: Set(weekdays))
        }
    }

    var body: some View {
#if os(iOS)
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard

                        if !isTodoMode {
                            quickTemplatesSection
                            typeGridSection
                            titleSection
                            notesSection
                            repeatChipsSection
                            timeCardSection
                        } else {
                            titleSection
                            notesSection
                        }

                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 50)
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        if isEditing {
                            updateReminder()
                        } else {
                            saveReminder()
                        }
                    } label: {
                        Text(isEditing ? "更新提醒" : "创建提醒")
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
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.5 : 1)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTimePicker) {
                TimePickerView(selectedTime: $selectedTime)
            }
            .sheet(isPresented: $showingRepeatOptions) {
                RepeatRulePickerView(selectedRule: $selectedRepeatRule)
            }
            .onAppear {
                syncCustomIntervalFromRule()
            }
            .onChange(of: selectedRepeatRule) { _ in
                syncCustomIntervalFromRule()
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
                title: "9点吃药",
                icon: "pills.fill",
                type: .medicine,
                time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
                repeatRule: .daily
            ),
            ReminderTemplate(
                title: "22点睡觉",
                icon: "bed.double.fill",
                type: .sleep,
                time: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date(),
                repeatRule: .daily
            ),
            ReminderTemplate(
                title: "13点午休",
                icon: "figure.seated.side",
                type: .rest,
                time: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()) ?? Date(),
                repeatRule: .weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
            ),
            ReminderTemplate(
                title: "18点运动",
                icon: "figure.run",
                type: .exercise,
                time: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
                repeatRule: .daily
            )
        ]
    }

    private func applyTemplate(_ template: ReminderTemplate) {
        title = template.title
        selectedType = template.type
        selectedTime = template.time ?? Date()
        selectedRepeatRule = template.repeatRule ?? .daily
        // Set default notes based on template type
        switch template.type {
        case .water:
            notes = "保持水分，有益健康"
        case .rest:
            notes = "适当休息，提高效率"
        case .sleep:
            notes = "早睡早起，身体好"
        case .medicine:
            notes = "按时服药，遵医嘱（如需早晚各一次，请单独建两个提醒）"
        case .exercise:
            notes = "坚持运动，保持健康"
        case .cooking:
            notes = "按时做饭，规律饮食"
        case .meal:
            notes = "规律饮食，有益健康"
        default:
            notes = ""
        }
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

  
            // Schedule notification only for non-TODO reminders
            if reminder.type != .todo {
                Task {
                    try await NotificationManager.shared.scheduleNotification(for: reminder)
                }
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
                ForEach(ReminderType.allCases.filter { isTodoMode ? true : $0 != .todo }, id: \.self) { type in
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
        VStack(alignment: .leading, spacing: 12) {
            Text("快速模板")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(quickTemplates, id: \.title) { template in
                    ReminderTemplateCard(
                        title: template.title,
                        icon: template.type.icon,
                        color: AppColors.colorForType(template.type),
                        isSelected: false
                    ) {
                        applyTemplate(template)
                    }
                }
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

    private func selectRepeatRule(_ rule: RepeatRule) {
        selectedRepeatRule = rule
        if case .intervalMinutes(let minutes) = rule {
            customIntervalMinutes = minutes
            useCustomInterval = true
        } else {
            lastNonIntervalRule = rule
            useCustomInterval = false
        }
    }

    private func applyCustomInterval() {
        useCustomInterval = true
        selectedRepeatRule = .intervalMinutes(customIntervalMinutes)
    }

    private func syncCustomIntervalFromRule() {
        if case .intervalMinutes(let minutes) = selectedRepeatRule {
            customIntervalMinutes = minutes
            useCustomInterval = true
        } else {
            useCustomInterval = false
            lastNonIntervalRule = selectedRepeatRule
        }
    }
}

// MARK: - iOS Styled Sections
private extension AddReminderView {
    var headerCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.colorForType(selectedType).opacity(0.18))
                    .frame(width: 72, height: 72)
                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                Image(systemName: selectedType.icon)
                    .foregroundColor(AppColors.colorForType(selectedType))
                    .font(.title2.weight(.bold))
            }
            Text(isTodoMode ? "创建一个待办事项" : "安排一个贴心提醒")
                .font(.title3.weight(.semibold))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(isTodoMode ? "给它起个名字，稍后可再补充备注" : "选个类型、起个名字，再定下频率和时间")
                .font(.subheadline)
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
            VStack(alignment: .leading, spacing: 2) {
                Text("提醒主题")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("先选个氛围，标题会自动带上关键词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ReminderType.allCases.filter { isTodoMode ? true : $0 != .todo }, id: \.self) { type in
                    TypeSelectionCard(
                        title: type.rawValue,
                        icon: type.icon,
                        color: AppColors.colorForType(type),
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                        applyAutoTitleIfNeeded(for: type)
                    }
                }
            }
        }
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("给它起个名字")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("一句话即可，稍后可再补充备注")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextField("例如：起来喝水、活动一下", text: $title)
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
        let quickRules: [RepeatRule] = [
            .never,
            .daily,
            RepeatRule.weekly([.monday, .tuesday, .wednesday, .thursday, .friday]),
            RepeatRule.weekly([.saturday, .sunday]),
            .monthly(1),
            .yearly(1, 1)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("提醒频率")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    useCustomInterval.toggle()
                    if useCustomInterval {
                        applyCustomInterval()
                    } else if case .intervalMinutes = selectedRepeatRule {
                        selectedRepeatRule = lastNonIntervalRule
                    }
                } label: {
                    Text(useCustomInterval ? "取消自定义" : "自定义间隔")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(useCustomInterval ? AppColors.timer.opacity(0.15) : AppColors.cardBackground)
                        )
                        .overlay(
                            Capsule().stroke(useCustomInterval ? AppColors.timer : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .foregroundColor(useCustomInterval ? AppColors.timer : .primary)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickRules, id: \.self) { rule in
                        let isSelected = rule.isSame(as: selectedRepeatRule) && !useCustomInterval
                        Button {
                            selectRepeatRule(rule)
                        } label: {
                            HStack(spacing: 6) {
                                Text(rule.shortDescription)
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(isSelected ? AppColors.primary.opacity(0.15) : AppColors.cardBackground)
                            )
                            .overlay(
                                Capsule().stroke(isSelected ? AppColors.primary : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if useCustomInterval {
                customIntervalCard
            }
        }
    }

    var customIntervalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("自定义间隔")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("适合高频任务，如喝水、伸展等")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                ForEach([15, 30, 60], id: \.self) { minutes in
                    let isSelected = useCustomInterval && customIntervalMinutes == minutes
                    Button {
                        customIntervalMinutes = minutes
                        applyCustomInterval()
                    } label: {
                        Text("每\(minutes)分")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(isSelected ? AppColors.timer.opacity(0.2) : AppColors.cardBackground)
                            )
                            .overlay(
                                Capsule().stroke(isSelected ? AppColors.timer : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("每 \(customIntervalMinutes) 分钟提醒一次")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                Slider(value: Binding(
                    get: { Double(customIntervalMinutes) },
                    set: { customIntervalMinutes = Int($0) }
                ), in: 5...180, step: 5)
                .tint(AppColors.timer)
                .onChange(of: customIntervalMinutes) { _ in
                    if useCustomInterval {
                        applyCustomInterval()
                    }
                }
                Text("范围 5-180 分钟，步进 5 分钟")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
    }

    var timeCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("开始日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }

                Spacer()

                VStack {
                    Toggle("结束日期", isOn: $hasEndDate)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))

                    if hasEndDate {
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
            }
        }
    }

    var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.headline)
                .foregroundColor(.primary)

            TextField("补充说明（可选）", text: $notes, axis: .vertical)
                .lineLimit(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
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

    private let workdayRule = RepeatRule.weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
    private let weekendRule = RepeatRule.weekly([.saturday, .sunday])

    private func isSelected(_ rule: RepeatRule) -> Bool {
        selectedRule.isSame(as: rule)
    }

    
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
                                if isSelected(rule) {
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
                        selectedRule = workdayRule
                        dismiss()
                    }) {
                        HStack {
                            Text("工作日（周一到周五）")
                            Spacer()
                            if isSelected(workdayRule) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    Button(action: {
                        selectedRule = weekendRule
                        dismiss()
                    }) {
                        HStack {
                            Text("周末（周六和周日）")
                            Spacer()
                            if isSelected(weekendRule) {
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
                                    if isSelected(rule) {
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
                                                .stroke(isSelected(rule) ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected(rule) ? 2 : 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // 高频
                    VStack(spacing: 8) {
                        Text("间隔提醒")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        Text("自定义间隔请在添加页面直接设置")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
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
                            selectedRule = workdayRule
                            dismiss()
                        }) {
                            HStack {
                                Text("工作日（周一到周五）")
                                    .font(.body)
                                Spacer()
                                if isSelected(workdayRule) {
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
                                            .stroke(isSelected(workdayRule) ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected(workdayRule) ? 2 : 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            selectedRule = weekendRule
                            dismiss()
                        }) {
                            HStack {
                                Text("周末（周六和周日）")
                                    .font(.body)
                                Spacer()
                                if isSelected(weekendRule) {
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
                                            .stroke(isSelected(weekendRule) ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected(weekendRule) ? 2 : 1)
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
