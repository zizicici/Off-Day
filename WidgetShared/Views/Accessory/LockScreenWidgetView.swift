import SwiftUI
import WidgetKit

struct LockScreenWidgetView: View {
    var entry: WidgetCalendarEntry

    var body: some View {
        WidgetAccessoryContainer {
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
                        .frame(width: 1)
                        .padding(.vertical, 4)
                        .accessibilityHidden(true)
                    dayColumn("widget.tomorrow", day: tomorrow, date: tomorrowDate)
                }
            } else {
                WidgetOpenAppPlaceholder(style: .accessory)
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var tomorrowDate: Date {
        calendar.date(byAdding: .day, value: 1, to: entry.date) ?? entry.date
    }

    private func dayColumn(_ title: LocalizedStringKey, day: WidgetCalendarDay, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(height: 14, alignment: .leading)
            Text(LocalizedStringKey(day.isOffDay ? "widget.offDay" : "widget.workDay"))
                .font(.system(size: 22, weight: .semibold))
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .frame(height: 14, alignment: .leading)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
