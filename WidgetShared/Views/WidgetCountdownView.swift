import SwiftUI

struct WidgetCountdownView: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    var entry: WidgetCountdownEntry

    private var colors: WidgetCountdownColors { entry.style.palette.colors(for: colorScheme) }

    var body: some View {
        WidgetCalendarContainer(isReady: entry.isReady, background: colors.background,
                                palette: entry.style.palette.calendarPalette) { _ in
            VStack(alignment: .leading, spacing: 0) {
                heading
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(colors.secondary)
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, minHeight: 16, maxHeight: 16, alignment: .leading)
                Group {
                    if let value = entry.countdown {
                        Text(value.daysRemaining, format: .number.grouping(.never))
                            .kerning(-2)
                            .lineLimit(1).minimumScaleFactor(0.3)
                            .overlay(alignment: Alignment(horizontal: .trailing, vertical: .firstTextBaseline)) {
                                Text("widget.countdown.dayUnit")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(colors.secondary.opacity(0.75))
                                    .fixedSize()
                                    .alignmentGuide(.trailing) { $0[.leading] - 5 }
                            }
                            // Center the digits themselves while reserving space for the unit.
                            .padding(.horizontal, 16)
                    } else {
                        Text(verbatim: "—").lineLimit(1)
                    }
                }
                .font(entry.style.font.numberFont(size: 80))
                .foregroundStyle(colors.number)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                footer
                    .frame(height: 16, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .foregroundStyle(colors.text)
            .accessibilityElement(children: .combine)
        }
    }

    private var heading: some View {
        Group {
            if let value = entry.countdown {
                let date = value.date.formatted(.dateTime.month(.abbreviated).day().widgetGregorian(locale: locale))
                Text("widget.countdown.until \(date)")
            } else {
                Text(LocalizedStringKey(entry.target == .publicHoliday ? "widget.countdown.target.publicHoliday" : "widget.countdown.target.offDay"))
            }
        }
    }

    private var footer: some View {
        Group {
            if let value = entry.countdown {
                if let name = value.name, !name.isEmpty {
                    Text(verbatim: name)
                } else if entry.target == .offDay {
                    Text(value.date, format: .dateTime.weekday(.wide).widgetGregorian(locale: locale))
                } else {
                    Text("widget.countdown.target.publicHoliday")
                }
            } else {
                Text("widget.countdown.none")
            }
        }
        .font(.system(size: 12, weight: .semibold))
        .lineLimit(1).minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(entry.countdown == nil ? colors.secondary : colors.text)
    }
}
