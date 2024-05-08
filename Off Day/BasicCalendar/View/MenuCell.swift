//
//  MenuCell.swift
//  Off Day
//
//  Created by zici on 2023/12/29.
//

import UIKit
import SnapKit

struct MenuCellItem: Hashable {
    var title: String
    var value: String
}

fileprivate extension UIConfigurationStateCustomKey {
    static let menuItem = UIConfigurationStateCustomKey("com.zizicici.offday.cell.menu.item")
}

private extension UICellConfigurationState {
    var menuItem: MenuCellItem? {
        set { self[.menuItem] = newValue }
        get { return self[.menuItem] as? MenuCellItem }
    }
}

class MenuBaseCell: UITableViewCell {
    private var menuItem: MenuCellItem? = nil
    
    func update(with newMenuItem: MenuCellItem?) {
        guard menuItem != newMenuItem else { return }
        menuItem = newMenuItem
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.menuItem = self.menuItem
        return state
    }
}

class MenuCell: MenuBaseCell {
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
            make.top.trailing.bottom.equalTo(contentView)
            make.leading.equalTo(contentView.snp.centerX)
        }
        tapButton.showsMenuAsPrimaryAction = true
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()
        var content = defaultListContentConfiguration().updated(for: state)
        content.text = state.menuItem?.title
        listContentView.configuration = content
        valueButton.setTitle(state.menuItem?.value ?? "", for: .normal)
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
