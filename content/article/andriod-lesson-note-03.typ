#import "/typ/templates/blog.typ": *

#show: main.with(
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
		
	
	
		!#link("https://prod-files-secure.s3.us-west-2.amazonaws.com/9f818825-dc97-4ead-98e8-502ed877201b/81236c87-3390-4bcf-9010-03a858a7e0a0/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB466SDZI7PKB%2F20260721%2Fus-west-2%2Fs3%2Faws4request&X-Amz-Date=20260721T122645Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEPX%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQCXiYO0hHDT0fBIEVvE72N3e8FJoLutpiwaHLcsnqVe4QIgfBlvxXy34KZx954%2FM4UX0vg1vyvuTEaEy%2FYVseBSbSEqiAQIvf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAAGgw2Mzc0MjMxODM4MDUiDAI15kOjDJAgm6WWHSrcA354iGPArSPRy7sAxUMoSkhLWiCRk77OBrClDTL5kOxdATRyIYAZdqj%2FR9827NfT%2FXcxeKx83WcmW0f9MpE8rtpTw7Zvk%2BsVm5eqtpHfyWdb5mh89wz86q1p%2FPHhA8z2uUSGZzKqKlcHAk3UdPKa98w9hm%2BIM4Mn1qua24S0lO6tAWSu6BC8YYf2h8pFR8mMojQpKKYwy936gbyn7zvRr%2F8ofXQdXPIUI9U1W%2FvybU3bC8gNbTClsCZ8Os0K9zcF1%2FO%2FbMubvDGmtiMAviz%2BYdSqLPGsFYhgiTQUTv06OkpZnqIZTys9jLkQf4ANUcawgzf7k0hjgB4BDepcC%2BE5AO40yWVjDkDqBKyGOcP1ib5KEF9UfLAZ8Dn0kk9joLIe%2BSnnoAkBNDLcVf3QWX8C8c51oxg0MINNUXUlCQ7GUCLaXSNyvl5hQC6YHfl1hKprlYFfZ%2BE0cd%2Bw3WYdHWj4nJOs%2Bs6nSlCOPly5uoRl56hC202cZwLuHEs9N16taGyWr5Gfnsu0KAkqOHFX9r8tLuI8ZRhr1Pzpm9T6kQvsVik2WxVZEQelTaEITF6cDMuCAb3o0JsRwy5eN%2F0x8rsu94Izo2VRi0mh%2BTVoUza%2Bam8VUojXtCdh6%2FSEK26OMJ3H%2FdIGOqUBAnZvscz%2FAYT3VblkyoYdvTDCycPpvE73oqnBunHD6LtuNTl3NreXCrUp6C6L%2B3ShpdAkpyRW15xNGWNNX%2FnBFMM%2BcyiRlG2pV5cCpfZBz0aa0JM60sqSB3QREB30RPS8VXkWxKoWAl3DRn5ZfN5VjhQy28szbiOJMEgtoaTkeoif%2B%2B9fO01gbVHlLc1%2BSJbSwEU2DSh%2Fj5TmzEwcotJCIARseBNb&X-Amz-Signature=07c68e88416c9a84b78ae4cc5d783c1387637ce63d4682566bd58ec564bd81c7&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject")[                                       TCP报文段结构，  图片来源：《计算机网络：自顶向下方法》第八版]
	


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
		
	
	
		!#link("https://prod-files-secure.s3.us-west-2.amazonaws.com/9f818825-dc97-4ead-98e8-502ed877201b/09823495-3876-46a7-935c-ea691611630c/image.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=ASIAZI2LB466SDZI7PKB%2F20260721%2Fus-west-2%2Fs3%2Faws4request&X-Amz-Date=20260721T122645Z&X-Amz-Expires=3600&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEPX%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCXVzLXdlc3QtMiJHMEUCIQCXiYO0hHDT0fBIEVvE72N3e8FJoLutpiwaHLcsnqVe4QIgfBlvxXy34KZx954%2FM4UX0vg1vyvuTEaEy%2FYVseBSbSEqiAQIvf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAAGgw2Mzc0MjMxODM4MDUiDAI15kOjDJAgm6WWHSrcA354iGPArSPRy7sAxUMoSkhLWiCRk77OBrClDTL5kOxdATRyIYAZdqj%2FR9827NfT%2FXcxeKx83WcmW0f9MpE8rtpTw7Zvk%2BsVm5eqtpHfyWdb5mh89wz86q1p%2FPHhA8z2uUSGZzKqKlcHAk3UdPKa98w9hm%2BIM4Mn1qua24S0lO6tAWSu6BC8YYf2h8pFR8mMojQpKKYwy936gbyn7zvRr%2F8ofXQdXPIUI9U1W%2FvybU3bC8gNbTClsCZ8Os0K9zcF1%2FO%2FbMubvDGmtiMAviz%2BYdSqLPGsFYhgiTQUTv06OkpZnqIZTys9jLkQf4ANUcawgzf7k0hjgB4BDepcC%2BE5AO40yWVjDkDqBKyGOcP1ib5KEF9UfLAZ8Dn0kk9joLIe%2BSnnoAkBNDLcVf3QWX8C8c51oxg0MINNUXUlCQ7GUCLaXSNyvl5hQC6YHfl1hKprlYFfZ%2BE0cd%2Bw3WYdHWj4nJOs%2Bs6nSlCOPly5uoRl56hC202cZwLuHEs9N16taGyWr5Gfnsu0KAkqOHFX9r8tLuI8ZRhr1Pzpm9T6kQvsVik2WxVZEQelTaEITF6cDMuCAb3o0JsRwy5eN%2F0x8rsu94Izo2VRi0mh%2BTVoUza%2Bam8VUojXtCdh6%2FSEK26OMJ3H%2FdIGOqUBAnZvscz%2FAYT3VblkyoYdvTDCycPpvE73oqnBunHD6LtuNTl3NreXCrUp6C6L%2B3ShpdAkpyRW15xNGWNNX%2FnBFMM%2BcyiRlG2pV5cCpfZBz0aa0JM60sqSB3QREB30RPS8VXkWxKoWAl3DRn5ZfN5VjhQy28szbiOJMEgtoaTkeoif%2B%2B9fO01gbVHlLc1%2BSJbSwEU2DSh%2Fj5TmzEwcotJCIARseBNb&X-Amz-Signature=50b38949afda5530b0780989eb4bc85573835f08543e79bc92b5bd3c996c3298&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject")[                         一个图书管理系统的时序图]
	

协议设计参考文档 #link("https://datatracker.ietf.org/doc/html/rfc3117")[RFC 3117: On the Design of Application Protocols]

#line()
    
   Baihyf
