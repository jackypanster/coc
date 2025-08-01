# Code on Cloud - 云端开发环境

## 项目概述

Code on Cloud 是一个基于容器的云端开发环境，提供完整的开发工具链和Web终端访问。

## 核心功能

- **容器化开发环境**: 基于 Debian 的完整开发环境，包含 Node.js、Python、Git 等工具
- **Web终端访问**: 通过 ttyd 提供浏览器内终端访问
- **认证系统**: 支持 SSO 和本地开发模式
- **动态版本管理**: 统一的版本配置管理系统

## 快速开始

### 1. 配置环境

复制并配置认证文件：
```bash
cp login/.env.example login/.env
# 编辑 login/.env 配置认证参数
```

### 2. 构建镜像

```bash
# 完整构建（首次使用）
./build-full.sh

# 快速构建（基础镜像已存在）
./build.sh
```

### 3. 启动服务

```bash
./start.sh
```

访问 http://localhost 即可使用。

## 版本管理

所有版本信息统一在 `versions.env` 文件中管理：

```bash
# Docker 镜像版本
VERSION=v1.0.0
IMAGE_NAME=cloud-code-dev

# NPM 包版本
CLAUDE_CODE_VERSION=1.0.54
CLAUDE_ROUTER_VERSION=1.0.26

# Node.js 版本
NODE_VERSION=20
```

## 项目结构

```
├── versions.env              # 版本配置文件
├── build-base.sh            # 基础镜像构建脚本
├── build.sh                 # 快速构建脚本
├── build-full.sh            # 完整构建脚本
├── start.sh                 # 启动脚本
├── Dockerfile.base          # 基础镜像 Dockerfile
├── Dockerfile.optimized     # 优化构建 Dockerfile
├── container-start.sh       # 容器启动脚本
├── login/                   # 认证服务
│   ├── server.js           # 登录服务器
│   ├── auth-manager.js     # 认证管理器
│   └── .env.example        # 环境变量模板
└── doc/                     # 文档目录
```

## 认证配置

### SSO 模式（生产环境）

在 `login/.env` 中配置：
```bash
AUTH_PROVIDER=sso
GFT_CLIENT_ID=your_client_id
GFT_CLIENT_SECRET=your_client_secret
GFT_OAUTH_URL=https://your-sso-server/oauth/authorize
```

### 本地模式（开发环境）

```bash
AUTH_PROVIDER=local
```

## 开发指南

### 构建脚本说明

- `build-base.sh`: 构建包含所有依赖的基础镜像，通常只需运行一次
- `build.sh`: 基于基础镜像快速构建业务镜像
- `build-full.sh`: 完整构建流程，包含基础镜像和业务镜像

### 版本更新

1. 修改 `versions.env` 中的版本号
2. 运行相应的构建脚本
3. 重新启动服务

### 故障排除

常见问题和解决方案请参考：
- [版本管理故障排除](doc/version-management-troubleshooting.md)
- [版本管理最佳实践](doc/version-management-best-practices.md)

## 技术架构

- **基础系统**: Debian Bookworm
- **Web服务**: Nginx 反向代理
- **终端服务**: ttyd + tmux
- **认证服务**: Node.js Express
- **开发工具**: Node.js 20, Python 3, Git, 编译工具链

## 许可证

本项目采用 MIT 许可证。