//
//  WeekdayOrderView.swift
//  Off Day
//
//  Created by zici on 2/8/24.
//

import UIKit
import SnapKit
import ZCCalendar

class WeekdayOrderView: UIView {
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5.0
        
        return stackView
    }()
    
    var labelColor: UIColor? {
        didSet {
            for subview in stackView.arrangedSubviews {
                if let label = subview as? UILabel {
                    label.textColor = labelColor
                }
            }
        }
    }
    
    private var itemWidth: CGFloat = 50.0
    private var interSpacing: CGFloat = 5.0
    private var itemCount: Int = 7
    
    var startWeekdayOrder: WeekdayOrder = WeekdayOrder.sun {
        didSet {
            if startWeekdayOrder != oldValue {
                updateLabels()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(12)
            make.top.equalTo(self)
            make.bottom.equalTo(self).inset(2)
        }
        
        updateLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(itemCount: Int, itemWidth: CGFloat, interSpacing: CGFloat) {
        self.init(frame: .zero)
        self.itemCount = itemCount
        self.itemWidth = itemWidth
        self.interSpacing = interSpacing
        self.stackView.spacing = interSpacing
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inset = (frame.width - itemWidth * CGFloat(itemCount) - interSpacing * CGFloat(itemCount - 1)) / 2.0
        stackView.snp.updateConstraints { make in
            make.leading.trailing.equalTo(self).inset(inset)
        }
    }
    
    func updateLabels() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let weekdayOrders = Array(0..<7).compactMap { index in
            let newIndex = self.startWeekdayOrder.rawValue + index
            if newIndex == 7 {
                return WeekdayOrder.sun
            } else {
                return WeekdayOrder(rawValue: newIndex % 7)
            }
        }
        for weekdayOrder in weekdayOrders {
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            label.textColor = .white
            label.text = weekdayOrder.getVeryShortSymbol()
            label.accessibilityLabel = weekdayOrder.getSymbol()
            stackView.addArrangedSubview(label)
        }
    }
}
