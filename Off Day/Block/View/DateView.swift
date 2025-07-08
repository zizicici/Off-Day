//
//  DateView.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import UIKit

class DateView: UIView {
    private var firstLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private var secondaryLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
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
    
    public func update(with date: String, alternativeCalendar: String?, foregroundColor: UIColor) {
        firstLabel.text = date
        firstLabel.textColor = foregroundColor
        
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
            let secondaryHeight: CGFloat = 14
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
