//
//  DayDetailIntent.swift
//  Off Day
//
//  Created by zici on 12/5/24.
//

import AppIntents
import ZCCalendar

struct DayDetailEntity: Identifiable, Hashable, Equatable, AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.dayDetail.type")
    typealias DefaultQuery = DayIntentQuery
    static var defaultQuery = DayIntentQuery()
    var displayRepresentation: DisplayRepresentation {
        let day = GregorianDay(JDN: id)
        let subtitle = String.assembleDetail(
            for: finalOffDay ? .offDay : .workDay,
            publicDayName: publicDayName,
            baseCalendarDayType: baseOffDay ? .offDay : .workDay,
            publicDayType: publicOffDay == nil ? .none : publicOffDay! == true ? .offDay : .workDay,
            customDayType: userOffDay == nil ? .none : userOffDay! == true ? .offDay : .workDay
        )
        return DisplayRepresentation(title: "\(day.formatString() ?? "")", subtitle: "\(subtitle)")
    }
    
    var id: Int
    
    @Property(title: "intent.dayDetail.dateValue")
    var date: Date
    
    @Property(title: "intent.dayDetail.offValue")
    var finalOffDay: Bool
    
    @Property(title: "intent.dayDetail.userOffValue")
    var userOffDay: Bool?
    
    @Property(title: "intent.dayDetail.publicOffValue")
    var publicOffDay: Bool?
    
    @Property(title: "intent.dayDetail.baseOffValue")
    var baseOffDay: Bool
    
    @Property(title: "intent.dayDetail.publicDay")
    var publicDayName: String?
    
    
    init(id: Int, date: Date, finalOffDay: Bool, userOffDay: Bool? = nil, publicOffDay: Bool? = nil, baseOffDay: Bool, publicDayName: String?) {
        self.id = id
        self.date = date
        self.finalOffDay = finalOffDay
        self.userOffDay = userOffDay
        self.publicOffDay = publicOffDay
        self.baseOffDay = baseOffDay
        self.publicDayName = publicDayName
    }
    
    static func == (lhs: DayDetailEntity, rhs: DayDetailEntity) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DayIntentQuery: EntityQuery {
    func entities(for identifiers: [DayDetailEntity.ID]) async throws -> [DayDetailEntity] {
        return []
    }
    
    func suggestedEntities() async throws -> [DayDetailEntity] {
        return []
    }
}

struct DayDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.dayDetail.intent.title"
    
    static var description: IntentDescription = IntentDescription("intent.dayDetail.intent.description", categoryName: "intent.dayDetail.intent.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("Which day?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get Day Detail of \(\.$date)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DayDetailEntity> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            
            if let detail = DayManager.getDayDetail(from: target) {
                return .result(value: detail)
            } else {
                throw FetchError.notFound
            }
        } else {
            throw FetchError.notFound
        }
    }

    static var openAppWhenRun: Bool = false
}
