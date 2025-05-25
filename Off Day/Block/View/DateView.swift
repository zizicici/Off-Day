//
//  DateView.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import UIKit
import SnapKit

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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(with date: String, alternativeCalendar: String?, foregroundColor: UIColor) {
        guard firstLabel.superview == nil else { return }
        firstLabel.text = date
        firstLabel.textColor = foregroundColor
        if let alternativeCalendar = alternativeCalendar {
            addSubview(secondaryLabel)
            secondaryLabel.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalTo(self)
                make.height.equalTo(14)
            }
            secondaryLabel.text = alternativeCalendar
            secondaryLabel.textColor = foregroundColor
            
            addSubview(firstLabel)
            firstLabel.snp.makeConstraints { make in
                make.leading.trailing.top.equalTo(self)
                make.bottom.equalTo(secondaryLabel.snp.top)
            }
        } else {
            addSubview(firstLabel)
            firstLabel.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }
        }
    }
    
    public func prepareForReuse() {
        firstLabel.removeFromSuperview()
        secondaryLabel.removeFromSuperview()
    }
}
