//
//  MonthTitleCell.swift
//  Off Day
//
//  Created by zici on 2/8/24.
//

import UIKit
import SnapKit

struct MonthItem: Hashable {
    var text: String
    var color: UIColor
}

fileprivate extension UIConfigurationStateCustomKey {
    static let monthItem = UIConfigurationStateCustomKey("com.zizicici.zzz.cell.month.item")
}

private extension UICellConfigurationState {
    var monthItem: MonthItem? {
        set { self[.monthItem] = newValue }
        get { return self[.monthItem] as? MonthItem }
    }
}

class MonthTitleBaseCell: UICollectionViewCell {
    private var monthItem: MonthItem? = nil
    
    func update(with newMonthItem: MonthItem) {
        guard monthItem != newMonthItem else { return }
        monthItem = newMonthItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.monthItem = self.monthItem
        return state
    }
}

class MonthTitleCell: MonthTitleBaseCell {
    let monthLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    private func setupViewsIfNeeded() {
        guard monthLabel.superview == nil else { return }
        
        self.addSubview(monthLabel)
        monthLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self).inset(4)
            make.bottom.equalTo(self).inset(4)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        
        if let monthItem = state.monthItem {
            monthLabel.text = monthItem.text
            monthLabel.textColor = monthItem.color
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        monthLabel.text = nil
    }
}
