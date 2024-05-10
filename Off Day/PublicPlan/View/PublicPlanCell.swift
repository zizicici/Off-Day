//
//  PublicPlanCell.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import UIKit
import SnapKit

class PublicPlanCell: UICollectionViewListCell {
    var detail: UICellAccessory?
    
    var customBackgroundView: UIView = {
        let view = UIView()
        
        view.backgroundColor = .secondarySystemGroupedBackground
        
        return view
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        detail = nil
    }
    
    private func setupViewsIfNeeded() {
        guard customBackgroundView.superview == nil else { return }
        
        contentView.addSubview(customBackgroundView)
        contentView.sendSubviewToBack(customBackgroundView)
        customBackgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        setupViewsIfNeeded()

        if state.isSelected {
            let checkmark = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)))
            accessories = [detail, .customView(configuration: .init(customView: checkmark, placement: .leading(), reservedLayoutWidth: .custom(12), tintColor: AppColor.offDay))].compactMap{ $0 }
        } else {
            accessories = [detail, (.customView(configuration: .init(customView: UIView(), placement: .leading(), reservedLayoutWidth: .custom(12), tintColor: AppColor.offDay)))].compactMap{ $0 }
        }
        if state.isHighlighted {
            if state.isSelected {
                customBackgroundView.alpha = 1.0
                customBackgroundView.backgroundColor = .systemGray4
            } else {
                customBackgroundView.alpha = 0.0
                customBackgroundView.backgroundColor = .secondarySystemGroupedBackground
            }
        } else {
            customBackgroundView.alpha = 1.0
            customBackgroundView.backgroundColor = .secondarySystemGroupedBackground
        }
        
        backgroundConfiguration = PublicPlanCellBackgroundConfiguration.configuration(for: state)
    }
}

struct PublicPlanCellBackgroundConfiguration {
    static func configuration(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.listGroupedCell()
        if state.isSelected {
            background.backgroundColor = .clear
        }
        return background
    }
}

