//
//  PublicPlanViewController.swift
//  Off Day
//
//  Created by zici on 3/5/24.
//

import UIKit
import SnapKit
import ZCCalendar

class PublicPlanViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    private var selectedItem: Item?
        
    enum Section: Hashable {
        case top
        case cn
        case hk
        case mo
        case sg
        case jp
        case us
        case th
        case kr
        
        var header: String? {
            return nil
        }
        
        var footer: String? {
            return nil
        }
    }
    
    enum Item: Hashable {
        case empty
        case create
        case appPlan(AppPublicPlan)
        case customPlan(CustomPublicPlan)
        
        var title: String {
            switch self {
            case .empty:
                return String(localized: "publicDay.item.special.empty")
            case .create:
                return String(localized: "publicDay.item.special.create")
            case .appPlan(let plan):
                return plan.title
            case .customPlan(let plan):
                return plan.name
            }
        }
        
        var subtitle: String? {
            switch self {
            case .empty:
                return nil
            case .create:
                return nil
            case .appPlan(let plan):
                return plan.subtitle
            case .customPlan:
                return nil
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(localized: "controller.publicDay.title")
        updateNavigationBarStyle()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "controller.publicDay.cancel"), style: .plain, target: self, action: #selector(cancelAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: String(localized: "controller.publicDay.confirm"), style: .plain, target: self, action: #selector(confirmAction))
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    deinit {
        print("PublicPlanViewController is deinited")
    }
    
    func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.separatorConfiguration = UIListSeparatorConfiguration(listAppearance: .insetGrouped)
            configuration.backgroundColor = AppColor.background
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    func configureDataSource() {
        let listCellRegistration = createListCellRegistration()
        let normalCellRegistration = createNormalCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
            case .create:
                return collectionView.dequeueConfiguredReusableCell(using: normalCellRegistration, for: indexPath, item: itemIdentifier)
            case .appPlan:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
            case .customPlan:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
            }
        })
    }
    
    func createListCellRegistration() -> UICollectionView.CellRegistration<PublicPlanCell, Item> {
        return UICollectionView.CellRegistration<PublicPlanCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            switch item {
            case .empty:
                var content = UIListContentConfiguration.valueCell()
                content.text = item.title
                var layoutMargins = content.directionalLayoutMargins
                layoutMargins.leading = 10.0
                content.directionalLayoutMargins = layoutMargins
                cell.contentConfiguration = content
                cell.detail = nil
            case .create:
                return
            case .appPlan, .customPlan:
                var content = UIListContentConfiguration.subtitleCell()
                content.text = item.title
                content.secondaryText = item.subtitle
                content.textToSecondaryTextVerticalPadding = 6.0
                content.secondaryTextProperties.color = AppColor.text.withAlphaComponent(0.75)
                var layoutMargins = content.directionalLayoutMargins
                layoutMargins.leading = 10.0
                layoutMargins.top = 10.0
                layoutMargins.bottom = 10.0
                content.directionalLayoutMargins = layoutMargins
                cell.contentConfiguration = content
                cell.detail = self.detailAccessoryForListCellItem(item)
            }
        }
    }
    
    func createNormalCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var content = UIListContentConfiguration.valueCell()
            content.text = item.title
            content.textProperties.alignment = .center
            content.textProperties.color = AppColor.offDay
            var layoutMargins = content.directionalLayoutMargins
            layoutMargins.leading = 0.0
            content.directionalLayoutMargins = layoutMargins
            cell.contentConfiguration = content
        }
    }
    
    func detailAccessoryForListCellItem(_ item: Item) -> UICellAccessory {
        return UICellAccessory.detail(options: UICellAccessory.DetailOptions(tintColor: AppColor.offDay), actionHandler: { [weak self] in
            self?.goToDetail(for: item)
        })
    }
    
    func goToDetail(for item: Item) {
        switch item {
        case .empty:
            break
        case .create:
            break
        case .appPlan(let plan):
            if let detailViewController = PublicPlanDetailViewController(appPlan: plan) {
                let nav = NavigationController(rootViewController: detailViewController)
                navigationController?.present(nav, animated: true)
            }
        case .customPlan(let plan):
            if let detailViewController = PublicPlanDetailViewController(customPlan: plan, allowEditing: true) {
                let nav = NavigationController(rootViewController: detailViewController)
                navigationController?.present(nav, animated: true)
            }
        }
    }
    
    func createCustomTemplate(prefill: PublicPlanInfo) {
        let editorViewController = PublicPlanDetailViewController(publicPlan: prefill, allowEditing: true)
        let nav = NavigationController(rootViewController: editorViewController)
        
        navigationController?.present(nav, animated: true)
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.top])
        var topItems: [Item] = [.empty]
        if let customPlans = try? PublicPlanManager.shared.fetchAllPublicPlan() {
            for customPlan in customPlans {
                topItems.append(.customPlan(customPlan))
            }
        }
        topItems.append(.create)
        snapshot.appendItems(topItems, toSection: .top)
        
        snapshot.appendSections([.cn])
        snapshot.appendItems([.appPlan(.cn), .appPlan(.cn_xj), .appPlan(.cn_xz), .appPlan(.cn_gx), .appPlan(.cn_nx)], toSection: .cn)
        
        snapshot.appendSections([.hk])
        snapshot.appendItems([.appPlan(.hk)], toSection: .hk)
        
        snapshot.appendSections([.mo])
        snapshot.appendItems([.appPlan(.mo_public), .appPlan(.mo_force), .appPlan(.mo_cs)], toSection: .mo)
        
        snapshot.appendSections([.sg])
        snapshot.appendItems([.appPlan(.sg)], toSection: .sg)
        
        snapshot.appendSections([.th])
        snapshot.appendItems([.appPlan(.th)], toSection: .th)
        
        snapshot.appendSections([.kr])
        snapshot.appendItems([.appPlan(.kr)], toSection: .kr)
        
        snapshot.appendSections([.jp])
        snapshot.appendItems([.appPlan(.jp)], toSection: .jp)
        
        snapshot.appendSections([.us])
        snapshot.appendItems([.appPlan(.us)], toSection: .us)
        
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.updateSelection()
        }
    }
    
    func updateSelection() {
        if let publicPlan = PublicPlanManager.shared.dataSource?.plan {
            switch publicPlan {
            case .app(let plan):
                if let index = dataSource.indexPath(for: .appPlan(plan)) {
                    selectedItem = .appPlan(plan)
                    collectionView.selectItem(at: index, animated: true, scrollPosition: .centeredHorizontally)
                }
            case .custom(let plan):
                if let index = dataSource.indexPath(for: .customPlan(plan)) {
                    selectedItem = .customPlan(plan)
                    collectionView.selectItem(at: index, animated: true, scrollPosition: .centeredHorizontally)
                }
            }
        }
        if selectedItem == nil {
            if let index = dataSource.indexPath(for: .empty) {
                selectedItem = .empty
                collectionView.selectItem(at: index, animated: true, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    @objc
    func cancelAction() {
        dismiss(animated: true)
    }
    
    @objc
    func confirmAction() {
        guard let selectedItem = selectedItem else {
            return
        }
        switch selectedItem {
        case .empty:
            PublicPlanManager.shared.select(plan: nil)
        case .create:
            return
        case .appPlan(let plan):
            PublicPlanManager.shared.select(plan: .app(plan))
        case .customPlan(let plan):
            PublicPlanManager.shared.select(plan: .custom(plan))
        }
        dismiss(animated: true)
    }
}

extension PublicPlanViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            selectedItem = item
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .empty:
                return true
            case .create:
                let day = GregorianDay(year: ZCCalendar.manager.today.year, month: .jan, day: 1)
                let publicPlanInfo = PublicPlanInfo(plan: .custom(CustomPublicPlan(name: String(localized: "publicDetail.title.new"))), days: [day.julianDay : CustomPublicDay(name: String(localized: "publicDetail.newYear.name"), date: day, type: .offDay)])
                createCustomTemplate(prefill: publicPlanInfo)
                return false
            case .appPlan, .customPlan:
                return true
            }
        } else {
            return false
        }
    }
}
