import Foundation
import SwiftData

@MainActor
class HolidayManager: ObservableObject {
    static let shared = HolidayManager()

    @Published var holidays: [Holiday] = []
    @Published var isLoading = false

    private let calendar = Calendar.current
    private var modelContext: ModelContext?

    private init() {
        // Initialize with model context if available
        // This will be set properly when integrated with the app
        self.modelContext = nil
    }

    func setModelContext(_ context: ModelContext) {
        // Set the model context for database operations
        // This is a workaround since we can't easily inject ModelContext in init
        self.modelContext = context
    }

    // Load predefined holidays for different countries
    func loadHolidays(for country: String, year: Int) async {
        isLoading = true
        defer { isLoading = false }

        // For now, we'll load some common Chinese holidays
        // In a real app, you might want to fetch from an API or have a more comprehensive list
        if country == "CN" {
            loadChineseHolidays(year: year)
        } else {
            // Default to some common international holidays
            loadInternationalHolidays(year: year)
        }
    }

    private func loadChineseHolidays(year: Int) {
        // This is a simplified implementation
        // In production, you'd want a complete list or API integration
        let chineseHolidays: [(name: String, month: Int, day: Int, isRecurring: Bool)] = [
            ("元旦", 1, 1, true),
            ("春节", 2, 10, false), // Example date, would need proper lunar calendar calculation
            ("清明节", 4, 5, false),
            ("劳动节", 5, 1, true),
            ("端午节", 6, 10, false), // Example date
            ("中秋节", 9, 15, false), // Example date
            ("国庆节", 10, 1, true)
        ]

        for holiday in chineseHolidays {
            let components = DateComponents(year: year, month: holiday.month, day: holiday.day)
            if let date = calendar.date(from: components) {
                let holidayModel = Holiday(
                    name: holiday.name,
                    date: date,
                    isRecurring: holiday.isRecurring,
                    country: "CN",
                    type: holiday.isRecurring ? .national : .traditional
                )
                holidays.append(holidayModel)
            }
        }
    }

    private func loadInternationalHolidays(year: Int) {
        let internationalHolidays: [(name: String, month: Int, day: Int, isRecurring: Bool)] = [
            ("New Year's Day", 1, 1, true),
            ("Valentine's Day", 2, 14, true),
            ("International Workers' Day", 5, 1, true),
            ("Christmas Day", 12, 25, true)
        ]

        for holiday in internationalHolidays {
            let components = DateComponents(year: year, month: holiday.month, day: holiday.day)
            if let date = calendar.date(from: components) {
                let holidayModel = Holiday(
                    name: holiday.name,
                    date: date,
                    isRecurring: holiday.isRecurring,
                    country: "INT",
                    type: .international
                )
                holidays.append(holidayModel)
            }
        }
    }

    // Check if date is a holiday
    func isHoliday(_ date: Date) -> Bool {
        // Check for exact match
        if holidays.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            return true
        }

        // Check for recurring holidays
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        return holidays.contains { holiday in
            guard holiday.isRecurring else { return false }
            let holidayMonth = calendar.component(.month, from: holiday.date)
            let holidayDay = calendar.component(.day, from: holiday.date)
            return holidayMonth == month && holidayDay == day
        }
    }

    // Add custom holidays
    func addHoliday(_ holiday: Holiday) {
        holidays.append(holiday)
        saveHoliday(holiday)
    }

    private func saveHoliday(_ holiday: Holiday) {
        // Save to SwiftData if model context is available
        // This would be implemented when the model context is properly injected
    }

    // Import holidays from external source
    func importHolidays(from url: URL) async throws {
        // Implementation for importing holidays from JSON or other formats
        guard let data = try? Data(contentsOf: url),
              let holidayData = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw HolidayImportError.invalidFormat
        }

        var importedHolidays: [Holiday] = []

        for item in holidayData {
            if let name = item["name"] as? String,
               let dateString = item["date"] as? String,
               let date = ISO8601DateFormatter().date(from: dateString) {

                let isRecurring = item["isRecurring"] as? Bool ?? false
                let country = item["country"] as? String
                let typeRaw = item["type"] as? String
                let type = Holiday.HolidayType(rawValue: typeRaw ?? "custom") ?? .custom

                let holiday = Holiday(
                    name: name,
                    date: date,
                    isRecurring: isRecurring,
                    country: country,
                    type: type
                )

                importedHolidays.append(holiday)
            }
        }

        holidays.append(contentsOf: importedHolidays)
    }

    enum HolidayImportError: Error, LocalizedError {
        case invalidFormat
        case corruptedData

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid holiday data format"
            case .corruptedData:
                return "The holiday data file is corrupted"
            }
        }
    }
}