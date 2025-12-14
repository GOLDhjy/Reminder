import SwiftUI
import SwiftData

struct TodoReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var reminder: Reminder?

    @State private var title = ""
    @State private var notes = ""
    @State private var userEditedTitle = false
    @State private var selectedTemplateTitle: String?

    private var isEditing: Bool {
        reminder != nil
    }

    // 快速模板
    private var quickTemplates: [ReminderTemplate] {
        [
            ReminderTemplate(
                title: "买菜",
                icon: "cart.fill",
                type: .todo
            ),
            ReminderTemplate(
                title: "交水电费",
                icon: "doc.text.fill",
                type: .todo
            ),
            ReminderTemplate(
                title: "打扫房间",
                icon: "broom.fill",
                type: .todo
            ),
            ReminderTemplate(
                title: "取快递",
                icon: "box.truck.fill",
                type: .todo
            )
        ]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 说明文字
                    infoCard

                    // 快速模板
                    quickTemplatesSection

                    // 标题
                    titleSection

                    // 备注
                    notesSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(isEditing ? "编辑待办" : "创建待办")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if reminder != nil {
                        updateTodo()
                    } else {
                        saveTodo()
                    }
                } label: {
                    Text(reminder == nil ? "创建待办" : "更新待办")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.todo)
                        )
                        .padding(.horizontal, 20)
                        .shadow(color: AppColors.todo.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 0)
                .padding(.bottom, 0)
                .disabled(title.isEmpty)
                .opacity(title.isEmpty ? 0.5 : 1)
            }
        }
        .background(AppColors.formBackground.ignoresSafeArea())
        .onAppear {
            if let reminder = reminder {
                title = reminder.title
                notes = reminder.notes ?? ""
                userEditedTitle = true
                selectedTemplateTitle = quickTemplates.first(where: { $0.title == reminder.title })?.title
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppColors.todo)
                Text("关于待办事项")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text("待办事项没有时间限制，完成后会自动删除。适合记录需要完成的任务。")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.todo.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.todo.opacity(0.3), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var quickTemplatesSection: some View {
        SectionCard(title: "常用待办") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(quickTemplates, id: \.title) { template in
                    ReminderTemplateCard(
                        title: template.title,
                        icon: template.icon,
                        color: AppColors.todo,
                        isSelected: selectedTemplateTitle == template.title
                    ) {
                        selectedTemplateTitle = template.title
                        title = template.title
                        userEditedTitle = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        SectionCard(title: "待办内容") {
            TextField("请输入待办事项", text: $title)
                .font(.headline)
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    userEditedTitle = true
                }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        SectionCard(title: "详细描述（可选）") {
            TextField("添加更多详细信息...", text: $notes, axis: .vertical)
                .font(.subheadline)
                .textFieldStyle(PlainTextFieldStyle())
                .lineLimit(3)
        }
    }

    // MARK: - Helper Methods

    private func saveTodo() {
        let newReminder = Reminder(
            title: title.isEmpty ? "待办事项" : title,
            type: .todo,
            timeOfDay: Date(),
            repeatRule: .never,
            notes: notes.isEmpty ? nil : notes
        )
        newReminder.isActive = true

        modelContext.insert(newReminder)
        try? modelContext.save()

        dismiss()
    }

    private func updateTodo() {
        guard let reminder = reminder else { return }

        reminder.title = title
        reminder.notes = notes.isEmpty ? nil : notes
        reminder.type = .todo
        reminder.updatedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Reminder.self, ReminderLog.self, Holiday.self, HolidayCalendar.self, configurations: config)

    NavigationView {
        TodoReminderView()
            .modelContainer(container)
    }
}
