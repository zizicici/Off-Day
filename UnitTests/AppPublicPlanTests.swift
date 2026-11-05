//
//  AppPublicPlanTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Testing
import ZCCalendar
@testable import Off_Day

@Suite(.serialized)
@MainActor
struct AppPublicPlanTests {
    @Test func allAppPublicPlanFilesShouldProvideReadableMetadata() {
        for file in AppPublicPlan.File.allCases {
            #expect(!file.resource.isEmpty)
            #expect(!file.title.isEmpty)
            #expect(!file.subtitle.isEmpty)
            let plan = AppPublicPlan(file: file)
            #expect(file.subtitle.contains(String(plan.start.year)))
            #expect(file.subtitle.contains(String(plan.end.year)))
        }
    }
    
    @Test func usPublicPlanDetailShouldLoadFromBundle() throws {
        let plan = AppPublicPlan(file: .us)
        let detail = try #require(AppPublicPlan.Detail(plan: plan))
        
        #expect(detail.plan?.file == .us)
        #expect(!detail.name.isEmpty)
        #expect(detail.days.count > 0)
        #expect(detail.start.julianDay <= detail.end.julianDay)
        
        #expect(plan.start.julianDay == detail.start.julianDay)
        #expect(plan.end.julianDay == detail.end.julianDay)
    }

    @Test(arguments: AppPublicPlan.File.allCases)
    func bundledPlansShouldCover2027WithUniqueDates(file: AppPublicPlan.File) throws {
        let detail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: file)))
        let expectedCounts = [
            "cn-mainland": 34, "cn-xinjiang": 34, "cn-xizang": 34,
            "cn-guangxi": 34, "cn-ningxia": 34, "cn-sichuan-liangshan": 34,
            "hk": 17, "mo-public": 20, "mo-force": 10, "mo-civil-servant": 26,
            "sg": 12, "th": 18, "kr": 24, "us": 12, "jp": 17,
        ]

        #expect(detail.end == GregorianDay(year: 2027, month: .dec, day: 31))
        #expect(detail.days.filter { $0.date.year == 2027 }.count == expectedCounts[file.resource])
        var dates = Set<Int>()
        for day in detail.days {
            #expect(day.date.julianDay >= detail.start.julianDay)
            #expect(day.date.julianDay <= detail.end.julianDay)
            #expect(dates.insert(day.date.julianDay).inserted)
        }
    }

    @Test func mainland2027ShouldMatchPublishedHolidayAndWorkdayRanges() throws {
        let detail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: .cn)))
        let days = detail.days.filter { $0.date.year == 2027 }
        let holidayRanges = [
            GregorianDay(year: 2027, month: .jan, day: 1).julianDay...GregorianDay(year: 2027, month: .jan, day: 3).julianDay,
            GregorianDay(year: 2027, month: .feb, day: 5).julianDay...GregorianDay(year: 2027, month: .feb, day: 13).julianDay,
            GregorianDay(year: 2027, month: .apr, day: 3).julianDay...GregorianDay(year: 2027, month: .apr, day: 5).julianDay,
            GregorianDay(year: 2027, month: .may, day: 1).julianDay...GregorianDay(year: 2027, month: .may, day: 5).julianDay,
            GregorianDay(year: 2027, month: .jun, day: 9).julianDay...GregorianDay(year: 2027, month: .jun, day: 9).julianDay,
            GregorianDay(year: 2027, month: .sep, day: 15).julianDay...GregorianDay(year: 2027, month: .sep, day: 15).julianDay,
            GregorianDay(year: 2027, month: .oct, day: 1).julianDay...GregorianDay(year: 2027, month: .oct, day: 7).julianDay,
        ]
        let workdays = [
            GregorianDay(year: 2027, month: .jan, day: 31),
            GregorianDay(year: 2027, month: .feb, day: 14),
            GregorianDay(year: 2027, month: .may, day: 8),
            GregorianDay(year: 2027, month: .sep, day: 26),
            GregorianDay(year: 2027, month: .oct, day: 9),
        ]

        #expect(Set(days.filter { $0.type == .offDay }.map { $0.date.julianDay }) == Set(holidayRanges.flatMap { $0 }))
        #expect(Set(days.filter { $0.type == .workDay }.map { $0.date.julianDay }) == Set(workdays.map { $0.julianDay }))
    }

    @Test func mainland2027ShouldMergeWithTheStandardWeek() throws {
        let detail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: .cn)))
        let plan = try #require(PublicPlanInfo(detail: detail))
        let first = GregorianDay(year: 2027, month: .jan, day: 1)
        var restDays = Set<GregorianDay>()

        for offset in 0..<365 {
            let day = first + offset
            let baseType: DayType = StandardConfig.default.weekdayOrders.contains(day.weekdayOrder()) ? .offDay : .workDay
            if DayManager.isOffDay(baseCalendarDayType: baseType, publicDayType: plan.days[day.julianDay]?.type, customDayType: nil) {
                restDays.insert(day)
            }
        }

        // A standard 2027 week has 104 weekend days; the holiday schedule adds 13 net days off.
        #expect(restDays.count == 117)
        #expect(restDays.contains(GregorianDay(year: 2027, month: .jan, day: 9))) // Ordinary Saturday.
        #expect(restDays.contains(GregorianDay(year: 2027, month: .jun, day: 9))) // Wednesday holiday.
        #expect(!restDays.contains(GregorianDay(year: 2027, month: .jun, day: 10)))
        #expect(restDays.contains(GregorianDay(year: 2027, month: .sep, day: 15))) // Wednesday holiday.
        #expect(!restDays.contains(GregorianDay(year: 2027, month: .sep, day: 16)))
        #expect(!restDays.contains(GregorianDay(year: 2027, month: .feb, day: 14))) // Make-up Sunday.
        #expect(!restDays.contains(GregorianDay(year: 2027, month: .oct, day: 9))) // Make-up Saturday.
    }

    @Test(arguments: [AppPublicPlan.File.cn_xj, .cn_xz, .cn_gx, .cn_nx, .cn_sc_ls])
    func local2027PlansShouldTemporarilyUseMainlandSchedule(file: AppPublicPlan.File) throws {
        let mainland = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: .cn)))
        let local = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: file)))
        func daysIn2027(_ detail: AppPublicPlan.Detail) -> Set<JSONPublicDay> {
            Set(detail.days.filter { $0.date.year == 2027 }.map {
                JSONPublicDay(name: $0.name, date: $0.date, type: $0.type)
            })
        }

        #expect(daysIn2027(local) == daysIn2027(mainland))
        #expect(local.note?.contains("2027年暂采用中国大陆") == true)
    }

    @Test func observed2027HolidaysShouldRespectEachRegionsRules() throws {
        func type(in file: AppPublicPlan.File, month: Month, day: Int) throws -> DayType? {
            let detail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: file)))
            let date = GregorianDay(year: 2027, month: month, day: day)
            return detail.days.first { $0.date == date }?.type
        }

        #expect(try type(in: .hk, month: .feb, day: 7) == nil)
        #expect(try type(in: .hk, month: .feb, day: 9) == .offDay)
        #expect(try type(in: .mo_public, month: .feb, day: 7) == .offDay)
        #expect(try type(in: .mo_public, month: .feb, day: 9) == nil)
        #expect(try type(in: .mo_cs, month: .feb, day: 9) == .offDay)
        #expect(try type(in: .mo_cs, month: .feb, day: 10) == .offDay)
        #expect(try type(in: .mo_cs, month: .feb, day: 5) == nil)
        #expect(try type(in: .mo_cs, month: .dec, day: 31) == nil)
        #expect(try type(in: .sg, month: .feb, day: 8) == .offDay)
        #expect(try type(in: .sg, month: .dec, day: 27) == nil)
        #expect(try type(in: .jp, month: .mar, day: 22) == .offDay)
        #expect(try type(in: .kr, month: .feb, day: 9) == .offDay)
        #expect(try type(in: .kr, month: .may, day: 3) == .offDay)
        #expect(try type(in: .kr, month: .jul, day: 19) == .offDay)
        #expect(try type(in: .th, month: .feb, day: 22) == .offDay)
        #expect(try type(in: .us, month: .jun, day: 18) == .offDay)
        #expect(try type(in: .us, month: .jul, day: 5) == .offDay)
        #expect(try type(in: .us, month: .dec, day: 24) == .offDay)
        #expect(try type(in: .us, month: .dec, day: 31) == .offDay)
    }
}
