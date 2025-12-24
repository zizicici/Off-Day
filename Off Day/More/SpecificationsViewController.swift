//
//  SpecificationsViewController.swift
//  OffDay
//
//  Created by zici on 2023/8/3.
//

import UIKit
import SnapKit
import SafariServices

class SpecificationsViewController: UIViewController {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    enum Section: Int, Hashable {
        case summary
        case thirdParty
        
        func headerTitle() -> String? {
            switch self {
            case .summary:
                return nil
            case .thirdParty:
                return String(localized: "specifications.item.thirdParty.header", comment: "Third Party Framework")
            }
        }
        
        func footerTitle() -> String? {
            switch self {
            case .thirdParty:
                return String(localized: "specifications.item.thirdParty.footer", comment: "We extend our heartfelt appreciation to all developers of open-source projects.")
            default:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        enum SummaryType {
            case name
            case version
            case manufacturer
            case publisher
            case date
            case license
            
            var title: String {
                switch self {
                case .name:
                    return String(localized: "specifications.item.summary.name", comment: "Name")
                case .version:
                    return String(localized: "specifications.item.summary.version", comment: "Version")
                case .manufacturer:
                    return String(localized: "specifications.item.summary.manufacturer", comment: "Manufacturer")
                case .publisher:
                    return String(localized: "specifications.item.summary.publisher", comment: "Publisher")
                case .date:
                    return String(localized: "specifications.item.summary.dateOfProduction", comment: "Date of Production")
                case .license:
                    return String(localized: "specifications.item.summary.icp", comment: "ICP Filing Number")
                }
            }
            
            var value: String {
                switch self {
                case .name:
                    return SpecificationsViewController.getAppName() ?? ""
                case .version:
                    return SpecificationsViewController.getAppVersion() ?? ""
                case .manufacturer:
                    return "@App君"
                case .publisher:
                    return "ZIZICICI LIMITED"
                case .date:
                    return "2025/12/24"
                case .license:
                    return "闽ICP备2023015823号-8A"
                }
            }
        }
        
        struct ThirdParty: Hashable {
            let urlString: String
            let name: String
            let version: String
            
            static let current: [ThirdParty] = {
                let GRDB = ThirdParty(
                    urlString: "https://github.com/groue/GRDB.swift",
                    name: "GRDB",
                    version: "7.5.0"
                )
                let SnapKit = ThirdParty(
                    urlString: "https://github.com/SnapKit/SnapKit",
                    name: "SnapKit",
                    version: "5.7.1"
                )
                let Toast = ThirdParty(
                    urlString: "https://github.com/scalessec/Toast-Swift",
                    name: "Toast",
                    version: "5.1.1"
                )
                let MarqueeLabel = ThirdParty(
                    urlString: "https://github.com/cbpowell/MarqueeLabel",
                    name: "MarqueeLabel",
                    version: "4.5.0"
                )
                let ZipArchive = ThirdParty(
                    urlString: "https://github.com/ZipArchive/ZipArchive",
                    name: "ZipArchive",
                    version: "2.6.0"
                )
                return [SnapKit, GRDB, Toast, MarqueeLabel, ZipArchive]
            }()
        }
        
        case summary(SummaryType)
        case thirdParty(ThirdParty)
        
        func cellTitle() -> String? {
            switch self {
            case .summary(let item):
                return item.title
            case .thirdParty(let item):
                return item.name
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
        
        title = String(localized: "controller.specifications.title")
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = AppColor.background

        configureHierarchy()
        configureDataSource()
        
        loadData()
    }
    
    func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .secondarySystemBackground
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
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension SpecificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return }
        switch identifier {
        case .thirdParty(let item):
            if let url = URL(string: item.urlString) {
                openSF(with: url)
            }
        default:
            break
        }
    }
}

extension SpecificationsViewController {
    func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return nil }
            switch identifier {
            case .summary(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                var content = UIListContentConfiguration.valueCell()
                content.text = item.title
                content.textProperties.color = .label
                content.secondaryText = item.value
                cell.contentConfiguration = content
                cell.accessoryType = .none
                
                return cell
            case .thirdParty(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                var content = UIListContentConfiguration.valueCell()
                content.text = item.name
                content.textProperties.color = .label
                content.secondaryText = item.version
                cell.contentConfiguration = content
                cell.accessoryType = .disclosureIndicator
                
                return cell
            }
        }
    }
    
    func loadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        snapshot.appendSections([.summary])
        snapshot.appendItems([.summary(.name), .summary(.version), .summary(.manufacturer), .summary(.publisher), .summary(.date), .summary(.license)])
        
        snapshot.appendSections([.thirdParty])
        snapshot.appendItems(Item.ThirdParty.current.map{ Item.thirdParty($0) })
        
        dataSource.apply(snapshot)
    }
    
    static func getAppVersion() -> String? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }
        
        return version
    }
    
    static func getAppName() -> String? {
        if let appName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
            return appName
        } else if let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return appName
        }
        
        return nil
    }
}
