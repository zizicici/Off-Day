//
//  ShortcutsViewController.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import SnapKit

class ShortcutsViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = String(localized: "controller.shortcuts.title")
        tabBarItem = UITabBarItem(title: String(localized: "controller.shortcuts.title"), image: UIImage(systemName: "sparkles"), tag: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("ShortcutsViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
        updateNavigationBarStyle()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
