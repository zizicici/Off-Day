//
//  PublicPlanDetailViewController.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import UIKit
import SnapKit
import ZCCalendar

class PublicPlanDetailViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var publicPlanInfo: PublicPlanInfo?
    private var mode: Mode = .viewer
    private var titleButton: UIButton?
    
    enum Mode {
        case viewer
        case editor
    }

    enum Section: Hashable {
        case year(Int)
        case add
        case delete
    }
    
    enum Item: Hashable {
        static func == (lhs: Item, rhs: Item) -> Bool {
            switch (lhs, rhs) {
            case (.add, .add):
                return true
            case (.dayInfo(let lhsDay), .dayInfo(let rhsDay)):
                return lhsDay.isEqual(rhsDay)
            default:
                return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .add:
                hasher.combine("add")
            case .dayInfo(let day):
                day.hash(into: &hasher)
            case .delete:
                hasher.combine("delete")
            }
        }
        
        case dayInfo(any PublicDay)
        case add
        case delete
    }
    
    convenience init(publicPlan: PublicPlanInfo, allowEditing: Bool = false) {
        self.init(nibName: nil, bundle: nil)
        self.publicPlanInfo = publicPlan
        if allowEditing {
            mode = .editor
        } else {
            mode = .viewer
        }
    }
    
    convenience init?(appPlan: AppPublicPlan, allowEditing: Bool = false) {
        if let detail = AppPublicPlan.Detail(plan: appPlan), let publicPlanInfo = PublicPlanInfo(detail: detail) {
            self.init(nibName: nil, bundle: nil)
            self.publicPlanInfo = publicPlanInfo
            if allowEditing {
                mode = .editor
            } else {
                mode = .viewer
            }
        } else {
            return nil
        }
    }
    
    convenience init?(customPlan: CustomPublicPlan, allowEditing: Bool = false) {
        guard let id = customPlan.id else { return nil }
        if let detail = try? PublicPlanManager.shared.fetchCustomPublicPlan(with: id) {
            self.init(nibName: nil, bundle: nil)
            self.publicPlanInfo = PublicPlanInfo(detail: detail)
            if allowEditing {
                mode = .editor
            } else {
                mode = .viewer
            }
        } else {
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateNavigationBarStyle()
        
        switch mode {
        case .viewer:
            title = publicPlanInfo?.name
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "publicDetail.close.title"), style: .plain, target: self, action: #selector(dismissAction))
            let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: nil)
            let action = UIAction(title: String(localized: "publicDetail.create.title"), image: UIImage(systemName: "pencil.and.list.clipboard")) { [weak self] _ in
                guard let self = self else { return }
                self.duplicateTemplate()
            }
            moreButton.menu = UIMenu(title: "", children: [action])
            navigationItem.rightBarButtonItem = moreButton
        case .editor:
            setupTitleButton()
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "publicDetail.cancel.title"), style: .plain, target: self, action: #selector(dismissAction))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: String(localized: "publicDetail.save.title"), style: .plain, target: self, action: #selector(saveAction))
        }
        
        configureHierarchy()
        configureDataSource()
        reloadData()
    }
    
    deinit {
        print("PublicPlanDetailViewController is deinited")
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
            case .add:
                var content = UIListContentConfiguration.cell()
                content.text = String(localized: "publicDetail.button.new")
                content.textProperties.color = AppColor.offDay
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
            case .delete:
                var content = UIListContentConfiguration.cell()
                content.text = String(localized: "publicDetail.button.delete")
                content.textProperties.color = .systemRed
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
            }
        }
    }
    
    @objc
    func reloadData() {
        guard let publicPlanInfo = publicPlanInfo else { return }
        let days = Array(publicPlanInfo.days.values)
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
        
        switch mode {
        case .viewer:
            break
        case .editor:
            snapshot.appendSections([.add])
            snapshot.appendItems([.add], toSection: .add)
            
            switch publicPlanInfo.plan {
            case .custom(let plan):
                if plan.id != nil {
                    snapshot.appendSections([.delete])
                    snapshot.appendItems([.delete], toSection: .delete)
                }
            default:
                break
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func setupTitleButton() {
        if titleButton != nil {
            titleButton?.removeFromSuperview()
            titleButton = nil
        }
        var configuration = UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .headline)

            return outgoing
        })
        configuration.title = self.publicPlanInfo?.name
        configuration.image = UIImage(systemName: "pencil")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 6.0
        
        let button = UIButton(configuration: configuration)
        button.tintColor = .white
        button.addTarget(self, action: #selector(showTitleAlert), for: .touchUpInside)
        titleButton = button
        
        navigationItem.titleView = button
    }
    
    @objc
    func dismissAction() {
        dismiss(animated: true)
    }
    
    func duplicateTemplate() {
        if let nav = presentingViewController as? NavigationController, let root = nav.topViewController as? PublicPlanViewController {
            if let customTemplateInfo = publicPlanInfo?.getDuplicateCustomPlan() {
                dismiss(animated: true) { [weak root] in
                    root?.createCustomTemplate(prefill: customTemplateInfo)
                }
            }
        }
    }
    
    @objc
    func saveAction() {
        switch mode {
        case .viewer:
            break
        case .editor:
            if let planInfo = publicPlanInfo {
                switch planInfo.plan {
                case .app:
                    break
                case .custom(let customPublicPlan):
                    if customPublicPlan.id != nil {
                        let result = PublicPlanManager.shared.update(planInfo)
                        if result {
                            dismissAction()
                        }
                    } else {
                        let result = PublicPlanManager.shared.create(planInfo)
                        if result {
                            dismissAction()
                        }
                    }
                case .none:
                    break
                }
            }
        }
    }
    
    func enterDayDetail(day: CustomPublicDay?) {
        let detailViewController = CustomPublicDayDetailViewController(day: day) { [weak self] publicDay in
            guard let self = self else { return false }
            if let day = day {
                if let newPublicDay = publicDay {
                    return self.update(day, with: newPublicDay)
                } else {
                    return self.delete(day)
                }
            } else {
                if let newPublicDay = publicDay {
                    return self.add(newPublicDay)
                } else {
                    return false
                }
            }
        }
        let nav = NavigationController(rootViewController: detailViewController)
        
        navigationController?.present(nav, animated: true)
    }
    
    func add(_ newDay: CustomPublicDay) -> Bool {
        guard let publicPlanInfo = publicPlanInfo else { return false }
        for day in publicPlanInfo.days.values.compactMap({ $0 }) {
            if day.date == newDay.date {
                return false
            }
        }
        self.publicPlanInfo?.days[newDay.date.julianDay] = newDay
        reloadData()
        return true
    }
    
    func delete(_ oldDay: CustomPublicDay) -> Bool {
        guard publicPlanInfo != nil else { return false }
        self.publicPlanInfo?.days.removeValue(forKey: oldDay.date.julianDay)
        reloadData()
        return true
    }
    
    func update(_ oldDay: CustomPublicDay, with newDay: CustomPublicDay) -> Bool {
        guard let publicPlanInfo = publicPlanInfo else { return false }
        var targetArray = publicPlanInfo.days.values.compactMap({ $0 as? CustomPublicDay })
        targetArray.removeAll { $0 == oldDay }
        for day in targetArray {
            if day.date == newDay.date {
                return false
            }
        }
        targetArray.append(newDay)
        targetArray = targetArray.sorted(by: { $0.date.julianDay < $1.date.julianDay })
        let dict = targetArray.reduce(into: [Int: CustomPublicDay](), { (partialResult, publicDay) in
            partialResult[publicDay.date.julianDay] = publicDay
        })
        self.publicPlanInfo?.days = dict
        reloadData()
        return true
    }
    
    @objc
    func showTitleAlert() {
        let alertController = UIAlertController(title: String(localized: "publicDetail.alert.title"), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicDetail.alert.cancel"), style: .cancel) { _ in
            //
        }
        let okAction = UIAlertAction(title: String(localized: "publicDetail.alert.confirm"), style: .default) { [weak self] _ in
            if let text = alertController.textFields?.first?.text {
                self?.publicPlanInfo?.name = text
                self?.setupTitleButton()
            }
        }
        okAction.isEnabled = publicPlanInfo?.name.count ?? 0 > 0
        alertController.addTextField { [weak self] textField in
            textField.placeholder = ""
            textField.text = self?.publicPlanInfo?.name
            textField.addTarget(alertController, action: #selector(alertController.textDidChangeInTitle), for: .editingChanged)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showDeleteAlert() {
        let alertController = UIAlertController(title: String(localized: "publicPlan.alert.delete.title"), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicPlan.alert.delete.cancel"), style: .cancel) { _ in
            //
        }
        let deleteAction = UIAlertAction(title: String(localized: "publicPlan.alert.delete.confirm"), style: .destructive) { [weak self] _ in
            self?.deleteAction()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteAction() {
        guard let publicPlanInfo = publicPlanInfo else { return }
        dismiss(animated: true) {
            _ = PublicPlanManager.shared.delete(publicPlanInfo)
        }
    }
}

extension PublicPlanDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .dayInfo(let publicDay):
                if self.mode == .editor {
                    if let publicDay = publicDay as? CustomPublicDay {
                        enterDayDetail(day: publicDay)
                    }
                }
            case .add:
                enterDayDetail(day: nil)
            case .delete:
                if publicPlanInfo != nil {
                    showDeleteAlert()
                }
            }
        }
    }
}

extension UIAlertController {
    @objc
    func textDidChangeInTitle() {
        if let title = textFields?[0].text, let action = actions.last {
            action.isEnabled = title.count > 0
        }
    }
}
