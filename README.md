# Reminder

SwiftUI 提醒应用，支持自定义提醒、定时任务、节假日管理，并适配浅色/深色模式。

## 运行
- 要求：Xcode 15+，iOS 17+（SwiftData）。
- 打开 `Reminder.xcodeproj`，运行 `Reminder` 目标即可。

## 特性
- SwiftData 持久化提醒、日志、节假日。
- 通知调度与测试 (`NotificationManager`)。
- 定时任务和常规提醒，支持重复规则、节假日排除。
- 自定义主题色，覆盖系统 Form/List 白底，暗黑模式友好。
- 新建提醒/定时任务时，按类型自动填充默认标题（用户手动修改后不覆盖）。

## 开发提示
- 主题色位于 `Utilities/AppColors.swift`；统一表单背景扩展在 `Utilities/View+Theme.swift`。
- 首页列表默认使用自定义布局，需切换回系统 `List` 可将 `useCustomList` 设为 `false`（`Views/ContentView.swift`）。
- UIKit 表单背景已在 `ReminderApp` 的 `init` 中设置，运行前重启 App 可生效。
