//
//  ShortcutsViewController.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import SnapKit

class ShortcutsViewController: UIViewController {
    let shortcutsURL = URL(string: "https://www.icloud.com/shortcuts/9e320348949c4b89a85499b6aed38533")
    
    private var addButton: UIButton = {
        var configuration = UIButton.Configuration.borderedTinted()
        configuration.image = UIImage(systemName: "wand.and.stars", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24.0))
        configuration.title = String(localized: "shortcuts.add.title")
        configuration.subtitle = String(localized: "shortcuts.add.subtitle")
        configuration.imagePadding = 8.0
        configuration.titlePadding = 4.0
        configuration.cornerStyle = .large
        configuration.buttonSize = .large
        
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .headline)

            return outgoing
        })
        
        let button = UIButton(configuration: configuration)
        button.tintColor = .offDay
        
        return button
    }()

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
        
        view.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.height.greaterThanOrEqualTo(60)
        }
        addButton.addTarget(self, action: #selector(addShortcuts), for: .touchUpInside)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func addShortcuts() {
        if let shortcutsURL = shortcutsURL {
            UIApplication.shared.open(shortcutsURL, options: [:], completionHandler: nil)
        }
    }
}
