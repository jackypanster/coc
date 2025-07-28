const path = require('path');

// 加载环境变量（从当前目录的.env文件）
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const { createProxyMiddleware } = require('http-proxy-middleware');
const AuthManager = require('./auth-manager');

const app = express();
const port = 3000;

// 中间件配置
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());

// 初始化认证管理器
const authProvider = process.env.AUTH_PROVIDER || 'sso';
const authManager = new AuthManager(authProvider);

// 启动认证管理器
(async () => {
    try {
        await authManager.initialize();
        console.log(`✅ 认证系统初始化完成，使用提供者: ${authProvider}`);
    } catch (error) {
        console.error('❌ 认证系统初始化失败:', error.message);
        process.exit(1);
    }
})();

// 认证相关路由
app.get('/login', authManager.getLoginHandler());
app.get('/login/config', authManager.getConfigHandler());
app.post('/logout', authManager.getLogoutHandler());

// 动态注册认证提供者的路由
const providerRoutes = authManager.getProviderRoutes();
providerRoutes.forEach(route => {
    const method = route.method.toLowerCase();
    if (route.path === '/login/sso' || route.path === '/login/local') {
        // 这些路由使用统一的认证处理器
        app[method](route.path, authManager.getAuthHandler());
    } else {
        // 其他自定义路由
        app[method](route.path, route.handler);
    }
});

// 认证中间件（必须在认证路由之后）
app.use(authManager.getMiddleware());

// 创建ttyd代理
const ttydProxy = createProxyMiddleware({
    target: 'http://127.0.0.1:7681',
    changeOrigin: true,
    ws: true, // 启用WebSocket代理
    onProxyReq: (proxyReq, req, res) => {
        // 传递用户信息到ttyd
        if (req.user) {
            if (req.user.name) {
                try {
                    const encodedName = encodeURIComponent(req.user.name);
                    proxyReq.setHeader('X-WEBAUTH-USER', encodedName);
                } catch (e) {
                    proxyReq.setHeader('X-WEBAUTH-USER', 'authenticated-user');
                }
            } else {
                proxyReq.setHeader('X-WEBAUTH-USER', 'authenticated-user');
            }
        } else {
            proxyReq.setHeader('X-WEBAUTH-USER', 'anonymous');
        }
    }
});

// 全局代理路由，在认证中间件之后应用
app.use('/', ttydProxy);

// 启动服务器
app.listen(port, () => {
    console.log(`🚀 登录服务器运行在 http://localhost:${port}`);
    console.log(`🔐 认证模式: ${authProvider}`);
    
    if (authProvider === 'local') {
        console.log('📝 本地开发模式提示:');
        console.log('   - 使用任意用户名密码登录');
        console.log('   - 生产环境请设置 AUTH_PROVIDER=sso');
    }
});