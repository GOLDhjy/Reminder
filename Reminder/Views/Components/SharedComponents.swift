import SwiftUI

// MARK: - Section Card
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Repeat Chip
struct RepeatChip: View {
    let rule: RepeatRule
    let isSelected: Bool
    let action: () -> Void

    private var displayText: String {
        switch rule {
        case .weekly(let weekdays):
            let weekdaySet = Set(weekdays)
            if weekdaySet == RepeatRule.workdayWeekdays {
                return "工作日"
            }
            if weekdaySet == RepeatRule.weekendWeekdays {
                return "周末"
            }
            return "每周"
        case .intervalMinutes:
            return rule.shortDescription
        default:
            return rule.displayName
        }
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppColors.primary : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? AppColors.primary : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// TimerPreset 已在 Reminder.swift 中定义

// MARK: - Weekday Picker
struct WeekdayPicker: View {
    @Binding var selectedWeekdays: Set<Weekday>

    private let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            ForEach(weekdays, id: \.self) { weekday in
                WeekdayButton(
                    weekday: weekday,
                    isSelected: selectedWeekdays.contains(weekday)
                ) {
                    if selectedWeekdays.contains(weekday) {
                        selectedWeekdays.remove(weekday)
                    } else {
                        selectedWeekdays.insert(weekday)
                    }
                }
            }
        }
    }
}

// MARK: - Weekday Button
private struct WeekdayButton: View {
    let weekday: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(weekday.shortName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.primary : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// Weekday.shortName 已在 Reminder.swift 中定义

// MARK: - RepeatRule Extension
extension RepeatRule {
    var displayName: String {
        switch self {
        case .never: return "一次"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        case .intervalMinutes: return "自定义"
        }
    }
}
