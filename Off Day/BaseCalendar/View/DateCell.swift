//
//  DateCell.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import UIKit
import SnapKit
import ZCCalendar

struct DateCellItem: Hashable {
    var title: String
    var nanoSecondsFrom1970: Int64?
    var date: GregorianDay?
}

extension UIConfigurationStateCustomKey {
    static let dateItem = UIConfigurationStateCustomKey("com.zizicici.zzz.cell.date.item")
}

extension UICellConfigurationState {
    var dateItem: DateCellItem? {
        set { self[.dateItem] = newValue }
        get { return self[.dateItem] as? DateCellItem }
    }
}

class DateBaseCell: UITableViewCell {
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

class DateCell: DateBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var selectDateAction: ((Date) -> ())?
    
    var datePicker: UIDatePicker?
    
    func setupViewsIfNeeded() {
        guard listContentView.superview == nil else {
            return
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
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(contentView)
            make.trailing.equalTo(datePicker.snp.leading)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        if let dateItem = state.dateItem, let day: GregorianDay = dateItem.date {
            content.text = dateItem.title
            listContentView.configuration = content
            
            datePicker?.date = day.generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) ?? Date()
            
            let text: String
            datePicker?.isHidden = false
            text = day.formatString() ?? ""

            accessibilityLabel = dateItem.title + ":" + text
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}

class TimeCell: DateBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var selectDateAction: ((Int64) -> ())?
    
    var datePicker: UIDatePicker?
    
    func setupViewsIfNeeded() {
        guard listContentView.superview == nil else {
            return
        }
        
        let datePicker = UIDatePicker(frame: CGRect.zero, primaryAction: UIAction(handler: { [weak self] _ in
            if let date = self?.datePicker?.date {
                self?.selectDateAction?(date.nanoSecondSince1970)
            }
        }))
        datePicker.datePickerMode = .time
        datePicker.tintColor = AppColor.offDay
        contentView.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).inset(16)
            make.centerY.equalTo(contentView)
        }
        self.datePicker = datePicker
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(contentView)
            make.trailing.equalTo(datePicker.snp.leading)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        if let dateItem = state.dateItem {
            content.text = dateItem.title
            listContentView.configuration = content
            
            if let nanoSecondsFrom1970 = dateItem.nanoSecondsFrom1970 {
                datePicker?.date = Date(nanoSecondSince1970: nanoSecondsFrom1970)
            } else {
                datePicker?.date = Date(nanoSecondSince1970: 0)
            }
            
            datePicker?.isHidden = false
            let text: String = datePicker?.date.formatted(date: .omitted, time: .standard) ?? ""

            accessibilityLabel = dateItem.title + ":" + text
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
