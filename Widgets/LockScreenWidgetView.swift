import SwiftUI
import WidgetKit

struct LockScreenWidgetView: View {
    var entry: WidgetCalendarEntry

    var body: some View {
        if #available(iOS 17.0, *) {
            LockScreenWidgetContent(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        } else {
            LockScreenWidgetContent(entry: entry)
        }
    }
}

/// Keep the two days equally prominent; the status is the first thing to read.
struct LockScreenWidgetContent: View {
    var entry: WidgetCalendarEntry

    @Environment(\.calendar) private var calendar

    var body: some View {
        Group {
            if let today = entry.today, let tomorrow = entry.tomorrow {
                HStack(spacing: 12) {
                    dayColumn("widget.today", day: today, date: entry.date)
                    Rectangle()
                        .fill(.primary.opacity(0.18))
                        .frame(width: 1, height: 36)
                        .accessibilityHidden(true)
                    dayColumn("widget.tomorrow", day: tomorrow, date: tomorrowDate)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("widget.openApp.title")
                        .font(.subheadline.weight(.semibold))
                    Text("widget.openApp.subtitle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var tomorrowDate: Date {
        calendar.date(byAdding: .day, value: 1, to: entry.date) ?? entry.date
    }

    private func dayColumn(_ title: LocalizedStringKey, day: WidgetCalendarDay, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey(day.isOffDay ? "widget.offDay" : "widget.workDay"))
                .font(.system(size: 17, weight: .semibold))
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
            Group {
                if let name = day.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                    Text(verbatim: name)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .truncationMode(.tail)
                } else {
                    Text(date, format: .dateTime.weekday(.abbreviated))
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
