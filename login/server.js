const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');
const axios = require('axios');
const crypto = require('crypto');

const app = express();
const port = 3000;



// 企业SSO配置（从环境变量获取）
const GFT_CONFIG = {
    oauth_url: process.env.GFT_OAUTH_URL,
    token_url: process.env.GFT_TOKEN_URL,
    userinfo_url: process.env.GFT_USERINFO_URL,
    client_id: process.env.GFT_CLIENT_ID,
    client_secret: process.env.GFT_CLIENT_SECRET,
    redirect_uri: process.env.GFT_REDIRECT_URI
};

// 验证必要的环境变量
if (!GFT_CONFIG.client_id || !GFT_CONFIG.client_secret) {
    console.error('❌ 错误：缺少必要的SSO配置环境变量');
    console.error('请设置以下环境变量：');
    console.error('- GFT_CLIENT_ID: SSO应用ID');
    console.error('- GFT_CLIENT_SECRET: SSO应用密钥');
    console.error('- GFT_OAUTH_URL: SSO登录URL');
    console.error('- GFT_TOKEN_URL: SSO令牌交换URL');
    console.error('- GFT_USERINFO_URL: SSO用户信息URL');
    process.exit(1);
}

// Session storage with timestamps and user info (in production, use Redis or database)
const activeSessions = new Map(); // sessionId -> { createdAt, lastAccess, user: { id, name, email, ... } }

app.use(bodyParser.json()); // 添加JSON解析中间件
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());

// Serve the login page
app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'login.html'));
});

// Provide SSO configuration to frontend (without sensitive data)
app.get('/login/config', (req, res) => {
    res.json({
        oauth_url: GFT_CONFIG.oauth_url,
        client_id: GFT_CONFIG.client_id,
        redirect_uri: GFT_CONFIG.redirect_uri,
        theme: 'mini',
        login_type: 'oa'
    });
});



// Handle SSO authentication
app.post('/login/sso', async (req, res) => {
    try {
        const { code, state, redirect_uri } = req.body;
        
        if (!code) {
            return res.status(400).json({ error: 'Missing authorization code' });
        }
        
        console.log('收到SSO认证码:', code, 'State:', state);
        console.log('使用重定向URI:', redirect_uri || GFT_CONFIG.redirect_uri);
        
        // 第一步：用认证码换取访问令牌
        const tokenRequestData = {
            grant_type: 'authorization_code',
            client_id: GFT_CONFIG.client_id,
            client_secret: GFT_CONFIG.client_secret,
            code: code,
            redirect_uri: redirect_uri || GFT_CONFIG.redirect_uri
        };
        
        console.log('发送Token请求到:', GFT_CONFIG.token_url);
        console.log('Token请求参数:', {
            grant_type: tokenRequestData.grant_type,
            client_id: tokenRequestData.client_id,
            client_secret: '***隐藏***',
            code: tokenRequestData.code.substring(0, 10) + '...',
            redirect_uri: tokenRequestData.redirect_uri
        });
        
        const tokenResponse = await axios.post(GFT_CONFIG.token_url, tokenRequestData, {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            timeout: 10000
        });
        
        const { access_token, token_type, expires_in } = tokenResponse.data;
        console.log('获取访问令牌成功:', { token_type, expires_in });
        
        // 第二步：使用访问令牌获取用户信息
        const userResponse = await axios.get(GFT_CONFIG.userinfo_url, {
            headers: {
                'Authorization': `${token_type || 'Bearer'} ${access_token}`
            },
            timeout: 10000
        });
        
        const userInfo = userResponse.data;
        console.log('获取用户信息成功:', { id: userInfo.id, name: userInfo.name });
        
        // 第三步：创建本地会话
        const sessionId = Date.now().toString() + Math.random().toString(36);
        const now = Date.now();
        activeSessions.set(sessionId, {
            createdAt: now,
            lastAccess: now,
            user: {
                id: userInfo.id || userInfo.user_id,
                name: userInfo.name || userInfo.username,
                email: userInfo.email,
                department: userInfo.department,
                type: 'sso',
                access_token: access_token // 保存访问令牌以备后用
            }
        });
        
        // 设置会话Cookie
        res.cookie('auth', sessionId, { 
            httpOnly: true,
            sameSite: 'strict',
            secure: false // 生产环境设置为true
        });
        
        console.log(`用户 ${userInfo.name} (${userInfo.id}) SSO登录成功`);
        res.json({ success: true, user: { name: userInfo.name, id: userInfo.id } });
        
    } catch (error) {
        console.error('SSO认证失败:', error.message);
        if (error.response) {
            console.error('错误响应:', error.response.status, error.response.data);
        }
        res.status(401).json({ 
            error: 'SSO authentication failed', 
            details: error.message 
        });
    }
});

// Middleware to check for authentication
app.use((req, res, next) => {
    const sessionId = req.cookies.auth;
    const now = Date.now();
    
    // Clean up expired sessions
    for (const [id, session] of activeSessions.entries()) {
        const age = now - session.createdAt;
        const inactivity = now - session.lastAccess;
        
        // Remove if older than 5 minutes OR inactive for more than 2 minutes
        if (age > 5 * 60 * 1000 || inactivity > 2 * 60 * 1000) {
            console.log(`清理过期会话: ${session.user?.name || 'unknown'} (${id.substring(0, 8)}...)`);
            activeSessions.delete(id);
        }
    }
    
    if (sessionId && activeSessions.has(sessionId)) {
        const session = activeSessions.get(sessionId);
        const age = now - session.createdAt;
        const inactivity = now - session.lastAccess;
        
        // Check if session is still valid
        if (age <= 5 * 60 * 1000 && inactivity <= 2 * 60 * 1000) {
            // Update last access time
            session.lastAccess = now;
            activeSessions.set(sessionId, session);
            
            // Add user info to request for potential future use
            req.user = session.user;
            
            // User is authenticated, proxy to ttyd
            return createProxyMiddleware({
                target: 'http://localhost:7681',
                changeOrigin: true,
                ws: true, // Enable WebSocket proxying
                logLevel: 'silent',
                onProxyReq: (proxyReq, req, res) => {
                    // Add user info headers for ttyd (optional)
                    if (req.user) {
                        proxyReq.setHeader('X-User-ID', req.user.id);
                        proxyReq.setHeader('X-User-Name', req.user.name);
                        proxyReq.setHeader('X-User-Type', req.user.type);
                    }
                }
            })(req, res, next);
        } else {
            // Session expired, remove it
            console.log(`会话过期: ${session.user?.name || 'unknown'} (${sessionId.substring(0, 8)}...)`);
            activeSessions.delete(sessionId);
            res.clearCookie('auth');
        }
    }
    
    // Not authenticated, redirect to login
    if (req.path !== '/login' && !req.path.startsWith('/login/')) {
        res.redirect('/login');
    } else {
        next();
    }
});

// Add logout endpoint for security
app.post('/logout', (req, res) => {
    const sessionId = req.cookies.auth;
    if (sessionId) {
        activeSessions.delete(sessionId);
        res.clearCookie('auth');
    }
    res.redirect('/login');
});

// Clean up expired sessions every 30 seconds
setInterval(() => {
    const now = Date.now();
    let cleanedCount = 0;
    
    for (const [sessionId, session] of activeSessions.entries()) {
        const sessionAge = now - session.createdAt;
        const lastAccessAge = now - session.lastAccess;
        
        // Remove sessions older than 5 minutes or inactive for 2 minutes
        if (sessionAge > 300000 || lastAccessAge > 120000) {
            activeSessions.delete(sessionId);
            cleanedCount++;
        }
    }
    
    if (cleanedCount > 0) {
        console.log(`Cleaned up ${cleanedCount} expired sessions`);
    }
}, 30000); // 30 seconds

// Create proxy to ttyd
const ttydProxy = createProxyMiddleware({
    target: 'http://127.0.0.1:7681',
    changeOrigin: true,
    ws: true, // Enable WebSocket proxying
    onProxyReq: (proxyReq, req, res) => {
        // Add authentication header for ttyd
        proxyReq.setHeader('X-WEBAUTH-USER', 'admin');
    }
});

// Protected route that proxies to ttyd
app.use('/', ttydProxy);

app.listen(port, () => {
    console.log(`Login server listening at http://localhost:${port}`);
});
