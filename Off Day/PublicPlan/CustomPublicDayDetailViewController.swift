//
//  PublicDayDetailViewController.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import UIKit
import SnapKit
import ZCCalendar

class CustomPublicDayDetailViewController: UIViewController {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    private var day: CustomPublicDay!
    private var editMode: EditMode = .add
    private var titleCell: TextInputCell?
    private var saveBarItem: UIBarButtonItem?
    
    var saveClosure: ((CustomPublicDay?) -> (Bool))?
    
    enum EditMode {
        case add
        case update
    }
    
    enum Section: Hashable {
        case main
        case action
    }
    
    enum Item: Hashable {
        case title(String)
        case date(GregorianDay)
        case type(DayType)
        case delete
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
    }
    
    convenience init(day: CustomPublicDay?, saveClosure: @escaping (CustomPublicDay?) -> (Bool)) {
        self.init(nibName: nil, bundle: nil)
        self.editMode = (day == nil) ? .add : .update
        self.saveClosure = saveClosure
        self.day = day ?? CustomPublicDay(name: "", date: ZCCalendar.manager.today, type: .offDay)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateNavigationBarStyle()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "publicDay.cancel.title"), style: .plain, target: self, action: #selector(dismissAction))
        switch editMode {
        case .add:
            self.title = String(localized: "publicDay.editor.title.add")
            let item = UIBarButtonItem(title: String(localized: "publicDay.editor.add.title"), style: .plain, target: self, action: #selector(saveAction))
            self.saveBarItem = item
            navigationItem.rightBarButtonItem = item
        case .update:
            self.title = String(localized: "publicDay.editor.title.update")
            let item = UIBarButtonItem(title: String(localized: "publicDay.editor.update.title"), style: .plain, target: self, action: #selector(saveAction))
            self.saveBarItem = item
            navigationItem.rightBarButtonItem = item
        }
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        updateSaveBarItem()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) { [weak self] in
            if self?.day.name.count == 0 {
                _ = self?.titleCell?.becomeFirstResponder()
            }
        }
    }
    
    deinit {
        print("CustomPublicDayDetailViewController is deinited")
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
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.register(TextInputCell.self, forCellReuseIdentifier: NSStringFromClass(TextInputCell.self))
        tableView.register(MenuCell.self, forCellReuseIdentifier: NSStringFromClass(MenuCell.self))
        tableView.register(DateCell.self, forCellReuseIdentifier: NSStringFromClass(DateCell.self))
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
            case .title(let title):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextInputCell.self), for: indexPath)
                if let cell = cell as? TextInputCell {
                    self.titleCell = cell
                    cell.update(text: title, placeholder: String(localized: "publicDay.detail.title.placeholder"))
                    cell.textDidChanged = { [weak self] text in
                        self?.day.name = text
                        self?.updateSaveBarItem()
                    }
                }
                return cell
            case .date(let day):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: String(localized: "publicDay.detail.date"), day: day, mode: .date))
                    cell.selectDateAction = { [weak self] nanoSeconds in
                        guard let self = self else { return }
                        let date = Date(nanoSecondSince1970: nanoSeconds)
                        let day = GregorianDay(from: date)
                        self.day.date = day
                    }
                }
                return cell
            case .type(let type):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MenuCell.self), for: indexPath)
                if let cell = cell as? MenuCell {
                    cell.update(with: MenuCellItem(title: String(localized: "publicDay.detail.type"), value: type.title))
                    let actions = [DayType.offDay, DayType.workDay].map { target in
                        let action = UIAction(title: target.title, state: type == target ? .on : .off) { [weak self] _ in
                            self?.day.type = target
                            self?.reloadData()
                        }
                        return action
                    }
                    let menu = UIMenu(children: actions)
                    cell.tapButton.menu = menu
                }
                return cell
            case .delete:
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
                var content = UIListContentConfiguration.cell()
                content.text = String(localized: "publicDay.detail.delete")
                content.textProperties.color = .systemRed
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
                return cell
            }
        }
    }
    
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.title(day.name), .date(day.date), .type(day.type)], toSection: .main)
        
        switch editMode {
        case .add:
            break
        case .update:
            snapshot.appendSections([.action])
            snapshot.appendItems([.delete], toSection: .action)
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc
    func dismissAction() {
        dismiss(animated: ConsideringUser.animated)
    }
    
    @objc
    func saveAction() {
        if saveClosure?(day) == true {
            dismissAction()
        } else {
            showDuplicatedAlert()
        }
    }
    
    func deleteAction() {
        if saveClosure?(nil) == true {
            dismissAction()
        }
    }
    
    func showDuplicatedAlert() {
        let alertController = UIAlertController(title: String(localized: "publicDay.alert.duplicate.title"), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicDay.alert.duplicate.cancel"), style: .cancel) { _ in
            //
        }

        alertController.addAction(cancelAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    func showDeleteAlert() {
        let alertController = UIAlertController(title: String(localized: "publicDay.alert.delete.title"), message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String(localized: "publicDay.alert.delete.cancel"), style: .cancel) { _ in
            //
        }
        let deleteAction = UIAlertAction(title: String(localized: "publicDay.alert.delete.confirm"), style: .destructive) { [weak self] _ in
            self?.deleteAction()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: ConsideringUser.animated, completion: nil)
    }
    
    func updateSaveBarItem() {
        saveBarItem?.isEnabled = day.allowSave()
    }
}

extension CustomPublicDayDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath) {
            switch item {
            case .title(_):
                break
            case .date(_):
                break
            case .type(_):
                break
            case .delete:
                showDeleteAlert()
            }
        }
    }
}
