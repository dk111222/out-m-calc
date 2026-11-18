import { PracticeDemo } from "@/components/PracticeDemo";

const FEATURES = [
  {
    title: "技巧阶梯，不是口诀格子",
    body: "从凑十、近双数到拆开相乘、乘 11、×25，覆盖幼儿园到五年级的心算技巧，做错只留一句可审核的策略提示。",
  },
  {
    title: "约四分钟的短会话",
    body: "整屏一题、大号算式、数字键盘。到点做完当前题再结束，适合晚饭后每个人轮流练一轮。",
  },
  {
    title: "家长看见哪一招还不稳",
    body: "进度按技巧「稳了 / 还在学」呈现，而不是金币或排行榜。正式版还可钉住弱项、导出 PDF 练习卷。",
  },
  {
    title: "先体验，不必注册",
    body: "下面的演示会随机出 20 道计算题。答错会显示正确答案和技巧句；换一组可重新抽题。",
  },
];

export default function Home() {
  return (
    <div className="site">
      <header className="site-header">
        <a className="brand" href="#top">
          Steady
        </a>
        <nav className="nav" aria-label="页面导航">
          <a href="#features">功能</a>
          <a href="#try">体验</a>
        </nav>
      </header>

      <main id="top">
        <section className="hero" aria-label="首屏">
          <div className="hero-visual" aria-hidden="true">
            <p className="hint">今晚的一招</p>
            <p className="big-eq">
              39 + 18
              <br />
              → 先加 40
            </p>
            <p className="hint">补偿 · 做错只留一句技巧</p>
          </div>

          <div className="hero-copy">
            <p className="eyebrow">Calculation Trainer</p>
            <h1>Steady</h1>
            <p className="support">
              每天约四分钟，用技巧把小学计算练快练准。家长能看见是哪一招还不稳。
            </p>
            <div className="cta-row">
              <a className="btn btn-primary" href="#try">
                立即体验 20 题
              </a>
              <a className="btn btn-ghost" href="#features">
                了解功能
              </a>
            </div>
          </div>
        </section>

        <section className="section features" id="features">
          <div className="section-inner">
            <p className="eyebrow">功能介绍</p>
            <h2>为短习惯设计的速算训练</h2>
            <p className="lede">
              不做全科数学课，也不做宠物养成。产品押注在一条能从低年级用到五年级的技巧日课。
            </p>

            <div className="feature-list">
              {FEATURES.map((feature, i) => (
                <article
                  className="feature-row"
                  key={feature.title}
                  style={{ animationDelay: `${i * 70}ms` }}
                >
                  <span className="idx">0{i + 1}</span>
                  <div>
                    <h3>{feature.title}</h3>
                    <p>{feature.body}</p>
                  </div>
                </article>
              ))}
            </div>
          </div>
        </section>

        <PracticeDemo />
      </main>

      <footer className="site-footer">
        <span>Steady · 计算技巧日课</span>
        <span>官网演示 · 无需登录</span>
      </footer>
    </div>
  );
}
