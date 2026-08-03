---
title: "用 Markdown 写作示例"
author: "baiheyufei"
description: "这是一篇用于验证 Astro 内容集合支持 Markdown 写作的示例文章。"
date: 2026-08-03
tags: ["markdown", "blog", "astro"]
---

# 你好，Markdown！

这是一篇用 **Markdown** 写成的博客文章，用于验证 Astro 内容集合对 `.md` 文件的支持。

## 支持的能力

+ 标准 Markdown 语法：标题、列表、表格、引用等
+ 代码块自动语法高亮（Astro 内置 Shiki）

```js
console.log("Hello, Astro!");
```

+ 行内代码如 `render()`、`<Content />` 以及[链接](https://docs.astro.build/)

## 元数据说明

文章的标题、日期、标签等元数据通过文件顶部的 YAML frontmatter 定义，与 `src/content.config.ts` 中的 schema 保持一致：

```yaml
title: "用 Markdown 写作示例"
date: 2026-08-03
tags: ["markdown", "blog", "astro"]
```

> 注意：Markdown 文章的 slug 由文件名决定，此文件将生成 `/article/markdown-example/` 页面。
