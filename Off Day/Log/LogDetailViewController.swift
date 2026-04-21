//
//  LogDetailViewController.swift
//  Off Day
//
//  Created by zici on 20/4/26.
//

import UIKit

final class LogDetailViewController: UIViewController {
    private let log: AppLog
    private var tableView: UITableView!
    private var dataSource: DataSource!

    enum Section: Hashable {
        case type
        case status
        case timestamp
        case input
        case output(showDayTypeHint: Bool)
        case error

        var header: String {
            switch self {
            case .type: return String(localized: "log.detail.type")
            case .status: return String(localized: "log.detail.status")
            case .timestamp: return String(localized: "log.detail.timestamp")
            case .input: return String(localized: "log.detail.input")
            case .output: return String(localized: "log.detail.output")
            case .error: return String(localized: "log.detail.error")
            }
        }

        var footer: String? {
            if case .output(let showHint) = self, showHint {
                return String(localized: "log.detail.output.dayTypeHint")
            }
            return nil
        }
    }

    enum Item: Hashable {
        case keyValue(Section, value: String)
        case code(Section, value: String)

        var section: Section {
            switch self {
            case .keyValue(let section, _), .code(let section, _):
                return section
            }
        }

        var value: String {
            switch self {
            case .keyValue(_, let v), .code(_, let v):
                return v
            }
        }
    }

    final class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            sectionIdentifier(for: section)?.header
        }

        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            sectionIdentifier(for: section)?.footer
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()

    private static func prettyPrint(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]),
              let output = String(data: pretty, encoding: .utf8) else {
            return jsonString
        }
        return output
    }

    init(log: AppLog) {
        self.log = log
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        title = log.displayTitle

        configureHierarchy()
        configureDataSource()
        applySnapshot()
    }

    private func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppColor.background
        tableView.delegate = self
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "kv")
        tableView.register(CodeCell.self, forCellReuseIdentifier: CodeCell.reuseID)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .keyValue(_, let value):
                let cell = tableView.dequeueReusableCell(withIdentifier: "kv", for: indexPath)
                var config = UIListContentConfiguration.valueCell()
                config.text = value
                cell.contentConfiguration = config
                cell.selectionStyle = .none
                return cell
            case .code(_, let value):
                let cell = tableView.dequeueReusableCell(withIdentifier: CodeCell.reuseID, for: indexPath) as! CodeCell
                cell.setText(value)
                return cell
            }
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        let typeLabel: String
        switch log.category {
        case .intent: typeLabel = String(localized: "log.detail.type.intent")
        case .subscription: typeLabel = String(localized: "log.detail.type.subscription")
        }
        snapshot.appendSections([.type])
        snapshot.appendItems([.keyValue(.type, value: typeLabel)], toSection: .type)

        snapshot.appendSections([.status])
        let statusValue = log.success
            ? String(localized: "log.status.success")
            : String(localized: "log.status.failure")
        snapshot.appendItems([.keyValue(.status, value: statusValue)], toSection: .status)

        snapshot.appendSections([.timestamp])
        snapshot.appendItems([.keyValue(.timestamp, value: Self.dateFormatter.string(from: log.creationDate))], toSection: .timestamp)

        if let input = log.inputJSON, !input.isEmpty {
            snapshot.appendSections([.input])
            snapshot.appendItems([.code(.input, value: Self.prettyPrint(input))], toSection: .input)
        }

        if let output = log.outputJSON, !output.isEmpty {
            let section: Section = .output(showDayTypeHint: log.category == .subscription)
            snapshot.appendSections([section])
            snapshot.appendItems([.code(section, value: Self.prettyPrint(output))], toSection: section)
        }

        if let error = log.errorMessage, !error.isEmpty {
            snapshot.appendSections([.error])
            snapshot.appendItems([.code(.error, value: error)], toSection: .error)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension LogDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let text = item.value
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copy = UIAction(
                title: String(localized: "log.detail.copy"),
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                UIPasteboard.general.string = text
            }
            return UIMenu(title: "", children: [copy])
        }
    }
}

private final class CodeCell: UITableViewCell {
    static let reuseID = "CodeCell"

    private let textView = UITextView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        contentView.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String) {
        textView.text = text
    }
}
