import Foundation
import GRDB
import Testing
import UIKit
import ZCCalendar
// UIKit fixtures from the Swift 5 app module are accessed only on MainActor.
@preconcurrency @testable import Off_Day

@Suite(.serialized)
@MainActor
struct PublicPlanLanguageTests {
    private let date = GregorianDay(year: 2027, month: .jan, day: 1)

    @Test func legacyTemplatesShouldKeepTheirNamesAndOmitTranslationsOnExport() throws {
        let data = Data(#"{"name":"Old plan","start":"2027-01-01","end":"2027-12-31","days":[{"name":"Holiday","date":"2027-01-01","type":0}]}"#.utf8)
        let plan = try JSONDecoder().decode(JSONPublicPlan.self, from: data)
        let day = try #require(plan.days.first)
        #expect(day.localizedNames == nil)
        #expect(day.localizedName(language: "th") == "Holiday")
        let exported = try #require(try plan.jsonContent())
        let decoded = try JSONDecoder().decode(JSONPublicPlan.self, from: Data(exported.utf8))
        #expect(decoded.days == plan.days)
        let object = try #require(try JSONSerialization.jsonObject(with: Data(exported.utf8)) as? [String: Any])
        let days = try #require(object["days"] as? [[String: Any]])
        #expect(days[0]["localizedNames"] == nil)
    }

    @Test func legacyNamesKeyShouldDecodeAndExportOnlyLocalizedNames() throws {
        let data = Data(#"{"name":"Holiday","date":"2027-01-01","type":0,"names":{"pt":"Feriado","zh-Hant":"假日"}}"#.utf8)
        let day = try JSONDecoder().decode(JSONPublicDay.self, from: data)
        #expect(day.localizedNames == ["pt": "Feriado", "zh-Hant": "假日"])
        let exported = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(day)) as? [String: Any])
        #expect(exported["localizedNames"] as? [String: String] == day.localizedNames)
        #expect(exported["names"] == nil)

        let replacements: [(Any, [String: String]?)] = [(["pt": "Novo"], ["pt": "Novo"]), (NSNull(), nil), ([String: String](), [:])]
        for (value, expected) in replacements {
            var object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            object["localizedNames"] = value
            let decoded = try JSONDecoder().decode(JSONPublicDay.self, from: JSONSerialization.data(withJSONObject: object))
            #expect(decoded.localizedNames == expected)
        }
    }

    @Test func arbitraryTemplateLanguagesShouldRoundTripAndResolveWithFallbacks() throws {
        let day = JSONPublicDay(name: "Fallback", date: date, type: .offDay,
                                localizedNames: ["pt": "Ano Novo", "ta": "புத்தாண்டு", "th": "วันขึ้นปีใหม่", "eo": "Novjaro", "zh-Hant": "新年", "ja": "  ", "": "Invalid language"])
        let decoded = try JSONDecoder().decode(JSONPublicDay.self, from: JSONEncoder().encode(day))
        #expect(decoded == day)
        #expect(day.localizedName(language: "pt-PT") == "Ano Novo")
        #expect(day.localizedName(language: "ta") == "புத்தாண்டு")
        #expect(day.localizedName(language: "th") == "วันขึ้นปีใหม่")
        #expect(day.localizedName(language: "eo") == "Novjaro")
        #expect(day.localizedName(language: "zh-HK") == "新年")
        #expect(day.localizedName(language: "zh-TW") == "新年")
        #expect(day.localizedName(language: "ja") == "Fallback")
        #expect(day.localizedName(language: "fr") == "Fallback")
        #expect(day.localizedName(language: nil) == "Fallback")
        let info = PublicPlanInfo(plan: .app(AppPublicPlan(file: .cn)), days: [date.julianDay: day])
        #expect(Set(info.availableLanguages) == Set(["pt", "ta", "th", "eo", "zh-Hant"]))
        #expect(!PublicPlanLanguage.title(for: "eo").isEmpty)
    }

    @Test(arguments: AppPublicPlan.File.allCases)
    func bundled2027DatesShouldIncludeLocalLanguagesAndBothChineseScripts(file: AppPublicPlan.File) throws {
        let detail = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: file)))
        let expected: Set<String>
        switch file {
        case .hk, .us: expected = ["en", "zh-Hans", "zh-Hant"]
        case .mo_public, .mo_force, .mo_cs: expected = ["pt", "zh-Hans", "zh-Hant"]
        case .sg: expected = ["en", "ms", "ta", "zh-Hans", "zh-Hant"]
        case .th: expected = ["th", "zh-Hans", "zh-Hant"]
        case .jp: expected = ["ja", "zh-Hans", "zh-Hant"]
        case .kr: expected = ["ko", "zh-Hans", "zh-Hant"]
        default: expected = ["zh-Hans", "zh-Hant"]
        }
        for day in detail.days where day.date.year == 2027 {
            #expect(Set(day.localizedNames?.keys.map { $0 } ?? []) == expected)
            #expect(day.localizedNames?.values.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } == true)
        }
        #expect(detail.days.filter { $0.date.year < 2027 }.allSatisfy { $0.localizedNames == nil })
    }

    @Test func languagePreferencesShouldBeIndependentForEachTemplate() throws {
        let suite = "OffDayLanguageTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let app = PublicPlanInfo.Plan.app(AppPublicPlan(file: .sg))
        let custom = PublicPlanInfo.Plan.custom(CustomPublicPlan(id: 42, name: "Custom", start: date, end: date))
        PublicPlanLanguage.save("ta", for: app, defaults: defaults)
        PublicPlanLanguage.save("pt", for: custom, defaults: defaults)
        #expect(PublicPlanLanguage.saved(for: app, defaults: defaults) == "ta")
        #expect(PublicPlanLanguage.saved(for: custom, defaults: defaults) == "pt")
        PublicPlanLanguage.save(nil, for: app, defaults: defaults)
        #expect(PublicPlanLanguage.saved(for: app, defaults: defaults) == nil)
        #expect(PublicPlanLanguage.saved(for: custom, defaults: defaults) == "pt")
    }

    @Test func languageFallbacksShouldPreserveScriptsAndCanonicalizeRegionCodes() {
        let day = JSONPublicDay(name: "Original", date: date, type: .offDay, localizedNames: [
            "sr-Latn": "Nova godina", "sr": "Нова година", "pt-BR": "Ano Novo",
            "zh-Hans": "农历新年", "zh-Hant": "農曆新年",
        ])
        #expect(day.localizedName(language: "sr-Latn-RS") == "Nova godina")
        #expect(day.localizedName(language: "zh-Hans-TW") == "农历新年")
        #expect(day.localizedName(language: "zh-hant-hk") == "農曆新年")
        #expect(day.localizedName(language: "PT_br") == "Ano Novo")

        let aliases = JSONPublicDay(name: "Original", date: date, type: .offDay,
                                    localizedNames: ["pt-br": "Ano Novo", "PT_br": "Ano Novo", "SR_latn": "Nova godina"])
        #expect(aliases.localizedName(language: "pt-BR") == "Ano Novo")
        #expect(aliases.localizedName(language: "sr-Latn-RS") == "Nova godina")
        let info = PublicPlanInfo(plan: .app(AppPublicPlan(file: .cn)), days: [date.julianDay: aliases])
        #expect(info.availableLanguages == ["pt-BR", "sr-Latn"])
    }

    @Test func detailIdentifiersShouldObeyEqualityAndHashableContracts() {
        typealias Item = PublicPlanDetailViewController.Item
        let actions: [Item] = [.add, .delete, .refreshSubscription, .pauseSubscription, .resumeSubscription]
        for item in actions { #expect(item == item) }

        var first = CustomPublicDay(name: "Holiday", date: date, type: .offDay, localizedNames: ["pt": "Feriado"])
        first.id = 1
        first.planId = 10
        var differentRecord = first
        differentRecord.id = 2
        var differentPlan = first
        differentPlan.planId = 20
        #expect(Item.dayInfo(first) != Item.dayInfo(differentRecord))
        #expect(Item.dayInfo(first) != Item.dayInfo(differentPlan))
        #expect(first.isEqual(first))
        #expect(!first.isEqual(differentRecord))
    }

    @Test(arguments: ["2027-02-29", "2027-13-01", "2027-01-00", "not-a-date", "9223372036854775807-01-01", "2027-01-9223372036854775807", "10000-01-01"])
    func invalidTemplateDatesShouldThrowBeforeCalendarArithmetic(invalidDate: String) throws {
        for field in ["start", "end", "date"] {
            var day: [String: Any] = ["name": "Holiday", "date": "2027-01-01", "type": 0]
            var object: [String: Any] = ["name": "Plan", "start": "2027-01-01", "end": "2027-12-31"]
            if field == "date" { day[field] = invalidDate } else { object[field] = invalidDate }
            object["days"] = [day]
            let data = try JSONSerialization.data(withJSONObject: object)
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(JSONPublicPlan.self, from: data) }
        }
    }

    @Test func legacyUnpaddedDatesAndNullTranslationsShouldRemainCompatible() throws {
        let data = Data(#"{"name":"Legacy","start":"2027-1-1","end":"2027-12-31","days":[{"name":"Holiday","date":"2027-1-1","type":0,"localizedNames":null}]}"#.utf8)
        let plan = try JSONDecoder().decode(JSONPublicPlan.self, from: data)
        #expect(plan.start == date)
        #expect(plan.days.first?.date == date)
        #expect(plan.days.first?.localizedNames == nil)
    }

    @Test func malformedTranslationsShouldFailDecodingWithoutAffectingLegacyNames() throws {
        for localizedNames: Any in ["English", ["en": 123], ["en": ["bad": "shape"]], ["English", "中文"]] as [Any] {
            let object: [String: Any] = ["name": "Holiday", "date": "2027-01-01", "type": 0, "localizedNames": localizedNames]
            let data = try JSONSerialization.data(withJSONObject: object)
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(JSONPublicDay.self, from: data) }
        }
        let day = JSONPublicDay(name: "Legacy", date: date, type: .offDay, localizedNames: [:])
        for language in ["", " ", "---", "x-klingon", "i-klingon", "not a language", "zh-@", "en_US_POSIX", "🌏", "en\0-US"] {
            _ = PublicPlanLanguage.title(for: language)
            #expect(day.localizedName(language: language) == "Legacy")
        }
    }

    @Test func savedCustomTemplateShouldSurviveRepeatedRecordAndTranslationUpdates() throws {
        var day = CustomPublicDay(name: "Holiday", date: date, type: .offDay, localizedNames: ["pt": "Feriado"])
        day.id = 1
        day.planId = 900000042
        var info = PublicPlanInfo(plan: .custom(CustomPublicPlan(id: day.planId, name: "Saved plan", start: date, end: date)), days: [date.julianDay: day])
        info.language = "pt"
        let controller = PublicPlanDetailViewController(publicPlan: info, allowEditing: true)
        controller.loadViewIfNeeded()
        let collection = try #require(controller.view.subviews.compactMap { $0 as? UICollectionView }.first)
        let source = try #require(collection.dataSource as? UICollectionViewDiffableDataSource<PublicPlanDetailViewController.Section, PublicPlanDetailViewController.Item>)
        for offset in 1...30 {
            var changed = day
            changed.id = Int64(offset + 1)
            if offset.isMultiple(of: 2) { changed.localizedNames?["pt"] = "Feriado \(offset)" }
            #expect(controller.update(day, with: changed))
            let items = source.snapshot().itemIdentifiers
            #expect(items.contains(.delete))
            #expect(Set(items).count == items.count)
            day = changed
        }
    }

    @Test func templateAndLanguageSwitchesShouldKeepSnapshotIdentifiersUnique() throws {
        let manager = PublicPlanManager.shared
        let originalPlan = manager.dataSource?.plan
        let originalLanguage = manager.dataSource?.language
        let preferences = AppPublicPlan.File.allCases.map { file in
            let plan = PublicPlanInfo.Plan.app(AppPublicPlan(file: file))
            return (plan, PublicPlanLanguage.saved(for: plan))
        }
        defer {
            manager.select(plan: originalPlan, language: originalLanguage)
            for (plan, language) in preferences { PublicPlanLanguage.save(language, for: plan) }
        }
        let calendar = BlockViewController()
        calendar.loadViewIfNeeded()
        let picker = PublicPlanViewController()
        picker.loadViewIfNeeded()
        let collection = try #require(picker.view.subviews.compactMap { $0 as? UICollectionView }.first)
        let source = try #require(collection.dataSource as? UICollectionViewDiffableDataSource<PublicPlanViewController.Section, PublicPlanViewController.Item>)
        for file in AppPublicPlan.File.allCases + AppPublicPlan.File.allCases.reversed() {
            let index = try #require(source.indexPath(for: .appPlan(AppPublicPlan(file: file))))
            collection.selectItem(at: index, animated: false, scrollPosition: [])
            picker.collectionView(collection, didSelectItemAt: index)
            picker.confirmAction()
            calendar.selectPublicPlanLanguage("zh-Hant")
            let items = source.snapshot().itemIdentifiers
            #expect(Set(items).count == items.count)
            #expect(manager.dataSource?.language == "zh-Hant")
            #expect(calendar.getPublicPlanLanguageMenu() != nil)
        }
        let emptyIndex = try #require(source.indexPath(for: .empty))
        collection.selectItem(at: emptyIndex, animated: false, scrollPosition: [])
        picker.collectionView(collection, didSelectItemAt: emptyIndex)
        picker.confirmAction()
        #expect(manager.dataSource == nil)
        #expect(calendar.getPublicPlanLanguageMenu() == nil)
    }

    @Test func calendarLanguageMenuShouldBeInTopRightAndRefreshAfterSelection() throws {
        let manager = PublicPlanManager.shared
        let originalPlan = manager.dataSource?.plan
        let originalLanguage = manager.dataSource?.language
        let singapore = PublicPlanInfo.Plan.app(AppPublicPlan(file: .sg))
        let savedLanguage = PublicPlanLanguage.saved(for: singapore)
        defer {
            manager.select(plan: originalPlan, language: originalLanguage)
            PublicPlanLanguage.save(savedLanguage, for: singapore)
        }
        manager.select(plan: singapore, language: "en")
        let calendar = BlockViewController()
        calendar.loadViewIfNeeded()
        func languageMenu() -> UIMenu? {
            calendar.navigationItem.rightBarButtonItem?.menu?.children.compactMap { $0 as? UIMenu }
                .first { $0.identifier == UIMenu.Identifier("publicPlan.language") }
        }
        let menu = try #require(languageMenu())
        #expect(menu.subtitle == PublicPlanLanguage.title(for: "en"))
        #expect(menu.children.count == 6)
        calendar.selectPublicPlanLanguage("ta")
        let updated = try #require(languageMenu())
        #expect(updated.subtitle == PublicPlanLanguage.title(for: "ta"))
        let actions = updated.children.compactMap { $0 as? UIAction }
        #expect(actions.filter { $0.state == .on }.count == 1)
        #expect(actions.first { $0.identifier == UIAction.Identifier("publicPlan.language.ta") }?.state == .on)
        #expect(PublicPlanLanguage.saved(for: singapore) == "ta")
        #expect(manager.publicDay(at: date.julianDay)?.name == "புத்தாண்டு தினம்")
        manager.select(plan: nil)
        #expect(languageMenu() == nil)
    }

    @Test func traditionalNamesShouldKeepCalendarTermsAndProperNames() throws {
        let singapore = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: .sg)))
        let thailand = try #require(AppPublicPlan.Detail(plan: AppPublicPlan(file: .th)))
        let newYear = try #require(singapore.days.first { $0.date == GregorianDay(year: 2027, month: .feb, day: 6) })
        let songkran = try #require(thailand.days.first { $0.date == GregorianDay(year: 2027, month: .apr, day: 13) })
        #expect(newYear.localizedName(language: "zh-Hant") == "農曆新年")
        #expect(newYear.localizedName(language: "ms") == "Tahun Baru Cina")
        #expect(songkran.localizedName(language: "zh-Hant") == "宋干節")
        let vesak = try #require(singapore.days.first { $0.date == GregorianDay(year: 2027, month: .may, day: 20) })
        let haji = try #require(singapore.days.first { $0.date == GregorianDay(year: 2027, month: .may, day: 17) })
        #expect(vesak.localizedName(language: "ms") == "Hari Vesak")
        #expect(haji.localizedName(language: "ta") == "ஹாஜி பெருநாள்")
    }

    @Test func databaseShouldPreserveLegacyRowsWhenAddingTranslations() throws {
        let queue = try DatabaseQueue()
        let database = try AppDatabase(queue)
        let plan = try #require(try database.savePlanWithDays(
            plan: CustomPublicPlan(name: "Legacy", start: date, end: date),
            days: [CustomPublicDay(name: "Holiday", date: date, type: .offDay)]))
        let id = try #require(plan.id)
        // Recreate the schema immediately before this feature's additive migration.
        try queue.write { db in
            try db.execute(sql: "ALTER TABLE custom_public_day DROP COLUMN localized_names")
            try db.execute(sql: "DELETE FROM grdb_migrations WHERE identifier IN (?, ?)", arguments: ["add_public_day_localized_names", "rename_public_day_localized_names"])
        }
        _ = try AppDatabase(queue)
        let legacy = try #require(try database.fetchCustomPublicDays(for: id).first)
        #expect(legacy.name == "Holiday")
        #expect(legacy.localizedNames == nil)
        var updated = legacy
        updated.localizedNames = ["th": "วันขึ้นปีใหม่", "zh-Hant": "元旦"]
        #expect(database.update(publicDay: updated))
        let loaded = try #require(try database.fetchCustomPublicDays(for: id).first)
        #expect(loaded.localizedNames == updated.localizedNames)
        #expect(loaded.name == "Holiday")
    }

    @Test func databaseRenameShouldPreserveExistingNamesColumnData() throws {
        let queue = try DatabaseQueue()
        let database = try AppDatabase(queue)
        let day = CustomPublicDay(name: "Holiday", date: date, type: .offDay, localizedNames: ["pt": "Feriado", "zh-Hant": "假日"])
        let plan = try #require(try database.savePlanWithDays(plan: CustomPublicPlan(name: "Earlier build", start: date, end: date), days: [day]))
        let id = try #require(plan.id)
        // Recreate the previous build's schema, including populated translations.
        try queue.write { db in
            try db.execute(sql: "ALTER TABLE custom_public_day RENAME COLUMN localized_names TO names")
            try db.execute(sql: "DELETE FROM grdb_migrations WHERE identifier = ?", arguments: ["rename_public_day_localized_names"])
        }
        _ = try AppDatabase(queue)
        let loaded = try #require(try database.fetchCustomPublicDays(for: id).first)
        #expect(loaded.name == day.name)
        #expect(loaded.localizedNames == day.localizedNames)
        let columns = try queue.read { db in try db.columns(in: "custom_public_day").map(\.name) }
        #expect(columns.contains("localized_names"))
        #expect(!columns.contains("names"))
    }

    @Test func copiesAndSubscriptionDiffsShouldKeepTranslationChanges() throws {
        let original = JSONPublicDay(name: "New Year", date: date, type: .offDay, localizedNames: ["pt": "Ano Novo", "zh-Hans": "元旦"])
        var info = PublicPlanInfo(plan: .app(AppPublicPlan(file: .us)), days: [date.julianDay: original])
        info.language = "zh-Hans"
        #expect(info.displayDay(original).name == "元旦")
        #expect(info.days[date.julianDay]?.name == "New Year")
        let copied = try #require(info.getDuplicateCustomPlan().days[date.julianDay] as? CustomPublicDay)
        #expect(copied.name == original.name)
        #expect(copied.localizedNames == original.localizedNames)
        var changed = original
        changed.localizedNames?["pt"] = "Dia de Ano Novo"
        let diff = SubscriptionManager.shared.computeDiff(planId: 1, planName: "Plan", currentDays: [copied], newDays: [changed])
        #expect(diff.modifiedDays.count == 1)
    }

    @Test(arguments: [false, true])
    func importedAndExportedTemplatesShouldKeepAllTranslations(multilingual: Bool) throws {
        let original = JSONPublicPlan(name: "Language round trip \(UUID().uuidString)", days: [
            JSONPublicDay(name: "New Year", date: date, type: .offDay, localizedNames: multilingual ? ["pt": "Ano Novo", "th": "วันขึ้นปีใหม่", "zh-Hans": "元旦"] : nil)
        ], start: date, end: date)
        let url = try TestFileHelper.writeTempFile(try #require(try original.jsonContent()))
        defer { try? FileManager.default.removeItem(at: url) }
        let manager = PublicPlanManager.shared
        #expect(manager.importPlan(from: url))
        let imported = try #require(try manager.fetchAllPublicPlan().first { $0.name == original.name })
        defer { _ = AppDatabase.shared.delete(publicPlan: imported) }
        let exportURL = try #require(manager.exportCustomPlanToFile(from: imported))
        defer { try? FileManager.default.removeItem(at: exportURL) }
        let exported = try JSONPublicPlan(from: exportURL)
        #expect(exported.days == original.days)
    }

    @Test func acceptedSubscriptionUpdatesShouldPreserveTranslationsAndLanguagePreference() throws {
        let manager = SubscriptionManager.shared
        let plan = try #require(try AppDatabase.shared.savePlanWithDays(
            plan: CustomPublicPlan(name: "Subscription language test", start: date, end: date, sourceURL: "https://example.com/holidays.json"),
            days: [CustomPublicDay(name: "New Year", date: date, type: .offDay)]))
        let id = try #require(plan.id)
        defer {
            manager.cleanupForDeletedPlan(id)
            PublicPlanLanguage.save(nil, for: .custom(plan))
            _ = AppDatabase.shared.delete(publicPlan: plan)
        }
        PublicPlanLanguage.save("pt", for: .custom(plan))
        let newDay = JSONPublicDay(name: "New Year", date: date, type: .offDay, localizedNames: ["pt": "Ano Novo", "zh-Hant": "元旦"])
        let json = JSONPublicPlan(name: plan.name, days: [newDay], start: date, end: date)
        let diff = manager.computeDiff(planId: id, planName: plan.name, currentDays: [CustomPublicDay(name: "New Year", date: date, type: .offDay)], newDays: [newDay])
        manager.savePendingUpdate(PendingSubscriptionUpdate(planId: id, planName: plan.name, fetchTime: 0, jsonPlan: json, diff: diff))
        #expect(manager.acceptUpdate(for: id))
        let loaded = try #require(try PublicPlanManager.shared.fetchCustomPublicPlan(with: id))
        let info = PublicPlanInfo(detail: loaded)
        #expect(info.language == "pt")
        #expect(loaded.days.first?.localizedNames == newDay.localizedNames)
        #expect(info.days[date.julianDay]?.localizedName(language: info.language) == "Ano Novo")
    }

    @Test(arguments: [false, true])
    func detailShouldDisplayTheSelectedLanguageWithWrapping(allowEditing: Bool) throws {
        let day = CustomPublicDay(name: "Original", date: date, type: .offDay, localizedNames: ["pt": "Dia Comemorativo do Estabelecimento da Região Administrativa Especial de Macau", "zh-Hant": "澳門特別行政區成立紀念日"])
        var info = PublicPlanInfo(plan: .custom(CustomPublicPlan(name: "Custom", start: date, end: date)), days: [date.julianDay: day])
        info.language = "pt"
        let controller = PublicPlanDetailViewController(publicPlan: info, allowEditing: allowEditing)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        let collection = try #require(controller.view.subviews.compactMap { $0 as? UICollectionView }.first)
        let source = try #require(collection.dataSource as? UICollectionViewDiffableDataSource<PublicPlanDetailViewController.Section, PublicPlanDetailViewController.Item>)
        let index = try #require(source.indexPath(for: .dayInfo(day)))
        collection.scrollToItem(at: index, at: .centeredVertically, animated: false)
        collection.layoutIfNeeded()
        let cell = try #require(collection.cellForItem(at: index) as? UICollectionViewListCell)
        let content = try #require(cell.contentConfiguration as? UIListContentConfiguration)
        #expect(content.text == day.localizedNames?["pt"])
        #expect(content.textProperties.numberOfLines == 0)
    }

    @Test func aSingleTranslationShouldBeSelectableAlongsideTheOriginalName() throws {
        let manager = PublicPlanManager.shared
        let originalPlan = manager.dataSource?.plan
        let originalLanguage = manager.dataSource?.language
        let day = CustomPublicDay(name: "New Year", date: date, type: .offDay, localizedNames: ["zh-Hant": "元旦"])
        let plan = try #require(try AppDatabase.shared.savePlanWithDays(plan: CustomPublicPlan(name: "One translation", start: date, end: date), days: [day]))
        defer {
            manager.select(plan: originalPlan, language: originalLanguage)
            PublicPlanLanguage.save(nil, for: .custom(plan))
            _ = AppDatabase.shared.delete(publicPlan: plan)
        }
        manager.select(plan: .custom(plan))
        let calendar = BlockViewController()
        calendar.loadViewIfNeeded()
        let menu = try #require(calendar.getPublicPlanLanguageMenu())
        #expect(menu.children.count == 2)
        calendar.selectPublicPlanLanguage("zh-Hant")
        #expect(manager.publicDay(at: date.julianDay)?.name == "元旦")
        #expect(PublicPlanLanguage.saved(for: .custom(plan)) == "zh-Hant")
    }

    @Test func calendarLanguageSelectionShouldPersistAndTemplatePickerShouldPreserveIt() throws {
        let manager = PublicPlanManager.shared
        let originalPlan = manager.dataSource?.plan
        let originalLanguage = manager.dataSource?.language
        let singapore = PublicPlanInfo.Plan.app(AppPublicPlan(file: .sg))
        let savedLanguage = PublicPlanLanguage.saved(for: singapore)
        defer {
            manager.select(plan: originalPlan, language: originalLanguage)
            PublicPlanLanguage.save(savedLanguage, for: singapore)
        }
        manager.select(plan: singapore, language: "en")
        let calendar = BlockViewController()
        calendar.loadViewIfNeeded()
        calendar.selectPublicPlanLanguage("ta")
        #expect(PublicPlanLanguage.saved(for: singapore) == "ta")
        calendar.selectPublicPlanLanguage("pt")
        #expect(manager.dataSource?.language == "ta")
        #expect(manager.dataSource?.plan == singapore)
        let picker = PublicPlanViewController()
        picker.loadViewIfNeeded()
        let collection = try #require(picker.view.subviews.compactMap { $0 as? UICollectionView }.first)
        let source = try #require(collection.dataSource as? UICollectionViewDiffableDataSource<PublicPlanViewController.Section, PublicPlanViewController.Item>)
        let usIndex = try #require(source.indexPath(for: .appPlan(AppPublicPlan(file: .us))))
        collection.selectItem(at: usIndex, animated: false, scrollPosition: [])
        picker.collectionView(collection, didSelectItemAt: usIndex)
        picker.cancelAction()
        #expect(manager.dataSource?.plan == singapore)
        #expect(manager.dataSource?.language == "ta")
        picker.confirmAction()
        #expect(manager.dataSource?.plan == PublicPlanInfo.Plan.app(AppPublicPlan(file: .us)))
        let sgIndex = try #require(source.indexPath(for: .appPlan(AppPublicPlan(file: .sg))))
        collection.selectItem(at: sgIndex, animated: false, scrollPosition: [])
        picker.collectionView(collection, didSelectItemAt: sgIndex)
        picker.confirmAction()
        #expect(manager.dataSource?.language == "ta")
        manager.load()
        #expect(manager.publicDay(at: date.julianDay)?.name == "புத்தாண்டு தினம்")
        calendar.selectPublicPlanLanguage(nil)
        #expect(manager.dataSource?.language == nil)
        #expect(manager.publicDay(at: date.julianDay)?.name == "New Year's Day")

        let legacy = try #require(try AppDatabase.shared.savePlanWithDays(plan: CustomPublicPlan(name: "Legacy", start: date, end: date), days: [CustomPublicDay(name: "Holiday", date: date, type: .offDay)]))
        defer { _ = AppDatabase.shared.delete(publicPlan: legacy) }
        manager.select(plan: .custom(legacy))
        #expect(calendar.getPublicPlanLanguageMenu() == nil)
        #expect(calendar.navigationItem.rightBarButtonItem?.menu?.children.compactMap { $0 as? UIMenu }
            .contains { $0.identifier == UIMenu.Identifier("publicPlan.language") } == false)
        #expect(manager.publicDay(at: date.julianDay)?.name == "Holiday")
    }

}
