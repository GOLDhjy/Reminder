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
    static let iconBackgroundDark = Color(red: 242/255, green: 237/255, blue: 225/255)

    // MARK: - Semantic Colors
    /// Primary accent color (blue)
    static let primary = Color.blue

    /// Secondary accent color (light blue variant)
    static let secondary = iconBackground

    /// Background color for the app - warmer cream background
    static let background = iconBackground

    /// Card background color - warm white with subtle tint
    static let cardBackground = Color(red: 253/255, green: 250/255, blue: 242/255)

    /// Form/Sheet background color - slightly warmer than system background
    static let formBackground = Color(red: 250/255, green: 248/255, blue: 243/255)

    /// Section background color for forms
    static let sectionBackground = Color(red: 252/255, green: 250/255, blue: 245/255)

    /// Navigation/Toolbar background
    static let navigationBackground = Color(UIColor.systemBackground)

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