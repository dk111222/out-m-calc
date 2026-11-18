# Steady · 计算技巧日课（out-m-calc）

美国 K–5 **计算技巧日课**：每天约四分钟，用凑十、补偿、拆数等技巧练速算；家长看到哪一招稳了；可导出 PDF 练习卷。

当前仓库包含：

1. **需求文档**（`docs/`）
2. **无需登录的官网**（Next.js）：功能介绍 + 随机 20 题体验

## 本地运行官网

```bash
npm install
npm run dev
```

打开 [http://localhost:3000](http://localhost:3000)。

```bash
npm run build && npm start   # 生产构建
```

## 文档

| 文档 | 说明 |
| --- | --- |
| [docs/需求功能书.md](docs/需求功能书.md) | 产品需求与功能规格（v1.1） |
| [docs/feature-checklist.md](docs/feature-checklist.md) | v1 实现勾选清单 |

## 官网范围（本迭代）

- 无注册 / 无登录
- 功能介绍
- 功能体验：随机生成 20 道计算题，即时对错与技巧提示
