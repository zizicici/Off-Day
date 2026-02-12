//
//  DatabaseModelTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

struct DatabaseModelTests {
    @Test func customDayHelpersShouldCreateAndSortAsExpected() {
        let firstDay = GregorianDay(year: 2026, month: .jan, day: 1)
        let secondDay = GregorianDay(year: 2026, month: .jan, day: 2)
        
        let empty = CustomDay.emptyDay(day: firstDay)
        #expect(empty.dayIndex == Int64(firstDay.julianDay))
        #expect(empty.dayType == .offDay)
        
        let later = CustomDay(dayIndex: Int64(secondDay.julianDay), dayType: .workDay)
        let earlier = CustomDay(dayIndex: Int64(firstDay.julianDay), dayType: .offDay)
        let sorted = [later, earlier].sortedByStart()
        
        #expect(sorted.map(\.dayIndex) == [Int64(firstDay.julianDay), Int64(secondDay.julianDay)])
    }
    
    @Test func customCommentSortedByStartShouldOrderByDayIndex() {
        let first = CustomComment(dayIndex: 10, content: "A")
        let second = CustomComment(dayIndex: 5, content: "B")
        let third = CustomComment(dayIndex: 8, content: "C")
        
        let sorted = [first, second, third].sortedByStart()
        
        #expect(sorted.map(\.dayIndex) == [5, 8, 10])
    }
    
    @Test func customPublicDayAllowSaveShouldRejectEmptyName() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        
        let invalid = CustomPublicDay(name: "", date: day, type: .offDay)
        let valid = CustomPublicDay(name: "Holiday", date: day, type: .offDay)
        
        #expect(!invalid.allowSave())
        #expect(valid.allowSave())
    }
    
    @Test func customPublicDayCodableShouldKeepPlanId() throws {
        var original = CustomPublicDay(name: "Holiday", date: GregorianDay(year: 2026, month: .jan, day: 1), type: .offDay)
        original.planId = 42
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CustomPublicDay.self, from: encoded)
        
        #expect(decoded.name == "Holiday")
        #expect(decoded.planId == 42)
        #expect(decoded.type == .offDay)
    }
}
