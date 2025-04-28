//
//  BlockViewController.swift
//  Off Day
//
//  Created by zici on 2024/1/2.
//

import UIKit
import SnapKit
import Toast
import ZCCalendar

class BlockViewController: BlockBaseViewController, DisplayHandlerDelegate {
    static let monthTagElementKind: String = "monthTagElementKind"
    
    // UI
    
    private var weekdayOrderView: WeekdayOrderView!
    
    // UIBarButtonItem
    
    private var publicPlanButton: UIBarButtonItem?
    
    private var moreButton: UIBarButtonItem?

    // Data
    
    internal var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    
    private var customDays: [CustomDay] = [] {
        didSet {
            customDaysDict = [:]
            for customDay in customDays {
                customDaysDict[Int(customDay.dayIndex)] = customDay
            }
            applyData()
        }
    }
    
    private var customDaysDict: [Int : CustomDay] = [:]
    
    // Handler
    
    private var displayHandler: DisplayHandler!
    
    private var didScrollToday: Bool = false {
        willSet {
            if didScrollToday == false, newValue == true {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) { [weak self] in
                    guard let self = self else { return }
                    self.scrollToToday()
                }
            }
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        displayHandler = DayDisplayHandler(delegate: self)
        
        tabBarItem = UITabBarItem(title: String(localized: "controller.calendar.title"), image: UIImage(systemName: "calendar"), tag: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("BlockViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        updateNavigationBarStyle(hideShadow: true)
        weekdayOrderView = WeekdayOrderView(itemCount: 7, itemWidth: DayGrid.itemWidth(in: view.frame.width), interSpacing: DayGrid.interSpacing)
        weekdayOrderView.backgroundColor = AppColor.navigationBar
        view.addSubview(weekdayOrderView)
        weekdayOrderView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(18)
        }
        updateNavigationTitleView()
        
        configureHierarchy()
        configureDataSource()
        
        addGestures()
        
        let publicPlanButton = UIBarButtonItem(image: UIImage(systemName: "calendar.badge.checkmark"), style: .plain, target: self, action: #selector(showPublicPlanPicker))
        navigationItem.leftBarButtonItem = publicPlanButton
        self.publicPlanButton = publicPlanButton
        
        moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: nil)
        updateMoreMenu()
        if let moreButton = moreButton {
            navigationItem.rightBarButtonItem = moreButton
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .TodayUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .SettingsUpdate, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func tap(in indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch item {
        case .invisible, .month:
            break
        case .block(let blockItem):
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: blockItem)
        }
    }
    
    override func hover(in indexPath: IndexPath) {
        super.hover(in: indexPath)
        guard let blockItem = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch blockItem {
        case .invisible, .month:
            break
        case .block(let blockItem):
            let style = ToastStyle.getStyle(messageColor: blockItem.foregroundColor, backgroundColor: blockItem.backgroundColor)
            view.makeToast(blockItem.calendarString, position: .top, style: style)
        }
    }
    
    private func tap(in targetView: UIView, for blockItem: BlockItem) {
        let detailViewController = BlockDetailViewController(blockItem: blockItem)
        showPopoverView(at: targetView, contentViewController: detailViewController)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] index, environment in
            guard let self = self else {
                return nil
            }
            return self.sectionProvider(index: index, environment: environment)
        }, configuration: config)
        return layout
    }
    
    private func configureDataSource() {
        let monthCellRegistration = getMonthSectionCellRegistration()
        let blockCellRegistration = getBlockCellRegistration()
        let invisibleCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { (cell, indexPath, identifier) in
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            // Return the cell.
            guard let self = self else { return nil }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .month:
                switch identifier {
                case .block:
                    fatalError("Wrong Identifier")
                case .month:
                    return collectionView.dequeueConfiguredReusableCell(using: monthCellRegistration, for: indexPath, item: identifier)
                case .invisible:
                    return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
                }
            case .row:
                switch identifier {
                case .month:
                    fatalError("Wrong Identifier")
                case .block:
                    return collectionView.dequeueConfiguredReusableCell(using: blockCellRegistration, for: indexPath, item: identifier)
                case .invisible:
                    return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
                }
            }
        }
    }
    
    private func configureHierarchy() {
        collectionView = UIDraggableCollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = AppColor.background
        collectionView.delaysContentTouches = false
        collectionView.canCancelContentTouches = true
        collectionView.scrollsToTop = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayOrderView.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: CGFloat.leastNormalMagnitude, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView.contentInset = .init(top: 0.0, left: 0.0, bottom: 10.0, right: 0.0)
    }

    @objc
    internal func reloadData() {
        let startWeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
        weekdayOrderView.startWeekdayOrder = startWeekdayOrder
        let leading = displayHandler.getLeading()
        let trailing = displayHandler.getTrailing()
        CustomDayManager.shared.fetchAllBetween(start: leading, end: trailing) { [weak self] customDays in
            guard let self = self else { return }
            self.customDays = customDays
        }
        self.updateNavigationTitleView()
        
        publicPlanButton?.image = getPublicPlanIndicator()
        publicPlanButton?.accessibilityLabel = String(localized: "controller.publicDay.title")
        publicPlanButton?.accessibilityValue = getPublicPlanName()
    }
    
    private func applyData() {
        if let snapshot = displayHandler.getSnapshot(customDaysDict: customDaysDict) {
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                guard let self = self, !self.didScrollToday else { return }
                self.didScrollToday = true
            }
            self.updateVisibleItems()
        }
        updateMoreMenu()
    }
    
    internal func getPublicPlanIndicator(defaultColor: UIColor = .white) -> UIImage? {
        if PublicPlanManager.shared.dataSource?.plan == nil {
            return UIImage(systemName: "calendar.badge.exclamationmark")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.systemPink, defaultColor]))
        } else {
            return UIImage(systemName: "calendar.badge.checkmark")
        }
    }
    
    internal func getCatalogueMenu(publicPlanName: String) -> UIMenu? {
        var children = displayHandler.getCatalogueMenuElements()
        let pickerAction = UIAction(title: String(localized: "controller.publicDay.title"), subtitle: publicPlanName, image: getPublicPlanIndicator(defaultColor: AppColor.text)) { [weak self] _ in
            guard let self = self else { return }
            self.showPublicPlanPicker()
        }
        let divider = UIMenu(title: "", options: .displayInline, children: [pickerAction])
        children.append(divider)
        
        return UIMenu(children: children)
    }
    
    func scrollToToday() {
        let item = dataSource.snapshot().itemIdentifiers.first { item in
            switch item {
            case .month, .invisible:
                return false
            case .block(let blockItem):
                if blockItem.day == ZCCalendar.manager.today {
                    return true
                } else {
                    return false
                }
            }
        }
        if let item = item, let indexPath = dataSource.indexPath(for: item) {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        }
    }
    
    private func updateMoreMenu() {
        var children: [UIMenuElement] = [getWeekStartTypeMenu(), getWeekEndColorMenu()]
        
        if PublicPlanManager.shared.hasHolidayShift() {
            children.append(getHolidayWorkColorMenu())
        }
        
        let batchEditorAction = UIAction(title: String(localized: "controller.calendar.batchEditor"), image: UIImage(systemName: "pencil")) { [weak self] _ in
            let batchEditor = BatchEditorViewController()
            let nav = NavigationController(rootViewController: batchEditor)
            self?.navigationController?.present(nav, animated: true)
        }
        let editDivider = UIMenu(options: . displayInline, children: [batchEditorAction])

        children.append(editDivider)
        
        moreButton?.menu = UIMenu(title: "", options: .displayInline, children: children)
    }
    
    @objc
    func showPublicPlanPicker() {
        let publicPlanViewController = PublicPlanViewController()
        let nav = NavigationController(rootViewController: publicPlanViewController)
        
        navigationController?.present(nav, animated: true)
    }
    
    private func getPublicPlanName() -> String {
        let publicPlanName: String
        if let publicPlan = PublicPlanManager.shared.dataSource?.plan {
            switch publicPlan {
            case .app(let appPublicPlan):
                publicPlanName = appPublicPlan.title
            case .custom(let customPublicPlan):
                publicPlanName = customPublicPlan.name
            }
        } else {
            publicPlanName = String(localized: "controller.calendar.noPublicPlan")
        }
        return publicPlanName
    }
    
    private func updateNavigationTitleView() {
        let publicPlanName = getPublicPlanName()
        navigationItem.setTitle(displayHandler.getTitle(), subtitle: publicPlanName, menu: getCatalogueMenu(publicPlanName: publicPlanName))
    }
}

extension UINavigationItem {
    func setTitle(_ title: String, subtitle: String, menu: UIMenu?) {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = title
        configuration.subtitle = subtitle
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .headline)
            
            return outgoing
        })
        configuration.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .caption2)
            
            return outgoing
        })
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        button.menu = menu
        titleView = button
    }
}
