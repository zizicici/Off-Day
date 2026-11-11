//
//  MarkDayIntent.swift
//  Off Day
//
//  Created by zici on 11/7/24.
//

import Foundation
import AppIntents
import ZCCalendar

public enum DayMark: String, AppEnum {
    case off
    case work
    case blank
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "intent.dayMark.type"
    
    public static var caseDisplayRepresentations: [DayMark : DisplayRepresentation] = [
        .off: "intent.dayMark.case.off",
        .work: "intent.dayMark.case.work",
        .blank: "intent.dayMark.case.blank"
    ]
}

struct UpdateDayMarkIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.dayMark.title"
    
    static var description: IntentDescription = IntentDescription("intent.dayMark.description", categoryName: "intent.dayMark.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("Which day?"))
    var date: Date
    
    @Parameter(title: "intent.dayMark.parameter.title", default: DayMark.off)
    var mark: DayMark
    
    static var parameterSummary: some ParameterSummary {
        Summary("Update Day Mark of \(\.$date) to \(\.$mark)?")
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let value = try await AppLogger.shared.run(
            intent: Self.titleLogKey,
            params: [
                "date": AnyEncodable(date),
                "mark": AnyEncodable(mark.rawValue)
            ]
        ) { () throws -> Bool in
            let result = try updateMark { WidgetCalendarPublisher.shared.publishNow() }

            await NotificationManager.shared.updateNotifications()

            return result
        }
        return .result(value: value)
    }

    @MainActor
    func updateMark(publishSnapshot: () -> Bool) throws -> Bool {
        let components = WidgetCalendarTimeline.calendar().dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day,
              let month = Month(rawValue: month) else { return false }
        let target = GregorianDay(year: year, month: month, day: day)
        switch mark {
        case .off: try AppDatabase.shared.setCustomDay(.offDay, at: target.julianDay)
        case .work: try AppDatabase.shared.setCustomDay(.workDay, at: target.julianDay)
        case .blank: try AppDatabase.shared.setCustomDay(nil, at: target.julianDay)
        }
        // Existing shortcuts report the committed DB result. A widget cache failure
        // must not abort their remaining actions; the publisher records the failure.
        _ = publishSnapshot()
        return true
    }

    static var openAppWhenRun: Bool = false
}
