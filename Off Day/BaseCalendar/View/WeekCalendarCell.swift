//
//  WeekCalendarCell.swift
//  Off Day
//
//  Created by zici on 8/5/24.
//

import UIKit
import SnapKit
import ZCCalendar

class WeekCalendarCell: UITableViewCell {
    let containerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 10.0
        
        return stackView
    }()
    
    var updateClosure: (([Int]) -> ())?
    
    var buttonDict: [Int: UIButton] = [:]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectedBackgroundView = UIView()
        
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView).inset(12)
            make.top.bottom.equalTo(contentView).inset(10).priority(.low)
            make.height.equalTo(40)
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
    
    func update(_ config: WeeksCircleConfig) {
        containerView.snp.updateConstraints { make in
            make.height.equalTo(config.weekCount.rawValue * (40 + 10) - 10)
        }
        let today = ZCCalendar.manager.today
        let mondayIndex = today.julianDay - today.weekdayOrder().rawValue + 1
        let weekCount = config.weekCount
        let weekOffset = (mondayIndex / 7) % weekCount.rawValue
        let actualOffset = (weekOffset + weekCount.rawValue - config.offset) % weekCount.rawValue
        let actualStartIndex = mondayIndex - actualOffset * 7
        
        for row in 0..<config.weekCount.rawValue {
            let rowStartIndex = actualStartIndex + row * 7
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .equalSpacing
            
            for itemIndex in 0..<7 {
                let day = GregorianDay(JDN: itemIndex + rowStartIndex)
                
                var configuration = UIButton.Configuration.filled()
                configuration.baseBackgroundColor = .clear
                configuration.baseForegroundColor = AppColor.text
                configuration.titleAlignment = .center
                configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
                    var outgoing = incoming
                    outgoing.font = UIFont.systemFont(ofSize: 9)

                    return outgoing
                })
                configuration.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
                    var outgoing = incoming
                    outgoing.font = UIFont.systemFont(ofSize: 15)

                    return outgoing
                })
                if today == day {
                    configuration.subtitle = "今天"
                } else {
                    configuration.title = day.weekdayOrder().getVeryShortSymbol()
                    configuration.subtitle = day.dayString()
                }
                configuration.contentInsets = .zero
                
                let button = UIButton.init(configuration: configuration)
                button.configuration = configuration
                button.configurationUpdateHandler = { button in
                    if button.isHighlighted || button.isSelected {
                        button.configuration?.baseBackgroundColor = WeekEndColorType.getValue().getColor()
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
                var buttonIndex = itemIndex + row * 7
                let lineCount = config.weekCount.rawValue
                let move = (lineCount - config.offset) % lineCount
                if row < move {
                    buttonIndex += (lineCount - move) * 7
                } else {
                    buttonIndex -= move * 7
                }
                if config.indexs.contains(buttonIndex) {
                    button.isSelected = true
                }
                buttonDict[buttonIndex] = button
            }
            
            containerView.addArrangedSubview(stackView)
        }
    }
    
    func notify() {
        var result: [Int] = []
        for key in buttonDict.keys.sorted() {
            if buttonDict[key]?.isSelected == true {
                result.append(key)
            }
        }
        updateClosure?(result)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        buttonDict.values.forEach { $0.isSelected = false }
        containerView.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        buttonDict = [:]
    }
}
