import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct WidgetCalendarDetailView: View {
    @Environment(\.locale) private var locale
    @Environment(\.widgetCalendarColors) private var colors
    var day: WidgetCalendarDayItem
    var display: WidgetCalendarDisplay
    var surface: WidgetCalendarSurface
    var hasError: Bool

    private var compact: Bool { surface != .month }
    private var small: Bool { surface == .threeDays }
    private var metrics: WidgetCalendarDetailMetrics { .init(surface: surface) }

    var body: some View {
        ViewThatFits(in: .vertical) {
            panel(showsComment: true, showsHolidayName: true)
            panel(showsComment: false, showsHolidayName: true)
            panel(showsComment: false, showsHolidayName: false)
        }
    }

    private func panel(showsComment: Bool, showsHolidayName: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Text(verbatim: day.formattedDate(locale: locale, compact: compact))
                if showsHolidayName, let name = day.value?.name {
                    Text(verbatim: name).font(.system(size: compact ? 10 : 17))
                }
            }
            .font(.system(size: small ? 12 : (compact ? 14 : 17)))
            .lineLimit(compact ? 1 : 2).minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .foregroundStyle(day.foreground(display: display, colors: colors))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, compact ? 8 : 12).padding(.vertical, compact ? 6 : 14)
            .background(WidgetCalendarDayBackground(appearance: day.palette(display: display)))
            VStack(spacing: compact ? 6 : 12) {
                if !compact {
                    Text("detail.custom").font(.footnote)
                        .foregroundStyle(colors.text.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                WidgetCalendarMarkLayout(prefersVertical: small, spacing: metrics.buttonSpacing,
                                         selectionAllowance: metrics.selectionAllowance) {
                    markButton(off: true)
                    markButton(off: false)
                }
                if showsComment, !hasError, let comment = day.detail?.comment, !comment.isEmpty {
                    if !compact { Divider() }
                    Text(verbatim: comment)
                        .font(.system(size: small ? 10 : (compact ? 11 : 16)))
                        .foregroundStyle(colors.text.opacity(0.8))
                        .lineLimit(compact ? 1 : 2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                if hasError {
                    Text("widget.month.updateFailed").font(.system(size: compact ? 10 : 13))
                        .foregroundStyle(colors.workAccent).lineLimit(2)
                }
            }
            .padding(metrics.contentInset)
        }
        .background(colors.background)
        .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func markButton(off: Bool) -> some View {
        let selected = day.detail?.customIsOffDay == off
        let paint = colors.markControl(isOffDay: off, selected: selected)
        let next = CalendarDayMarkInteraction.nextValue(current: day.detail?.customIsOffDay, tapped: off)
        let target: WidgetDayMark = next.map { $0 ? .off : .work } ?? .automatic
        return Button(intent: SetWidgetCalendarDayMarkIntent(dayIndex: day.id, mark: target, surface: surface)) {
            HStack(spacing: 4) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: metrics.buttonFontSize * 0.8, weight: .semibold))
                        .frame(width: metrics.buttonFontSize)
                }
                markTitle(off: off, paint: paint)
            }
            .font(.system(size: metrics.buttonFontSize, weight: .medium))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(paint.foreground)
            .padding(.horizontal, metrics.buttonHorizontalInset)
            .padding(.vertical, metrics.buttonVerticalInset)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: metrics.buttonHeight)
            .background {
                if paint.usesPatterns {
                    WidgetCalendarDayBackground(appearance: paint.palette)
                } else {
                    paint.background
                }
            }
            .clipShape(Capsule(style: .continuous))
            .overlay { Capsule(style: .continuous).strokeBorder(paint.stroke, lineWidth: CalendarDayTexture.lineWidth) }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .layoutValue(key: WidgetCalendarMarkSelectedKey.self, value: selected)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(Text(LocalizedStringKey(off ? "detail.day.off.title" : "detail.day.work.title")))
    }

    @ViewBuilder
    private func markTitle(off: Bool, paint: CalendarMarkControlAppearance) -> some View {
        if paint.usesPatterns {
            let title = String(localized: off ? "detail.day.off.title" : "detail.day.work.title", locale: locale)
            let font = UIFont.systemFont(ofSize: metrics.buttonFontSize, weight: .medium)
            let layout = CalendarInkTextLayout.resolve(title, font: font,
                size: CGSize(width: .greatestFiniteMagnitude, height: font.lineHeight), minimumScaleFactor: 1, locale: locale)
            WidgetCalendarInkText(text: title, font: font, foreground: paint.foreground, backing: paint.background)
                .frame(width: ceil(layout.advance) + 3, height: ceil(font.lineHeight) + 3)
        } else {
            Text(LocalizedStringKey(off ? "detail.day.off.title" : "detail.day.work.title"))
        }
    }
}
