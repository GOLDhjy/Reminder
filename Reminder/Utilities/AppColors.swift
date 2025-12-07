//
//  AppColors.swift
//  Reminder
//
//  Created by Claude Code on 2025/12/6.
//

import SwiftUI

struct AppColors {
    // MARK: - Primary Colors
    /// Primary icon background color (RGB: 247, 242, 230)
    static let iconBackground = Color(red: 247/255, green: 242/255, blue: 230/255)

    /// Darker shade of icon background for hover/active states
    static let iconBackgroundDark = Color(red: 237/255, green: 232/255, blue: 220/255)

    // MARK: - Semantic Colors
    /// Primary accent color (blue)
    static let primary = Color.blue

    /// Secondary accent color (light blue variant)
    static let secondary = iconBackground

    /// Background color for the app
    static let background = Color(.systemGroupedBackground)

    /// Card background color
    static let cardBackground = Color(.secondarySystemGroupedBackground)

    // MARK: - Type-specific Colors
    static let water = Color.blue
    static let meal = Color.orange
    static let rest = Color.green
    static let sleep = Color.purple
    static let medicine = Color.red
    static let exercise = Color.mint
    static let custom = Color.gray

    // MARK: - Status Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // MARK: - Text Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let accentText = Color.accentColor

    // MARK: - Shadow Colors
    static let shadow = Color.black.opacity(0.05)
    static let primaryShadow = Color.blue.opacity(0.3)

    // MARK: - Helper Methods
    /// Returns color for reminder type
    static func colorForType(_ type: ReminderType) -> Color {
        switch type {
        case .water: return water
        case .meal: return meal
        case .rest: return rest
        case .sleep: return sleep
        case .medicine: return medicine
        case .exercise: return exercise
        case .custom: return custom
        }
    }
}