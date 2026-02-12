//
//  ChineseYearAndRangeTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

struct ChineseYearAndRangeTests {
    @Test func chineseYearTypeLeapMonthMappingsShouldMatchImplementation() {
        let type = ChineseYearType.runEr
        
        #expect(type.repeatableChineseMonth(at: 0)?.encodeInt == 1)
        #expect(type.repeatableChineseMonth(at: 1)?.encodeInt == 2)
        #expect(type.repeatableChineseMonth(at: 2)?.encodeInt == -2)
        
        #expect(type.getIndex(for: .normal(.san)) == 3)
        #expect(type.getIndex(for: .interCalary(.er)) == 2)
        #expect(type.getNext(for: .normal(.er))?.encodeInt == -2)
    }
    
    @Test func chineseYearDecodeShouldBuildDayCountAndMonthTimeline() throws {
        let json = """
        {
          "start": "2026-01-01",
          "leapMonth": -1,
          "sizeInfo": "10",
          "sexagenaryCycleInfo": 0
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        let year = try JSONDecoder().decode(ChineseYear.self, from: data)
        
        #expect(year.startMonth.encodeInt == 1)
        #expect(year.fullMonths == [true, false])
        #expect(year.dayCount == 59)
        #expect(year.endDay == nil)
        
        let monthFirstDays = year.getMonthFirstDays()
        #expect(monthFirstDays.count == 2)
        #expect(monthFirstDays[0].1.encodeInt == 1)
        #expect(monthFirstDays[1].1.encodeInt == 2)
        #expect(monthFirstDays[1].0 == year.startDay + 30)
    }
    
    @Test func chineseYearEncodeShouldKeepSizeInfoAndStartMonth() throws {
        let json = """
        {
          "start": "2026-01-01",
          "leapMonth": -1,
          "sizeInfo": "1",
          "sexagenaryCycleInfo": 0,
          "startMonth": -2
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        let year = try JSONDecoder().decode(ChineseYear.self, from: data)
        
        #expect(year.startMonth.encodeInt == -2)
        
        let encoded = try JSONEncoder().encode(year)
        let object = try JSONSerialization.jsonObject(with: encoded)
        let root = try #require(object as? [String: Any])
        
        #expect(root["sizeInfo"] as? String == "1")
        #expect(root["startMonth"] as? Int == -2)
    }
    
    @Test func chineseYearDayInfoShouldWorkOnBoundaryDays() throws {
        let json = """
        {
          "start": "2026-01-01",
          "leapMonth": -1,
          "sizeInfo": "10",
          "sexagenaryCycleInfo": 0
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        let year = try JSONDecoder().decode(ChineseYear.self, from: data)
        
        let startDay = GregorianDay(year: 2026, month: .jan, day: 1)
        let startInfo = try #require(year.dayInfo(at: startDay, variant: .chinese))
        #expect(startInfo.day == .chuYi)
        #expect(startInfo.month.encodeInt == 1)
        
        let secondMonthFirstDay = startDay + 30
        let secondInfo = try #require(year.dayInfo(at: secondMonthFirstDay, variant: .chinese))
        #expect(secondInfo.day == .chuYi)
        #expect(secondInfo.month.encodeInt == 2)
        
        #expect(year.dayInfo(at: GregorianDay(year: 2025, month: .dec, day: 31), variant: .chinese) == nil)
        #expect(year.dayInfo(at: GregorianDay(year: 2026, month: .mar, day: 2), variant: .chinese) == nil)
    }
    
    @Test func chineseCalendarDataSourceShouldFindDayInfoAndRespectVariant() throws {
        let json = """
        {
          "name": "Test Source",
          "reference": "unit-test",
          "start": "2026-01-01",
          "end": "2026-01-30",
          "years": [
            {
              "start": "2026-01-01",
              "leapMonth": -1,
              "sizeInfo": "1",
              "sexagenaryCycleInfo": 0
            }
          ]
        }
        """
        
        let data = try #require(json.data(using: .utf8))
        var source = try JSONDecoder().decode(ChineseCalendarDataSource.self, from: data)
        
        #expect(source.firstDay() == GregorianDay(year: 2026, month: .jan, day: 1).julianDay)
        #expect(source.lastDay() == GregorianDay(year: 2026, month: .jan, day: 30).julianDay)
        
        source.variant = .kyureki
        let info = try #require(source.findChineseDayInfo(GregorianDay(year: 2026, month: .jan, day: 1)))
        #expect(info.shortDisplayString().contains("旧"))
    }
    
    @Test func yearRangeShouldRespectConfiguredBoundaries() {
        #expect(YearRange.isAvailable(year: 1900))
        #expect(YearRange.isAvailable(year: 2099))
        #expect(!YearRange.isAvailable(year: 1899))
        #expect(!YearRange.isAvailable(year: 2100))
        #expect(YearRange.isAvailable(day: GregorianDay(year: 1900, month: .jan, day: 1)))
    }
}
