import Foundation

struct RepeatRuleCalculator {
    private let calendar = Calendar.current

    func nextTriggerDate(
        from date: Date,
        rule: RepeatRule,
        startDate: Date,
        endDate: Date?,
        excludeHolidays: Bool,
        timeOfDay: Date
    ) -> Date? {
        // Extract time component
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOfDay)

        // One-time reminders use their start day and do not repeat
        if case .never = rule {
            let baseDay = calendar.startOfDay(for: startDate)
            let candidate = calendar.date(
                bySettingHour: timeComponents.hour ?? 0,
                minute: timeComponents.minute ?? 0,
                second: 0,
                of: baseDay
            ) ?? startDate

            // Only fire if the scheduled time is still in the future
            return candidate > date ? candidate : nil
        }

        // Check if we should start from today or tomorrow
        var searchDate: Date
        if date < startDate {
            searchDate = startDate
        } else {
            // Get today's date with the target time
            let today = calendar.startOfDay(for: date)
            if let todayWithTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                               minute: timeComponents.minute ?? 0,
                                               second: 0,
                                               of: today) {
                // If the target time has passed today, start from tomorrow
                if todayWithTime <= date {
                    searchDate = calendar.date(byAdding: .day, value: 1, to: todayWithTime) ?? todayWithTime
                } else {
                    searchDate = todayWithTime
                }
            } else {
                searchDate = date
            }
        }

        // Generate candidate dates up to end date or 1 year from now
        let maxDate = endDate ?? calendar.date(byAdding: .year, value: 1, to: searchDate) ?? searchDate

        return findNextValidDate(
            from: searchDate,
            to: maxDate,
            rule: rule,
            startDate: startDate,
            timeComponents: timeComponents,
            excludeHolidays: excludeHolidays
        )
    }

    private func findNextValidDate(
        from searchDate: Date,
        to maxDate: Date,
        rule: RepeatRule,
        startDate: Date,
        timeComponents: DateComponents,
        excludeHolidays: Bool
    ) -> Date? {
        var currentDate = searchDate

        while currentDate <= maxDate {
            // Apply time of day
            if let dateWithTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                              minute: timeComponents.minute ?? 0,
                                              second: 0,
                                              of: currentDate) {
                // Check if matches rule
                if matchesRule(dateWithTime, rule: rule, startDate: startDate) {
                    // Check holiday exclusion
                    if !excludeHolidays || !isHoliday(dateWithTime) {
                        return dateWithTime
                    }
                }
            }

            // Move to next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }

        return nil
    }

    func matchesRule(_ date: Date, rule: RepeatRule, startDate: Date) -> Bool {
        switch rule {
        case .never:
            // Only match the start date once for non-repeating timers
            return calendar.isDate(date, inSameDayAs: startDate) && date >= startDate

        case .daily:
            return date >= startDate

        case .weekly(let weekdays):
            guard let weekday = calendar.dateComponents([.weekday], from: date).weekday,
                  let weekDay = Weekday(rawValue: weekday) else {
                return false
            }
            return weekdays.contains(weekDay) && date >= startDate

        case .monthly(let day):
            let dayOfMonth = calendar.component(.day, from: date)
            return dayOfMonth == day && date >= startDate

        case .yearly(let month, let day):
            let monthOfYear = calendar.component(.month, from: date)
            let dayOfMonth = calendar.component(.day, from: date)
            return monthOfYear == month && dayOfMonth == day && date >= startDate
        }
    }

    private func isHoliday(_ date: Date) -> Bool {
        // For now, implement a simple check without accessing HolidayManager
        // In a production app, you would want to handle the MainActor access properly
        return false
    }

    func generateSchedule(
        from startDate: Date,
        to endDate: Date,
        rule: RepeatRule,
        excludeHolidays: Bool,
        timeOfDay: Date
    ) -> [Date] {
        var schedule: [Date] = []
        var currentDate = startDate

        while currentDate <= endDate {
            if let nextDate = nextTriggerDate(
                from: currentDate,
                rule: rule,
                startDate: startDate,
                endDate: endDate,
                excludeHolidays: excludeHolidays,
                timeOfDay: timeOfDay
            ) {
                schedule.append(nextDate)
                currentDate = nextDate
            } else {
                break
            }
        }

        return schedule
    }
}
