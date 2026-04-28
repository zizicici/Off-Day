//
//  SceneDelegate.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import MoreKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var tutorialSetting: TutorialEntranceType?
    var logEntranceSetting: LogEntranceType?

    private enum TabKind: String, CaseIterable {
        case tutorial
        case calendar
        case log
        case more

        var tag: Int {
            switch self {
            case .tutorial: return 0
            case .calendar: return 1
            case .more:     return 2
            case .log:      return 3
            }
        }

        @MainActor
        func makeViewController() -> UIViewController {
            switch self {
            case .tutorial:
                return NavigationController(rootViewController: TutorialsViewController())
            case .calendar:
                return NavigationController(rootViewController: BlockViewController())
            case .log:
                return NavigationController(rootViewController: LogViewController())
            case .more:
                return MoreNavigationController(rootViewController: MoreControllerFactory.make())
            }
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        reloadTabsIfNeeded()
        
        window?.makeKeyAndVisible()
        refreshSubscriptionsForUserLaunch()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTabsIfNeeded), name: .SettingsUpdate, object: nil)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        SubscriptionManager.shared.presentPendingUpdateAlertIfNeeded()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    @objc
    func reloadTabsIfNeeded() {
        let tutorialValue = TutorialEntranceType.getValue()
        let logEntranceValue = LogEntranceType.getValue()
        guard tutorialSetting != tutorialValue || logEntranceSetting != logEntranceValue else {
            return
        }
        tutorialSetting = tutorialValue
        logEntranceSetting = logEntranceValue

        let tabbarController = (window?.rootViewController as? TabbarController) ?? TabbarController()
        tabbarController.view.tintColor = AppColor.offDay
        tabbarController.tabBar.tintColor = AppColor.offDay

        let kinds = Self.orderedTabs(tutorial: tutorialValue, logEntrance: logEntranceValue)

        if #available(iOS 18.0, *) {
            applyTabsUsingUITab(kinds: kinds, on: tabbarController)
        } else {
            applyTabsLegacy(kinds: kinds, on: tabbarController)
        }

        if window?.rootViewController !== tabbarController {
            window?.rootViewController = tabbarController
        }
    }

    private static func orderedTabs(tutorial: TutorialEntranceType, logEntrance: LogEntranceType) -> [TabKind] {
        var kinds: [TabKind]
        switch tutorial {
        case .firstTab:  kinds = [.tutorial, .calendar]
        case .secondTab: kinds = [.calendar, .tutorial]
        case .hidden:    kinds = [.calendar]
        }
        if logEntrance == .tab {
            kinds.append(.log)
        }
        kinds.append(.more)
        return kinds
    }

    private func refreshSubscriptionsForUserLaunch() {
        Task {
            await SubscriptionManager.shared.refreshAll(trigger: .launch)
            await SubscriptionManager.shared.presentPendingUpdateAlertIfNeeded()
        }
    }

    @available(iOS 18.0, *)
    private func applyTabsUsingUITab(kinds: [TabKind], on tabbarController: TabbarController) {
        var reusable: [String: UITab] = [:]
        for tab in tabbarController.tabs {
            reusable[tab.identifier] = tab
        }
        tabbarController.tabs = kinds.map { kind in
            if let existing = reusable[kind.rawValue] {
                return existing
            }
            let viewController = kind.makeViewController()
            let item = viewController.tabBarItem
            return UITab(
                title: item?.title ?? "",
                image: item?.image,
                identifier: kind.rawValue
            ) { _ in viewController }
        }
    }

    private func applyTabsLegacy(kinds: [TabKind], on tabbarController: TabbarController) {
        var reusable: [Int: UIViewController] = [:]
        for viewController in tabbarController.viewControllers ?? [] {
            if let tag = viewController.tabBarItem?.tag {
                reusable[tag] = viewController
            }
        }
        let viewControllers = kinds.map { kind in
            reusable[kind.tag] ?? kind.makeViewController()
        }
        tabbarController.setViewControllers(viewControllers, animated: false)
    }
}
