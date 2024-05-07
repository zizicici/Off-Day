//
//  SettingOptionsViewController.swift
//  Off Day
//
//  Created by zici on 7/5/24.
//

import UIKit

class SettingOptionsViewController<T: SettingsOption>: UIViewController, UITableViewDelegate {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Hashable {
        case main
        
        var header: String? {
            return T.getHeader()
        }
        
        var footer: String? {
            return T.getFooter()
        }
    }
    
    enum Item: Hashable {
        case option(T, Bool)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = T.getTitle()
        
        view.backgroundColor = AppColor.background
        navigationItem.largeTitleDisplayMode = .never
        
        configureHierarchy()
        configureDataSource()
        reloadData()
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
            make.edges.equalTo(view)
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .option(let item, let isSelected):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = isSelected ? .checkmark : .none
                cell.tintColor = AppColor.offDay
                var content = UIListContentConfiguration.valueCell()
                content.text = item.getName()
                content.textProperties.color = .label
                cell.contentConfiguration = content
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        
        let currentOption = T.current
        let options: [T] = T.getOptions()
        snapshot.appendItems(options.map{ Item.option($0, $0 == currentOption) })
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return }
        switch identifier {
        case .option(let item, _):
            T.current = item
        }
        
        self.reloadData()
    }
}
