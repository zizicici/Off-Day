import SwiftUI
import UIKit
import WidgetKit

/// Shared by home and lock-screen calendars. No per-cell geometry reader, bitmap mask, or custom press behavior.
struct WidgetCalendarDayCell: View {
    @Environment(\.locale) private var locale
    @Environment(\.widgetCalendarColors) private var colors
    var day: WidgetCalendarDayItem
    var display: WidgetCalendarDisplay
    var surface: WidgetCalendarSurface
    var size: CGSize
    var shape: WidgetCalendarCellShape = .init()
    var showsTodayIndicator = true
    var isInteractive = true
    var showsShadow = true
    var dateFontSize: CGFloat = CalendarDayAppearance.dateFontSize
    private var symbolMarkSize: CGFloat { CalendarDayMarkGeometry.side(for: size.width) }

    var body: some View {
        if #available(iOS 17.0, *), isInteractive {
            Button(intent: SelectWidgetCalendarDayIntent(dayIndex: day.id, surface: surface)) { labels }
                .buttonStyle(.plain)
        } else {
            labels
        }
    }

    private var labels: some View {
        gridLabels
        .widgetAccentable(colors.usesSystemRendering && day.value?.isOffDay == true)
        .frame(width: size.width, height: size.height)
        .foregroundStyle(day.foreground(display: display, colors: colors))
        .background {
            WidgetCalendarDayBackground(appearance: day.palette(display: display)).clipShape(shape)
                .shadow(color: Color(uiColor: .systemGray).opacity(showsShadow ? Double(CalendarDayAppearance.shadowOpacity) : 0),
                        radius: CalendarDayAppearance.shadowRadius,
                        x: CalendarDayAppearance.shadowOffset.width, y: CalendarDayAppearance.shadowOffset.height)
        }
        .overlay(alignment: .topTrailing) {
            if let custom = day.detail?.customIsOffDay {
                if colors.usesOriginalMarks {
                    Image(custom ? "OffDayMark" : "WorkDayMark")
                        .resizable().frame(width: CalendarDayAppearance.markSize, height: CalendarDayAppearance.markSize)
                        .clipShape(WidgetCalendarMarkCorner())
                } else {
                    WidgetCalendarSymbolMark(isOffDay: custom,
                        foreground: colors.markFill(isOffDay: custom, appearance: day.palette(display: display)),
                        background: colors.markSymbol(appearance: day.palette(display: display)),
                        usesSystemRendering: colors.usesSystemRendering, side: symbolMarkSize)
                        .frame(width: symbolMarkSize, height: symbolMarkSize)
                        .clipShape(WidgetCalendarMarkCorner())
                        .widgetAccentable(colors.usesSystemRendering)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if day.detail?.hasComment == true {
                RoundedRectangle(cornerRadius: 2)
                    .fill(day.foreground(display: display, colors: colors).opacity(colors.usesSystemRendering ? 1 : 0.5))
                    .frame(width: CalendarDayAppearance.commentSize, height: CalendarDayAppearance.commentSize)
                    .padding(5)
            }
        }
        .overlay {
            if showsTodayIndicator && day.isToday {
                shape.strokeBorder(colors.todayStroke(for: day.palette(display: display)), lineWidth: CalendarDayAppearance.todayStrokeWidth)
                    .widgetAccentable(colors.usesSystemRendering)
            }
        }
        .contentShape(shape)
        .opacity(day.isCurrentMonth ? 1 : (colors.usesSystemRendering ? 0.75 : 0.38))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var gridLabels: some View {
        let desiredHeight: CGFloat = dateFontSize + 3 + (day.alternativeName != nil ? CalendarDayAppearance.alternativeHeight : 0)
            + (day.value?.name != nil ? CalendarDayAppearance.holidayHeight : 0)
        let scale = min(1, max(0.5, (size.height - CalendarDayAppearance.inset * 2) / desiredHeight))
        return VStack(spacing: 0) {
            dateText(String(day.day.day), size: dateFontSize,
                     weight: colors.usesSystemRendering ? .medium : .regular, monospaced: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let alternative = day.alternativeName {
                dateText(alternative, size: CalendarDayAppearance.alternativeFontSize)
                    .frame(height: CalendarDayAppearance.alternativeHeight * scale)
            }
            if let holiday = day.value?.name {
                dateText(holiday, size: CalendarDayAppearance.holidayFontSize, weight: .bold)
                    .frame(height: CalendarDayAppearance.holidayHeight * scale)
            }
        }
        .lineLimit(1).minimumScaleFactor(0.5)
        .padding(CalendarDayAppearance.inset)
    }

    @ViewBuilder
    private func dateText(_ text: String, size: CGFloat, weight: UIFont.Weight = .regular,
                          monospaced: Bool = false) -> some View {
        let appearance = day.palette(display: display)
        if colors.usesInkBacking(for: appearance) {
            WidgetCalendarInkText(text: text,
                font: monospaced ? .monospacedDigitSystemFont(ofSize: size, weight: weight) : .systemFont(ofSize: size, weight: weight),
                foreground: colors.foreground(for: appearance), backing: colors.background(for: appearance))
        } else {
            let fontWeight: Font.Weight = weight == .bold ? .bold : (weight == .medium ? .medium : .regular)
            if monospaced {
                Text(verbatim: text).font(.system(size: size, weight: fontWeight)).monospacedDigit()
            } else {
                Text(verbatim: text).font(.system(size: size, weight: fontWeight))
            }
        }
    }

    private var accessibilityLabel: Text {
        var result = Text(verbatim: day.formattedDate(locale: locale))
        if let value = day.value {
            result = result + Text(verbatim: ", ") + Text(LocalizedStringKey(value.isOffDay ? "widget.offDay" : "widget.workDay"))
        }
        for text in [day.alternativeName, day.value?.name, day.detail?.comment].compactMap({ $0 }) {
            result = result + Text(verbatim: ", ") + Text(verbatim: text)
        }
        return result
    }
}

private struct WidgetCalendarSymbolMark: View {
    var isOffDay: Bool
    var foreground: Color
    var background: Color
    var usesSystemRendering: Bool
    var side: CGFloat

    var body: some View {
        WidgetCalendarMarkTriangle()
            .fill(usesSystemRendering ? foreground.opacity(0.14) : foreground)
            .overlay(alignment: .topTrailing) {
                Image(systemName: CalendarDayMarkGeometry.symbol(isOffDay: isOffDay))
                    .resizable().scaledToFit()
                    .symbolRenderingMode(.monochrome)
                    .fontWeight(.bold)
                    .foregroundStyle(usesSystemRendering ? foreground : background)
                    .frame(width: side * 0.42, height: side * 0.42)
                    .padding(.top, side * 0.06).padding(.trailing, side * 0.06)
            }
            .overlay {
                Path { path in path.move(to: .zero); path.addLine(to: CGPoint(x: side, y: side)) }
                    .stroke(usesSystemRendering ? foreground.opacity(0.65) : background, lineWidth: 1)
            }
    }
}

private struct WidgetCalendarMarkTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path(CalendarDayMarkGeometry.triangle(in: rect))
    }
}

private struct WidgetCalendarMarkCorner: Shape {
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: .topRight,
                          cornerRadii: CGSize(width: CalendarDayAppearance.cornerRadius, height: CalendarDayAppearance.cornerRadius)).cgPath)
    }
}
