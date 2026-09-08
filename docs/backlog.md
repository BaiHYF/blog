# Backlog — Earendil 风格复刻（已实现 + 后续待办）

## 已实现

### 1. WebGL 着色器背景（完全复刻）
`src/components/BackgroundCanvas.astro` + `src/scripts/ocean-shader.js`：
从 earendil.com 移植 "ocean weaves" 光线步进 shader（MIT 许可，来源 afl_ext）。
- 海面波光（raymarch + FBM 波）＋ 日夜天空 ＋ 夜晚星空 ＋ 胶片颗粒
- logo 水面反射（`public/static/emblem.svg`）＋ 点击涟漪（投影到 y=0 水面）
- `u_night` 随 `<html>.dark` 700ms 平滑混合；`@property --veil-r/g/b` 让纸幕同步淡变
- 内容页降为 15fps / 0.5 分辨率；`prefers-reduced-motion` 降低波速
- WebGL 不可用时回退到 CSS 渐变（`body.no-webgl .background canvas { display:none }`）

### 2. htmx 局部换页 + 滚动记忆
`src/components/PageFrame.astro`：
- `<body hx-boost hx-select="div.page" hx-target="div.page" hx-swap="outerHTML swap:220ms">`
- `.page` 加 `hx-history-elt`；自托管 `public/static/htmx.min.js` + `head-support.js`
- `htmx:beforeSwap` 捕获滚动、加 `.is-leaving`；`afterSwap` 复位到顶；`historyRestore` 恢复 back/forward 滚动
- `htmx:sendError/swapError/responseError` 回退原生跳转
- `astro.config.mjs` 移除了 `prefetch.prefetchAll`（避免与 htmx 双请求）

## 后续待办（可选进阶）

### A. 内容页间细粒度过渡（content-page-swap）
目前整页交叉淡化（`.page.is-leaving` + `pageEnter`）。Earendil 在 content→content 导航时只淡出
`.content-surface`、让背景纸幕不闪断。要复刻需：`beforeSwap` 探测两侧是否都是 `.content-page`，
加 `body.content-page-swap`，并给 `.content-surface` 单独过渡。

### B. htmx 消毒（XSS）
当前未引入 dompurify。自托管可信同源内容暂可。若以后引入外部 / 用户提交的 Markdown，再加
`purify.min.js` 与 `htmx:beforeProcessNode` 过滤。

### C. i18n 语言切换
Earendil 有 EN/中文切换（host `/static/i18n.js` + `data-i18n-*`）。本次未要求，未实现。

## 现状速览
- 字体：等宽 `MapleMono`、衬线 `Noto Serif SC Variable`
- 背景：WebGL shader（CSS 渐变兜底）
- 换页：htmx 局部刷新 ＋ 滚动记忆；首页 hero 居中
- 主题：`.dark` on `<html>`，600ms CSS 过渡 + shader 700ms 混合，localStorage 持久化
