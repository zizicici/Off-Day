//
//  StandardConfigCell.swift
//  Off Day
//
//  Created by zici on 8/5/24.
//

import UIKit
import SnapKit
import ZCCalendar

class StandardConfigCell: UITableViewCell {
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        
        return stackView
    }()
    
    var updateClosure: (([WeekdayOrder]) -> ())?
    
    var buttonDict: [WeekdayOrder: UIButton] = [:]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectedBackgroundView = UIView()
        
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView).inset(12)
            make.top.bottom.equalTo(contentView).inset(10).priority(.low)
            make.height.equalTo(40.0)
        }
        
        for order in WeekdayOrder.allCases {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = .clear
            configuration.baseForegroundColor = AppColor.text
            configuration.title = order.getVeryShortSymbol()
            
            let button = UIButton.init(configuration: configuration)
            button.configuration = configuration
            button.configurationUpdateHandler = { button in
                if button.isHighlighted || button.isSelected {
                    button.configuration?.baseBackgroundColor = AppColor.offDay
                    button.configuration?.baseForegroundColor = .white
                } else {
                    button.configuration?.baseBackgroundColor = .clear
                    button.configuration?.baseForegroundColor = AppColor.text
                }
            }
            button.snp.makeConstraints { make in
                make.width.height.equalTo(40.0)
            }
            button.addTarget(self, action: #selector(updateButton(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            
            buttonDict[order] = button
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func updateButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        notify()
    }
    
    func update(_ weekdayOrder: [WeekdayOrder]) {
        for order in weekdayOrder {
            buttonDict[order]?.isSelected = true
        }
    }
    
    func notify() {
        var result: [WeekdayOrder] = []
        for order in WeekdayOrder.allCases {
            if buttonDict[order]?.isSelected == true {
                result.append(order)
            }
        }
        updateClosure?(result)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        buttonDict.values.forEach { $0.isSelected = false }
    }
}
