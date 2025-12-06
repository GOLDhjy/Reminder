//
//  Item.swift
//  Reminder
//
//  Created by 黄金溢 on 2025/12/6.
//

import Foundation
import SwiftData

// MARK: - Legacy Item Model (Deprecated)
// This model is kept for backward compatibility
// Use Reminder model instead for new functionality
@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
