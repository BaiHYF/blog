#import "/typ/templates/blog.typ": *

#show: main-zh.with(
  title: "Build an App to Make Yourself Happy — Andriod Lesson Note 02: Andriod UI Technique",
  desc: [中山大学腾讯客户端开发菁英班2024课程笔记 02],
  date: "2024-10-27",
  tags: (
    blog-tags.software,
  ),
  show-outline: true,
)

中山大学腾讯客户端开发菁英班2024课程笔记 02 

== 资源管理框架

	如何组织与管理安卓安装包的资源？

def. Resource
	Q: UI资源是指的什么?
	A: 资源（Resource）是从代码中分离，用于UI呈现和存储其他逻辑数据的静态内容。比如图片，字符串，界面布局等。
	
`assets` 目录：
	原始资源，任意格式组织方式
	
`res`目录：
	系统化资源，系统统一组织管理
	
> Aside: MVC模式MVC（Model-View-Controller）是一种常用的软件设计模式，特别适用于构建用户界面的应用程序。它将应用程序分为三个相互关联的部分：Model（模型）： 代表应用程序核心功能和数据。例如，一个待办事项应用中的任务列表。View（视图）： 负责信息的可视化展示。它从Model获取数据并呈现给用户。例如，显示任务列表的UI界面。Controller（控制器）： 接收用户输入并调用模型和视图去完成用户需求。它作为模型和视图之间的中介。例如，处理用户添加新任务的操作。 MVC模式解决了应用程序中业务逻辑、数据和界面显示的耦合问题，使得开发和维护更加清晰和简单。参考：#link("https://www.runoob.com/design-pattern/mvc-pattern.html")[MVC 模式 | 菜鸟教程]

== UI框架

	如何在运行时将资源渲染到屏幕上？

def. UI
	User Interface
	几乎是App的全部
def. 窗口
	每个App都挂载在一个窗口中
def. 控件
	UI最基础的单元
	- View
	- ViewGroup
界面(UI)是一颗抽象的 View Tree
	View 有明显的，层次的父子关系
=== UI消息循环机制

	UI渲染是单线程的

- 消息循环 Looper
	- 消息发送 (从消息队列去一个 View, 给到 Handler)
	- 消息处理 (Handler: View 的渲染)
=== 渲染过程
从“树”根开始 (DecorView), 三个步骤
+ Measure: 递归计算所有子View的“大小”，
+ Layout: 递归计算所有子View的“位置”
+ Draw: 递归地渲染所有的View
Skia 图形库
	安卓上的绘图API
动画实现
方式一： 定时器+分时渲染
方式二：安卓Animations库
	- 帧动画 Frame Animation
	- 补间动画 Tween Animation (比如通过矩阵变换实现动画)
	- 属性动画 Property Animator （比如 skeleton ）
== UI性能优化
def. 流畅
	≥ 60fps
	每隔16ms准备好一帧的画面
	
为了更高效的实现60fps, 我们需要
原则1：主线程不该干太多事
Solution:
+ 过度重绘检查 Overdraw
+ 减少Layout层级 （减少View Tree的层数）
+ 主线程不做耗时操作- 主线程尽量不做IO操作- 主线程一定不要做网络操作- 不要同时做过多UI布局计算
