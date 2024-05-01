//
//  BlockViewController+Popover.swift
//  Off Day
//
//  Created by zici on 2024/1/4.
//

import UIKit

extension BlockViewController {
    func showPopoverView(at sourceView: UIView, contentViewController: UIViewController) {
        let nav = UINavigationController.init(rootViewController: contentViewController)
        nav.preferredContentSize = CGSize(width: 330, height: 400)
        nav.modalPresentationStyle = .popover

        if let pres = nav.presentationController {
            pres.delegate = self
        }
        present(nav, animated: true, completion: nil)

        if let popover = nav.popoverPresentationController {
            popover.sourceView = sourceView
            popover.permittedArrowDirections = [.up, .down]
        }
    }
}

extension BlockViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if view.frame.width < 376.0 {
            return .automatic
        } else {
            return .none
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
//        if let nav = presentationController.presentedViewController as? UINavigationController, let addVC = nav.topViewController as? EventEditorViewController {
//            return addVC.allowDismiss()
//        } else {
//            return true
//        }
        return true
    }
}
