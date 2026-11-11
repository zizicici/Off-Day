import Foundation
import Testing
import UIKit
import ZCCalendar
// UIKit fixtures from the Swift 5 app module are accessed only on MainActor.
@preconcurrency @testable import Off_Day

@Suite(.serialized)
@MainActor
struct PublicPlanReviewRegressionTests {
    @Test(arguments: [false, true])
    func reminderDatesShouldNotChangeWithTheDisplayLanguage(collidingTranslations: Bool) throws {
        let manager = PublicPlanManager.shared
        let originalPlan = manager.dataSource?.plan
        let originalLanguage = manager.dataSource?.language
        let first = GregorianDay(year: 2027, month: .feb, day: 5)
        let days: [CustomPublicDay]
        let language: String
        let expectedDates: [Int]
        if collidingTranslations {
            days = [
                CustomPublicDay(name: "New Year's Day", date: first, type: .offDay, localizedNames: ["zh-Hans": "新年"]),
                CustomPublicDay(name: "Lunar New Year's Day", date: first + 30, type: .offDay, localizedNames: ["zh-Hans": "新年"]),
            ]
            language = "zh-Hans"
            expectedDates = [first.julianDay, (first + 30).julianDay]
        } else {
            days = [
                CustomPublicDay(name: "春节", date: first, type: .offDay, localizedNames: ["en": "Chinese New Year"]),
                CustomPublicDay(name: "春节", date: first + 1, type: .offDay),
                CustomPublicDay(name: "春节", date: first + 2, type: .offDay),
            ]
            language = "en"
            expectedDates = [first.julianDay]
        }
        let plan = try #require(try AppDatabase.shared.savePlanWithDays(
            plan: CustomPublicPlan(name: "Reminder grouping", start: first, end: first + 31), days: days))
        defer {
            manager.select(plan: originalPlan, language: originalLanguage)
            PublicPlanLanguage.save(nil, for: .custom(plan))
            _ = AppDatabase.shared.delete(publicPlan: plan)
        }
        manager.select(plan: .custom(plan), language: nil)
        #expect(manager.getDaysAfter(day: first + (-1)).map(\.key) == expectedDates)
        manager.select(plan: .custom(plan), language: language)
        let reminders = manager.getDaysAfter(day: first + (-1))
        #expect(reminders.map(\.key) == expectedDates)
        #expect(reminders.first?.value.name == days[0].localizedName(language: language))
    }

    @Test(arguments: [4, 15, 22, 31])
    func historicalOctoberShouldAcceptItsValidDayNumbers(day: Int) throws {
        let text = "1582-10-\(day)"
        let data = try JSONSerialization.data(withJSONObject: [
            "name": "Historical", "start": text, "end": text,
            "days": [["name": "Holiday", "date": text, "type": 0]],
        ])
        let plan = try JSONDecoder().decode(JSONPublicPlan.self, from: data)
        #expect(plan.start.day == day)
        #expect(plan.end.day == day)
        #expect(plan.days.first?.date.day == day)
        #expect(plan.start.month == .oct)
        #expect(plan.start.year == 1582)
    }

    @Test(arguments: [5, 14])
    func historicalCalendarGapShouldBeRejected(day: Int) throws {
        let text = "1582-10-\(day)"
        for field in ["start", "end", "date"] {
            var holiday: [String: Any] = ["name": "Holiday", "date": "1582-10-15", "type": 0]
            var plan: [String: Any] = ["name": "Historical", "start": "1582-10-15", "end": "1582-10-21"]
            if field == "date" { holiday[field] = text } else { plan[field] = text }
            plan["days"] = [holiday]
            let data = try JSONSerialization.data(withJSONObject: plan)
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(JSONPublicPlan.self, from: data) }
        }
    }

    @Test func newLocalizedDaysShouldKeepACompleteOriginalFallback() throws {
        var saved: CustomPublicDay?
        let editor = CustomPublicDayDetailViewController(day: nil, language: "pt") { day in
            saved = day
            return true
        }
        editor.loadViewIfNeeded()
        #expect(editor.navigationItem.rightBarButtonItem?.isEnabled == false)
        editor.updateName("N")
        editor.updateName("Novo Ano")
        #expect(editor.navigationItem.rightBarButtonItem?.isEnabled == true)
        editor.saveAction()
        let day = try #require(saved)
        #expect(day.name == "Novo Ano")
        #expect(day.localizedNames == ["pt": "Novo Ano"])
        #expect(day.localizedName(language: nil) == "Novo Ano")
    }

    @Test func localizedNameEditsShouldRejectEmptyInputAndPreserveOtherNames() throws {
        let date = GregorianDay(year: 2027, month: .jan, day: 1)
        let original = CustomPublicDay(name: "Original", date: date, type: .offDay,
                                       localizedNames: ["pt": "Feriado", "zh-Hant": "假日"])
        var saved: CustomPublicDay?
        let editor = CustomPublicDayDetailViewController(day: original, language: "pt") { day in
            saved = day
            return true
        }
        editor.loadViewIfNeeded()
        for text in ["", " \t\n "] {
            editor.updateName(text)
            #expect(editor.navigationItem.rightBarButtonItem?.isEnabled == false)
            editor.saveAction()
            #expect(saved == nil)
        }
        editor.updateName("Atualizado")
        editor.reloadData()
        #expect(editor.navigationItem.rightBarButtonItem?.isEnabled == true)
        editor.saveAction()
        let day = try #require(saved)
        #expect(day.name == "Original")
        #expect(day.localizedNames == ["pt": "Atualizado", "zh-Hant": "假日"])
    }

    @Test func untouchedFallbackNamesShouldNotCreateAnExtraTranslation() throws {
        let date = GregorianDay(year: 2027, month: .jan, day: 1)
        let original = CustomPublicDay(name: "Original", date: date, type: .offDay,
                                       localizedNames: ["pt": "Feriado"])
        var saved: CustomPublicDay?
        let editor = CustomPublicDayDetailViewController(day: original, language: "pt-BR") { day in
            saved = day
            return true
        }
        editor.loadViewIfNeeded()
        editor.reloadData()
        editor.saveAction()
        #expect(saved == original)
    }

    @Test(arguments: [Optional<String>.none, "pt", "pt-BR"])
    func editingADisplayedNameShouldUpdateThatLanguage(language: String?) throws {
        let date = GregorianDay(year: 2027, month: .jan, day: 1)
        let day = CustomPublicDay(name: "Original", date: date, type: .offDay,
                                  localizedNames: ["pt": "Feriado", "zh-Hant": "假日"])
        var info = PublicPlanInfo(plan: .custom(CustomPublicPlan(name: "Custom", start: date, end: date)),
                                  days: [date.julianDay: day])
        info.language = language
        let controller = PublicPlanDetailViewController(publicPlan: info, allowEditing: true)
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previousWindow = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        let animations = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        let navigation = NavigationController(rootViewController: controller)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        defer {
            navigation.dismiss(animated: false)
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
            UIView.setAnimationsEnabled(animations)
        }
        controller.enterDayDetail(day: day)
        let editorNavigation = try #require(navigation.presentedViewController as? UINavigationController)
        let editor = try #require(editorNavigation.topViewController as? CustomPublicDayDetailViewController)
        editor.loadViewIfNeeded()
        editor.view.layoutIfNeeded()
        let table = try #require(editor.view.subviews.compactMap { $0 as? UITableView }.first)
        table.layoutIfNeeded()
        let source = try #require(table.dataSource as? CustomPublicDayDetailViewController.DataSource)
        #expect(source.snapshot().itemIdentifiers.contains(.title(day.localizedName(language: language))))
        let titleItem = try #require(source.snapshot().itemIdentifiers.first {
            if case .title = $0 { return true }
            return false
        })
        let index = try #require(source.indexPath(for: titleItem))
        let cell = try #require(table.cellForRow(at: index) as? TextInputCell)
        var saved: CustomPublicDay?
        let save = editor.saveClosure
        editor.saveClosure = { updated in
            saved = updated
            return save?(updated) ?? false
        }
        cell.textDidChanged?("Updated")
        editor.saveAction()
        let updated = try #require(saved)
        #expect(updated.localizedName(language: language) == "Updated")
        #expect(updated.localizedNames?["zh-Hant"] == "假日")
        if let language {
            #expect(updated.name == "Original")
            #expect(updated.localizedNames?[language] == "Updated")
        } else {
            #expect(updated.name == "Updated")
            #expect(updated.localizedNames == day.localizedNames)
        }
        let collection = try #require(controller.view.subviews.compactMap { $0 as? UICollectionView }.first)
        collection.layoutIfNeeded()
        let list = try #require(collection.dataSource as? UICollectionViewDiffableDataSource<PublicPlanDetailViewController.Section, PublicPlanDetailViewController.Item>)
        let updatedIndex = try #require(list.indexPath(for: .dayInfo(updated)))
        collection.scrollToItem(at: updatedIndex, at: .centeredVertically, animated: false)
        collection.layoutIfNeeded()
        let updatedCell = try #require(collection.cellForItem(at: updatedIndex) as? UICollectionViewListCell)
        let content = try #require(updatedCell.contentConfiguration as? UIListContentConfiguration)
        #expect(content.text == "Updated")
    }
}
