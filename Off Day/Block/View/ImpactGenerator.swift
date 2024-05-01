//
//  ImpactGenerator.swift
//  Off Day
//
//  Created by zici on 2023/3/21.
//

import UIKit

struct ImpactGenerator {
    static func impact(intensity: CGFloat = 0.5, style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
}
