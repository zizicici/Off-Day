//
//  PublicPlanDetailViewController.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import UIKit
import SnapKit

class PublicPlanDetailViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var publicPlanProvider: PublicDayProvider?

    enum Section: Hashable {
        case year(Int)
    }
    
    enum Item: Hashable {
        case dayInfo(PublicDay)
    }
    
    convenience init(publicPlan: PublicDayManager.PublicPlan) {
        self.init(nibName: nil, bundle: nil)
        load(publicPlan: publicPlan)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = publicPlanProvider?.name
        updateNavigationBarStyle()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "publicDetail.close.title"), style: .plain, target: self, action: #selector(dismissAction))
        
        configureHierarchy()
        configureDataSource()
        reloadData()
    }
    
    deinit {
        print("PublicPlanDetailViewController is deinited")
    }
    
    private func load(publicPlan: PublicDayManager.PublicPlan) {
        if let url = Bundle.main.url(forResource: publicPlan.resource, withExtension: "json"), let data = try? Data(contentsOf: url) {
            do {
                publicPlanProvider = try JSONDecoder().decode(PublicDayProvider.self, from: data)
            } catch {
                print("Unexpected error: \(error).")
            }
        }
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
    
    func createListCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] (cell, indexPath, item) in
            guard self != nil else { return }
            switch item {
            case .dayInfo(let item):
                var content = UIListContentConfiguration.valueCell()
                content.text = item.name
                content.secondaryText = item.date.completeFormatString()
                content.textToSecondaryTextVerticalPadding = 6.0
                content.textProperties.color = item.type == .offDay ? AppColor.offDay : AppColor.workDay
                content.textProperties.adjustsFontSizeToFitWidth = true
                content.textProperties.minimumScaleFactor = 0.5
                content.secondaryTextProperties.color = AppColor.text
                content.secondaryTextProperties.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
                content.secondaryTextProperties.adjustsFontSizeToFitWidth = true
                content.secondaryTextProperties.minimumScaleFactor = 0.5
                var layoutMargins = content.directionalLayoutMargins
                layoutMargins.top = 16.0
                layoutMargins.bottom = 16.0
                content.directionalLayoutMargins = layoutMargins
                cell.contentConfiguration = content
            }
        }
    }
    
    @objc
    func reloadData() {
        guard let publicPlanProvider = publicPlanProvider else { return }
        let days = Array(publicPlanProvider.days.values)
        let dicts = Dictionary(grouping: days, by: { $0.date.year })
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        for key in dicts.keys.sorted() {
            snapshot.appendSections([.year(key)])
            if let items = dicts[key]?.sorted(by: { leftItem, rightItem in
                leftItem.date.julianDay < rightItem.date.julianDay
            }).compactMap({ Item.dayInfo($0) }) {
                snapshot.appendItems(items, toSection: .year(key))
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc
    func dismissAction() {
        dismiss(animated: true)
    }
}

extension PublicPlanDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
