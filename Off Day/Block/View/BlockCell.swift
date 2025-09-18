//
//  BlockCell.swift
//  Off Day
//
//  Created by zici on 2023/3/10.
//

import UIKit
import ZCCalendar
import MarqueeLabel

fileprivate extension UIConfigurationStateCustomKey {
    static let blockItem = UIConfigurationStateCustomKey("com.zizicici.zzz.cell.block.item")
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
    
    var commentMark: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.0
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    var highlightColor: UIColor = .gray.withAlphaComponent(0.35)
    
    // 存储布局相关状态
    private var hasPublicDay: Bool = false
    private var needsSetupViews: Bool = true
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isHover = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 设置视图frame
        let contentBounds = contentView.bounds
        let inset: CGFloat = 3.0
        
        // Corner mark (固定大小15x15，右上角)
        cornerMark.frame = CGRect(
            x: contentBounds.width - 15.0,
            y: 0,
            width: 15.0,
            height: 15.0
        )
        
        // Comment mark (固定大小5x5，左上角内边距5)
        commentMark.frame = CGRect(
            x: 5.0,
            y: 5.0,
            width: 5.0,
            height: 5.0
        )
        
        if hasPublicDay {
            // 有publicDayLabel时的布局
            let publicDayHeight: CGFloat = 16.0
            publicDayLabel.frame = CGRect(
                x: inset,
                y: contentBounds.height - publicDayHeight - inset,
                width: contentBounds.width - 2 * inset,
                height: publicDayHeight
            )
            publicDayLabel.setNeedsLayout()
            
            dateView.frame = CGRect(
                x: inset,
                y: inset,
                width: contentBounds.width - 2 * inset,
                height: contentBounds.height - publicDayHeight - 2 * inset
            )
        } else {
            // 没有publicDayLabel时的布局
            dateView.frame = contentBounds.insetBy(dx: inset, dy: inset)
            publicDayLabel.frame = .zero
        }
    }
    
    private func setupViewsIfNeeded() {
        guard needsSetupViews else { return }
        
        contentView.addSubview(dateView)
        contentView.addSubview(cornerMark)
        contentView.addSubview(commentMark)
        contentView.addSubview(publicDayLabel)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        
        needsSetupViews = false
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let item = state.blockItem {
            // 更新publicDayLabel状态
            if let publicDayName = item.publicDayName {
                hasPublicDay = true
                publicDayLabel.isHidden = false
                publicDayLabel.text = publicDayName
                publicDayLabel.textColor = item.foregroundColor
            } else {
                hasPublicDay = false
                publicDayLabel.isHidden = true
            }
            
            // 更新cornerMark
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
            
            // 更新背景色
            var backgroundColor = item.backgroundColor
            if isHover || isHighlighted {
                backgroundColor = highlightColor.overlay(on: backgroundColor)
            }
            
            // 更新dateView
            dateView.update(
                with: item.day.dayString(),
                alternativeCalendar: item.alternativeCalendarDayName,
                foregroundColor: item.foregroundColor
            )
            
            // 更新commentMark
            commentMark.isHidden = item.customDayInfo.customComment == nil
            commentMark.backgroundColor = item.foregroundColor.withAlphaComponent(0.5)
            
            // 更新accessibility
            if item.isToday {
                accessibilityLabel = String(localized: "weekCalendar.today") + (item.day.completeFormatString() ?? "")
            } else {
                accessibilityLabel = item.day.completeFormatString()
            }
            
            if let alternativeCalendarA11yName = item.alternativeCalendarA11yName {
                accessibilityLabel = (accessibilityLabel ?? "") + "," + alternativeCalendarA11yName
            }
            
            // 配置背景
            backgroundConfiguration = BlockCellBackgroundConfiguration.configuration(
                for: state,
                backgroundColor: backgroundColor,
                cornerRadius: 6.0,
                showStroke: item.isToday,
                strokeColor: AppColor.today,
                strokeWidth: 3.0,
                strokeOutset: 0.0
            )
            
            // 更新accessibilityValue
            let dayType: DayType = DayManager.isOffDay(
                baseCalendarDayType: item.baseCalendarDayType,
                publicDayType: item.publicDayType,
                customDayType: item.customDayType
            ) ? .offDay : .workDay
            
            accessibilityValue = String.assembleDetail(
                for: dayType,
                publicDayName: item.publicDayName,
                baseCalendarDayType: item.baseCalendarDayType,
                publicDayType: item.publicDayType,
                customDayType: item.customDayType,
                customComment: item.customDayInfo.customComment?.content
            )
        }
        
        // 标记需要重新布局
        setNeedsLayout()
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
