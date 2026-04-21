//
//  LogViewController.swift
//  Off Day
//
//  Created by zici on 20/4/26.
//

import UIKit

final class LogViewController: UIViewController {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    private var emptyLabel: UILabel!
    private var reloadWorkItem: DispatchWorkItem?
    private var hasPendingReload = false

    enum Section: Int, Hashable {
        case today
        case yesterday
        case thisWeek
        case earlier

        var header: String {
            switch self {
            case .today: return String(localized: "log.section.today")
            case .yesterday: return String(localized: "log.section.yesterday")
            case .thisWeek: return String(localized: "log.section.thisWeek")
            case .earlier: return String(localized: "log.section.earlier")
            }
        }
    }

    final class DataSource: UITableViewDiffableDataSource<Section, AppLog> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            sectionIdentifier(for: section)?.header
        }
    }

    // MARK: - Lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        tabBarItem = UITabBarItem(
            title: String(localized: "controller.log.title"),
            image: UIImage(systemName: "doc.text.magnifyingglass"),
            tag: 3
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        title = String(localized: "controller.log.title")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: makeMoreMenu()
        )
        configureHierarchy()
        setupEmptyLabel()
        configureDataSource()
        reload()

        NotificationCenter.default.addObserver(
            self, selector: #selector(scheduleReload),
            name: .AppLogAdded, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(scheduleReload),
            name: .AppLogCleared, object: nil
        )
    }

    deinit {
        reloadWorkItem?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasPendingReload {
            reloadWorkItem?.cancel()
            reload()
        }
    }

    // MARK: - Setup

    private func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppColor.background
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        tableView.register(LogCell.self, forCellReuseIdentifier: LogCell.reuseID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = String(localized: "log.empty.message")
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { tableView, indexPath, log in
            let cell = tableView.dequeueReusableCell(withIdentifier: LogCell.reuseID, for: indexPath) as! LogCell
            cell.configure(with: log)
            return cell
        }
    }

    // MARK: - Data

    @objc private func scheduleReload() {
        guard isViewLoaded, view.window != nil else {
            hasPendingReload = true
            return
        }
        reloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: work)
    }

    @objc private func reload() {
        hasPendingReload = false
        let logs = AppDatabase.shared.fetchAppLogs(limit: 500)
        applySnapshot(logs: logs)
        let isEmpty = logs.isEmpty
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
    }

    private func applySnapshot(logs: [AppLog]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, AppLog>()

        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let startOfYesterday = cal.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfWeek = cal.date(byAdding: .day, value: -7, to: startOfToday)!

        var buckets: [Section: [AppLog]] = [:]
        for log in logs {
            let date = log.creationDate
            let section: Section
            if date >= startOfToday {
                section = .today
            } else if date >= startOfYesterday {
                section = .yesterday
            } else if date >= startOfWeek {
                section = .thisWeek
            } else {
                section = .earlier
            }
            buckets[section, default: []].append(log)
        }

        for section in [Section.today, .yesterday, .thisWeek, .earlier] {
            guard let items = buckets[section], !items.isEmpty else { continue }
            snapshot.appendSections([section])
            snapshot.appendItems(items, toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Menu

    private func makeMoreMenu() -> UIMenu {
        let clear = UIAction(
            title: String(localized: "log.menu.clearAll"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.promptClear()
        }
        return UIMenu(children: [clear])
    }

    private func promptClear() {
        let alert = UIAlertController(
            title: String(localized: "log.clear.title"),
            message: String(localized: "log.clear.message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: String(localized: "log.clear.confirm"),
            style: .destructive
        ) { _ in
            AppDatabase.shared.deleteAllAppLogs()
        })
        alert.addAction(UIAlertAction(
            title: String(localized: "log.clear.cancel"),
            style: .cancel
        ))
        present(alert, animated: true)
    }
}

extension LogViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let log = dataSource.itemIdentifier(for: indexPath) else { return }
        let detail = LogDetailViewController(log: log)
        navigationController?.pushViewController(detail, animated: true)
    }
}
