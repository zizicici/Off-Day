//
//  LogCell.swift
//  Off Day
//
//  Created by zici on 20/4/26.
//

import UIKit

final class LogCell: UITableViewCell {
    static let reuseID = "LogCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusDot = UIView()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        accessoryType = .disclosureIndicator

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel
        contentView.addSubview(iconView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        contentView.addSubview(subtitleLabel)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .preferredFont(forTextStyle: .caption2)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .tertiaryLabel
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(timeLabel)

        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.layer.cornerRadius = 4
        statusDot.backgroundColor = .systemRed
        statusDot.isHidden = true
        contentView.addSubview(statusDot)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusDot.leadingAnchor, constant: -6),

            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),
            statusDot.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            statusDot.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -6),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    func configure(with log: AppLog) {
        switch log.category {
        case .intent:
            iconView.image = UIImage(systemName: "square.stack.3d.up.fill")
        case .subscription:
            iconView.image = UIImage(systemName: "arrow.clockwise")
        }
        titleLabel.text = log.displayTitle
        subtitleLabel.text = summary(for: log)
        timeLabel.text = Self.relativeFormatter.localizedString(for: log.creationDate, relativeTo: Date())
        statusDot.isHidden = log.success
    }

    private func summary(for log: AppLog) -> String? {
        if !log.success, let error = log.errorMessage {
            return error
        }
        switch log.category {
        case .intent:
            return log.outputJSON.map { collapse($0) }
        case .subscription:
            if let json = log.outputJSON,
               let data = json.data(using: .utf8),
               let parsed = try? JSONDecoder().decode(SubscriptionLogOutput.self, from: data) {
                let total = parsed.added.count + parsed.removed.count + parsed.modified.count
                let dayPart = total == 0 ? nil : "+\(parsed.added.count) −\(parsed.removed.count) ~\(parsed.modified.count)"
                let metadata = parsed.metadataChanges ?? []
                let metaPart = metadata.isEmpty ? nil : String(
                    format: String(localized: "log.summary.metadataChanges"),
                    metadata.joined(separator: ", ")
                )
                switch (dayPart, metaPart) {
                case (nil, nil): return String(localized: "log.summary.noChanges")
                case (let d?, nil): return d
                case (nil, let m?): return m
                case (let d?, let m?): return "\(d) · \(m)"
                }
            }
            return log.inputJSON.map { collapse($0) }
        }
    }

    private func collapse(_ json: String) -> String {
        let cleaned = json
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        if cleaned.count > 120 {
            return String(cleaned.prefix(120)) + "…"
        }
        return cleaned
    }
}
