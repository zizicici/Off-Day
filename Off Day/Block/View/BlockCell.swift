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
    static let blockItem = UIConfigurationStateCustomKey("com.zizicici.offday.cell.block.item")
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
        view.layer.cornerRadius = 6.0
        
        return view
    }()
    
    var highlightView: UIView = {
        let view = UIView()
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 6.0
        
        return view
    }()
    
    var label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    var cornerMark: UIImageView = {
        let view = UIImageView(image: UIImage(named: "OffDayMark"))
        view.layer.cornerRadius = 4.0
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        
        return view
    }()
    
    var defaultBackgroundColor: UIColor = AppColor.paper
    var highlightColor: UIColor = .gray.withAlphaComponent(0.5)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
        label.text = nil
        label.backgroundColor = .clear
        paperView.backgroundColor = defaultBackgroundColor
        cornerMark.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        paperView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.init(x: 0, y: 0), size: CGSize(width: frame.width, height: frame.height)), cornerRadius: 6.0).cgPath
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
        
        paperView.addSubview(cornerMark)
        cornerMark.snp.makeConstraints { make in
            make.right.top.equalTo(paperView)
            make.width.height.equalTo(15.0)
        }
        
        paperView.addSubview(highlightView)
        highlightView.snp.makeConstraints { make in
            make.edges.equalTo(paperView)
        }
        
        paperView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalTo(paperView).inset(3)
        }
        label.layer.cornerRadius = 4.0
        label.clipsToBounds = true
        
        paperView.bringSubviewToFront(cornerMark)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            paperView.backgroundColor = item.backgroundColor
            if let customDayType = item.customDayType {
                cornerMark.isHidden = false
                switch customDayType {
                case .offDay:
                    cornerMark.image = UIImage(named: "OffDayMark")
                case .workDay:
                    cornerMark.image = UIImage(named: "WorkDayMark")
                }
            } else {
                cornerMark.isHidden = true
            }
            if isHover || isHighlighted {
                highlightView.backgroundColor = highlightColor
            } else {
                highlightView.backgroundColor = .clear
            }
            
            label.textColor = item.foregroundColor
            label.text = item.day.dayString()
            if item.isToday {
                label.backgroundColor = AppColor.today
                accessibilityLabel = String(localized: "weekCalendar.today") + (item.day.completeFormatString() ?? "")
            } else {
                accessibilityLabel = item.day.completeFormatString()
            }
            
            let dayType: DayType = DayManager.isOffDay(baseCalendarDayType: item.baseCalendarDayType, publicDayType: item.publicDayType, customDayType: item.customDayType) ? .offDay : .workDay
            accessibilityValue = String.assembleDetail(for: dayType, publicDayName: item.publicDayName, baseCalendarDayType: item.baseCalendarDayType, publicDayType: item.publicDayType, customDayType: item.customDayType)
        }
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
