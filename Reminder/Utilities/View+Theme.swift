//
//  View+Theme.swift
//  Reminder
//
//  Created by Codex on 2025/2/9.
//

import SwiftUI

extension View {
    /// Consistent form/list background using app theme (avoids system white)
    func themedFormBackground(
        rowBackground: Color = AppColors.cardElevated,
        formBackground: Color = AppColors.formBackground
    ) -> some View {
        self
            .scrollContentBackground(.hidden)
            .listRowBackground(rowBackground)
            .background(formBackground)
    }
}
