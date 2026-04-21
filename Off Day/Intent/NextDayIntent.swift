//
//  NextDayIntent.swift
//  Off Day
//
//  Created by zici on 25/9/24.
//

import AppIntents
import ZCCalendar

struct NextOffDayDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.nextOffDayDetail.intent.title"
    
    static var description: IntentDescription = IntentDescription("intent.nextOffDayDetail.intent.description", categoryName: "intent.dayDetail.intent.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("From which day onward?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Next Off Day Detail after \(\.$date)")
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DayDetailEntity> {
        let detail = try await AppLogger.shared.run(
            intent: Self.titleLogKey,
            params: ["date": AnyEncodable(date)],
            operation: { () throws -> DayDetailEntity in
                let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
                    let day = GregorianDay(year: year, month: month, day: day)

                    if let resultDay = DayManager.fetchNextDay(type: .offDay, after: day), let detail = DayManager.getDayDetail(from: resultDay) {
                        return detail
                    } else {
                        throw FetchError.notFound
                    }
                } else {
                    throw FetchError.notFound
                }
            },
            toOutput: { DayDetailLog($0) }
        )
        return .result(value: detail)
    }

    static var openAppWhenRun: Bool = false
}

struct NextWorkDayDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.nextWorkDayDetail.intent.title"
    
    static var description: IntentDescription = IntentDescription("intent.nextWorkDayDetail.intent.description", categoryName: "intent.dayDetail.intent.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("From which day onward?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Next Work Day Detail after \(\.$date)")
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DayDetailEntity> {
        let detail = try await AppLogger.shared.run(
            intent: Self.titleLogKey,
            params: ["date": AnyEncodable(date)],
            operation: { () throws -> DayDetailEntity in
                let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
                    let day = GregorianDay(year: year, month: month, day: day)

                    if let resultDay = DayManager.fetchNextDay(type: .workDay, after: day), let detail = DayManager.getDayDetail(from: resultDay) {
                        return detail
                    } else {
                        throw FetchError.notFound
                    }
                } else {
                    throw FetchError.notFound
                }
            },
            toOutput: { DayDetailLog($0) }
        )
        return .result(value: detail)
    }

    static var openAppWhenRun: Bool = false
}
