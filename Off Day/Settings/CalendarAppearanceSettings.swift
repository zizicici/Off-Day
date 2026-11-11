import Foundation
import MoreKit

enum CalendarAppearanceSettings {
    static let key = "com.zizicici.common.settings.CalendarAppearance"

    static func load(from defaults: UserDefaults = .standard) -> CalendarVisualStyle {
        guard let data = defaults.data(forKey: key),
              let style = try? JSONDecoder().decode(CalendarVisualStyle.self, from: data) else { return .init() }
        return style
    }

    static func save(_ style: CalendarVisualStyle, to defaults: UserDefaults = .standard,
                     notificationCenter: NotificationCenter = .default) {
        guard style != load(from: defaults), let data = try? JSONEncoder().encode(style) else { return }
        defaults.set(data, forKey: key)
        if Thread.isMainThread {
            notificationCenter.post(name: .SettingsUpdate, object: nil)
        } else {
            DispatchQueue.main.async { notificationCenter.post(name: .SettingsUpdate, object: nil) }
        }
    }
}
