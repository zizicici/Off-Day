import Foundation

enum WidgetCalendarStore {
    static let appGroup = "group.com.zizicici.zzz"

    static func fileURL() throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return container.appendingPathComponent("widget-calendar.json")
    }

    static func summaryFileURL() throws -> URL {
        try fileURL().deletingLastPathComponent().appendingPathComponent("widget-calendar-summary.json")
    }

    static func loadSummary() -> WidgetCalendarSnapshot? {
        if let url = try? summaryFileURL(), let snapshot = load(from: url) { return snapshot }
        // Installed widgets can still read the previous snapshot before the first app launch.
        return load()?.summary
    }

    static func load(from url: URL? = nil) -> WidgetCalendarSnapshot? {
        guard let url = try? url ?? fileURL(),
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetCalendarSnapshot.self, from: data),
              snapshot.isValid else { return nil }
        return snapshot
    }
}
