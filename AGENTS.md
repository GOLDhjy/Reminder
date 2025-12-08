# Repository Guidelines

## Project Structure & Module Organization
- App code lives in `Reminder/`: `Views/` (SwiftUI screens and sheets), `Models/` (SwiftData entities like `Reminder`, `ReminderLog`, `Holiday`), `Services/` (notification scheduling, holiday loading, Siri intents, repeat rule calculator), `Utilities/` (theme helpers such as `AppColors.swift`, constants), `Resources/` (assets including app icons), `Intents/` (intent handler), and `Preview Content/` for SwiftUI previews.
- Tests sit beside the app: `ReminderTests/` for unit-style tests using the `Testing` module, `ReminderUITests/` for XCTest UI coverage and launch performance checks.
- App configuration is in `Reminder/Info.plist` and entitlements in `Reminder/Reminder.entitlements`; the project file is `Reminder.xcodeproj`.

## Build, Test, and Development Commands
- Open in Xcode 15+ (iOS 17+ target): `open Reminder.xcodeproj` and run the `Reminder` scheme.
- CLI build example: `xcodebuild -scheme Reminder -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- Full test run (unit + UI): `xcodebuild -scheme Reminder -destination 'platform=iOS Simulator,name=iPhone 15' test`.
- Targeted suites: `xcodebuild -scheme Reminder -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:ReminderTests` or `-only-testing:ReminderUITests`.

## Coding Style & Naming Conventions
- Swift style with 4-space indentation; keep `// MARK:` sections and lightweight doc comments for non-obvious logic.
- Types use PascalCase; properties, functions, and enum cases use camelCase (`notificationManager`, `handleIncomingURL`).
- Favor SwiftUI patterns with environment objects and `@StateObject`; keep services injectable via setters before use (see managers in `ReminderApp`).
- Reuse theming helpers instead of hardcoding colors: prefer `AppColors` and `View+Theme` extensions.
- Keep view files focused (UI + small state), move business logic to `Services/` or dedicated helpers.

## Testing Guidelines
- Unit tests: use the `Testing` module with `@Test func testCaseName() async throws` and `#expect` assertions; place fixtures close to the test file.
- UI tests: extend `ReminderUITests` with `@MainActor` methods; set `continueAfterFailure = false` and launch via `XCUIApplication().launch()`.
- Add tests for date/recurrence logic, notification scheduling boundaries, and SwiftData persistence migrations.
- Run tests on iPhone 15 (iOS 17 simulator) to match the target; avoid flakiness from notification permission prompts by stubbing where possible.

## Commit & Pull Request Guidelines
- Git history mixes short Chinese summaries and occasional conventional prefixes (e.g., `feat:`). Prefer present-tense, concise titles: `feat: add repeat rule calculator` or `修复: 节假日加载失败`.
- PRs should describe scope, risks, and test coverage; link related issues/tasks. Include screenshots or screen recordings for UI changes (light and dark mode) and note any simulator/device quirks.
- Before opening a PR: ensure build + tests pass, check for regressions in reminders scheduling, and confirm themes still use `AppColors` without reintroducing white backgrounds.
