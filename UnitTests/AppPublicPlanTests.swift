//
//  AppPublicPlanTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Testing
import ZCCalendar
@testable import Off_Day

struct AppPublicPlanTests {
    @Test func allAppPublicPlanFilesShouldProvideReadableMetadata() {
        for file in AppPublicPlan.File.allCases {
            #expect(!file.resource.isEmpty)
            #expect(!file.title.isEmpty)
            #expect(!file.subtitle.isEmpty)
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
}
