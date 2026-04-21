//
//  PublicPlanViewController.swift
//  Off Day
//
//  Created by zici on 3/5/24.
//

import UIKit
import os
import SnapKit
import ZCCalendar
import UniformTypeIdentifiers
import Toast
import MoreKit

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
        case importPlan
        case subscribePlan
        case appPlan(AppPublicPlan)
        case customPlan(CustomPublicPlan)

        var title: String {
            switch self {
            case .empty:
                return String(localized: "publicDay.item.special.empty")
            case .create:
                return String(localized: "publicDay.item.special.create")
            case .importPlan:
                return String(localized: "publicDay.item.special.import")
            case .subscribePlan:
                return String(localized: "publicDay.item.special.subscribe")
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
            case .importPlan:
                return nil
            case .subscribePlan:
                return nil
            case .appPlan(let plan):
                return plan.subtitle
            case .customPlan(let plan):
                let dateRange = "\(plan.start.formatString() ?? "") - \(plan.end.formatString() ?? "")"
                if plan.isPaused == true {
                    return "\(dateRange)\n\(String(localized: "publicPlan.paused.indicator"))"
                } else if plan.sourceURL != nil, let ts = plan.lastRefreshTime, ts > 0 {
                    let date = Date(timeIntervalSince1970: TimeInterval(ts))
                    let formatted = date.formatted(.relative(presentation: .named))
                    return "\(dateRange)\n\(String(format: String(localized: "publicPlan.lastRefresh.indicator"), formatted))"
                }
                return dateRange
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(localized: "controller.publicDay.title")
        updateNavigationBarStyle()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "controller.publicDay.cancel"), style: .plain, target: self, action: #selector(cancelAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: String(localized: "controller.publicDay.confirm"), style: .plain, target: self, action: #selector(confirmAction))
        if #available(iOS 26.0, *) {
            navigationItem.leftBarButtonItem?.hidesSharedBackground = true
            navigationItem.leftBarButtonItem?.tintColor = .white
            navigationItem.rightBarButtonItem?.hidesSharedBackground = true
            navigationItem.rightBarButtonItem?.tintColor = .white
        } else {
            // Fallback on earlier versions
        }
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .SettingsUpdate, object: nil)
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
                    if (indexPath.section == createIndex.section) && (indexPath.row + 1 == createIndex.row) {
                        var configuration = sectionSeparatorConfiguration
                        configuration.bottomSeparatorVisibility = .hidden
                        return configuration
                    }
                }
                switch item {
                case .empty, .appPlan, .customPlan:
                    return sectionSeparatorConfiguration
                case .create, .importPlan, .subscribePlan:
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
        let listCellRegistration = createListCellRegistration()
        let normalCellRegistration = createNormalCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
            case .create, .importPlan, .subscribePlan:
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
            case .create, .importPlan, .subscribePlan:
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
        case .empty:
            return nil
        case .create:
            return nil
        case .importPlan:
            return nil
        case .subscribePlan:
            return nil
        case .appPlan:
            return nil
        case .customPlan(let customPublicPlan):
            if customPublicPlan.sourceURL != nil {
                if customPublicPlan.isPaused == true {
                    let resumeAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                        if let planId = customPublicPlan.id {
                            SubscriptionManager.shared.resumeSubscription(for: planId)
                            completion(true)
                            Task {
                                do {
                                    _ = try await SubscriptionManager.shared.refresh(plan: customPublicPlan, trigger: .manual, ignorePause: true, clearRejected: true)
                                } catch {
                                    Logger.subscription.error("Refresh after resume failed: \(error.localizedDescription)")
                                }
                                SubscriptionManager.shared.presentPendingUpdateAlert(for: planId)
                            }
                        } else {
                            completion(true)
                        }
                    }
                    resumeAction.title = String(localized: "publicPlan.resume.title")
                    resumeAction.backgroundColor = AppColor.offDay

                    return UISwipeActionsConfiguration(actions: [resumeAction])
                } else {
                    let pauseAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                        if let planId = customPublicPlan.id {
                            SubscriptionManager.shared.pauseSubscription(for: planId)
                        }
                        completion(true)
                    }
                    pauseAction.title = String(localized: "publicPlan.pause.title")
                    pauseAction.backgroundColor = .systemOrange

                    let refreshAction = UIContextualAction(style: .normal, title: nil) { (_, _, completion) in
                        Task {
                            do {
                                _ = try await SubscriptionManager.shared.refresh(plan: customPublicPlan, trigger: .manual, clearRejected: true)
                            } catch {
                                Logger.subscription.error("Refresh failed: \(error.localizedDescription)")
                            }
                            if let planId = customPublicPlan.id {
                                SubscriptionManager.shared.presentPendingUpdateAlert(for: planId)
                            }
                            await MainActor.run {
                                completion(true)
                            }
                        }
                    }
                    refreshAction.title = String(localized: "publicPlan.refresh.title")
                    refreshAction.backgroundColor = AppColor.offDay

                    return UISwipeActionsConfiguration(actions: [pauseAction, refreshAction])
                }
            } else {
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
        case .create, .importPlan, .subscribePlan:
            break
        case .appPlan(let plan):
            if let detailViewController = PublicPlanDetailViewController(appPlan: plan) {
                let nav = NavigationController(rootViewController: detailViewController)
                navigationController?.present(nav, animated: ConsideringUser.animated)
            }
        case .customPlan(let plan):
            let allowEditing = plan.sourceURL == nil
            if let detailViewController = PublicPlanDetailViewController(customPlan: plan, allowEditing: allowEditing) {
                let nav = NavigationController(rootViewController: detailViewController)
                navigationController?.present(nav, animated: ConsideringUser.animated)
            }
        }
    }
    
    func createCustomTemplate(prefill: PublicPlanInfo) {
        let editorViewController = PublicPlanDetailViewController(publicPlan: prefill, allowEditing: true)
        let nav = NavigationController(rootViewController: editorViewController)
        
        navigationController?.present(nav, animated: ConsideringUser.animated)
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
        topItems.append(.importPlan)
        topItems.append(.subscribePlan)
        snapshot.appendItems(topItems, toSection: .top)
        
        snapshot.appendSections([.cn])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .cn)), .appPlan(AppPublicPlan(file: .cn_xj)), .appPlan(AppPublicPlan(file: .cn_xz)), .appPlan(AppPublicPlan(file: .cn_gx)), .appPlan(AppPublicPlan(file: .cn_nx)), .appPlan(AppPublicPlan(file: .cn_sc_ls))], toSection: .cn)
        
        snapshot.appendSections([.hk])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .hk))], toSection: .hk)
        
        snapshot.appendSections([.mo])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .mo_public)), .appPlan(AppPublicPlan(file: .mo_force)), .appPlan(AppPublicPlan(file: .mo_cs))], toSection: .mo)
        
        snapshot.appendSections([.sg])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .sg))], toSection: .sg)
        
        snapshot.appendSections([.th])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .th))], toSection: .th)
        
        snapshot.appendSections([.kr])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .kr))], toSection: .kr)
        
        snapshot.appendSections([.jp])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .jp))], toSection: .jp)
        
        snapshot.appendSections([.us])
        snapshot.appendItems([.appPlan(AppPublicPlan(file: .us))], toSection: .us)
        
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
                        collectionView.selectItem(at: index, animated: ConsideringUser.animated, scrollPosition: .centeredHorizontally)
                    }
                case .custom(let plan):
                    if let index = dataSource.indexPath(for: .customPlan(plan)) {
                        selectedItem = .customPlan(plan)
                        collectionView.selectItem(at: index, animated: ConsideringUser.animated, scrollPosition: .centeredHorizontally)
                    }
                }
            }
        }
        if selectedItem == nil {
            if let index = dataSource.indexPath(for: .empty) {
                selectedItem = .empty
                collectionView.selectItem(at: index, animated: ConsideringUser.animated, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    @objc
    func cancelAction() {
        dismiss(animated: ConsideringUser.animated)
    }
    
    @objc
    func confirmAction() {
        guard let selectedItem = selectedItem else {
            return
        }
        switch selectedItem {
        case .empty:
            PublicPlanManager.shared.select(plan: nil)
        case .create, .importPlan, .subscribePlan:
            return
        case .appPlan(let plan):
            PublicPlanManager.shared.select(plan: .app(plan))
        case .customPlan(let plan):
            PublicPlanManager.shared.select(plan: .custom(plan))
        }
        dismiss(animated: ConsideringUser.animated)
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
        present(documentPickerViewController, animated: ConsideringUser.animated)
    }
    
    func importPlan(from url: URL) {
        let result = PublicPlanManager.shared.importPlan(from: url)
        let style = ToastStyle.getStyle(messageColor: .white, backgroundColor: AppColor.offDay)
        view.makeToast(
            result ? String(localized: "publicDetail.import.success") : String(localized: "publicDetail.import.failure"), position: .center, style: style)
    }
    
    func subscribeAction() {
        let alertController = UIAlertController(
            title: String(localized: "publicPlan.subscribe.alert.title"),
            message: String(localized: "publicPlan.subscribe.alert.message"),
            preferredStyle: .alert
        )
        alertController.addTextField { textField in
            textField.placeholder = String(localized: "publicPlan.subscribe.alert.placeholder")
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        let confirmAction = UIAlertAction(title: String(localized: "publicPlan.subscribe.alert.confirm"), style: .default) { [weak self] _ in
            guard let self = self else { return }
            guard let urlString = alertController.textFields?.first?.text, !urlString.isEmpty else { return }
            if SubscriptionManager.shared.isURLAlreadySubscribed(urlString) {
                let duplicateAlert = UIAlertController(
                    title: String(localized: "publicPlan.subscribe.duplicate.title"),
                    message: String(localized: "publicPlan.subscribe.duplicate.message"),
                    preferredStyle: .alert
                )
                duplicateAlert.addAction(UIAlertAction(title: String(localized: "button.ok"), style: .default))
                self.present(duplicateAlert, animated: ConsideringUser.animated)
                return
            }
            Task { [weak self] in
                do {
                    let result = try await SubscriptionManager.shared.subscribe(from: urlString)
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        let style = ToastStyle.getStyle(messageColor: .white, backgroundColor: AppColor.offDay)
                        self.view.makeToast(
                            result ? String(localized: "publicPlan.subscribe.success") : String(localized: "publicPlan.subscribe.failure"),
                            position: .center,
                            style: style
                        )
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        let style = ToastStyle.getStyle(messageColor: .white, backgroundColor: AppColor.offDay)
                        self.view.makeToast(
                            String(localized: "publicPlan.subscribe.failure"),
                            position: .center,
                            style: style
                        )
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: String(localized: "publicPlan.subscribe.alert.cancel"), style: .cancel)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: ConsideringUser.animated)
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
                Logger.publicPlan.error("\(error.localizedDescription)")
            }
        }
        
        present(controller, animated: ConsideringUser.animated)
    }
    
    func showDateErrorAlert() {
        let alertController = UIAlertController(title: String(localized: "publicPlan.alert.dateError.title"), message: String(localized: "publicPlan.alert.dateError.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicPlan.alert.dateError.cancel"), style: .cancel) { _ in
            //
        }

        alertController.addAction(cancelAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
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
                createTemplate()
                return false
            case .importPlan:
                importPlanAction()
                return false
            case .subscribePlan:
                subscribeAction()
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
        
        let coordinator = NSFileCoordinator()
        
        coordinator.coordinate(readingItemAt: url, options: [], error: nil) { [weak self] (coordinatedURL) in
            self?.importPlan(from: coordinatedURL)
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("documentPickerWasCancelled")
    }
}
