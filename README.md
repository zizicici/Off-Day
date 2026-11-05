<h4 align="right">English | <strong><a href="README_CN.md">中文</a></strong></h4>

<div align="center">
  <img src="zzz.png" width="180" height="180" alt="Off Day logo" />
  <h1>Off Day</h1>
  <p><strong>No alarms on off days.</strong></p>
  <p>A holiday-aware iOS app for day classification, automation, and reminders.</p>
</div>

<p align="center">
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0" /></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-iOS%2016%2B-blue.svg" alt="iOS 16+" /></a>
  <a href="https://apps.apple.com/app/id6501973975"><img src="https://img.shields.io/itunes/v/6501973975" alt="App Store" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT License" /></a>
</p>

## Overview

Off Day helps users decide whether a day should be treated as an off day or a work day, then use that result in iOS Shortcuts and notification workflows.

The app is local-first:
- Holiday data is bundled as JSON templates or user-imported custom plans.
- User overrides, comments, and settings are stored in a local SQLite database.
- Optional iCloud backup is available for database snapshots.

## Key Features

- Multi-layer day decision engine with deterministic priority:
  `User Mark > Public Holiday Template > Base Calendar`
- Built-in public holiday templates:
  China Mainland, Xinjiang, Tibet, Guangxi, Ningxia, Hong Kong, Macau (Public / Force / Civil Servant), Singapore, Thailand, Korea, Japan, United States
- Custom public holiday plans:
  create, edit, duplicate, import JSON, export JSON
- Subscription-based remote templates:
  subscribe via URL, background refresh, update review with diff comparison, accept/reject/pause
- Flexible base calendar modes:
  Standard weekly, Week-cycle, Day-cycle
- Rich App Intents for Shortcuts automation:
  check day type, check clash day, get day details, find next off/work day, update day mark, manage day comments
- Notification center for three scenarios:
  template expiration, upcoming public holidays, upcoming custom-mark days
- Backup and restore:
  iCloud auto backup, manual database export/import (`.zip` / `.sqlite`)
- Localization support:
  English, Simplified Chinese, Traditional Chinese, Traditional Chinese (Hong Kong)
- Optional alternative calendar display:
  Chinese lunar / Kyureki data support

## How Off Day Decides a Day Type

Off Day merges three data sources in fixed order:

1. User mark (manual override)
2. Public holiday template entry (including holiday shifts)
3. Base calendar configuration

Equivalent logic:

```text
finalDayType = userMark ?? publicHolidayType ?? baseCalendarType
```

This rule is implemented in `Off Day/DayManager.swift`.

## Built-in Holiday Template Coverage

Template files are located at `Off Day/PublicPlan/JSON/`.

| Region | Coverage |
| --- | --- |
| China Mainland / Xinjiang / Tibet / Guangxi / Ningxia | 2024-01-01 to 2027-12-31 |
| Liangshan, Sichuan | 2026-01-01 to 2027-12-31 |
| Hong Kong | 2024-01-01 to 2027-12-31 |
| Macau (Public / Force / Civil Servant) | 2024-01-01 to 2027-12-31 |
| Singapore | 2024-01-01 to 2027-12-31 |
| Thailand (Financial Institutions) | 2024-01-01 to 2027-12-31 |
| Korea | 2024-01-01 to 2027-12-31 |
| United States (Federal) | 2024-01-01 to 2027-12-31 |
| Japan | 1955-01-01 to 2027-12-31 |

The 2027 China Mainland schedule follows the [State Council notice published by Xinhua](https://www.xinhuanet.com/20261105/ac6792e1565949dc8e7d6e8261b9a055/c.html). For 2027, the Xinjiang, Tibet, Guangxi, Ningxia, and Liangshan templates temporarily use the mainland schedule pending local holiday updates. Historical local schedules are preserved.

Other 2027 schedules follow the official publications from [Hong Kong](https://www.info.gov.hk/gia/general/202605/15/P2026051400304p.htm), [Macau](https://www.gov.mo/zh-hant/public-holidays/year-2027/), [Singapore's Ministry of Manpower](https://www.mom.gov.sg/newsroom/press-releases/2026/0618-public-holidays-for-2027), the [Bank of Thailand](https://www.bot.or.th/content/dam/bot/fipcs/documents/FPG/2569/EngPDF/25690175.pdf), [Korea AeroSpace Administration](https://www.kasa.go.kr/prog/plcyBrf/brief/kor/sub01_01_04/view.do?plcyBrfNo=431), the [U.S. Office of Personnel Management](https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/), and [Japan's Cabinet Office](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html). The Macau Civil Servant template marks full-day holidays only. The U.S. template includes the observance of New Year's Day 2028 on December 31, 2027.

Templates record the dates explicitly designated as holidays, substitute holidays, or make-up workdays. Adjacent ordinary weekends are handled by the base calendar. Local holidays in the Tibet template follow Lhasa notices; other cities and counties may differ. Thailand follows the nationwide financial institution calendar and excludes regional holidays such as Bangkok-only closures. The U.S. template covers Federal employees, including officially announced government-wide days off; private employers may follow different schedules.

Historical corrections verified on November 5, 2026:

- Singapore: removed the erroneous June 1, 2024 entry; added [Polling Day on May 3, 2025](https://www.mom.gov.sg/newsroom/press-releases/2025/0415-public-holiday-on-polling-day_3-may-2025) and the [Vesak Day observance on June 1, 2026](https://www.mom.gov.sg/newsroom/press-releases/2025/0616-public-holidays-for-2026).
- Korea: added [October 1, 2024](https://www.mpm.go.kr/mpm/comm/newsPress/newsPressRelease/?cntId=3940&mode=view), [January 27, 2025](https://www.korea.kr/news/policyNewsView.do?newsId=148938559), [June 3, 2025](https://www.korea.kr/news/policyNewsView.do?newsId=148941443), and [Labor Day on May 1, 2026](https://www.mpm.go.kr/mpm/comm/newsPress/newsPressRelease/?cntId=4250&mode=view).
- Thailand: followed the [BOT calendar](https://www.bot.or.th/en/financial-institutions-holiday.html) to remove cancelled January 2, 2024 and ordinary weekend dates April 13–14, 2024; added the special holiday on April 12, 2024.
- Xinjiang: added March 29–30, 2025 to complete the Eid al-Fitr period in the [regional notice](https://www.xinjiang.gov.cn/xinjiang/tzgg/202412/01242215d31b4ede946837906c473b7c.shtml).
- Lhasa: added [August 25, 2025](https://www.lasa.gov.cn/lasa/tggs/202508/b93d0e1929294462ba882353756e41d7.shtml), [February 24–26, 2026](https://www.lasa.gov.cn/lasa/tggs/202601/f87553d7183d439fb044eca99fcbf225.shtml), and [August 14, 2026](https://www.lasa.gov.cn/lasa/tggs/202608/62250cb433474533a4fd40173b681f7e.shtml).
- United States: added government-wide closures on [December 24, 2024](https://www.opm.gov/chcoc/transmittals/2024/Dec%2024%202024%20CPM%20and%20Attachment.pdf), [January 9, 2025](https://www.opm.gov/chcoc/transmittals/2024/National%20Day%20of%20Mourning%20for%20President%20Carter%20CPM%202024-28.pdf), and [December 24 and 26, 2025](https://www.opm.gov/chcoc/published-memos/closing-of-federal-government-departments-and-agencies-on-wednesday-december-24-2025-and-friday-december-26-2025.pdf).

## Quick Start (User)

1. Select a public holiday template.
2. Configure your base calendar mode.
3. Add Off Day intents in Shortcuts.
4. Build personal automations (alarm, focus mode, reminders).
5. Optionally add manual day marks and comments for exceptions.

## Development

### Requirements

- macOS with Xcode 14 or newer
- iOS/iPadOS 16.0+
- Swift Package Manager (resolved automatically by Xcode)

### Run

```bash
git clone https://github.com/zizicici/Off-Day.git
cd Off-Day
open "Off Day.xcodeproj"
```

Select the `Off Day` scheme and run on simulator or device.

### Dependencies

- [GRDB.swift](https://github.com/groue/GRDB.swift) `7.9.0`
- [SnapKit](https://github.com/SnapKit/SnapKit) `5.7.1`
- [Toast-Swift](https://github.com/scalessec/Toast-Swift) `5.1.1`
- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel) `4.5.3`
- [ZipArchive](https://github.com/ZipArchive/ZipArchive) `2.6.0`
- [ZCCalendar](https://github.com/zizicici/ZCCalendar) `0.2.0`
- [MoreKit](https://github.com/zizicici/MoreKit) `2.2.0`

## Project Structure

```text
Off Day/
├── Block/           # Main calendar UI and day interaction
├── PublicPlan/      # Built-in and custom holiday plans
├── BaseCalendar/    # Base calendar strategies
├── Intent/          # App Intents for Shortcuts
├── Notification/    # Local notification scheduling
├── Backup/          # iCloud backup and DB import/export
├── Database/        # GRDB models, migrations, persistence
├── ChineseCalendar/ # Lunar/Kyureki data support
└── More/            # Settings, about, tutorials, support
```

## JSON Format for Custom Holiday Plan

Imported/exported plans follow this shape:

```json
{
  "name": "My Plan",
  "start": "2027-01-01",
  "end": "2027-12-31",
  "days": [
    {
      "name": "New Year",
      "date": "2027-01-01",
      "type": 0,
      "localizedNames": {
        "en": "New Year",
        "zh-Hans": "元旦",
        "zh-Hant": "元旦"
      }
    }
  ]
}
```

`name` is the required original name. Optional `localizedNames` maps language codes (such as `pt`, `th`, `ta`, or `zh-Hant`) to translations, independently of the app’s interface languages. `type` is `0` for a day off or `1` for a workday. Dates must be valid, with years from 1 to 9999; legacy dates without zero padding remain supported. Existing templates without `localizedNames` remain compatible; missing or blank translations fall back to `name`. The earlier `names` key is accepted when reading; exports use `localizedNames`. If both keys are present, `localizedNames` takes precedence.

For templates with translations, choose Holiday Name Language from the calendar home screen’s top-right (…) menu. Original Names is the default. Changes take effect immediately and are remembered separately for each template. Imports, exports, copies, and subscription updates preserve translations. When editing a custom holiday, selecting a language updates that translation while preserving the original and other translations; Original Names edits `name`. Newly created holidays also receive an original name for fallback. Language selection affects display text; reminder grouping continues to use original names. Bundled 2027 entries include local official languages and simplified/traditional Chinese: English for Hong Kong and the US, Portuguese for Macao, English/Malay/Tamil for Singapore, and Japanese/Korean/Thai for their respective regions. Mainland and local Chinese templates initially include simplified/traditional Chinese; minority languages will follow later. Earlier entries retain their original names. Portuguese names follow the [Macao government calendar](https://www.gov.mo/pt/feriados/year-2027/); Thai names follow the [Bank of Thailand notice](https://www.bot.or.th/content/dam/bot/fipcs/documents/FPG/2569/ThaiPDF/25690175.pdf). Singapore terminology follows MOM’s [Malay guide](https://www.mom.gov.sg/-/media/mom/documents/employment-practices/workright/workright-guide-employment-laws-malay.pdf) and [Tamil guide](https://www.mom.gov.sg/-/media/mom/documents/employment-practices/workright/workright-guide-employment-laws-tamil.pdf).

Reference model: `Off Day/PublicPlan/Model/JSONPublicPlan.swift`.

## Roadmap

- [x] Built-in multi-region holiday templates
- [x] Custom template import/export
- [x] Base calendar modes (standard/week-cycle/day-cycle)
- [x] App Intents + automation workflow
- [x] Backup and restore
- [ ] Interactive widget
- [x] Subscribable remote holiday templates with update review

## Contributing

Issues and pull requests are welcome.

If you contribute holiday data:
- Keep `start`/`end` aligned with actual dataset coverage.
- Ensure all `days[].date` values stay within the range.
- Keep JSON sorted and readable.

## Screenshots

<div align="center">
  <img src="https://i.v2ex.co/0SL75bVd.png" alt="Off Day Screenshot" />
</div>

## License

Off Day is available under the [MIT License](LICENSE).
