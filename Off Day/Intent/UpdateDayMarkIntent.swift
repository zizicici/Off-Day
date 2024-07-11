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
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var result = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            result = true
            switch mark {
            case .off:
                CustomDayManager.shared.update(dayType: .offDay, to: target.julianDay)
            case .work:
                CustomDayManager.shared.update(dayType: .workDay, to: target.julianDay)
            case .blank:
                CustomDayManager.shared.update(dayType: nil, to: target.julianDay)
            }
        }
        return .result(value: result)
    }

    static var openAppWhenRun: Bool = false
}
