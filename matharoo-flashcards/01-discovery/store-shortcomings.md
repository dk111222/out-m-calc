# Matharoo Flash Cards：应用商店暴露的不足

**Phase:** 竞品切片（商店评价与上架信息，不是完整 Phase 3）
**Project:** matharoo-flashcards
**Date:** 2026-11-18
**Confidence:** High（有没有评价、有没有上架）；Low（用户实际讨厌什么——没有评论可引用）

---

对象是 Kathryn Halterman / Brandon Halterman 的 **Matharoo Flash Cards**（App Store id `6780922169`，bundle `com.brandonhalterman.matharoo`，版本 1.3）。Kidslox 的 Matharoo（matharoo.app）是另一个产品，下面不用它的材料。

## 结论

Google Play 和 App Store **都没有可引用的用户差评**。Play 上没有这款应用。App Store 在已查的 12 个店里公开评论数是 0。能说的不足来自上架信息本身：没有 Android、没有用户证言、文案和标价互相矛盾、语言和系统版本很窄、练习范围停在口算事实。

## Google Play

**[Data]** 2026-11-18 搜索 `Matharoo Flash Cards` 和 `Matharoo`，结果里没有同名应用。出现的是 Quizlet、Math Flash Cards（November31）等其他产品。

因此不存在 Play 评分、评论、下载量或崩溃报告。Android 家庭和学校用不了它。这是渠道缺口，不是用户投诉。

## App Store 评论

**[Data]** Customer Reviews RSS 在 us、gb、au、ca、nz、cn、jp、de、fr、in、br、mx 的 `im:rating` 条目数都是 0。商店页面原文是 “This app has not received enough ratings or reviews to display an overview.”

**[Data]** Lookup：美国 $1.99、英国 £1.99、澳大利亚 $2.99，`userRatingCount` 都是 0，版本 1.3，语言只有 EN。中国区 lookup 的 `resultCount` 是 0，中国店没有这条上架。

**[Data]** 首次发布 2026-06-28，当前版本发布 2026-07-09。到 2026-11-18 仍是 0 条公开评价。

没有评论，就不能声称崩溃、广告、难度或儿童体验有用户投诉。零评价本身是弱点：购买前没有社会证明。

## 上架信息里能直接看到的不足

这些是商店页面和官方截图里的事实，不是用户原话。

1. **文案说免费，标价不是免费。** **[Data]** 描述末句是 “Download free and start learning today!”，美区标价 $1.99。同一段又写 “No in-app purchases”。买断和“免费下载”写在同一屏。
2. **只有英文。** **[Data]** `languageCodesISO2A` 只有 EN。
3. **系统门槛高。** **[Data]** 需要 iOS 17 / iPadOS 17 或更高。Mac 需要 macOS 14 且是 M1 或更新芯片，页面同时写着 “Designed for iPad. Not verified for macOS.”
4. **商店年龄带窄于文案承诺。** **[Data]** 年龄标注是 Made for Ages 6–8。描述却写四则运算、12 以内乘法，以及 “sharpening all four operations for school”。**[Opinion]** 6–8 岁和“为上学把四则都练熟”不是同一群孩子。
5. **进度锁在单机。** **[Data]** 卖点是无账号、不采集数据、进度只留在本机、可离线。**[Opinion]** 家长换手机、老师看全班、兄弟姐妹分设备，这些场景商店方案都没有覆盖。
6. **练习停在口算事实，题型窄。** **[Data]** 描述的上限是 12 以内表内乘除，外加加减。官方测验截图是四选一，没有键盘作答。首页把加法标成 “Sums 0–20”。翻卡截图只有翻转、洗牌和上一张/下一张，画面上没有“会了/不会”的自我评分。
7. **选题可以让测验做不下去。** **[Data]** 官方练习页截图写着：“Pick a few more numbers — these don't make any whole problems together.” 用户选了 0 和 2 之后，整除题凑不出来，测验被挡住。

## 不能写成不足的东西

- 不要把其他数学闪卡应用的 Play 差评安到 Matharoo 头上。
- 不要把 Kidslox Matharoo 在 Devpost 上的配对故障写成这款闪卡应用的问题。
- 奖励商店、袋鼠、八个世界是产品选择，不是商店差评。

## 若要验证真正的使用不足

商店没有用户句子。下一步只能是自己安装（美区约 $1.99，iOS 17+）或访谈用过的家长，记录卡壳点。在那之前，用户痛点的置信度保持 Low。

---

## Flags

**Red Flags:**
- 没有。零评论说明“用户讨厌什么”这件事目前没有证据，不是这款产品已经失败的证据。

**Yellow Flags:**
- 付费、零评价、无 Android、仅英文、iOS 17+、中国区未上架。若目标是家庭或学校市场，分发面比功能清单更窄。
- 描述中的“免费下载”和 $1.99 标价冲突，购买前信任会被这一句打掉。

## Sources

- App Store listing, id 6780922169（美区、英国、澳大利亚、中国 lookup；页面文案）— Tier 1 商店原始数据，2026-11-18
- iTunes Customer Reviews RSS，12 个店，0 条 — Tier 1，2026-11-18
- Google Play 搜索 `Matharoo Flash Cards` 与 `Matharoo` — Tier 1，2026-11-18，无匹配上架
- 官方商店截图 `screenshot/01-home.png`、`screenshot/06-hub.png`、`screenshot/07-flip.png`、`screenshot/08-quiz.png` — Tier 1 开发者提交的界面，2026-11-18 下载
