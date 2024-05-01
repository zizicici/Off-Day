//
//  BlockBaseViewController.swift
//  Off Day
//
//  Created by zici on 2024/1/2.
//

import UIKit
import Toast

class BlockBaseViewController: UIViewController {
    var collectionView: UICollectionView! = nil
    var hoverGesture: HoverGestureRecognizer?
    
    var lastIndexPath: IndexPath? = nil {
        didSet {
            view.hideAllToasts()
            if let previousIndexPath = oldValue {
                if let cell = collectionView?.cellForItem(at: previousIndexPath) as? BlockCell {
                    cell.update(isHover: false)
                }
            }
            if let currentIndexPath = lastIndexPath {
                if let cell = collectionView?.cellForItem(at: currentIndexPath) as? BlockCell {
                    cell.update(isHover: true)
                    hover(in: currentIndexPath)
                }
            }
        }
    }

    func addGestures() {
        let swipeGesture = HoverGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        swipeGesture.delaysTouchesBegan = false
        swipeGesture.delaysTouchesEnded = false
        collectionView?.addGestureRecognizer(swipeGesture)
        self.hoverGesture = swipeGesture
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction(_:)))
        collectionView?.addGestureRecognizer(tapGesture)
//        swipeGesture.require(toFail: tapGesture)
    }
    
    @objc func tapGestureAction(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: collectionView)
        print(recognizer.state.rawValue)
        switch recognizer.state {
        case .ended:
            if let indexPath = collectionView?.indexPathForItem(at: point) {
                tap(in: indexPath)
            }
        default:
            break
        }
    }
    
    @objc func panGestureAction(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: collectionView)
        switch recognizer.state {
        case .possible:
            print("possible")
        case .began:
            lastIndexPath = collectionView?.indexPathForItem(at: point)
        case .changed:
            updateLastIndexPath(at: point)
        case .failed, .cancelled:
            updateLastIndexPath(at: nil)
        case .ended:
            updateLastIndexPath(at: nil)
            if let currentIndexPath = collectionView?.indexPathForItem(at: point) {
                tap(in: currentIndexPath)
            }
        @unknown default:
            updateLastIndexPath(at: nil)
        }
    }
    
    public func updateLastIndexPath(at point: CGPoint?) {
        if let point = point {
            let currentIndexPath = collectionView?.indexPathForItem(at: point)
            if lastIndexPath != currentIndexPath {
                lastIndexPath = currentIndexPath
            }
        } else {
            lastIndexPath = nil
        }
    }
    
    open func tap(in indexPath: IndexPath) {
        
    }
    
    open func hover(in indexPath: IndexPath) {
        impactFeedbackGeneratorCoourred()
    }
    
    func impactFeedbackGeneratorCoourred() {
        ImpactGenerator.impact(intensity: 0.5, style: .rigid)
    }
    
    func updateVisibleItems() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems

        guard let firstIndexPath = visibleIndexPaths.min(by: { $0.section < $1.section }),
              let lastIndexPath = visibleIndexPaths.max(by: { $0.section < $1.section }) else {
            // Handle the case where visibleIndexPaths is empty
            return
        }

        update(startSection: firstIndexPath.section, endSection: lastIndexPath.section)
    }
    
    open func update(startSection: Int, endSection: Int) {
        
    }
}

extension BlockBaseViewController: UICollectionViewDelegate {
    
}

extension BlockBaseViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let _ = scrollView as? UICollectionView {
//            print("didScroll")
            hoverGesture?.cancelWorkItem()
        }
//        scrollObserver?.dayDetailViewDidScroll(scrollView)
        
        updateVisibleItems()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let _ = scrollView as? UICollectionView {
//            print("beginDragging")
            hoverGesture?.cancelWorkItem()
        }
//        scrollObserver?.dayDetailViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        scrollObserver?.dayDetailViewDidEndDecelerating(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
//            scrollObserver?.dayDetailViewDidEndDecelerating(scrollView)
        }
    }
}
