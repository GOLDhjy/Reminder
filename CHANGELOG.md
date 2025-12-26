# Changelog

本文档记录 Reminder 项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 待发布
- 项目持续开发中

## [1.0.0] - 2025-12-26

### Added
- 🎉 综合生活提醒应用初始发布
- ✨ 支持多种提醒类型：喝水、吃饭、做饭、休息、睡觉、吃药、运动
- ✨ TODO 任务管理功能，无时间限制的任务管理
- ✨ 计时任务功能，包含 15 个生活实用预设（烹饪、饮品、健康、自定义）
- ✨ 灵活的调度规则：单次、每天、每周、每月、每年重复
- ✨ 自定义间隔提醒（每 N 分钟重复）
- ✨ 节假日排除功能
- ✨ 智能通知系统，支持交互式操作（完成、延迟、忽略）
- ✨ URL Scheme API，支持第三方应用集成
- ✨ JSON 导入/导出功能
- ✨ Siri 语音创建和查询提醒
- ✨ 三段式布局：待办事项、进行中的提醒、已暂停/完成
- ✨ 自定义主题颜色系统
- ✨ 深色模式支持
- ✨ 多平台支持：iOS、macOS、visionOS
- 📝 完整的项目文档（README.md、CLAUDE.md、AGENTS.md）
- 🤖 GitHub Actions CI/CD 工作流
- 🚀 自动化发布流程

### Changed
- ♻️ 重构代码结构，优化项目架构
- 🎨 优化应用界面和用户交互体验
- 🎨 增强颜色管理和主题系统
- 🔔 重构通知管理器，提升通知调度效率
- 📱 优化添加提醒视图的交互流程

### Fixed
- 🐛 修复计时任务通知显示问题
- 🐛 优化提醒调度规则计算

### Documentation
- 📚 新增仓库指南文档（AGENTS.md）
- 📚 新增开发说明文档（CLAUDE.md）
- 📚 完善README功能描述和使用说明

---

## 变更类型说明

- **Added** - 新增功能
- **Changed** - 功能变更
- **Deprecated** - 即将废弃的功能
- **Removed** - 已删除的功能
- **Fixed** - Bug 修复
- **Security** - 安全性改进
- **Documentation** - 文档更新

---

## 版本规范

- **主版本号 (Major)**: 不兼容的 API 变更
- **次版本号 (Minor)**: 向下兼容的功能新增
- **修订号 (Patch)**: 向下兼容的 Bug 修复
