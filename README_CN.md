<h4 align="right"><strong><a href="README.md">English</a></strong> | 中文</h4>

<div align="center">
  <img src="zzz.png" width="180" height="180" alt="Off Day logo" />
  <h1>Off Day</h1>
  <p><strong>休息日闹钟不响。</strong></p>
  <p>一个用于日期判断、自动化和提醒的节假日 iOS 应用。</p>
</div>

<p align="center">
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0" /></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-iOS%2016%2B-blue.svg" alt="iOS 16+" /></a>
  <a href="https://apps.apple.com/app/id6501973975"><img src="https://img.shields.io/itunes/v/6501973975" alt="App Store" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT License" /></a>
</p>

## 项目简介

Off Day 用来判断某一天是休息日还是工作日，并将结果无缝接入 iOS 快捷指令与通知自动化流程。

项目采用本地优先设计：
- 节假日数据来自应用内置 JSON 模板或用户自定义导入模板。
- 用户标注、备注、设置保存在本地 SQLite 数据库。
- 提供可选 iCloud 自动备份数据库快照能力。

## 核心功能

- 多层级日期判定引擎，优先级固定：
  `用户标注 > 公共假期模板 > 基础日历`
- 内置公共假期模板：
  中国大陆、新疆、西藏、广西、宁夏、香港、澳门（公众假期 / 强制性假日 / 公务员假日）、新加坡、泰国、韩国、日本、美国
- 自定义公共假期模板：
  新建、编辑、复制、JSON 导入、JSON 导出
- 灵活基础日历模式：
  标准周模式、周循环模式、天循环模式
- 丰富 App Intents（快捷指令）能力：
  判断日期类型、检查冲突日、获取日期详情、查询下一个休息日/工作日、更新标注、管理备注
- 三类通知场景：
  模板过期提醒、公共假期前提醒、自定义标注日前提醒
- 数据备份恢复：
  iCloud 自动备份、手动导出/导入数据库（`.zip` / `.sqlite`）
- 多语言支持：
  英文、简体中文、繁体中文、繁体中文（香港）
- 可选替代历法显示：
  支持农历与旧历（Kyureki）数据

## 休息日判定规则

Off Day 按固定顺序合并三层数据源：

1. 用户标注（手动覆盖）
2. 公共假期模板（含调休/调班）
3. 基础日历配置

等价逻辑：

```text
finalDayType = userMark ?? publicHolidayType ?? baseCalendarType
```

实现位置：`Off Day/DayManager.swift`。

## 内置模板覆盖范围

模板文件位于 `Off Day/PublicPlan/JSON/`。

| 地区 | 覆盖区间 |
| --- | --- |
| 中国大陆 / 新疆 / 西藏 / 广西 / 宁夏 | 2024-01-01 至 2026-12-31 |
| 香港 | 2024-01-01 至 2026-12-31 |
| 澳门（公众 / 强制 / 公务员） | 2024-01-01 至 2026-12-31 |
| 新加坡 | 2024-01-01 至 2026-12-31 |
| 泰国 | 2024-01-01 至 2026-12-31 |
| 韩国 | 2024-01-01 至 2026-12-31 |
| 美国（联邦假日） | 2024-01-01 至 2026-12-31 |
| 日本 | 1955-01-01 至 2026-12-31 |

## 快速上手（用户）

1. 选择公共假期模板。
2. 配置基础日历模式。
3. 在快捷指令中添加 Off Day 指令。
4. 搭建个人自动化（闹钟、专注模式、提醒等）。
5. 对特殊日期做手动标注和备注。

## 本地开发

### 环境要求

- macOS + Xcode 14 及以上
- iOS/iPadOS 16.0+
- Swift Package Manager（Xcode 自动解析）

### 运行方式

```bash
git clone https://github.com/zizicici/Off-Day.git
cd Off-Day
open "Off Day.xcodeproj"
```

选择 `Off Day` Scheme，运行到模拟器或真机。

### 依赖库

- [GRDB.swift](https://github.com/groue/GRDB.swift) `7.9.0`
- [SnapKit](https://github.com/SnapKit/SnapKit) `5.7.1`
- [Toast-Swift](https://github.com/scalessec/Toast-Swift) `5.1.1`
- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel) `4.5.3`
- [ZipArchive](https://github.com/ZipArchive/ZipArchive) `2.6.0`
- [ZCCalendar](https://github.com/zizicici/ZCCalendar) `0.1.4`
- [AppInfo](https://github.com/zizicici/AppInfo) `1.3.0`

## 项目结构

```text
Off Day/
├── Block/           # 主日历界面与日期交互
├── PublicPlan/      # 内置与自定义公共假期模板
├── BaseCalendar/    # 基础日历策略
├── Intent/          # 快捷指令 App Intents
├── Notification/    # 本地通知调度
├── Backup/          # iCloud 备份与数据库导入导出
├── Database/        # GRDB 模型、迁移、持久化
├── ChineseCalendar/ # 农历/旧历数据支持
└── More/            # 设置、说明、教程、支持入口
```

## 自定义模板 JSON 格式

导入/导出的模板结构如下：

```json
{
  "name": "My Plan",
  "start": "2026-01-01",
  "end": "2026-12-31",
  "days": [
    {
      "name": "New Year",
      "date": "2026-01-01",
      "type": "offDay"
    }
  ]
}
```

参考模型：`Off Day/PublicPlan/Model/JSONPublicPlan.swift`。

## 路线图

- [x] 多地区内置模板
- [x] 自定义模板导入导出
- [x] 基础日历模式（标准/周循环/天循环）
- [x] App Intents 与自动化流程
- [x] 备份与恢复
- [ ] 交互式桌面小组件
- [ ] 可订阅远程节假日模板

## 参与贡献

欢迎提交 Issue 和 Pull Request。

如果你提交节假日数据：
- 请保证 `start`/`end` 与数据真实覆盖区间一致。
- 请保证 `days[].date` 都落在覆盖区间内。
- 建议保持 JSON 有序且可读。

## 截图

<div align="center">
  <img src="https://i.v2ex.co/0SL75bVd.png" alt="Off Day Screenshot" />
</div>

## 协议

Off Day 基于 [MIT 协议](LICENSE) 开源。
