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
        updateNavigationBarStyle()
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
        case .info, .tag, .invisible:
            break
        case .block(let blockItem):
            impactFeedbackGeneratorCoourred()
            tap(in: cell, for: blockItem)
        }
    }
    
    func filter(customDays: [CustomDay], from startIndex: Int, to endIndex: Int) -> [CustomDay] {
        return customDays.filter({ customDay in
            if customDay.dayIndex < startIndex {
                return false
            } else if customDay.dayIndex > endIndex {
                return false
            } else {
                return true
            }
        })
    }
    
    override func hover(in indexPath: IndexPath) {
        super.hover(in: indexPath)
        guard let blockItem = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch blockItem {
        case .info, .tag, .invisible:
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
        let infoCellRegistration = getInfoSectionCellRegistration()
        let blockCellRegistration = getBlockCellRegistration()
        let weekCellRegistration = getWeekCellRegistration()
        let invisibleCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Item> { (cell, indexPath, identifier) in
        }
        let monthTagRegistration = getMonthTagRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Item) -> UICollectionViewCell? in
            // Return the cell.
            guard let self = self else { return nil }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .info:
                return collectionView.dequeueConfiguredReusableCell(using: infoCellRegistration, for: indexPath, item: identifier)
            case .topTag:
                return collectionView.dequeueConfiguredReusableCell(using: weekCellRegistration, for: indexPath, item: identifier)
            case .row:
                switch identifier {
                case .info, .tag:
                    fatalError("Wrong Identifier")
                case .block:
                    return collectionView.dequeueConfiguredReusableCell(using: blockCellRegistration, for: indexPath, item: identifier)
                case .invisible:
                    return collectionView.dequeueConfiguredReusableCell(using: invisibleCellRegistration, for: indexPath, item: identifier)
                }
            }
        }
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, index) in
            guard let self = self else { return nil }
            if kind == Self.monthTagElementKind {
                return self.collectionView.dequeueConfiguredReusableSupplementary(using: monthTagRegistration, for: index)
            } else {
                return nil
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
            make.edges.equalTo(view)
        }
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: CGFloat.leastNormalMagnitude, left: 0.0, bottom: 0.0, right: 0.0)
    }

    @objc
    internal func reloadData() {
        // TODO: Apply Active Handler for reduce request
        CustomDayManager.shared.fetchAll { [weak self] customDays in
            guard let self = self else { return }
            self.customDays = filter(customDays: customDays.sortedByStart(), from: self.displayHandler.getLeading(), to: self.displayHandler.getTrailing())
        }
        self.updateNavigationTitleView()
        
        if PublicDayManager.shared.publicPlan == nil {
            publicPlanButton?.image = UIImage(systemName: "calendar.badge.exclamationmark")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.systemPink, .white]))
        } else {
            publicPlanButton?.image = UIImage(systemName: "calendar.badge.checkmark")
        }
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
    
    internal func getCatalogueMenu() -> UIMenu? {
        let children = displayHandler.getCatalogueMenuElements()
        return UIMenu(children: children)
    }
    
    func scrollToToday() {
        let today = ZCCalendar.manager.today
        collectionView.scrollToItem(at: IndexPath(item: today.day, section: today.month.rawValue + 1), at: .centeredVertically, animated: true)
    }
    
    private func updateMoreMenu() {
        var children: [UIMenuElement] = [getWeekStartTypeMenu(), getWeekEndColorMenu()]
        
        if PublicDayManager.shared.hasHolidayShift() {
            children.append(getHolidayWorkColorMenu())
        }
        
        moreButton?.menu = UIMenu(title: "", options: .displayInline, children: children)
    }
    
    @objc
    func showPublicPlanPicker() {
        let publicPlanViewController = PublicPlanViewController()
        let nav = NavigationController(rootViewController: publicPlanViewController)
        
        navigationController?.present(nav, animated: true)
    }
    
    func updateNavigationTitleView() {
        let publicPlan = PublicDayManager.shared.publicPlan
        let subtitle = (publicPlan == nil) ? String(localized: "controller.calendar.noPublicPlan") : publicPlan!.title
        
        navigationItem.setTitle(String(localized: "controller.calendar.title"), subtitle: subtitle)
    }
}

extension UINavigationItem {
    func setTitle(_ title: String, subtitle: String) {
        let textColor = UIColor.white
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: UIFont.TextStyle.headline)
        titleLabel.textColor = textColor

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: UIFont.TextStyle.caption2)
        subtitleLabel.textColor = textColor

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.layoutSubviews()
               
        self.titleView = stackView
    }
}
