//
//  AppCell.swift
//  OffDay
//
//  Created by zici on 2023/8/10.
//

import UIKit
import SnapKit

enum App: Hashable {
    case lemon
    case moontake
    case coconut
    case festivals
    case pigeon
    case one
    
    var image: UIImage? {
        switch self {
        case .lemon:
            return UIImage(named: "LemonIcon")
        case .moontake:
            return UIImage(named: "MoontakeIcon")
        case .coconut:
            return UIImage(named: "CoconutIcon")
        case .festivals:
            return UIImage(named: "FestivalsIcon")
        case .pigeon:
            return UIImage(named: "PigeonIcon")
        case .one:
            return UIImage(named: "OneOneIcon")
        }
    }
    
    var name: String {
        switch self {
        case .lemon:
            return String(localized: "app.lemon.title", comment: "A Lemon Diary")
        case .moontake:
            return "moontake"
        case .coconut:
            return String(localized: "app.coconut.title", comment: "Calendar Island")
        case .festivals:
            return String(localized: "app.festivals.title", comment: "China Festivals")
        case .pigeon:
            return String(localized: "app.pigeon.title", comment: "Air Pigeon")
        case .one:
            return "1/1"
        }
    }
    
    var subtitle: String {
        switch self {
        case .lemon:
            return String(localized: "app.lemon.subtitle", comment: "A pure text diary")
        case .moontake:
            return String(localized: "app.moontake.subtitle", comment: "A camera for moon")
        case .coconut:
            return String(localized: "app.coconut.subtitle", comment: "Calendar + Dynamic Island")
        case .festivals:
            return String(localized: "app.festivals.subtitle", comment: "What festival is it today?")
        case .pigeon:
            return String(localized: "app.pigeon.subtitle", comment: "Focus Mode On")
        case .one:
            return String(localized: "app.one.subtitle", comment: "1/1")
        }
    }
    
    var storeId: String {
        switch self {
        case .lemon:
            return "id6449700998"
        case .moontake:
            return "id6451189717"
        case .coconut:
            return "id6469671638"
        case .festivals:
            return "id6460976841"
        case .pigeon:
            return "id6473819512"
        case .one:
            return "id6474681491"
        }
    }
}

class AppCell: UITableViewCell {
    private var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerCurve = .continuous
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    private var firstLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .natural
        label.textColor = .label
        label.numberOfLines = 1
        
        return label
    }()
    
    private var secondLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textAlignment = .natural
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(16)
            make.width.height.equalTo(50)
            make.centerY.equalTo(contentView)
        }
        
        contentView.addSubview(firstLabel)
        firstLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(16)
            make.trailing.equalTo(contentView).inset(16)
            make.top.equalTo(contentView).inset(12)
        }
        
        contentView.addSubview(secondLabel)
        secondLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(16)
            make.trailing.equalTo(contentView).inset(16)
            make.top.equalTo(firstLabel.snp.bottom).offset(10)
            make.bottom.equalTo(contentView).inset(12)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(_ app: App) {
        icon.image = app.image
        firstLabel.text = app.name
        secondLabel.text = app.subtitle
    }
}
