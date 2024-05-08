//
//  BasicCalendarEditorViewController.swift
//  Off Day
//
//  Created by zici on 8/5/24.
//

import UIKit
import SnapKit
import ZCCalendar

extension BasicCalendarType {
    var title: String {
        switch self {
        case .standard:
            return String(localized: "basicCalendar.type.standard")
        case .weeksCircle:
            return String(localized: "basicCalendar.type.weeks")
        case .daysCircle:
            return String(localized: "basicCalendar.type.days")
        }
    }
}

class BasicCalendarEditorViewController: UIViewController, UITableViewDelegate {
    private var tableView: UITableView!
    private var dataSource: DataSource!
    
    private var selectedConfig: BasicCalendarManager.Config!
    
    enum Section: Hashable {
        case main
        case standardConfig
        case weeksCircleConfig
        case daysCircleConfig
        
        var header: String? {
            switch self {
            case .main:
                return String(localized: "basicCalendar.main.header")
            case .standardConfig:
                return nil
            case .weeksCircleConfig:
                return nil
            case .daysCircleConfig:
                return nil
            }
        }
        
        var footer: String? {
            switch self {
            case .main:
                return nil
            case .standardConfig:
                return String(localized: "basicCalendar.standard.footer")
            case .weeksCircleConfig:
                return String(localized: "basicCalendar.standard.footer")
            case .daysCircleConfig:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case calendarType(BasicCalendarType, Bool)
        case stadardConfig([WeekdayOrder])
        case weekCount(WeekCount)
        case weekCalendar(WeeksCircleConfig)
        case date(GregorianDay)
        case workCount(Int)
        case offCount(Int)
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
        
        self.title = String(localized: "controller.basicCalendar.title")
        
        view.backgroundColor = AppColor.background
        navigationItem.largeTitleDisplayMode = .never
        updateNavigationBarStyle()
        
        self.selectedConfig = BasicCalendarManager.shared.getConfig()
        
        configureHierarchy()
        configureDataSource()
        reloadData()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: String(localized: "controller.publicDay.cancel"), style: .plain, target: self, action: #selector(cancelAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: String(localized: "controller.publicDay.confirm"), style: .plain, target: self, action: #selector(confirmAction))
    }
    
    func configureHierarchy() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = AppColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.register(StandardConfigCell.self, forCellReuseIdentifier: NSStringFromClass(StandardConfigCell.self))
        tableView.register(MenuCell.self, forCellReuseIdentifier: NSStringFromClass(MenuCell.self))
        tableView.register(WeekCalendarCell.self, forCellReuseIdentifier: NSStringFromClass(WeekCalendarCell.self))
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
            case .calendarType(let calendarType, let isSelected):
                let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
                cell.accessoryType = isSelected ? .checkmark : .none
                cell.tintColor = AppColor.offDay
                var content = UIListContentConfiguration.valueCell()
                content.text = calendarType.title
                content.textProperties.color = .label
                cell.contentConfiguration = content
                return cell
            case .stadardConfig(let weekdayOrders):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(StandardConfigCell.self), for: indexPath)
                if let cell = cell as? StandardConfigCell {
                    cell.update(weekdayOrders)
                    cell.updateClosure = { [weak self] weekdayOrders in
                        guard let self = self else { return }
                        self.updateStandardConfig(with: weekdayOrders)
                    }
                }
                return cell
            case .weekCount(let weekCount):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MenuCell.self), for: indexPath)
                if let cell = cell as? MenuCell {
                    cell.update(with: MenuCellItem(title: String(localized: "basicCalendar.weeks.count"), value: weekCount.title))
                    let actions = WeekCount.allCases.map { target in
                        let action = UIAction(title: target.title, state: weekCount == target ? .on : .off) { [weak self] _ in
                            self?.resetWeeksCircle(with: target)
                            self?.reloadData()
                        }
                        return action
                    }
                    let menu = UIMenu(children: actions)
                    cell.tapButton.menu = menu
                }
                return cell
            case .weekCalendar(let config):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(WeekCalendarCell.self), for: indexPath)
                if let cell = cell as? WeekCalendarCell {
                    cell.update(config)
                    cell.updateClosure = { [weak self] indexs in
                        guard let self = self else { return }
                        self.updateWeeksCircleConfig(with: indexs)
                    }
                }
                return cell
            case .date(let day):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DateCell.self), for: indexPath)
                if let cell = cell as? DateCell {
                    cell.update(with: DateCellItem(title: String(localized: "basicCalendar.days.start"), date: day))
                    cell.selectDateAction = { [weak self] date in
                        guard let self = self else { return }
                        let day = GregorianDay(from: date)
                        self.updateDaysCircleConfig(start: day.julianDay)
                    }
                }
                return cell
            case .workCount(let count):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MenuCell.self), for: indexPath)
                if let cell = cell as? MenuCell {
                    cell.update(with: MenuCellItem(title: String(localized: "basicCalendar.days.work"), value: String(format: (String(localized: "basicCalendar.days.day%i")), count)))
                    let actions = (1...10).map { target in
                        let action = UIAction(title: String(format: (String(localized: "basicCalendar.days.day%i")), target), state: count == target ? .on : .off) { [weak self] _ in
                            self?.updateDaysCircleConfig(workCount: target)
                        }
                        return action
                    }
                    let menu = UIMenu(children: actions)
                    cell.tapButton.menu = menu
                }
                return cell
            case .offCount(let count):
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MenuCell.self), for: indexPath)
                if let cell = cell as? MenuCell {
                    cell.update(with: MenuCellItem(title: String(localized: "basicCalendar.days.off"), value: String(format: (String(localized: "basicCalendar.days.day%i")), count)))
                    let actions = (1...10).map { target in
                        let action = UIAction(title: String(format: (String(localized: "basicCalendar.days.day%i")), target), state: count == target ? .on : .off) { [weak self] _ in
                            self?.updateDaysCircleConfig(offCount: target)
                        }
                        return action
                    }
                    let menu = UIMenu(children: actions)
                    cell.tapButton.menu = menu
                }
                return cell
            }
        }
    }
    
    @objc
    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        
        let options: [BasicCalendarType] = [.standard, .weeksCircle, .daysCircle]
        snapshot.appendItems(options.map{ .calendarType($0, self.selectedConfig.type == $0) })
        
        switch selectedConfig {
        case .standard(let config):
            snapshot.appendSections([.standardConfig])
            snapshot.appendItems([.stadardConfig(config.weekdayOrders)], toSection: .standardConfig)
        case .weeksCircle(let config):
            snapshot.appendSections([.weeksCircleConfig])
            snapshot.appendItems([.weekCount(config.weekCount), .weekCalendar(config)], toSection: .weeksCircleConfig)
        case .daysCircle(let config):
            snapshot.appendSections([.daysCircleConfig])
            snapshot.appendItems([.date(GregorianDay(JDN: config.start)), .workCount(config.workCount), .offCount(config.offCount)], toSection: .daysCircleConfig)
        case .none:
            break
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return }
        switch identifier {
        case .calendarType(let item, let isSelected):
            guard !isSelected else { return }
            switch item {
            case .standard:
                selectedConfig = .standard(StandardConfig.default)
            case .weeksCircle:
                resetWeeksCircle(with: .two)
            case .daysCircle:
                let today = ZCCalendar.manager.today
                selectedConfig = .daysCircle(DaysCircleConfig(start: today.julianDay, workCount: 1, offCount: 1))
            }
            reloadData()
        case .stadardConfig:
            break
        case .weekCount:
            break
        case .weekCalendar:
            break
        case .date:
            break
        case .workCount:
            break
        case .offCount:
            break
        }
    }
    
    func updateStandardConfig(with weekdayOrders: [WeekdayOrder]) {
        switch selectedConfig {
        case .standard(let config):
            var config = config
            config.weekdayOrders = weekdayOrders
            selectedConfig = .standard(config)
            reloadData()
        default:
            break
        }
    }
    
    func updateWeeksCircleConfig(with indexs: [Int]) {
        switch selectedConfig {
        case .weeksCircle(var config):
            config.indexs = indexs
            selectedConfig = .weeksCircle(config)
            reloadData()
        default:
            break
        }
    }
    
    func resetWeeksCircle(with weekCount: WeekCount) {
        let today = ZCCalendar.manager.today
        let mondayIndex = today.julianDay - today.weekdayOrder().rawValue + 1
        let weekOffset = (mondayIndex / 7) % weekCount.rawValue
        selectedConfig = .weeksCircle(WeeksCircleConfig(offset: weekOffset, weekCount: weekCount, indexs: []))
    }
    
    func updateDaysCircleConfig(start: Int? = nil, workCount: Int? = nil, offCount: Int? = nil) {
        switch selectedConfig {
        case .daysCircle(var config):
            if let start = start {
                config.start = start
            }
            if let workCount = workCount {
                config.workCount = workCount
            }
            if let offCount = offCount {
                config.offCount = offCount
            }
            selectedConfig = .daysCircle(config)
            reloadData()
        default:
            break
        }
    }
}

extension BasicCalendarEditorViewController {
    @objc
    func cancelAction() {
        dismiss(animated: true)
    }
    
    @objc
    func confirmAction() {
        BasicCalendarManager.shared.save(config: selectedConfig)
        
        dismiss(animated: true)
    }
}
