# CLAUDE.md

本文件为 Claude Code 在此代码库中工作时提供指导。

## 项目概述

Code on Cloud (CoC) 是一个容器化的云端开发环境，提供基于Web的终端、tmux会话管理、xterm.js前端、SSO认证和Claude Code集成。

## 常用命令

### 构建和运行
```bash
# 构建基础镜像（首次使用或依赖变更时）
./build-base.sh

# 基于缓存基础镜像快速构建
./build.sh

# 完整重建（基础镜像 + 应用镜像）
./build-full.sh

# 使用本地认证启动（开发环境）
AUTH_PROVIDER=local ./start.sh

# 使用SSO认证启动（生产环境）
./start.sh  # 默认使用SSO
```

### 容器内开发
```bash
# 运行Python脚本
python3 script.py

# Node.js开发
npm install
npm run dev
npm test

# Claude Code命令
claude-code
claude-code-router

# tmux命令（Ctrl+A为前缀键）
Ctrl+A | # 垂直分割
Ctrl+A - # 水平分割
Ctrl+A c # 新建窗口
Ctrl+A n # 下一个窗口
```

## 系统架构

### 容器结构
- **分层Docker构建**优化：
  - `Dockerfile.base`: 稳定依赖（Node.js、Python、工具、tmux）
  - `Dockerfile.optimized`: 应用层
  - 基础镜像通过`versions.env`管理版本

### 认证系统（可插拔）
- **AuthProvider接口**: 所有认证实现的基类
- **AuthManager**: 加载和管理认证提供者
- **认证模式**:
  - `AUTH_PROVIDER=sso`: 企业SSO（OAuth2.0）- 生产环境
  - `AUTH_PROVIDER=local`: 本地开发模式 - 任意用户名密码
  - 可在`login/auth-providers/`中添加自定义提供者

### 认证流程
1. 用户访问Web终端 → Nginx检查认证状态
2. 未认证 → 重定向到登录页面
3. 通过选定提供者认证（SSO/本地/自定义）
4. 设置会话Cookie → 授权访问终端（xterm.js + tmux）

### 核心组件
- **登录服务器**（`login/server.js`）: 带可插拔认证的Express应用
- **认证提供者**（`login/auth-providers/`）: 模块化认证实现
- **Nginx**（`login/nginx.conf`）: 反向代理路由和认证强制
- **终端技术栈**:
  - **xterm.js**: 前端终端模拟器
  - **ttyd**: WebSocket终端服务器（7681端口）
  - **tmux**: 会话管理和持久化
- **会话管理**: 每个认证提供者可配置

## 配置管理

### 环境变量
- 认证模式: `AUTH_PROVIDER=sso|local`（默认: sso）
- SSO凭据: 在`login/.env`文件中设置（GFT_CLIENT_ID, GFT_CLIENT_SECRET）
- 版本管理: 在`versions.env`中管理（NODE_VERSION, CLAUDE_CODE_VERSION等）
- Claude Code Router: 在`config.json`中配置

### 重要文件
- `versions.env`: 统一版本配置文件
- `login/server.js`: 带认证钩子的主服务器
- `login/auth-provider.js`: 认证提供者接口
- `login/auth-manager.js`: 认证管理系统
- `login/auth-providers/`: 认证实现（SSO、本地等）
- `tmux.conf`: 开发用tmux配置
- `config.json`: Claude Code Router配置

## 版本管理

### 动态版本系统
- 所有版本信息统一在`versions.env`中管理
- Docker构建时自动读取版本参数
- 支持版本格式验证和错误提示
- 构建脚本自动传递版本参数

### 版本配置示例
```bash
# Docker镜像版本
VERSION=v1.0.0
IMAGE_NAME=cloud-code-dev

# NPM包版本
CLAUDE_CODE_VERSION=1.0.54
CLAUDE_ROUTER_VERSION=1.0.26

# Node.js版本
NODE_VERSION=20
```

## 测试和调试

### 认证调试
- 查看日志: `docker logs cloud-code-dev`
- 验证`.env`配置
- 测试SSO重定向URL配置

### 容器访问
- Web终端: http://localhost（认证后）
- 直接容器Shell: `docker exec -it cloud-code-dev /bin/bash`

### 版本一致性测试
```bash
# 运行版本一致性测试
./test-version-consistency.sh

# CI环境测试
./scripts/ci-version-test.sh
```

## 安全考虑
- 永远不要提交包含凭据的`.env`文件
- 会话Cookie为HTTP-only
- SSO令牌在服务端验证
- 日志中屏蔽敏感数据

## 开发技巧
- `/workspace`卷挂载保持代码变更
- 容器内预装所有开发工具
- 使用Python 3和pip进行包管理
- Claude Code在终端中全局可用
- tmux会话在容器重启后保持

## 文档结构
- `README.md`: 项目概述和快速开始
- `doc/PRD.md`: 产品需求文档
- `doc/design.md`: 系统设计文档
- `doc/认证系统指南.md`: 认证系统使用指南
- `doc/终端使用指南.md`: tmux和终端使用指南
- `doc/version-management-*.md`: 版本管理相关文档