//
//  ChineseDayInfo.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import Foundation

enum SexagenaryCycleInfo: Int, Codable {
    case jiaZi = 0
    case yiChou
    case bingYin
    case dingMao
    case wuChen
    case jiSi
    case gengWu
    case xinWei
    case renShen
    case guiYou
    case jiaXu
    case yiHai
    case bingZi
    case dingChou
    case wuYin
    case jiMao
    case gengChen
    case xinSi
    case renWu
    case guiWei
    case jiaShen
    case yiYou
    case bingXu
    case dingHai
    case wuZi
    case jiChou
    case gengYin
    case xinMao
    case renChen
    case guiSi
    case jiaWu
    case yiWei
    case bingShen
    case dingYou
    case wuXu
    case jiHai
    case gengZi
    case xinChou
    case renYin
    case guiMao
    case jiaChen
    case yiSi
    case bingWu
    case dingWei
    case wuShen
    case jiYou
    case gengXu
    case xinHai
    case renZi
    case guiChou
    case jiaYin
    case yiMao
    case bingChen
    case dingSi
    case wuWu
    case jiWei
    case gengShen
    case xinYou
    case renXu
    case guiHai

    func name(_ yearType: ChineseYearType? = nil) -> String {
        switch self {
        case .jiaZi:
            return "甲子"
        case .yiChou:
            return "乙丑"
        case .bingYin:
            return "丙寅"
        case .dingMao:
            return "丁卯"
        case .wuChen:
            return "戊辰"
        case .jiSi:
            return "己巳"
        case .gengWu:
            return "庚午"
        case .xinWei:
            return "辛未"
        case .renShen:
            return "壬申"
        case .guiYou:
            return "癸酉"
        case .jiaXu:
            return "甲戌"
        case .yiHai:
            return "乙亥"
        case .bingZi:
            return "丙子"
        case .dingChou:
            return "丁丑"
        case .wuYin:
            return "戊寅"
        case .jiMao:
            return "己卯"
        case .gengChen:
            return "庚辰"
        case .xinSi:
            return "辛巳"
        case .renWu:
            return "壬午"
        case .guiWei:
            return "癸未"
        case .jiaShen:
            return "甲申"
        case .yiYou:
            return "乙酉"
        case .bingXu:
            return "丙戌"
        case .dingHai:
            return "丁亥"
        case .wuZi:
            return "戊子"
        case .jiChou:
            return "己丑"
        case .gengYin:
            return "庚寅"
        case .xinMao:
            return "辛卯"
        case .renChen:
            return "壬辰"
        case .guiSi:
            return "癸巳"
        case .jiaWu:
            return "甲午"
        case .yiWei:
            return "乙未"
        case .bingShen:
            return "丙申"
        case .dingYou:
            return "丁酉"
        case .wuXu:
            return "戊戌"
        case .jiHai:
            return "己亥"
        case .gengZi:
            return "庚子"
        case .xinChou:
            return "辛丑"
        case .renYin:
            return "壬寅"
        case .guiMao:
            return "癸卯"
        case .jiaChen:
            return "甲辰"
        case .yiSi:
            return "乙巳"
        case .bingWu:
            return "丙午"
        case .dingWei:
            return "丁未"
        case .wuShen:
            return "戊申"
        case .jiYou:
            return "己酉"
        case .gengXu:
            return "庚戌"
        case .xinHai:
            return "辛亥"
        case .renZi:
            return "壬子"
        case .guiChou:
            return "癸丑"
        case .jiaYin:
            return "甲寅"
        case .yiMao:
            return "乙卯"
        case .bingChen:
            return "丙辰"
        case .dingSi:
            return "丁巳"
        case .wuWu:
            return "戊午"
        case .jiWei:
            return "己未"
        case .gengShen:
            return "庚申"
        case .xinYou:
            return "辛酉"
        case .renXu:
            return "壬戌"
        case .guiHai:
            return "癸亥"
        }
    }

    func chineseZodiac() -> ChineseZodiac {
        return ChineseZodiac(rawValue: rawValue % 12) ?? .shu
    }
}

enum ChineseZodiac: Int, Codable {
    case shu = 0
    case niu
    case hu
    case tu
    case long
    case she
    case ma
    case yang
    case hou
    case ji
    case gou
    case zhu

    func name() -> String {
        switch self {
        case .shu:
            return "鼠"
        case .niu:
            return "牛"
        case .hu:
            return "虎"
        case .tu:
            return "兔"
        case .long:
            return "龙"
        case .she:
            return "蛇"
        case .ma:
            return "马"
        case .yang:
            return "羊"
        case .hou:
            return "猴"
        case .ji:
            return "鸡"
        case .gou:
            return "狗"
        case .zhu:
            return "猪"
        }
    }
}

enum Rokuyo: Int {
    case sensho = 2
    case tomobiki = 3
    case senbu = 4
    case butsumetsu = 5
    case taian = 0
    case shakku = 1
    
    var name: String {
        switch self {
        case .sensho:
            return "先勝"
        case .tomobiki:
            return "友引"
        case .senbu:
            return "先負"
        case .butsumetsu:
            return "仏滅"
        case .taian:
            return "大安"
        case .shakku:
            return "赤口"
        }
    }
    
    static func get(at dayInfo: ChineseDayInfo) -> Self {
        var value = 0
        switch dayInfo.month {
        case .normal(let month):
            value = (month.rawValue + dayInfo.day.rawValue) % 6
        case .interCalary(let month):
            value = (month.rawValue + dayInfo.day.rawValue) % 6
        }
        return Rokuyo(rawValue: value) ?? .taian
    }
}

struct ChineseDayInfo {
    let year: ChineseYear
    let month: RepeatableChineseMonth
    let day: ChineseDay
    let variant: ChineseCalendarVariant

    func shortDisplayString() -> String {
        switch variant {
        case .chinese:
            if day == .chuYi {
                return month.rawValue
            } else {
                return day.displayString()
            }
        case .kyureki:
            switch month {
            case .normal(let chineseMonth):
                return String(format: "旧 %d/%d", chineseMonth.rawValue, day.rawValue)
            case .interCalary(let chineseMonth):
                return String(format: "旧 閏%d/%d", chineseMonth.rawValue, day.rawValue)
            }
        }
    }

    func displayString() -> String {
        let yearString = year.sexagenaryCycleInfo.name(year.yearType)
        let chineseZodiac = year.sexagenaryCycleInfo.chineseZodiac().name()
        let monthString = month.rawValue
        let dayString = day.displayString()
        return "农历" + yearString + "\(chineseZodiac)" + "年" + monthString + dayString
    }
    
    func pronounceString() -> String {
        let yearString = year.sexagenaryCycleInfo.name(year.yearType)
        let monthString = month.rawValue
        let dayString = day.displayString()
        return yearString + "年" + monthString + dayString
    }
}
