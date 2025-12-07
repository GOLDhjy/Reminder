//
//  AppColors.swift
//  Reminder
//
//  Created by Claude Code on 2025/12/6.
//

import SwiftUI

struct AppColors {
    // MARK: - Primary Colors
    /// Primary icon background color - warm cream
    static let iconBackground = Color(red: 246/255, green: 238/255, blue: 229/255)

    /// Darker shade of icon background for hover/active states
    static let iconBackgroundDark = Color(red: 238/255, green: 226/255, blue: 213/255)

    // MARK: - Semantic Colors
    /// Primary accent color - terracotta
    static let primary = Color(red: 209/255, green: 125/255, blue: 95/255)

    /// Secondary accent color - muted sage
    static let secondary = Color(red: 171/255, green: 178/255, blue: 156/255)

    /// Background color for the app - soft parchment
    static let background = Color(red: 249/255, green: 244/255, blue: 236/255)

    /// Card background color - warm white with subtle tint
    static let cardBackground = Color(red: 253/255, green: 249/255, blue: 242/255)

    /// Elevated card background for prominent actions
    static let cardElevated = Color(red: 250/255, green: 241/255, blue: 232/255)

    /// Form/Sheet background color - slightly warmer than system background
    static let formBackground = Color(red: 248/255, green: 241/255, blue: 233/255)

    /// Section background color for forms
    static let sectionBackground = Color(red: 245/255, green: 236/255, blue: 225/255)

    /// Navigation/Toolbar background
    static let navigationBackground = Color(UIColor.systemBackground)

    // MARK: - Type-specific Colors
    static let water = Color(red: 132/255, green: 178/255, blue: 202/255)
    static let meal = Color(red: 222/255, green: 152/255, blue: 109/255)
    static let rest = Color(red: 174/255, green: 183/255, blue: 150/255)
    static let sleep = Color(red: 177/255, green: 156/255, blue: 164/255)
    static let medicine = Color(red: 206/255, green: 120/255, blue: 120/255)
    static let exercise = Color(red: 199/255, green: 166/255, blue: 110/255)
    static let cooking = Color(red: 205/255, green: 142/255, blue: 92/255)
    static let custom = Color(red: 155/255, green: 155/255, blue: 155/255)

    // MARK: - Status Colors
    static let success = Color(red: 164/255, green: 183/255, blue: 120/255)
    static let warning = Color(red: 222/255, green: 152/255, blue: 109/255)
    static let error = Color(red: 206/255, green: 120/255, blue: 120/255)

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
        case .cooking: return cooking
        case .rest: return rest
        case .sleep: return sleep
        case .medicine: return medicine
        case .exercise: return exercise
        case .custom: return custom
        }
    }
}
