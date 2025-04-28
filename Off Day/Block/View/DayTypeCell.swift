//
//  DayTypeCell.swift
//  Off Day
//
//  Created by Ci Zi on 28/4/25.
//

import UIKit
import SnapKit

fileprivate extension UIConfigurationStateCustomKey {
    static let dayTypeItem = UIConfigurationStateCustomKey("com.zizicici.offday.cell.dayType.item")
}

private extension UICellConfigurationState {
    var dayTypeItem: DayType? {
        set { self[.dayTypeItem] = newValue }
        get { return self[.dayTypeItem] as? DayType }
    }
}

class DayTypeBaseCell: UITableViewCell {
    private var dayTypeItem: DayType? = nil
    
    func update(with newDayType: DayType?) {
        guard dayTypeItem != newDayType else { return }
        dayTypeItem = newDayType
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.dayTypeItem = self.dayTypeItem
        return state
    }
}

class DayTypeCell: DayTypeBaseCell {
    private func defaultListContentConfiguration() -> UIListContentConfiguration { return .valueCell() }
    private lazy var listContentView = UIListContentView(configuration: defaultListContentConfiguration())
    
    var tapButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        
        let button = UIButton(configuration: configuration)

        return button
    }()
    
    var valueButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Test"
        configuration.imagePadding = 10.0
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        configuration.image = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: config)
        configuration.imagePlacement = .trailing
        configuration.contentInsets = .zero
        configuration.baseForegroundColor = .secondaryLabel
        
        let button = UIButton(configuration: configuration)
        button.isAccessibilityElement = false

        return button
    }()
    
    func setupViewsIfNeeded() {
        guard tapButton.superview == nil else {
            return
        }
        
        contentView.addSubview(listContentView)
        listContentView.snp.makeConstraints { make in
            make.leading.top.bottom.trailing.equalTo(contentView)
        }
        
        contentView.addSubview(valueButton)
        valueButton.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).inset(12)
        }
        
        contentView.addSubview(tapButton)
        tapButton.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        tapButton.showsMenuAsPrimaryAction = true
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        content.text = String(localized: "dayType.title")
        listContentView.configuration = content
        valueButton.setTitle(state.dayTypeItem?.title ?? String(localized: "dayType.none"), for: .normal)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
