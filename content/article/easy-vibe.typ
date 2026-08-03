#import "/typ/templates/blog.typ": *

#show: main-zh.with(
  title: "Easy Vibe学习过程记录",
  desc: [\[Easy-Vibe 教程\]\(https://datawhalechina.github.io/easy-vibe/zh-cn/stage-1/ai-capabilities-through-g...],
  date: "2026-07-17",
  tags: (
    blog-tags.misc,
  ),
  show-outline: true,
)

> 本文是我在跟着 #link("https://datawhalechina.github.io/easy-vibe/zh-cn/")[Easy-Vibe 教程] 学习过程中的一些随笔。 

== 初级一：AI 时代，会说话就会编程
#link("https://datawhalechina.github.io/easy-vibe/zh-cn/stage-1/ai-capabilities-through-games/")[Easy-Vibe 教程]
这是第一章，目的是带学生体验Vibe Coding，一句话描述一个简单的小项目。这大概也是我之前接触过的，并且最常用的模式。
下面是一部分精彩内容的摘抄：
> 
=== 对话编程能做什么不能做什么
	本节聚焦一个具体问题：当你只依赖对话式 AI、不写任何代码时，它究竟能把事情推进到哪一步。在经验层面，一个较为稳定的结论是：它可以帮你完成一个“小而完整”的东西，但“做到什么程度就算够”，仍然需要你亲自决策每一步的详细步骤。
==== 更擅长“小而清晰”的应用
	从前面的贪吃蛇示例中，你已经看到了一种典型模式：只要你能把界面和交互说清楚，AI 通常可以在几轮对话内，拼出一个可以打开、可以点击、可以玩的完整网页。
	这类任务往往具备几个共同特征：
	- 范围清晰：一页网页、一个简单内部工具、一个小玩法
	- 结果可见：你能立即在浏览器中验证是否按预期工作
	- 纠错直接：发现问题后，可以在后续对话中点明具体现象并要求修正（通过复制错误直接粘贴，或者截图粘贴的形式让 AI 进行修改）
	在这个边界内，你可以把对话式 AI 看作一位执行力不错的”辅助开发者”。你只需在每一轮用自然语言细化和修正需求，就能快速得到可用的原型。
==== 大型项目需要“流程视角”
	一旦超出小而清晰的范围，只指望靠几轮对话让 AI 端到端完成复杂系统，很快就会遇到上限。大型项目往往要接后端、连数据库、整合第三方服务，还牵涉权限、安全、并发和大量业务规则，目标是交付一整套与现有业务深度打通的系统，而不是一页网页。
	在这种情况下，更合理的做法不是把所有需求一股脑丢给 AI，而是先梳理出清晰的整体流程：关键步骤是什么、每一步的输入输出和状态变化是什么、哪些节点对性能和安全最敏感。再基于这张流程图，把相对独立的环节拆分出来，交给对话式 AI 生成接口、模块、脚本和测试。
	以目前的能力来看，AI 更擅长加速一个个小步骤，由你（或你的团队）来决定怎么拆步骤、如何串联，并负责最终的架构设计、系统集成和运维。

== 跟着vibe一个应用
#link("https://datawhalechina.github.io/easy-vibe/zh-cn/stage-2/frontend/multi-product-ui/#%E5%8F%82%E8%80%83-ui-%E8%AE%BE%E8%AE%A1%E8%A7%84%E8%8C%83%E8%AE%BE%E8%AE%A1%E9%A1%B5%E9%9D%A2%E5%92%8C%E6%8C%89%E9%92%AE")[Easy-Vibe 教程]
目标：
== 参考 UI 设计规范设计页面和按钮
=== 怎样用 AI 参考别人的规范来设计页面
这一节最实用。
很多人让 AI 设计页面时，只会说：
```plain text
帮我做一个设置页面，要高级一点，参考苹果风格
```
这类提示词太模糊了，AI 最后通常只能模仿“白底、圆角、阴影”。
对新手来说，更实用的方式不是自己总结一大段，而是直接把规范原文里的关键句贴给 AI。
这样做有两个好处：
- 你不用自己先“翻译”一遍设计思想
- AI 更容易按官方定义去理解页面和按钮
=== 6.1 例子一：让 AI 参考 Apple 设计一个设置页面
先找一句 Apple 原文：
> #link("https://developer.apple.com/design/human-interface-guidelines/")["Establish a clear visual hierarchy..."]
你可以直接这样贴给 AI：
```plain text
参考 Apple Human Interface Guidelines 里的这句话：
"Establish a clear visual hierarchy..."

帮我设计一个账号安全设置页面。
要求页面层级清楚，重要信息放前面，分组整齐一点。
```
这样写的重点是：不用你自己解释太多，直接把 Apple 的原话贴进去。
=== 6.2 例子二：让 AI 参考 Fluent 设计后台页面按钮
先找一句 Fluent 原文：
> #link("https://fluent2.microsoft.design/components/web/react/core/button/usage")["Only use one primary button in a layout..."]
你可以直接这样贴给 AI：
```plain text
参考 Fluent 2 里的这句话：
"Only use one primary button in a layout..."

帮我设计一个团队管理后台的按钮。
添加成员按钮最明显，导出、筛选、更多操作弱一点，删除按钮单独突出。
```
这一句非常适合新手，因为它直接告诉 AI：一个区域不要放太多主按钮。
=== 6.3 例子三：让 AI 同时参考页面规范和按钮规范
你也可以一次贴两句原文，让 AI 同时参考页面和按钮：
> Apple: #link("https://developer.apple.com/design/human-interface-guidelines/")["Establish a clear visual hierarchy..."]
	Fluent: #link("https://fluent2.microsoft.design/components/web/react/core/button/usage")["Only use one primary button in a layout..."]
然后直接这样写：
```plain text
参考下面两句设计规范原文：
Apple: "Establish a clear visual hierarchy..."
Fluent: "Only use one primary button in a layout..."

帮我设计一个项目详情页。
页面包含项目介绍、成员、最近活动和设置入口。
页面层级清楚一点，主按钮只保留一个，其他按钮弱一点。
```
这种方式特别适合新手，因为你只要会复制原文，再加两句自己的需求就够了。
=== 怎样用 AI 参考按钮规范来直接生成按钮设计
如果你只想先做按钮，也可以直接贴按钮规范原文。
例如 Atlassian 对按钮的定义很短：
> #link("https://atlassian.design/components/button/")["A button triggers an event or action."]
你可以这样问 AI：
```plain text
参考 Atlassian 的这句话：
"A button triggers an event or action."

帮我设计一套后台页面按钮样式。
我要有主按钮、次按钮、删除按钮，顺便告诉我分别用在什么地方。
```
这类提示词尤其适合新手，基本就是“贴原文 + 说需求”。
=== 小结
参考 UI 设计规范设计页面和按钮，最重要的不是“做得像谁”，而是学会下面这几件事：
+ 用层级组织页面，而不是把内容堆上去
+ 用按钮分级表达操作优先级，而不是让所有按钮都一样抢眼
+ 用设计规范里的定义、边界和判断标准指导设计
+ 让 AI 参考别人规范时，参考的是“原则和结构”，而不是只参考皮肤
当你这样使用规范时，你参考到的就不只是一个风格，而是一套成熟的设计思考方式。

== 用Skills美化界面
#link("https://datawhalechina.github.io/easy-vibe/zh-cn/stage-2/frontend/llm-skills-beautiful/")[Easy-Vibe 教程]
=== 附录：设计风格速查表


风格
关键词
适用场景
示例产品


极简主义
留白、单色、简洁
高端产品、个人作品集
Apple官网


玻璃拟态
毛玻璃、渐变、模糊
科技产品、SaaS 落地页
macOS Big Sur


新野兽派
粗边框、硬阴影、纯色
潮流品牌、艺术类网站
Brassius


Bento Grid
网格、拼贴、卡片
信息展示、仪表盘
Apple 宣传页


复古未来
霓虹、渐变、合成器波
游戏类、音乐类
STRANGER THINGS


手绘风格
不规则、圆润、插画
教育类、儿童产品
Duolingo


杂志风
大字体、不对称、留白
内容型网站、博客
Medium


暗色奢华
深色、金色、精致
高端产品、奢侈品
各种高端品牌


=== 附录：Skills 安装速查
```plain text
# UI/UX Pro Max
npm install -g uipro-cli
uipro init --ai claude

# Anthropic frontend-design
npx skills add anthropics/skills/frontend-design

# Anthropic brand-guidelines
npx skills add anthropics/skills/brand-guidelines

# 查看 Claude Code 中已安装的 Skills
/help
```
=== 附录：配色方案推荐


配色方案
主色
点缀色
背景
风格


日落
\#F97316
\#FBBF24
\#FFF7ED
温暖、活力


海洋
\#0EA5E9
\#06B6D4
\#F0F9FF
清新、专业


森林
\#10B981
\#34D399
\#ECFDF5
自然、健康


浆果
\#8B5CF6
\#EC4899
\#FAF5FF
浪漫、创意


咖啡
\#78350F
\#D97706
\#FFFBEB
温暖、复古


单石
\#6B7280
\#9CA3AF
\#F9FAFB
专业、中性


=== 附录：设计风格提示词速查
让前端页面更好看可以尝试的提示词：
==== 风格类别


风格
关键词（英文）
核心视觉特征
提示词示例


波普艺术
Pop Art
大胆的撞色、黑色轮廓线、网点纹理
Pop art style website, bold colors and comic dots, vibrant


极简主义
Minimalism
大量留白、极少色彩与线条、无装饰
Minimalist web design, ample white space, geometric, serene


抽象表现主义
Abstract Expressionism
充满情感张力的笔触、泼洒色彩
Abstract expressionism background, dynamic paint splashes, emotional


复古风格
Retro/Vintage
旧式字体、做旧纹理、复古配色
Retro 80s website design, neon grid and synthwave color palette


赛博朋克
Cyberpunk
高对比霓虹色、故障艺术效果、暗黑背景
Cyberpunk UI, neon lights on dark background, glitch effects


新拟态
Neumorphism
柔和的阴影与高光，轻微凸起/凹陷质感
Neumorphism design style, soft shadows, clean and modern


生成式艺术
Generative Art
算法生成的流动的视觉图案
Generative art background, flowing algorithmic patterns, digital


酸性设计
Acid Graphics
金属质感、玻璃态、锯齿字体
Acid graphics web layout, glass morphism, chaotic typography


沉浸式3D
Immersive 3D
互动3D场景、空间感极强
Immersive 3D website, interactive product model in space


== Another Day
第二天,今天主要要折腾办公电脑.
> 麒麟K9000 + 统信UOS, 全国产, 这辈子有了 

	
		> 折腾新电脑:   
			- [x] 终端配置
			- [x] 字体配置
			- [x] 主题
			- [x] 输入法
			- [ ] IDE
			- [ ] Agent相关
	
	
		> 继续昨天vibe的画廊项目:   
			- [x] 修复扫描文件是卡死的问题
			- [ ] 添加AI接口?
	

#line()
    
 

1
