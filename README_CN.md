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
- 远程模板订阅：
  通过 URL 订阅、后台自动刷新、变更差异审查、接受/拒绝/暂停更新
- 灵活基础日历模式：
  标准周模式、周循环模式、天循环模式
- 丰富 App Intents（快捷指令）能力：
  判断日期类型、检查冲突日、获取日期详情、查询下一个休息日/工作日、更新标注、管理备注
- 三类通知场景：
  模板过期提醒、公共假期前提醒、自定义标注日前提醒
- 锁屏 Widget：
  矩形组件并排显示今天、明天的休息或上班状态及节假日名称，圆形组件可单独显示今天或明天
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
| 中国大陆 / 新疆 / 西藏 / 广西 / 宁夏 | 2024-01-01 至 2027-12-31 |
| 四川凉山 | 2026-01-01 至 2027-12-31 |
| 香港 | 2024-01-01 至 2027-12-31 |
| 澳门（公众 / 强制 / 公务员） | 2024-01-01 至 2027-12-31 |
| 新加坡 | 2024-01-01 至 2027-12-31 |
| 泰国（金融机构假日） | 2024-01-01 至 2027-12-31 |
| 韩国 | 2024-01-01 至 2027-12-31 |
| 美国（联邦假日） | 2024-01-01 至 2027-12-31 |
| 日本 | 1955-01-01 至 2027-12-31 |

2027 年中国大陆安排依据[国务院办公厅通知（新华社受权发布）](https://www.xinhuanet.com/20261105/ac6792e1565949dc8e7d6e8261b9a055/c.html)。新疆、西藏、广西、宁夏、四川凉山模板的 2027 年数据暂采用大陆安排，地方节假日待更新；历年地方安排保留。

其他地区的 2027 年数据依据[香港政府](https://www.info.gov.hk/gia/general/202605/15/P2026051400304p.htm)、[澳门政府](https://www.gov.mo/zh-hant/public-holidays/year-2027/)、[新加坡人力部](https://www.mom.gov.sg/newsroom/press-releases/2026/0618-public-holidays-for-2027)、[泰国央行](https://www.bot.or.th/content/dam/bot/fipcs/documents/FPG/2569/EngPDF/25690175.pdf)、[韩国宇宙航空厅](https://www.kasa.go.kr/prog/plcyBrf/brief/kor/sub01_01_04/view.do?plcyBrfNo=431)、[美国人事管理局](https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/)及[日本内阁府](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html)。澳门公务员模板仅标记全日假期；美国模板包含 2028 年元旦提前至 2027 年 12 月 31 日的补假。

模板按通知中明确列出的放假、补假和调班日期记录；仅与相邻周末连休时，普通周末由基础日历判断。西藏模板中的地方假期依据拉萨市通知，其他市县请按当地安排调整。泰国模板适用于全国金融机构，不包含曼谷等地区专属假日。美国模板适用于联邦雇员，包含官方统一休假通知；私营单位安排可能不同。

2026-11-05 历史数据复核更正：

- 新加坡：移除误记的 2024-06-01，补入 [2025-05-03 投票日](https://www.mom.gov.sg/newsroom/press-releases/2025/0415-public-holiday-on-polling-day_3-may-2025)和 [2026-06-01 佛诞补假](https://www.mom.gov.sg/newsroom/press-releases/2025/0616-public-holidays-for-2026)。
- 韩国：补入 [2024-10-01 国军日](https://www.mpm.go.kr/mpm/comm/newsPress/newsPressRelease/?cntId=3940&mode=view)、[2025-01-27 临时假日](https://www.korea.kr/news/policyNewsView.do?newsId=148938559)、[2025-06-03 总统选举日](https://www.korea.kr/news/policyNewsView.do?newsId=148941443)和 [2026-05-01 劳动节](https://www.mpm.go.kr/mpm/comm/newsPress/newsPressRelease/?cntId=4250&mode=view)。
- 泰国：按[央行金融机构日历](https://www.bot.or.th/en/financial-institutions-holiday.html)移除已取消的 2024-01-02、未列为金融机构假日的 2024-04-13/14，补入 2024-04-12 特别假日。
- 新疆：按[自治区 2025 年通知](https://www.xinjiang.gov.cn/xinjiang/tzgg/202412/01242215d31b4ede946837906c473b7c.shtml)补齐 2025-03-29/30 肉孜节假期。
- 拉萨：补入 [2025-08-25 雪顿节](https://www.lasa.gov.cn/lasa/tggs/202508/b93d0e1929294462ba882353756e41d7.shtml)、[2026-02-24 至 26 日春节及藏历新年](https://www.lasa.gov.cn/lasa/tggs/202601/f87553d7183d439fb044eca99fcbf225.shtml)和 [2026-08-14 雪顿节](https://www.lasa.gov.cn/lasa/tggs/202608/62250cb433474533a4fd40173b681f7e.shtml)。
- 美国：按 OPM 通知补入 [2024-12-24](https://www.opm.gov/chcoc/transmittals/2024/Dec%2024%202024%20CPM%20and%20Attachment.pdf)、[2025-01-09](https://www.opm.gov/chcoc/transmittals/2024/National%20Day%20of%20Mourning%20for%20President%20Carter%20CPM%202024-28.pdf)、[2025-12-24/26](https://www.opm.gov/chcoc/published-memos/closing-of-federal-government-departments-and-agencies-on-wednesday-december-24-2025-and-friday-december-26-2025.pdf) 的联邦政府统一休假。

## 快速上手（用户）

1. 选择公共假期模板。
2. 配置基础日历模式。
3. 在快捷指令中添加 Off Day 指令。
4. 搭建个人自动化（闹钟、专注模式、提醒等）。
5. 对特殊日期做手动标注和备注。

## 本地开发

锁屏 Widget 使用 `Widgets` 扩展和 `WidgetShared` 共享模型。主应用和扩展的签名都需要启用 App Group `group.com.zizicici.zzz`；使用其他开发者账号时，请替换为自己账号下的 Group，并同步修改两份 entitlements 和 `WidgetCalendarStore.appGroup`。

运行应用一次以同步日历后，长按锁屏，进入「自定 → 锁定屏幕 → 添加小组件」，选择「休息日」的「今天和明天」，或更紧凑的「今天」「明天」圆形组件。矩形组件优先显示节假日名称，没有节名时显示星期。Widget 沿用应用的日期判定规则，在本地午夜切换日期；数据修改后会请求系统刷新，实际刷新时间由 WidgetKit 调度。

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
- [ZCCalendar](https://github.com/zizicici/ZCCalendar) `0.2.0`
- [MoreKit](https://github.com/zizicici/MoreKit) `2.2.0`

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

`name` 是必填的原始名称；`localizedNames` 是可选的多语言名称，键为语言代码（如 `pt`、`th`、`ta` 或 `zh-Hant`），不限于 App 的界面语言。`type` 为 `0`（休息日）或 `1`（工作日）。日期必须有效，年份范围为 1–9999；兼容旧模板未补零的年月日。不含 `localizedNames` 的旧模板可继续导入和使用；译名缺失或为空时显示 `name`。读取时兼容之前的 `names` 字段，导出统一使用 `localizedNames`；两者同时存在时以 `localizedNames` 为准。

选中含译名的模板后，可在日期主页右上角“…”菜单中的“节日名称语言”切换原始名称与译名。默认使用原始名称；切换立即生效，并分别记住每个模板的语言偏好。导入、导出、复制和订阅更新均保留多语言名称。编辑自定义节日时，选择某种语言会修改对应译名并保留原始名称及其他译名；选择“原始名称”则修改 `name`。新建节日时同时建立原始名称作为回退。语言选择只影响显示文字，假期提醒仍按原始名称分组。2027 年内置模板提供当地官方语言及简繁中文：香港含英语，澳门含葡萄牙语，新加坡含英语、马来语和泰米尔语，日本、韩国、泰国分别含日语、韩语、泰语，美国含英语。大陆及地方模板本次先提供简繁中文，少数民族语言待后续补充。2027 年以前的条目保持原名称。葡萄牙语名称参考[澳门政府葡文日历](https://www.gov.mo/pt/feriados/year-2027/)，泰语名称参考[泰国央行泰文通知](https://www.bot.or.th/content/dam/bot/fipcs/documents/FPG/2569/ThaiPDF/25690175.pdf)；新加坡用语参考人力部[马来语指南](https://www.mom.gov.sg/-/media/mom/documents/employment-practices/workright/workright-guide-employment-laws-malay.pdf)和[泰米尔语指南](https://www.mom.gov.sg/-/media/mom/documents/employment-practices/workright/workright-guide-employment-laws-tamil.pdf)。

参考模型：`Off Day/PublicPlan/Model/JSONPublicPlan.swift`。

## 路线图

- [x] 多地区内置模板
- [x] 自定义模板导入导出
- [x] 基础日历模式（标准/周循环/天循环）
- [x] App Intents 与自动化流程
- [x] 备份与恢复
- [ ] 交互式桌面小组件
- [x] 可订阅远程节假日模板（含更新审查机制）

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
