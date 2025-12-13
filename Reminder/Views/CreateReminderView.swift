import SwiftUI
import SwiftData

struct CreateReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var reminder: Reminder?
    var initialMode: ReminderCreationMode?

    @State private var selectedMode: ReminderCreationMode = .timeReminder

    private var isEditing: Bool {
        reminder != nil
    }

    init(reminder: Reminder? = nil, initialMode: ReminderCreationMode? = nil) {
        self.reminder = reminder
        self.initialMode = initialMode

        if let reminder = reminder {
            // 根据提醒类型设置初始模式
            if reminder.type == .todo {
                _selectedMode = State(initialValue: .todo)
            } else if reminder.type == .timer {
                _selectedMode = State(initialValue: .timer)
            } else {
                _selectedMode = State(initialValue: .timeReminder)
            }
        } else if let initialMode = initialMode {
            _selectedMode = State(initialValue: initialMode)
        }
    }

    var body: some View {
        Group {
            switch selectedMode {
            case .timeReminder:
                TimeReminderView(reminder: reminder)
            case .todo:
                TodoReminderView(reminder: reminder)
            case .timer:
                TimerTaskSheet(reminder: reminder)
            }
        }
    }
}

// MARK: - Reminder Creation Mode
enum ReminderCreationMode: CaseIterable {
    case timeReminder
    case todo
    case timer

    var title: String {
        switch self {
        case .timeReminder:
            return "时间提醒"
        case .todo:
            return "待办事项"
        case .timer:
            return "计时任务"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)

    CreateReminderView()
        .modelContainer(container)
}