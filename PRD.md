# Code on Cloud 需求文档

## 概述
请提供一个 Dockerfile，基于 `debian:bookworm` 创建一个镜像。

## 安装要求

### 1. 核心组件安装
- **Claude Code**: `npm install -g @anthropic-ai/claude-code`
  - 官网: https://github.com/anthropics/claude-code
- **Claude Code Router**: `npm install -g @musistudio/claude-code-router`
  - 官网: https://github.com/musistudio/claude-code-router/tree/main
- **TTYD**: https://github.com/tsl0922/ttyd

### 2. 脚本提供
- 一键编译脚本
- 一键启动脚本

## 容器运行配置

### 3. 目录挂载
- 用户在自己的工作目录启动容器
- 将当前 `pwd` 挂载到容器的 `/app` 目录

### 4. 服务启动
- **TTYD**: 端口 `7681`，host `0.0.0.0`

### 5. 访问方式
- 用户访问 `http://localhost:7681` 即可访问 TTYD
- 容器只暴露 TTYD 端口

## 配置文件处理

### 6. 环境配置
- 将当前目录的 `config` 拷贝到镜像中的 `~/.claude-code-router/config.json`

### 7. 登录页面
- 创建一个用户登录页面，用户登录后才能进入TTYD, 请对接企业内部的SSO系统


```

PC端浏览器应用对接
大体步骤：
页前端
A） 应用登录页通过iframe方式嵌入登录认证框
（以下2.2）
B） 登录认证框对用户进行认证 ，认证通过企业SSO前端通过PostMessage返回认证码（redirect_uri 中包含认证码 ) 给应用登录
（以下 2.2 eventer部分)
C） 应用前端提交认证码给后端，后端请求企业SSO获取AccessToken完成登录过程
其中 登录认证框已实现功能：
进行相应配置。
（以下2.3）
OA帐号密码认证/扫码登录认证/用户类型（正式员工，合作方员工，群组，特殊账号列表）限制，有需要请咨询企业SSO开发团队
2.1. 申请内部统一认证系统的应用ID
向企业SSO开发团队申请 应用ID，应用名，重定向URL（需要应用方实现的接口）
2.2. 前端对接(例子中应用ID为 test,
/callback)：
重定向URL为 http://local.example.com/login


登录页嵌入
//, IFrame
function OpenLoginFrame() {
var eventMethod = window.addEventListener ? "addEventListener" : "attachEvent";
var eventer = window[eventMethod];
var messageEvent = eventMethod === "attachEvent" ? "onmessage" : "message";
eventer(messageEvent,function(e) {
if (e.data && e.data.url && e.data.url.indexOf("code=") > 1) { // FIXME: eredirect_uri
var redirect_url = e.data.url;
//TODO , redirect_uri http://local.example.com/login/callback?code=12345678-1234-1234-1234-
123456781234?state=AnyStateString
//TODO Angularredirect_uri
//TODO if http.get(redirect_url).ok() { //goto ; }
//TODO: redirect_uriredirect_uri
//TODO: window.location = redirect_url;
}
},false);
var loginFrame = document.createElement("iframe");
//oauth2.example.com
//testoauth2.example.com
//https https://testoauth2.example.com
//http http://testoauth2.example.com
loginFrame.setAttribute("src", "//testoauth2.example.com/login?
theme=mini&login_type=oa&client_id=test&redirect_uri=http://local.example.com/login/callback?
state=AnyStateString");
loginFrame.style.width = "604px";
loginFrame.style.height = "400px";
loginFrame.style.position = "absolute";
loginFrame.style.top = "60px";
loginFrame.style.right = "60px";
loginFrame.style.frameBorder = "0";
loginFrame.style.border = "solid 0px";
loginFrame.style.scrolling = "no";
document.body.appendChild(loginFrame);
}
以上为嵌入ifame方式，嵌入登录框至应用登录页面实现。
```