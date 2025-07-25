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
- 创建一个用户登录页面，用户登录后才能进入TTYD, 请对接内部的SSO系统