//
//  CheckDayIntent.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import AppIntents
import ZCCalendar

enum FetchError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case overReach
    case notFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .overReach:
            return "intent.error.overReach"
        case .notFound:
            return "intent.error.notFound"
        }
    }
}

struct CheckDayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.check.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is an off day, otherwise, it is a work day.", categoryName: "Check Off Day")
    
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
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isOffDay()
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.check.today.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is an off day, otherwise, it is a work day.", categoryName: "Check Off Day")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is Today an Off Day?")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isOffDay()
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckTomorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.check.tomorrow.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is an off day, otherwise, it is a work day.", categoryName: "Check Off Day")
    
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
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isOffDay()
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckOffsetDayOffIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.check.offset.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is an off day, otherwise, it is a work day.", categoryName: "Check Off Day")
    
    @Parameter(title: "Day Count", default: 2)
    var dayCount: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is it an Off Day in \(\.$dayCount) day(s)?")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let tomorrow = Calendar.current.date(byAdding: .day, value: dayCount, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isOffDay()
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

extension GregorianDay {
    fileprivate func isOffDay() -> Bool {
        var isOffDay = BaseCalendarManager.shared.isOff(day: self)
        if let publicDay = PublicPlanManager.shared.publicDay(at: julianDay) {
            isOffDay = publicDay.type == .offDay
        }
        if let customDay = CustomDayManager.shared.fetchCustomDay(by: julianDay) {
            isOffDay = customDay.dayType == .offDay
        }
        return isOffDay
    }
}
