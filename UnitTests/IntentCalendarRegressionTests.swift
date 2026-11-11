import AppIntents
import Foundation
import GRDB
import MoreKit
import Testing
import UIKit
import ZCCalendar
@testable import Off_Day

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["OFF_DAY_EXPECTED_CALENDAR"] != nil,
                            "Run scripts/test-gregorian-regressions.sh to isolate shared App state."))
@MainActor
struct IntentCalendarRegressionTests {
    @Test func changingAppearanceShouldPreserveRecordsAndExistingIntentUpdates() async throws {
        let index = GregorianDay(year: 2094, month: .nov, day: 26).julianDay
        let previous = UserDefaults.standard.object(forKey: CalendarAppearanceSettings.key)
        defer {
            if let previous { UserDefaults.standard.set(previous, forKey: CalendarAppearanceSettings.key) }
            else { UserDefaults.standard.removeObject(forKey: CalendarAppearanceSettings.key) }
            NotificationCenter.default.post(name: .SettingsUpdate, object: nil)
        }
        try await withRestoredData(indices: [index]) { calendar in
            let date = try #require(calendar.date(from: .init(year: 2094, month: 11, day: 26, hour: 12)))
            let update = UpdateDayMarkIntent()
            update.date = date
            update.mark = .work
            #expect(try await update.perform().value == true)
            let comment = UpdateDayCommentIntent()
            comment.date = date
            comment.content = "Appearance must preserve this record"
            #expect(try await comment.perform().value == true)
            let original = try persistedRecords(at: index)
            let check = CheckDayIntent()
            check.date = date
            let detail = DayDetailIntent()
            detail.date = date
            let getComment = GetDayCommentIntent()
            getComment.date = date

            let home: BlockViewController?
            if Calendar.current.identifier == .gregorian {
                home = BlockViewController(nibName: nil, bundle: nil)
                home?.loadViewIfNeeded()
            } else { home = nil }
            for style in [CalendarVisualStyle(), .init(coloredPatterns: true), .init(palette: .mono), .init()] {
                let before = try persistedRecords(at: index)
                CalendarAppearanceSettings.save(style)
                let after = try persistedRecords(at: index)
                #expect(after.marks == before.marks)
                #expect(after.comments == before.comments)
                #expect(try await check.perform().value == false)
                let result = try await detail.perform()
                #expect(result.value?.userOffDay == false)
                #expect(result.value?.userComment == comment.content)
                #expect((try await getComment.perform().value ?? nil) == comment.content)
                if let home {
                    #expect(home.navigationItem.rightBarButtonItems?.count == 1)
                    let moreMenu = try #require(home.navigationItem.rightBarButtonItem?.menu)
                    let menu = try #require(moreMenu.children.compactMap { $0 as? UIMenu }
                        .first { $0.identifier.rawValue == "calendar.appearance" })
                    #expect(menu.subtitle == style.palette.calendarAppearanceName)
                    let actions = menu.children.compactMap { $0 as? UIMenu }.flatMap(\.children).compactMap { $0 as? UIAction }
                    #expect(actions.first { $0.identifier.rawValue == "calendar.appearance.palette.\(style.palette.rawValue)" }?.state == .on)
                    let patterns = actions.first { $0.identifier.rawValue == "calendar.appearance.coloredPatterns" }
                    #expect((patterns != nil) == (style.palette == .classic))
                    if let patterns { #expect(patterns.state == (style.coloredPatterns ? .on : .off)) }
                }
                // Existing shortcuts still update the same database row in every style.
                for mark in [DayMark.off, .work] {
                    update.mark = mark
                    #expect(try await update.perform().value == true)
                    #expect(try await check.perform().value == (mark == .off))
                    let stored = try persistedRecords(at: index)
                    #expect(stored.marks.first?.id == original.marks.first?.id)
                    #expect(stored.marks.first?.creationTime == original.marks.first?.creationTime)
                    #expect(stored.comments == original.comments)
                    #expect(stored.marks.first?.dayType == (mark == .off ? .offDay : .workDay))
                }
            }
        }
    }

    @Test func existingIntentsShouldRoundTripMarksCommentsAndReturnedDates() async throws {
        let start = GregorianDay(year: 2094, month: .nov, day: 10).julianDay
        try await withRestoredData(indices: Array(start...(start + 2))) { calendar in
            let date = try #require(calendar.date(from: .init(year: 2094, month: 11, day: 10, hour: 12)))
            let update = UpdateDayMarkIntent()
            update.date = date
            let check = CheckDayIntent()
            check.date = date
            let detail = DayDetailIntent()
            detail.date = date
            for mark in [DayMark.off, .work] {
                update.mark = mark
                #expect(try await update.perform().value == true)
                #expect(try await check.perform().value == (mark == .off))
                let result = try await detail.perform()
                let entity = try #require(result.value)
                #expect(entity.id == start)
                #expect(entity.userOffDay == (mark == .off))
                #expect(calendar.isDate(entity.date, inSameDayAs: date))
                #expect(String(localized: entity.displayRepresentation.title)
                    == Date.FormatStyle(date: .abbreviated, time: .omitted)
                        .widgetGregorian(locale: .current).format(entity.date))
            }
            let comment = UpdateDayCommentIntent()
            comment.date = date
            comment.content = "Calendar round trip"
            #expect(try await comment.perform().value == true)
            #expect(CustomDayManager.shared.fetchCustomComment(by: start)?.content == comment.content)
            let getComment = GetDayCommentIntent()
            getComment.date = date
            let commentResult = try await getComment.perform()
            #expect((commentResult.value ?? nil) == comment.content)
            let detailResult = try await detail.perform()
            #expect(detailResult.value?.userComment == comment.content)

            try AppDatabase.shared.setCustomDay(.workDay, at: start + 1)
            try AppDatabase.shared.setCustomDay(.offDay, at: start + 2)
            let nextWork = NextWorkDayDetailIntent()
            nextWork.date = date
            let nextOff = NextOffDayDetailIntent()
            nextOff.date = date
            for (entity, index) in [(try #require(try await nextWork.perform().value), start + 1),
                                    (try #require(try await nextOff.perform().value), start + 2)] {
                #expect(entity.id == index)
                let parts = calendar.dateComponents([.year, .month, .day], from: entity.date)
                let returnedDay = GregorianDay(year: parts.year!, month: Month(rawValue: parts.month!)!, day: parts.day!)
                #expect(returnedDay.julianDay == index)
            }
            let delete = DeleteDayCommentIntent()
            delete.date = date
            #expect(try await delete.perform().value == true)
            #expect(CustomDayManager.shared.fetchCustomComment(by: start) == nil)
            update.mark = .blank
            #expect(try await update.perform().value == true)
            #expect(CustomDayManager.shared.fetchCustomDay(by: start) == nil)
        }
    }

    @Test func todayTomorrowAndOffsetIntentsShouldUseTheSameGregorianDays() async throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let parts = calendar.dateComponents([.year, .month, .day], from: Date())
        let today = GregorianDay(year: parts.year!, month: Month(rawValue: parts.month!)!, day: parts.day!).julianDay
        try await withRestoredData(indices: Array(today...(today + 2))) { _ in
            for index in today...(today + 2) {
                let isOff = BaseCalendarManager.shared.isOff(day: GregorianDay(JDN: index))
                try AppDatabase.shared.setCustomDay(isOff ? .workDay : .offDay, at: index)
            }
            let todayExpected = DayManager.check(GregorianDay(JDN: today), is: .offDay)
            let tomorrowExpected = DayManager.check(GregorianDay(JDN: today + 1), is: .offDay)
            #expect(try await CheckTodayIntent().perform().value == todayExpected)
            #expect(try await CheckTomorrowIntent().perform().value == tomorrowExpected)
            let offset = CheckOffsetDayOffIntent()
            offset.dayCount = 2
            #expect(try await offset.perform().value == DayManager.check(GregorianDay(JDN: today + 2), is: .offDay))
            let todayClash = CheckTodayClashIntent()
            todayClash.enableUserMark = true
            let tomorrowClash = CheckTomorrowClashIntent()
            tomorrowClash.enableUserMark = true
            let offsetClash = CheckOffsetDayClashIntent()
            offsetClash.dayCount = 2
            offsetClash.enableUserMark = true
            #expect(try await todayClash.perform().value == true)
            #expect(try await tomorrowClash.perform().value == true)
            #expect(try await offsetClash.perform().value == true)
            let clash = CheckDayClashIntent()
            clash.date = Date()
            clash.enableUserMark = true
            #expect(try await clash.perform().value == true)
        }
    }

    @Test func widgetEditsShouldBeImmediatelyVisibleToExistingIntentsWithoutLosingComments() async throws {
        if #available(iOS 17.0, *) {
            let index = GregorianDay(year: 2094, month: .nov, day: 20).julianDay
            try await withRestoredData(indices: [index]) { calendar in
                let date = try #require(calendar.date(from: .init(year: 2094, month: 11, day: 20, hour: 12)))
                let comment = UpdateDayCommentIntent()
                comment.date = date
                comment.content = "Keep this comment"
                _ = try await comment.perform()
                let check = CheckDayIntent()
                check.date = date
                let detail = DayDetailIntent()
                detail.date = date
                for surface in WidgetCalendarSurface.allCases {
                    for mark in [WidgetDayMark.off, .work, .automatic] {
                        _ = try await SetWidgetCalendarDayMarkIntent(dayIndex: index, mark: mark, surface: surface).perform()
                        let expected: Bool? = mark == .automatic ? nil : mark == .off
                        let result = try await detail.perform()
                        #expect(result.value?.id == index)
                        #expect(result.value?.userOffDay == expected)
                        #expect(result.value?.userComment == comment.content)
                        #expect(try await check.perform().value == DayManager.check(GregorianDay(JDN: index), is: .offDay))
                        #expect(WidgetCalendarStore.load()?.details?[index]?.customIsOffDay == expected)
                        // Open a new connection to the actual app database after every edit.
                        // Manager reads and the shared JSON alone cannot prove persistence.
                        let stored = try persistedRecords(at: index)
                        #expect(stored.marks.count == (mark == .automatic ? 0 : 1))
                        #expect(stored.marks.first.map { $0.dayType == .offDay } == expected)
                        #expect(stored.comments.first?.content == comment.content)
                    }
                }
            }
        }
    }

    @Test func existingShortcutsShouldReadAndWriteWithMissingCorruptOrUnwritableWidgetCache() async throws {
        let index = GregorianDay(year: 2094, month: .nov, day: 21).julianDay
        try await withRestoredData(indices: [index]) { calendar in
            let date = try #require(calendar.date(from: .init(year: 2094, month: 11, day: 21, hour: 12)))
            for state in UnavailableWidgetCache.allCases {
                for mark in [DayMark.off, .work, .blank] {
                    try await withUnavailableWidgetCache(state) {
                        #expect(WidgetCalendarStore.load() == nil)
                        let update = UpdateDayMarkIntent()
                        update.date = date
                        update.mark = mark
                        #expect(try await update.perform().value == true)

                        let comment = UpdateDayCommentIntent()
                        comment.date = date
                        comment.content = "Existing shortcut with \(state) cache"
                        #expect(try await comment.perform().value == true)
                        let getComment = GetDayCommentIntent()
                        getComment.date = date
                        let commentResult = try await getComment.perform()
                        #expect((commentResult.value ?? nil) == comment.content)

                        let expected: Bool? = mark == .blank ? nil : mark == .off
                        let stored = try persistedRecords(at: index)
                        #expect(stored.marks.count == (mark == .blank ? 0 : 1))
                        #expect(stored.marks.first.map { $0.dayType == .offDay } == expected)
                        #expect(stored.comments.first?.content == comment.content)
                        let detail = DayDetailIntent()
                        detail.date = date
                        let result = try await detail.perform()
                        #expect(result.value?.id == index)
                        #expect(result.value?.userOffDay == expected)
                        #expect(result.value?.userComment == comment.content)
                        let check = CheckDayIntent()
                        check.date = date
                        #expect(try await check.perform().value == (expected ?? BaseCalendarManager.shared.isOff(day: GregorianDay(JDN: index))))

                        let delete = DeleteDayCommentIntent()
                        delete.date = date
                        #expect(try await delete.perform().value == true)
                        #expect(try persistedRecords(at: index).comments.isEmpty)
                        if state == .unwritable {
                            // The real publisher failed, while every old shortcut completed.
                            #expect(WidgetCalendarStore.load() == nil)
                        }
                    }
                }
            }
        }
    }

    @Test func widgetAndExistingShortcutsShouldPreserveOlderRecordsAndUnrelatedDays() async throws {
        if #available(iOS 17.0, *) {
            let index = GregorianDay(year: 2094, month: .nov, day: 22).julianDay
            try await withRestoredData(indices: [index, index + 1]) { calendar in
                try AppDatabase.shared.setCustomDay(nil, at: index)
                let originalTime: Int64 = 1_700_000_000_000_000_000
                #expect(AppDatabase.shared.add(customDay: .init(creationTime: originalTime,
                    modificationTime: originalTime, dayIndex: Int64(index), dayType: .workDay)))
                try AppDatabase.shared.setCustomDay(.offDay, at: index + 1)
                let comment = UpdateDayCommentIntent()
                comment.date = try #require(calendar.date(from: .init(year: 2094, month: 11, day: 22, hour: 12)))
                comment.content = "Created before the widget edit"
                #expect(try await comment.perform().value == true)
                let original = try persistedRecords(at: index)
                let neighbor = try persistedRecords(at: index + 1)

                for surface in WidgetCalendarSurface.allCases {
                    _ = try await SetWidgetCalendarDayMarkIntent(dayIndex: index, mark: .off, surface: surface).perform()
                    let update = UpdateDayMarkIntent()
                    update.date = comment.date
                    update.mark = .work
                    #expect(try await update.perform().value == true)
                    let stored = try persistedRecords(at: index)
                    #expect(stored.marks.count == 1)
                    #expect(stored.marks.first?.id == original.marks.first?.id)
                    #expect(stored.marks.first?.creationTime == originalTime)
                    #expect(stored.marks.first?.dayType == .workDay)
                    #expect(stored.comments == original.comments)
                    let untouched = try persistedRecords(at: index + 1)
                    #expect(untouched.marks == neighbor.marks)
                    #expect(untouched.comments == neighbor.comments)
                }
            }
        }
    }

    @Test func failedDatabaseWritesShouldNotReportSuccessOrChangeExistingRecords() async throws {
        if #available(iOS 17.0, *) {
            let index = GregorianDay(year: 2094, month: .nov, day: 24).julianDay
            try await withRestoredData(indices: [index]) { calendar in
                try AppDatabase.shared.setCustomDay(.workDay, at: index)
                let original = try persistedRecords(at: index)
                let writer = try #require(AppDatabase.shared.dbWriter)
                // Exercise an actual SQLite transaction failure, without replacing the app DB.
                try await writer.write { db in
                    try db.execute(sql: """
                        CREATE TRIGGER intent_regression_reject_mark BEFORE UPDATE ON custom_day
                        WHEN OLD.day_index = \(index)
                        BEGIN SELECT RAISE(ABORT, 'Intent regression write failure'); END;
                        """)
                }
                defer {
                    do {
                        try writer.write { try $0.execute(sql: "DROP TRIGGER intent_regression_reject_mark") }
                    } catch {
                        Issue.record(error, "Could not remove the regression test trigger")
                    }
                }
                let update = UpdateDayMarkIntent()
                update.date = try #require(calendar.date(from: .init(year: 2094, month: 11, day: 24, hour: 12)))
                update.mark = .off
                await #expect(throws: (any Error).self) { _ = try await update.perform() }
                for surface in WidgetCalendarSurface.allCases {
                    await #expect(throws: (any Error).self) {
                        _ = try await SetWidgetCalendarDayMarkIntent(dayIndex: index, mark: .off, surface: surface).perform()
                    }
                }
                let stored = try persistedRecords(at: index)
                #expect(stored.marks == original.marks)
                #expect(stored.comments == original.comments)
                let check = CheckDayIntent()
                check.date = update.date
                #expect(try await check.perform().value == false)
            }
        }
    }

    @Test func existingMarkShortcutShouldSucceedWhenOnlyWidgetPublicationFails() async throws {
        let index = GregorianDay(year: 2094, month: .nov, day: 25).julianDay
        try await withRestoredData(indices: [index]) { calendar in
            let intent = UpdateDayMarkIntent()
            intent.date = try #require(calendar.date(from: .init(year: 2094, month: 11, day: 25, hour: 12)))
            intent.mark = .off
            var publicationAttempts = 0
            let success = try intent.updateMark {
                publicationAttempts += 1
                return false
            }
            #expect(success)
            #expect(publicationAttempts == 1)
            #expect(CustomDayManager.shared.fetchCustomDay(by: index)?.dayType == .offDay)
            let check = CheckDayIntent()
            check.date = intent.date
            #expect(try await check.perform().value == true)
        }
    }

    @Test func existingIntentsShouldKeepPublicHolidayAndCustomMarkPriority() async throws {
        let index = GregorianDay(year: 2026, month: .dec, day: 25).julianDay
        try await withRestoredData(indices: [index]) { calendar in
            PublicPlanManager.shared.select(plan: .app(AppPublicPlan(file: .us)))
            let holiday = try #require(PublicPlanManager.shared.publicDay(at: index))
            #expect(holiday.type == .offDay)
            try AppDatabase.shared.setCustomDay(nil, at: index)
            let date = try #require(calendar.date(from: .init(year: 2026, month: 12, day: 25, hour: 12)))
            let check = CheckDayIntent()
            check.date = date
            let detail = DayDetailIntent()
            detail.date = date
            #expect(try await check.perform().value == true)
            let publicResult = try await detail.perform()
            #expect(publicResult.value?.id == index)
            #expect(publicResult.value?.publicOffDay == true)
            #expect(publicResult.value?.publicDayName == holiday.name)
            if #available(iOS 17.0, *) {
                _ = try await SetWidgetCalendarDayMarkIntent(dayIndex: index, mark: .work).perform()
                #expect(try await check.perform().value == false)
                let customResult = try await detail.perform()
                #expect(customResult.value?.publicOffDay == true)
                #expect(customResult.value?.userOffDay == false)
                #expect(customResult.value?.publicDayName == holiday.name)
                #expect(customResult.value?.finalOffDay == false)
            }
        }
    }

    @Test func widgetCommentsShouldKeepDistantBadgesAndFetchTextWhenBrowsing() async throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let parts = calendar.dateComponents([.year, .month, .day], from: Date())
        let today = GregorianDay(year: parts.year!, month: Month(rawValue: parts.month!)!, day: parts.day!).julianDay
        let distant = GregorianDay(year: 2001, month: .feb, day: 5).julianDay
        let future = GregorianDay(year: 2200, month: .feb, day: 5).julianDay
        let previousMonth = WidgetCalendarMonthStore.current
        WidgetCalendarMonthStore.current = nil
        defer { WidgetCalendarMonthStore.current = previousMonth; WidgetCalendarPublisher.shared.publishNow() }
        try await withRestoredData(indices: [today, distant, future]) { _ in
            let writer = try #require(AppDatabase.shared.dbWriter)
            try writer.write { db in
                for index in [today, distant, future] {
                    try CustomComment.filter(CustomComment.Columns.dayIndex == index).deleteAll(db)
                    var comment = CustomComment(dayIndex: Int64(index), content: "Note for \(index)")
                    try comment.insert(db)
                }
            }
            #expect(WidgetCalendarPublisher.shared.publishNow())
            let snapshot = try #require(WidgetCalendarStore.load())
            #expect(snapshot.details?[today]?.comment == "Note for \(today)")
            for index in [distant, future] {
                #expect(snapshot.details?[index]?.hasComment == true)
                #expect(snapshot.details?[index]?.comment == nil)
            }
            let summary = try #require(WidgetCalendarStore.loadSummary())
            #expect(summary.details == nil && summary.display == nil && summary.interaction == nil)
            WidgetCalendarMonthStore.current = GregorianDay(year: 2001, month: .feb, day: 1).julianDay
            #expect(WidgetCalendarPublisher.shared.publishNow())
            #expect(WidgetCalendarStore.load()?.details?[distant]?.comment == "Note for \(distant)")
            #expect(WidgetCalendarStore.loadSummary() == summary)
        }
    }

    @Test func widgetCommitsShouldUpdateNotificationsEvenWhenPublicationFails() async throws {
        let index = GregorianDay(year: 2094, month: .nov, day: 27).julianDay
        try await withRestoredData(indices: [index]) { _ in
            var notificationsUpdated = false
            var publicationAttempts = 0
            await #expect(throws: WidgetCalendarIntentError.publicationFailed) {
                try await WidgetCalendarIntentHandler.setMark(.off, dayIndex: index,
                    publishSnapshot: {
                        #expect(notificationsUpdated)
                        publicationAttempts += 1
                        return false
                    }, updateNotifications: {
                        await Task.yield()
                        notificationsUpdated = true
                    })
            }
            #expect(notificationsUpdated && publicationAttempts > 0)
            #expect(CustomDayManager.shared.fetchCustomDay(by: index)?.dayType == .offDay)
            #expect(WidgetCalendarInteractionStore.current?.error == true)
        }
    }

    private func persistedRecords(at index: Int) throws -> (marks: [CustomDay], comments: [CustomComment]) {
        var configuration = Configuration()
        configuration.readonly = true
        let url = try AppDatabase.databaseFolderURL().appendingPathComponent(AppDatabase.dbName)
        let connection = try DatabaseQueue(path: url.path, configuration: configuration)
        let records = try connection.read { db in
            (marks: try CustomDay.filter(CustomDay.Columns.dayIndex == index).order(CustomDay.Columns.id).fetchAll(db),
             comments: try CustomComment.filter(CustomComment.Columns.dayIndex == index).order(CustomComment.Columns.id).fetchAll(db))
        }
        try connection.close()
        return records
    }

    private enum UnavailableWidgetCache: CaseIterable {
        case missing, corrupt, unwritable
    }

    private func withUnavailableWidgetCache(_ state: UnavailableWidgetCache,
                                            operation: () async throws -> Void) async throws {
        let url = try WidgetCalendarStore.fileURL()
        let previous = try Data(contentsOf: url)
        try FileManager.default.removeItem(at: url)
        defer {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                try previous.write(to: url, options: .atomic)
            } catch {
                Issue.record(error, "Could not restore the widget snapshot")
            }
        }
        switch state {
        case .missing: break
        case .corrupt: try Data("invalid widget JSON".utf8).write(to: url)
        case .unwritable: try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        }
        try await operation()
    }

    private func withRestoredData(indices: [Int], operation: (Calendar) async throws -> Void) async throws {
        if let expected = ProcessInfo.processInfo.environment["OFF_DAY_EXPECTED_CALENDAR"] {
            #expect(String(describing: Calendar.current.identifier) == expected)
        }
        let writer = try #require(AppDatabase.shared.dbWriter)
        let marks = CustomDay.filter(indices.contains(CustomDay.Columns.dayIndex))
        let comments = CustomComment.filter(indices.contains(CustomComment.Columns.dayIndex))
        let savedMarks = try await writer.read { try marks.fetchAll($0) }
        let savedComments = try await writer.read { try comments.fetchAll($0) }
        let previousPlan = PublicPlanManager.shared.dataSource
        let interaction = WidgetCalendarInteractionStore.current
        PublicPlanManager.shared.select(plan: nil)
        defer {
            do {
                try writer.write { db in
                    try marks.deleteAll(db)
                    try comments.deleteAll(db)
                    for var mark in savedMarks { try mark.insert(db) }
                    for var comment in savedComments { try comment.insert(db) }
                }
            } catch {
                Issue.record(error, "Could not restore the test database records")
            }
            PublicPlanManager.shared.select(plan: previousPlan?.plan, language: previousPlan?.language)
            WidgetCalendarInteractionStore.current = interaction
            NotificationCenter.default.post(name: .DatabaseUpdated, object: nil)
            WidgetCalendarPublisher.shared.publishNow()
        }
        try await operation(WidgetCalendarTimeline.calendar())
    }
}
