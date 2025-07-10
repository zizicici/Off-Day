//
//  DatePickerCell.swift
//  Off Day
//
//  Created by zici on 12/5/24.
//

import UIKit
import SnapKit
import ZCCalendar

class DatePickerBaseCell: UICollectionViewListCell {
    private var dateItem: DateCellItem? = nil
    
    func update(with newDate: DateCellItem) {
        guard dateItem != newDate else { return }
        dateItem = newDate
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.dateItem = self.dateItem
        return state
    }
}

class DatePickerCell: DatePickerBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var selectDateAction: ((Date) -> ())?
    
    var datePicker: UIDatePicker?
    
    func setupViewsIfNeeded() {
        guard listContentView.superview == nil else {
            return
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.top.bottom.trailing.equalTo(contentView)
        }
        
        let datePicker = UIDatePicker(frame: CGRect.zero, primaryAction: UIAction(handler: { [weak self] _ in
            if let date = self?.datePicker?.date {
                self?.selectDateAction?(date)
            }
        }))
        datePicker.datePickerMode = .date
        datePicker.tintColor = .systemRed
        contentView.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).inset(16)
            make.centerY.equalTo(contentView)
        }
        self.datePicker = datePicker
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        
        var content = defaultListContentConfiguration().updated(for: state)
        if let dateItem = state.dateItem, let day: GregorianDay = dateItem.day {
            content.text = dateItem.title
            listContentView.configuration = content
            
            datePicker?.date = day.generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) ?? Date()
            
            let text: String
            datePicker?.isHidden = false
            text = day.formatString() ?? ""

            accessibilityLabel = (dateItem.title ?? "") + ":" + text
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
