# 认证提供者开发指南

## 概述

Code on Cloud (CoC) 使用可插拔的认证架构，允许开发者轻松实现和集成不同的认证方式。本指南将帮助您创建自定义认证提供者。

## 架构设计

### 核心组件

1. **AuthProvider** - 认证接口基类，定义了所有认证提供者必须实现的方法
2. **AuthManager** - 认证管理器，负责加载和管理认证提供者
3. **认证提供者** - 具体的认证实现（如SSO、本地认证等）

### 工作流程

```
用户访问 → Nginx → Express Server → AuthManager → AuthProvider → 认证成功 → ttyd终端
```

## 创建自定义认证提供者

### 1. 目录结构

在 `login/auth-providers/` 目录下创建您的认证模块：

```
login/auth-providers/
├── your-provider/
│   ├── index.js       # 认证逻辑实现
│   ├── login.html     # 登录页面（可选）
│   └── config.js      # 配置处理（可选）
```

### 2. 实现认证提供者

创建 `index.js` 并继承 `AuthProvider` 基类：

```javascript
const AuthProvider = require('../../auth-provider');

class YourAuthProvider extends AuthProvider {
    constructor() {
        super({
            maxAge: 12 * 60 * 60 * 1000,      // 会话最大生存时间
            maxInactivity: 60 * 60 * 1000     // 会话最大不活跃时间
        });
    }

    async initialize() {
        // 初始化逻辑，如验证配置
        console.log('认证提供者初始化');
    }

    async getLoginPage() {
        // 返回登录页面HTML
        return '<html>...</html>';
    }

    async getClientConfig() {
        // 返回前端需要的配置（不含敏感信息）
        return {
            authType: 'custom',
            apiEndpoint: '/login/custom'
        };
    }

    async authenticate(req, res) {
        // 核心认证逻辑
        // 成功返回用户信息，失败抛出异常
        const { username, password } = req.body;
        
        // 验证逻辑...
        
        return {
            id: 'user123',
            name: 'John Doe',
            email: 'john@example.com',
            type: 'custom'
        };
    }

    getRoutes() {
        // 定义自定义路由
        return [
            {
                method: 'post',
                path: '/login/custom',
                handler: async (req, res) => {
                    // 路由处理逻辑
                }
            }
        ];
    }
}

module.exports = YourAuthProvider;
```

### 3. 必须实现的方法

- **initialize()** - 初始化认证提供者
- **getLoginPage()** - 返回登录页面HTML
- **authenticate(req, res)** - 处理认证请求，返回用户信息
- **getClientConfig()** - 返回客户端配置（可选）
- **getRoutes()** - 返回自定义路由（可选）

### 4. 可选覆盖的方法

- **validateSession(session)** - 自定义会话验证逻辑
- **logout(session)** - 自定义登出逻辑

## 配置和使用

### 1. 环境变量配置

设置 `AUTH_PROVIDER` 环境变量来选择认证提供者：

```bash
# 使用SSO认证
AUTH_PROVIDER=sso

# 使用本地认证
AUTH_PROVIDER=local

# 使用自定义认证
AUTH_PROVIDER=your-provider
```

### 2. 启动容器

```bash
# 开发模式（本地认证）
docker run -e AUTH_PROVIDER=local ...

# 生产模式（SSO认证）
docker run -e AUTH_PROVIDER=sso -e GFT_CLIENT_ID=xxx ...
```

## 现有认证提供者

### SSO认证 (`auth-providers/sso`)

- 企业内部SSO系统集成
- OAuth2.0标准流程
- 需要配置客户端ID和密钥

### 本地认证 (`auth-providers/local`)

- 开发环境使用
- 接受任意用户名密码
- 无需额外配置

## 最佳实践

### 1. 安全性

- 使用HTTPS传输敏感信息
- 不要在日志中记录密码或令牌
- 实现合理的会话超时策略
- 使用HTTP-only cookies存储会话

### 2. 用户体验

- 提供清晰的错误信息
- 实现友好的登录界面
- 支持记住登录状态（可选）

### 3. 可维护性

- 使用环境变量管理配置
- 实现详细的日志记录
- 提供配置验证机制
- 编写单元测试

## 调试技巧

### 1. 启用详细日志

在认证提供者中添加调试日志：

```javascript
console.log('🔍 认证请求:', { username, timestamp: new Date() });
console.log('✅ 认证成功:', userId);
console.error('❌ 认证失败:', error.message);
```

### 2. 测试认证流程

```bash
# 查看容器日志
docker logs -f coc

# 测试认证端点
curl -X POST http://localhost/login/your-provider \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'
```

### 3. 会话调试

在AuthManager中已实现会话管理，可通过日志查看：
- 会话创建
- 会话验证
- 会话清理

## 扩展示例

### LDAP认证提供者

```javascript
const ldap = require('ldapjs');

class LDAPAuthProvider extends AuthProvider {
    async authenticate(req, res) {
        const { username, password } = req.body;
        
        // LDAP认证逻辑
        const client = ldap.createClient({
            url: process.env.LDAP_URL
        });
        
        // 绑定和搜索用户...
        
        return {
            id: ldapUser.uid,
            name: ldapUser.cn,
            email: ldapUser.mail,
            type: 'ldap'
        };
    }
}
```

### SAML认证提供者

```javascript
const saml2 = require('saml2-js');

class SAMLAuthProvider extends AuthProvider {
    async authenticate(req, res) {
        // SAML认证流程
        const sp = new saml2.ServiceProvider({...});
        const idp = new saml2.IdentityProvider({...});
        
        // 处理SAML响应...
        
        return userInfo;
    }
}
```

## 故障排除

### 常见问题

1. **认证提供者加载失败**
   - 检查模块路径是否正确
   - 确认index.js导出了类
   - 查看容器日志中的错误信息

2. **认证总是失败**
   - 检查authenticate方法的返回值格式
   - 确认环境变量配置正确
   - 查看网络请求是否正常

3. **会话过期太快**
   - 调整maxAge和maxInactivity参数
   - 检查系统时间是否正确

## 贡献指南

欢迎贡献新的认证提供者！请遵循以下步骤：

1. Fork项目并创建功能分支
2. 在auth-providers目录下创建新模块
3. 编写完整的实现和文档
4. 添加测试用例
5. 提交Pull Request

## 联系支持

如有问题或需要帮助，请联系平台团队或在项目issue中提出。