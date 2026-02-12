//
//  PublicPlanJSONTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

struct PublicPlanJSONTests {
    @Test func jsonContentShouldBeValidAndRoundTrip() throws {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let plan = JSONPublicPlan(
            name: "Test Plan",
            days: [
                JSONPublicDay(name: "New Year", date: start, type: .offDay),
                JSONPublicDay(name: "Work Shift", date: GregorianDay(year: 2026, month: .jan, day: 2), type: .workDay),
            ],
            start: start,
            end: end
        )
        
        let jsonString = try #require(try plan.jsonContent())
        let jsonData = try #require(jsonString.data(using: .utf8))
        
        _ = try JSONSerialization.jsonObject(with: jsonData)
        let decoded = try JSONDecoder().decode(JSONPublicPlan.self, from: jsonData)
        
        #expect(decoded.name == "Test Plan")
        #expect(decoded.days.count == 2)
        #expect(decoded.start == start)
        #expect(decoded.end == end)
        #expect(decoded.days.first?.type == .offDay)
        #expect(decoded.days.last?.type == .workDay)
    }
    
    @Test func jsonContentShouldContainRequiredTopLevelKeys() throws {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let plan = JSONPublicPlan(
            name: "Key Check",
            days: [JSONPublicDay(name: "Holiday", date: day, type: .offDay)],
            start: day,
            end: day
        )
        
        let jsonString = try #require(try plan.jsonContent())
        let jsonData = try #require(jsonString.data(using: .utf8))
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let root = try #require(jsonObject as? [String: Any])
        
        #expect(root["name"] as? String == "Key Check")
        #expect(root["days"] != nil)
        #expect(root["start"] != nil)
        #expect(root["end"] != nil)
    }
    
    @Test func initFromURLShouldDecodeValidFile() throws {
        let validJSON = """
        {
          "name": "Imported Plan",
          "start": "2026-01-01",
          "end": "2026-12-31",
          "days": [
            {
              "date": "2026-01-01",
              "name": "Holiday",
              "type": 0
            }
          ]
        }
        """
        
        let fileURL = try TestFileHelper.writeTempFile(validJSON)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        let plan = try JSONPublicPlan(from: fileURL)
        #expect(plan.name == "Imported Plan")
        #expect(plan.days.count == 1)
        #expect(plan.days.first?.type == .offDay)
    }
    
    @Test func initFromURLShouldFailForInvalidFile() throws {
        let invalidJSON = """
        {
          "name": "Broken Plan",
          "start": "2026-01-01",
          "days": [ { "name": "Missing Required Fields" } ]
        }
        """
        
        let fileURL = try TestFileHelper.writeTempFile(invalidJSON)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        var didThrow = false
        do {
            _ = try JSONPublicPlan(from: fileURL)
        } catch {
            didThrow = true
        }
        
        #expect(didThrow)
    }
}
