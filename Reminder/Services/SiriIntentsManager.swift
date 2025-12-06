//
//  SiriIntentsManager.swift
//  Reminder
//
//  Created by Claude Code on 2025/12/6.
//

import Foundation
import Intents
import SwiftData

@MainActor
class SiriIntentsManager: NSObject, ObservableObject {
    static let shared = SiriIntentsManager()

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // Handle Siri intent to add a reminder
    func handleAddReminderIntent(
        title: String,
        timeInterval: TimeInterval,
        repeatOption: String?,
        reminderType: String?
    ) -> Bool {
        guard let modelContext = modelContext else { return false }

        // Parse time
        let timeOfDay = Date().addingTimeInterval(timeInterval)

        // Determine reminder type
        let type: ReminderType
        if let typeString = reminderType?.lowercased() {
            switch typeString {
            case "水", "喝水": type = .water
            case "吃饭", "用餐": type = .meal
            case "休息": type = .rest
            case "睡觉", "睡眠": type = .sleep
            case "吃药", "药物": type = .medicine
            default: type = .custom
            }
        } else {
            type = .custom
        }

        // Determine repeat rule
        let repeatRule: RepeatRule
        if let repeatOption = repeatOption?.lowercased() {
            switch repeatOption {
            case "每天": repeatRule = .daily
            case "每周": repeatRule = .weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
            case "周末": repeatRule = .weekly([.saturday, .sunday])
            case "每月": repeatRule = .monthly(1)
            default: repeatRule = .never
            }
        } else {
            repeatRule = .never
        }

        // Create reminder
        let reminder = Reminder(
            title: title,
            type: type,
            timeOfDay: timeOfDay,
            repeatRule: repeatRule
        )

        // Save and schedule
        modelContext.insert(reminder)

        do {
            try modelContext.save()

            // Schedule notification
            Task {
                try await NotificationManager.shared.scheduleNotification(for: reminder)
            }

            return true
        } catch {
            print("Failed to save reminder: \(error)")
            return false
        }
    }

    // Get reminders for Siri intent
    func getReminders() -> [String] {
        guard let modelContext = modelContext else { return [] }

        do {
            let descriptor = FetchDescriptor<Reminder>(
                predicate: #Predicate<Reminder> { $0.isActive }
            )
            let reminders = try modelContext.fetch(descriptor)
            return reminders.map { $0.title }
        } catch {
            return []
        }
    }
}