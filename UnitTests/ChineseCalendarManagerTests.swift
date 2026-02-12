//
//  ChineseCalendarManagerTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Testing
import ZCCalendar
@testable import Off_Day

struct ChineseCalendarManagerTests {
    @Test func solarTermsShouldReturnAll24TermsForSupportedYear() throws {
        let manager = ChineseCalendarManager.shared
        let terms = try #require(manager.getSolarTerms(for: 2026))
        
        #expect(terms.count == SolarTerm.allCases.count)
        #expect(Set(terms.values).count == SolarTerm.allCases.count)
        #expect(terms.keys.allSatisfy { $0.year == 2026 })
    }
    
    @Test func solarTermLookupShouldMatchYearDictionaryAndCacheResult() throws {
        let manager = ChineseCalendarManager.shared
        let first = try #require(manager.getSolarTerms(for: 2026))
        let second = try #require(manager.getSolarTerms(for: 2026))
        
        #expect(first == second)
        
        let sample = try #require(first.first)
        #expect(manager.getSolarTerm(for: sample.key) == sample.value)
    }
    
    @Test func solarTermsShouldBeEmptyForOutOfRangeYear() throws {
        let manager = ChineseCalendarManager.shared
        let terms = try #require(manager.getSolarTerms(for: 2200))
        
        #expect(terms.isEmpty)
        #expect(manager.getSolarTerm(for: GregorianDay(year: 2200, month: .jan, day: 1)) == nil)
    }
}
