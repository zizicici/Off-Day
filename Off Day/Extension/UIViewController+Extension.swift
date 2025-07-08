//
//  UIViewController+Extension.swift
//  coco
//
//  Created by zici on 2023/5/11.
//

import UIKit
import SafariServices

extension UIViewController {
    func updateNavigationBarStyle(hideShadow: Bool = false) {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.backgroundColor = AppColor.navigationBar
        if hideShadow {
            navBarAppearance.shadowColor = UIColor.clear            
        }
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.tintColor = UIColor.white
    }

    func openSF(with url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        navigationController?.present(safariViewController, animated: ConsideringUser.animated)
    }
}
