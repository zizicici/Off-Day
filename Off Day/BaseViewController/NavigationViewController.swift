//
//  NavigationViewController.swift
//  Off Day
//
//  Created by zici on 2023/8/15.
//

import UIKit

class NavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return children.first?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool {
        return children.first?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
}
