# Backlog — Earendil 风格复刻（待办）

以上是对线 baiheyufei's-blog 的 Earendil 风格改造，按用户决定先做了 CSS 近似版，以下两项明确推迟，待全部工作结束后再评估是否实施。

## 1. 完全复刻 WebGL 着色器背景
当前 `.background` 用 CSS 径向渐变 + `feTurbulence` 噪点纸纹近似 Earendil 的 shader（地平线 + 纸质纹理 + 明暗双主题）。

目标：复刻 earendil.com 的 `<canvas>` WebGL fragment shader（纸张噪点材质 + 地平线 + 相机透视），替换 `src/styles/global.css` 里的 `.background` 元素。
- 涉及：新建 `src/components/BackgroundCanvas`，全局初始化脚本
- 需保留明暗主题同步（`--veil-r/g/b`，以及 `--theme-transition-duration` 的平滑过渡）
- 注意 `prefers-reduced-motion` 降级
- 参考：earendil.com `/static/script.js` 中的 canvas 初始化与 shader

## 2. 复刻 htmx 局部换页 + 滚动记忆 + i18n
当前保留 Astro 原生导航 + 页面淡入（`.page` 的 `pageEnter` 动画）。

目标：引入 htmx 无刷新换页（`hx-boost`/`hx-select="div.page"`），并加入：
- 滚动位置记忆（back/forward 恢复）
- 内容页间的局部淡出/淡入（`.content-page` 在 content-to-content 导航时只过渡内容面）
- i18n 语言切换（EN/中文），参考 earendil: host `/static/i18n.js` + `data-i18n-*` 属性

注意：与 Astro 的 `prefetch: { prefetchAll: true }` 存在重叠，需评估取舍。

## 实现现状记录
- 字体：等宽 `MapleMono`、衬线 `Noto Serif SC Variable`（`@fontsource-variable/noto-serif-sc`）
- 背景：CSS 近似（见上）
- 导航：MENU 切换（桌面右对齐下拉 / 移动端全屏面板）
- 主题：`.dark` on `<html>`，600ms 平滑过渡，localStorage 持久化
- 页面：首页 hero、文章列表、正文（`.prose` 衬线）、about、friend 均已统一
