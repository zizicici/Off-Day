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
        
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.workDay
        
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
        
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.offDay
        
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
        
        view.addSubview(headView)
        headView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(headView.safeAreaLayoutGuide.snp.top).offset(50.0)
        }
        headView.backgroundColor = blockItem.backgroundColor
        
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
        
        dateLabel.text = blockItem.calendarString
        
        updateDateLabelColor()

        workDayButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            
            switch self.customDayType {
            case .offDay:
                config?.image = nil
            case .workDay:
                config?.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12.0))
            case nil:
                config?.image = nil
            }
            
            button.configuration = config
        }
        
        offDayButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            
            switch self.customDayType {
            case .offDay:
                config?.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12.0))
            case .workDay:
                config?.image = nil
            case nil:
                config?.image = nil
            }
            
            button.configuration = config
        }
        
        updateButtons()
        
        workDayButton.addTarget(self, action: #selector(workDayButtonAction), for: .touchUpInside)
        offDayButton.addTarget(self, action: #selector(offDayButtonAction), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    var customDayType: DayType? {
        return blockItem.customDay?.dayType
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
        switch customDayType {
        case .offDay:
            dateTypeDebounce.emit(value: .workDay)
        case .workDay:
            dateTypeDebounce.emit(value: nil)
        case nil:
            dateTypeDebounce.emit(value: .workDay)
        }
    }
    
    @objc
    func offDayButtonAction() {
        switch customDayType {
        case .offDay:
            dateTypeDebounce.emit(value: nil)
        case .workDay:
            dateTypeDebounce.emit(value: .offDay)
        case nil:
            dateTypeDebounce.emit(value: .offDay)
        }
    }
    
    @objc
    func reloadData() {
        blockItem.customDay = CustomDayManager.shared.fetchCustomDay(by: blockItem.day.julianDay)
        updateButtons()
    }
    
    func updateButtons() {
        offDayButton.setNeedsUpdateConfiguration()
        workDayButton.setNeedsUpdateConfiguration()
    }
    
    func commit(dayType: DayType?) {
        if let dayType = dayType {
            if var customDay = CustomDayManager.shared.fetchCustomDay(by: blockItem.day.julianDay) {
                if customDay.dayType != dayType{
                    customDay.dayType = dayType
                    CustomDayManager.shared.update(customDay: customDay)
                }
            } else {
                let customDay = CustomDay(dayIndex: Int64(blockItem.day.julianDay), dayType: dayType)
                CustomDayManager.shared.add(customDay: customDay)
            }
        } else {
            if let customDay = CustomDayManager.shared.fetchCustomDay(by: blockItem.day.julianDay) {
                CustomDayManager.shared.delete(customDay: customDay)
            } else {
                //
            }
        }
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

final class Debounce<T> {
    private let block: @Sendable (T) async -> Void
    private let duration: Double
    private var task: Task<Void, Never>?
    
    init(
        duration: Double,
        block: @Sendable @escaping (T) async -> Void
    ) {
        self.duration = duration
        self.block = block
    }
    
    func emit(value: T) {
        self.task?.cancel()
        self.task = Task { [duration, block] in
            do {
                if #available(iOS 16.0, *) {
                    try await Task.sleep(for: .seconds(duration))
                } else {
                    try await Task.sleep(seconds: duration)
                }
                await block(value)
            } catch {}
        }
    }
}
