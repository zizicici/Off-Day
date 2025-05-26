<h4 align="right">English | <strong><a href="README_CN.md">中文</a></strong></h4>

<div align="center">
    <img src="Off Day/Assets.xcassets/AppIcon.appiconset/zzz.png" width=200 height=200>
    <h1>Off Day</h1>
</div>

> Our Goal is...
> 
> 'No Alarms on Off Days!'

[![Swift Version](https://img.shields.io/badge/swift-5.0-orange.svg)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://makeapullrequest.com)
[![iTunes App Store](https://img.shields.io/itunes/v/6501973975)](https://apps.apple.com/app/id6501973975)

Off Day is a holiday alarm clock app on iOS. Users can easily and elegantly mark holidays and toggle alarms based on conditions using the built-in shortcuts in Off Day.

# Usage

1. Choose Public Holiday Template
2. Add Shortcuts
3. Enable Shortcuts Automation

# Screenshots
<div align="center">
    <img src="https://i.v2ex.co/0SL75bVd.png">
</div>

# Features/Roadmaps

- [x] Inner Public Holiday Template (🇨🇳 China Mainland/ 🇭🇰 Hong Kong SAR/ 🇲🇴 Macau SAR/ 🇸🇬 Singapore/ 🇹🇭 Thailand/ 🇰🇷 Korea/ 🇯🇵 Japan/ 🇺🇸 US)
- [x] Custom Public Holiday Template (Edit/Import/Export)
- [x] Basic Calendar (Supports Days Circle/Weeks Circle/Standard Calendar)
- [x] User Annotation (Users Can Overwrite Off/Work Day Status)
- [ ] Subscriptionable Remote Public Holiday Template

# Determination

The determination of 'Off Day' involves three levels of data: 1. User Annotation, 2. Public Holiday Template, 3. Base Calendar. The priority of these three levels of data decreases in the following order:

1. If the user has manually annotated a specific day as an 'Off Day' or 'Working Day,' then that day is of the user's annotated type, regardless of the information in the Public Holiday Template and Base calendar.
2. If the user has not annotated, then it checks if there is any holiday information on that day in the Public Holiday Template. If there is holiday information, the type of that day is determined according to the holiday information.
3. If there is no information in the public holiday template, it then checks if that day is an 'Off Day' in the base calendar. (For example, if the base calendar is set to a two-day weekend, then Saturday and Sunday are 'Off Day's.)

# Requirements

- iOS/iPadOS 16+
- Xcode 16

# License

Off Day is available under the [MIT license](LICENSE).
