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
        case templateToggle(Bool, Bool)
        case templateFireTime(Int64)
        case publicHolidayToggle(Bool, Bool)
        case publicHolidayFireTime(Int64)
        case customDayToggle(Bool, Bool)
        case customDayFireTime(Int64)
        
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
            case .templateToggle:
                return String(localized: "notificationEditor.template.toggle")
            case .templateFireTime:
                return String(localized: "notificationEditor.template.fireTime")
            case .publicHolidayToggle:
                return String(localized: "notificationEditor.publicHoliday.toggle")
            case .publicHolidayFireTime:
                return String(localized: "notificationEditor.publicHoliday.fireTime")
            case .customDayToggle:
                return String(localized: "notificationEditor.customDay.toggle")
            case .customDayFireTime:
                return String(localized: "notificationEditor.customDay.fireTime")
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
        
        NotificationCenter.default.addObserver(forName: .DatabaseUpdated, object: nil, queue: .main) { [weak self] _ in
            self?.reloadData()
        }
        NotificationCenter.default.addObserver(forName: .NotificationPermissionUpdated, object: nil, queue: .main) { [weak self] _ in
            self?.reloadData()
        }
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
                    let timeZoneSeconds = Int64(Calendar.current.timeZone.secondsFromGMT() * 1000)
                    cell.update(with: DateCellItem(title: identifier.title ?? "", nanoSecondsFrom1970: fireTime - timeZoneSeconds, mode: .time))
                    cell.selectDateAction = { nanoSeconds in
                        var appConfig = AppConfiguration.get()
                        appConfig.publicDayNanoseconds = timeZoneSeconds + nanoSeconds
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
                    let timeZoneSeconds = Int64(Calendar.current.timeZone.secondsFromGMT() * 1000)
                    cell.update(with: DateCellItem(title: identifier.title ?? "", nanoSecondsFrom1970: fireTime - timeZoneSeconds, mode: .time))
                    cell.selectDateAction = { nanoSeconds in
                        var appConfig = AppConfiguration.get()
                        appConfig.customDayNanoseconds = timeZoneSeconds + nanoSeconds
                    }
                }
                return cell
            case .templateToggle(let isEnabled, let isOn):
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
            case .templateFireTime(let fireTime):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    let timeZoneSeconds = Int64(Calendar.current.timeZone.secondsFromGMT() * 1000)
                    cell.update(with: DateCellItem(title: identifier.title ?? "", nanoSecondsFrom1970: fireTime - timeZoneSeconds, mode: .time))
                    cell.selectDateAction = { nanoSeconds in
                        var appConfig = AppConfiguration.get()
                        appConfig.templateNanoseconds = timeZoneSeconds + nanoSeconds
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
        
        let appConfig = AppConfiguration.get()
        let isTemplateNotificationEnabled = appConfig.isTemplateNotificationEnabled
        snapshot.appendSections([.template])
        snapshot.appendItems([.templateToggle(allowAction, isTemplateNotificationEnabled)], toSection: .template)
        if allowAction, isTemplateNotificationEnabled {
            snapshot.appendItems([.templateFireTime(appConfig.templateNanoseconds)], toSection: .template)
        }
        
        let publicHolidayStartIsEnabled = appConfig.isPublicDayNotificationEnabled
        snapshot.appendSections([.publicHoliday])
        snapshot.appendItems([.publicHolidayToggle(allowAction, publicHolidayStartIsEnabled)], toSection: .publicHoliday)
        if allowAction, publicHolidayStartIsEnabled {
            snapshot.appendItems([.publicHolidayFireTime(appConfig.publicDayNanoseconds)], toSection: .publicHoliday)
        }
        
        let customDayStartIsEnabled = appConfig.isCustomDayNotificationEnabled
        snapshot.appendSections([.customDay])
        snapshot.appendItems([.customDayToggle(allowAction, customDayStartIsEnabled)], toSection: .customDay)
        if allowAction, customDayStartIsEnabled {
            snapshot.appendItems([.customDayFireTime(appConfig.customDayNanoseconds)], toSection: .customDay)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func handle(authStatus: UNAuthorizationStatus) {
        switch authStatus {
        case .notDetermined:
            NotificationManager.shared.requestPermission(completion: nil)
        case .denied, .provisional, .ephemeral:
            jumpToSettings()
        case .authorized:
            break
        @unknown default:
            fatalError()
        }
    }
    
    @objc
    func publicHolidayToggle(_ toggle: UISwitch) {
        var appConfig = AppConfiguration.get()
        appConfig.isPublicDayNotificationEnabled = toggle.isOn
    }
    
    @objc
    func customDayToggle(_ toggle: UISwitch) {
        var appConfig = AppConfiguration.get()
        appConfig.isCustomDayNotificationEnabled = toggle.isOn
    }
    
    @objc
    func expiryToggle(_ toggle: UISwitch) {
        var appConfig = AppConfiguration.get()
        appConfig.isTemplateNotificationEnabled = toggle.isOn
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
            case .templateToggle:
                break
            case .templateFireTime:
                break
            }
        }
    }
}
