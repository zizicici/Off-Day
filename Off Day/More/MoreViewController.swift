//
//  MoreViewController.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import SnapKit
import SafariServices
import AppInfo
import StoreKit

class MoreViewController: UIViewController {
    static let supportEmail = "offday@zi.ci"

    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Hashable {
        case general
        case dataSource
        case notification
        case backup
        case contact
        case help
        case appjun
        case about
        
        var header: String? {
            switch self {
            case .general:
                return String(localized: "more.section.general")
            case .dataSource:
                return String(localized: "more.section.dataSource")
            case .notification:
                return String(localized: "more.section.notification")
            case .backup:
                return String(localized: "more.section.backup")
            case .contact:
                return String(localized: "more.section.contact")
            case .help:
                return String(localized: "more.section.help")
            case .appjun:
                return String(localized: "more.section.appjun")
            case .about:
                return String(localized: "more.section.about")
            }
        }
        
        var footer: String? {
            return nil
        }
    }
    
    enum Item: Hashable {
        enum GeneralItem: Hashable {
            case language
            case tutorial(TutorialEntranceType)
            case alternative(AlternativeCalendarType)
            
            var title: String {
                switch self {
                case .language:
                    return String(localized: "more.item.settings.language")
                case .tutorial:
                    return TutorialEntranceType.getTitle()
                case .alternative:
                    return AlternativeCalendarType.getTitle()
                }
            }
            
            var value: String? {
                switch self {
                case .language:
                    return String(localized: "more.item.settings.language.value")
                case .tutorial(let type):
                    return type.getName()
                case .alternative(let type):
                    return type.getName()
                }
            }
        }
        
        enum DataSourceItem: Hashable {
            case publicPlan(PublicPlanInfo.Plan?)
            case baseCalendar(BaseCalendarType)
            
            var title: String {
                switch self {
                case .publicPlan:
                    return String(localized: "more.item.settings.publicPlan")
                case .baseCalendar:
                    return String(localized: "more.item.settings.baseCalendar")
                }
            }
            
            var value: String? {
                switch self {
                case .publicPlan(let plan):
                    if let plan = plan {
                        switch plan {
                        case .app(let appPublicPlan):
                            return appPublicPlan.title
                        case .custom(let customPublicPlan):
                            return customPublicPlan.name
                        }
                    } else {
                        return String(localized: "more.item.settings.publicPlan.noSet")
                    }
                case .baseCalendar(let type):
                    return type.title
                }
            }
        }
        
        enum ContactItem: Hashable, CaseIterable {
            case email
            case xiaohongshu
            case bilibili

            var title: String {
                switch self {
                case .email:
                    return String(localized: "more.item.contact.email")
                case .xiaohongshu:
                    return String(localized: "more.item.contact.xiaohongshu")
                case .bilibili:
                    return String(localized: "more.item.contact.bilibili")
                }
            }
            
            var value: String? {
                switch self {
                case .email:
                    return MoreViewController.supportEmail
                case .bilibili, .xiaohongshu:
                    return "@App君"
                }
            }
            
            var image: UIImage? {
                switch self {
                case .email:
                    return UIImage(systemName: "envelope")
                case .xiaohongshu:
                    return UIImage(systemName: "book.closed")
                case .bilibili:
                    return UIImage(systemName: "play.tv")
                }
            }
        }
        
        enum AboutItem {
            case specifications
            case share
            case review
            case eula
            case privacyPolicy
            
            var title: String {
                switch self {
                case .specifications:
                    return String(localized: "more.item.about.specifications")
                case .share:
                    return String(localized: "more.item.about.share")
                case .review:
                    return String(localized: "more.item.about.review")
                case .eula:
                    return String(localized: "more.item.about.eula")
                case .privacyPolicy:
                    return String(localized: "more.item.about.privacyPolicy")
                }
            }
            
            var value: String? {
                return nil
            }
        }
        
        case settings(GeneralItem)
        case dataSource(DataSourceItem)
        case notification
        case backup
        case help
        case contact(ContactItem)
        case appjun(AppInfo.App)
        case about(AboutItem)
        
        var title: String {
            switch self {
            case .settings(let item):
                return item.title
            case .dataSource(let item):
                return item.title
            case .notification:
                return String(localized: "notificationEditor.title")
            case .backup:
                return String(localized: "backup.title")
            case .help:
                return String(localized: "more.item.help")
            case .contact(let item):
                return item.title
            case .appjun(let item):
                return ""
            case .about(let item):
                return item.title
            }
        }
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let sectionKind = sectionIdentifier(for: section)
            return sectionKind?.header
        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            let sectionKind = sectionIdentifier(for: section)
            return sectionKind?.footer
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = String(localized: "controller.more.title")
        tabBarItem = UITabBarItem(title: String(localized: "controller.more.title"), image: UIImage(systemName: "ellipsis"), tag: 2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("MoreViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .SettingsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.register(AppCell.self, forCellReuseIdentifier: NSStringFromClass(AppCell.self))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .settings(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            case .dataSource(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            case .notification, .backup:
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                cell.contentConfiguration = content
                return cell
            case .help:
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                cell.contentConfiguration = content
                return cell
            case .contact(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            case .appjun(let app):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(AppCell.self), for: indexPath)
                if let cell = cell as? AppCell {
                    cell.update(app)
                }
                cell.accessoryType = .disclosureIndicator
                return cell
            case .about(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = .disclosureIndicator
                var content = UIListContentConfiguration.valueCell()
                content.text = identifier.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.general])
        snapshot.appendItems([.settings(.language), .settings(.tutorial(TutorialEntranceType.getValue())), .settings(.alternative(AlternativeCalendarType.getValue()))], toSection: .general)
        
        snapshot.appendSections([.dataSource])
        snapshot.appendItems([.dataSource(.publicPlan(PublicPlanManager.shared.dataSource?.plan)), .dataSource(.baseCalendar(BaseCalendarManager.shared.config.type))], toSection: .dataSource)
        
        snapshot.appendSections([.notification])
        snapshot.appendItems([.notification], toSection: .notification)
        
        snapshot.appendSections([.backup])
        snapshot.appendItems([.backup], toSection: .backup)
        
        snapshot.appendSections([.help])
        snapshot.appendItems([.help], toSection: .help)
        
        snapshot.appendSections([.contact])
        snapshot.appendItems([.contact(.email), .contact(.xiaohongshu), .contact(.bilibili)], toSection: .contact)
        
        snapshot.appendSections([.appjun])
        var appItems: [Item] = [.appjun(.tagDay), .appjun(.lemon), .appjun(.moontake), .appjun(.coconut), .appjun(.pigeon)]
        if Language.type() == .zh {
            appItems.append(.appjun(.festivals))
        }
        appItems.append(.appjun(.one))
        snapshot.appendItems(appItems, toSection: .appjun)
        
        snapshot.appendSections([.about])
        snapshot.appendItems([.about(.specifications), .about(.eula), .about(.share), .about(.review), .about(.privacyPolicy)], toSection: .about)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension MoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .settings(let item):
                switch item {
                case .language:
                    jumpToSettings()
                case .tutorial:
                    enterSettings(TutorialEntranceType.self)
                case .alternative:
                    enterSettings(AlternativeCalendarType.self)
                }
            case .dataSource(let item):
                switch item {
                case .publicPlan:
                    showPublicPlanPicker()
                case .baseCalendar:
                    showBaseCalendarEditor()
                }
            case .notification:
                enterNotificationSettings()
            case .backup:
                enterBackup()
            case .help:
                enterHelpCenter()
            case .contact(let item):
                handle(contactItem: item)
            case .appjun(let app):
                openStorePage(for: app)
            case .about(let item):
                switch item {
                case .specifications:
                    enterSpecifications()
                case .share:
                    shareApp()
                case .review:
                    openAppStoreForReview()
                case .eula:
                    openEULA()
                case .privacyPolicy:
                    openPrivacyPolicy()
                }
            }
        }
    }
}

extension MoreViewController {
    func showPublicPlanPicker() {
        let publicPlanViewController = PublicPlanViewController()
        let nav = NavigationController(rootViewController: publicPlanViewController)
        
        navigationController?.present(nav, animated: ConsideringUser.animated)
    }
    
    func showBaseCalendarEditor() {
        let baseCalendarViewController = BaseCalendarEditorViewController()
        let nav = NavigationController(rootViewController: baseCalendarViewController)
        
        navigationController?.present(nav, animated: ConsideringUser.animated)
    }
    
    func enterSettings<T: SettingsOption>(_ type: T.Type) {
        let settingsOptionViewController = SettingOptionsViewController<T>()
        settingsOptionViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(settingsOptionViewController, animated: ConsideringUser.pushAnimated)
    }
    
    func enterNotificationSettings() {
        let notificationViewController = NotificationViewController()
        notificationViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(notificationViewController, animated: ConsideringUser.pushAnimated)
    }
    
    func enterBackup() {
        let notificationViewController = BackupViewController()
        notificationViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(notificationViewController, animated: ConsideringUser.pushAnimated)
    }
    
    func enterHelpCenter() {
        if let url = HelpURL.helpCenterURL {
            openSF(with: url)
        }
    }
    
    func enterSpecifications() {
        let specificationViewController = SpecificationsViewController()
        specificationViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(specificationViewController, animated: ConsideringUser.pushAnimated)
    }
    
    func openEULA() {
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            openSF(with: url)
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://zizicici.medium.com/privacy-policy-for-off-day-app-6f7f26f68c7c") {
            openSF(with: url)
        }
    }
    
    func openYoutubeWebpage() {
        if let url = URL(string: "https://www.youtube.com/@app_jun") {
            openSF(with: url)
        }
    }
    
    func openStorePage(for app: App) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [SKStoreProductParameterITunesItemIdentifier: app.storeId]
        
        storeViewController.loadProduct(withParameters: parameters) { [weak self] (loaded, error) in
            if loaded {
                // 成功加载，展示视图控制器
                self?.present(storeViewController, animated: ConsideringUser.animated, completion: nil)
            } else if let error = error {
                // 加载失败，可以选择跳转到 App Store 应用作为后备方案
                print("Error loading App Store: \(error.localizedDescription)")
                self?.jumpToAppStorePage(for: app)
            }
        }
    }
    
    func jumpToAppStorePage(for app: App) {
        guard let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/" + app.storeId) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    func openAppStoreForReview() {
        guard let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id6501973975?action=write-review") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    func shareApp() {
        if let url = URL(string: "https://apps.apple.com/app/id6501973975") {
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            present(controller, animated: ConsideringUser.animated)
        }
    }
}

extension MoreViewController {
    func showOverlayViewController() {
        let overlayVC = OverlayViewController()
        
        // 让当前视图控制器的内容可见但不可交互
        overlayVC.modalPresentationStyle = .overCurrentContext
        overlayVC.modalTransitionStyle = .crossDissolve
        
        // 显示覆盖全屏的遮罩层
        navigationController?.present(overlayVC, animated: ConsideringUser.animated, completion: nil)
    }

    func hideOverlayViewController() {
        // 隐藏覆盖全屏的遮罩层
        navigationController?.dismiss(animated: ConsideringUser.animated, completion: nil)
    }
}

extension MoreViewController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: ConsideringUser.animated, completion: nil)
    }
}

class OverlayViewController: UIViewController {
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置背景颜色和透明度
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        // 添加指示器到视图并居中
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 开始旋转
        activityIndicator.startAnimating()
    }
}

struct Language {
    enum LanguageType {
        case zh
        case en
        case ja
    }
    
    static func type() -> LanguageType {
        switch String(localized: "more.item.settings.language.value") {
        case "简体中文", "繁體中文", "繁體中文（香港）":
            return .zh
        case "日本語":
            return .ja
        default:
            return .en
        }
    }
}

extension UIViewController {
    func handle(contactItem: MoreViewController.Item.ContactItem) {
        switch contactItem {
        case .email:
            sendEmailToCustomerSupport()
        case .xiaohongshu:
            openXiaohongshuWebpage()
        case .bilibili:
            openBilibiliWebpage()
        }
    }
    
    func sendEmailToCustomerSupport() {
        let recipient = MoreViewController.supportEmail
        
        guard let emailUrlString = "mailto:\(recipient)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let emailUrl = URL(string: emailUrlString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(emailUrl) {
            UIApplication.shared.open(emailUrl, options: [:], completionHandler: nil)
        } else {
            // 打开邮件应用失败，进行适当的处理或提醒用户
        }
    }
    
    
    func openBilibiliWebpage() {
        if let url = URL(string: "https://space.bilibili.com/4969209") {
            openSF(with: url)
        }
    }
    
    func openXiaohongshuWebpage() {
        if let url = URL(string: "https://www.xiaohongshu.com/user/profile/63f05fc5000000001001e524") {
            openSF(with: url)
        }
    }
}
