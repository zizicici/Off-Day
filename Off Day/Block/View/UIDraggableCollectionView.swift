//
//  UIDraggableCollectionView.swift
//  Off Day
//
//  Created by zici on 2023/3/21.
//

import UIKit

class UIDraggableCollectionView: UICollectionView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) {
            return true
        } else {
            return super.touchesShouldCancel(in: view)
        }
    }
}

class UIDraggableTableView: UITableView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIButton.self) {
            return true
        } else {
            return super.touchesShouldCancel(in: view)
        }
    }
}
