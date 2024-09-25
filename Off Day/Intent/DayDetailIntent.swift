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
        return DisplayRepresentation(title: "\(day.formatString() ?? "")")
    }
    
    var id: Int
    
    @Property(title: "intent.dayDetail.dateValue")
    var date: Date
    
    @Property(title: "intent.dayDetail.userOffValue")
    var userOffDay: Bool?
    
    @Property(title: "intent.dayDetail.publicOffValue")
    var publicOffDay: Bool?
    
    @Property(title: "intent.dayDetail.baseOffValue")
    var baseOffDay: Bool
    
    @Property(title: "intent.dayDetail.publicDay")
    var publicDayName: String?
    
    
    init(id: Int, date: Date, userOffDay: Bool? = nil, publicOffDay: Bool? = nil, baseOffDay: Bool, publicDayName: String?) {
        self.id = id
        self.date = date
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
            
            if let detail = target.getDayDetail() {
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

extension GregorianDay {
    func getDayDetail() -> DayDetailEntity? {
        let baseOffValue = BaseCalendarManager.shared.isOff(day: self)
        let publicDay = PublicPlanManager.shared.publicDay(at: self.julianDay)
        let publicOffValue: Bool = publicDay?.type == .offDay
        let customOffValue: Bool? = CustomDayManager.shared.fetchCustomDay(by: julianDay)?.dayType == .offDay
        if let date = generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) {
            let detail = DayDetailEntity(id: julianDay, date: date, userOffDay: customOffValue, publicOffDay: publicOffValue, baseOffDay: baseOffValue, publicDayName: publicDay?.name)
            return detail
        } else {
            return nil
        }
    }
}
