//
//  MoreViewController.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import MoreKit
import SafariServices

enum ContactItem: Hashable, CaseIterable {
    case email
    case xiaohongshu

    var title: String {
        switch self {
        case .email:
            return String(localized: "more.item.contact.email")
        case .xiaohongshu:
            return String(localized: "more.item.contact.xiaohongshu")
        }
    }

    var value: String? {
        switch self {
        case .email:
            return MoreControllerFactory.supportEmail
        case .xiaohongshu:
            return "@App君"
        }
    }

    var image: UIImage? {
        switch self {
        case .email:
            return UIImage(systemName: "envelope")
        case .xiaohongshu:
            return UIImage(systemName: "book.closed")
        }
    }
}

extension UIViewController {
    func handle(contactItem: ContactItem) {
        switch contactItem {
        case .email:
            sendEmailToCustomerSupport()
        case .xiaohongshu:
            openXiaohongshuWebpage()
        }
    }

    func sendEmailToCustomerSupport() {
        let recipient = MoreControllerFactory.supportEmail
        guard let urlString = "mailto:\(recipient)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }

    func openXiaohongshuWebpage() {
        if let url = URL(string: "https://www.xiaohongshu.com/user/profile/63f05fc5000000001001e524") {
            openSF(with: url)
        }
    }
}

final class MoreNavigationController: NavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
}

enum MoreControllerFactory {
    static let supportEmail = "offday@zi.ci"
    static let appStoreId = "6501973975"

    static func make() -> MoreViewController {
        let appShowcase = AppShowcaseConfiguration(
            apps: [.pin, .tagDay, .lemon, .moontake, .coconut, .pigeon, .one, .campfire, .watermelon, .doufu, .festivals],
            displayCount: 4,
            automaticallyIncludesFestivalsForChineseLocales: true
        )

        let specConfig = SpecificationsConfiguration(
            summaryItems: [
                .init(type: .name, value: SpecificationsViewController.getAppName() ?? ""),
                .init(type: .version, value: SpecificationsViewController.getAppVersion() ?? ""),
                .init(type: .manufacturer, value: "@App君"),
                .init(type: .publisher, value: "ZIZICICI LIMITED"),
                .init(type: .dateOfProduction, value: "2026/04/20"),
                .init(type: .license, value: "闽ICP备2023015823号-8A"),
            ],
            thirdPartyLibraries: [
                .init(name: "SnapKit", version: "5.7.1", urlString: "https://github.com/SnapKit/SnapKit"),
                .init(name: "GRDB", version: "7.10.0", urlString: "https://github.com/groue/GRDB.swift"),
                .init(name: "Toast", version: "5.1.1", urlString: "https://github.com/scalessec/Toast-Swift"),
                .init(name: "MarqueeLabel", version: "4.5.3", urlString: "https://github.com/cbpowell/MarqueeLabel"),
                .init(name: "ZipArchive", version: "2.6.0", urlString: "https://github.com/ZipArchive/ZipArchive"),
            ]
        )

        let config = MoreViewControllerConfiguration(
            title: String(localized: "controller.more.title"),
            tabBarImage: UIImage(systemName: "ellipsis"),
            email: supportEmail,
            appStoreId: appStoreId,
            privacyPolicyURL: "https://zizicici.medium.com/privacy-policy-for-off-day-app-6f7f26f68c7c",
            specificationsConfig: specConfig,
            appShowcase: appShowcase
        )

        let controller = MoreViewController(configuration: config, dataSource: MoreDataSource.shared)
        controller.tabBarItem = UITabBarItem(
            title: String(localized: "controller.more.title"),
            image: UIImage(systemName: "ellipsis"),
            tag: 2
        )
        return controller
    }
}

final class MoreDataSource: NSObject, MoreViewControllerDataSource {
    static let shared = MoreDataSource()

    func sections(for controller: MoreViewController) -> [MoreSectionType] {
        [
            .custom(generalSection()),
            .custom(dataSourceSection()),
            .custom(MoreCustomSection(
                id: "notification",
                items: [MoreCustomItem(id: "notification", title: String(localized: "notificationEditor.title"))]
            )),
            .custom(MoreCustomSection(
                id: "backup",
                items: [MoreCustomItem(id: "backup", title: String(localized: "backup.title"))]
            )),
            .custom(MoreCustomSection(
                id: "help",
                items: [MoreCustomItem(id: "help", title: String(localized: "more.item.help"))]
            )),
            .custom(logSection()),
            .contact,
            .appjun,
            .about,
        ]
    }

    func moreViewController(_ controller: MoreViewController, didSelectCustomItem item: MoreCustomItem) {
        switch item.id {
        case "settings.tutorial":
            controller.enterSettings(TutorialEntranceType.self)
        case "settings.alternative":
            controller.enterSettings(AlternativeCalendarType.self)
        case "settings.logo":
            controller.enterSettings(Logo.self)
        case "settings.logEntrance":
            controller.enterSettings(LogEntranceType.self)
        case "log.open":
            controller.pushViewController(LogViewController())
        case "settings.logRetention":
            controller.enterSettings(LogRetentionType.self)
        case "dataSource.publicPlan":
            presentPublicPlan(from: controller)
        case "dataSource.baseCalendar":
            presentBaseCalendar(from: controller)
        case "notification":
            controller.pushViewController(NotificationViewController())
        case "backup":
            controller.pushViewController(BackupViewController())
        case "help":
            if let url = HelpURL.helpCenterURL {
                presentSafari(with: url, from: controller)
            }
        default:
            break
        }
    }

    func additionalReloadNotifications() -> [Notification.Name] {
        [.DatabaseUpdated]
    }

    private func generalSection() -> MoreCustomSection {
        MoreCustomSection(
            id: "general",
            header: String(localized: "more.section.general"),
            items: [
                MoreCustomItem.languageSettings(),
                MoreCustomItem(
                    id: "settings.tutorial",
                    title: TutorialEntranceType.getTitle(),
                    value: TutorialEntranceType.getValue().getName()
                ),
                MoreCustomItem(
                    id: "settings.alternative",
                    title: AlternativeCalendarType.getTitle(),
                    value: AlternativeCalendarType.getValue().getName()
                ),
                MoreCustomItem(
                    id: "settings.logo",
                    title: Logo.getTitle(),
                    value: Logo.getValue().getName()
                ),
            ]
        )
    }

    private func logSection() -> MoreCustomSection {
        var items: [MoreCustomItem] = [
            MoreCustomItem(
                id: "settings.logEntrance",
                title: LogEntranceType.getTitle(),
                value: LogEntranceType.getValue().getName()
            )
        ]
        if LogEntranceType.getValue() == .hidden {
            items.append(MoreCustomItem(
                id: "log.open",
                title: String(localized: "controller.log.title")
            ))
        }
        items.append(MoreCustomItem(
            id: "settings.logRetention",
            title: LogRetentionType.getTitle(),
            value: LogRetentionType.getValue().getName()
        ))
        return MoreCustomSection(
            id: "log",
            header: String(localized: "more.section.log"),
            items: items
        )
    }

    private func dataSourceSection() -> MoreCustomSection {
        let publicPlanValue: String = {
            if let plan = PublicPlanManager.shared.dataSource?.plan {
                switch plan {
                case .app(let app):
                    return app.title
                case .custom(let custom):
                    return custom.name
                }
            }
            return String(localized: "more.item.settings.publicPlan.noSet")
        }()

        return MoreCustomSection(
            id: "dataSource",
            header: String(localized: "more.section.dataSource"),
            items: [
                MoreCustomItem(
                    id: "dataSource.publicPlan",
                    title: String(localized: "more.item.settings.publicPlan"),
                    value: publicPlanValue
                ),
                MoreCustomItem(
                    id: "dataSource.baseCalendar",
                    title: String(localized: "more.item.settings.baseCalendar"),
                    value: BaseCalendarManager.shared.config.type.title
                ),
            ]
        )
    }

    private func presentPublicPlan(from controller: UIViewController) {
        let vc = PublicPlanViewController()
        let nav = NavigationController(rootViewController: vc)
        controller.navigationController?.present(nav, animated: ConsideringUser.animated)
    }

    private func presentBaseCalendar(from controller: UIViewController) {
        let vc = BaseCalendarEditorViewController()
        let nav = NavigationController(rootViewController: vc)
        controller.navigationController?.present(nav, animated: ConsideringUser.animated)
    }

    private func presentSafari(with url: URL, from controller: UIViewController) {
        let sf = SFSafariViewController(url: url)
        controller.navigationController?.present(sf, animated: ConsideringUser.animated)
    }
}
