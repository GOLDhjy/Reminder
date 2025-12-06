# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive life reminder application built with SwiftUI and SwiftData. The app supports multiple platforms (iOS, macOS, visionOS) and provides full-featured reminder functionality with notifications, Siri integration, and external API support.

## Build and Development Commands

```bash
# Build the project
xcodebuild -project Reminder.xcodeproj -scheme Reminder -configuration Debug build

# Build for release
xcodebuild -project Reminder.xcodeproj -scheme Reminder -configuration Release build

# Run on simulator (update device name as needed)
xcodebuild -project Reminder.xcodeproj -scheme Reminder -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run unit tests only
xcodebuild test -project Reminder.xcodeproj -scheme Reminder -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ReminderTests

# Run UI tests only
xcodebuild test -project Reminder.xcodeproj -scheme Reminder -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ReminderUITests

# Clean build
xcodebuild clean -project Reminder.xcodeproj -scheme Reminder

# Open in Xcode (for interactive development)
open Reminder.xcodeproj
```

## Architecture

### Core Components

- **SwiftData**: Primary data persistence layer using `@Model` classes with complex relationships
- **SwiftUI**: Declarative UI framework with MVVM pattern
- **UserNotifications**: Local notification system for reminders
- **Intents Framework**: Siri integration for voice commands
- **Multi-platform Support**: Conditional compilation for iOS/macOS/visionOS

### Key Files

**App Configuration**
- `ReminderApp.swift`: App entry point with SwiftData, NotificationManager, HolidayManager, and SiriIntentsManager setup
- `Info.plist`: App permissions, URL schemes, and background modes

**Data Models (`Reminder/Models/`)**
- `Reminder.swift`: Core reminder model with scheduling rules and metadata
- `ReminderLog.swift`: History tracking for reminder triggers and actions
- `Holiday.swift`: Holiday management for exclusion functionality

**Services (`Reminder/Services/`)**
- `NotificationManager.swift`: Handles scheduling and managing local notifications
- `HolidayManager.swift`: Manages holiday data and exclusion rules
- `RepeatRuleCalculator.swift`: Calculates next trigger dates for recurring reminders
- `ExternalInterfaceManager.swift`: URL Scheme API for external app integration
- `SiriIntentsManager.swift`: Siri integration for voice commands

**Views (`Reminder/Views/`)**
- `ContentView.swift`: Main interface with reminder list and filtering
- `AddReminderView.swift`: Comprehensive reminder creation interface
- `ReminderDetailView.swift`: Detailed view and editing interface
- `SettingsView.swift`: App settings, holiday management, and configuration

### Data Model Structure

The app uses SwiftData with comprehensive models:

**Reminder Model Features:**
- Basic info: title, notes, type (water, meal, rest, sleep, medicine, custom)
- Schedule: timeOfDay, startDate, endDate, repeatRule
- Options: excludeHolidays, isActive, snoozeCount
- Relationships: logs for tracking history

**RepeatRule Enum:**
- Never, Daily, Weekly (array of weekdays), Monthly (day of month), Yearly (month, day)

**Holiday Integration:**
- Predefined holidays for different countries
- Custom holiday support
- Automatic exclusion from scheduled reminders

## Testing

### Frameworks
- **Unit Tests**: Swift Testing framework
- **UI Tests**: XCUITest framework for automation testing

### Test Structure
- `ReminderTests/ReminderTests.swift`: Unit tests for core functionality
- `ReminderUITests/`: UI automation tests for user workflows

## External Integration

### URL Scheme API
- **Scheme**: `reminder://`
- **Operations**:
  - Add reminders: `reminder://add?title=喝水&time=10:00&repeat=daily&type=water`
  - Toggle reminders: `reminder://toggle?id=[UUID]`
  - Complete reminders: `reminder://complete?id=[UUID]`
  - List reminders: `reminder://list?type=water`

### Siri Shortcuts
**Voice Commands:**
- "提醒我[时间][内容]" - Create immediate reminders
- "每天[时间][内容]" - Create daily recurring reminders
- "每周[时间][内容]" - Create weekly recurring reminders
- "显示我的提醒" - View all reminders

## Development Requirements

- **Xcode 16.0+** (for latest iOS 18+ features)
- **Swift 5.9+** (for SwiftData and modern SwiftUI)
- **Apple Developer Account** (for notifications and distribution)

## Key Features Implemented

1. **Comprehensive Reminder Types**
   - Preset types: Water, Meals, Rest, Sleep, Medicine
   - Custom reminder types with full customization
   - Visual differentiation with icons and colors

2. **Flexible Scheduling**
   - Multiple repeat patterns: Daily, Weekly, Monthly, Yearly
   - Custom weekday selection
   - Optional end dates
   - Holiday exclusion functionality

3. **Smart Notifications**
   - Local notifications with custom content
   - Interactive actions (Complete, Snooze, Dismiss)
   - Sound and vibration support
   - Background scheduling

4. **External API Support**
   - Complete URL Scheme implementation
   - JSON export/import functionality
   - Third-party app integration capabilities

5. **Cross-Platform Support**
   - iOS, macOS, and visionOS native UI
   - Platform-specific optimizations
   - Consistent functionality across devices

6. **Siri Integration**
   - Voice command support for creating reminders
   - Natural language understanding
   - Query existing reminders via Siri

## Common Development Patterns

### Adding New Reminder Types
```swift
// Extend ReminderType enum in Reminder.swift
enum ReminderType: String, CaseIterable, Codable, Identifiable, Hashable {
    case water = "喝水"
    case meal = "吃饭"
    case exercise = "运动"  // Add new type here
    // ... existing types
}
```

### Scheduling Complex Reminders
```swift
// Example: Create a reminder that repeats every other day
let calendar = Calendar.current
let startDate = Date()
let nextTrigger = calendar.date(byAdding: .day, value: 2, to: startDate)!
```

### Testing Notification Scheduling
```swift
// In tests, verify notification creation
let expectation = XCTestExpectation(description: "Notification scheduled")
NotificationCenter.default.addObserver(forName: .testNotification, object: nil, queue: .main) { _ in
    expectation.fulfill()
}
```