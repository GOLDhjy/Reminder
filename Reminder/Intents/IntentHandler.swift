//
//  IntentHandler.swift
//  Reminder
//
//  Created by Claude Code on 2025/12/6.
//

import Intents
import IntentsUI

// Simple intent handler for basic Siri integration
class IntentHandler: NSObject, INExtension {

    func handler(for intent: INIntent) -> Any {
        return self
    }
}

// Handle INAddTasksIntent for creating reminders
extension IntentHandler: INAddTasksIntentHandling {

    func handle(intent: INAddTasksIntent) async -> INAddTasksIntentResponse {
        guard let taskTitles = intent.taskTitles, !taskTitles.isEmpty,
              let firstTask = taskTitles.first else {
            return INAddTasksIntentResponse(code: .failure, userActivity: nil)
        }

        let title = firstTask.spokenPhrase

        // Use SiriIntentsManager to handle the intent
        let success = await SiriIntentsManager.shared.handleAddReminderIntent(
            title: title,
            timeInterval: 0,
            repeatOption: nil,
            reminderType: nil
        )

        return INAddTasksIntentResponse(code: success ? .success : .failure, userActivity: nil)
    }

    func resolveTaskTitles(for intent: INAddTasksIntent) async -> INStringResolutionResult {
        guard let taskTitles = intent.taskTitles, !taskTitles.isEmpty else {
            return INStringResolutionResult.needsValue()
        }
        return INStringResolutionResult.success(with: taskTitles.first?.spokenPhrase ?? "")
    }
}