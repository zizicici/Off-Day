//
//  ChineseYear.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import Foundation
import ZCCalendar

enum ChineseYearType: Int, Codable {
    case ping = -1
    case runYi = 0
    case runEr
    case runSan
    case runSi
    case runWu
    case runLiu
    case runQi
    case runBa
    case runJiu
    case runShi
    case runDong
    case runLa

    func repeatableChineseMonth(at index: Int) -> RepeatableChineseMonth? {
        var result: RepeatableChineseMonth?
        switch self {
        case .ping:
            if let month = ChineseMonth(rawValue: index + 1) {
                result = RepeatableChineseMonth.normal(month)
            }
        default:
            if rawValue + 1 == index {
                if let month = ChineseMonth(rawValue: index) {
                    result = RepeatableChineseMonth.interCalary(month)
                }
            } else if rawValue + 1 > index {
                if let month = ChineseMonth(rawValue: index + 1) {
                    result = RepeatableChineseMonth.normal(month)
                }
            } else {
                if let month = ChineseMonth(rawValue: index) {
                    result = RepeatableChineseMonth.normal(month)
                }
            }
        }
        return result
    }

    func getIndex(for repeatableChineseMonth: RepeatableChineseMonth) -> Int? {
        switch self {
        case .ping:
            switch repeatableChineseMonth {
            case .normal(let chineseMonth):
                return chineseMonth.rawValue - 1
            case .interCalary:
                return nil
            }
        default:
            switch repeatableChineseMonth {
            case .normal(let chineseMonth):
                if chineseMonth.rawValue > rawValue + 1 {
                    // ChineseMonth.er is 2, YearType.runYi's rawValue is 0
                    return chineseMonth.rawValue
                } else {
                    return chineseMonth.rawValue - 1
                }
            case .interCalary(let chineseMonth):
                if chineseMonth.rawValue - rawValue == 1 {
                    // ChineseMonth.er is 2, YearType.runEr's rawValue is 1
                    // return 2 for interCalary
                    return chineseMonth.rawValue
                } else {
                    return nil
                }
            }
        }
    }

    func getNext(for targetMonth: RepeatableChineseMonth) -> RepeatableChineseMonth? {
        if let index = getIndex(for: targetMonth) {
            return repeatableChineseMonth(at: index + 1)
        } else {
            print("getNext index is is nil")
            return nil
        }
    }

    func biggerDayCount() -> Int {
        switch self {
        default:
            return 30
        }
    }
}

struct ChineseYear: Codable {
    let startDay: GregorianDay
    let yearType: ChineseYearType
    let fullMonths: [Bool]
    let sexagenaryCycleInfo: SexagenaryCycleInfo
    let startMonth: RepeatableChineseMonth

    let dayCount: Int
    let endDay: GregorianDay?

    enum CodingKeys: String, CodingKey {
        case startDay = "start"
        case yearType = "leapMonth"
        case fullMonths = "sizeInfo"
        case sexagenaryCycleInfo
        case endDay = "end"
        case startMonth = "startMonth"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        startDay = try values.decode(GregorianDay.self, forKey: .startDay)
        yearType = try values.decode(ChineseYearType.self, forKey: .yearType)
        let fullMonthsString = try values.decode(String.self, forKey: .fullMonths)
        var fullMonthArray: [Bool] = []
        for i in fullMonthsString {
            fullMonthArray.append(i == "0" ? false : true)
        }
        fullMonths = fullMonthArray
        sexagenaryCycleInfo = try values.decode(SexagenaryCycleInfo.self, forKey: .sexagenaryCycleInfo)
        let biggerDayCount = yearType.biggerDayCount()
        let alterDayCount = biggerDayCount - 1
        dayCount = fullMonths.reduce(0, { $0 + ($1 ? biggerDayCount : alterDayCount) })
        endDay = try? values.decode(GregorianDay.self, forKey: .endDay)
        if let startMonthValue = try? values.decode(Int.self, forKey: .startMonth) {
            if startMonthValue < 0 {
                startMonth = RepeatableChineseMonth.interCalary(ChineseMonth(rawValue: abs(startMonthValue)) ?? .yi)
            } else {
                startMonth = RepeatableChineseMonth.normal(ChineseMonth(rawValue: abs(startMonthValue)) ?? .yi)
            }
        } else {
            startMonth = RepeatableChineseMonth.normal(.yi)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startDay, forKey: .startDay)
        try container.encode(yearType, forKey: .yearType)
        try container.encode(sexagenaryCycleInfo, forKey: .sexagenaryCycleInfo)
        var fullMonthString = ""
        for value in fullMonths {
            fullMonthString.append(value ? "1" : "0")
        }
        try container.encode(fullMonthString, forKey: .fullMonths)
        try container.encode(startMonth.encodeInt, forKey: .startMonth)
    }

    func getMonthFirstDays() -> [(GregorianDay, RepeatableChineseMonth)] {
        var result = [(startDay, startMonth)]
        for info in fullMonths.dropLast() {
            if let nextMonth = yearType.getNext(for: result.last!.1) {
                result.append((result.last!.0 + (info ? 30 : 29), nextMonth))
            }
        }
        return result
    }
}

extension ChineseYear: GregorianDayContainerProtocol {
    func firstDay() -> Int {
        return startDay.julianDay
    }

    func lastDay() -> Int {
        return endDay?.julianDay ?? (startDay.julianDay + dayCount - 1)
    }
}

extension ChineseYear {
    func dayInfo(at gregorianDay: GregorianDay, variant: ChineseCalendarVariant) -> ChineseDayInfo? {
        var dayIndex = gregorianDay - startDay
        let biggerDayCount = yearType.biggerDayCount()
        let alterDayCount = biggerDayCount - 1
        if dayIndex >= 0 {
            var targetIndex: Int?
            for (index, value) in fullMonths.enumerated() {
                let dayCount: Int = (value ? biggerDayCount : alterDayCount)
                if dayIndex >= dayCount {
                    dayIndex -= dayCount
                } else {
                    targetIndex = index
                    break
                }
            }
            guard let index = targetIndex else {
                return nil
            }
            guard let chineseDay = ChineseDay(rawValue: dayIndex + 1) else {
                return nil
            }
            if let chineseMonth = yearType.repeatableChineseMonth(at: index) {
                return ChineseDayInfo(year: self, month: chineseMonth, day: chineseDay, variant: variant)
            }
        }

        return nil
    }
}
