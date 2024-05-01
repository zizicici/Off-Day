//
//  EventDate.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import Foundation
import ZCCalendar

enum EventDate: Hashable {
    case year(Int)
    case month(GregorianMonth)
    case day(GregorianDay)
    
    func isValid(with trailing: EventDate) -> Bool {
        let compareDateType: DateType = max(dateType, trailing.dateType)
        let leading = leadingIndex(for: compareDateType)
        let trailing = trailing.trailingIndex(for: compareDateType)
        
        return leading <= trailing
    }
    
    var title: String {
        switch self {
        case .year(let year):
            return "\(year)"
        case .month(let yearMonth):
            return yearMonth.title
        case .day(let gregorianDay):
            return gregorianDay.formatString() ?? ""
        }
    }
    
    var shortTitle: String {
        switch self {
        case .year(let year):
            return "\(year)"
        case .month(let yearMonth):
            return yearMonth.shortTitle
        case .day(let gregorianDay):
            return gregorianDay.shortTitle()
        }
    }
    
    var formatNumericString: String {
        switch self {
        case .year(let year):
            return "\(year)"
        case .month(let gregorianMonth):
            return "\(gregorianMonth.year)/\(gregorianMonth.month.rawValue)"
        case .day(let gregorianDay):
            return "\(gregorianDay.year)/\(gregorianDay.month.rawValue)/\(gregorianDay.day)"
        }
    }
    
    var dateType: DateType {
        switch self {
        case .year(_):
            return .year
        case .month(_):
            return .month
        case .day(_):
            return .day
        }
    }
    
    private var index: Int {
        switch self {
        case .year(let year):
            return year
        case .month(let gregorianMonth):
            return gregorianMonth.index
        case .day(let gregorianDay):
            return gregorianDay.julianDay
        }
    }
    
    func leadingIndex() -> Int {
        return leadingIndex(for: dateType)
    }
    
    func trailingIndex() -> Int {
        return trailingIndex(for: dateType)
    }
    
    func leading(for dateType: DateType) -> EventDate {
        switch self {
        case .year(let year):
            switch dateType {
            case .year:
                return self
            case .month:
                return .month(GregorianMonth(year: Int(year), month: .jan))
            case .day:
                return .day(GregorianDay(year: Int(year), month: .jan, day: 1))
            }
        case .month(let yearMonth):
            switch dateType {
            case .year:
                return .year(yearMonth.year)
            case .month:
                return self
            case .day:
                return .day(GregorianDay(year: yearMonth.year, month: yearMonth.month, day: 1))
            }
        case .day(let gregorianDay):
            switch dateType {
            case .year:
                return .year(gregorianDay.year)
            case .month:
                return .month(GregorianMonth(year: gregorianDay.year, month: gregorianDay.month))
            case .day:
                return self
            }
        }
    }
    
    func trailing(for dateType: DateType) -> EventDate {
        switch self {
        case .year(let year):
            switch dateType {
            case .year:
                return self
            case .month:
                return .month(GregorianMonth(year: Int(year), month: .dec))
            case .day:
                return .day(GregorianDay(year: Int(year), month: .dec, day: 31))
            }
        case .month(let yearMonth):
            switch dateType {
            case .year:
                return .year(yearMonth.year)
            case .month:
                return self
            case .day:
                return .day(ZCCalendar.manager.lastDay(at: yearMonth.month, year: yearMonth.year))
            }
        case .day(let gregorianDay):
            switch dateType {
            case .year:
                return .year(gregorianDay.year)
            case .month:
                return .month(GregorianMonth(year: gregorianDay.year, month: gregorianDay.month))
            case .day:
                return self
            }
        }
    }
    
    func leadingIndex(for dateType: DateType) -> Int {
        return leading(for: dateType).index
    }
    
    func trailingIndex(for dateType: DateType) -> Int {
        return trailing(for: dateType).index
    }
    
    func convert(to newDateType: DateType) -> EventDate {
        guard dateType != newDateType else {
            return self
        }
        return leading(for: newDateType)
    }
}
