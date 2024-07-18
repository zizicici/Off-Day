<h4 align="right"><strong><a href="README.md">English</a></strong> | 中文</h4>

<div align="center">
    <img src="Off Day/Assets.xcassets/AppIcon.appiconset/zzz.png" width=200 height=200>
    <h1>Off Day</h1>
</div>

> 我们的目标是：
> 
> “休息日闹钟不响！”

[![Swift Version](https://img.shields.io/badge/swift-5.0-orange.svg)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://makeapullrequest.com)
[![iTunes App Store](https://img.shields.io/itunes/v/6501973975)](https://apps.apple.com/app/id6501973975)

「休息日」（Off Day） 是一个iOS平台上的节假日闹钟App。用户可以简单并且优雅的使用 Off Day 及其自带的快捷指令，来标记节假日与开关闹钟。

# 使用方法

1. 选择公共假期模板
2. 添加快捷指令
3. 开启快捷指令自动化

# 截屏
<div align="center">
    <img src="https://i.v2ex.co/0SL75bVd.png">
</div>

# 功能/展望

- [x] 内置多个公共假期模板 (🇨🇳 中国大陆/ 🇭🇰 香港特别行政区/ 🇲🇴 澳门特别行政区/ 🇸🇬 新加坡/ 🇹🇭 泰国/ 🇰🇷 韩国/ 🇯🇵 日本/ 🇺🇸 美国)
- [x] 自定义公共假期模板 (支持编辑/导入/导出等操作)
- [x] 基础日历系统 (用于大小周/轮休/普通日历)
- [x] 用户标注 (用户可以标注工作日/休息日)
- [ ] 用户贴纸 (为用户增加更多备注信息)

# 「某一天是休息日」是如何判断的？

「休息日」的判断，涉及三个层面的数据，分别是：1. 用户标注，2. 公共假期模板，3. 基础日历。这三个层面的数据优先级依次降低：

1. 如果用户有自行标注特定的某一天为「休息日」或者「工作日」，则这一天，就是用户标注的类型，无视公共假期模板和基础日历的信息。
2. 如果用户没有标注，则查看在公共假期模板的这一天有没有节日信息，如果有节日信息，则按照节日信息的类型（放假/调班），决定这一天的类型：放假的节日就是「休息日」，上班的节日调班就是「工作日」。
3. 如果公共假期模板里也没有信息，则查看基础日历里这一天是不是「休息日」。（比如基础日历默认设置是一周双休，那么周六周天就是「休息日」）

# 项目编译要求

- iOS/iPadOS 16+
- Xcode 15

# 协议

「休息日」遵循 [MIT 协议](LICENSE).
