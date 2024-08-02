//
//  CalendarTitleView.swift
//  Off Day
//
//  Created by zici on 2/8/24.
//

import UIKit
import SnapKit

class CalendarTitleView: UICollectionReusableView {
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 5.0
        
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self).inset(4)
            make.bottom.equalTo(self).inset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func update(text: String, at index: Int, spilt count: Int, color: UIColor, textAlignment: NSTextAlignment = .center) {
        stackView.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        
        for i in 0..<count {
            let label = UILabel()
            label.textAlignment = textAlignment
            label.font = UIFont.preferredSystemFont(for: .subheadline, weight: .medium)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            if i == index {
                label.text = text
            } else {
                label.text = ""
            }
            label.textColor = color
            stackView.addArrangedSubview(label)
        }
    }
}
