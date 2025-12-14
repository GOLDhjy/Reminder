//
//  AppConstants.swift
//  Reminder
//
//  Created by Claude Code on 2025/12/6.
//

import Foundation

/// Application-wide constants
struct AppConstants {

    // MARK: - App Information
    /// The display name of the application
    static let appName = "小帮手"

    // MARK: - Notification Constants
    static let reminderNotificationCategory = "REMINDER_CATEGORY"
    static let timerNotificationCategory = "TIMER_NOTIFICATION"
    static let completeActionIdentifier = "COMPLETE_ACTION"
    static let snoozeActionIdentifier = "SNOOZE_ACTION"
    static let resetTimerActionIdentifier = "RESET_TIMER"

    // MARK: - URL Scheme
    static let urlScheme = "reminder"

    // MARK: - User Defaults Keys
    static let hasLaunchedBeforeKey = "hasLaunchedBefore"

    // MARK: - Default Settings
    static let defaultSnoozeInterval: TimeInterval = 300 // 5 minutes
    static let maxSnoozeCount = 3
}
