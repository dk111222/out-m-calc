# Recon map: Math Tricks + 速算训练 (iOS / Android)

Scope: 技巧学习 + 限时训练。对照产品是美区 Math Tricks: Mental Math，以及国内「速算训练」。克隆目标是面向海外 homeschool 家长和小学老师的 K1–K5 速算 App。
For: homeschool 家长、小学老师，学习者为 K–5 年级。
Date: 2026-11-19
Platform constraint: Flutter Android + iOS。不做 Web，不生成 Next.js。

`brief.md` 不在本仓库。产品边界以本轮说明和 `docs/stepmath-requirements.md` 为准。参考图来自 `screenshots/`，副本在 `replica/screens/`，只作对照，不进入安装包。

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | Math Tricks App Store 美区 | https://apps.apple.com/us/app/math-tricks-mental-math/id1209287132 | 免费，去广告 $4.99，含广告。评分在 2.0 被重置。截图是技巧课、目录、键盘练习 |
| 2 | Math Tricks Google Play | https://play.google.com/store/apps/details?id=example.matharithmetics&hl=en_US | 同一作者。10M+ 下载。内购区间 $0.99–$24.99。更新日志写过 Pro 解锁全部技巧、去掉买金币、激励广告 |
| 3 | 速算训练 App Store 中国区 | https://apps.apple.com/cn/app/id6468921340 | 杭州家之馨。2 个评分。月 ¥35 / 半年 ¥55 / 年 ¥80。竞速、巧算、错题、打印、排行榜 |
| 4 | 速算训练 应用宝 | https://sj.qq.com/appdetail/com.lz.ssxl | 包名 com.lz.ssxl。约 3300 次下载，4.7。简介多了按年龄的 30+ 巧算和周报 |
| 5 | 参考截图 Math Tricks | `screenshots/math-tricks/` | 16 张，iOS 5 + Play 11。见下方屏幕表 |
| 6 | 参考截图 速算训练 | `screenshots/suan-suan/` | 5 张商店宣传图，画面内是真界面 |

没有登录任何人的账号，没有看安装包，没有抓接口。流程点击数是从这些公开界面推断的，标为 inferred。

## Core loop

家长或老师按年级指定一条技巧；孩子先看步骤再键盘作答；答错后定位到失败的那一步；同一年级再用限时或限题做速度训练。

## Screens

原产品屏幕。ID 稳定，需求文档用同一套 ID 指原界面。

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| MT-S01 | Math Tricks 首页 | 启动 | 选模式 | Single game、Joint game、Multiplayer、Training mode、By heart、Settings；总题数、连续天数、今日 0/100 | 有数据。空状态未见。Play 版有 Please rate、Email support。截图底部仍印 v2.0 2016-06-06 |
| MT-S02 | 平板首页 | 宽屏 | 同上，两列 | 六个入口排成两列 | 仅填充态。`play-11-home-tablet.png` |
| MT-S03 | 训练目录 | Training mode | 按运算找技巧 | 加、减、乘、除、平方、乘方、开方、百分比；0/100；One player / Two players | 百分比组展开过一次。加载和空列表未见 |
| MT-S04 | 技巧列表 | 展开某一运算 | 选具体技巧并看进度 | 编号技巧、0/100、勾、锁和 $500 | 有锁、有已勾。`play-07`、深色 `play-10` |
| MT-S05 | 技巧课 | 点开一条技巧 | 教步骤 | 标题、分步、同色数字、箭头图、下一步、YouTube 图标 | 只见平方和乘 11。无加载失败 |
| MT-S06 | 竖屏练习 | 课之后或直接练 | 键盘作答 | 关卡、题号、分数、三星、算式、进度条、金币、喇叭、无限时、数字键盘 | 平方、乘法。答错态、空输入未见 |
| MT-S07 | 横屏练习 | 转屏 | 同上 | 题干在左或上，键盘在右。百分比题 | `play-02`、`ios-04`、`play-09` |
| MT-S08 | 对错确认 | 做出百分比后 | 对照拆解 | 已填答案、分步颜色、大号叉和勾 | 只见一帧。`play-03` |
| SS-S01 | 速算首页 | 启动 | 当天练习入口 | 练习天数、排行榜、错题本、VIP、3 分钟竞速、最高纪录、每日一练、巧算列表、打印 | 有纪录的填充态。空状态未见 |
| SS-S02 | 速算拓展 | 底栏「速算拓展」 | 配置闪电算 / 看心算 | 运算、最小/最大位数、笔数、间隔 | 默认值 1–4 位。未见开始后的闪题画面 |
| SS-S03 | 巧算方法 | 首页巧算进「凑整法」 | 读方法再练习 | 方法段、两道例题和解法、打印、开始练习 | 只见凑整法 |
| SS-S04 | 排行榜 | 首页排行榜 | 按做对题数排名 | 前三名、列表、我的名次 | 填充态。名字像示例数据 |
| SS-S05 | 错题集 | 首页错题本 | 按日期回看错题 | 时间/类型、日期分组、橙色答案、练习 | 有错题。空列表未见 |

## Flows

```
F01 学一条技巧（Math Tricks，inferred）
    MT-S01 -> MT-S03 -> MT-S04 -> MT-S05 -> MT-S06
    happy path clicks: 4（进训练、点运算、点技巧、开始后第一题）
    edge: 技巧被 $500 锁住；个位和凑不出整题时原产品未在这些图里表现；答对后评论称开头会卡住

F02 看百分比拆解（Math Tricks，inferred）
    MT-S06 -> MT-S08
    happy path clicks: 1 次提交
    edge: 横竖屏同一题；只见勾叉，不见「错在第几步」

F03 三人分钟竞速（速算训练，inferred）
    SS-S01 点「开始练习」
    happy path clicks: 1
    edge: 限时 3 分钟写在卡片上；设置和打印在同一张卡旁；最高纪录 55 题

F04 读巧算再练（速算训练，inferred）
    SS-S01 -> SS-S03 -> 开始练习
    happy path clicks: 2
    edge: 方法是整段文字，没有涂色箭头；打印在方法页右上

F05 复习错题（速算训练，inferred）
    SS-S01 -> SS-S05 -> 练习
    happy path clicks: 2
    edge: 按日期或类型；橙色答案的对错规则截图本身不一致，不能当成判题规格

F06 本机双人（Math Tricks，inferred）
    MT-S03 底部 Two players
    happy path clicks: 1 次切换，随后仍要选技巧
    edge: 未见对局中的换手画面
```

克隆产品要打过的点击数：家长选好孩子和年级后，孩子从今日任务到第一题不超过 2 次点击。

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| 模式入口行 | 图标加标题 | 默认 | MT-S01、MT-S02 |
| 运算分组 | 八种运算，可展开 | 收起、展开 | MT-S03、MT-S04 |
| 技巧行 | 编号、进度、锁 | 未做、进行中、已勾、锁定 | MT-S04 |
| 步骤卡 | 编号步骤、同色数字、箭头 | 只见阅读态 | MT-S05、SS-S03 |
| 数字键盘 | 0–9、删除 | 竖屏、横屏、深色目录不是键盘 | MT-S06、MT-S07 |
| 练习顶栏 | 关卡、题号、分数、星 | 填充 | MT-S06 |
| 对错大按钮 | 叉、勾 | 默认 | MT-S08 |
| 竞速卡 | 倒计时说明、算式预览、开始、纪录 | 有纪录 | SS-S01 |
| 步进器 | 减、数字、加 | 位数、笔数、间隔 | SS-S02 |
| 错题分组 | 日期、题数、练习 | 有条目 | SS-S05 |
| 排行榜领奖台 | 前三、列表、我的名次 | 填充 | SS-S04 |
| VIP / 锁 | 会员按钮、金币锁 | 锁定 | SS-S01、MT-S04 |

克隆时保留：步骤卡、数字键盘、竞速开始卡、错题分组、步进器。不保留：金币锁、YouTube 按钮、公开领奖台、商店评分按钮。

## Inferred data model

```
Learner     id, display_name, grade (K|1|2|3|4|5), pin_protected
            evidence: 产品范围是 K1–K5，多个孩子由家长或老师在一台设备上管理
            confidence: high（产品决定），原 App 截图里没有年级字段

Trick       id, grade, operation, title, applies_when, not_when, steps[]
            evidence: MT-S04 编号技巧，MT-S05 步骤，SS-S03 方法段
            confidence: high

Attempt     id, learner_id, trick_id, prompt, user_answer, correct_answer,
            failed_step, mode (guided|final|speed), created_at
            evidence: MT-S06 只显示最终算式；失败步骤是克隆补上的，原图没有
            confidence: medium

WrongItem   attempt_id, reviewed_ok
            evidence: SS-S05
            confidence: high

SpeedRound  id, learner_id, operation, digit_min, digit_max, limit_mode (time|count),
            limit_value, correct_count, duration_ms
            evidence: SS-S01 3 分钟和最高纪录，SS-S02 位数和笔数
            confidence: high

Assignment  learner_id, date, trick_id or speed config, status
            evidence: 家长和老师是使用者，原 App 没有布置作业这一屏
            confidence: guess，克隆需要

Mastery     learner_id, trick_id, last_20_final_accuracy, mastered
            evidence: MT-S04 的 0/100 是原产品进度；90% / 最近 20 题是克隆规则
            confidence: medium
```

Relationships: Learner 1-n Attempt，Learner 1-n SpeedRound，Trick 1-n Attempt，Learner 1-n WrongItem。

## Feature matrix

见 `features.csv`。Must: 18，should: 12，could: 6，skip: 10。

## Out of scope (cannot or should not be cloned)

- Math Tricks 的 YouTube 讲解视频和金币商店。视频是别人的内容，金币是原产品的付费墙。
- 速算训练的公开排行榜和上面的用户昵称。那是他们的用户网络。
- 闪电算、看心算。截图只到设置页，而且面向珠心算，不在 K1–K5 海外范围。
- 原产品的广告 SDK、会员价和内购商品编号。
- Web、Next.js、浏览器版。本产品只做 Flutter 的 Android 和 iOS。
- 在线多人、班级云端、账号体系。第一版数据留在这台设备上。

## Size

原产品对照屏幕 14，流程 6，克隆实体 7。难的部分：按年级出题且每一步都能生成、限时训练和技巧学习共用键盘但不共用计时、离线进度、家长/老师和孩子在同一安装包里的切换、双端打印。规模：M。一个年级的技巧加限时训练可以在几周内做成可试用版本；K 到 5 的全部技巧内容要按年级追加，不在第一次试用里做完。

下一步是 `/replica-architect`：把实体收成 Flutter 本地库结构，并定 Android / iOS 工程边界。
