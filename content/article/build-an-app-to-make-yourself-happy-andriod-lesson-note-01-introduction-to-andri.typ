#import "/typ/templates/blog.typ": *

#show: main.with(
  title: "Build an App to Make Yourself Happy — Andriod Lesson Note 01: Introduction to Andriod",
  desc: [中山大学腾讯客户端开发菁英班2024课程笔记 01],
  date: "2024-10-27",
  tags: (
    blog-tags.software,
  ),
  show-outline: true,
)

中山大学腾讯客户端开发菁英班2024课程笔记 01 
== 安卓应用基础架构
核心模块
- 交互界面
- 网络协议
- 数据存储
扩展模块
- 终端安全
- 性能优化
- 多媒体
- 其他前沿技术…

== 课程环境
IDE: Andriod Studio
Teamwork: github

== 安卓操作系统介绍
=== AndriodOS的分层
```plain text
+----------------------------+
|           应用层           |
+----------------------------+
|        应用程序框架        |
+------------+---------------+
| 系统底层库 | Andriod虚拟机 |
+------------+---------------+
|         Linux内核层        |
+----------------------------+
```

=== 安卓应用静态结构
APK — Andriod Application PacKage, 安卓应用的封装形式。
	与 `.jar` 文件一样，`.apk` 本质上是在 `.zip` 的基础上增加了签名信息（`META-INF`）。
dex — 安卓可执行代码文件 `class[N].dex` ，类似windows下的 `.exe` 。
res 目录 — resources 资源目录 

== 安卓应用动态结构
安卓系统上软件以APK为载体，程序生命周期重新通过四大组件进行封装。
	- Activity
	- Service
	- BroadcastReceiver
	- ContentProvider
这一环节大概就是要了解到，Andriod上的程序与linux上不太一样，比如没有main函数，取而代之的是所谓的四大组件。

== 安卓应用简单设计
这里以 微信1.0 为例，我们简单地看一下一个聊天应用的架构
```mermaid
graph LR
  MyIM --> 登陆模块 --> 1[LoginActivity RegisterActivity <br>...]
  MyIM --> 主界面 --> 2[MainActivity ChatListActivity ContactsActivity <br>...]
  MyIM --> 聊天功能 --> 3[ChattingActivity EmojiPanelView <br>...]
  MyIM --> 消息推送 --> 4[PushService <br> MessageService <br>...]
```

可以注意到每个功能模块分成几个功能，每个功能通过 Activity, Service 等组件之一实现(至少图里是这样)。
```plain text
╔════════════════════════╦════════════╗
║ UI Layer               ║ With State ║
╠════════════════════════╣            ║
║ Logic Control          ║            ║
╠════════════════════════╩════════════╣
║ --------------------------------    ║
╠══════════════╦═════════╦════════════╣
║ Data Storage ║ Network ║ Stateless  ║
╠══════════════╩═════════╣            ║
║ Utils                  ║            ║
╚════════════════════════╩════════════╝
```
