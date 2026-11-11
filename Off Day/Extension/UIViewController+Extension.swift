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
        navBarAppearance.titleTextAttributes = [.foregroundColor: AppColor.navigationText]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: AppColor.navigationText]
        navBarAppearance.backgroundColor = AppColor.navigationBar
        if hideShadow {
            navBarAppearance.shadowColor = UIColor.clear            
        }
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.tintColor = AppColor.navigationText
        // Screen setup can run after the navigation controller's initial theme pass.
        (navigationController as? NavigationController)?.refreshTheme()
    }

    func openSF(with url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredControlTintColor = AppColor.accent
        safariViewController.preferredBarTintColor = AppColor.background
        navigationController?.present(safariViewController, animated: ConsideringUser.animated)
    }
}

extension UIViewController {
    func showAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "button.ok"), style: .cancel)
        alertController.addAction(cancelAction)

        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
}

extension UIViewController {
    func jumpToSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}
