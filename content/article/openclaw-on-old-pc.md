---
title: "在旧电脑上运行OpenClaw的过程记录与总结"
author: "baiheyufei"
description: "记录在旧电脑上从零部署 OpenClaw,实现无人值守长期运行与公网访问的过程与总结。"
date: 2026-08-07
tags: ["OpenClaw", "Cloudflare", "部署"]
---

## 一、动机

刚参加工作，一直听到各种关于使用AI的推广。此前在学校我并没有使用OpenClaw的需求，现在工作了，刚好手上有旧电脑，有域名，就尝试进行OpenClaw的部署，以后也许可能会有机会用到。

这次的目标为：

1. 成功部署OpenClaw
2. 实现无人值守长期运行
3. 实现对OpenClaw的公网访问

## 二、前置条件

这次在旧电脑部署OpenClaw用到的材料有：

- 一台能开机，能联网的联想台式机，软硬件条件大致为：

  | 项目 | 配置 |
  | --- | --- |
  | CPU | Intel i5-4460,4 核 3.2GHz |
  | 内存 | 6GB |
  | 硬盘 | 西数 1TB 7200 转机械盘(单盘) |
  | 系统 | Windows 10 21H2 |

  原生的操作系统为Window 8，出于我个人使用习惯重装了Windows 10系统。

- 一个国内备案认证过的域名，能正常在公网访问。域名是我以前在腾讯云上购买的(<https://buy.cloud.tencent.com/domain>)。最便宜的域名形如六位随机数字.xyz(如:123456.xyz),价格大概是80元10年，我看了下现在还可以以这个价格买到。

  ![腾讯云域名购买页面](/blog/blog-resources/openclaw-on-old-pc-domain.png)

- 顺畅的网络
- 个人手机，或者其他终端设备

## 三、部署过程记录

这个环节记录旧电脑从重装系统以后到成功完成部署的过程。

### 3.0 安装Terminal (Powershell)

Windows10系统默认的命令行cmd不好用，要安装更加现代的终端。

简单来说，在微软商店(Microsoft Store)中搜索Termial下载即可。或者直接在浏览器搜索引擎里搜，然后下载。最好不要用百度。

安装好之后最好设置默认使用管理员权限打开，方便一点。

个人认为这个环节做到这一步就可以。后续不需要其他配置。

### 3.1 安装WSL子系统

WSL全称为 Windows Subsystem Linux，可以非常简单粗浅的理解为微软官方提供的linux虚拟机，虽然内核并不和虚拟机完全一样。不像几年前BUG还非常多，2026年的WSL已经是一个非常完善的系统了，在不需要访问本机硬件驱动的情况下，基本可以完全当linux用。

为什么要在WSL上运行OpenClaw，而不是在Windows环境下直接运行？这一点在网上已经有很多分析了，这里不再赘述，反正是有一些好处。

安装的过程很简单，保证网络畅通，以管理员权限打开Terminal。然后输入`wsl --install` ，回车。这样就行了。等安装好之后如果需要重启电脑，终端里会有提示，按照要求重启即可。

```markdown
> wsl --install
```

也有一些其他方式，问AI或者网上搜都可以。

### 3.2 安装并部署OpenClaw

安装好WSL后，以管理员权限打开Terminal，运行指令`wsl` 即可进入wsl系统。

```bash
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

加载个人及系统配置文件用了 4553 毫秒。
❯ wsl
Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 6.6.87.1-microsoft-standard-WSL2 x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

This message is shown once a day. To disable it please create the
/home//.hushlogin file.
**$:**
```

更直观的说，看到终端里最后一行的最后一个字符从 **`>`**  变成 `$` ，就说明成功进入wsl了。

之后开始部署OpenClaw，之后照着OpenClaw的官方文档做：https://docs.openclaw.ai/install

保证网络顺畅，直接运行安装命令

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

之后如果网没问题，顺利的安装好，就会自动进入OpenClaw的安装引导程序，默认是英文，但好像可以设成中文，照着做就可以。这里不再赘述。

照着引导程序做，就可以算是完成OpenClaw的安装了。不过现在我只能在这台旧电脑上本地访问它，没法在其他设备中通过浏览器/QQ/微信等其他方式访问，接下来要解决这个问题。

### 3.3 将旧电脑的OpenClaw网关安全地暴露到公网

这个环节开始，很多事情都是我让OpenClaw自己做的了，不过其中有一些我认为值得记录的部分，所以进行一点记录。

这一节的目的简单来说就是要让旧电脑上的OpenClaw能被我的手机与个人电脑远程访问。

想要实现这个功能有很多的途径，结合我个人的情况以及家庭宽带的情况，我最终选择的方法是使用Cloudflare tunnel来进行路由。它大概的原理是这样的：

![Cloudflare Tunnel 原理示意](/blog/blog-resources/openclaw-on-old-pc-tunnel.png)

值得一提的是，普通"中间站/反代"是中间站主动发起连接(比如 nginx 反代:客户端连到 nginx,nginx 再连后端)，这需要我的机器有公网 IP 或端口，但是我没有。Cloudflare Tunnel 是我的机器主动发起连接,跟 Cloudflare 边缘保持一条长连接,边缘收到请求后从这条"已建立的通道"送进来，所以我的机器不用有公网IP。

第一步是安装cloudflared (可以让agent做)

```bash
$: echo "deb [signed-by=/etc/apt/keyrings/cloudflare-main.gpg] https://cloudflare.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
$: sudo apt-get update && sudo apt-get install cloudflared
```

然后需要在cloudflare中免费生成两个子域名，完成后在腾讯云中为自己的域名添加设置DNS，让该域名解析到cloudflare给的子域名。这一步需要在浏览器中人工进行操作，网上应该有教程，这里不再赘述。

这里在将DNS托管到Cloudflare后，Cloudflare会显示要等待最多24小时才生效，但实际上没有这么久，我这里十几分钟久可以了。

然后**一定要在旧电脑本地**通过WSL命令行登录cloudflare

```bash
$: cloudflared tunnel login
```

运行后会生成一个授权链接,浏览器打开 → 登录 Cloudflare 账号 → 勾选域名 → 授权。

这会在旧电脑上生成一个token。人不需要知道这个token是什么，放在哪里，只需要知道token生成了就行，一般看到网页上显示授权成功了都没问题。

拿到token后再进行隧道的创建与链接

```bash
$: cloudflared tunnel create openclaw   # 创建隧道,专给OpenClaw使用,返回一个隧道 ID
$: cloudflared tunnel route dns openclaw my.personal.domain   # 绑定子域名
```

隧道建好后,编辑配置文件 `~/.cloudflared/config.yml`,把域名转发到本机的 OpenClaw 网关(18789 端口):

```yaml
tunnel: <你的隧道ID>
credentials-file: /home/<用户名>/.cloudflared/<隧道ID>.json
protocol: http2        # 必须显示指定 http2

ingress:
  - hostname: my.personal.domain
    service: http://localhost:18789   
  - service: http_status:404         
```

隧道同样是一个程序，需要一直运行，我的做法是用 **`tmux`** 开一个会话,让隧道常驻:

```bash
tmux new-session -d -s cftunnel '~/.local/bin/cloudflared tunnel run openclaw'
```

### 3.4 无人值守

到了这一步，我希望我的旧电脑能一直运行，像一台服务器一样，不需要我随时去看他，插上电源和网线放在那里就行了。

首先是进程的托管，网上所有文章都是教读者使用 **`systemctl`**  托管后台进程，但不知道为什么我的旧电脑WSL一直用不了**`systemd` 。**各种AI都说：

> WSL 默认不启用 `systemd` 是因为微软想保持轻量和快速启动。在 2026 年的 WSL 版本中，只要在 `/etc/wsl.conf` 里加上 `[boot] systemd=true`，然后 `wsl --shutdown` 再重启，`systemctl` 就能用。

但是我照做了，没能成功。我怀疑是硬件太旧了，产生了BUG，反正最后还是没能解决这个问题。所以我最后是直接用了 **`tmux`** 进行托管，这么久下来也能用，没出什么问题。

最终这套服务跑在三个 tmux 会话里,

| **会话名** | **承载进程** | **作用** |
| --- | --- | --- |
| `openclaw` | OpenClaw 网关 | 提供 18789 端口服务 |
| `cftunnel` | cloudflared 隧道 | 维持与 Cloudflare 边缘的长连接 |
| `watchdog` | 看门狗脚本 | 每 60 秒检查,挂了自动拉起 |

之后就是要设置OpenClaw网关与隧道的开机自启。经过了一些尝试，能在我的旧电脑跑起来的方案大致是：

```bash
Windows开机自启动Terminal(Powershell)
↓
Terminal启动脚本中拉起WSL
↓
WSL启动脚本中拉起上文的三个session
```

旧电脑比较慢，这样实测开机之后5分钟左右，我的手机才能通过公网访问到OpenClaw。
