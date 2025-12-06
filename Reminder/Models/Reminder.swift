import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var title: String
    var notes: String?
    var type: ReminderType
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    // Schedule properties
    var timeOfDay: Date // Only time component matters
    var startDate: Date
    var endDate: Date?
    var repeatRule: RepeatRule
    var excludeHolidays: Bool

    // Notification properties
    var notificationID: String?
    var snoozeCount: Int
    var lastTriggered: Date?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ReminderLog.reminder)
    var logs: [ReminderLog] = []

    init(title: String, type: ReminderType, timeOfDay: Date, repeatRule: RepeatRule = .never, notes: String? = nil) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.timeOfDay = timeOfDay
        self.repeatRule = repeatRule
        self.notes = notes
        self.isActive = true
        self.excludeHolidays = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.startDate = Date()
        self.snoozeCount = 0
    }

    // Computed property for next trigger date
    var nextTriggerDate: Date? {
        let calculator = RepeatRuleCalculator()
        let fromDate = lastTriggered ?? Date()
        return calculator.nextTriggerDate(
            from: fromDate,
            rule: repeatRule,
            startDate: startDate,
            endDate: endDate,
            excludeHolidays: excludeHolidays,
            timeOfDay: timeOfDay
        )
    }
}

enum ReminderType: String, CaseIterable, Codable, Identifiable, Hashable {
    case water = "喝水"
    case meal = "吃饭"
    case rest = "休息"
    case sleep = "睡觉"
    case medicine = "吃药"
    case custom = "自定义"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .meal: return "fork.knife"
        case .rest: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .medicine: return "pills.fill"
        case .custom: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .water: return "blue"
        case .meal: return "orange"
        case .rest: return "green"
        case .sleep: return "purple"
        case .medicine: return "red"
        case .custom: return "gray"
        }
    }
}

enum RepeatRule: Codable, CaseIterable, Hashable {
    case never
    case daily
    case weekly([Weekday])
    case monthly(Int) // Day of month
    case yearly(Int, Int) // Month, Day

    var description: String {
        switch self {
        case .never:
            return "不重复"
        case .daily:
            return "每天"
        case .weekly(let weekdays):
            if weekdays.count == 7 {
                return "每天"
            } else {
                let weekdayNames = weekdays.map { $0.shortName }.joined(separator: ", ")
                return "每周：\(weekdayNames)"
            }
        case .monthly(let day):
            return "每月 \(day) 日"
        case .yearly(let month, let day):
            return "每年 \(month) 月 \(day) 日"
        }
    }

    static var allCases: [RepeatRule] {
        return [
            .never,
            .daily,
            .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]),
            .weekly([.saturday, .sunday]),
            .monthly(1),
            .yearly(1, 1)
        ]
    }
}

enum Weekday: Int, CaseIterable, Codable, Identifiable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday: return "周日"
        case .monday: return "周一"
        case .tuesday: return "周二"
        case .wednesday: return "周三"
        case .thursday: return "周四"
        case .friday: return "周五"
        case .saturday: return "周六"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "日"
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        }
    }
}