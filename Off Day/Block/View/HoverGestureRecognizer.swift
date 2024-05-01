//
//  HoverGestureRecognizer.swift
//  Off Day
//
//  Created by zici on 2023/3/10.
//

import Foundation
import UIKit

class HoverGestureRecognizer: UIPanGestureRecognizer {
    private var beginPoint: CGPoint?
    private var currentWorkItem: DispatchWorkItem? {
        didSet {
            if oldValue?.isCancelled == false {
                oldValue?.cancel()
            }
        }
    }
    
    func cancelWorkItem() {
//        print("cancel work item")
        currentWorkItem?.cancel()
    }
    
    func updateStateToBeganIfNeeded() {
//        print("state: \(state.rawValue)")
        switch state {
        case .possible:
            state = .began
        case .failed:
            break
        default:
            break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
//        print("touchBegan")
//        currentWorkItem?.cancel()
        super.touchesBegan(touches, with: event)
        beginPoint = touches.first?.location(in: self.view)
        if let collectionView = self.view as? UICollectionView, let beginPoint = beginPoint {
            if collectionView.indexPathForItem(at: beginPoint) == nil {
                return
            }
        }
        currentWorkItem = DispatchWorkItem { // Set the work item with the block you want to execute
            self.updateStateToBeganIfNeeded()
        }
        if let workItem = currentWorkItem {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: workItem)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
//        print("cancel \(state.rawValue)")
        cancelWorkItem()
        super.touchesCancelled(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
//        print("end \(state.rawValue)")
        cancelWorkItem()
        super.touchesEnded(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
//        print("touchmoved")
        defer {
            super.touchesMoved(touches, with: event)
            self.beginPoint = nil
        }
        currentWorkItem?.cancel()
        guard let view = self.view,
              touches.first?.location(in: view) != nil,
              self.beginPoint != nil else {
//            print()
            return
        }
        if state != .began {
            state = .failed
        }
//        let deltaY = abs(beginPoint.y - touchPoint.y)
//        let deltaX = abs(beginPoint.x - touchPoint.x)
//        print("deltaY:\(deltaY), deltaX:\(deltaX)")
//        if deltaY != 0 && deltaY / deltaX > 0.5 && deltaY > 3 {
//            state = .failed
//            print("failed")
//            return
//        }
    }
}

