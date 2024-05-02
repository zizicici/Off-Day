//
//  TitleCell.swift
//  Off Day
//
//  Created by zici on 2023/12/25.
//

import UIKit
import SnapKit

struct TitleInfoCellItem: Hashable {
    var catalogue: Catalogue
}

fileprivate extension UIConfigurationStateCustomKey {
    static let titleInfoItem = UIConfigurationStateCustomKey("com.zizicici.off-day.cell.book.info.item")
}

private extension UICellConfigurationState {
    var titleInfoItem: TitleInfoCellItem? {
        set { self[.titleInfoItem] = newValue }
        get { return self[.titleInfoItem] as? TitleInfoCellItem }
    }
}

class TitleBaseCell: UICollectionViewCell {
    private var titleInfoItem: TitleInfoCellItem? = nil

    func update(with newBookInfo: TitleInfoCellItem) {
        guard titleInfoItem != newBookInfo else { return }
        titleInfoItem = newBookInfo
        setNeedsUpdateConfiguration()
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.titleInfoItem = self.titleInfoItem
        return state
    }
}


class TitleCell: TitleBaseCell {
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption2)
        label.textColor = .label.withAlphaComponent(0.75)
        label.minimumScaleFactor = 0.25
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        
        return label
    }()
    
    private var indexButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .body)

            return outgoing
        })
        
        let button = UIButton(configuration: configuration)
        button.tintColor = .offDay
        button.showsMenuAsPrimaryAction = true
        
        return button
    }()
    
    private func setupViewsIfNeeded() {
        guard titleLabel.superview == nil else { return }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView).inset(32)
            make.width.lessThanOrEqualTo(contentView).offset(-64)
            make.height.greaterThanOrEqualTo(0)
            make.height.lessThanOrEqualTo(300)
        }
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        contentView.addSubview(indexButton)
        indexButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(contentView).inset(30)
            make.bottom.equalTo(contentView)
            make.height.greaterThanOrEqualTo(0)
        }
        indexButton.setContentHuggingPriority(.required, for: .vertical)
        indexButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        setupViewsIfNeeded()
        if let bookInfoCellItem = state.titleInfoItem {
            switch bookInfoCellItem.catalogue {
            case .targetYear(let year):
                titleLabel.text = String(localized: "calendar.title.hint")
                let text = String(format: (String(localized: "calendar.title.year%i")), year)
                indexButton.setTitle(text, for: .normal)
            }
        }
    }
    
    public func setup(menu: UIMenu?) {
        indexButton.menu = menu
    }
}
