//
//  DayInfo.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import Foundation
import ZCCalendar

protocol DayInfoProvider {
    var days: [Day] { get }
}

enum DayType: Int, Codable {
    case offday = 0
    case workday
}

protocol Day {
    var name: String { get }
    var julianDay: Int { get }
    var dayType: DayType { get }
}

struct PublicDay: Day {
    let name: String
    let day: GregorianDay
    var julianDay: Int {
        return day.julianDay
    }
    let dayType: DayType
}

struct CustomDay: Day {
    let name: String
    let julianDay: Int
    let dayType: DayType
}

struct Mainland2024: DayInfoProvider {
    var days: [any Day] {
        get {
            let year = 2024
            let day1_1 = PublicDay(name: "元旦", day: GregorianDay(year: year, month: .jan, day: 1), dayType: .offday)
            let day2_4 = PublicDay(name: "春节调班", day: GregorianDay(year: year, month: .feb, day: 4), dayType: .workday)
            let day2_10 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 10), dayType: .offday)
            let day2_11 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 11), dayType: .offday)
            let day2_12 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 12), dayType: .offday)
            let day2_13 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 13), dayType: .offday)
            let day2_14 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 14), dayType: .offday)
            let day2_15 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 15), dayType: .offday)
            let day2_16 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 16), dayType: .offday)
            let day2_17 = PublicDay(name: "春节", day: GregorianDay(year: year, month: .feb, day: 17), dayType: .offday)
            let day2_18 = PublicDay(name: "春节调班", day: GregorianDay(year: year, month: .feb, day: 18), dayType: .workday)
            let day4_4 = PublicDay(name: "清明节", day: GregorianDay(year: year, month: .apr, day: 4), dayType: .offday)
            let day4_7 = PublicDay(name: "清明节调班", day: GregorianDay(year: year, month: .apr, day: 7), dayType: .workday)
            let day4_28 = PublicDay(name: "劳动节调班", day: GregorianDay(year: year, month: .apr, day: 28), dayType: .workday)
            let day5_1 = PublicDay(name: "劳动节", day: GregorianDay(year: year, month: .may, day: 1), dayType: .offday)
            let day5_2 = PublicDay(name: "劳动节", day: GregorianDay(year: year, month: .may, day: 2), dayType: .offday)
            let day5_3 = PublicDay(name: "劳动节", day: GregorianDay(year: year, month: .may, day: 3), dayType: .offday)
            let day5_4 = PublicDay(name: "劳动节", day: GregorianDay(year: year, month: .may, day: 4), dayType: .offday)
            let day5_5 = PublicDay(name: "劳动节", day: GregorianDay(year: year, month: .may, day: 5), dayType: .offday)
            let day5_11 = PublicDay(name: "劳动节调班", day: GregorianDay(year: year, month: .may, day: 11), dayType: .workday)
            let day6_10 = PublicDay(name: "端午节", day: GregorianDay(year: year, month: .jun, day: 10), dayType: .offday)
            let day9_14 = PublicDay(name: "中秋节调班", day: GregorianDay(year: year, month: .sep, day: 14), dayType: .workday)
            let day9_15 = PublicDay(name: "中秋节", day: GregorianDay(year: year, month: .sep, day: 15), dayType: .offday)
            let day9_16 = PublicDay(name: "中秋节", day: GregorianDay(year: year, month: .sep, day: 16), dayType: .offday)
            let day9_17 = PublicDay(name: "中秋节", day: GregorianDay(year: year, month: .sep, day: 17), dayType: .offday)
            let day9_29 = PublicDay(name: "国庆节调班", day: GregorianDay(year: year, month: .sep, day: 29), dayType: .workday)
            let day10_1 = PublicDay(name: "国庆节", day: GregorianDay(year: year, month: .oct, day: 1), dayType: .offday)
            let day10_2 = PublicDay(name: "国庆节", day: GregorianDay(year: year, month: .oct, day: 2), dayType: .offday)
            let day10_3 = PublicDay(name: "国庆节", day: GregorianDay(year: year, month: .oct, day: 3), dayType: .offday)
            let day10_4 = PublicDay(name: "国庆节", day: GregorianDay(year: year, month: .oct, day: 4), dayType: .offday)
            let day10_5 = PublicDay(name: "国庆节", day: GregorianDay(year: year, month: .oct, day: 5), dayType: .offday)
            let day10_6 = PublicDay(name: "国庆节", day: GregorianDay(year: year, month: .oct, day: 6), dayType: .offday)
            let day10_7 = PublicDay(name: "国庆节", day: GregorianDay(year: year, month: .oct, day: 7), dayType: .offday)
            let day10_12 = PublicDay(name: "国庆节调班", day: GregorianDay(year: year, month: .oct, day: 12), dayType: .workday)
            return [day1_1, day2_4, day2_10, day2_11, day2_12, day2_13, day2_14, day2_15, day2_16, day2_17, day2_18, day4_4, day4_7, day4_28, day5_1, day5_2, day5_3, day5_4, day5_5, day5_11, day6_10, day9_14, day9_15, day9_16, day9_17, day9_29, day10_1, day10_2, day10_3, day10_4, day10_5, day10_6, day10_7, day10_12]
        }
    }
}
