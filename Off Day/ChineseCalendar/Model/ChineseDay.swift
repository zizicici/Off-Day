//
//  ChineseDay.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import Foundation

enum ChineseDay: Int {
    case chuYi = 1
    case chuEr = 2
    case chuSan = 3
    case chuSi = 4
    case chuWu = 5
    case chuLiu = 6
    case chuQi = 7
    case chuBa = 8
    case chuJiu = 9
    case chuShi = 10
    case shiYi = 11
    case shiEr = 12
    case shiSan = 13
    case shiSi = 14
    case shiWu = 15
    case shiLiu = 16
    case shiQi = 17
    case shiBa = 18
    case shiJiu = 19
    case erShi = 20
    case nianYi = 21
    case nianEr = 22
    case nianSan = 23
    case nianSi = 24
    case nianWu = 25
    case nianLiu = 26
    case nianQi = 27
    case nianBa = 28
    case nianJiu = 29
    case sanShi = 30
    case saYi = 31 // Design for Tianli

    func displayString() -> String {
        var result = ""
        switch self {
        case .chuYi:
            result = "初一"
        case .chuEr:
            result = "初二"
        case .chuSan:
            result = "初三"
        case .chuSi:
            result = "初四"
        case .chuWu:
            result = "初五"
        case .chuLiu:
            result = "初六"
        case .chuQi:
            result = "初七"
        case .chuBa:
            result = "初八"
        case .chuJiu:
            result = "初九"
        case .chuShi:
            result = "初十"
        case .shiYi:
            result = "十一"
        case .shiEr:
            result = "十二"
        case .shiSan:
            result = "十三"
        case .shiSi:
            result = "十四"
        case .shiWu:
            result = "十五"
        case .shiLiu:
            result = "十六"
        case .shiQi:
            result = "十七"
        case .shiBa:
            result = "十八"
        case .shiJiu:
            result = "十九"
        case .erShi:
            result = "二十"
        case .nianYi:
            result = "廿一"
        case .nianEr:
            result = "廿二"
        case .nianSan:
            result = "廿三"
        case .nianSi:
            result = "廿四"
        case .nianWu:
            result = "廿五"
        case .nianLiu:
            result = "廿六"
        case .nianQi:
            result = "廿七"
        case .nianBa:
            result = "廿八"
        case .nianJiu:
            result = "廿九"
        case .sanShi:
            result = "三十"
        case .saYi:
            result = "卅一"
        }
        return result
    }
}
