//
//  DayEditorViewController.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/23.
//

import UIKit
import SnapKit
import ZCCalendar

class DayEditorViewController: UIViewController {
    private var comment: CustomComment!
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Int, Hashable {
        case comment
        
        var header: String? {
            switch self {
            case .comment:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .comment:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case comment(String)
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
    
    enum EditMode {
        case comment
        case time
    }
    
    private var editMode: EditMode = .comment
    
    private var isEdited: Bool = false
    
    private var content: String {
        get {
            return comment.content
        }
        set {
            if comment.content != newValue {
                comment.content = newValue
                isEdited = true
                updateSaveButtonStatus()
            }
        }
    }
    
    weak var commentCell: TextViewCell?
    
    private var day: GregorianDay {
        return GregorianDay(JDN: Int(comment.dayIndex))
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(comment: CustomComment) {
        self.init()
        self.comment = comment
    }
    
    deinit {
        print("DayEditorViewController is deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.background
        navigationController?.navigationBar.tintColor = AppColor.offDay
        
        self.title = String(localized: "dayEditor.comment")
        
        let saveItem = UIBarButtonItem(title: String(localized: "button.save"), style: .done, target: self, action: #selector(save))
        saveItem.isEnabled = false
        navigationItem.rightBarButtonItem = saveItem
        
        let closeItem = UIBarButtonItem(title: String(localized: "button.close"), style: .plain, target: self, action: #selector(dismissViewController))
        navigationItem.leftBarButtonItem = closeItem
        
        configureHierarchy()
        configureDataSource()
        reloadData()
    }
    
    func configureHierarchy() {
        tableView = UIDraggableTableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(TextViewCell.self, forCellReuseIdentifier: NSStringFromClass(TextViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50.0
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: -20.0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .comment(let content):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TextViewCell.self), for: indexPath)
                if let cell = cell as? TextViewCell {
                    cell.tintColor = AppColor.offDay
                    cell.update(text: content, placeholder: String(localized: "dayEditor.placeholder.comment"))
                    cell.textDidChanged = { [weak self] text in
                        self?.content = text
                    }
                    self.commentCell = cell
                }
                return cell
            }
        }
    }
    
    func reloadData() {
        updateSaveButtonStatus()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.comment])
        snapshot.appendItems([.comment(content)], toSection: .comment)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc
    func save() {
        let result: Bool
        if isNewMode() {
            if comment.content.count == 0 {
                // Do nothing
                result = true
            } else {
                result = AppDatabase.shared.add(customComment: comment)
            }
        } else {
            if comment.content.count == 0 {
                // Delete
                result = AppDatabase.shared.delete(customComment: comment)
            } else {
                result = AppDatabase.shared.update(customComment: comment)
            }
        }
        if result {
            dismissViewController()
        }
    }
    
    func isNewMode() -> Bool {
        return comment.id == nil
    }
    
    @objc
    func dismissViewController() {
        if commentCell?.isFirstResponder == true {
            _ = commentCell?.resignFirstResponder()
            navigationItem.rightBarButtonItem?.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.7) {
                self.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    func updateSaveButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = allowSave()
    }
    
    func allowSave() -> Bool {
        if isNewMode() {
            return comment.content.isValidComment() && comment.content.count > 0
        } else {
            return comment.content.isValidComment()
        }
    }
}


extension DayEditorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension String {
    func isValidComment() -> Bool{
        return count <= 200
    }
}

