import Foundation
import SwiftData

@Model
final class ReminderLog {
    var id: UUID
    var timestamp: Date
    var action: LogAction
    var notes: String?

    var reminder: Reminder?

    init(action: LogAction, notes: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.notes = notes
    }

    enum LogAction: String, Codable, CaseIterable {
        case triggered = "已触发"
        case acknowledged = "已确认"
        case snoozed = "已延迟"
        case skipped = "已跳过"
        case completed = "已完成"
    }
}