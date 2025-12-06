//
//  IntentHandler.swift
//  Reminder
//
//  Created by Claude Code on 2025/12/6.
//

import Intents
import IntentsUI

class IntentHandler: NSObject, INExtensionRequestHandling {

    func handler(for intent: INIntent) -> Any {
        // This will be called to handle the intent when the user requests it from Siri
        return self
    }
}

extension IntentHandler: INAddTasksIntentHandling {

    func handle(intent: INAddTasksIntent) async -> INAddTasksIntentResponse {
        guard let title = intent.title?.spokenPhrase else {
            let response = INAddTasksIntentResponse(code: .failure, userActivity: nil)
            response.failureReason = "无法理解提醒内容"
            return response
        }

        // Extract time information
        let timeInterval = intent.temporalEvent?.date?.timeIntervalSinceNow ?? 0
        let repeatOption = intent.temporalEvent?.recurrenceRule?.frequency?.spokenPhrase
        let reminderType = intent.target?.spokenPhrase

        // Use SiriIntentsManager to handle the intent
        let success = SiriIntentsManager.shared.handleAddReminderIntent(
            title: title,
            timeInterval: timeInterval,
            repeatOption: repeatOption,
            reminderType: reminderType
        )

        let response = INAddTasksIntentResponse(code: success ? .success : .failure, userActivity: nil)

        if !success {
            response.failureReason = "无法创建提醒"
        }

        return response
    }
}

extension IntentHandler: INSearchForItemsIntentHandling {

    func handle(intent: INSearchForItemsIntent) async -> INSearchForItemsIntentResponse {
        // Return all reminders
        let reminders = SiriIntentsManager.shared.getReminders()

        let response = INSearchForItemsIntentResponse(code: .success, userActivity: nil)

        // Create INTask objects for each reminder
        response.tasks = reminders.map { title in
            let task = INTask()
            task.title = INSpeakableString(spokenPhrase: title)
            return task
        }

        return response
    }
}