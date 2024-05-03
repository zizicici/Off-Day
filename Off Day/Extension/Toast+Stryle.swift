//
//  Toast+Stryle.swift
//  Off Day
//
//  Created by zici on 3/5/24.
//

import UIKit
import Toast

extension ToastStyle {
    static func getStyle(messageColor: UIColor, backgroundColor: UIColor) -> Self {
        var style = Self.init()
        
        style.messageColor = messageColor
        style.backgroundColor = backgroundColor
        
        style.messageAlignment = .center
        style.verticalPadding = 12.0
        style.horizontalPadding = 16.0

        style.shadowColor = UIColor.gray
        style.shadowOpacity = 0.2
        style.shadowOffset = CGSize(width: 0, height: 2)
        style.shadowRadius = 4.0
        style.displayShadow = true
        
        return style
    }
}
