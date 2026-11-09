//
//  NavigationViewController.swift
//  Off Day
//
//  Created by zici on 2023/8/15.
//

import UIKit

class NavigationController: UINavigationController {
    @available(iOS 27.1, *)
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }

    @available(iOS 27.1, *)
    override var childForPreferredVerticalBarBehavior: UIViewController? {
        nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return children.first?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool {
        return children.first?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
}
