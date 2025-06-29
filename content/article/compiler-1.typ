#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Compiler CheetSheet I",
  desc: [编译原理课程考试前的一些总结. Ch9],
  date: "2025-06-15",
  tags: (
    blog-tags.exam,
    blog-tags.compiler,
  ),
  show-outline: true,
)

= Chapter09代码优化

== 题型1-局部优化-为基本块构造DAG并根据DAG优化基本块

+ 求基本块的入口语句，它们是：
  - 程序的一个语句；
  - 条件转移或无条件转移语句的转移目标语句；
  - 紧跟在条件转移语句后面的语句。

+ 对每一入口语句，构造其所属的基本块：
  - 它是由该入口语句到下一入口语句(不包括下一入口语句);
  - 或到一转移语句(包括该转移语句);
  - 或到一停止语句(包括该停止语句)之间的语句序列组成的。

#figure(
  image("../../public/blog-resources/image-13.png"),
  caption: [例题],
)

== 题型2-循环优化-在流图中确定循环
根据流图计算所有结点的支配结点集[Dominators]，然后得到流图中的回边[Back Edges]，根据回边就可以确定该流图中的循环。
+ 计算支配结点集[Dominators]
  - 对任意两个结点 `m` 和 `n`，若从流图首结点出发，到达 `n` 的任一通路都要经过 `m`，则称 `m` 是 `n` 的支配结点，记为：`m DOM n`
  - 流图中结点 `n` 的所有支配结点的集合称为结点 `n` 的支配结点集，记为
  `D(n) = {m | m DOM n}`
  - 设 `n0` 为流图中的首结点，则对流图中任意结点 `a`，必有：
    - 自反性：`a DOM a`
    - 首结点支配性：`n0 DOM a`
+ 得到回边[Back Edges]
  - 假设`a->b`是流图中的一条有向边，如果`b DOM a`，则称其是流图中的一条回边
+ 确定循环[Loop]
  - 如果`a->b`是回边，则结点`a`，结点`b`，以及 到达`a`且不需要经过`b`的所有结点成循环，且`b`是该循环的唯一入口

#figure(
  image("../../public/blog-resources/image-14.png"),
  caption: [例题],
)

== 题型3-全局优化-到达/定值数据流分析
到达-定值数据流分析[Reaching Definition Analysis]
- 向前流：信息流的方向与控制流是一致的
- 变量A的定值[definition]是对A的赋值或读值到A的语句，该语句的位置称作A的定值点
- 变量A的定值点`d`到达[reaching]某点`p`，是指流图中从`d`有一条路径到达`p`且该通路上没有A的其它定值

 即当我们在p之后立即使用变量A时，A的值可能由d决定

分析过程，从入口基本块开始，依次对每个基本块B进行计算
+ `OUT[B] = GEN[B] ∪ (IN[B]-KILL[B])`
  - 人话：OUT[B]为所有该基本块B入口处的定值点集合IN[B]去除当前基本块“杀死”的定值点，再加入当前基本块新产生的定值点(构成的集合)
+ `IN[B] = ∪(OUT[b] | b in pred(B))`
  - 人话：IN[B]为所有B的直接前驱基本块b的OUT[b]的并集
循环直到收敛

注解:
- B:基本块,pred(B):B的所有前驱基本块
- IN[B]: 到达B入口处的各个变量的所有定值点集合
- OUT[B]: 离开B出口处的各个变量的所有定值点集合
- GEN[B]: B中新产生的各个变量的所有定值点集合(B中定值并可到达B出口处的所有定值点集合)
- KILL[B]: B中“杀死”的各个变量的所有定值点集合(B之外的能够到达B的入口处、且其定值的变量在B中又重新定值,即被B所“杀死”,的定值点集合)

计算UD链:变量A在引用语句u的定值链
- 设在程序中某点u引用了变量A的值，则把能到达u的A的所有定值点的全体，称为A在引用点u的引用-定值链，简称UD链。

#figure(
  image("../../public/blog-resources/image-15.png"),
  caption: [
    例题
    + 对该流图进行到达-定值数据流分析,假设B1的IN信息为∅,请将迭代结束时的结果填充在下表中
    + 指出该流图范围内,变量`a`在(11)的UD链
  ],
)

Answer: 正体为第一次循环得到,_斜体为第二次循环得到_

#table(
  columns: (auto, auto, auto, auto, auto),
  table.header("Basic Block", "GEN", "KILL", "IN", "OUT"),
  [B1], [1], [∅], [∅], [1],
  [B2], [2], [9], [1,4,_5,7,8,9_], [1,2,_4,5,7,8_],
  [B3], [4], [1,14], [1,2,_4,5,7,8_], [2,4,_5,7,8_],
  [B4], [5,7,8,9], [2,13,11], [1,2,4,_5,7,8,11,13,14_], [1,4,5,7,8,9,_14_],
  [B5], [11], [7], [1,4,5,7,8,9,11,_14_], [1,4,5,8,9,11,_14_],
  [B6], [13,14], [1,4,8], [1,4,5,8,9,11,_14_], [5,9,11,13,14],
  [B7], [∅], [∅], [5,9,11,13,14], [5,9,11,13,14],
)

`a`在(11)的UD链:{1,4,14}

== 题型4-全局优化-活跃变量数据流分析
活跃变量数据流分析[Live Variable Analysis]
- 向后流：信息流的方向与控制流反向
- 活跃变量
  + 对程序中的某变量A和某点`p`而言，如果存在一条从`p`开始的通路，其中引用了A在点`p`的值，则称A在点`p`是活跃的
  + 直观地，对于全局范围的分析来说，一个变量是活跃的，如果存在一条路径使得该变量被重新定值之前它的当前值还要被引用

 之后会被用到的某个定义

分析过程，从入口基本块开始，依次对每个基本块B进行计算
+ `Liveln(B)= LiveUse(B) ∪ (LiveOut(B)-Def(B))`
  - 人话：变量在B中定值前有引用，或者在B出口处活跃且未在B中被定值，则它在B入口处是活跃的
+ `LiveOut(B)=∪ Liveln(s) | s in S[B]`
  - 人话：IN[B]为所有B的直接前驱基本块b的OUT[b]的并集
循环直到收敛

注解:
- B:基本块,S(B):B的所有直接后继基本块
- LiveUse[B]: B中被定值之前要被引用的变量的集合
- LiveOut[B]: B的出口处活跃的变量的集合
- LiveIn[B]: B的入口处活跃的变量的集合
- Def[B]: 在B中定值的且定值前未曾在B中被引用过的变量集合

此处`引用`==`使用`,对应的英文都为`use`

计算DU链:[Definition-Use Chaining,定值-引用链]：变量A在定值语句u的使用链
- 假设在程序中某点`u`定义了变量A的值，从`u`存在一条到达A的某个引用点`s`的路径，且该路径上不存在A的其他定值点，则把所有此类引用点`s`的全体称为A在定值点`u`的定值—引用链，简称DU链。
- 即变量A在`u`被定义了，之后会在其他哪些地方被使用。

#figure(
  image("../../public/blog-resources/image-15.png"),
  caption: [
    例题
    + 对该流图进行活跃变量数据流分析，假设B7的LiveOut信息为∅，请将迭代结束时的结果填充在下表中
    + 指出该流图范围内,变量`a`在(11)的UD链
  ],
)

Answer: 正体为第一次循环得到,_斜体为第二次循环得到_

#table(
  columns: (auto, auto, auto, auto, auto),
  table.header("Basic Block", "DEF", "LiveUse", "LiveOut", "LiveIn"),
  [B1], [a], [∅], [ae], [∅],
  [B2], [c], [a], [ae], [ae],
  [B3], [a], [e], [a], [e],
  [B4], [bcde], [a], [acde], [a],
  [B5], [∅], [ad], [acd], [acd],
  [B6], [e], [ac], [e], [ac],
  [B7], [∅], [∅], [∅], [∅],
)

`c`在(2)的DU链:{3}
