//
//  OptionCell.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/26.
//

import UIKit
import SnapKit

protocol OptionItem: Hashable, Equatable {
    static var noneTitle: String { get }
    static var sectionTitle: String { get }
    
    var title: String { get }
    var subtitle: String? { get }
}

enum PublicPlanType: OptionItem {
    case local
    case remote
    
    static var noneTitle = String(localized: "publicPlan.type.none")
    static var sectionTitle = String(localized: "publicPlan.type.title")
    
    var title: String {
        switch self {
        case .local:
            String(localized: "publicPlan.type.local.title")
        case .remote:
            String(localized: "publicPlan.type.remote.title")
        }
    }
    
    var subtitle: String? {
        switch self {
        case .local:
            return nil
        case .remote:
            return String(localized: "publicPlan.type.remote.subtitle")
        }
    }
}

fileprivate extension UIConfigurationStateCustomKey {
    static let optionItem = UIConfigurationStateCustomKey("com.zizicici.zzz.cell.option.item")
}

private extension UICellConfigurationState {
    var optionItem: (any OptionItem)? {
        set { self[.optionItem] = newValue as? AnyHashable }
        get { return self[.optionItem] as? (any OptionItem) }
    }
}

class OptionBaseCell<T: OptionItem>: UICollectionViewCell {
    private var optionItem: T? = nil
    
    func update(with newOption: T?) {
        guard optionItem != newOption else { return }
        optionItem = newOption
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.optionItem = self.optionItem
        return state
    }
}

class OptionCell<T: OptionItem>: OptionBaseCell<T> {
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
    
    var defaultSectionTitle: String { T.sectionTitle }
    var defaultNoneTitle: String { T.noneTitle }
    
    func setupViewsIfNeeded() {
        guard tapButton.superview == nil else { return }
        
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
        content.text = defaultSectionTitle
        listContentView.configuration = content
        
        if let optionItem = state.optionItem as? T {
            valueButton.setTitle(optionItem.title, for: .normal)
        } else {
            valueButton.setTitle(defaultNoneTitle, for: .normal)
        }
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        
        if #available(iOS 18.0, *) {
            backgroundConfiguration = UIBackgroundConfiguration.listCell()
        } else {
            backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
        }
    }
}
