//
//  BatchEditorViewController.swift
//  Off Day
//
//  Created by Ci Zi on 24/4/25.
//

import UIKit
import SnapKit
import ZCCalendar
import OSLog

class BatchEditorViewController: UIViewController {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Hashable {
        case dayType
        case time
        
        var header: String? {
            switch self {
            case .dayType:
                return nil
            case .time:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .dayType:
                return String(localized: "batchEditor.section.dayType.footer")
            case .time:
                return String(localized: "batchEditor.section.time.footer")
            }
        }
    }
    
    enum Item: Hashable {
        case dayType(DayType?)
        case start(DateCellItem)
        case end(DateCellItem)
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
    
    enum PickerStatus: Hashable {
        case none
        case start
        case end
    }
    
    private var start: GregorianDay = ZCCalendar.manager.today
    private var end: GregorianDay = ZCCalendar.manager.today
    private var dayType: DayType? = nil {
        didSet {
            reloadData()
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("BatchEditorViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateNavigationBarStyle()
        view.backgroundColor = .secondarySystemGroupedBackground
        
        title = String(localized: "batchEditor.title")
        let saveItem = UIBarButtonItem(title: String(localized: "batchEditor.button.update"), style: .plain, target: self, action: #selector(showAlert))
        navigationItem.rightBarButtonItem = saveItem
        saveItem.isEnabled = false
        
        if navigationController?.viewControllers.count ?? 0 == 1 {
            let closeItem = UIBarButtonItem(title: String(localized: "batchEditor.button.cancel"), style: .plain, target: self, action: #selector(close))
            navigationItem.leftBarButtonItem = closeItem
        }

        configureHierarchy()
        configureDataSource()
        reloadData()
    }
    
    func saveAndClose() {
        guard allowSave() else {
            return
        }
        os_log("start")
        CustomDayManager.shared.update(dayType: dayType, from: start.julianDay, to: end.julianDay)
        os_log("end")
        close()
    }
    
    @objc
    func showAlert() {
        guard allowSave() else {
            return
        }
        let message: String
        if let dayType = dayType {
            message = String(format: String(localized: "batchEditor.alert.message.normal%@,%@,%@"), start.shortTitle(), end.shortTitle(), dayType.title)
        } else {
            message = String(format: String(localized: "batchEditor.alert.message.toBlank%@,%@"), start.shortTitle(), end.shortTitle())
        }
        let alertController = UIAlertController(title: String(localized: "batchEditor.alert.title"), message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "batchEditor.button.cancel"), style: .cancel) { _ in
            //
        }
        let confirmAction = UIAlertAction(title: String(localized: "batchEditor.button.confirm"), style: .destructive) { [weak self] _ in
            self?.saveAndClose()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    @objc
    func close() {
        dismiss(animated: ConsideringUser.animated)
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(DateCell.self, forCellReuseIdentifier: NSStringFromClass(DateCell.self))
        tableView.register(DayTypeCell.self, forCellReuseIdentifier: NSStringFromClass(DayTypeCell.self))
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
            case .start(let dateItem):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: dateItem)
                    cell.selectDateAction = { [weak self] date in
                        guard let self = self else { return }
                        let day = GregorianDay(from: date)
                        self.start = day
                        self.updateAddButtonStatus()
                    }
                }
                return cell
            case .end(let dateItem):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: dateItem)
                    cell.selectDateAction = { [weak self] date in
                        guard let self = self else { return }
                        let day = GregorianDay(from: date)
                        self.end = day
                        self.updateAddButtonStatus()
                    }
                }
                return cell
            case .dayType(let dayType):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DayTypeCell.self), for: indexPath)
                if let cell = cell as? DayTypeCell {
                    cell.update(with: dayType)
                    let noneAction = UIAction(title: String(localized: "dayType.none"), state: dayType == nil ? .on : .off) { [weak self] _ in
                        self?.dayType = nil
                    }
                    let actions = [DayType.offDay, DayType.workDay].map { target in
                        let action = UIAction(title: target.title, state: dayType == target ? .on : .off) { [weak self] _ in
                            self?.dayType = target
                        }
                        return action
                    }
                    let divider = UIMenu(title: "", options: . displayInline, children: actions)
                    let menu = UIMenu(children: [noneAction, divider])
                    cell.tapButton.menu = menu
                }
                return cell
            }
        }
    }
    
    func reloadData(preferrScrollPicker: Bool = false) {
        updateAddButtonStatus()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.dayType])
        snapshot.appendItems([.dayType(dayType)], toSection: .dayType)
        snapshot.appendSections([.time])
        snapshot.appendItems([.start(DateCellItem(title: String(localized: "batchEditor.cell.start"), date: start))], toSection: .time)
        snapshot.appendItems([.end(DateCellItem(title: String(localized: "batchEditor.cell.end"), date: end))], toSection: .time)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func allowSave() -> Bool {
        let startEndValid = start <= end
        let dayLengthValid = (end - start) <= 1000
        return startEndValid && dayLengthValid
    }
    
    func updateAddButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
}

extension BatchEditorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
