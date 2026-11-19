# Tech and product: StepMath
*Skill: startup-competitors | Generated: 2026-11-19*

核对日期：2026-11-19。只使用各产品的帮助中心、官方产品页、商店列表和厂商自己的说明文件。没有反编译，没有调用未公开的接口。某项机制若这些页面没有写，记为 DATA GAP。置信度只针对「公开文字说了什么」。

## 范围

StepMath 的计划来自本仓库 2026-11-19 的 intake：Flutter，Android + iOS，离线优先，Hive 存在本机，不建账号，练习中无广告，家长 PIN，可打 PDF 练习卷。下面把它当作对照基准，不把它写成已经上架的事实。

对照的五家是 XtraMath、ExploreLearning Reflex、Math Tricks: Mental Math、Mathseeds、Prodigy Math。每个产品回答三件家长会碰到的事：不建账号能做什么、飞机上（没有网络）能不能练、答错以后会不会指出失败的那一步。

## 机制对照

| 产品 | 不建账号，家长能做什么 | 飞机上能不能练 | 答错会不会标出失败的那一步 | 公开文字里的相邻机制 |
| --- | --- | --- | --- | --- |
| XtraMath | 不能开练，也不能看报告。孩子不能自己建账号。 | 帮助中心要求已联网的浏览器。2024-07-10 起官方停用手机 App。 | 超时后出示正确答案，并要求再输入。日期报告记下输错的数。不讲步骤。 | 计时器不能关；藏起来以后时间仍在走。孩子用 4 位 PIN 登录。报告在网上的家长或教师账号里。 |
| Reflex | 自适应练习要学生登录。免费家长报告账号要先有学校里的孩子账号。在家用有 Home User License，那也是账号。 | 官方把它写成在线、给联网设备用的程序。系统要求页没有写离线练习。 | DATA GAP。答错会让辅导游戏里的角色变慢或停下。辅导段会讲新事实，页面没有写标出失败步骤。 | 按学生表现挑事实和事实族。报告看已掌握的事实和事实族。 |
| Math Tricks | 商店简介没有写必须注册才能做题。更新日志有 Cloud progress saving。能不能完全不登录练完，DATA GAP。 | DATA GAP。没有「无网络可练」的句子。云端存进度需要网络。 | 商店写了逐步学习和逐步例题。没有写答错后标出哪一步错了。 | Play 写每题 15 秒。含广告，iOS 去广告 $4.99。 |
| Mathseeds | 商店写必须用账号登录，并要有效试用或订阅。 | 商店把无线网络写成最低要求。打印卷被写成在线课以外的离线补充。 | DATA GAP（现行界面）。2015 年厂商文件写驾驶测验答错要重做，并立刻知道对错。没有写标出失败步骤。 | 家长在 Family Dashboard 看报告。课程可重复。 |
| Prodigy | 玩游戏要学生用户名和密码，或 SSO。帮助中心写的在家路径是家长先建账号，再给孩子建账号。 | 官方写「有互联网的地方就能玩」。打不开时，帮助中心第一步是检查网络。 | 学生可点灯泡看「解题过程的提醒」，也可使用学具。页面没有写答错后自动标出失败步骤。 | 家长站和教师站与学生账号分开。离线 PDF 练习卷在 Core 或 Ultra 会员里。 |

## XtraMath

**[Data]** 家庭指南把产品写成免费的在线程序：加法、减法、乘法、除法的回忆和自动化。需要「任何有浏览器的设备」，「没有要安装的东西」。家长用邮箱或 Google 免费注册。每个孩子有按年级匹配的程序，以及自己的 4 位 PIN 用来登录。来源：家庭指南，2026-11-19 抓取。

**[Data]** 2026 家庭快速入门 PDF 写：选 Family Account；确认自己年满 16 岁；「孩子不能自己建账号」。同一份 PDF 写日期报告会列出当天每一题，答错的图标会显示输入的错误答案。来源：`XtraMath-family-homeschool-quickstart.pdf`。

**[Data]** 《Basic requirements for XtraMath》：技术要求是「一台已连接互联网、使用现代浏览器的设备」，并要打开 JavaScript。教育要求写明它是流利度工具，不教运算方法；若孩子还在一步一步算，而不是回忆，官方认为还不到用 XtraMath 的时候。来源：帮助中心。

**[Data]** 计时器不能关掉。帮助中心的理由是：计时的间隔重复用来同时练准确和速度。家长或教师可以在学生设置里勾选 Hide Timer，学生自己也可以点左上角的计时图标。藏起来以后，2024-07-10 的官方博客仍写「时间仍在走」。默认作答阈值 6 秒。1.5 秒、2 秒、3 秒要许可证；12 秒面向 K–2 和需要更多时间的学生。换程序会重置进度。来源：计时器帮助页、程序设置页、2024-07-10 博客。

**[Data]** 超时：术语表写，超时后答案带着沙漏图标出现，学生必须输入该答案才能进入下一题。默认 6 秒程序的超时是 20 秒。2024-07-10 博客把超时画成蓝色段，并写学生必须输入正确答案才能继续。答对且在阈值内是绿色；答对但不够快是黄色。答案图标同时用在学生练习和日期报告里：答错时「显示输入的错误答案」；没作答则先出示正确答案。来源：术语表、2024-07-10 博客。

**[Data]** 《How does XtraMath work》：按间隔重复挑孩子还不熟的事实，像一套会调整的闪卡。当前运算的流利度分到 100 才进入下一运算。官方再次写它建立流利度，不教背后的策略。来源：帮助中心。

**[Data]** 报告在网上的家长或教师账号里：学生报告有练习日历、奖杯、证书、流利度分、进度图和事实矩阵；日期报告看当天每一题；家长可收每周 PDF。家庭许可证另有可打印的英文和西班牙文活动。免费可打印的是证书和奖杯涂色页。来源：家庭指南、进度报告帮助页。

**[Data]** 2024-07-10 官方博客：手机 App 不再提供，手机浏览器用网页版。

家长不建账号：公开流程从注册家庭账号或用学校传单上的 12 位码绑定开始。没有写访客练习。飞机：帮助中心的技术要求是已联网的浏览器。答错：练习记录错的数，超时后给出正确答案并要求重输；官方说明不教步骤，因此没有「标出心算失败步骤」这一层。置信度：高。这几条都是 2024–2026 的官方页。

## Reflex

**[Data]** 官方产品文把 Reflex 写成自适应、个性化的在线程序，年级约 2 年级起，练加减乘除的基本事实。系统按事实族出题，并用交换律、规则型模式和视觉模型介绍新事实；会按表现调整。学生可从「任何联网设备」登录，把学校的练习延续到家里。来源：Reflex 研究摘要 PDF（正文引用到 2024 年调查，封面无单独出版日期，2026-11-19 抓取）；家庭与学校说明页。

**[Data]** 研究摘要把一次练习拆成三截：Fact Fair 评估、Coach Penny 的辅导、Reflex Island 上最多十个游戏。辅导按该生还不流利的事实决定当天教什么。教师报告可看使用和进步，并在使用量低于建议时提醒。来源：同一份研究摘要。

**[Data]** 帮助中心《Coaching Practice Activities》（约 2026 年 10 月仍在更新）：Coach Penny 先有一段短的学习，呈现新事实并让学生练，再到练习活动。目标是让学生凭记忆回答新事实。另一篇辅导游戏说明写：答错时角色变慢，错得太多会完全停下。来源：ExploreLearning 帮助中心，文章 8976358、9000271。

**[Data]** iPad 学生端要先下载 Reflex Student，再用教师用户名、班级、自己的名字和密码登录。系统要求页（Anthony Jennings，2026-10-16）列出的是最新 Chrome、Edge、Firefox 或 Safari，声音，以及至少 1024×768；iPad App 支持 iOS 11 及更新。这一页没有出现「离线」或「必须有互联网」这几个词。下载帮助只写下载 App 时 iPad 要联网。来源：帮助中心文章 8954974、17643727、8954956。

**[Data]** 家长页的标题是免费家长账号，条件句是：如果孩子通过学校在用 Reflex，可以注册免费的家长报告账号，查看孩子已掌握哪些事实和事实族。报价页另有 Home User License，对象是在家教育、家教和家长，包含一年使用权以及个人和小组的管理与报告。来源：`reflex.explorelearning.com/parents` 与 `/buy`，2026-11-19 抓取。

家长不建账号：自适应练习和学生报告的公开入口都是登录。免费家长报告还要先有学校分配的孩子账号。在家教育走的是付费的 Home User License，仍然是账号。飞机：产品文和「联网设备」这句话把练习放在在线场景里；2026-10-16 的系统要求页没有承诺断网可练，也没有写本地缓存。答错：公开帮助写的是角色变慢或停下，以及辅导段先教新事实。没有句子说答错后标出计算里失败的那一步。DATA GAP：iPad App 在安装并登录之后，断网时游戏是否还能开。置信度：在线定位为高；「飞机上一定不能练」为中，因为系统要求页没有直接写禁止离线。

## Math Tricks: Mental Math

对照的是同一作者的商店条目：Google Play `example.matharithmetics`（开发者名 Mental Math Tricks Academy），美国区 App Store id 1209287132（开发者 Antoni Ion）。隐私政策在 `antonisoftgroup.github.io/privacy.html`，数据控制者 Antoni Ion Software，政策写着 LAST UPDATED: July 22, 2026。

**[Data]** Play 简介（2026-11-19 抓取，页面写 Updated on Nov 19, 2026）列出：逐步学习并且难度上升、计时训练、进度和评分、每项技巧多个等级、每题 15 秒的计时挑战、按表现给星。主题包括加减优化、乘除捷径、百分数、平方和进阶算术模式。商店标记 Contains ads、In-app purchases、10M+ Downloads、Everyone。

**[Data]** 同一 Play 页的 What’s new：v3.71 扩展游戏统计；v3.65 每日连续打卡图，以及漏打一天的保护；v3.64 Cloud progress saving；v3.52 Step-by-step example solutions。数据安全声明写可能收集并与第三方共享位置和 App 活动等，数据在传输中加密，且「数据不能删除」。这是开发者向商店提交的声明。

**[Data]** 美国区 App Store（2026-11-19 抓取）：免费，含广告，内购 Remove Ads $4.99，4+，iOS 15 或更高，包体 40.5 MB，支持 Game Center 和排行榜。简介写：学一条技巧，跟着步骤，再自己练；把计算拆成更简单的步骤。What’s new 的 2.0（页面只写 Nov 11，没有写年份）是：新的视觉样式，以及「现在可以逐步解题」。这一条简介没有写 15 秒。隐私营养标签写用于追踪的数据包括位置、标识符、使用数据和诊断数据；与身份关联的数据包括联系信息，分析用途下有 Email Address。

**[Data]** 隐私政策只区分免费版和已购去广告版。免费版把广告标识、IP 和设备类型交给 AdMob。闹钟等权限被写成只在本机使用，不靠这些权限收集或传个人数据。付款由商店处理。政策全文没有注册、登录、云端存档或离线这几节。

家长不建账号：两家商店的功能简介都没有写「先注册才能做题」。Play 更新日志已经有云端存进度，App Store 营养标签列出邮箱，隐私政策又没写账号。DATA GAP：不登录能否做完一课、进度是否只留在本机、云端存档是可选还是强制。飞机：DATA GAP。没有「无网络可练」的句子；云端存进度这一条说明至少有一条功能要网络。答错：Play 的逐步例题和 App Store 的「逐步解题」写的是例题和解题过程。两页都没有写答错后指出哪一步错了。iOS 上是否仍是每题 15 秒，DATA GAP，15 秒只出现在当天的 Play 简介里。置信度：广告、逐步例题、Play 的 15 秒和云端存进度为高；无账号、可离线为低，因为页面互相没对齐。

2018–2023 年的商店评论提到广告打断和计时压力。评论不是帮助中心，只作旁证。Children and Media 的旧评测写过 Google 登录、以及「没有内购」。这和 2026 年商店上的 Remove Ads 内购不一致，不采用为现行机制。

## Mathseeds

**[Data]** Google Play `com.blake.mathseeds`（Blake eLearning Pty Ltd，2026-11-19 抓取，Updated on Oct 20, 2026）：3–9 岁，200 节自学课，到大约 3 年级；有分班测验、地图结束测验和 Driving Tests；详细报告；「数百张可打印练习卷，用来补充在线课，并把学习带到离线」。最低要求写明：无线网络连接，以及有效的试用或订阅。「Users must log in with their account details to access Mathseeds.」一份订阅最多四个孩子。教师账号目前不支持。商店标记有内购，没有在这条简介里写第三方广告。

**[Data]** 开发者在 Play 评论里的回复（2025-09-05）把再次要求登录写成安全功能，用来保护 Family Dashboard 里的数据，并写每个孩子有自己的登录。另一条回复（2025-04-08）写：用正确的登录可以在任何设备上用；Google Play 注册失败时可以在网站注册。

**[Data]** 帮助中心《Does Mathseeds have an app?》（Elizabeth Carlson，更新于 2023-05-09）写：没有 App，要在部分 iPad、Android 平板和手机的浏览器里用。这一条和 2026-10-20 仍在更新的 Play App 矛盾。现行商店页优先。2023 年这篇帮助文章视为过时。

**[Data]** 排障 PDF 要求桌面端有固定宽带、平板端有高速 Wi-Fi，并列出必须能访问的域名，包括 `student.mathseeds.com` 和 `api.readingeggs.com`。来源：`mathseeds.com/assets/mathseeds-troubleshooting.pdf`，PDF 本身无日期，2026-11-19 抓取。

**[Data]** Reading Eggs 入门文（页面显示修改于 9 月 23 日，未写年份）把 Mathseeds 放在 3–9 岁，并写家长可在 Family Dashboard 的学生档案里打开 Reports。英国站 FAQ 把更细的时间与测验报告、以及带答案的打印册，写在 Mathseeds Prime 的家庭面板里。这是 Prime 的句子，不自动套到美国区 Mathseeds 主课。

**[Data]** 2015 年 3 月白皮书和版权页为 2015 的报告 PDF 写：游戏会立刻告诉学生这题对不对；Driving Tests 答错要重做该题，以便学生自己检查错误答案；教师能看到各次尝试。这两份文件比 12 个月更旧。2026 年商店页仍使用 Driving Tests 这个名字，但没有重述答错界面。现行「答错后看见什么」记为 DATA GAP。2015 年文件也没有写标出失败步骤。

家长不建账号：2026 年商店页写必须登录，并要试用或订阅。报告在登录后的面板里。飞机：在线课的最低要求包含无线网络；打印卷是商店明确写出的离线补充，不是课本身。答错：现行帮助中心和商店页没有写失败步骤。置信度：登录和无线网络为高；2015 年的重做机制只代表当时的厂商描述，现行界面为低。

## Prodigy

**[Data]** 教师入门（帮助中心，更新于 2024-07-11）把 Prodigy 写成课程对齐的自适应在线游戏。数学题覆盖 1–8 年级。会员不是做这些题目的前提。自适应算法先做分班测验，再沿课程树前进；某项技能做得不好时会退回先修技能。Online 一节写：因为是网页产品，在学校、家里或度假时都能玩；「凡是能上网的地方」都能进入。浏览器和 iPad、Android App 都算官方入口。来源：帮助中心文章 115005896246。

**[Data]** 同一篇文章列出三种免费账号。教师账号管班级、作业和报告。家长账号看进度、取回孩子的登录信息。学生账号只用来登录和玩游戏，不能进家长或教师网站上要登录的部分。

**[Data]** 建学生账号的帮助文（更新于 2026-07-15）从家长账号写起：家长登录后选 Add child、Create account，填写孩子的名、姓的首字母和年级，系统给出用户名和密码。家长面板（更新于 2026-07-08）写：看家长面板必须有家长账号，并且至少关联一个孩子。最近活动能看到技能、所属分支，以及答对的题数。管理孩子的地方可以查看和取回用户名与密码。来源：文章 201597153、115001744726。

**[Data]** 登录帮助（更新于 2026-07-22）：到 `play.prodigygame.com`，输入用户名和密码，或用 Apple、Google、Clever、ClassLink。页面打不开时，帮助中心的第一步是确认系统和「可用的互联网连接」，并列出 `api.prodigygame.com`、`websocket.prodigygame.com` 等必须放行的地址。来源：文章 206956163、213706123。支持设备文（更新于 2025-06-19）分浏览器版和 App 版，没有离线模式这一节。

**[Data]** 游戏内辅助（更新于 2024-07-31）：每一题都可以看提示或课，并使用虚拟学具。提示从左侧灯泡打开，官方称之为解题过程的提醒；看完后回到题目。学具包括画笔、十进制积木、硬币、分数条和计数物。来源：文章 201695627。

**[Data]** Practice Sheets 是会员功能。家长博客写：Core 或 Ultra 可按技能生成 PDF，约 10 题，带答案；Ultra 另有 Frustration Detection。会员说明写练习卷大约 7–10 题，从 Practice Areas 里孩子正在练或可能需要帮助的技能生成，可下载或打印。来源：Prodigy 家长博客《Practice Areas》；帮助中心《Parent Membership Perks》。博客无单独日期，2026-11-19 抓取。

**[Data]** 2026 年公司博客写：不向学生出售数据，不向学生展示第三方广告，面向 1–8 年级，并称符合 COPPA。这是营销页，不是帮助中心的操作步骤。来源：`prodigygame.com` 的 educational-games 博文。

家长不建账号：帮助中心写出的玩游戏方式是学生登录。在家开户的写出路径是家长账号再建孩子账号。家长面板本身也要家长账号。公开帮助里没有家长 PIN；把门的是另一套家长邮箱账号，学生进不了家长站。DATA GAP：是否存在一条完全不经家长或教师、由孩子独自注册的现行入口。本轮在官方帮助里没有找到访客练习。飞机：官方把可玩范围写成有互联网的地方；打印卷是会员功能，而且要先在网上生成 PDF。答错：提示是学生主动打开的过程提醒，加上可拖动的学具。帮助文没有写系统在错误答案上标出失败的那一步。置信度：账号、联网、可选提示为高；「提示的正文是否包含分步」为中，因为帮助文没有贴出提示原文。

## 公开技术栈

本轮不根据安装包、权限或「看起来像网页」推断 React Native、Flutter 或原生。用户要求只有公开的工程文章点名时才写客户端框架。

**[Data]** 五家里，只有 Prodigy 找到厂商工程博客。Prodigy Engineering 在 Medium 的一篇 GraphQL 文章写到前后端之间的 GraphQL 层，并提到 parent mobile app team 要按约定的类型接入。文章没有写这个家长 App 是 Flutter、React Native 还是原生。来源：Angela Lee，*Rediscovering SOLID Principles with GraphQL*，`medium.com/prodigy-engineering`。

**[Data]** Prodigy 的招聘启事（MaRS、Built In；其中一条 Built In 职位在 2025-09-15 下架）列出 AWS、Kubernetes、TypeScript、Python、React、GraphQL、Datadog、Sentry，以及游戏侧的 Pixi.js、Node.js、MongoDB。招聘启事不是工程文章，也不等于学生端客户端的框架。这些职位里没有一句写 React Native 或 Flutter。超过 12 个月或已下架的启事，只说明当时对外怎么招人。

XtraMath、Reflex、Mathseeds、Math Tricks：DATA GAP。没有找到点名客户端框架的公开工程文章。XtraMath 官方写的是浏览器里的网页程序，2024 年起不再提供自己的手机 App。Reflex 官方同时有浏览器和 iPad 学生 App。Mathseeds 与 Prodigy 官方同时有网站和商店 App。Math Tricks 是商店里的已安装 App。这些是发行形态，不是技术栈。

## 少见的机制

下面十条是这五家公开页面放在一起才显得少见的机制。判断依据只限本次读到的帮助中心、商店页和厂商说明。**[Opinion]** 不能外推成整个数学 App 市场都没有。

1. 只有 XtraMath 的帮助中心把练习写成「已联网的浏览器」，并在 2024-07-10 宣布停用自己的手机 App。
2. 只有 Mathseeds 的 2026 年商店页把无线网络写成最低要求，并把打印卷单独写成「把学习带到离线」。
3. 只有 Math Tricks 的现行商店页同时写着第三方广告、Play 上的每题 15 秒，以及逐步例题。
4. 只有 Math Tricks 在更新日志里写 Cloud progress saving，同时隐私政策不提账号。不登录能否练完，因此是缺口，不是已证实的纯本机产品。
5. 只有 XtraMath 写明计时器不能关；藏起来以后时间仍在走；超时后出示正确答案并要求再输入。
6. 只有 XtraMath 写明孩子用 4 位 PIN 登录。五家的公开页都没有把 PIN 写成家长锁。
7. Reflex 和 Prodigy 都把自适应出题写进官方说明，而出题和报告都挂在学生账号上。
8. Prodigy 的过程提示要学生自己点灯泡。帮助中心没有写答错后标出失败步骤。
9. 五家的帮助中心和商店页都没有写：答错以后标出心算技巧里失败的那一步。
10. 可打印练习都写在账号或付费后面：XtraMath 家庭许可证、Mathseeds 订阅、Prodigy 的 Core 或 Ultra。没有一家写「不建账号，本机就能打出当天的卷」。

StepMath 计划里的组合是：本机练习、不建账号、无广告、家长 PIN、答错标出失败步骤、本机 PDF。以这五家的公开文字为准，这个组合没有现成的公开对应物。单点并不少见：Math Tricks 已有逐步例题和广告，Prodigy 已有可选的过程提示和付费 PDF，XtraMath 已有孩子 PIN 和超时后的正确答案。

## Red Flags

- 若把「答错标出失败步骤」说成市场上没有人做，证据只够说到：这五家的帮助中心和商店页没有写。界面里仍可能有未写入帮助文档的反馈。本轮没有安装或录屏。
- Math Tricks 在 2026-11-19 的 Play 页已经列出 Cloud progress saving。把它写成「无账号、进度只在本机」会和当天的商店日志冲突。
- Mathseeds 2023-05-09 的帮助文写「没有 App」。2026-10-20 的 Play 列表仍是一个要登录、要无线网络的 App。只用旧帮助文会把渠道判断反了。
- Mathseeds 关于答错重做的原文在 2015 年白皮书和 2015 年版权的报告 PDF 里。课数也已从当时的 140+ 变成商店上的 200。用 2015 年的句子描述 2026 年的错题界面会过时。
- XtraMath 是浏览器里的事实流利度练习，官方写明不教策略。拿它和「本机心算技巧课」比功能表时，品类本身就不同。它的 4 位 PIN 是孩子的登录码，不是家长锁。
- 除 Prodigy 的 GraphQL 工程文之外，没有公开工程文章点名这五家的手机客户端框架。招聘启事不能用来宣布 Prodigy 学生端是 React 或 Pixi.js 做的。

## Yellow Flags

- Math Tricks 的 App Store 营养标签列出邮箱和分析数据，2026-07-22 的隐私政策没有写账号或邮箱。两份厂商文本还没对齐。
- Play 上 Math Tricks 的数据安全声明写数据不能删除。若 StepMath 用「数据留在本机、可以删掉」作对比，对方的商店声明是反方向的，但是声明不是审计。
- Math Tricks 的 15 秒只在 Play 简介里核实到。App Store 简介没有这句。2018 年的一条评论提过另一种 20 秒模式，不能当成现行规则。
- Reflex 2026-10-16 的系统要求页没有写「必须联网」，营销和产品说明却写在线、联网设备。飞机场景因此留了中等置信度，而不是已关闭的缺口。
- Prodigy 灯泡提示的正文没有在帮助文里展开。它可能已经很接近「把过程再讲一遍」，只是没有写成答错后的逐步批改。
- 一份学校转发的 Reflex 家长信（Broward，文件路径时间戳约 2024 年末）写孩子可在有互联网的手机上用。现行家长注册页更短，只承诺查看已掌握的事实和事实族。报告细节以哪一页为准，帮助中心没有单独的目录页把两者对齐。
- XtraMath、Reflex、Mathseeds 的学生练习里有没有第三方广告，本轮打开的帮助页没有写。不能从「页面没提」推出「确认无广告」。Prodigy 的无第三方学生广告来自公司博客，不是帮助中心操作文。

## Sources

- XtraMath 家庭指南，https://home.xtramath.org/family-guide ，抓取 2026-11-19
- XtraMath 家庭快速入门 PDF，https://cdn0.xtramath.org/docs/en/XtraMath-family-homeschool-quickstart.pdf ，抓取 2026-11-19
- XtraMath《Basic requirements》，https://home.xtramath.org/support/basic-requirements-for-xtramath ，抓取 2026-11-19
- XtraMath《How does XtraMath work》，https://home.xtramath.org/support/how-does-xtramath-work ，抓取 2026-11-19
- XtraMath 计时器不能关，https://home.xtramath.org/support/can-i-turn-off-the-timer-during-student-activities ，抓取 2026-11-19
- XtraMath 计时选项，https://home.xtramath.org/support/what-are-the-timer-options-and-how-do-they-benefit-students ，抓取 2026-11-19
- XtraMath 程序设置，https://home.xtramath.org/support/program-settings ，抓取 2026-11-19
- XtraMath 术语与图标，https://home.xtramath.org/support/xtramath-glossary-and-icon-guide ，抓取 2026-11-19
- XtraMath 进度报告，https://home.xtramath.org/teacher-guide/profress-reports ，抓取 2026-11-19
- XtraMath 博客，手机 App 停用，2024-07-10，https://home.xtramath.org/blog/new-enhanced-student-experience-this-school-year
- Reflex 家庭与学校说明，https://reflex.explorelearning.com/resources/insights/math-fact-fluency-home-and-school ，抓取 2026-11-19
- Reflex 研究摘要 PDF，https://reflex.explorelearning.com/user_area/content_media/raw/Reflex-Research-Summary.pdf ，抓取 2026-11-19，正文引用研究至 2024
- Reflex 家长注册，https://reflex.explorelearning.com/parents ，抓取 2026-11-19
- Reflex 报价与 Home User License，https://reflex.explorelearning.com/buy ，抓取 2026-11-19
- ExploreLearning 系统要求，Anthony Jennings，2026-10-16，https://help.explorelearning.com/en/articles/8954956-system-requirements-and-test-page
- Reflex iPad 登录，https://help.explorelearning.com/en/articles/8954974-accessing-reflex-or-frax-via-the-ipad-app ，页面写 October 13, 2026
- Reflex 辅导活动，https://help.explorelearning.com/en/articles/8976358-coaching-practice-activities
- Reflex 辅导游戏与答错变慢，https://help.explorelearning.com/en/articles/9000271-reflex-coaching-practice-activities
- Broward 学校转发的 Reflex 在家说明 PDF，https://resources.finalsite.net/images/v1730401395/browardschoolscom/it6nhv6v68qxbxgkhidc/reflex-parent-and-teacher-remote-learning-guide.pdf ，路径时间戳约 2024-10，抓取 2026-11-19
- Math Tricks Play，https://play.google.com/store/apps/details?id=example.matharithmetics&hl=en_US ，页面写 Updated on Nov 19, 2026
- Math Tricks 美国区 App Store，https://apps.apple.com/us/app/math-tricks-mental-math/id1209287132 ，抓取 2026-11-19
- Math Tricks 隐私政策，LAST UPDATED July 22, 2026，https://antonisoftgroup.github.io/privacy.html
- Mathseeds Play，https://play.google.com/store/apps/details?id=com.blake.mathseeds&hl=en_US ，页面写 Updated on Oct 20, 2026
- Mathseeds《Does Mathseeds have an app?》，Elizabeth Carlson，2023-05-09，https://support.mathseeds.com/en_US/does-mathseeds-have-an-app
- Mathseeds 排障 PDF，https://mathseeds.com/assets/mathseeds-troubleshooting.pdf ，抓取 2026-11-19
- Mathseeds 白皮书，2015 年 3 月，https://mathseeds.com/assets/mathseeds-white-paper.pdf
- Mathseeds 报告 PDF，版权 2015，https://mathseeds.com/assets/mathseeds-reporting.pdf
- Reading Eggs / Mathseeds 入门，https://support.readingeggs.com/support/solutions/articles/266070-getting-started ，页面写 Modified on Wed, 23 Sep
- Prodigy 教师入门，更新 2024-07-11，https://prodigygame.zendesk.com/hc/en-us/articles/115005896246-Teachers-Getting-Started-with-Prodigy
- Prodigy 新建学生账号，更新 2026-07-15，https://prodigygame.zendesk.com/hc/en-us/articles/201597153-How-to-Create-A-New-Student-Account
- Prodigy 家长面板，更新 2026-07-08，https://prodigygame.zendesk.com/hc/en-us/articles/115001744726-Parent-Dashboard
- Prodigy 登录，更新 2026-07-22，https://prodigygame.zendesk.com/hc/en-us/articles/206956163-How-to-Log-in-and-play-Prodigy
- Prodigy 页面打不开，更新 2024-10-08，https://prodigygame.zendesk.com/hc/en-us/articles/213706123-The-website-website-pages-does-not-load
- Prodigy 游戏内提示与学具，更新 2024-07-31，https://prodigygame.zendesk.com/hc/en-us/articles/201695627-FAQ-In-Game-Student-Math-Aids
- Prodigy Practice Areas 博客，https://www.prodigygame.com/main-en/blog/practice-areas-tool ，抓取 2026-11-19
- Prodigy 会员权益，https://prodigygame.zendesk.com/hc/en-us/articles/360045401352-Parent-Membership-Perks ，抓取 2026-11-19
- Prodigy 无第三方学生广告的公司博客，https://www.prodigygame.com/main-en/blog/educational-games-for-children ，抓取 2026-11-19
- Prodigy Engineering，GraphQL 与 parent mobile app team，https://medium.com/prodigy-engineering/rediscovering-solid-principles-with-graphql-c24070221263 ，抓取 2026-11-19
