//
//  CheckDayIntent.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import AppIntents
import ZCCalendar

struct CheckDayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.check.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is an off day, otherwise, it is a work day.", categoryName: "Check")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("Which day?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is \(\.$date) an Off Day?")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if target.weekdayOrder().isWeekEnd {
                isOffDay = true
            } else {
                isOffDay = false
            }
            if let publicDay = Mainland2024().days[target.julianDay] as? PublicDay {
                switch publicDay.dayType {
                case .offday:
                    isOffDay = true
                case .workday:
                    isOffDay = false
                }
            }
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.check.today.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is an off day, otherwise, it is a work day.", categoryName: "Check")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is Today an Off Day?")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if target.weekdayOrder().isWeekEnd {
                isOffDay = true
            } else {
                isOffDay = false
            }
            if let publicDay = Mainland2024().days[target.julianDay] as? PublicDay {
                switch publicDay.dayType {
                case .offday:
                    isOffDay = true
                case .workday:
                    isOffDay = false
                }
            }
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckTomorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.check.tomorrow.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is an off day, otherwise, it is a work day.", categoryName: "Check")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is Tomorrow an Off Day?")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if target.weekdayOrder().isWeekEnd {
                isOffDay = true
            } else {
                isOffDay = false
            }
            if let publicDay = Mainland2024().days[target.julianDay] as? PublicDay {
                switch publicDay.dayType {
                case .offday:
                    isOffDay = true
                case .workday:
                    isOffDay = false
                }
            }
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}
