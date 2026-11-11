import Foundation
import SwiftUI
import Testing
import UIKit
import ZCCalendar
@testable import Off_Day

@Suite(.serialized)
@MainActor
struct AppThemeTests {
    private let styles = [CalendarVisualStyle(), .init(coloredPatterns: true), .init(palette: .mono)]

    @Test func coloredPatternsShouldKeepGreenAndMonoShouldStayAchromatic() {
        for mode in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: mode)
            let green = AppTheme(style: .init(coloredPatterns: true))
            for role in [AppTheme.ColorRole.accent, .navigationBackground] {
                let classic = AppTheme(style: .init())
                expectColor(green.color(role, for: traits), classic.color(role, for: traits))
            }
            for theme in [green, AppTheme(style: .init())] {
                expectColor(theme.color(.attention, for: traits), UIColor.systemPink.resolvedColor(with: traits))
                expectColor(theme.color(.success, for: traits), UIColor.systemGreen.resolvedColor(with: traits))
            }
            let mono = AppTheme(style: .init(palette: .mono))
            for role in [AppTheme.ColorRole.accent, .onAccent, .navigationBackground, .navigationText, .attention, .success, .warning, .destructive] {
                let values = rgb(mono.color(role, for: traits))
                #expect(abs(values[0] - values[1]) < 0.001 && abs(values[1] - values[2]) < 0.001)
            }
        }
    }

    @Test func semanticColorsShouldKeepClassicAssetsAndThemeContrast() {
        for style in styles {
            let theme = AppTheme(style: style)
            for mode in [UIUserInterfaceStyle.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: mode)
                if theme.usesPatterns {
                    let pairs: [(AppTheme.ColorRole, AppTheme.ColorRole)] = [(.text, .background),
                                                                          (.onAccent, .accent), (.navigationText, .navigationBackground)]
                    for (foreground, background) in pairs {
                        #expect(contrast(theme.color(foreground, for: traits), theme.color(background, for: traits)) >= 4.5)
                    }
                } else {
                    expectColor(theme.color(.navigationBackground, for: traits), UIColor.navigationBar.resolvedColor(with: traits))
                    expectColor(theme.color(.accent, for: traits), UIColor.offDay.resolvedColor(with: traits))
                }
                for off in [true, false] {
                    let paint = theme.colors(for: traits).markControl(isOffDay: off, selected: true)
                    #expect(paint.usesPatterns == theme.usesPatterns)
                    if paint.usesPatterns {
                        #expect(contrast(UIColor(paint.foreground).resolvedColor(with: traits),
                                         UIColor(paint.background).resolvedColor(with: traits)) >= 4.5)
                    }
                }
            }
        }
    }

    @Test func changingThemeShouldRefreshLoadedUIAndKeepTheCommentDraft() throws {
        let previous = CalendarAppearanceSettings.load()
        defer { select(previous) }
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        let draft = "Unsaved theme regression draft"
        let editor = DayEditorViewController(comment: .init(dayIndex: 2_800_000, content: draft))
        let nav = NavigationController(rootViewController: editor)
        nav.overrideUserInterfaceStyle = .dark
        window.rootViewController = nav
        window.isHidden = false
        defer { window.isHidden = true; window.rootViewController = nil }
        nav.loadViewIfNeeded(); editor.loadViewIfNeeded(); window.layoutIfNeeded()
        let originalView = editor.view
        let text = try #require(descendants(editor.view).compactMap { $0 as? UITextView }.first)
        let responder = text.isFirstResponder
        for style in styles {
            select(style)
            window.layoutIfNeeded()
            #expect(editor.view === originalView)
            #expect(nav.viewControllers.first === editor)
            #expect(text.text == draft)
            #expect(text.isFirstResponder == responder)
            expectColor(editor.view.backgroundColor!.resolvedColor(with: editor.traitCollection),
                        AppTheme(style: style).color(.background, for: editor.traitCollection))
            let layer = try #require(editor.view.layer.backgroundColor)
            expectColor(UIColor(cgColor: layer), AppTheme(style: style).color(.background, for: editor.traitCollection))
        }
    }

    @Test func popoverShouldUseThemeControlsAndKeepItsSelectedRecord() throws {
        let previous = CalendarAppearanceSettings.load()
        defer { select(previous) }
        let controller = BlockDetailViewController(blockItem: item())
        controller.loadViewIfNeeded()
        let buttons = descendants(controller.view).compactMap { $0 as? CalendarMarkButton }
        #expect(buttons.count == 2)
        for style in styles {
            select(style)
            for button in buttons {
                button.updateConfiguration()
                #expect(button.configuration?.cornerStyle == .capsule)
                #expect(button.isSelected == !button.isOffDay)
                #expect((button.configuration?.image != nil) == button.isSelected)
                #expect(button.accessibilityLabel == String(localized: button.isOffDay ? "detail.day.off.title" : "detail.day.work.title"))
                if AppTheme.current.usesPatterns {
                    #expect(button.configuration?.background.customView is CalendarDayTextureView)
                    let title = try #require(button.configuration?.attributedTitle)
                    #expect(NSAttributedString(title).attribute(.attachment, at: 0, effectiveRange: nil) is NSTextAttachment)
                }
            }
            #expect(controller.customDayType == .workDay)
        }
    }

    @Test func dateStyleNamesAndMenusShouldDescribeTheActualTheme() throws {
        let previous = CalendarAppearanceSettings.load()
        defer { select(previous) }
        let home = BlockViewController(nibName: nil, bundle: nil)
        home.loadViewIfNeeded()
        for style in styles {
            select(style)
            let titleItem = UINavigationItem()
            titleItem.setTitle("2026", subtitle: "US Federal Holidays", menu: nil)
            let titleButton = try #require(titleItem.titleView as? UIButton)
            #expect(titleButton.accessibilityLabel == "2026")
            #expect(titleButton.accessibilityValue == "US Federal Holidays")
            let more = try #require(home.navigationItem.rightBarButtonItem?.menu)
            let appearance = try #require(more.children.compactMap { $0 as? UIMenu }.first { $0.identifier.rawValue == "calendar.appearance" })
            let sections = appearance.children.compactMap { $0 as? UIMenu }
            for identifier in ["calendar.appearance.baseOffDay", "calendar.appearance.holidayWorkday"] {
                let section = try #require(sections.first { $0.identifier.rawValue == identifier })
                #expect(section.options.contains(.displayInline))
            }
            let patterns = sections.flatMap(\.children).compactMap { $0 as? UIAction }
                .first { $0.identifier.rawValue == "calendar.appearance.coloredPatterns" }
            #expect(patterns?.image == nil)
            #expect(!more.children.compactMap { $0 as? UIMenu }.contains { $0.identifier.rawValue == "calendar.appearance.baseOffDay" })
            if AppTheme.current.usesPatterns {
                let colored = style.usesColoredPatterns
                #expect(WeekEndColorType.offDay.getName() == String(localized: colored ? "calendar.texture.greenDiagonal" : "calendar.texture.diagonal"))
                #expect(WeekEndColorType.blue.getName() == String(localized: colored ? "calendar.texture.blueHorizontal" : "calendar.texture.horizontal"))
                #expect(HolidayWorkColorType.workDay.getName() == String(localized: colored ? "calendar.texture.redDots" : "calendar.texture.dots"))
            }
        }
        #expect(UIImage(systemName: "swatchpalette") != nil)
        #expect(WeekEndColorType.offDay.rawValue == 0 && WeekEndColorType.blue.rawValue == 1)
        #expect(HolidayWorkColorType.workDay.rawValue == 0 && HolidayWorkColorType.paper.rawValue == 1)
    }

    @Test func renderThemesAcrossNavigationPopoverAndCommentEditor() async throws {
        let previous = CalendarAppearanceSettings.load()
        defer { select(previous) }
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews/AppThemes")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for mode in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: mode)
            var columns: [[UIImage]] = []
            for style in styles {
                select(style)
                let popover = BlockDetailViewController(blockItem: item())
                popover.loadViewIfNeeded()
                let header = try #require(descendants(popover.view).compactMap { $0 as? CalendarThemeHeaderLabel }.first)
                header.text = Locale.current.language.languageCode?.identifier == "zh"
                    ? "2026年11月10日 星期二\n公共假期与调休安排"
                    : "Tuesday, November 10, 2026\nPublic holiday arrangements"
                let popupImage = try await snapshotPopover(popover, traits: traits)
                let editor = DayEditorViewController(comment: .init(dayIndex: 2_800_000, content: "保留备注内容，与主题切换独立。"))
                let navigation = NavigationController(rootViewController: editor)
                let editorImage = try snapshot(navigation, traits: traits, width: 320, height: 280)
                let tutorials = NavigationController(rootViewController: TutorialsViewController())
                let tutorialImage = try snapshot(tutorials, traits: traits, width: 320, height: 460)
                let name = style.palette == .mono ? "mono" : style.usesColoredPatterns ? "colored-patterns" : "classic"
                try #require(tutorialImage.pngData()).write(to: folder.appendingPathComponent("tutorials-\(name)-\(mode == .dark ? "dark" : "light").png"))
                columns.append([popupImage, editorImage])
            }
            let sheet = HStack(alignment: .top, spacing: 20) {
                ForEach(styles.indices, id: \.self) { index in
                    VStack(spacing: 14) {
                        Text(verbatim: ["经典", "彩色纹理", "黑白"][index]).font(.headline)
                        Text(verbatim: "Popover").font(.caption)
                        Image(uiImage: columns[index][0])
                        Text(verbatim: "备注编辑 / 导航").font(.caption)
                        Image(uiImage: columns[index][1])
                    }.padding(16).background(AppTheme(style: styles[index]).color(.background, for: traits).swiftUIColor)
                }
            }.padding(20).foregroundStyle(mode == .dark ? .white : .black)
                .background(Color(white: mode == .dark ? 0.07 : 0.85))
            let renderer = ImageRenderer(content: sheet)
            renderer.scale = 2
            try #require(renderer.uiImage?.pngData()).write(to: folder.appendingPathComponent("app-themes-\(mode == .dark ? "dark" : "light").png"))
        }
    }

    @Test func renderHomeNavigationAndWeekdayAsOneThemedSurface() async throws {
        let previous = CalendarAppearanceSettings.load()
        defer { select(previous) }
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WidgetPreviews/AppThemes")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for mode in [UIUserInterfaceStyle.light, .dark] {
            var images: [UIImage] = []
            for style in styles {
                select(style)
                let image = try await snapshotHome(traits: .init(userInterfaceStyle: mode))
                images.append(image)
                if style.usesColoredPatterns {
                    try #require(image.pngData()).write(to: folder.appendingPathComponent("home-colored-patterns-\(mode == .dark ? "dark" : "light").png"))
                }
            }
            let sheet = HStack(alignment: .top, spacing: 20) {
                ForEach(styles.indices, id: \.self) { index in
                    VStack(spacing: 14) {
                        Text(verbatim: ["经典", "彩色纹理", "黑白"][index]).font(.headline)
                        Image(uiImage: images[index])
                    }
                }
            }.padding(20).foregroundStyle(mode == .dark ? .white : .black)
                .background(Color(white: mode == .dark ? 0.07 : 0.85))
            let renderer = ImageRenderer(content: sheet)
            renderer.scale = 2
            try #require(renderer.uiImage?.pngData()).write(to: folder.appendingPathComponent("home-themes-\(mode == .dark ? "dark" : "light").png"))
        }
    }

    @Test func initialHomeNavigationShouldKeepThePersistedPatternAfterScreenSetup() throws {
        let previous = CalendarAppearanceSettings.load()
        defer { select(previous) }
        select(.init(coloredPatterns: true))
        for mode in [UIUserInterfaceStyle.light, .dark] {
            let home = ThemeHomePreviewController(nibName: nil, bundle: nil)
            let nav = NavigationController(rootViewController: home)
            nav.overrideUserInterfaceStyle = mode
            // Theme application can run before the selected tab loads its content.
            nav.refreshTheme()
            home.loadViewIfNeeded()
            #expect(nav.navigationBar.standardAppearance.backgroundColor?.cgColor.colorSpace?.model == .pattern)
            #expect(nav.navigationBar.scrollEdgeAppearance?.backgroundColor?.cgColor.colorSpace?.model == .pattern)
            // A later screen appearance setup must also retain the active theme.
            home.updateNavigationBarStyle(hideShadow: true)
            #expect(nav.navigationBar.standardAppearance.backgroundColor?.cgColor.colorSpace?.model == .pattern)
        }
    }

    private func snapshotHome(traits: UITraitCollection) async throws -> UIImage {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = .init(x: 0, y: 0, width: 320, height: 460)
        let home = ThemeHomePreviewController(nibName: nil, bundle: nil)
        let nav = NavigationController(rootViewController: home)
        nav.overrideUserInterfaceStyle = traits.userInterfaceStyle
        let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
        window.rootViewController = nav
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previousKeyWindow?.makeKey() }
        nav.loadViewIfNeeded(); home.loadViewIfNeeded(); window.layoutIfNeeded()
        let style = AppTheme.current.style
        var data = home.dataSource.snapshot()
        let month = GregorianMonth(year: 2026, month: .nov)
        data.appendSections([.month(month)])
        data.appendItems([.month(.init(text: month.month.name, color: AppColor.text))])
        data.appendSections([.row(month)])
        let roles = ["PaperColor", "OffDayColor", "WeekEndColor", "WorkDayColor"]
        data.appendItems((1...30).map { day in
            let role = CalendarDayAppearance.Palette(backgroundAsset: roles[(day - 1) % roles.count], whiteText: day % 4 != 1)
            let paint = CalendarCellPresentation(style: style, appearance: role)
            var block = item()
            block.index = GregorianDay(year: 2026, month: .nov, day: day).julianDay
            block.customDayInfo = .init(dayIndex: block.index, customDay: day <= 4
                ? .init(dayIndex: Int64(block.index), dayType: day % 2 == 0 ? .workDay : .offDay) : nil)
            block.appearance = role; block.visualStyle = style
            block.backgroundColor = paint.background; block.foregroundColor = paint.foreground
            return .block(block)
        })
        await withCheckedContinuation { continuation in
            home.dataSource.applySnapshotUsingReloadData(data) { continuation.resume() }
        }
        window.layoutIfNeeded(); home.collectionView.layoutIfNeeded()
        let weekday = try #require(descendants(home.view).compactMap { $0 as? WeekdayOrderView }.first)
        weekday.refreshTheme()
        #expect((nav.navigationBar.standardAppearance.backgroundColor?.cgColor.colorSpace?.model == .pattern) == style.usesColoredPatterns)
        #expect((nav.navigationBar.scrollEdgeAppearance?.backgroundColor?.cgColor.colorSpace?.model == .pattern) == style.usesColoredPatterns)
        #expect(weekday.stackView.arrangedSubviews.count == 7)
        #expect(home.dataSource.snapshot().itemIdentifiers.count == 31)
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        // Pushing an ordinary screen must restore its native solid navigation surface.
        let other = UIViewController()
        nav.setViewControllers([home, other], animated: false)
        other.updateNavigationBarStyle()
        nav.refreshTheme()
        #expect(nav.navigationBar.standardAppearance.backgroundImage == nil)
        #expect(nav.navigationBar.standardAppearance.backgroundColor?.cgColor.colorSpace?.model != .pattern)
        return image
    }

    private func item() -> BlockItem {
        let index = GregorianDay(year: 2026, month: .nov, day: 10).julianDay
        return .init(index: index, publicDayName: nil, baseCalendarDayType: .offDay, publicDayType: nil,
            customDayInfo: .init(dayIndex: index, customDay: .init(dayIndex: Int64(index), dayType: .workDay),
                                 customComment: .init(dayIndex: Int64(index), content: "与家人出游")),
            backgroundColor: .white, foregroundColor: .black, isToday: false,
            alternativeCalendarDayName: nil, alternativeCalendarA11yName: nil,
            appearance: .init(backgroundAsset: "OffDayColor", whiteText: true))
    }

    private func snapshot(_ controller: UIViewController, traits: UITraitCollection, width: CGFloat, height: CGFloat? = nil) throws -> UIImage {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: width, height: height ?? 400)
        controller.overrideUserInterfaceStyle = traits.userInterfaceStyle
        window.rootViewController = controller
        let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previousKeyWindow?.makeKey() }
        controller.loadViewIfNeeded()
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        if let height { controller.view.frame = .init(x: 0, y: 0, width: width, height: height) }
        else {
            let size = controller.view.systemLayoutSizeFitting(.init(width: width, height: 1000),
                withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            print("THEME_POPOVER_FITTING \(size)")
            #expect(size.height > 160)
            controller.view.frame = .init(x: 0, y: 0, width: width, height: size.height)
            window.frame.size.height = size.height
        }
        window.layoutIfNeeded(); controller.view.layoutIfNeeded()
        #expect(!controller.view.hasAmbiguousLayout)
        return UIGraphicsImageRenderer(size: controller.view.bounds.size).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    private func snapshotPopover(_ controller: BlockDetailViewController, traits: UITraitCollection) async throws -> UIImage {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = .init(x: 0, y: 0, width: 320, height: 380)
        let host = ThemePopoverPreviewHost()
        host.overrideUserInterfaceStyle = traits.userInterfaceStyle
        host.view.backgroundColor = AppColor.background
        window.rootViewController = host
        let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
        window.makeKeyAndVisible()
        defer {
            host.dismiss(animated: false)
            window.isHidden = true; window.rootViewController = nil; previousKeyWindow?.makeKey()
        }
        controller.overrideUserInterfaceStyle = traits.userInterfaceStyle
        controller.view.frame = .init(x: 0, y: 0, width: 280, height: 1000)
        controller.view.layoutIfNeeded()
        controller.preferredContentSize = controller.view.systemLayoutSizeFitting(.init(width: 280, height: 1000),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        controller.modalPresentationStyle = .popover
        let presentation = try #require(controller.popoverPresentationController)
        presentation.sourceView = host.view
        presentation.sourceRect = .init(x: 159, y: 65, width: 2, height: 2)
        presentation.permittedArrowDirections = .up
        presentation.delegate = host
        #expect(host.view.window === window)
        await withCheckedContinuation { continuation in
            host.present(controller, animated: false) { continuation.resume() }
        }
        window.layoutIfNeeded(); controller.view.layoutIfNeeded()
        let buttons = descendants(controller.view).compactMap { $0 as? CalendarMarkButton }
        #expect(buttons.allSatisfy { $0.bounds.width > 80 && $0.bounds.height > 30 })
        let date = try #require(descendants(controller.view).compactMap { $0 as? CalendarThemeHeaderLabel }.first)
        #expect(date.bounds.height > 20)
        return UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    private func select(_ style: CalendarVisualStyle) {
        CalendarAppearanceSettings.save(style)
        ThemeManager.shared.updateAppearance()
    }

    private func descendants(_ view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }

    private func expectColor(_ actual: UIColor, _ expected: UIColor, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(zip(rgb(actual), rgb(expected)).allSatisfy { abs($0 - $1) < 0.005 }, sourceLocation: sourceLocation)
    }

    private func rgb(_ color: UIColor) -> [CGFloat] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b]
    }

    private func contrast(_ foreground: UIColor, _ background: UIColor) -> Double {
        func luminance(_ color: UIColor) -> Double {
            let v = rgb(color).map { value -> Double in let c = Double(value); return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
            return v[0] * 0.2126 + v[1] * 0.7152 + v[2] * 0.0722
        }
        let a = luminance(foreground), b = luminance(background)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}

private final class ThemePopoverPreviewHost: UIViewController, UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle { .none }
}

private final class ThemeHomePreviewController: BlockViewController {
    // Deterministic fixture; do not read or write the user's records for a preview.
    override func viewDidAppear(_ animated: Bool) {}
}

private extension UIColor {
    var swiftUIColor: Color { Color(uiColor: self) }
}
