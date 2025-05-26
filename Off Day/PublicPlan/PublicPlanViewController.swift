//
//  PublicPlanViewController.swift
//  Off Day
//
//  Created by zici on 3/5/24.
//

import UIKit
import SnapKit
import ZCCalendar
import UniformTypeIdentifiers
import Toast

class PublicPlanViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    private var selectedItem: Item?
    
    private var publicPlanType: PublicPlanType? {
        didSet {
            reloadData()
        }
    }
    
    // Picker: Remote
    //
    // Remote URL lists (Swipe To Share, Tap Edit, (update), (i))
    // Add URL
    //
    // Network Permission
    //
    // Notification Permission
    
    enum InnerRegion: Hashable, CaseIterable {
        case cn
        case hk
        case mo
        case sg
        case th
        case kr
        case jp
        case us
        
        var files: [AppPublicPlan.File] {
            switch self {
            case .cn:
                return [.cn, .cn_xj, .cn_xz, .cn_gx, .cn_nx]
            case .hk:
                return [.hk]
            case .mo:
                return [.mo_public, .mo_force, .mo_cs]
            case .sg:
                return [.sg]
            case .th:
                return [.th]
            case .kr:
                return [.kr]
            case .jp:
                return [.jp]
            case .us:
                return [.us]
            }
        }
    }
    
    enum Section: Hashable {
        case picker
        case manual
        case inner(InnerRegion)
        
        var header: String? {
            return nil
        }
        
        var footer: String? {
            return nil
        }
    }
    
    enum Item: Hashable {
        case picker(PublicPlanType?)
        case create
        case importPlan
        case appPlan(AppPublicPlan)
        case customPlan(CustomPublicPlan)
        
        var title: String {
            switch self {
            case .picker:
                return String(localized: "publicPlan.type.title")
            case .create:
                return String(localized: "publicPlan.item.special.create")
            case .importPlan:
                return String(localized: "publicPlan.item.special.import")
            case .appPlan(let plan):
                return plan.title
            case .customPlan(let plan):
                return plan.name
            }
        }
        
        var subtitle: String? {
            switch self {
            case .picker:
                return nil
            case .create:
                return nil
            case .importPlan:
                return nil
            case .appPlan(let plan):
                return plan.subtitle
            case .customPlan(let plan):
                return "\(plan.start.formatString() ?? "") - \(plan.end.formatString() ?? "")"
            }
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.publicPlanType = currentPublicPlanType()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] (indexPath) in
                guard let self = self else { return nil }
                guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
                return self.trailingSwipeActionConfigurationForListCellItem(item)
            }
            configuration.itemSeparatorHandler = { [weak self] (indexPath, sectionSeparatorConfiguration) in
                guard let self = self else { return sectionSeparatorConfiguration }
                guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return sectionSeparatorConfiguration }
                if let createIndex = self.dataSource.indexPath(for: .create) {
                    if indexPath == createIndex, createIndex.row == 0 {
                        var configuration = sectionSeparatorConfiguration
                        configuration.topSeparatorVisibility = .hidden
                        configuration.bottomSeparatorVisibility = .hidden
                        return configuration
                    }
                    if (indexPath.section == createIndex.section) && (indexPath.row + 1 == createIndex.row) {
                        var configuration = sectionSeparatorConfiguration
                        configuration.bottomSeparatorVisibility = .hidden
                        return configuration
                    }
                }
                switch item {
                case .picker, .appPlan,.customPlan:
                    return sectionSeparatorConfiguration
                case .create, .importPlan:
                    var configuration = sectionSeparatorConfiguration
                    configuration.topSeparatorVisibility = .visible
                    configuration.topSeparatorInsets = .zero
                    configuration.bottomSeparatorVisibility = .hidden
                    return configuration
                }
            }
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
        let optionCellRegistration = createOptionCellRegistration()
        let listCellRegistration = createListCellRegistration()
        let normalCellRegistration = createNormalCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .picker:
                return collectionView.dequeueConfiguredReusableCell(using: optionCellRegistration, for: indexPath, item: itemIdentifier)
            case .create, .importPlan:
                return collectionView.dequeueConfiguredReusableCell(using: normalCellRegistration, for: indexPath, item: itemIdentifier)
            case .appPlan:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
            case .customPlan:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
            }
        })
    }
    
    func createOptionCellRegistration() -> UICollectionView.CellRegistration<OptionCell<PublicPlanType>, Item> {
        return UICollectionView.CellRegistration<OptionCell<PublicPlanType>, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            switch item {
            case .picker(let templateOption):
                cell.update(with: templateOption)
                let noneAction = UIAction(title: PublicPlanType.noneTitle, state: templateOption == nil ? .on : .off) { [weak self] _ in
                    self?.publicPlanType = nil
                }
                let actions = [PublicPlanType.local, PublicPlanType.remote].map { target in
                    let action = UIAction(title: target.title, subtitle: target.subtitle, state: templateOption == target ? .on : .off) { [weak self] _ in
                        self?.publicPlanType = target
                    }
                    return action
                }
                let divider = UIMenu(title: "", options: . displayInline, children: actions)
                let menu = UIMenu(children: [noneAction, divider])
                cell.tapButton.menu = menu
            default:
                return
            }
        }
    }
    
    func createListCellRegistration() -> UICollectionView.CellRegistration<PublicPlanCell, Item> {
        return UICollectionView.CellRegistration<PublicPlanCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            switch item {
            case .picker:
                return
            case .create, .importPlan:
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
            cell.contentConfiguration = content
        }
    }
    
    func trailingSwipeActionConfigurationForListCellItem(_ item: Item) -> UISwipeActionsConfiguration? {
        switch item {
        case .picker:
            return nil
        case .create:
            return nil
        case .importPlan:
            return nil
        case .appPlan:
            return nil
        case .customPlan(let customPublicPlan):
            let shareAction = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completion) in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                self.sharePlan(customPlan: customPublicPlan)
                
                completion(true)
            }
            shareAction.title = String(localized: "publicPlan.share.title")
            shareAction.backgroundColor = AppColor.offDay
            return UISwipeActionsConfiguration(actions: [shareAction])
        }

    }
    
    func detailAccessoryForListCellItem(_ item: Item) -> UICellAccessory {
        return UICellAccessory.detail(options: UICellAccessory.DetailOptions(tintColor: AppColor.offDay), actionHandler: { [weak self] in
            self?.goToDetail(for: item)
        })
    }
    
    func goToDetail(for item: Item) {
        switch item {
        case .picker:
            break
        case .create, .importPlan:
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
    
    func currentPublicPlanType() -> PublicPlanType? {
        switch PublicPlanManager.shared.dataSource?.plan {
        case .none:
            return nil
        case .app:
            return .local
        case .custom:
            return .local
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        snapshot.appendSections([.picker])
        snapshot.appendItems([.picker(publicPlanType)], toSection: .picker)
        
        switch publicPlanType {
        case .local:
            snapshot.appendSections([.manual])
            var topItems: [Item] = []
            if let customPlans = try? PublicPlanManager.shared.fetchAllPublicPlan() {
                for customPlan in customPlans {
                    topItems.append(.customPlan(customPlan))
                }
            }
            topItems.append(.create)
            topItems.append(.importPlan)
            snapshot.appendItems(topItems, toSection: .manual)
            
            for innerRegion in InnerRegion.allCases {
                snapshot.appendSections([.inner(innerRegion)])
                snapshot.appendItems(innerRegion.files.map { .appPlan(AppPublicPlan(file: $0)) }, toSection: .inner(innerRegion))
            }
        case .remote:
            break
        case nil:
            break
        }
        
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.updateSelection()
        }
    }
    
    func updateSelection() {
        var needUseManagerDataSource: Bool = false
        if let selectedItem = selectedItem {
            if dataSource.indexPath(for: selectedItem) == nil {
                needUseManagerDataSource = true
                self.selectedItem = nil
            }
        } else {
            needUseManagerDataSource = true
        }
        if needUseManagerDataSource {
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
        }
    }
    
    @objc
    func cancelAction() {
        dismiss(animated: true)
    }
    
    @objc
    func confirmAction() {
        switch publicPlanType {
        case .local:
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .picker, .create, .importPlan:
                    break
                case .appPlan(let plan):
                    PublicPlanManager.shared.select(plan: .app(plan))
                case .customPlan(let plan):
                    PublicPlanManager.shared.select(plan: .custom(plan))
                }
            }
        case .remote:
            break
        case nil:
            PublicPlanManager.shared.select(plan: nil)
        }
        dismiss(animated: true)
    }
    
    func createTemplate() {
        let firstDay = GregorianDay(year: ZCCalendar.manager.today.year, month: .jan, day: 1)
        let lastDay = GregorianDay(year: ZCCalendar.manager.today.year, month: .dec, day: 31)
        let publicPlanInfo = PublicPlanInfo(plan: .custom(CustomPublicPlan(name: String(localized: "publicDetail.title.new"), start: firstDay, end: lastDay)), days: [firstDay.julianDay : CustomPublicDay(name: String(localized: "publicDetail.newYear.name"), date: firstDay, type: .offDay)])
        createCustomTemplate(prefill: publicPlanInfo)
    }
    
    func importPlanAction() {
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPickerViewController.allowsMultipleSelection = false
        documentPickerViewController.shouldShowFileExtensions = true
        documentPickerViewController.delegate = self
        present(documentPickerViewController, animated: true)
    }
    
    func importPlan(from url: URL) {
        let result = PublicPlanManager.shared.importPlan(from: url)
        let style = ToastStyle.getStyle(messageColor: .white, backgroundColor: AppColor.offDay)
        view.makeToast(
            result ? String(localized: "publicDetail.import.success") : String(localized: "publicDetail.import.failure"), position: .center, style: style)
    }
    
    func sharePlan(customPlan: CustomPublicPlan) {
        if let url = PublicPlanManager.shared.exportCustomPlanToFile(from: customPlan) {
            showActivityController(url: url)
        }
    }
    
    func showActivityController(url: URL) {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            // Drop exported file
            do {
                try FileManager.default.removeItem(at: url)
            }
            catch {
                print(error)
            }
        }
        
        present(controller, animated: true)
    }
    
    func showDateErrorAlert() {
        let alertController = UIAlertController(title: String(localized: "publicPlan.alert.dateError.title"), message: String(localized: "publicPlan.alert.dateError.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicPlan.alert.dateError.cancel"), style: .cancel) { _ in
            //
        }

        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
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
            case .picker:
                return false
            case .create:
                createTemplate()
                return false
            case .importPlan:
                importPlanAction()
                return false
            case .appPlan:
                return true
            case .customPlan(let customPlan):
                if customPlan.start.julianDay <= customPlan.end.julianDay {
                    return true
                } else {
                    showDateErrorAlert()
                    return false
                }
            }
        } else {
            return false
        }
    }
}

extension PublicPlanViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        // Start accessing a security-scoped resource.
        guard url.startAccessingSecurityScopedResource() else {
            // Handle the failure here.
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let pickedURL = urls.first else {
            return
        }
        
        let coordinator = NSFileCoordinator()
        
        coordinator.coordinate(readingItemAt: pickedURL, options: [], error: nil) { [weak self] (url) in
            self?.importPlan(from: url)
            pickedURL.stopAccessingSecurityScopedResource()
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("documentPickerWasCancelled")
    }
}
