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
    
    private var dateTypeDebounce: Debounce<DayType?>!
    
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
        label.textColor = .label.withAlphaComponent(0.8)
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
        configuration.imagePadding = 4.0
        configuration.contentInsets.leading = 0
        configuration.contentInsets.trailing = 0
        
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.workDay
        button.accessibilityHint = String(localized: "detail.day.work.hint")
        
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
        configuration.imagePadding = 4.0
        configuration.contentInsets.leading = 0
        configuration.contentInsets.trailing = 0
        
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.offDay
        button.accessibilityHint = String(localized: "detail.day.off.hint")
        
        return button
    }()
    
    convenience init(blockItem: BlockItem) {
        self.init(nibName: nil, bundle: nil)
        self.blockItem = blockItem
        dateTypeDebounce = Debounce(duration: 0.25, block: { [weak self] value in
            await self?.commit(dayType: value)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(12.0)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(12.0)
        }
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        dateLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        view.insertSubview(headView, belowSubview: dateLabel)
        headView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(dateLabel).offset(12.0)
        }
        headView.backgroundColor = blockItem.backgroundColor
        
        view.addSubview(customLabel)
        customLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(14.0)
            make.top.equalTo(headView.snp.bottom).offset(12.0)
        }
        customLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        customLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10.0
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(12.0)
            make.top.equalTo(customLabel.snp.bottom).offset(8.0)
        }
        
        stackView.addArrangedSubview(offDayButton)
        stackView.addArrangedSubview(workDayButton)
        stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        stackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        dateLabel.text = blockItem.calendarString
        
        updateDateLabelColor()

        workDayButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            
            var isSelected: Bool = false
            switch self.customDayType {
            case .offDay:
                config?.image = nil
            case .workDay:
                isSelected = true
                config?.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(textStyle: .footnote))
            case nil:
                config?.image = nil
            }
            
            button.configuration = config
            button.isSelected = isSelected
        }
        
        offDayButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            
            var isSelected: Bool = false
            switch self.customDayType {
            case .offDay:
                isSelected = true
                config?.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(textStyle: .footnote))
            case .workDay:
                config?.image = nil
            case nil:
                config?.image = nil
            }
            
            button.configuration = config
            button.isSelected = isSelected
        }
        
        updateButtons()
        
        workDayButton.addTarget(self, action: #selector(workDayButtonAction), for: .touchUpInside)
        offDayButton.addTarget(self, action: #selector(offDayButtonAction), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    var customDayType: DayType? {
        return blockItem.customDayType
    }
    
    func updateDateLabelColor() {
        dateLabel.textColor = blockItem.foregroundColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDateLabelColor()
    }
    
    @objc
    func workDayButtonAction() {
        let targetDayType: DayType?
        switch customDayType {
        case .offDay:
            targetDayType = .workDay
        case .workDay:
            targetDayType = nil
        case nil:
            targetDayType = .workDay
        }
        if UIAccessibility.isVoiceOverRunning {
            commit(dayType: targetDayType)
        } else {
            dateTypeDebounce.emit(value: targetDayType)
        }
    }
    
    @objc
    func offDayButtonAction() {
        let targetDayType: DayType?
        switch customDayType {
        case .offDay:
            targetDayType = nil
        case .workDay:
            targetDayType = .offDay
        case nil:
            targetDayType = .offDay
        }
        if UIAccessibility.isVoiceOverRunning {
            commit(dayType: targetDayType)
        } else {
            dateTypeDebounce.emit(value: targetDayType)
        }
    }
    
    @objc
    func reloadData() {
        blockItem.customDayType = CustomDayManager.shared.fetchCustomDay(by: blockItem.day.julianDay)?.dayType
        updateButtons()
    }
    
    func updateButtons() {
        offDayButton.setNeedsUpdateConfiguration()
        workDayButton.setNeedsUpdateConfiguration()
    }
    
    func commit(dayType: DayType?) {
        CustomDayManager.shared.update(dayType: dayType, to: blockItem.day.julianDay)
    }
}
