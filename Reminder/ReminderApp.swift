//
//  ReminderApp.swift
//  Reminder
//
//  Created by 黄金溢 on 2025/12/6.
//

import SwiftUI
import SwiftData
import UserNotifications
import Intents

@main
struct ReminderApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var holidayManager = HolidayManager.shared
    @StateObject private var siriIntentsManager = SiriIntentsManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Legacy model for backward compatibility
            Item.self,
            // New models
            Reminder.self,
            ReminderLog.self,
            Holiday.self,
            HolidayCalendar.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Clear badge on app launch
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    setupServices()
                    requestNotificationPermission()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(notificationManager)
        .environmentObject(holidayManager)
        .environmentObject(siriIntentsManager)
    }

    private func setupServices() {
        // Inject model context into services
        let context = sharedModelContainer.mainContext
        holidayManager.setModelContext(context)
        notificationManager.setModelContext(context)
        siriIntentsManager.setModelContext(context)

        // Load holidays for current year and country
        let currentYear = Calendar.current.component(.year, from: Date())
        Task {
            await holidayManager.loadHolidays(for: "CN", year: currentYear)
        }
    }

    private func requestNotificationPermission() {
        Task {
            do {
                try await notificationManager.requestAuthorization()
            } catch {
                print("Failed to request notification authorization: \(error)")
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        Task {
            let externalManager = ExternalInterfaceManager()
            let modelContext = sharedModelContainer.mainContext
            externalManager.setModelContext(modelContext)
            await externalManager.handleIncomingURL(url)
        }
    }
}
