//
//  BlockCell.swift
//  Off Day
//
//  Created by zici on 2023/3/10.
//

import UIKit
import SnapKit
import ZCCalendar
import MarqueeLabel

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
    
    var dateView: DateView = {
        let label = DateView()
        
        return label
    }()
    
    var publicDayLabel: MarqueeLabel = {
        let label = MarqueeLabel(frame: .zero, duration: 4.0, fadeLength: 2.0)
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.trailingBuffer = 10.0
        label.textAlignment = .center
        
        return label
    }()
    
    var cornerMark: UIImageView = {
        let view = UIImageView(image: UIImage(named: "OffDayMark"))
        view.layer.cornerRadius = 6.0
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        
        return view
    }()
    
    var highlightColor: UIColor = .gray.withAlphaComponent(0.35)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isHover = false
        dateView.prepareForReuse()
        cornerMark.isHidden = true
        publicDayLabel.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func setupViewsIfNeeded() {
        guard dateView.superview == nil else { return }
        
        contentView.addSubview(dateView)

        contentView.addSubview(cornerMark)
        cornerMark.snp.makeConstraints { make in
            make.right.top.equalTo(contentView)
            make.width.height.equalTo(15.0)
        }
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            if let publicDayName = item.publicDayName {
                contentView.addSubview(publicDayLabel)
                publicDayLabel.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalTo(contentView).inset(3.0)
                    make.height.equalTo(16.0)
                }
                publicDayLabel.text = publicDayName
                publicDayLabel.textColor = item.foregroundColor
                dateView.snp.remakeConstraints { make in
                    make.leading.trailing.top.equalTo(contentView).inset(3.0)
                    make.bottom.equalTo(publicDayLabel.snp.top)
                }
            } else {
                dateView.snp.remakeConstraints { make in
                    make.edges.equalTo(contentView).inset(3.0)
                }
            }
            
            var backgroundColor = item.backgroundColor
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
                backgroundColor = highlightColor.overlay(on: backgroundColor)
            }
            
            dateView.update(with: item.day.dayString(), alternativeCalendar: item.alternativeCalendarName, foregroundColor: item.foregroundColor)
            if item.isToday {
                accessibilityLabel = String(localized: "weekCalendar.today") + (item.day.completeFormatString() ?? "")
            } else {
                accessibilityLabel = item.day.completeFormatString()
            }
            
            backgroundConfiguration = BlockCellBackgroundConfiguration.configuration(for: state, backgroundColor: backgroundColor, cornerRadius: 6.0, showStroke: item.isToday, strokeColor: AppColor.today, strokeWidth: 3.0, strokeOutset: 0.0)
            
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
}

struct BlockCellBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState, backgroundColor: UIColor = .clear, cornerRadius: CGFloat = 6.0, showStroke: Bool, strokeColor: UIColor, strokeWidth: CGFloat = 1.0, strokeOutset: CGFloat = -1.0) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = backgroundColor
        background.cornerRadius = cornerRadius
        background.strokeWidth = strokeWidth
        background.strokeOutset = strokeOutset
        if showStroke {
            background.strokeColor = strokeColor
        } else {
            background.strokeColor = .clear
        }
        if #available(iOS 18.0, *) {
            background.shadowProperties.color = .systemGray
            background.shadowProperties.opacity = 0.1
            background.shadowProperties.radius = 6.0
            background.shadowProperties.offset = CGSize(width: 0.0, height: 2.0)
        }

        return background
    }
}
