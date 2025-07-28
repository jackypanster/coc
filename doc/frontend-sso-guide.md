# SSO解耦架构 - 前端团队对接指南

## 🏗️ 解耦架构说明

### 设计理念
Code on Cloud 采用**插件化认证架构**，实现前后端职责分离：
- **后端团队**：专注核心业务逻辑和认证框架维护
- **前端团队**：独立开发认证UI和用户交互逻辑
- **配置驱动**：通过配置文件控制认证方式，无需修改代码

### 架构组件
```
用户访问 → Nginx → Express Server → AuthManager → AuthProvider → 认证成功 → ttyd终端
                                          ↓
                                   SSO/Local/Custom
                                   (独立认证模块)
```

## 🎯 前端团队职责边界

### ✅ 前端负责
- **登录页面UI设计** (`login/auth-providers/*/login.html`)
- **用户交互逻辑** (表单验证、错误提示、加载状态)
- **前端认证流程** (SSO iframe、本地表单提交等)
- **样式和用户体验** (CSS、动画、响应式设计)

### ❌ 后端负责  
- **认证核心逻辑** (`login/auth-providers/*/index.js`)
- **会话管理** (Cookie设置、过期处理、安全策略)
- **API接口** (认证验证、配置获取、用户信息)
- **系统集成** (与SSO服务器通信、数据库操作)

## 🚀 快速上手流程

### 1. 环境准备
```bash
# 切换到本地开发模式
# 编辑 login/.env 文件
AUTH_PROVIDER=local

# 启动容器
./start.sh

# 浏览器访问
http://localhost
```

### 2. 前端开发目录
```
login/auth-providers/
├── sso/
│   ├── index.js         ❌ 后端负责 - 不要修改
│   └── login.html       ✅ 前端负责 - 可以修改
├── local/
│   ├── index.js         ❌ 后端负责
│   └── login.html       ✅ 前端负责 - 可以修改
└── your-custom/         ✅ 前端可以创建新认证UI
    └── login.html
```

### 3. 修改SSO登录页面
编辑 `login/auth-providers/sso/login.html`：

```html
<!-- 修改页面样式、布局、交互逻辑 -->
<div class="login-container">
    <div class="logo">YOUR CUSTOM DESIGN</div>
    <button id="sso-login-btn" onclick="openSSOLogin()">
        [ 自定义SSO登录按钮 ]
    </button>
</div>

<script>
// 前端可以修改的部分：
// - UI交互逻辑
// - 错误提示样式
// - 加载动画效果
// - 用户体验优化

// ❌ 不要修改核心认证逻辑：
// - submitAuthCode() 函数的核心逻辑
// - 与后端 /login/sso 的通信协议
</script>
```

## 🔧 开发实操指南

### 配置文件控制
```bash
# login/.env 文件
AUTH_PROVIDER=local    # 开发环境
AUTH_PROVIDER=sso      # 生产环境
```

### 前端API接口
```bash
GET  /login/config     # 获取认证配置（client_id、oauth_url等）
POST /login/sso        # SSO认证提交（后端处理）
POST /login/local      # 本地认证提交（后端处理）
GET  /login            # 获取登录页面（前端展示）
```

### 开发测试流程
1. **本地测试** - 设置 `AUTH_PROVIDER=local`，任意用户名密码登录
2. **UI调试** - 修改 `login.html`，刷新浏览器即可看到效果
3. **SSO集成** - 设置 `AUTH_PROVIDER=sso`，配置真实SSO参数
4. **容器重启** - 修改配置后执行 `./start.sh` 应用新配置

## 📋 前端开发清单

### UI定制
- [ ] 修改登录页面设计 (`login.html`)
- [ ] 调整CSS样式和主题色彩
- [ ] 添加公司Logo和品牌元素
- [ ] 优化移动端响应式布局

### 交互体验
- [ ] 添加加载动画和状态提示
- [ ] 完善错误信息显示
- [ ] 实现记住登录状态（如需要）
- [ ] 添加多语言支持（如需要）

### 测试验证
- [ ] 本地开发模式功能测试
- [ ] SSO生产模式集成测试
- [ ] 不同浏览器兼容性测试
- [ ] 移动端设备适配测试

## 🔄 模式切换

### 开发 → 生产
```bash
# 1. 修改配置文件
# login/.env
AUTH_PROVIDER=sso

# 2. 重启容器
./start.sh

# 3. 验证SSO登录流程
```

### 团队协作
- **前端团队**：独立开发UI，通过git管理 `*.html` 文件
- **后端团队**：维护认证逻辑，管理 `*.js` 和配置文件
- **配置管理**：生产环境通过 `login/.env` 文件统一管理

## 🆘 常见问题

### Q: 修改登录页面后不生效？
A: 确保容器重启 (`./start.sh`) 并清除浏览器缓存

### Q: 如何调试SSO认证流程？
A: 打开浏览器开发者工具，查看Console日志和Network请求

### Q: 前端可以添加新的认证方式吗？
A: 可以创建新的UI，但需要后端团队配合实现对应的认证逻辑

### Q: 生产环境如何快速切换认证模式？
A: 修改 `login/.env` 中的 `AUTH_PROVIDER` 值，重启容器即可

---

**💡 提示**：前端团队专注于用户体验和界面交互，后端负责安全和业务逻辑。通过清晰的职责分工，可以并行开发，提高效率。