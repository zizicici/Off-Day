//
//  BackupViewController.swift
//  Off Day
//
//  Created by Ci Zi on 2025/7/7.
//

import Foundation
import UIKit
import SnapKit
import UniformTypeIdentifiers
import ZipArchive
import Toast
import ZCCalendar

class BackupViewController: UIViewController {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Int, Hashable {
        case autoBackup
        case summary
        case database
        
        func headerTitle() -> String? {
            switch self {
            case .autoBackup:
                return ""
            case .summary:
                return String(localized: "backup.section.summary.title", comment: "iCloud Backup Summary")
            case .database:
                return String(localized: "backup.section.database.title", comment: "Database")
            }
        }
        
        func footerTitle() -> String? {
            switch self {
            case .autoBackup:
                let footer = String(localized: "backup.section.toggle.hint")
                
                var addition: String = ""
                
                if !BackupManager.shared.iCloudDocumentIsAccessable {
                    addition += String(localized: "backup.section.toggle.hint2", comment: "") + "\n"
                }
                
                return addition + footer
            case .summary:
                return nil
            case .database:
                return String(localized: "backup.section.database.hint", comment: "Importing the database will delete all existing data.")
            }
        }
    }
    
    enum Item: Hashable {
        enum AutoActionType {
            case `switch`
        }
        
        enum StatusActionType: Hashable {
            case latest(Date?)
            case folderName(String)
            case backupNow
        }
        
        enum DatabaseActionType {
            case export
            case `import`
        }
        
        case autoUpdate(AutoActionType)
        case status(StatusActionType)
        case database(DatabaseActionType)
        
        func cellTitle() -> String {
            switch self {
            case .autoUpdate(let action):
                switch action {
                case .switch:
                    return String(localized: "backup.item.switch", comment: "Auto Backup")
                }
            case .status(let action):
                switch action {
                case .latest:
                    return String(localized: "backup.item.status.latest", comment: "Latest Backup")
                case .backupNow:
                    return String(localized: "backup.item.status.backupNow", comment: "Backup Now")
                case .folderName:
                    return String(localized: "backup.item.status.folderName", comment: "Folder Name")
                }
            case .database(let action):
                switch action {
                case .export:
                    return String(localized: "backup.item.database.export", comment: "Export Database File")
                case .import:
                    return String(localized: "backup.item.database.import", comment: "Import Database File")
                }
            }
        }
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let sectionKind = Section(rawValue: section)
            return sectionKind?.headerTitle()
        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            let sectionKind = Section(rawValue: section)
            return sectionKind?.footerTitle()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String(localized: "backup.title")
        
        view.backgroundColor = AppColor.background
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)
            make.bottom.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .autoUpdate(let action):
                switch action {
                case .switch:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                    let itemSwitch = UISwitch()
                    let isEnable = BackupManager.shared.allowAutoBackup
                    let isAutoUpdate = (AutoBackup.getValue() == .enable) && isEnable
                    itemSwitch.isEnabled = isEnable
                    itemSwitch.isOn = isAutoUpdate
                    itemSwitch.addTarget(self, action: #selector(self.toggle(_:)), for: .touchUpInside)
                    itemSwitch.onTintColor = AppColor.offDay
                    var content = cell.defaultContentConfiguration()
                    content.text = identifier.cellTitle()
                    content.textProperties.color = .label
                    cell.accessoryView = itemSwitch
                    cell.contentConfiguration = content
                    return cell
                }
            case .status(let action):
                switch action {
                case .latest(let time):
                    let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                    var content = UIListContentConfiguration.valueCell()
                    content.text = identifier.cellTitle()
                    content.textProperties.color = .label
                    content.secondaryText = time?.formatted() ?? String(localized: "backup.history.none")
                    cell.contentConfiguration = content
                    cell.accessoryType = .none
                    return cell
                case .folderName(let name):
                    let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                    var content = UIListContentConfiguration.valueCell()
                    content.text = identifier.cellTitle()
                    content.textProperties.color = .label
                    content.secondaryText = name
                    cell.contentConfiguration = content
                    cell.accessoryType = .disclosureIndicator
                    return cell
                case .backupNow:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                    var content = cell.defaultContentConfiguration()
                    content.text = identifier.cellTitle()
                    if BackupManager.shared.iCloudDocumentIsAccessable {
                        content.textProperties.color = AppColor.offDay
                    } else {
                        content.textProperties.color = .secondaryLabel
                    }
                    cell.contentConfiguration = content
                    return cell
                }
            case .database:
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                var content = cell.defaultContentConfiguration()
                content.text = identifier.cellTitle()
                content.textProperties.color = AppColor.offDay
                cell.contentConfiguration = content
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.autoBackup])
        snapshot.appendItems([.autoUpdate(.switch)])
        snapshot.appendSections([.summary])
        let latestTime = BackupManager.shared.getLatestiCloudBackupDate()
        let folderName = BackupManager.shared.getFolderName()
        snapshot.appendItems([.status(.folderName(folderName)), .status(.latest(latestTime)), .status(.backupNow)])
        snapshot.appendSections([.database])
        snapshot.appendItems([.database(.export), .database(.import)])
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc
    func toggle(_ autoSwitch: UISwitch) {
        if autoSwitch.isOn {
            AutoBackup.setValue(.enable)
        } else {
            AutoBackup.setValue(.disable)
        }
    }
    
    func updateFolderName(name: String) {
        guard !name.isEmpty, !name.isBlank else {
            return
        }
        if let encodingName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            BackupManager.shared.set(folderName: encodingName)
            reloadData()
        }
    }
}

extension BackupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return }
        switch identifier {
        case .autoUpdate(_):
            break
        case .status(let action):
            switch action {
            case .latest:
                break
            case .folderName:
                let alertController = UIAlertController(title: String(localized: "backup.alert.folderName.title", comment: "Enter Folder Name"), message: String(localized: "backup.alert.folderName.message", comment: "It is recommended to input Arabic numerals or English letters."), preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.placeholder = ""
                    textField.text = BackupManager.shared.getFolderName()
                }
                let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel) { _ in
                    //
                }
                let okAction = UIAlertAction(title: String(localized: "button.ok"), style: .default) { [weak self] _ in
                    if let text = alertController.textFields?.first?.text {
                        self?.updateFolderName(name: text)
                    } else {
                        //
                    }
                }

                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: ConsideringUser.animated, completion: nil)
            case .backupNow:
                let result = BackupManager.shared.backup(overwrite: true)
                if result {
                    self.view.makeToast(String(localized: "backup.alert.result.success", comment: "Operation completed"), position: .center)
                } else {
                    self.view.makeToast(String(localized: "backup.alert.result.failed", comment: "Operation failed"), position: .center)
                }
                reloadData()
            }
        case .database(let action):
            switch action {
            case .import:
                let alertController = UIAlertController(title: nil, message: String(localized: "backup.alert.import.title", comment: "Importing the database will delete all existing data."), preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: String(localized: "button.cancel"), style: .cancel) { _ in
                    //
                }
                let okAction = UIAlertAction(title: String(localized: "button.ok"), style: .default) { [weak self] _ in
                    self?.importDatabaseAction()
                }

                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                present(alertController, animated: ConsideringUser.animated, completion: nil)
            case .export:
                exportDatabaseAction()
            }
        }
    }
}

extension BackupViewController {
    @objc
    func exportDatabaseAction() {
        if let path = AppDatabase.shared.backupToTempPath() {
            let url = URL(fileURLWithPath: path)
            showActivityController(url: url)
        }
    }
    
    @objc
    func importDatabaseAction() {
        var types: [UTType] = [.zip]
        if let sqliteType = UTType(filenameExtension: "sqlite") {
            types.append(sqliteType)
        }
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: types)
        documentPickerViewController.allowsMultipleSelection = false
        documentPickerViewController.shouldShowFileExtensions = true
        documentPickerViewController.delegate = self
        present(documentPickerViewController, animated: ConsideringUser.animated)
    }
    
    func pick(file: URL) {
        switch file.pathExtension {
        case "zip", "sqlite":
            AppDatabase.shared.importDatabase(file)
        default:
            break
        }
    }
}

extension BackupViewController {
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
        
        present(controller, animated: ConsideringUser.animated)
    }
}

extension BackupViewController: UIDocumentPickerDelegate {
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
            self?.pick(file: url)
            
            pickedURL.stopAccessingSecurityScopedResource()
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("documentPickerWasCancelled")
    }
}

extension String {
    var isBlank: Bool {
        return allSatisfy({ $0.isWhitespace })
    }
}

extension Optional where Wrapped == String {
    var isBlank: Bool {
        return self?.isBlank ?? true
    }
}
