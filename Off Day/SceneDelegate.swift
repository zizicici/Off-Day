//
//  SceneDelegate.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var tutorialSetting: TutorialEntranceType?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let tabBarController = TabbarController()
        tabBarController.view.tintColor = AppColor.offDay
        tabBarController.tabBar.tintColor = AppColor.offDay
        
        reloadTabsIfNeeded()
        
        window?.makeKeyAndVisible()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTabsIfNeeded), name: .SettingsUpdate, object: nil)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
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
        guard tutorialSetting != TutorialEntranceType.getValue() else {
            return
        }
        let newValue = TutorialEntranceType.getValue()
        tutorialSetting = newValue
        
        let tabbarController: TabbarController = window?.rootViewController as? TabbarController ?? TabbarController()
        tabbarController.view.tintColor = AppColor.offDay
        tabbarController.tabBar.tintColor = AppColor.offDay
        
        var viewControllers: [UIViewController] = []
        let calendarViewController = tabbarController.viewControllers?.first { viewController in
            return (viewController as? NavigationController)?.viewControllers.first is BlockViewController
        } ?? NavigationController(rootViewController: BlockViewController())
        let moreViewController = tabbarController.viewControllers?.first { viewController in
            return (viewController as? NavigationController)?.viewControllers.first is MoreViewController
        } ?? NavigationController(rootViewController: MoreViewController())
        let tutorialViewController = tabbarController.viewControllers?.first { viewController in
            return (viewController as? NavigationController)?.viewControllers.first is TutorialsViewController
        } ?? NavigationController(rootViewController: TutorialsViewController())

        switch newValue {
        case .firstTab:
            viewControllers = [tutorialViewController, calendarViewController, moreViewController]
        case .secondTab:
            viewControllers = [calendarViewController, tutorialViewController, moreViewController]
        case .hidden:
            viewControllers = [calendarViewController, moreViewController]
        }
        
        if #available(iOS 18.0, *) {
            tabbarController.tabs = viewControllers.compactMap({ viewController in
                if let tabItem = viewController.tabBarItem {
                    return UITab(title: tabItem.title ?? "", image: tabItem.image, identifier: "\(tabItem.tag)") { tab in
                        return viewController
                    }
                } else {
                    return nil
                }
            })
        } else {
            tabbarController.setViewControllers(viewControllers, animated: false)
        }
        
        window?.rootViewController = tabbarController
    }
}

