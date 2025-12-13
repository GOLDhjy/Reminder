import SwiftUI
import SwiftData

struct TimeReminderView: View {
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
    @State private var customIntervalMinutes = 30
    @State private var useCustomInterval = false
    @State private var lastNonIntervalRule: RepeatRule = .daily

    @State private var showingTimePicker = false
    @State private var showingRepeatOptions = false

    private var isEditing: Bool {
        reminder != nil
    }

    // 快速模板
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
                title: "22点30分睡觉",
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
                repeatRule: .daily
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

    // 快速频率选项
    private var quickRules: [RepeatRule] {
        [.never, .daily, .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]), .weekly([.saturday, .sunday]), .monthly(1), .yearly(1, 1)]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 快速模板
                    quickTemplatesSection

                    // 类型选择
                    typeGridSection

                    // 标题和备注
                    titleSection
                    notesSection

                    // 重复设置
                    repeatChipsSection

                    // 时间设置
                    timeCardSection

                    // 高级设置
                    if case .weekly = selectedRepeatRule {
                        weekdaySection
                    }

                    if hasEndDate {
                        endDateSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(isEditing ? "编辑提醒" : "创建提醒")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
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
                .padding(.horizontal, 0)
                .padding(.bottom, 0)
                .disabled(title.isEmpty)
                .opacity(title.isEmpty ? 0.5 : 1)
            }
        }
        .background(AppColors.formBackground.ignoresSafeArea())
        .onAppear {
            if let reminder = reminder {
                // 编辑模式：加载现有数据
                title = reminder.title
                notes = reminder.notes ?? ""
                selectedType = reminder.type
                selectedTime = reminder.timeOfDay
                selectedRepeatRule = reminder.repeatRule
                startDate = reminder.startDate
                endDate = reminder.endDate ?? Date()
                excludeHolidays = reminder.excludeHolidays
                userEditedTitle = true
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            DatePicker("选择时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .padding()
        }
        .sheet(isPresented: $showingRepeatOptions) {
            NavigationView {
                Form {
                    Picker("重复频率", selection: $selectedRepeatRule) {
                        Text("仅一次").tag(RepeatRule.never)
                        Text("每天").tag(RepeatRule.daily)
                        Text("工作日").tag(RepeatRule.weekly([.monday, .tuesday, .wednesday, .thursday, .friday]))
                        Text("周末").tag(RepeatRule.weekly([.saturday, .sunday]))
                        Text("每月").tag(RepeatRule.monthly(1))
                        Text("每年").tag(RepeatRule.yearly(1, 1))
                    }
                }
                .navigationTitle("选择频率")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            showingRepeatOptions = false
                        }
                    }
                }
            }
        }
        .onChange(of: selectedRepeatRule) {
            syncCustomIntervalFromRule()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var quickTemplatesSection: some View {
        SectionCard(title: "快速模板") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(quickTemplates, id: \.title) { template in
                    ReminderTemplateCard(
                        title: template.title,
                        icon: template.icon,
                        color: AppColors.colorForType(template.type),
                        isSelected: false
                    ) {
                        applyTemplate(template)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var typeGridSection: some View {
        SectionCard(title: "提醒类型") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(ReminderType.allCases.filter({ $0 != .custom && $0 != .todo && $0 != .timer }), id: \.self) { type in
                    TypeSelectionCard(
                        title: type.rawValue,
                        icon: type.icon,
                        color: AppColors.colorForType(type),
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                        if !userEditedTitle {
                            autoTitle = "\(selectedType.rawValue)"
                            title = autoTitle ?? ""
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        SectionCard(title: "提醒内容") {
            TextField("请输入提醒内容", text: $title)
                .font(.headline)
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    userEditedTitle = true
                }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        SectionCard(title: "备注（可选）") {
            TextField("添加备注信息", text: $notes, axis: .vertical)
                .font(.subheadline)
                .textFieldStyle(PlainTextFieldStyle())
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var repeatChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("提醒频率")
                .font(.headline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickRules, id: \.self) { rule in
                        RepeatChip(
                            rule: rule,
                            isSelected: selectedRepeatRule == rule
                        ) {
                            handleRuleSelection(rule)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private var timeCardSection: some View {
        SectionCard(title: "提醒时间") {
            VStack(spacing: 12) {
                HStack {
                    Text("每日提醒时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(selectedTime.formatted(date: .omitted, time: .shortened)) {
                        showingTimePicker = true
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.primary)
                }
                .padding(14)
                .background(AppColors.cardElevated)
                .cornerRadius(12)

                // 节假日排除
                Toggle("节假日不提醒", isOn: $excludeHolidays)
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var weekdaySection: some View {
        SectionCard(title: "选择星期") {
            WeekdayPicker(selectedWeekdays: $selectedWeekdays)
        }
    }

    @ViewBuilder
    private var endDateSection: some View {
        SectionCard(title: "结束日期") {
            DatePicker("结束日期", selection: $endDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.compact)
        }
    }

    // MARK: - Helper Methods

    private func applyTemplate(_ template: ReminderTemplate) {
        title = template.title
        selectedType = template.type
        selectedTime = template.time ?? Date()
        selectedRepeatRule = template.repeatRule ?? .daily
        userEditedTitle = true
    }

    private func handleRuleSelection(_ rule: RepeatRule) {
        if case .intervalMinutes = rule {
            useCustomInterval = true
            selectedRepeatRule = rule
        } else {
            useCustomInterval = false
            lastNonIntervalRule = rule
            selectedRepeatRule = rule
        }
    }

    private func syncCustomIntervalFromRule() {
        if case .intervalMinutes = selectedRepeatRule {
            // intervalMinutes is valid
        } else {
            useCustomInterval = false
        }
    }

    private func saveReminder() {
        let newReminder = Reminder(
            title: title,
            type: selectedType,
            timeOfDay: selectedTime,
            repeatRule: selectedRepeatRule,
            notes: notes.isEmpty ? nil : notes
        )

        // Set additional properties
        newReminder.startDate = startDate
        if hasEndDate {
            newReminder.endDate = endDate
        }
        newReminder.excludeHolidays = excludeHolidays

        modelContext.insert(newReminder)
        try? modelContext.save()

        Task {
            try? await NotificationManager.shared.scheduleNotification(for: newReminder)
        }

        dismiss()
    }

    private func updateReminder() {
        guard let reminder = reminder else { return }

        reminder.title = title
        reminder.notes = notes.isEmpty ? nil : notes
        reminder.type = selectedType
        reminder.timeOfDay = selectedTime
        reminder.repeatRule = selectedRepeatRule
        reminder.startDate = startDate
        reminder.endDate = hasEndDate ? endDate : nil
        reminder.excludeHolidays = excludeHolidays
        reminder.updatedAt = Date()

        try? modelContext.save()

        Task {
            try? await NotificationManager.shared.scheduleNotification(for: reminder)
        }

        dismiss()
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)

    NavigationView {
        TimeReminderView()
            .modelContainer(container)
    }
}