//
//  CalendarManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import ZCCalendar
import Foundation

class ChineseCalendarManager {
    static let shared = ChineseCalendarManager()
    
    private var chineseDataSources: [ChineseCalendarDataSource] = []
    
    private var solarTermCache: [Int: [GregorianDay: SolarTerm]] = [:]
    private let queue = DispatchQueue(label: "com.zizicici.tag.solarTermCache", attributes: .concurrent)
    
    // Start from 1901
    private let solorTermsData: [Int] = [0x6aaaa6aa9a5a, 0xaaaaaabaaa6a, 0xaaabbabbafaa, 0x5aa665a65aab, 0x6aaaa6aa9a5a, 0xaaaaaaaaaa6a, 0xaaabbabbafaa, 0x5aa665a65aab, 0x6aaaa6aa9a5a, 0xaaaaaaaaaa6a, 0xaaabbabbafaa, 0x5aa665a65aab, 0x6aaaa6aa9a56, 0xaaaaaaaa9a5a, 0xaaabaabaaeaa, 0x569665a65aaa, 0x5aa6a6a69a56, 0x6aaaaaaa9a5a, 0xaaabaabaaeaa, 0x569665a65aaa, 0x5aa6a6a65a56, 0x6aaaaaaa9a5a, 0xaaabaabaaa6a, 0x569665a65aaa, 0x5aa6a6a65a56, 0x6aaaa6aa9a5a, 0xaaaaaabaaa6a, 0x555665665aaa, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0xaaaaaabaaa6a, 0x555665665aaa, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0xaaaaaaaaaa6a, 0x555665665aaa, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0xaaaaaaaaaa6a, 0x555665665aaa, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0xaaaaaaaaaa6a, 0x555665655aaa, 0x569665a65a56, 0x6aa6a6aa9a56, 0xaaaaaaaa9a5a, 0x5556556559aa, 0x569665a65a55, 0x6aa6a6a65a56, 0xaaaaaaaa9a5a, 0x5556556559aa, 0x569665a65a55, 0x5aa6a6a65a56, 0x6aaaa6aa9a5a, 0x5556556555aa, 0x569665a65a55, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0x55555565556a, 0x555665665a55, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0x55555565556a, 0x555665665a55, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0x55555555556a, 0x555665665a55, 0x5aa665a65a56, 0x6aaaa6aa9a5a, 0x55555555556a, 0x555665655a55, 0x5aa665a65a56, 0x6aa6a6aa9a5a, 0x55555555456a, 0x555655655a55, 0x5a9665a65a56, 0x6aa6a6a69a5a, 0x55555555456a, 0x555655655a55, 0x569665a65a56, 0x6aa6a6a65a56, 0x55555155455a, 0x555655655955, 0x569665a65a55, 0x5aa6a5a65a56, 0x15555155455a, 0x555555655555, 0x569665665a55, 0x5aa665a65a56, 0x15555155455a, 0x555555655515, 0x555665665a55, 0x5aa665a65a56, 0x15555155455a, 0x555555555515, 0x555665665a55, 0x5aa665a65a56, 0x15555155455a, 0x555555555515, 0x555665665a55, 0x5aa665a65a56, 0x15555155455a, 0x555555555515, 0x555655655a55, 0x5aa665a65a56, 0x15515155455a, 0x555555554515, 0x555655655a55, 0x5a9665a65a56, 0x15515151455a, 0x555551554515, 0x555655655a55, 0x569665a65a56, 0x155151510556, 0x555551554505, 0x555655655955, 0x569665665a55, 0x155110510556, 0x155551554505, 0x555555655555, 0x569665665a55, 0x55110510556, 0x155551554505, 0x555555555515, 0x555665665a55, 0x55110510556, 0x155551554505, 0x555555555515, 0x555665665a55, 0x55110510556, 0x155551554505, 0x555555555515, 0x555655655a55, 0x55110510556, 0x155551554505, 0x555555555515, 0x555655655a55, 0x55110510556, 0x155151514505, 0x555555554515, 0x555655655a55, 0x54110510556, 0x155151510505, 0x555551554515, 0x555655655a55, 0x14110110556, 0x155110510501, 0x555551554505, 0x555555655555, 0x14110110555, 0x155110510501, 0x555551554505, 0x555555555555, 0x14110110555, 0x55110510501, 0x155551554505, 0x555555555555, 0x110110555, 0x55110510501, 0x155551554505, 0x555555555515, 0x110110555, 0x55110510501, 0x155551554505, 0x555555555515, 0x100100555, 0x55110510501, 0x155151514505, 0x555555555515, 0x100100555, 0x54110510501, 0x155151514505, 0x555551554515, 0x100100555, 0x54110510501, 0x155150510505, 0x555551554515, 0x100100555, 0x14110110501, 0x155110510505, 0x555551554505, 0x100055, 0x14110110500, 0x155110510501, 0x555551554505, 0x55, 0x14110110500, 0x55110510501, 0x155551554505, 0x55, 0x110110500, 0x55110510501, 0x155551554505, 0x15, 0x100110500, 0x55110510501, 0x155551554505, 0x555555555515]
    
    private let solorTermsEncVerctor: [Int] = [4, 19, 3, 18, 4, 19, 4, 19, 4, 20, 4, 20, 6, 22, 6, 22, 6, 22, 7, 22, 6, 21, 6, 21]
    
    init() {
        load(dataSourceName: "HKO1901_2099", variant: .chinese)
        load(dataSourceName: "kyureki", variant: .kyureki)
    }
    
    func load(dataSourceName: String, variant: ChineseCalendarVariant) {
        if let url = Bundle.main.url(forResource: dataSourceName, withExtension: "json"), let data = try? Data(contentsOf: url) {
            do {
                var dataSource = try JSONDecoder().decode(ChineseCalendarDataSource.self, from: data)
                dataSource.variant = variant
                chineseDataSources.append(dataSource)
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }
    
    func findChineseDayInfo(_ day: GregorianDay, variant: ChineseCalendarVariant) -> ChineseDayInfo? {
        let target = chineseDataSources.first { $0.variant == variant }
        return target?.findChineseDayInfo(day)
    }

    private func unZipSolarTermsList(_ data: Int, rangeEndNum: Int = 24, charCountLen: Int = 2) -> [Int] {
        let unzip = (1...rangeEndNum).map { i in
            let right = charCountLen * (rangeEndNum - i)
            let x = data >> right
            return x % (1 << charCountLen)
        }.reversed()
        return zip(unzip, solorTermsEncVerctor).map(+)
    }
    
    private func calSolarTerms(for year: Int) -> [GregorianDay: SolarTerm] {
        let index = year - 1901
        guard index < solorTermsData.count else {
            return [:]
        }
        
        let data = solorTermsData[index]
        let dayInfos: [GregorianDay: SolarTerm] = unZipSolarTermsList(data).enumerated().reduce(into: [:]) { dict, tuple in
            let (index, day) = tuple
            let month = index / 2 + 1
            let solarTerm = SolarTerm(rawValue: (index + 22) % 24)!
            let gregorianDay = GregorianDay(year: year, month: Month(rawValue: month) ?? .jan, day: day)
            dict[gregorianDay] = solarTerm
        }
        
        return dayInfos
    }
    
    public func getSolarTerms(for year: Int) -> [GregorianDay: SolarTerm]? {
        var result: [GregorianDay: SolarTerm]?
        
        queue.sync {
            result = solarTermCache[year]
        }
        
        if result == nil {
            let dict = calSolarTerms(for: year)
            setSolarTerms(for: year, terms: dict)
            result = dict
        }
        
        return result
    }
    
    private func setSolarTerms(for year: Int, terms: [GregorianDay: SolarTerm]) {
        queue.async(flags: .barrier) {
            self.solarTermCache[year] = terms
        }
    }
    
    public func getSolarTerm(for day: GregorianDay) -> SolarTerm? {
        return getSolarTerms(for: day.year)?[day]
    }
}
