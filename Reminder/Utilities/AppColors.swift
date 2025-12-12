//
//  AppColors.swift
//  Reminder
//
//  Created by Claude Code on 2025/12/6.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct AppColors {
    // MARK: - Primary Colors
    /// Primary icon background color - warm cream
    static let iconBackground = adaptiveColor(
        light: (246, 238, 229),
        dark: (70, 60, 54)
    )

    /// Darker shade of icon background for hover/active states
    static let iconBackgroundDark = adaptiveColor(
        light: (238, 226, 213),
        dark: (88, 74, 66)
    )

    // MARK: - Semantic Colors
    /// Primary accent color - terracotta
    static let primary = Color(red: 209/255, green: 125/255, blue: 95/255)

    /// Secondary accent color - muted sage
    static let secondary = Color(red: 171/255, green: 178/255, blue: 156/255)

    /// Background color for the app - soft parchment
    static let background = adaptiveColor(
        light: (249, 244, 236),
        dark: (17, 15, 13)
    )

    /// Card background color - warm white with subtle tint
    static let cardBackground = adaptiveColor(
        light: (253, 249, 242),
        dark: (27, 23, 20)
    )

    /// Elevated card background for prominent actions
    static let cardElevated = adaptiveColor(
        light: (250, 241, 232),
        dark: (33, 28, 24)
    )

    /// Form/Sheet background color - slightly warmer than system background
    static let formBackground = adaptiveColor(
        light: (248, 241, 233),
        dark: (24, 21, 18)
    )

    /// Section background color for forms
    static let sectionBackground = adaptiveColor(
        light: (245, 236, 225),
        dark: (38, 33, 28)
    )

    /// Navigation/Toolbar background
    static let navigationBackground = {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }()

    // MARK: - Type-specific Colors
    static let water = Color(red: 132/255, green: 178/255, blue: 202/255)
    static let meal = Color(red: 222/255, green: 152/255, blue: 109/255)
    static let rest = Color(red: 174/255, green: 183/255, blue: 150/255)
    static let sleep = Color(red: 177/255, green: 156/255, blue: 164/255)
    static let medicine = Color(red: 206/255, green: 120/255, blue: 120/255)
    static let exercise = Color(red: 199/255, green: 166/255, blue: 110/255)
    static let cooking = Color(red: 205/255, green: 142/255, blue: 92/255)
    static let todo = Color(red: 99/255, green: 102/255, blue: 241/255)  // Indigo color
    static let custom = Color(red: 155/255, green: 155/255, blue: 155/255)
    static let timer = Color(red: 175/255, green: 122/255, blue: 197/255)  // Purple color for timer tasks

    // MARK: - Status Colors
    static let success = Color(red: 164/255, green: 183/255, blue: 120/255)
    static let warning = Color(red: 222/255, green: 152/255, blue: 109/255)
    static let error = Color(red: 206/255, green: 120/255, blue: 120/255)

    // MARK: - Text Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let accentText = Color.accentColor

    // MARK: - Shadow Colors
    static let shadow = adaptiveColor(
        light: (0, 0, 0),
        dark: (0, 0, 0),
        alpha: 0.08,
        darkAlpha: 0.32
    )
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
        case .todo: return todo
        case .custom: return custom
        case .timer: return timer
        }
    }

    
    // MARK: - Helpers
    private static func adaptiveColor(
        light: (Double, Double, Double),
        dark: (Double, Double, Double),
        alpha: Double = 1.0,
        darkAlpha: Double? = nil
    ) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traitCollection in
            let rgb = traitCollection.userInterfaceStyle == .dark ? dark : light
            let resolvedAlpha = traitCollection.userInterfaceStyle == .dark ? (darkAlpha ?? alpha) : alpha
            return UIColor(
                red: rgb.0/255,
                green: rgb.1/255,
                blue: rgb.2/255,
                alpha: resolvedAlpha
            )
        })
        #else
        return Color(
            red: light.0/255,
            green: light.1/255,
            blue: light.2/255,
            opacity: alpha
        )
        #endif
    }
}
