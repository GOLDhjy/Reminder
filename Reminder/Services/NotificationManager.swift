import Foundation
import UserNotifications
import SwiftData
#if os(iOS)
import UIKit
#endif

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        notificationCenter.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }

    // Set model context after initialization
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // Request authorization for notifications
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .carPlay, .criticalAlert]
        let granted = try await notificationCenter.requestAuthorization(options: options)

        await MainActor.run {
            self.isAuthorized = granted
            self.authorizationStatus = granted ? .authorized : .denied
        }

        if granted {
            // Configure notification settings
            #if os(iOS)
            await MainActor.run {
                notificationCenter.delegate = self
                // Set default notification settings
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.getNotificationSettings { settings in
                    print("Notification settings: \(settings)")
                }
            }
            #endif
        }
    }

    // Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()

        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // Register for remote notifications (for background updates)
    private func registerForRemoteNotifications() async {
        // This would be implemented if you need remote notification support
        // For now, we focus on local notifications
    }

    // Schedule a notification for a reminder
    func scheduleNotification(for reminder: Reminder) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        // TODO 类型不需要调度通知
        if reminder.type == .todo {
            reminder.notificationID = nil
            return
        }

        // Cancel existing notification if any
        if let notificationID = reminder.notificationID {
            cancelNotification(withID: notificationID)
        }

        // Calculate next trigger date
        guard let nextTrigger = reminder.nextTriggerDate else {
            throw NotificationError.noValidSchedule
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        // 在标题前添加类型相关的 emoji
        content.title = "\(reminder.type.emojiIcon) \(reminder.title)"

        // 计时任务使用不同的 body 文本
        if reminder.type == .timer {
            content.body = "计时结束了！"
            content.categoryIdentifier = "TIMER_NOTIFICATION"
        } else {
            content.body = "该\(reminder.title)了"
            content.categoryIdentifier = AppConstants.reminderNotificationCategory
        }

        // Add rich notification attachments for better appearance
        content.sound = .default
        content.userInfo = [
            "reminderID": reminder.id.uuidString,
            "reminderType": reminder.type.rawValue
        ]
        if let iconAttachment = makeAppIconAttachment() {
            content.attachments = [iconAttachment]
        }

        // Don't set badge here - let the system manage it when notification is actually delivered

        // Set priority to timeSensitive for persistent display (won't auto-dismiss)
        content.interruptionLevel = .timeSensitive

        // 设置通知为关键通知，确保在 Apple Watch 上也能显示
        #if os(iOS)
        content.threadIdentifier = "reminder-\(reminder.type.rawValue)"
        #endif

        // Add actions with better titles and options
        // 为 Apple Watch 优化：使用简短文字和图标
        let completeAction = UNNotificationAction(
            identifier: AppConstants.completeActionIdentifier,
            title: "✅ 完成",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: AppConstants.snoozeActionIdentifier,
            title: "⏰ 稍后",
            options: []
        )

        // 创建支持 Apple Watch 的 category
        let category = UNNotificationCategory(
            identifier: AppConstants.reminderNotificationCategory,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // 创建计时任务的单独 category
        let timerCompleteAction = UNNotificationAction(
            identifier: AppConstants.completeActionIdentifier,
            title: "✅ 完成",
            options: [.foreground]
        )

        let timerResetAction = UNNotificationAction(
            identifier: "RESET_TIMER",
            title: "🔄 重置",
            options: []
        )

        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_NOTIFICATION",
            actions: [timerCompleteAction, timerResetAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([category, timerCategory])

        // Create trigger
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextTrigger)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create request
        let notificationID = reminder.id.uuidString
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        try await notificationCenter.add(request)

        // Update reminder with notification ID
        reminder.notificationID = notificationID
        reminder.updatedAt = Date()

        // Save to database
        try modelContext?.save()
    }

    // Cancel a specific notification
    func cancelNotification(for reminder: Reminder) {
        if let notificationID = reminder.notificationID {
            cancelNotification(withID: notificationID)
            reminder.notificationID = nil
            reminder.updatedAt = Date()
            try? modelContext?.save()
        }
    }

    // Cancel notification by ID
    private func cancelNotification(withID id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }

    // Reschedule all active notifications
    func rescheduleAllNotifications() async throws {
        guard let modelContext = modelContext else {
            throw NotificationError.modelContextNotAvailable
        }

        // Cancel all pending notifications
        notificationCenter.removeAllPendingNotificationRequests()

        // Fetch all active reminders
        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate<Reminder> { $0.isActive }
        )

        let reminders = try modelContext.fetch(descriptor)

        // Schedule notifications for each reminder
        for reminder in reminders {
            try await scheduleNotification(for: reminder)
        }
    }

    // Handle notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        guard let reminderID = response.notification.request.content.userInfo["reminderID"] as? String,
              let reminderUUID = UUID(uuidString: reminderID),
              let modelContext = modelContext else {
            return
        }

        // Find the reminder
        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate<Reminder> { $0.id == reminderUUID }
        )

        guard let reminder = try? modelContext.fetch(descriptor).first else {
            return
        }

        // Create log entry
        let log: ReminderLog
        switch response.actionIdentifier {
        case AppConstants.completeActionIdentifier:
            log = ReminderLog(action: .completed, notes: "用户点击了已完成")
        case AppConstants.snoozeActionIdentifier:
            log = ReminderLog(action: .snoozed, notes: "用户延迟了5分钟")
            // Schedule snooze notification
            try? await scheduleSnoozeNotification(for: reminder)
        case UNNotificationDefaultActionIdentifier:
            log = ReminderLog(action: .acknowledged, notes: "用户打开了通知")
        case UNNotificationDismissActionIdentifier:
            log = ReminderLog(action: .skipped, notes: "用户关闭了通知")
        default:
            log = ReminderLog(action: .acknowledged, notes: "未知操作")
        }

        log.reminder = reminder
        modelContext.insert(log)

        // Update reminder
        reminder.lastTriggered = Date()
        reminder.updatedAt = Date()

        // If non-repeating, mark inactive after first trigger
        if case .never = reminder.repeatRule {
            cancelNotification(for: reminder)
            reminder.isActive = false
            reminder.notificationID = nil
            try? modelContext.save()
            await clearBadge()
            return
        }

        // Schedule next notification if not completed and repeating
        if response.actionIdentifier != AppConstants.completeActionIdentifier {
            try? await scheduleNotification(for: reminder)
        }

        try? modelContext.save()

        // Clear the badge when user interacts with notification
        await clearBadge()
    }

    // Clear application badge
    private func clearBadge() async {
        #if os(iOS)
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        #endif
    }

    // Send test notification
    func sendTestNotification() async {
        // First check current notification settings
        let settings = await notificationCenter.notificationSettings()

        print("=== Notification Settings ===")
        print("Authorization Status: \(settings.authorizationStatus)")
        print("Alert Setting: \(settings.alertSetting)")
        print("Sound Setting: \(settings.soundSetting)")
        print("Badge Setting: \(settings.badgeSetting)")
        print("Alert Style: \(settings.alertStyle)")
        print("========================")

        // If not authorized, try to request authorization
        if settings.authorizationStatus != .authorized {
            do {
                _ = try await requestAuthorization()
                print("Requested notification authorization...")
            } catch {
                print("Failed to request authorization: \(error)")
                return
            }
        }

        // Create multiple test notifications with different approaches
        await sendImmediateTestNotification()
        await sendDelayedTestNotification()
    }

    // Send immediate notification (no trigger)
    private func sendImmediateTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "🔔 即时测试通知"
        content.body = "这是\(AppConstants.appName)的即时测试通知"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        // Add category for interactive actions
        content.categoryIdentifier = AppConstants.reminderNotificationCategory

        content.userInfo = [
            "test": true,
            "type": "immediate",
            "bundleIdentifier": Bundle.main.bundleIdentifier ?? "unknown",
            "timestamp": Date().timeIntervalSince1970
        ]

        // Create request with no trigger (fires immediately)
        let request = UNNotificationRequest(
            identifier: "immediate-test-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil  // No trigger = immediate
        )

        do {
            try await notificationCenter.add(request)
            print("Immediate test notification sent successfully")
        } catch {
            print("Failed to send immediate test notification: \(error)")
        }
    }

    // Send delayed notification (for comparison)
    private func sendDelayedTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ 延迟测试通知"
        content.body = "这是\(AppConstants.appName)的延迟测试通知 (2秒后显示)"
        content.sound = .default
        content.interruptionLevel = .critical

        content.userInfo = [
            "test": true,
            "type": "delayed",
            "bundleIdentifier": Bundle.main.bundleIdentifier ?? "unknown",
            "timestamp": Date().timeIntervalSince1970
        ]

        // Schedule with 2 second delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "delayed-test-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Delayed test notification scheduled successfully")

            // Log all pending notifications
            let pendingRequests = await notificationCenter.pendingNotificationRequests()
            print("Total pending notifications: \(pendingRequests.count)")
            for req in pendingRequests {
                print("- \(req.identifier): \(req.content.title)")
            }
        } catch {
            print("Failed to send delayed test notification: \(error)")
        }
    }

    // Schedule a snooze notification
    private func scheduleSnoozeNotification(for reminder: Reminder) async throws {
        let content = UNMutableNotificationContent()
        // 在标题前添加类型相关的 emoji
        content.title = "\(reminder.type.emojiIcon) \(reminder.title)"
        content.sound = .default
        content.categoryIdentifier = AppConstants.reminderNotificationCategory
        content.userInfo = [
            "reminderID": reminder.id.uuidString,
            "reminderType": reminder.type.rawValue,
            "isSnooze": true
        ]
        // 设置延迟提醒的优先级为 timeSensitive（持续显示）
        content.interruptionLevel = .timeSensitive
        if let iconAttachment = makeAppIconAttachment() {
            content.attachments = [iconAttachment]
        }

        // Trigger after default snooze interval
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: AppConstants.defaultSnoozeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(reminder.id.uuidString)-snooze",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    enum NotificationError: Error, LocalizedError {
        case notAuthorized
        case noValidSchedule
        case modelContextNotAvailable

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "需要通知权限才能设置提醒"
            case .noValidSchedule:
                return "无法找到有效的提醒时间"
            case .modelContextNotAvailable:
                return "数据库不可用"
            }
        }
    }
}

extension NotificationManager {
    private var calendar: Calendar {
        Calendar.current
    }

    #if os(iOS)
    private func makeAppIconAttachment() -> UNNotificationAttachment? {
        guard let image = appIconImage(),
              let data = image.pngData() else { return nil }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("app-icon-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            let attachment = try UNNotificationAttachment(identifier: "app-icon", url: url, options: nil)
            return attachment
        } catch {
            print("Failed to attach app icon: \(error)")
            return nil
        }
    }

    private func appIconImage() -> UIImage? {
        if let messages = UIImage(named: "MessagesIcon") {
            return resizeForNotification(messages)
        }
        if let bundled = UIImage(named: "NotificationIcon") {
            return resizeForNotification(bundled)
        }
        guard
            let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcons = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcons["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last,
            let image = UIImage(named: lastIcon)
        else {
            return nil
        }
        return resizeForNotification(image)
    }

    private func resizeForNotification(_ image: UIImage, maxSize: CGFloat = 128) -> UIImage? {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return image }
        let scaleRatio = maxSize / longestSide
        if scaleRatio >= 1 { return image }

        let newSize = CGSize(width: image.size.width * scaleRatio, height: image.size.height * scaleRatio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #else
    private func makeAppIconAttachment() -> UNNotificationAttachment? { nil }
    #endif
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Show banner/list even when app is前台，确保看到带app图标的系统通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await handleNotificationResponse(response)
            completionHandler()
        }
    }
}
