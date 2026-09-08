---
title: '关于对 DeepSeek Harness "一切皆插件" 设计思想的简单分析与思考'
description: '对 DeepSeek Harness「一切皆插件」设计思想的深入分析:Cordis 可组合性范式、配置即架构、无特权核心、会话日志唯一事实源,以及设计代价与可迁移要点。'
date: 2026-08-23
tags: ["Software Engineering", "Miscellaneous"]
---

## 序言

对于开源项目，有能力的开发者原本就能按自己的意愿修改。LLM 编程应用出现后，门槛进一步降低：让大模型读源码、按需求改、再重新构建打包。但这条路依然有门槛——需要先拿到源码，让模型改，再重新打包，只是门槛在持续降低。

deepseek harness（简称 dsh）出现后，主打的宣传特性是"一切皆插件"：用户可以借助大模型，近乎随意地按自己的意愿修改这个应用，而且走的是官方给出的渠道。你不喜欢主题界面的颜色？说一句话就换成你想要的。想要侧边栏？任务清单？仪表盘？待办列表？多智能体协同？都可以直接在应用里用自然语言与智能体对话实现。

与其他开源应用相比，dsh 把"DIY 这个应用"的时间成本和 token 成本大幅降低。一切皆插件——所有功能都是可插拔的，随时可以插上你需要的新功能。

如果抛开设计哲学、设计思想，更别提人生观、世界观、价值观这类宏大的东西，我认为"一切皆插件"这种模式的意义很朴素：一方面激发了个人用户的创造活力，另一方面增加了用户的 token 需求。大部分人还是懒得手动 DIY 的，写代码的活都交给 AI。不知道我表述清楚没有：我原本不太用这类智能体，也没有这个需求；但 dsh（以及将来类似的应用）出现后，我产生了兴趣，愿意去 DIY、去玩。于是我就这样给大模型供应商交了更多的钱，需求就是这样被创造出来的。

其他智能体应用，包括 WorkBuddy、Trae 等，也许很快就会学 dsh 的思路，上线类似的功能，让用户能一定程度地 DIY。我们的数字员工 CM-STAFF 也已经紧跟时髦上线了类似功能，只不过还在内测期间。


## 0. 结论

DeepSeek Harness(下称 dsh)是一个基于 Node.js 的 Agent 运行时,核心口号是 "Agent = Model + Harness"。它的插件化程度高于一般框架:模型适配器、工具注册表、会话日志、Agent 主循环、UI、存储、沙箱、调度全部由插件实现,且不存在需要修改源码才能扩展的"特权核心"。

底层框架是 Cordis(vendor 在仓库内,约 2700 行 TypeScript),设计依据为论文 *A Programming Paradigm for Spatiotemporal Composability*(2026-08-13 草稿)。论文把"插件可插拔"形式化为两个维度:**时间可组合性**(组件卸载时副作用完整回滚)和**空间可组合性**(组件间依赖可声明、可响应式解析)。该机制在代码中有完整实现:每个注册都是带逆操作的 effect,插件卸载时按注册逆序全部撤销。

总体评价:这是目前开源 Agent 框架中,把"可组合性"作为编程范式(而非事后插件机制)实现得最彻底的一个。相应的代价是学习曲线较陡、配置树调试较难、v0.1 阶段兼容性不稳定。

## 1. 实验环境

| 项 | 值 | 出处 |
|---|---|---|
| 仓库 | github.com/deepseek-ai/deepseek-harness | README |
| 协议 | MIT | LICENSE |
| 版本 | v0.1 开发者预览,`THERE WILL BE COMPATIBILITY-BREAKING CHANGES` | README |
| 启动 | `npx @deepseek-ai/dsh web` → Web UI 于 127.0.0.1:3080 | README |
| 底层框架 | Cordis(仓库内 vendor,独立发布为 `cordis` 包) | README / vendor/cordis |
| 理论依据 | 论文 *A Programming Paradigm for Spatiotemporal Composability*(cordiverse/paper,preprint) | vendor/cordis/README、仓库 README |
| 语言 | TypeScript,ESM-first,pnpm monorepo | package.json |
| 事件词汇 | 约 40 种 Session 事件类型,由脚本生成目录 | packages/core/session/src/known-event-types.ts |

## 2. "一切皆插件"的四个层面

### 2.1 配置即架构:整个产品是一张 YAML 插件清单

运行中的 dsh 由 YAML 配置决定。以 `packages/bundle/base/cordis.patch.yml` 为例:

```yaml
# dsh-base bundle patch:the shared core of every dsh profile
- insert:
    - id: llm
      name: '@deepseek-ai/dsh-llm'
    - id: session
      name: '@deepseek-ai/dsh-session'
    - id: agent
      name: '@deepseek-ai/dsh-agent'
    - id: agent-default-model
      name: '@deepseek-ai/dsh-agent-default-model'
      config:
        provider: deepseek-official
        model: deepseek-v4-flash
    - id: sandbox
      name: '@deepseek-ai/dsh-sandbox-local'
    - id: approval
      name: '@deepseek-ai/dsh-user-approval'
    - id: tool-bash
      name: '@deepseek-ai/dsh-tool-bash'
    # ... 共 80+ 行
```

每一行对应一个插件(id、npm 包名、config)。可以认为"产品"就是这些配置行的总和。

组合机制(`packages/boot/app-boot/src/profile.ts` + `docs/architecture.md`):

- **Profile**(命名组合):`$DSH_HOME/profiles/<name>/` 目录,包含 `package.json`(声明有序的 `dsh.profile.bundles` 列表和外部插件依赖)与用户自己的 `cordis.patch.yml`。
- **Bundle**(发行格式):npm 包,`package.json` 中 `dsh.bundle.patch` 指向其 patch 文件。bundle 是"配置行 + 对应代码"的打包。
- **分层叠加**:按 `profile.bundles` 顺序将每个 bundle 的 patch 应用到空条目列表,再依次应用 profile 的 patch、home 级 patch 与 `--patch` 覆盖层。
- **Patch 语义**:按 `id` 定位行,整行替换或插入新行;同一行多次写入时,最后写入者生效(last write wins)。
- **可观测性**:`dsh --profile web --dump-config` 打印实际启动的整棵插件树;树中任意一行都可以被用户 patch 替换,这是"没有特权核心"在配置层的具体含义。

关键细节:patch 是整行替换,不是合并。因此同一个插件在不同模式下配置不同的行,必须由各模式 bundle 声明完整配置,保证"一行最多被 bundle 层与用户层各写一次"。这是官方在 base patch 头部注释中明确的规则。

### 2.2 内核极小:Cordis 的五个概念

`vendor/cordis/src/` 全部源码约 2700 行:`context.ts(146) events.ts(352) fiber.ts(754) registry.ts(337) service.ts(115) reflect.ts(418) utils.ts(287)`。

`docs/cordis-primer.md` 用五个概念概括:

1. **插件 = 实现 Service 的对象**(函数 + 可选 `inject`/`apply(ctx)`,或 `Service` 子类)。
2. **Context = 服务的仓库**:服务在 ctx 上占据稳定键(`ctx.tools`、`ctx.llm`、`ctx.sessions`),其他插件通过键查找,而不是 import 具体实现。
3. **依赖通过 `inject` 声明**:插件声明所需服务,框架等服务就绪后再启动插件;加载顺序由服务依赖表达,而非手工编排。
4. **类型化事件通信**:通过 TypeScript 声明合并定义事件名,按 `emit`(观察)/ `waterfall`(环绕中间件,`next()` 委托)/ `parallel`(并行)/ `serial`(顺序)分派。
5. **注册即可逆 effect**:prompt 段、工具 schema、适配器、监听器均通过 `ctx.effect()` / `ctx.on()` 安装,reload/teardown 时按注册逆序完整撤销。

`fiber.ts` 中每个 effect 返回一个 disposer;`Fiber` 管理插件生命周期,卸载时逆序执行所有 disposer(支持异步)。这是论文中 "revertible effects" 的运行时实现。

### 2.3 无特权核心:Agent 主循环本身也是插件

架构文档原文:*"There is no privileged core to patch:you extend dsh by mounting a plugin beside the others, and registrations are effects that unwind when their plugin unloads."*

- `@deepseek-ai/dsh-agent-loop`(`packages/core/agent-loop/src/index.ts`)是默认循环插件:创建 scoped 的 `ReactLoopAgent`,通过 agent/session 注册表发布,并负责有序 teardown(`FactoryOwnership` 跟踪活体 agent 与启动任务)。
- 需要替换循环时,注册另一个提供 `Agent` 接口的插件即可。`core/agent` 定义接口,`core/agent-loop` 是默认实现,接口与实现分离,两者均为插件。
- 校验循环不变式的逻辑也是插件:`packages/core/agent-loop/src/invariant.ts` 通过 `ctx.invariants` 注册一个 `llm/stream` 监听器,检查"模型请求必须能从日志重建"。

### 2.4 会话日志作为唯一事实源(运行时强制)

- `core/session`:`SessionEvent` 是 append-only 日志,通过 `session/event` 广播;Fork、重放、转录、遥测、持久化均从这条流派生。
- 模型可见表面(surface):只有三种事件类型能投影为 LLM 消息——`user/message`、`assistant/message`、`tool/result`(`packages/core/session/src/surface.ts`)。`deriveMessages()` 将日志投影为模型历史。
- 不变式 "Model-visible means logged":任何进入模型请求的内容必须能从日志重建。`invariant.ts` 在每次 `llm/stream` 时断言:请求必须冻结、必须携带 session id、日志中必须有 `step/start` 与 `request/header`、`messages` 必须等于 `session.deriveMessages()` 的结果、header 各字段必须一致。违反该不变式会导致请求失败。
- 新增模型可见输入的唯一途径是扩展 `SessionEventMap` 并从日志渲染——日志是唯一事实源,模型可见性等价于日志可见性。
- 前向兼容:日志中出现 `KNOWN_SESSION_EVENT_TYPES` 之外的类型时,持久化读取端拒绝解释(除非带 `ignorable` 标记),避免用旧代码重建新日志产生错误会话(known-event-types.ts)。

## 3. 模式与预设:模式本身也是配置

发布公告称 v0.1 提供四种模式:标准 / PTC(程序化工具调用,模型生成代码编排多轮工具调用)/ 极简(仅保留 shell 与文件编辑工具,用于基准测试)/ 创造(运行时检查当前环境、试验 Cordis 插件并组合新模式)。

当前 master 已将其调整为 **agent-presets**(`apps/cli/config/agent-presets/`),四个预设为 `standard`(功能完整的编码 Agent)、`minimal`、`code`、`cordis`。每个预设由两个文件组成:

- `preset.yml`:`name` / `description` / `order`(UI 排序用)
- `agent.cordis.yml`:YAML 组合,包含 persona、agent-instructions、tool-bash(win32 上自动禁用)、tool-pwsh、tool-fs、tool-fs-search 等

这可以视为"一切皆插件"的一个例证:产品自身的"模式"以配置文件形式发布,修改模式不需要改动代码。发布后约十天,预设结构经历了一次重组,与 v0.1 破坏性变更的声明一致。

`headless` bundle 是另一个示例(`packages/bundle/headless/cordis.patch.yml`):不挂载 Host、HTTP server、Web runtime 与浏览器插件,直接通过核心注册表创建 Agent,打印持久化结果后退出。同一个 base,不同组合,对应两种差异较大的产品形态(Web IDE 与一次性任务 runner)。

## 4. Seam 的三个角色:更换 provider 的影响范围

`docs/capability-seams.md` 是自动生成的服务图。每个可插拔能力是一个 seam,包含三个角色:

1. **Service Definition**——声明接口(`ctx.llm`、`ctx.tools`、`ctx.sandbox`、`ctx.fs` 等)
2. **Service Provider**——实现接口(如 `llm-deepseek`、`sandbox-local`)
3. **Consumer**——使用接口,通常是模型可见工具

架构文档的关键论断:"Seams are why one provider swap changes the whole product." 例:filesystem 与 subprocess 共享同一个执行世界,将 sandbox provider 指向远程沙箱后,Bash、PTY、LSP 会随之迁移,不需要为每个工具维护 provider 分叉。同理,subagent provider 的同一个接口背后,可以是进程内子 agent,也可以是委派给另一个产品的一轮对话。

扩展点(摘自 architecture.md,节选):

| 想做什么 | 挂哪里 |
|---|---|
| 加模型 provider | 在 `ctx.llm` 注册 adapter |
| 加模型可见能力 | 注册到 `ctx.tools`,schema 自动进入 prompt 组装 |
| 加 shell 执行 | 注册 `ctx.shell` backend |
| 加后台任务 | 注册 `ctx.jobs` |
| 加文件系统访问/策略 | 注册 `ctx.fs` provider 或监听 `fs/*` 事件 |
| 拦截请求/工具/回合 | `agent/*` 或 `tools/*` 事件(`agent/turn-stopping` 可停止回合) |
| 加模型可见上下文 | `agent.inject()` |
| 加 UI/编辑器集成 | 驱动 `ctx.agents`,从 `session/event` 渲染 |
| 加持久会话状态 | 扩展 `SessionEventMap`,从日志渲染/重放 |

设计纪律:一行插件若注入服务,则归宿主层;若要在预设中提供服务行,必须放入带 `isolate` realm 的 group,否则会发布进 root realm 造成进程级串扰。`dsh-agent-presets` 在挂载时会拒绝此类行(standard preset 头部注释)。这相当于在配置层做类型检查。

## 5. 论文的Title: 可组合性的形式化

*[A Programming Paradigm for Spatiotemporal Composability](https://github.com/cordiverse/paper)*(preprint,2026-08-13):

- 现代软件(插件系统、自进化 agent harness)需要动态组合,但其形式化基础薄弱。
- 两个正交维度:
  - **时间可组合性**:组件移除时能完全回滚其副作用。
  - **空间可组合性**:组件间依赖可声明、可响应式管理。
- 方法:将 effect / coeffect 概念提升为运行时机制——每个上下文变换携带运行时跟踪的逆(revertible effects);上下文每次变化按组件的 coeffect 规格通知组件(reactive coeffects);effect 上下文与 coeffect 上下文统一为单一 context 类型。
- 在此基础上定义 component,给出动态组合的演算,将时空可组合性从单个组件推广到交错组件的整个系统。
- 实现:Cordis——effect 跟踪 + coeffect 解析 + 声明式组件加载器(配置协调 + HMR)。

用工程语言概括:"插件卸载要干净"与"插件依赖要声明"不是约定,而是运行时保证的语义。框架保证移除任何组件都不会留下副作用残留,这是 dsh 将一切组件化的前提。

## 6. 设计的代价

### 6.1 内核与信任边界

Cordis 的 Context(service resolver 代理)、Registry、Loader 与配置协调逻辑是事实上的内核。"没有特权核心"是设计目标,而非客观事实。真正需要关注的是信任边界的位置:

- `cordis.patch.yml` 支持 `!!js` 表达式(YAML 中直接写 JS,挂载时求值),配置即代码。示例(`headless/cordis.patch.yml`):

  ```yaml
  - id: headless-runner
    config:
      task: !!js ctx.headlessStartup.task
  ```

  这一特性对供应链有较大风险:安装恶意插件等同于在配置层执行任意代码。
- 社区插件数量较多(900+),且 fs/subprocess provider 可指向远程执行世界,prompt injection 与供应链攻击面大于传统框架。base bundle 内置 approval(人工审批)与 sandbox-policy,方向正确,但默认值需要仔细检查。

### 6.2 配置树调试困难

分层 patch 与 last-write-wins 语义下,`--dump-config` 能展示某行的当前值,但难以回答"这一行被哪一层修改过、为什么是这个值"。排查问题时,需要手动重放层叠顺序。官方以整行替换与分组合法性检查缓解该问题,但缺少类似"配置来源链"的工具。

### 6.3 深度与灵活性的张力

Deep Module 的原则是小接口封装大行为;"一切皆插件"则相反,每个 seam 都有退化为浅接口的风险。Cordis 的三角色 seam 与类型化事件是结构性约束,但约束之外,插件质量依赖社区自律。后续值得观察的是:生态中沉淀的是封装完整行为的插件,还是仅以配置组合实现的临时方案。目前(发布约十天)下结论尚早。

### 6.4 可追踪性的成本

全量 append-only 日志与每次请求的日志重建校验有实际成本:第三方实测一个 35 分钟的任务消耗约 2000 万 token(100% 缓存命中)。审计能力以 token 与延迟为代价,对个人和小团队是实际开销。

### 6.5 v0.1 兼容性

README 明确声明 "THERE WILL BE COMPATIBILITY-BREAKING CHANGES",且公告中的"四种模式"在发布后约十天被重组。当前开发插件需要应对接口变动,建议锁定版本并只依赖稳定 seam(ctx.llm / ctx.tools / session 事件)。

## 7. 可迁移的设计要点

1. **Seam 需要完整设计三个角色**(接口 / 实现 / 消费者),缺一不可。增加能力意味着设计三个角色,而不是写一个函数。
2. **状态采用 append-only 日志,派生视图从日志计算**。dsh 将"模型可见上下文"、"UI 渲染"、"fork"、"标题"全部实现为日志的派生投影,单一事实源消除了大量同步类问题。配合运行时不变式("任何模型可见内容必须能从日志重建"),其约束力强于大量单元测试。
3. **注册是带逆的 effect**。每个注册返回 disposer,卸载时逆序执行;插件/模块系统的"干净卸载"因此成为运行时保证。实现插件系统时,应把清理作为一等公民。
4. **配置即架构,组合即产品**。模式、预设、形态差异通过配置层表达,而非 if-else。`--dump-config` 提供了整系统可观测性,这一思路可迁移到其他项目。
5. **事件是扩展 API,需要类型化与文档化**。dsh 提供自动生成的事件 producer/consumer 总表,dispatch 模式(emit/waterfall/parallel/serial)是事件契约的一部分。扩展面一旦成为文档化的公共 API,生态才能持续生长。
6. **形式化先行**。Cordis 先有论文后有实现,effect/coeffect 的语义并非随意定义。对复杂系统,先精确定义"可回滚、可组合"等概念,实现才有依据。

## 8. 总结
综合上述分析，DeepSeek Harness 在 Agent 框架中提供了一种以“可组合性”为核心编程范式的实现路径。其设计围绕 Cordis 运行时展开，通过配置层声明、依赖注入、可逆注册和事件驱动机制，将模型适配、工具集成、会话管理、主循环等所有能力统一为插件形态，实现了架构层面“无特权核心”的目标。配置即架构的 YAML 组合方案、带逆操作的 effect 语义、以及基于 append-only 日志的一致性模型，构成该框架区别于同类项目的三个显著技术特征。

从实际应用角度看，该设计降低了用户个性化定制的门槛，同时为开发者提供了体系化的扩展接口。但其代价同样明确：配置层调试缺乏来源链追踪，插件质量依赖生态自律，全量日志校验对 Token 与延迟产生可测影响，v0.1 阶段的兼容性波动亦需提前评估。这些约束对于个人用户、小型团队或企业级部署而言，均需根据实际场景权衡。

值得关注的是，DSH 所体现的“可组合性”思想并非仅限于 Agent 领域，其 seam 三角色设计、配置即产品形态、运行时不变式约束等要点，具备向其他插件化系统迁移的参考价值。当前该项目仍处于早期开发预览阶段，未来生态能否形成稳定且高质量的插件集合，将决定这一设计范式从技术可行性走向实际可用性的最终成效。对于同类产品而言，DSH 提供了一个可对照的技术样本，其设计选择与代价权衡可供后续实践借鉴。
