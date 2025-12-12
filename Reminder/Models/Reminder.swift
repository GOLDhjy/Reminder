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

        // For new reminders that haven't been triggered, check from current time
        // For existing reminders, check from last triggered or now
        let fromDate = Date()

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
    case cooking = "做饭"
    case rest = "休息"
    case sleep = "睡觉"
    case medicine = "吃药"
    case exercise = "运动"
    case todo = "待办事项"
    case custom = "自定义"
    case timer = "计时任务"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .meal: return "fork.knife"
        case .cooking: return "fork.knife.circle.fill"
        case .rest: return "figure.seated.side"
        case .sleep: return "bed.double.fill"
        case .medicine: return "pills.fill"
        case .exercise: return "figure.run"
        case .todo: return "checkmark.circle.fill"
        case .custom: return "star.fill"
        case .timer: return "timer"
        }
    }

    var systemImage: String {
        return icon
    }

    var emojiIcon: String {
        switch self {
        case .water: return "💧"
        case .meal: return "🍽️"
        case .cooking: return "🍳"
        case .rest: return "🧘"
        case .sleep: return "😴"
        case .medicine: return "💊"
        case .exercise: return "🏃"
        case .todo: return "✅"
        case .custom: return "📝"
        case .timer: return "⏰"
        }
    }

    var color: String {
        switch self {
        case .water: return "blue"
        case .meal: return "orange"
        case .cooking: return "brown"
        case .rest: return "green"
        case .sleep: return "purple"
        case .medicine: return "red"
        case .exercise: return "mint"
        case .todo: return "indigo"
        case .custom: return "gray"
        case .timer: return "timer"
        }
    }
}

enum RepeatRule: Codable, CaseIterable, Hashable {
    case never
    case daily
    case weekly([Weekday])
    case monthly(Int) // Day of month
    case yearly(Int, Int) // Month, Day
    case intervalMinutes(Int) // Every N minutes

    // Common weekday presets for clearer comparisons
    static let workdayWeekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekendWeekdays: Set<Weekday> = [.saturday, .sunday]

    var description: String {
        switch self {
        case .never:
            return "不重复"
        case .daily:
            return "每天"
        case .weekly(let weekdays):
            let weekdaySet = Set(weekdays)
            if weekdaySet == RepeatRule.workdayWeekdays {
                return "工作日（周一到周五）"
            }
            if weekdaySet == RepeatRule.weekendWeekdays {
                return "周末（周六和周日）"
            }
            if weekdaySet.count == 7 {
                return "每天"
            } else {
                let weekdayNames = weekdays
                    .sorted { $0.rawValue < $1.rawValue }
                    .map { $0.shortName }
                    .joined(separator: ", ")
                return "每周：\(weekdayNames)"
            }
        case .monthly(let day):
            return "每月 \(day) 日"
        case .yearly(let month, let day):
            return "每年 \(month) 月 \(day) 日"
        case .intervalMinutes(let minutes):
            return RepeatRule.formattedIntervalDescription(minutes: minutes)
        }
    }

    var shortDescription: String {
        switch self {
        case .never:
            return "一次"
        case .daily:
            return "每日"
        case .weekly(let weekdays):
            let weekdaySet = Set(weekdays)
            if weekdaySet == RepeatRule.workdayWeekdays {
                return "工作日"
            }
            if weekdaySet == RepeatRule.weekendWeekdays {
                return "周末"
            }
            if weekdaySet.count == 7 {
                return "每日"
            } else if weekdays.count == 1 {
                return "每周\(weekdays.first?.shortName ?? "")"
            } else {
                return "每周"
            }
        case .monthly:
            return "每月"
        case .yearly:
            return "每年"
        case .intervalMinutes(let minutes):
            return RepeatRule.formattedIntervalShort(minutes: minutes)
        }
    }

    static var allCases: [RepeatRule] {
        return [
            .never,
            .daily,
            .intervalMinutes(30),
            .weekly([.monday, .tuesday, .wednesday, .thursday, .friday]),
            .weekly([.saturday, .sunday]),
            .monthly(1),
            .yearly(1, 1)
        ]
    }

    func isSame(as other: RepeatRule) -> Bool {
        switch (self, other) {
        case (.never, .never), (.daily, .daily):
            return true
        case (.weekly(let lhs), .weekly(let rhs)):
            return Set(lhs) == Set(rhs)
        case (.monthly(let lhsDay), .monthly(let rhsDay)):
            return lhsDay == rhsDay
        case (.yearly(let lhsMonth, let lhsDay), .yearly(let rhsMonth, let rhsDay)):
            return lhsMonth == rhsMonth && lhsDay == rhsDay
        case (.intervalMinutes(let lhsMinutes), .intervalMinutes(let rhsMinutes)):
            return lhsMinutes == rhsMinutes
        default:
            return false
        }
    }

    private static func formattedIntervalDescription(minutes: Int) -> String {
        guard minutes > 0 else { return "自定义间隔" }
        if minutes % 60 == 0 {
            let hours = minutes / 60
            return "每\(hours)小时"
        }
        if minutes > 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "每\(hours)小时\(remainingMinutes)分钟"
        }
        return "每\(minutes)分钟"
    }

    private static func formattedIntervalShort(minutes: Int) -> String {
        guard minutes > 0 else { return "间隔" }
        if minutes % 60 == 0 {
            let hours = minutes / 60
            return "每\(hours)小时"
        }
        if minutes > 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "每\(hours)小时\(remainingMinutes)分钟"
        }
        return "每\(minutes)分钟"
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
