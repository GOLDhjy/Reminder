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
                .background(AppColors.secondary.ignoresSafeArea())
                .onAppear {
                    // Clear badge on app launch
                    #if os(iOS)
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    #endif
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

                // After getting permission, check and debug notification settings
                #if os(iOS)
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                print("=== Notification Settings Debug ===")
                print("Authorization status: \(settings.authorizationStatus)")
                print("Alert setting: \(settings.alertSetting)")
                print("Sound setting: \(settings.soundSetting)")
                print("Badge setting: \(settings.badgeSetting)")
                print("Critical alert setting: \(settings.criticalAlertSetting)")
                print("Lock screen setting: \(settings.lockScreenSetting)")
                print("Notification center setting: \(settings.notificationCenterSetting)")
                print("Car play setting: \(settings.carPlaySetting)")

                // Check app icon configuration
                print("=== App Icon Debug ===")
                print("Bundle identifier: \(Bundle.main.bundleIdentifier ?? "unknown")")
                print("App icon files configured in Info.plist")
                #endif
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
