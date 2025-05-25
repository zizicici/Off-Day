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

}
