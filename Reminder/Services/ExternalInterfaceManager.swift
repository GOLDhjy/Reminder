import Foundation
import SwiftData
import UserNotifications

@MainActor
class ExternalInterfaceManager: ObservableObject {
    private var modelContext: ModelContext?
    private let notificationManager = NotificationManager.shared

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // Handle incoming URL from other apps
    func handleIncomingURL(_ url: URL) async {
        guard url.scheme == AppConstants.urlScheme else {
            print("Invalid URL scheme: \(url.scheme ?? "nil")")
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let action = components.host else {
            print("Invalid URL format")
            return
        }

        switch action.lowercased() {
        case "add":
            await handleAddReminder(components)
        case "toggle":
            handleToggleReminder(components)
        case "complete":
            handleCompleteReminder(components)
        case "list":
            handleListReminders(components)
        default:
            print("Unknown action: \(action)")
        }
    }

    // Handle add reminder from URL
    private func handleAddReminder(_ components: URLComponents) async {
        guard let queryItems = components.queryItems,
              let modelContext = modelContext else {
            return
        }

        // Parse parameters
        guard let title = queryItems.first(where: { $0.name == "title" })?.value else {
            print("Missing required parameter: title")
            return
        }

        let timeString = queryItems.first(where: { $0.name == "time" })?.value ?? "09:00"
        let notes = queryItems.first(where: { $0.name == "notes" })?.value
        let typeString = queryItems.first(where: { $0.name == "type" })?.value?.lowercased()
        let repeatString = queryItems.first(where: { $0.name == "repeat" })?.value?.lowercased()
        let excludeHolidays = queryItems.first(where: { $0.name == "excludeHolidays" })?.value == "true"

        // Parse time
        let timeOfDay = parseTimeString(timeString) ?? Date()

        // Determine reminder type
        let reminderType: ReminderType
        if let typeString = typeString,
           let type = ReminderType.allCases.first(where: { $0.rawValue.lowercased() == typeString }) {
            reminderType = type
        } else {
            reminderType = .custom
        }

        // Determine repeat rule
        let repeatRule: RepeatRule
        switch repeatString {
        case "daily":
            repeatRule = .daily
        case "weekly":
            // Default to weekdays
            repeatRule = .weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
        case "interval30", "every30m":
            repeatRule = .intervalMinutes(30)
        case "monthly":
            repeatRule = .monthly(1)
        case "yearly":
            repeatRule = .yearly(1, 1)
        default:
            repeatRule = .never
        }

        // Create reminder
        let reminder = Reminder(
            title: title,
            type: reminderType,
            timeOfDay: timeOfDay,
            repeatRule: repeatRule,
            notes: notes
        )
        reminder.excludeHolidays = excludeHolidays

        // Save to database
        modelContext.insert(reminder)

        do {
            try modelContext.save()

            // Schedule notification
            try await notificationManager.scheduleNotification(for: reminder)

            print("Successfully created reminder: \(title)")
        } catch {
            print("Failed to create reminder: \(error)")
        }
    }

    // Handle toggle reminder status
    private func handleToggleReminder(_ components: URLComponents) {
        guard let queryItems = components.queryItems,
              let idString = queryItems.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: idString),
              let modelContext = modelContext else {
            return
        }

        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate<Reminder> { $0.id == id }
        )

        guard let reminder = try? modelContext.fetch(descriptor).first else {
            print("Reminder not found with ID: \(idString)")
            return
        }

        // Toggle active status
        reminder.isActive.toggle()
        reminder.updatedAt = Date()

        do {
            try modelContext.save()

            // Update notification
            Task {
                if reminder.isActive {
                    try await notificationManager.scheduleNotification(for: reminder)
                } else {
                    notificationManager.cancelNotification(for: reminder)
                }
            }

            print("Toggled reminder status for: \(reminder.title)")
        } catch {
            print("Failed to toggle reminder: \(error)")
        }
    }

    // Handle complete reminder
    private func handleCompleteReminder(_ components: URLComponents) {
        guard let queryItems = components.queryItems,
              let idString = queryItems.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: idString),
              let modelContext = modelContext else {
            return
        }

        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate<Reminder> { $0.id == id }
        )

        guard let reminder = try? modelContext.fetch(descriptor).first else {
            print("Reminder not found with ID: \(idString)")
            return
        }

        // Create completion log
        let log = ReminderLog(action: .completed, notes: "通过外部接口完成")
        log.reminder = reminder
        modelContext.insert(log)

        // Update reminder
        reminder.lastTriggered = Date()
        reminder.updatedAt = Date()

        do {
            try modelContext.save()

            // Schedule next occurrence if it's a repeating reminder
            Task {
                if case .never = reminder.repeatRule {
                    // No more notifications for one-time reminders
                    notificationManager.cancelNotification(for: reminder)
                } else {
                    // Schedule next occurrence
                    try await notificationManager.scheduleNotification(for: reminder)
                }
            }

            print("Marked reminder as completed: \(reminder.title)")
        } catch {
            print("Failed to complete reminder: \(error)")
        }
    }

    // Handle list reminders request
    private func handleListReminders(_ components: URLComponents) {
        guard let modelContext = modelContext else { return }

        let typeString = components.queryItems?.first(where: { $0.name == "type" })?.value?.lowercased()

        var descriptor = FetchDescriptor<Reminder>(
            sortBy: [SortDescriptor(\.nextTriggerDate)]
        )

        // Filter by type if specified
        if let typeString = typeString,
           let type = ReminderType.allCases.first(where: { $0.rawValue.lowercased() == typeString }) {
            descriptor.predicate = #Predicate<Reminder> { $0.type == type }
        }

        do {
            let reminders = try modelContext.fetch(descriptor)

            print("Reminders (\(reminders.count)):")
            for reminder in reminders {
                let status = reminder.isActive ? "Active" : "Inactive"
                let nextDate = reminder.nextTriggerDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never"
                print("- \(reminder.title) (\(reminder.type.rawValue)) - \(status) - Next: \(nextDate)")
            }
        } catch {
            print("Failed to fetch reminders: \(error)")
        }
    }

    // Helper to parse time string
    private func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        let today = Date()
        guard let time = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        ))
    }

    // Export reminders for external use
    func exportReminders(ofType type: ReminderType?) -> [[String: Any]] {
        guard let modelContext = modelContext else { return [] }

        var descriptor = FetchDescriptor<Reminder>()

        // Filter by type if specified
        if let type = type {
            descriptor.predicate = #Predicate<Reminder> { $0.type == type }
        }

        do {
            let reminders = try modelContext.fetch(descriptor)

            return reminders.map { reminder in
                var dict: [String: Any] = [
                    "id": reminder.id.uuidString,
                    "title": reminder.title,
                    "type": reminder.type.rawValue,
                    "isActive": reminder.isActive,
                    "timeOfDay": ISO8601DateFormatter().string(from: reminder.timeOfDay),
                    "repeatRule": String(describing: reminder.repeatRule),
                    "excludeHolidays": reminder.excludeHolidays,
                    "createdAt": ISO8601DateFormatter().string(from: reminder.createdAt)
                ]

                if let notes = reminder.notes {
                    dict["notes"] = notes
                }

                if let endDate = reminder.endDate {
                    dict["endDate"] = ISO8601DateFormatter().string(from: endDate)
                }

                if let nextTrigger = reminder.nextTriggerDate {
                    dict["nextTrigger"] = ISO8601DateFormatter().string(from: nextTrigger)
                }

                return dict
            }
        } catch {
            print("Failed to export reminders: \(error)")
            return []
        }
    }
}

// MARK: - URL Scheme Documentation
/*
Supported URL Schemes:

1. Add a reminder:
   \(AppConstants.urlScheme)://add?title=喝水&time=10:00&repeat=daily&type=water&excludeHolidays=true

   Parameters:
   - title (required): Reminder title
   - time: Time in HH:mm format (default: 09:00)
   - repeat: never, daily, weekly, monthly, yearly
   - type: water, meal, rest, sleep, medicine, custom
   - notes: Additional notes
   - excludeHolidays: true/false

2. Toggle reminder:
   \(AppConstants.urlScheme)://toggle?id=[UUID]

3. Complete reminder:
   \(AppConstants.urlScheme)://complete?id=[UUID]

4. List reminders:
   \(AppConstants.urlScheme)://list?type=water
*/
