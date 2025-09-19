//
//  TabbarController.swift
//  Off Day
//
//  Created by zici on 2023/11/20.
//

import UIKit

class TabbarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
        
        if #available(iOS 18, *), UIDevice.current.userInterfaceIdiom == .pad {
            setOverrideTraitCollection( UITraitCollection(horizontalSizeClass: .compact), forChild: self)
        }
        
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior = .onScrollDown
        } else {
            // Fallback on earlier versions
        }
    }
}
