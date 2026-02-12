//
//  PublicPlanInfoTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Testing
import ZCCalendar
@testable import Off_Day

struct PublicPlanInfoTests {
    @Test func initFromCustomDetailShouldDeduplicateSameDateDays() throws {
        let targetDay = GregorianDay(year: 2026, month: .jan, day: 1)
        let customPlan = CustomPublicPlan(name: "Plan A", start: targetDay, end: GregorianDay(year: 2026, month: .dec, day: 31))
        let detail = CustomPublicPlan.Detail(
            plan: customPlan,
            days: [
                CustomPublicDay(name: "First", date: targetDay, type: .offDay),
                CustomPublicDay(name: "Second", date: targetDay, type: .workDay),
            ]
        )
        
        let info = PublicPlanInfo(detail: detail)
        
        #expect(info.days.count == 1)
        #expect(info.name == "Plan A")
        #expect(info.start == targetDay)
        #expect(info.days[targetDay.julianDay]?.name == "First")
    }
    
    @Test func customSettersShouldUpdatePlanFields() {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let newStart = GregorianDay(year: 2026, month: .feb, day: 1)
        let newEnd = GregorianDay(year: 2026, month: .nov, day: 30)
        
        let detail = CustomPublicPlan.Detail(
            plan: CustomPublicPlan(name: "Original", start: start, end: end),
            days: [CustomPublicDay(name: "Holiday", date: start, type: .offDay)]
        )
        var info = PublicPlanInfo(detail: detail)
        
        info.name = "Updated"
        info.start = newStart
        info.end = newEnd
        
        #expect(info.name == "Updated")
        #expect(info.start == newStart)
        #expect(info.end == newEnd)
    }
    
    @Test func duplicateCustomPlanShouldBeIndependentAndUseCustomDayType() throws {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let detail = CustomPublicPlan.Detail(
            plan: CustomPublicPlan(name: "Original", start: day, end: day),
            days: [CustomPublicDay(name: "Holiday", date: day, type: .offDay)]
        )
        var original = PublicPlanInfo(detail: detail)
        
        let duplicated = original.getDuplicateCustomPlan()
        
        let isCustomPlan: Bool
        if case .custom = duplicated.plan {
            isCustomPlan = true
        } else {
            isCustomPlan = false
        }
        #expect(isCustomPlan)
        
        let duplicatedDay = try #require(duplicated.days[day.julianDay])
        #expect((duplicatedDay as? CustomPublicDay) != nil)
        #expect(duplicatedDay.name == "Holiday")
        
        original.days[day.julianDay] = CustomPublicDay(name: "Changed", date: day, type: .workDay)
        #expect(original.days[day.julianDay]?.name == "Changed")
        #expect(duplicated.days[day.julianDay]?.name == "Holiday")
    }
    
    @Test func appPlanInitShouldLoadAndSettersShouldNotMutate() throws {
        let appDetail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: .us)))
        var info = try #require(PublicPlanInfo(detail: appDetail))
        
        let originalName = info.name
        let originalStart = info.start
        let originalEnd = info.end
        
        info.name = "Ignored Name"
        info.start = GregorianDay(year: 2030, month: .jan, day: 1)
        info.end = GregorianDay(year: 2030, month: .dec, day: 31)
        
        #expect(info.name == originalName)
        #expect(info.start == originalStart)
        #expect(info.end == originalEnd)
    }
}
