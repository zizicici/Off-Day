# Widget shared code

`WidgetShared` is compiled into both the main app and the widget extension. UIKit
calendar cells also use its appearance, texture, mark geometry and ink text rules.

- `Views`: each widget's composition; `Components` owns date cells, grids,
  weekday headers, home/accessory containers and placeholders.
- `Layout`: resolved cell sizes, the two outside bottom corner arcs, and editor
  measurements. Geometry is measured once per calendar, never inside date cells.
- `Appearance`: shared colors, textures, text backing and countdown typography.
- `Models`: snapshot/entry models and stable `WidgetKind` identifiers.
- `Formatting`: Gregorian dates with localized language and field ordering.
- `Timeline`: local-midnight fallback entries and calendar editor expiry refreshes.
- `Intents`: action/configuration schemas; configuration types and parameter names
  are persisted by WidgetKit and must remain stable.
- `Storage`: read-only App Group snapshot access.

`Widgets` contains registrations, gallery presentation and timeline providers.
Gallery order stays in `WidgetsBundle`. Static iOS 16 and configurable iOS 17+
registrations share their identifiers and gallery metadata.

## Data ownership

The main app's `WidgetCalendarIntentHandler` commits edits to the app database,
then `WidgetCalendarPublisher` publishes atomic snapshots and reloads widgets.
The extension must not write the database or App Group. Summary snapshots serve
the original status widgets; detailed snapshots serve calendars and countdowns.
The reload groups in `WidgetKind` must stay consistent with those readers.

## Verification

- `WidgetMonthRenderingTests`, `WidgetCalendarStyleTests`,
  `LockScreenThreeDayWidgetTests`, `WidgetAccessoryRenderingTests` and
  `CalendarAppearanceTests` render the actual shared views in light/dark mode,
  supported languages, themes, calendar shapes, editor and missing-data states.
  PNGs are written to the simulator app's `Documents/WidgetPreviews` directory.
- `WidgetCompatibilityTests`, the calendar/month/period/countdown tests and
  `WidgetCalendarPublishingTests` cover identifiers, local midnight/DST, snapshot
  compatibility and database-backed edits.
- `scripts/test-gregorian-regressions.sh <simulator-udid>` runs existing App Intent
  and widget date regressions under Gregorian, Buddhist, Islamic and Japanese
  system-calendar settings. The app's data model remains Gregorian.
