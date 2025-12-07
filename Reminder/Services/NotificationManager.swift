import Foundation
import UserNotifications
import SwiftData
#if os(iOS)
import UIKit
#endif

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {
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
        content.body = "该\(reminder.title)了"

        // Add rich notification attachments for better appearance
        content.sound = .default
        content.categoryIdentifier = AppConstants.reminderNotificationCategory
        content.userInfo = [
            "reminderID": reminder.id.uuidString,
            "reminderType": reminder.type.rawValue
        ]

        // Don't set badge here - let the system manage it when notification is actually delivered

        // Set priority to critical for longer display and more prominence
        content.interruptionLevel = .critical

  
        // Add actions with better titles and options
        let completeAction = UNNotificationAction(
            identifier: AppConstants.completeActionIdentifier,
            title: "✅ 完成",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: AppConstants.snoozeActionIdentifier,
            title: "⏰ 稍后提醒",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: AppConstants.reminderNotificationCategory,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([category])

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

        // If non-repeating, remove after first trigger
        if case .never = reminder.repeatRule {
            cancelNotification(for: reminder)
            modelContext.delete(reminder)
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
        // 设置延迟提醒的优先级为 critical
        content.interruptionLevel = .critical

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
}
