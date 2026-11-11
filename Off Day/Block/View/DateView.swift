//
//  DateView.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import UIKit

class DateView: UIView {
    private var firstLabel: CalendarInkTextLabel = {
        let label = CalendarInkTextLabel()
        label.textColor = AppColor.text
        label.textAlignment = .center
        label.font = UIFont.monospacedDigitSystemFont(ofSize: CalendarDayAppearance.dateFontSize, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private var secondaryLabel: CalendarInkTextLabel = {
        let label = CalendarInkTextLabel()
        label.textColor = AppColor.text
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: CalendarDayAppearance.alternativeFontSize, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private var hasAlternativeCalendar: Bool {
        return !secondaryLabel.isHidden
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(firstLabel)
        addSubview(secondaryLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(with date: String, alternativeCalendar: String?, foregroundColor: UIColor,
                       inkBackingColor: UIColor? = nil) {
        firstLabel.text = date
        firstLabel.textColor = foregroundColor
        firstLabel.inkBackingColor = inkBackingColor
        secondaryLabel.inkBackingColor = inkBackingColor
        
        if let alternativeCalendar = alternativeCalendar {
            secondaryLabel.isHidden = false
            secondaryLabel.text = alternativeCalendar
            secondaryLabel.textColor = foregroundColor
        } else {
            secondaryLabel.isHidden = true
        }
        
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if hasAlternativeCalendar {
            let secondaryHeight = CalendarDayAppearance.alternativeHeight
            secondaryLabel.frame = CGRect(
                x: 0,
                y: bounds.height - secondaryHeight,
                width: bounds.width,
                height: secondaryHeight
            )
            
            firstLabel.frame = CGRect(
                x: 0,
                y: 0,
                width: bounds.width,
                height: bounds.height - secondaryHeight
            )
        } else {
            firstLabel.frame = bounds
        }
    }
}
