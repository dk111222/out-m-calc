# Intake: StepMath

*Skill: startup-competitors | Generated: 2026-11-19*

## 产品

StepMath（工作名）是给美国 homeschool 家长和小学老师用的 K–5 心算 App。孩子在本机做两件事：先按步骤学一条美式心算技巧，再按年级做限时或限题的速算。Flutter，Android + iOS。离线优先，不强制登录，默认不埋点。

付费者是大人，使用者是孩子。第一名学习者免费。打印、额外学习者和年级以外的技巧包打算一次性解锁，没有月订阅，练习中不放广告。价格数字尚未定。

仓库里的规格是 `docs/stepmath-requirements.md` v0.3，以及 `replica/recon.md`。工程已有一版 Flutter 壳，还不是上架产品。

## 市场

美国。买家是在家教育的家长和小学老师。学习者是幼儿园到五年级。

要解决的事：现有技巧 App 把步骤画出来，但不指出错在哪一步，学习过程还带计时或广告；国内速算 App 把当天练习、错题和打印放在一起，但是中文、按年龄段，而且心算挑战里有珠心算。StepMath 想把「步骤可定位」和「当天可开练的速算」放进同一台设备，数据留在本地。

## 已知对手

本仓库已经对照过的产品，不是完整名单：

| 产品 | 关系 | 本仓库里已有的事实 |
| --- | --- | --- |
| Math Tricks: Mental Math | 直接 | 美区 App Store id 1209287132，免费，去广告 $4.99，含广告。Google Play `example.matharithmetics`，商店页写 10,000,000+ 下载，内购区间 $0.99–$24.99。同一作者。 |
| 速算训练 | 直接，但是中国产品 | iOS id 6468921340，杭州家之馨。中国区免费，VIP 月 ¥35 / 半年 ¥55 / 年 ¥80。包名 `com.lz.ssxl`，应用宝约 3300 次下载。美区列表存在，此前查到 0 个评分。 |
| Matharoo Flash Cards | 相邻 | iOS id 6780922169，$1.99，英文，口算闪卡。12 国商店页 0 条评价，没有 Google Play 列表。不是技巧课，也不是限时竞速。 |

还没做档案、但会占同一笔家长预算的名字：Prodigy Math、Khan Academy Kids、SplashLearn、Mathseeds、Elephant Learning。这些在研究里核实，不在这里当作已经查证的事实。

## 来源说明

`matharoo-flashcards/PROGRESS.md` 属于 startup-design，而且只做了商店不足摘录，没有 competitor-landscape、market-analysis、target-audience 或 brief。这次不把它当成已经完成的 startup-design。

## Red Flags

- 产品还没上架，也没有自己的用户。竞争力现在只能对照别人的公开商店页，不能对照留存或收入。
- 一次性解锁的价格没定。和「免费加广告」或「月订阅」比，要等定价研究，不能先宣布更便宜。

## Yellow Flags

- Math Tricks 的 10,000,000+ 是全球 Play 下载，不是美国独占。
- 速算训练的美区存在感很弱。它说明这个形态可以做出来，不说明美国买家已经在用它。

## Sources

- `docs/stepmath-requirements.md`（2026-11-19，v0.3）
- `replica/recon.md`（2026-11-19）
- `matharoo-flashcards/01-discovery/store-shortcomings.md`（2026-11-18）
