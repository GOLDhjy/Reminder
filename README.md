# Reminder

> 使用 Claude 和 Codex 开发，仍需人工引导与调试。

综合生活提醒应用，支持多种提醒类型、TODO任务管理、计时任务、节假日管理，并适配 iOS/macOS/visionOS 多平台。

## 运行
- 要求：Xcode 16+，iOS 18+（SwiftData）。
- 打开 `Reminder.xcodeproj`，运行 `Reminder` 目标即可。

## 特性

### 1. 多种提醒类型
- **常规提醒**：喝水、吃饭、做饭、休息、睡觉、吃药、运动等预设类型
- **TODO任务**：无时间限制的任务管理，复选框界面
- **计时任务**：倒计时提醒，包含15个生活实用预设

### 2. 计时任务预设
- **烹饪类**：煮面(5min)、煮鸡蛋(8min)、煲汤(45min)、蒸蛋(10min)、焖饭(20min)、烤面包(3min)、提醒关火(30min)
- **饮品类**：泡茶(3min)、咖啡(5min)
- **健康类**：运动间歇(15min)、番茄工作法(25min)、休息一下(5min)、眼保健操(3min)、面膜时间(15min)
- **自定义**：用户可自由设置时长

### 3. 灵活的调度规则
- 重复模式：单次、每天、每周（可选工作日/周末）、每月、每年
- 自定义间隔：每N分钟重复
- 节假日排除功能
- 可选结束日期

### 4. 智能通知系统
- 本地推送通知，支持自定义内容
- 交互式操作（完成、延迟、忽略）
- 声音和震动支持
- 后台自动调度

### 5. 外部集成
- URL Scheme API，支持第三方应用集成
- JSON 导入/导出功能
- Siri 语音创建和查询提醒

### 6. UI/UX 设计
- 三段式布局：待办事项、进行中的提醒、已暂停/完成
- 紫色主题区分计时任务
- 网格化预设选择界面
- 深色模式友好
- 底部创建按钮，避免误触

## 开发提示

### 核心文件结构
- **数据模型** (`Models/`)：
  - `Reminder.swift` - 提醒数据模型，支持多种类型和重复规则
  - `ReminderLog.swift` - 提醒历史记录
  - `Holiday.swift` - 节假日管理

- **服务层** (`Services/`)：
  - `NotificationManager.swift` - 通知调度管理
  - `HolidayManager.swift` - 节假日数据管理
  - `RepeatRuleCalculator.swift` - 重复规则计算器
  - `ExternalInterfaceManager.swift` - URL Scheme API
  - `SiriIntentsManager.swift` - Siri 集成

- **视图层** (`Views/`)：
  - `ContentView.swift` - 主界面，三段式列表展示
  - `AddReminderView.swift` - 常规提醒创建界面
  - `TimerTaskSheet.swift` - 计时任务创建界面，包含预设网格
  - `SettingsView.swift` - 设置和节假日管理

### 主题色系统
- 所有颜色定义在 `Utilities/AppColors.swift`
- 支持自适应浅色/深色模式
- 每种提醒类型都有专属配色

### 数据持久化
- 使用 SwiftData 进行本地存储
- 支持 iCloud 同步（需要配置）
- 自动清理过期的一次性提醒

### 多平台支持
- iOS：原生体验，支持动态岛和实时活动
- macOS：菜单栏集成，键盘快捷键
- visionOS：空间计算适配
