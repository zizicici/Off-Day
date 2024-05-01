//
//  BlockCell.swift
//  Off Day
//
//  Created by zici on 2023/3/10.
//

import UIKit
import SnapKit
import ZCCalendar

fileprivate extension UIConfigurationStateCustomKey {
    static let blockItem = UIConfigurationStateCustomKey("com.zizicici.pigeon.cell.block.item")
}

private extension UICellConfigurationState {
    var blockItem: BlockItem? {
        set { self[.blockItem] = newValue }
        get { return self[.blockItem] as? BlockItem }
    }
}

class BlockBaseCell: UICollectionViewCell {
    private var blockItem: BlockItem? = nil
    
    func update(with newBlockItem: BlockItem) {
        guard blockItem != newBlockItem else { return }
        blockItem = newBlockItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.blockItem = self.blockItem
        return state
    }
}

class BlockCell: BlockBaseCell {
    var isHover: Bool = false {
        didSet {
            if oldValue != isHover {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    var paperView: UIView = {
        let view = UIView()
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 4.0
        
        return view
    }()
    
    var highlightView: UIView = {
        let view = UIView()
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 4.0
        
        return view
    }()
    
    var label: UILabel = {
        let label = UILabel()
        label.textColor = .label.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    var defaultBackgroundColor: UIColor = .paper
    var highlightColor: UIColor = .gray.withAlphaComponent(0.5)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
        label.text = nil
        paperView.backgroundColor = defaultBackgroundColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        paperView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.init(x: 0, y: 0), size: CGSize(width: frame.width, height: frame.height)), cornerRadius: 4.0).cgPath
    }
    
    private func setupViewsIfNeeded() {
        guard paperView.superview == nil else { return }
        
//        contentView.backgroundColor = defaultBackgroundColor
//        contentView.layer.cornerCurve = .continuous
//        contentView.layer.cornerRadius = 3.0
//        contentView.layer.masksToBounds = true
        
        contentView.addSubview(paperView)
        paperView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
        paperView.layer.shadowColor = UIColor.gray.cgColor
        paperView.layer.shadowOpacity = 0.1
        paperView.layer.shadowOffset = CGSize(width: 0, height: 2)
        paperView.layer.cornerCurve = .continuous
        paperView.backgroundColor = defaultBackgroundColor
        
        paperView.addSubview(highlightView)
        highlightView.snp.makeConstraints { make in
            make.edges.equalTo(paperView)
        }
        
        paperView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalTo(paperView).inset(2)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            if item.calendarDay.dayType == .offday {
                paperView.backgroundColor = .offDay.withAlphaComponent(0.8)
            } else {
                paperView.backgroundColor = defaultBackgroundColor
            }
            if let events = item.events, let first = events.first {
                paperView.backgroundColor = UIColor(string: first.color)
                if paperView.backgroundColor?.isSimilar(to: .background) == true {
                    paperView.layer.borderWidth = 1.0
                    paperView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
                } else {
                    paperView.layer.borderWidth = 0.0
                }
            } else {
                paperView.layer.borderWidth = 0.0
            }
            if isHover || isHighlighted {
                highlightView.backgroundColor = highlightColor
            } else {
                highlightView.backgroundColor = .clear
            }
            
            switch (paperView.backgroundColor?.isLight ?? false, UIColor.text.isLight) {
            case (true, true):
                label.textColor = .text.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            case (false, true):
                label.textColor = .text
            case (false, false):
                label.textColor = .text.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            case (true, false):
                label.textColor = .text
            }
            
            label.text = item.day.dayString()
            accessibilityLabel = item.day.formatString()
        }
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    func update(isHover: Bool) {
        self.isHover = isHover
    }
    
    override var isHighlighted: Bool {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
}
