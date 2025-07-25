# SSO集成指南

## 概述

Code on Cloud现已集成内部SSO系统，支持用户使用账号或扫码方式安全登录。

## 功能特性

### 🔐 认证系统
- **SSO集成** - 标准OAuth2.0认证流程
- **多种登录方式** - 账号密码 / 扫码登录
- **用户类型支持** - 正式用户、合作方用户、群组、特殊账号
- **会话管理** - 5分钟绝对超时，2分钟不活跃超时

### 🎨 用户界面
- **像素艺术风格** - 保持原有的复古游戏风格
- **响应式设计** - iframe弹窗居中显示
- **开发模式切换** - 支持本地登录fallback（开发环境）
- **实时状态提示** - 登录过程状态反馈

### 🏗️ 技术架构
- **前端集成** - 简洁的登录界面和交互体验
- **前端iframe集成** - 嵌入SSO登录框
- **PostMessage通信** - 安全的跨域认证码传递
- **后端OAuth2流程** - 认证码换取访问令牌
- **用户信息获取** - 自动获取用户基本信息

## 部署配置

### 1. 申请SSO应用凭据

联系SSO开发团队申请：
- **应用ID** (client_id)
- **应用密钥** (client_secret)  
- **重定向URL** (redirect_uri)

### 2. 环境变量配置

复制 `.env.example` 为 `.env` 并配置：

```bash
# SSO应用凭据
GFT_CLIENT_ID=your-app-id
GFT_CLIENT_SECRET=your-app-secret
GFT_REDIRECT_URI=https://your-domain.com/login/callback

# 生产环境
NODE_ENV=production
ENABLE_LOCAL_FALLBACK=false
```

### 3. Docker部署

SSO功能已集成到现有Docker镜像中：

```bash
# 构建镜像
./build.sh

# 启动容器（确保环境变量已设置）
./start.sh
```

## 认证流程

### OAuth2标准流程

1. **用户访问** → 重定向到登录页面
2. **点击登录** → 打开SSO iframe
3. **完成认证** → SSO返回认证码
4. **后端验证** → 用认证码换取访问令牌
5. **获取用户信息** → 使用令牌获取用户信息
6. **建立会话** → 创建本地会话，跳转到ttyd

### 技术实现细节

```javascript
// 前端：iframe嵌入和PostMessage监听
function openGFTLogin() {
    // 创建iframe，监听认证码返回
    // 提交认证码到后端 /login/sso
}

// 后端：OAuth2认证流程
app.post('/login/sso', async (req, res) => {
    // 1. 用认证码换取访问令牌
    // 2. 用访问令牌获取用户信息
    // 3. 创建本地会话
});
```

## 安全特性

### 会话管理
- **双重过期机制** - 绝对超时 + 不活跃超时
- **自动清理** - 定期清理过期会话
- **安全Cookie** - HttpOnly, SameSite=strict

### 用户信息保护
- **最小权限原则** - 只获取必要的用户信息
- **令牌安全存储** - 访问令牌仅在服务端保存
- **会话隔离** - 每个用户独立会话空间

## 开发模式

开发环境支持本地登录fallback：

```javascript
// 切换到本地登录模式
ENABLE_LOCAL_FALLBACK=true
```

用户可以在登录页面点击"开发模式：本地登录"切换。

## 监控和日志

系统会记录关键认证事件：
- SSO认证成功/失败
- 会话创建和过期
- 用户登录和登出

## 故障排除

### 常见问题

1. **认证码获取失败**
   - 检查client_id是否正确
   - 确认redirect_uri与申请时一致

2. **令牌交换失败**
   - 验证client_secret配置
   - 检查网络连接到SSO服务器

3. **用户信息获取失败**
   - 确认访问令牌有效性
   - 检查用户权限设置

### 调试模式

开启详细日志：
```bash
NODE_ENV=development
```

查看浏览器控制台和服务器日志获取详细错误信息。

## 升级说明

从简单登录升级到SSO：
- ✅ 保持现有像素艺术UI风格
- ✅ 向下兼容本地登录（开发模式）
- ✅ 无需修改ttyd配置
- ✅ 会话管理机制保持不变
