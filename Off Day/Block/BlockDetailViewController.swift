//
//  BlockDetailViewController.swift
//  Off Day
//
//  Created by zici on 2023/12/27.
//

import UIKit
import SnapKit

class BlockDetailViewController: UIViewController {
    private var blockItem: BlockItem!
    
    private var dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.textAlignment = .center
        label.minimumScaleFactor = 0.25
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        
        return label
    }()
    
    private var headView: UIView = {
        let view = UIView()
        
        return view
    }()
    
    private var customLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .label
        label.textAlignment = .natural
        label.minimumScaleFactor = 0.25
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.text = String(localized: "detail.custom")
        
        return label
    }()
    
    private var workDayButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .body)

            return outgoing
        })
        configuration.title = String(localized: "detail.day.work.title")
        
        let button = UIButton(configuration: configuration)
        button.tintColor = .workDay
        
        return button
    }()
    
    private var offDayButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .body)

            return outgoing
        })
        configuration.title = String(localized: "detail.day.off.title")
        
        let button = UIButton(configuration: configuration)
        button.tintColor = .offDay
        
        return button
    }()
    
    convenience init(blockItem: BlockItem) {
        self.init(nibName: nil, bundle: nil)
        self.blockItem = blockItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
        
        view.addSubview(headView)
        headView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(headView.safeAreaLayoutGuide.snp.top).offset(50.0)
        }
        headView.backgroundColor = blockItem.calendarColor
        
        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(12.0)
            make.top.bottom.equalTo(headView.safeAreaLayoutGuide).inset(6.0)
        }
        
        view.addSubview(customLabel)
        customLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(14.0)
            make.top.equalTo(headView.snp.bottom).offset(6.0)
        }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10.0
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(12.0)
            make.top.equalTo(customLabel.snp.bottom).offset(6.0)
        }
        
        stackView.addArrangedSubview(offDayButton)
        stackView.addArrangedSubview(workDayButton)
        
        var suffix = ""
        if let name = blockItem.publicDay?.name {
            suffix = "\n\(name)"
        }
        dateLabel.text = (blockItem.day.completeFormatString() ?? "") + suffix
        
        updateDateLabelColor()
    }
    
    func updateDateLabelColor() {
        switch (headView.backgroundColor?.isLight ?? false, UIColor.text.isLight) {
        case (true, true):
            dateLabel.textColor = .text.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        case (false, true):
            dateLabel.textColor = .text
        case (false, false):
            dateLabel.textColor = .text.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        case (true, false):
            dateLabel.textColor = .text
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDateLabelColor()
    }
}
