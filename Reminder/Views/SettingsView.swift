//
//  SettingsView.swift
//  Reminder
//
//  Created by 黄金溢 on 2025/12/6.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var holidayManager: HolidayManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingHolidayManagement = false
    @State private var showingExportOptions = false
    @State private var showingAbout = false
    @State private var notificationTestResult = ""

    var body: some View {
#if os(iOS)
        NavigationView {
            Form {
                // Notifications Section
                Section(header: Text("通知设置")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("通知权限")
                            Text(notificationManager.isAuthorized ? "已授权" : "未授权")
                                .font(.caption)
                                .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                        }
                        Spacer()
                        Button(notificationManager.isAuthorized ? "已开启" : "开启通知") {
                            if !notificationManager.isAuthorized {
                                Task {
                                    try? await notificationManager.requestAuthorization()
                                }
                            }
                        }
                        .disabled(notificationManager.isAuthorized)
                        .foregroundColor(notificationManager.isAuthorized ? .gray : AppColors.primary)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("通知预览")
                            if !notificationManager.isAuthorized {
                                Text("需要先开启通知权限")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        Spacer()
                        Button("测试通知") {
                            sendTestNotification()
                        }
                        .disabled(!notificationManager.isAuthorized)
                        .foregroundColor(notificationManager.isAuthorized ? .blue : .gray)
                    }
                }

                // Holiday Management Section
                Section(header: Text("节假日管理")) {
                    Button(action: { showingHolidayManagement = true }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            Text("节假日设置")
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Data Management Section
                Section(header: Text("数据管理")) {
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("导出提醒数据")
                        }
                    }
                    .foregroundColor(.primary)

                    Button(action: rescheduleAllNotifications) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.green)
                            Text("重新调度所有通知")
                        }
                    }
                    .foregroundColor(.primary)
                }

                // URL Scheme Documentation
                Section(header: Text("外部接口")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL Scheme: reminder://")
                            .font(.caption)
                            .foregroundColor(AppColors.primary)

                        Text("其他应用可以通过 URL Scheme 添加提醒：")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("reminder://add?title=喝水&time=10:00&repeat=daily")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.cardBackground)
                            .cornerRadius(4)
                    }
                }

                // About Section
                Section(header: Text("关于")) {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                            Text("关于\(AppConstants.appName)")
                        }
                    }
                    .foregroundColor(.primary)

                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    if !notificationTestResult.isEmpty {
                        Text(notificationTestResult)
                            .font(.caption)
                            .foregroundColor(AppColors.primary)
                            .transition(.opacity)
                            .animation(.easeInOut, value: notificationTestResult)
                    }
                }
            }
            .themedFormBackground()
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHolidayManagement) {
                HolidayManagementView()
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .background(AppColors.background.ignoresSafeArea())
        }
#else
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("设置")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)

            Form {
                // Notifications Section
                Section(header: Text("通知设置")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("通知权限")
                            Text(notificationManager.isAuthorized ? "已授权" : "未授权")
                                .font(.caption)
                                .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                        }
                        Spacer()
                        Button(notificationManager.isAuthorized ? "已开启" : "开启通知") {
                            if !notificationManager.isAuthorized {
                                Task {
                                    try? await notificationManager.requestAuthorization()
                                }
                            }
                        }
                        .disabled(notificationManager.isAuthorized)
                        .foregroundColor(notificationManager.isAuthorized ? .gray : AppColors.primary)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("通知预览")
                            if !notificationManager.isAuthorized {
                                Text("需要先开启通知权限")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        Spacer()
                        Button("测试通知") {
                            sendTestNotification()
                        }
                        .disabled(!notificationManager.isAuthorized)
                        .foregroundColor(notificationManager.isAuthorized ? .blue : .gray)
                    }
                }

                // Holiday Management Section
                Section(header: Text("节假日管理")) {
                    Button(action: { showingHolidayManagement = true }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            Text("节假日设置")
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Data Management Section
                Section(header: Text("数据管理")) {
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("导出提醒数据")
                        }
                    }
                    .foregroundColor(.primary)

                    Button(action: rescheduleAllNotifications) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.green)
                            Text("重新调度所有通知")
                        }
                    }
                    .foregroundColor(.primary)
                }

                // URL Scheme Documentation
                Section(header: Text("外部接口")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL Scheme: reminder://")
                            .font(.caption)
                            .foregroundColor(AppColors.primary)

                        Text("其他应用可以通过 URL Scheme 添加提醒：")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("reminder://add?title=喝水&time=10:00&repeat=daily")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.cardBackground)
                            .cornerRadius(4)
                    }
                }

                // About Section
                Section(header: Text("关于")) {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                            Text("关于\(AppConstants.appName)")
                        }
                    }
                    .foregroundColor(.primary)

                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .themedFormBackground()

            Spacer()

            // Close button
            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .sheet(isPresented: $showingHolidayManagement) {
            HolidayManagementView()
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
#endif
    }

    private func sendTestNotification() {
        if !notificationManager.isAuthorized {
            notificationTestResult = "请先开启通知权限"
            return
        }

        notificationTestResult = "正在发送测试通知..."

        Task {
            await notificationManager.sendTestNotification()

            await MainActor.run {
                notificationTestResult = "测试通知已发送！请检查通知中心"

                // 3秒后清除提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    notificationTestResult = ""
                }
            }
        }
    }

    private func rescheduleAllNotifications() {
        Task {
            do {
                try await notificationManager.rescheduleAllNotifications()
                print("All notifications rescheduled successfully")
            } catch {
                print("Failed to reschedule notifications: \(error)")
            }
        }
    }

    private func checkNotificationStatus() {
        #if os(iOS)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("\n=== 通知设置状态 ===")
            print("授权状态: \(settings.authorizationStatus)")
            print("提醒设置: \(settings.alertSetting)")
            print("声音设置: \(settings.soundSetting)")
            print("角标设置: \(settings.badgeSetting)")
            print("锁屏设置: \(settings.lockScreenSetting)")
            print("通知中心设置: \(settings.notificationCenterSetting)")
            print("横幅设置: \(settings.alertSetting)")
            print("==================\n")
        }
        #endif
    }
}

// MARK: - Holiday Management View
struct HolidayManagementView: View {
    @EnvironmentObject private var holidayManager: HolidayManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCountry = "CN"
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("节假日设置")) {
                    Picker("国家/地区", selection: $selectedCountry) {
                        Text("中国").tag("CN")
                        Text("美国").tag("US")
                        Text("国际通用").tag("INT")
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("年份", selection: $selectedYear) {
                        ForEach(selectedYear-1...selectedYear+2, id: \.self) { year in
                            Text("\(year)年").tag(year)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Button("加载节假日") {
                        Task {
                            await holidayManager.loadHolidays(for: selectedCountry, year: selectedYear)
                        }
                    }
                    .foregroundColor(AppColors.primary)
                }

                Section(header: Text("当前节假日")) {
                    if holidayManager.holidays.isEmpty {
                        Text("暂无节假日数据")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(holidayManager.holidays.filter { $0.country == selectedCountry }, id: \.id) { holiday in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(holiday.name)
                                Text(holiday.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(holiday.type.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.cardBackground)
                                .cornerRadius(4)
                        }
                    }
                    }
                }
            }
            .formStyle(.grouped)
            .themedFormBackground()
            .navigationTitle("节假日管理")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

// MARK: - Export Options View
struct ExportOptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var exportFormat = "json"
    @State private var includeCompleted = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("导出格式")) {
                    Picker("格式", selection: $exportFormat) {
                        Text("JSON").tag("json")
                        Text("CSV").tag("csv")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("导出内容")) {
                    Toggle("包含已完成的提醒", isOn: $includeCompleted)
                }

                Section {
                    Button("导出") {
                        exportReminders()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
            }
            .formStyle(.grouped)
            .themedFormBackground()
            .navigationTitle("导出数据")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func exportReminders() {
        let externalManager = ExternalInterfaceManager()
        externalManager.setModelContext(modelContext)

        let reminders = externalManager.exportReminders(ofType: nil)

        do {
            let data = try JSONSerialization.data(withJSONObject: reminders, options: .prettyPrinted)

            // Save to file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent("reminders_export.json")

            try data.write(to: fileURL)

            print("Exported \(reminders.count) reminders to: \(fileURL.path)")
            dismiss()
        } catch {
            print("Failed to export reminders: \(error)")
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // App Icon
                Image(systemName: "bell.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.primary)
                    .padding(.top, 50)

                // App Info
                VStack(spacing: 10) {
                    Text(AppConstants.appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("版本 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Description
                VStack(spacing: 15) {
                    Text("一个简洁实用的生活提醒应用")
                        .font(.title3)
                        .multilineTextAlignment(.center)

                    Text("帮助您管理日常生活中的各种提醒事项，包括喝水、吃饭、休息、睡觉和吃药等。支持自定义重复规则和节假日排除功能。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Copyright
                Text("© 2025 \(AppConstants.appName)\n保留所有权利")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("关于")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 400)
        }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager.shared)
        .environmentObject(HolidayManager.shared)
}
