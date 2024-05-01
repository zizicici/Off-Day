//
//  MoreViewController.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import SnapKit

class MoreViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = String(localized: "controller.more.title")
        tabBarItem = UITabBarItem(title: String(localized: "controller.more.title"), image: UIImage(systemName: "ellipsis"), tag: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("MoreViewController is deinited")
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

