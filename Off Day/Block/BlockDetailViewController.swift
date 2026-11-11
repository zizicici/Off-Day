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
    
    private var dateLabel: CalendarThemeHeaderLabel = {
        let label = CalendarThemeHeaderLabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = AppColor.text
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
        label.textColor = AppColor.text.withAlphaComponent(0.8)
        label.textAlignment = .natural
        label.minimumScaleFactor = 0.25
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.text = String(localized: "detail.custom")
        
        return label
    }()
    
    private let workDayButton = CalendarMarkButton(isOffDay: false)
    private let offDayButton = CalendarMarkButton(isOffDay: true)
    private let headerTexture = CalendarDayTextureView()
    private let markStackView = UIStackView()

    private var commentButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .footnote)

            return outgoing
        })
        configuration.image = UIImage(systemName: "plus.bubble", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16.0, weight: .medium))
        
        let button = UIButton(configuration: configuration)
        button.tintColor = AppColor.text.withAlphaComponent(0.8)
        button.accessibilityHint = String(localized: "detail.comment.hint")
        
        return button
    }()

    private var commentLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = AppColor.text.withAlphaComponent(0.8)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 1
        
        return label
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
            make.top.equalTo(view.safeAreaLayoutGuide).inset(14.0)
        }
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        dateLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        view.insertSubview(headView, belowSubview: dateLabel)
        headView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view)
            make.bottom.equalTo(dateLabel).offset(14.0)
        }
        headView.addSubview(headerTexture)
        headerTexture.isUserInteractionEnabled = false
        headerTexture.snp.makeConstraints { $0.edges.equalTo(headView) }
        
        view.addSubview(customLabel)
        customLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(18.0)
            make.top.equalTo(headView.snp.bottom).offset(12.0)
        }
        customLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        customLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        let stackView = markStackView
        stackView.axis = .horizontal
        stackView.spacing = 12.0
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(customLabel.snp.bottom).offset(12.0)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(12.0)
        }
        
        stackView.addArrangedSubview(offDayButton)
        stackView.addArrangedSubview(workDayButton)
        stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        stackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        let separator = UIView()
        separator.backgroundColor = AppColor.separator
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(12.0)
            make.centerX.equalTo(stackView)
            make.height.equalTo(0.5)
            make.width.equalTo(200)
        }
        
        view.addSubview(commentButton)
        commentButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(20.0)
            make.width.equalTo(44.0)
            make.height.equalTo(44.0)
            make.trailing.equalTo(view).inset(ConsideringUser.buttonShapesEnabled ? 12.0 : 6.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12.0)
        }
        
        view.addSubview(commentLabel)
        commentLabel.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(20.0)
            make.leading.equalTo(stackView).inset(6.0)
            make.trailing.equalTo(commentButton.snp.leading).offset(-6.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12.0)
        }
        
        dateLabel.text = blockItem.calendarString
        
        updateDateLabelColor()

        commentButton.configurationUpdateHandler = { [weak self] button in
            guard let self = self else { return }
            var config = button.configuration
            
            if self.blockItem.customDayInfo.customComment == nil {
                config?.image = UIImage(systemName: "plus.bubble", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14.0, weight: .medium))
                button.accessibilityLabel = String(localized: "comment.add")
            } else {
                if #available(iOS 18.0, *) {
                    config?.image = UIImage(systemName: "bubble.and.pencil", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14.0, weight: .medium))
                } else {
                    config?.image = UIImage(systemName: "text.bubble", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14.0, weight: .medium))
                }
                button.accessibilityLabel = String(localized: "comment.edit")
            }
            
            button.configuration = config
        }
        
        updateUI()
        
        workDayButton.addTarget(self, action: #selector(workDayButtonAction), for: .touchUpInside)
        offDayButton.addTarget(self, action: #selector(offDayButtonAction), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(commentButtonAction), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppearance), name: .SettingsUpdate, object: nil)
    }
    
    var customDayType: DayType? {
        get {
            return blockItem.customDayInfo.customDay?.dayType
        }
    }
    
    func updateDateLabelColor() {
        updateAppearance()
    }

    @objc
    private func updateAppearance() {
        guard isViewLoaded else { return }
        let theme = AppTheme.current
        let colors = theme.colors(for: traitCollection)
        let background = UIColor(colors.background(for: blockItem.appearance)).resolvedColor(with: traitCollection)
        view.backgroundColor = AppColor.background
        headView.backgroundColor = background
        headerTexture.update(appearance: blockItem.appearance, colors: colors)
        dateLabel.textColor = UIColor(colors.foreground(for: blockItem.appearance)).resolvedColor(with: traitCollection)
        dateLabel.inkBackingColor = colors.usesInkBacking(for: blockItem.appearance) ? background : nil
        updatePopoverAppearance()
        markStackView.distribution = theme.usesPatterns ? .fillEqually : .fill
        markStackView.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        updateButtons()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDateLabelColor()
    }

    func updatePopoverAppearance() {
        // An explicit opaque backdrop lets UIKit extend the content into the
        // arrow and clip the header to the same outline as the popover itself.
        guard let popover = popoverPresentationController else { return }
        let background: UIColor? = AppTheme.current.usesPatterns ? AppColor.background : nil
        if popover.backgroundColor != background { popover.backgroundColor = background }
    }
    
    @objc
    func workDayButtonAction() {
        updateMarkFromButton(isOffDay: false)
    }
    
    @objc
    func offDayButtonAction() {
        updateMarkFromButton(isOffDay: true)
    }

    private func updateMarkFromButton(isOffDay: Bool) {
        let next = CalendarDayMarkInteraction.nextValue(current: customDayType.map { $0 == .offDay }, tapped: isOffDay)
        let targetDayType: DayType? = next.map { $0 ? .offDay : .workDay }
        if UIAccessibility.isVoiceOverRunning {
            commit(dayType: targetDayType)
        } else {
            dateTypeDebounce.emit(value: targetDayType)
        }
    }
    
    @objc
    func reloadData() {
        let dayIndex = blockItem.day.julianDay
        blockItem.customDayInfo = CustomDayManager.shared.fetchCustomDayInfo(by: dayIndex)
        updateUI()
    }
    
    func updateUI() {
        updateButtons()
        commentLabel.text = blockItem.customDayInfo.customComment?.content
        if let commentContent = commentLabel.text, commentContent.count > 0 {
            commentLabel.accessibilityLabel = String(format: String(localized: "comment.%@"), commentContent)
        } else {
            commentLabel.accessibilityLabel = ""
        }
    }
    
    func updateButtons() {
        offDayButton.isSelected = customDayType == .offDay
        workDayButton.isSelected = customDayType == .workDay
        offDayButton.setNeedsUpdateConfiguration()
        workDayButton.setNeedsUpdateConfiguration()
        commentButton.setNeedsUpdateConfiguration()
    }
    
    func commit(dayType: DayType?) {
        CustomDayManager.shared.update(dayType: dayType, to: blockItem.day.julianDay)
    }
}

extension BlockDetailViewController {
    @objc
    func commentButtonAction() {
        let editorViewController = DayEditorViewController(comment: blockItem.customDayInfo.customComment ?? CustomComment(dayIndex: Int64(blockItem.day.julianDay), content: ""))
        let nav = NavigationController(rootViewController: editorViewController)
        present(nav, animated: ConsideringUser.animated)
    }
}
