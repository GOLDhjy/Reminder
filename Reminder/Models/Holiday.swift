import Foundation
import SwiftData

@Model
final class Holiday {
    var id: UUID
    var name: String
    var date: Date
    var isRecurring: Bool // 是否每年重复
    var country: String?
    var type: HolidayType

    init(name: String, date: Date, isRecurring: Bool = false, country: String? = nil, type: HolidayType = .national) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.isRecurring = isRecurring
        self.country = country
        self.type = type
    }

    enum HolidayType: String, Codable, CaseIterable {
        case national = "国家法定假日"
        case traditional = "传统节日"
        case international = "国际节日"
        case custom = "自定义"
    }
}

@Model
final class HolidayCalendar {
    var id: UUID
    var name: String
    var country: String
    var year: Int
    var holidays: [Holiday] = []

    init(name: String, country: String, year: Int) {
        self.id = UUID()
        self.name = name
        self.country = country
        self.year = year
    }
}