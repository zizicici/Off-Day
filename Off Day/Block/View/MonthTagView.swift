//
//  MonthTagView.swift
//  Off Day
//
//  Created by zici on 2023/12/26.
//

import UIKit
import SnapKit

class MonthTagView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .label.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(2.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MonthCell: UICollectionViewCell {
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        label.textColor = .label.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSpecialColor() {
        titleLabel.textColor = .systemRed
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = .label.withAlphaComponent(0.8)
    }
}
