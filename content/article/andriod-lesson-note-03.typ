#import "/typ/templates/blog.typ": *

#show: main-zh.with(
  title: "终端网络技术 — 网络协议 Andriod Lesson Note 03",
  desc: [*中山大学腾讯客户端开发菁英班2024课程随笔 03*],
  date: "2024-11-09",
  tags: (
    blog-tags.software,
    blog-tags.network,
  ),
  show-outline: true,
)

中山大学腾讯客户端开发菁英班2024课程随笔 03
	

== Overview: Protocol 网络协议
网络协议是一套规则和约定，用于在计算机网络中进行通信和数据交换。它定义了数据如何被格式化、发送、接收和解释。
从设计一个网络协议来讲，我们可以认为其由语法（syntax），语义（semantics），时序（timing）三个部分组成。

	
		我们以TCP为例，语法：TCP采用了一种约定格式的语法，比如其规定了报文段的结构，每一项的长度。
		语义：约定的报文段中每一项代表的含义时序： 通过三次握手的过程，两个实体才能建立起一个TCP连接，这就是我们所说的时序。
		
	
	
		!#link("https://prod-files-secure.s3.us-west-2.amazonaws.com/9f818825-dc97-4ead-98e8-502ed877201b/81236c87-3390-4bcf-9010-03a858a7e0a0/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB466YU7S7RL4%2F20260723%2Fus-west-2%2Fs3%2Faws4request&X-Amz-Date=20260723T120035Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjECQaCXVzLXdlc3QtMiJIMEYCIQCXxMMjln6JzkkxNE7FjvlHIQGoCu99LxRMDxPeQRyFYAIhAIgXTb%2FSaQfd27wcjW%2FDFDbu7%2B5hnXu4TFFKXF3BU5BcKogECO3%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEQABoMNjM3NDIzMTgzODA1Igw90MsbxInpNngzydYq3AME4PQPqOPRF9Ct47MzPRnBWL3l4H6Aoy%2FDcRBVSBuZkYhZBCweTt0suj2fcvNZNQVsCgIMsiUrBpqrjngjq%2FAiWBzG%2FKpyejPStU6OTqb853yXWmILkJCCogwQkUWDmNhezR9M8D0zL7uuIjUuvJRh3yNJQczwP%2FUZyuqbidhDaEFfFwis9sOv6oRriFYM9t9RCQtCcH7mXQvNVjSXkLHEvqDxxLY3fQoNrQ1HMu2UhDxlWVs0MaPF9DIQKFyyLd%2FfOgSrT38yDPD9LQK%2FODfCqyDPYXNzwViEzjLT3mlMQQIOIyLH4duajIn0gstGMJz393VWX2fY3xT9uQEuljUnetPQAyyqW8fb97G1mX59Cg%2BarAwSNaWMeLI5cUEH%2FmudnrCoeA6at9Pxy1paLuM3pzBDw6YleiJO2bK0g6Qc9wUua6Jqa%2BmFimRE4AJdV9S2fA6Y0bnkEGiL6wvG0UZ62L3IzHzN373Y1PYxFrsTiue3XlNNua3aL59LX6yizxKxW8mcc6fbl3VG%2F1AdwRfj%2F4hAiMET67syL%2BHn5ELvNyKF3GwM6TrON1%2BnvlxhAhE4Rndu40WLIVZK%2BU5JzaOteEyAs1xOi3yg8iTsTnIwHdfks6vxZMo79ETRwjDW%2BofTBjqkAfW2s7rtXEheXsPvDmajtxIYy%2BunSqsvOwRtFi74wHcsQ1W6UH26qVFxK62xxxVGA2tMk5hyxCR2Ti9rUsKp2bab3c22WiOOX0cnSqRoNb9np21yzNAc1f3QKbI%2BE7atpbgbC0f8blqXqbUGsDuFoevJ%2FBipJ%2FybhIXtmNyjWXDPzjE0C5%2Flm66FT9VDeCySd%2Fp1E6udnDtkOEchJNaCDq1sZ2eB&X-Amz-Signature=5f68edd45082080ded42db3b11d67025aeed5405be07a8533abae88c6b49e10d&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject")[                                       TCP报文段结构，  图片来源：《计算机网络：自顶向下方法》第八版]
	


== Syntax 语法
这一部分关注的是数据的编码。
比如Alice在微信上发一条消息给Bob,那么对于这条消息，我们需要至少处理包含发送者，接收者，发送内容，发送时间等内容——语法考虑的就是怎样组织，编码这些内容。
接下来介绍几种常见的语法。
文本编码——符号分隔将每一项用一个符号分隔开，比如逗号。(Alice, Bob, Ciallo, 2024.11.9;15:10)
文本编码——Key-value每一项用一个键值对表示(比如HTTP) Sender:Alice[CRLF] Receiver:Bob[CRLF] Content: Ciallo[CRLF] SendTime: 2024.11.9;15:10[CRLF]
文本编码——XML相较于单纯的Key-value模式，XML层次更清晰 ，也能进行类型安全检查。
```xml
<SendMsg>
	<Sender value="Alice"/>
	<Receiver value="Bob"/>
	<Content value="Ciallo"/>
	<SendTime value="2024.11.9 15:10"/>
</SendMsg>
```
二进制编码—Google ProtoBuf二进制编码相较于文本编码最显著的优点就是能进行压缩，节省空间。
```protobuf
message SendMsg {
	required string sender = 1;
	required string receiver = 2;
	optional string content = 3;
	optional string sendtime = 4;
}
```

== Semantics 语义
语义关注的是协议的内容，将某个事物描述清楚。我们需要做到协议语义的可拓展性，兼容性，错误处理，简洁性等。


== Timing 时序
时序关注的是协议中各个事件发生的顺序和时间。一个良好的时序设计可以提高通信效率，减少延迟，并确保数据的可靠传输。时序设计与每个具体的协议相关，这里主要介绍一下时序设计中常用的工具。


	
		时序图时序图，又称顺序图或序列图，它是描述对象行为的一种交互视图，主要用来更直观的表现多个对象交互的时间顺序，将体现的重点放在 以时间为参照，各个对象发送、接收消息，处理消息，返回消息的时间流程顺序。
		
		状态图状态图是状态机的一种表现形式，利用状态机可以精确地描述对象的行为。状态机用于对模型元素的动态行为进行建模，或是说对系统中受事件驱动的方面进行建模。
		从对象的初始状态起，开始响应事件并执行某些动作，这些事件引起状态的转换；对象在新状态下又开始响应事件和执行动作，如此连续进行直到终结状态。
		
	
	
		!#link("https://prod-files-secure.s3.us-west-2.amazonaws.com/9f818825-dc97-4ead-98e8-502ed877201b/09823495-3876-46a7-935c-ea691611630c/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB466YU7S7RL4%2F20260723%2Fus-west-2%2Fs3%2Faws4request&X-Amz-Date=20260723T120035Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjECQaCXVzLXdlc3QtMiJIMEYCIQCXxMMjln6JzkkxNE7FjvlHIQGoCu99LxRMDxPeQRyFYAIhAIgXTb%2FSaQfd27wcjW%2FDFDbu7%2B5hnXu4TFFKXF3BU5BcKogECO3%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEQABoMNjM3NDIzMTgzODA1Igw90MsbxInpNngzydYq3AME4PQPqOPRF9Ct47MzPRnBWL3l4H6Aoy%2FDcRBVSBuZkYhZBCweTt0suj2fcvNZNQVsCgIMsiUrBpqrjngjq%2FAiWBzG%2FKpyejPStU6OTqb853yXWmILkJCCogwQkUWDmNhezR9M8D0zL7uuIjUuvJRh3yNJQczwP%2FUZyuqbidhDaEFfFwis9sOv6oRriFYM9t9RCQtCcH7mXQvNVjSXkLHEvqDxxLY3fQoNrQ1HMu2UhDxlWVs0MaPF9DIQKFyyLd%2FfOgSrT38yDPD9LQK%2FODfCqyDPYXNzwViEzjLT3mlMQQIOIyLH4duajIn0gstGMJz393VWX2fY3xT9uQEuljUnetPQAyyqW8fb97G1mX59Cg%2BarAwSNaWMeLI5cUEH%2FmudnrCoeA6at9Pxy1paLuM3pzBDw6YleiJO2bK0g6Qc9wUua6Jqa%2BmFimRE4AJdV9S2fA6Y0bnkEGiL6wvG0UZ62L3IzHzN373Y1PYxFrsTiue3XlNNua3aL59LX6yizxKxW8mcc6fbl3VG%2F1AdwRfj%2F4hAiMET67syL%2BHn5ELvNyKF3GwM6TrON1%2BnvlxhAhE4Rndu40WLIVZK%2BU5JzaOteEyAs1xOi3yg8iTsTnIwHdfks6vxZMo79ETRwjDW%2BofTBjqkAfW2s7rtXEheXsPvDmajtxIYy%2BunSqsvOwRtFi74wHcsQ1W6UH26qVFxK62xxxVGA2tMk5hyxCR2Ti9rUsKp2bab3c22WiOOX0cnSqRoNb9np21yzNAc1f3QKbI%2BE7atpbgbC0f8blqXqbUGsDuFoevJ%2FBipJ%2FybhIXtmNyjWXDPzjE0C5%2Flm66FT9VDeCySd%2Fp1E6udnDtkOEchJNaCDq1sZ2eB&X-Amz-Signature=3bc3ac3e7af897771fbb074354de020ed85af689bd53aaf02f60fed366fa4c92&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject")[                         一个图书管理系统的时序图]
	

协议设计参考文档 #link("https://datatracker.ietf.org/doc/html/rfc3117")[RFC 3117: On the Design of Application Protocols]

#line()
    
   Baihyf
