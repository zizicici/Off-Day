//
//  PublicPlanViewController.swift
//  Off Day
//
//  Created by zici on 3/5/24.
//

import UIKit
import SnapKit

class PublicPlanViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    private var selectedItem: Item?
        
    enum Section: Hashable {
        case special
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
        case plan(PublicDayManager.PublicPlan)
        
        var title: String {
            switch self {
            case .empty:
                return String(localized: "publicDay.item.special.empty")
            case .plan(let plan):
                return plan.title
            }
        }
        
        var subtitle: String {
            switch self {
            case .empty:
                return String(localized: "publicDay.item.special.empty")
            case .plan(let plan):
                return plan.subtitle
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
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) { [weak self] in
            self?.updateSelection()
        }
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
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
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
            default:
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
    
    func detailAccessoryForListCellItem(_ item: Item) -> UICellAccessory {
        return UICellAccessory.detail(options: UICellAccessory.DetailOptions(tintColor: AppColor.offDay), actionHandler: { [weak self] in
            self?.goToDetail(for: item)
        })
    }
    
    func goToDetail(for item: Item) {
        switch item {
        case .empty:
            break
        case .plan(let publicPlan):
            let detailViewController = PublicPlanDetailViewController(publicPlan: publicPlan)
            let nav = UINavigationController(rootViewController: detailViewController)
            
            navigationController?.present(nav, animated: true)
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.special])
        snapshot.appendItems([.empty], toSection: .special)
        
        snapshot.appendSections([.cn])
        snapshot.appendItems([.plan(.cn), .plan(.cn_xj), .plan(.cn_xz), .plan(.cn_gx), .plan(.cn_nx)], toSection: .cn)
        
        snapshot.appendSections([.hk])
        snapshot.appendItems([.plan(.hk)], toSection: .hk)
        
        snapshot.appendSections([.mo])
        snapshot.appendItems([.plan(.mo_public), .plan(.mo_force), .plan(.mo_cs)], toSection: .mo)
        
        snapshot.appendSections([.sg])
        snapshot.appendItems([.plan(.sg)], toSection: .sg)
        
        snapshot.appendSections([.th])
        snapshot.appendItems([.plan(.th)], toSection: .th)
        
        snapshot.appendSections([.kr])
        snapshot.appendItems([.plan(.kr)], toSection: .kr)
        
        snapshot.appendSections([.jp])
        snapshot.appendItems([.plan(.jp)], toSection: .jp)
        
        snapshot.appendSections([.us])
        snapshot.appendItems([.plan(.us)], toSection: .us)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func updateSelection() {
        if let plan = PublicDayManager.shared.publicPlan, let index = dataSource.indexPath(for: .plan(plan)) {
            selectedItem = .plan(plan)
            collectionView.selectItem(at: index, animated: true, scrollPosition: .centeredHorizontally)
        } else {
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
            PublicDayManager.shared.publicPlan = nil
        case .plan(let publicPlan):
            PublicDayManager.shared.publicPlan = publicPlan
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
}

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
