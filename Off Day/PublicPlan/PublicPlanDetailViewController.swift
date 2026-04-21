//
//  PublicPlanDetailViewController.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import UIKit
import os
import SnapKit
import ZCCalendar

class PublicPlanDetailViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var publicPlanInfo: PublicPlanInfo?
    var mode: Mode = .viewer
    private var titleButton: UIButton?
    
    enum Mode {
        case viewer
        case editor
        case subscriptionPreview
    }

    enum DeclineAction {
        case skip
        case pause
    }

    var onAccept: (() -> Void)?
    var onDecline: ((DeclineAction) -> Void)?
    var changeEntries: [ChangeEntry] = []

    struct ChangeEntry: Hashable {
        let icon: String
        let text: String
        let color: UIColor

        static func == (lhs: ChangeEntry, rhs: ChangeEntry) -> Bool {
            lhs.icon == rhs.icon && lhs.text == rhs.text
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(icon)
            hasher.combine(text)
        }
    }

    enum Section: Hashable {
        case changes
        case info
        case year(Int)
        case add
        case delete
        case actions
    }
    
    enum Item: Hashable {
        static func == (lhs: Item, rhs: Item) -> Bool {
            switch (lhs, rhs) {
            case (.add, .add):
                return true
            case (.dayInfo(let lhsDay), .dayInfo(let rhsDay)):
                return lhsDay.isEqual(rhsDay)
            case (.start(let lDay), .start(let rDay)):
                return lDay == rDay
            case (.end(let lDay), .end(let rDay)):
                return lDay == rDay
            case (.note(let lNote), .note(let rNote)):
                return lNote == rNote
            case (.changeItem(let lEntry), .changeItem(let rEntry)):
                return lEntry == rEntry
            case (.sourceURL(let l), .sourceURL(let r)):
                return l == r
            case (.lastRefreshTime(let l), .lastRefreshTime(let r)):
                return l == r
            case (.refreshSubscription, .refreshSubscription):
                return true
            case (.pauseSubscription, .pauseSubscription):
                return true
            case (.resumeSubscription, .resumeSubscription):
                return true
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
            case .start(let day):
                day.hash(into: &hasher)
            case .end(let day):
                day.hash(into: &hasher)
            case .note(let note):
                hasher.combine("note")
                hasher.combine(note)
            case .changeItem(let entry):
                hasher.combine("changeItem")
                entry.hash(into: &hasher)
            case .sourceURL(let url):
                hasher.combine("sourceURL")
                hasher.combine(url)
            case .lastRefreshTime(let time):
                hasher.combine("lastRefreshTime")
                hasher.combine(time)
            case .refreshSubscription:
                hasher.combine("refreshSubscription")
            case .pauseSubscription:
                hasher.combine("pauseSubscription")
            case .resumeSubscription:
                hasher.combine("resumeSubscription")
            }
        }

        case start(GregorianDay)
        case end(GregorianDay)
        case note(String?)
        case dayInfo(any PublicDay)
        case add
        case delete
        case changeItem(ChangeEntry)
        case sourceURL(String)
        case lastRefreshTime(Int64)
        case refreshSubscription
        case pauseSubscription
        case resumeSubscription
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
        case .subscriptionPreview:
            title = publicPlanInfo?.name
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "subscription.preview.decline"), style: .plain, target: self, action: #selector(showDeclineAlert))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: String(localized: "subscription.preview.accept"), style: .plain, target: self, action: #selector(acceptAction))
        }
        
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
        let dateCellRegistration = createDateCellRegistration()
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self = self else { return nil }
            switch itemIdentifier {
            case .start, .end:
                switch self.mode {
                case .viewer, .subscriptionPreview:
                    return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
                case .editor:
                    return collectionView.dequeueConfiguredReusableCell(using: dateCellRegistration, for: indexPath, item: itemIdentifier)
                }
            default:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: itemIdentifier)
            }
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
            case .start(let day):
                var content = UIListContentConfiguration.valueCell()
                content.text = String(localized: "publicDetail.start")
                content.secondaryText = day.formatString()
                cell.contentConfiguration = content
            case .end(let day):
                var content = UIListContentConfiguration.valueCell()
                content.text = String(localized: "publicDetail.end")
                content.secondaryText = day.formatString()
                cell.contentConfiguration = content
            case .changeItem(let entry):
                var content = UIListContentConfiguration.cell()
                content.image = UIImage(systemName: entry.icon)
                content.imageProperties.tintColor = entry.color
                content.text = entry.text
                content.textProperties.color = entry.color
                content.textProperties.numberOfLines = 0
                cell.contentConfiguration = content
            case .note(let note):
                var content = UIListContentConfiguration.valueCell()
                content.text = String(localized: "publicDetail.note")
                if let note = note, !note.isEmpty {
                    content.secondaryText = note
                } else {
                    content.secondaryText = String(localized: "publicDetail.note.empty")
                    content.secondaryTextProperties.color = .placeholderText
                }
                content.secondaryTextProperties.numberOfLines = 0
                cell.contentConfiguration = content
            case .sourceURL(let url):
                var content = UIListContentConfiguration.valueCell()
                content.text = String(localized: "publicDetail.sourceURL")
                content.secondaryText = url
                content.secondaryTextProperties.numberOfLines = 0
                content.secondaryTextProperties.color = .secondaryLabel
                cell.contentConfiguration = content
            case .lastRefreshTime(let timestamp):
                var content = UIListContentConfiguration.valueCell()
                content.text = String(localized: "publicDetail.lastRefreshTime")
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                content.secondaryText = date.formatted(.relative(presentation: .named))
                cell.contentConfiguration = content
            case .refreshSubscription:
                var content = UIListContentConfiguration.cell()
                content.text = String(localized: "publicDetail.button.refresh")
                content.textProperties.color = AppColor.offDay
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
            case .pauseSubscription:
                var content = UIListContentConfiguration.cell()
                content.text = String(localized: "publicDetail.button.pause")
                content.textProperties.color = .systemOrange
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
            case .resumeSubscription:
                var content = UIListContentConfiguration.cell()
                content.text = String(localized: "publicDetail.button.resume")
                content.textProperties.color = AppColor.offDay
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
            }
        }
    }
    
    func createDateCellRegistration() -> UICollectionView.CellRegistration<DatePickerCell, Item> {
        return UICollectionView.CellRegistration<DatePickerCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            switch item {
            case .start(let day):
                cell.update(with: DateCellItem(title: String(localized: "publicDetail.start"), day: day))
                cell.selectDateAction = { [weak self] date in
                    guard let self = self else { return }
                    let day = GregorianDay(from: date)
                    self.publicPlanInfo?.start = day
                }
            case .end(let day):
                cell.update(with: DateCellItem(title: String(localized: "publicDetail.end"), day: day))
                cell.selectDateAction = { [weak self] date in
                    guard let self = self else { return }
                    let day = GregorianDay(from: date)
                    self.publicPlanInfo?.end = day
                }
            default:
                break
            }
        }
    }
    
    @objc
    func reloadData() {
        guard let publicPlanInfo = publicPlanInfo else { return }
        let days = Array(publicPlanInfo.days.values)
        let dicts = Dictionary(grouping: days, by: { $0.date.year })
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        if mode == .subscriptionPreview, !changeEntries.isEmpty {
            snapshot.appendSections([.changes])
            snapshot.appendItems(changeEntries.map { .changeItem($0) }, toSection: .changes)
        }

        snapshot.appendSections([.info])
        var infoItems: [Item] = [.start(publicPlanInfo.start), .end(publicPlanInfo.end)]
        switch mode {
        case .viewer:
            if let note = publicPlanInfo.note, !note.isEmpty {
                infoItems.append(.note(publicPlanInfo.note))
            }
            // Subscribed plan: show URL and last refresh time
            if case .custom(let plan) = publicPlanInfo.plan, let url = plan.sourceURL {
                infoItems.append(.sourceURL(url))
                if let ts = plan.lastRefreshTime, ts > 0 {
                    infoItems.append(.lastRefreshTime(ts))
                }
            }
        case .subscriptionPreview:
            if let note = publicPlanInfo.note, !note.isEmpty {
                infoItems.append(.note(publicPlanInfo.note))
            }
        case .editor:
            infoItems.append(.note(publicPlanInfo.note))
        }
        snapshot.appendItems(infoItems, toSection: .info)
        
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
            // Subscribed plan: show actions + delete
            if case .custom(let plan) = publicPlanInfo.plan, plan.sourceURL != nil, plan.id != nil {
                snapshot.appendSections([.actions])
                var actionItems: [Item] = [.refreshSubscription]
                if plan.isPaused == true {
                    actionItems.append(.resumeSubscription)
                } else {
                    actionItems.append(.pauseSubscription)
                }
                snapshot.appendItems(actionItems, toSection: .actions)

                snapshot.appendSections([.delete])
                snapshot.appendItems([.delete], toSection: .delete)
            }
        case .subscriptionPreview:
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
        dismiss(animated: ConsideringUser.animated)
    }

    @objc
    func acceptAction() {
        dismiss(animated: ConsideringUser.animated) { [weak self] in
            self?.onAccept?()
        }
    }

    @objc
    func showDeclineAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: String(localized: "subscription.preview.decline.skip"), style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: ConsideringUser.animated) {
                self.onDecline?(.skip)
            }
        })
        alertController.addAction(UIAlertAction(title: String(localized: "subscription.preview.decline.pause"), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: ConsideringUser.animated) {
                self.onDecline?(.pause)
            }
        })
        alertController.addAction(UIAlertAction(title: String(localized: "subscription.preview.decline.cancel"), style: .cancel))
        present(alertController, animated: ConsideringUser.animated)
    }

    func duplicateTemplate() {
        if let nav = presentingViewController as? NavigationController, let root = nav.topViewController as? PublicPlanViewController {
            if let customTemplateInfo = publicPlanInfo?.getDuplicateCustomPlan() {
                dismiss(animated: ConsideringUser.animated) { [weak root] in
                    root?.createCustomTemplate(prefill: customTemplateInfo)
                }
            }
        }
    }
    
    @objc
    func saveAction() {
        guard mode == .editor else {
            return
        }
        guard let planInfo = publicPlanInfo, planInfo.start.julianDay <= planInfo.end.julianDay else {
            showDateErrorAlert()
            return
        }
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
        
        navigationController?.present(nav, animated: ConsideringUser.animated)
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
        present(alertController, animated: ConsideringUser.animated, completion: nil)
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
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    func showDateErrorAlert() {
        let alertController = UIAlertController(title: String(localized: "publicPlan.alert.dateError.title"), message: String(localized: "publicPlan.alert.dateError.message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicPlan.alert.dateError.cancel"), style: .cancel) { _ in
            //
        }

        alertController.addAction(cancelAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    func showNoteAlert() {
        let alertController = UIAlertController(title: String(localized: "publicDetail.note.alert.title"), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicDetail.alert.cancel"), style: .cancel) { _ in
        }
        let okAction = UIAlertAction(title: String(localized: "publicDetail.alert.confirm"), style: .default) { [weak self] _ in
            let text = alertController.textFields?.first?.text
            self?.publicPlanInfo?.note = (text?.isEmpty == true) ? nil : text
            self?.reloadData()
        }
        alertController.addTextField { [weak self] textField in
            textField.placeholder = String(localized: "publicDetail.note.empty")
            textField.text = self?.publicPlanInfo?.note
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    func deleteAction() {
        guard let publicPlanInfo = publicPlanInfo else { return }
        dismiss(animated: ConsideringUser.animated) {
            _ = PublicPlanManager.shared.delete(publicPlanInfo)
        }
    }

    func refreshSubscriptionAction() {
        guard case .custom(let plan) = publicPlanInfo?.plan else { return }
        Task {
            do {
                _ = try await SubscriptionManager.shared.refresh(plan: plan, trigger: .manual, ignorePause: true, clearRejected: true)
            } catch {
                Logger.subscription.error("Refresh failed: \(error.localizedDescription)")
            }
            if let planId = plan.id {
                if let detail = try? PublicPlanManager.shared.fetchCustomPublicPlan(with: planId) {
                    self.publicPlanInfo = PublicPlanInfo(detail: detail)
                    self.reloadData()
                }
                SubscriptionManager.shared.presentPendingUpdateAlert(for: planId)
            }
        }
    }

    func pauseSubscriptionAction() {
        guard case .custom(let plan) = publicPlanInfo?.plan, let planId = plan.id else { return }
        SubscriptionManager.shared.pauseSubscription(for: planId)
        if let detail = try? PublicPlanManager.shared.fetchCustomPublicPlan(with: planId) {
            self.publicPlanInfo = PublicPlanInfo(detail: detail)
            self.reloadData()
        }
    }

    func resumeSubscriptionAction() {
        guard case .custom(let plan) = publicPlanInfo?.plan, let planId = plan.id else { return }
        SubscriptionManager.shared.resumeSubscription(for: planId)
        Task {
            do {
                _ = try await SubscriptionManager.shared.refresh(plan: plan, trigger: .manual, ignorePause: true, clearRejected: true)
            } catch {
                Logger.subscription.error("Refresh after resume failed: \(error.localizedDescription)")
            }
            if let detail = try? PublicPlanManager.shared.fetchCustomPublicPlan(with: planId) {
                self.publicPlanInfo = PublicPlanInfo(detail: detail)
                self.reloadData()
            }
            SubscriptionManager.shared.presentPendingUpdateAlert(for: planId)
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
            case .note:
                if self.mode == .editor {
                    showNoteAlert()
                }
            case .refreshSubscription:
                refreshSubscriptionAction()
            case .pauseSubscription:
                pauseSubscriptionAction()
            case .resumeSubscription:
                resumeSubscriptionAction()
            case .start, .end, .changeItem, .sourceURL, .lastRefreshTime:
                break
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
        if case .sourceURL(let url) = item {
            return UIContextMenuConfiguration(actionProvider: { _ in
                let copyAction = UIAction(title: String(localized: "publicDetail.sourceURL.copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = url
                }
                return UIMenu(children: [copyAction])
            })
        }
        return nil
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
