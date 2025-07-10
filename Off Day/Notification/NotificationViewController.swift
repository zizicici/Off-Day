//
//  NotificationViewController.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/31.
//

import Foundation
import UIKit
import SnapKit
import UserNotifications

class NotificationViewController: UIViewController {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Hashable {
        case permission
        case publicHoliday
        case customDay
        case template
        
        var header: String? {
            switch self {
            case .permission:
                return nil
            case .publicHoliday:
                return String(localized: "notificationEditor.publicHoliday.section")
            case .customDay:
                return String(localized: "notificationEditor.customDay.section")
            case .template:
                return String(localized: "notificationEditor.template.section")
            }
        }
        
        var footer: String? {
            switch self {
            case .permission:
                return nil
            case .publicHoliday:
                return String(localized: "notificationEditor.publicHoliday.hint")
            case .customDay:
                return String(localized: "notificationEditor.customDay.hint")
            case .template:
                return String(localized: "notificationEditor.template.hint")
            }
        }
    }
    
    enum Item: Hashable {
        case permission(UNAuthorizationStatus)
        case publicHolidayToggle(Bool, Bool)
        case publicHolidayFireTime(Int64)
        case customDayToggle(Bool, Bool)
        case customDayFireTime(Int64)
        case expireToggle(Bool, Bool)
        case expireFireTime(Int64)
        
        var title: String? {
            switch self {
            case .permission(let authStatus):
                switch authStatus {
                case .notDetermined:
                    return String(localized: "notificationEditor.auth.notDetermined")
                case .denied:
                    return String(localized: "notificationEditor.auth.needToSettings")
                case .authorized:
                    return nil
                case .provisional:
                    return String(localized: "notificationEditor.auth.needToSettings")
                case .ephemeral:
                    return String(localized: "notificationEditor.auth.needToSettings")
                @unknown default:
                    fatalError()
                }
            case .publicHolidayToggle:
                return String(localized: "notificationEditor.publicHoliday.toggle")
            case .publicHolidayFireTime:
                return String(localized: "notificationEditor.publicHoliday.fireTime")
            case .customDayToggle:
                return String(localized: "notificationEditor.customDay.toggle")
            case .customDayFireTime:
                return String(localized: "notificationEditor.customDay.fireTime")
            case .expireToggle:
                return String(localized: "notificationEditor.expire.toggle")
            case .expireFireTime:
                return String(localized: "notificationEditor.expire.fireTime")
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("NotificationViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(localized: "notificationEditor.title")
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: Notification.Name.SettingsUpdate, object: nil)
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(DateCell.self, forCellReuseIdentifier: NSStringFromClass(DateCell.self))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .permission:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                var content = UIListContentConfiguration.cell()
                content.text = identifier.title
                content.textProperties.color = AppColor.offDay
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
                
                return cell
            case .publicHolidayToggle(let isEnabled, let isOn):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                let itemSwitch = UISwitch()
                itemSwitch.isEnabled = isEnabled
                itemSwitch.isOn = isEnabled && isOn
                itemSwitch.onTintColor = AppColor.offDay
                itemSwitch.addTarget(self, action: #selector(self.publicHolidayToggle(_:)), for: .touchUpInside)
                cell.accessoryView = itemSwitch
                
                var content = cell.defaultContentConfiguration()
                content.text = identifier.title
                cell.contentConfiguration = content
                
                return cell
            case .publicHolidayFireTime(let fireTime):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: identifier.title ?? "", nanoSecondsFrom1970: fireTime))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        
                    }
                }
                return cell
            case .customDayToggle(let isEnabled, let isOn):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                let itemSwitch = UISwitch()
                itemSwitch.isEnabled = isEnabled
                itemSwitch.isOn = isEnabled && isOn
                itemSwitch.onTintColor = AppColor.offDay
                itemSwitch.addTarget(self, action: #selector(self.customDayToggle(_:)), for: .touchUpInside)
                cell.accessoryView = itemSwitch
                
                var content = cell.defaultContentConfiguration()
                content.text = identifier.title
                cell.contentConfiguration = content
                
                return cell
            case .customDayFireTime(let fireTime):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: identifier.title ?? "", nanoSecondsFrom1970: fireTime))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        
                    }
                }
                return cell
            case .expireToggle(let isEnabled, let isOn):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                let itemSwitch = UISwitch()
                itemSwitch.isEnabled = isEnabled
                itemSwitch.isOn = isEnabled && isOn
                itemSwitch.onTintColor = AppColor.offDay
                itemSwitch.addTarget(self, action: #selector(self.expiryToggle(_:)), for: .touchUpInside)
                cell.accessoryView = itemSwitch
                
                var content = cell.defaultContentConfiguration()
                content.text = identifier.title
                cell.contentConfiguration = content
                
                return cell
            case .expireFireTime(let fireTime):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: identifier.title ?? "", nanoSecondsFrom1970: fireTime))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        
                    }
                }
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.apply(with: settings.authorizationStatus)
            }
        }
    }
    
    func apply(with authStatus: UNAuthorizationStatus) {
        let manager = NotificationManager.shared
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        let allowAction: Bool
        switch authStatus {
        case .notDetermined:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        case .denied:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        case .authorized:
            allowAction = true
        case .provisional:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        case .ephemeral:
            allowAction = false
            snapshot.appendSections([.permission])
            snapshot.appendItems([.permission(authStatus)], toSection: .permission)
        @unknown default:
            fatalError()
        }
        
        let templateExpiryIsEnabled = manager.isEnabled(for: .templateExpiry)
        snapshot.appendSections([.template])
        snapshot.appendItems([.expireToggle(allowAction, templateExpiryIsEnabled)], toSection: .template)
        if allowAction, templateExpiryIsEnabled {
            snapshot.appendItems([.expireFireTime(0)], toSection: .template)
        }
        
        let publicHolidayStartIsEnabled = manager.isEnabled(for: .publicHoliday)
        snapshot.appendSections([.publicHoliday])
        snapshot.appendItems([.publicHolidayToggle(allowAction, publicHolidayStartIsEnabled)], toSection: .publicHoliday)
        if allowAction, publicHolidayStartIsEnabled {
            snapshot.appendItems([.publicHolidayFireTime(0)], toSection: .publicHoliday)
        }
        
        let customDayStartIsEnabled = manager.isEnabled(for: .customDay)
        snapshot.appendSections([.customDay])
        snapshot.appendItems([.customDayToggle(allowAction, customDayStartIsEnabled)], toSection: .customDay)
        if allowAction, customDayStartIsEnabled {
            snapshot.appendItems([.customDayFireTime(0)], toSection: .customDay)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func handle(authStatus: UNAuthorizationStatus) {
        switch authStatus {
        case .notDetermined:
            NotificationManager.shared.requestPermission()
        case .denied, .provisional, .ephemeral:
            jumpToSettings()
        case .authorized:
            break
        @unknown default:
            fatalError()
        }
    }
    
    func jumpToSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @objc
    func publicHolidayToggle(_ toggle: UISwitch) {
        NotificationManager.shared.set(isEnabled: toggle.isOn, for: .publicHoliday)
    }
    
    @objc
    func customDayToggle(_ toggle: UISwitch) {
        NotificationManager.shared.set(isEnabled: toggle.isOn, for: .customDay)
    }
    
    @objc
    func expiryToggle(_ toggle: UISwitch) {
        NotificationManager.shared.set(isEnabled: toggle.isOn, for: .templateExpiry)
    }
}

extension NotificationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .permission(let authStatus):
                handle(authStatus: authStatus)
            case .publicHolidayToggle:
                break
            case .publicHolidayFireTime:
                break
            case .customDayToggle:
                break
            case .customDayFireTime:
                break
            case .expireToggle:
                break
            case .expireFireTime:
                break
            }
        }
    }
}
