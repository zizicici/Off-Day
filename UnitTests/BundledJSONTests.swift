import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

@Suite(.serialized)
@MainActor
struct BundledJSONTests {
    @Test(arguments: AppPublicPlan.File.allCases.map { $0.resource } + ["HKO1901_2099", "kyureki"])
    func bundledDatesShouldBeRealCanonicalGregorianDates(resource: String) throws {
        let url = try #require(Bundle.main.url(forResource: resource, withExtension: "json"))
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false

        func checkDates(in value: Any) throws {
            if let dictionary = value as? [String: Any] {
                for (key, child) in dictionary {
                    if ["date", "start", "end"].contains(key) {
                        let string = try #require(child as? String)
                        let date = try #require(formatter.date(from: string), "Invalid date: \(resource): \(string)")
                        #expect(formatter.string(from: date) == string)
                    } else {
                        try checkDates(in: child)
                    }
                }
            } else if let array = value as? [Any] {
                for child in array {
                    try checkDates(in: child)
                }
            }
        }

        try checkDates(in: object)
    }

    @Test(arguments: AppPublicPlan.File.allCases)
    func holidayRecordsShouldBeNamedAndChronological(file: AppPublicPlan.File) throws {
        let detail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: file)))
        #expect(!detail.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(detail.days.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        let dates = detail.days.map { $0.date.julianDay }
        #expect(dates == dates.sorted())
    }

    @Test(arguments: ["HKO1901_2099", "kyureki"])
    func lunarYearsShouldContinuouslyCoverTheDeclaredRange(resource: String) throws {
        let url = try #require(Bundle.main.url(forResource: resource, withExtension: "json"))
        let source = try JSONDecoder().decode(ChineseCalendarDataSource.self, from: Data(contentsOf: url))
        let first = try #require(source.years.first)
        let last = try #require(source.years.last)
        #expect(first.startDay == source.start)
        #expect(last.lastDay() == source.end.julianDay)

        for year in source.years {
            #expect(year.fullMonths.count == (year.yearType == .ping ? 12 : 13))
        }
        for (previous, next) in zip(source.years, source.years.dropFirst()) {
            #expect(previous.lastDay() + 1 == next.firstDay())
        }
    }

    @Test func historicalCorrectionsShouldMatchOfficialNotices() throws {
        let cases: [(AppPublicPlan.File, String, DayType?)] = [
            (.sg, "2024-06-01", nil),
            (.sg, "2025-05-03", .offDay),
            (.sg, "2026-06-01", .offDay),
            (.kr, "2024-10-01", .offDay),
            (.kr, "2025-01-27", .offDay),
            (.kr, "2025-06-03", .offDay),
            (.kr, "2026-05-01", .offDay),
            (.th, "2024-01-02", nil),
            (.th, "2024-04-12", .offDay),
            (.th, "2024-04-13", nil),
            (.th, "2024-04-14", nil),
            (.th, "2026-10-16", nil), // Bangkok-only closure.
            (.cn_xj, "2025-03-29", .offDay),
            (.cn_xj, "2025-03-30", .offDay),
            (.cn_xz, "2025-08-25", .offDay),
            (.cn_xz, "2026-02-24", .offDay),
            (.cn_xz, "2026-02-25", .offDay),
            (.cn_xz, "2026-02-26", .offDay),
            (.cn_xz, "2026-08-12", nil), // Festival date differs from the notified day off.
            (.cn_xz, "2026-08-14", .offDay),
            (.us, "2024-12-24", .offDay),
            (.us, "2025-01-09", .offDay),
            (.us, "2025-12-24", .offDay),
            (.us, "2025-12-26", .offDay),
        ]

        for (file, dateString, expected) in cases {
            let detail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: file)))
            let date = try JSONDecoder().decode(GregorianDay.self, from: JSONEncoder().encode(dateString))
            #expect(detail.days.first { $0.date == date }?.type == expected, "\(file.resource): \(dateString)")
        }
    }
}
