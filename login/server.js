const path = require('path');

// 加载环境变量（从当前目录的.env文件）
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const { createProxyMiddleware } = require('http-proxy-middleware');
const axios = require('axios');
const crypto = require('crypto');

const app = express();
const port = 3000;



// SSO配置（从环境变量获取）
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
// 安全日志输出函数：隐藏敏感数据但保留调试价值
function safeLog(label, data) {
    if (typeof data === 'string') {
        // 字符串类型：显示头尾字符
        const safe = data.length > 12 ? data.substring(0, 6) + '****' + data.slice(-4) : data.substring(0, 4) + '****';
        console.log(label, safe);
    } else if (typeof data === 'object' && data !== null) {
        // 对象类型：递归处理敏感字段
        const safeObj = {};
        for (const [key, value] of Object.entries(data)) {
            if (['code', 'access_token', 'client_secret', 'refresh_token'].includes(key)) {
                safeObj[key] = typeof value === 'string' && value.length > 8 ? 
                    value.substring(0, 6) + '****' + value.slice(-4) : '****';
            } else {
                safeObj[key] = value;
            }
        }
        console.log(label, safeObj);
    } else {
        console.log(label, data);
    }
}

app.post('/login/sso', async (req, res) => {
    console.log('=== DEBUG: SSO认证函数开始执行 ===');
    safeLog('DEBUG: 请求体内容:', req.body);
    
    try {
        const { code, state, redirect_uri } = req.body;
        console.log('DEBUG: 解析请求参数 - code:', code ? code.substring(0, 6) + '****' + code.slice(-4) : 'undefined', 'state:', state);
        
        if (!code) {
            console.log('DEBUG: 认证码缺失，返回400错误');
            return res.status(400).json({ error: 'Missing authorization code' });
        }
        
        console.log('DEBUG: 步骤1 - 准备Token交换请求');
        console.log('收到SSO认证码长度:', code.length, 'State:', state);
        console.log('使用重定向URI:', GFT_CONFIG.redirect_uri ? GFT_CONFIG.redirect_uri.substring(0, 20) + '****' + GFT_CONFIG.redirect_uri.slice(-15) : 'undefined');
        
        // 第一步：用认证码换取访问令牌
        const tokenRequestData = {
            grant_type: 'code',  // 按照API文档，授权类型必须是字符串'code'
            client_id: GFT_CONFIG.client_id,
            client_secret: GFT_CONFIG.client_secret,
            code: code,  // 实际的授权码参数
            redirect_uri: GFT_CONFIG.redirect_uri
        };
        
        console.log('DEBUG: Token请求配置完成');
        console.log('发送Token请求到:', GFT_CONFIG.token_url);
        safeLog('Token请求参数:', tokenRequestData);
        
        console.log('DEBUG: 开始发送Token请求...');
        const tokenResponse = await axios.post(GFT_CONFIG.token_url, tokenRequestData, {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            timeout: 10000
        });
        
        console.log('DEBUG: Token请求成功，状态码:', tokenResponse.status);
        const { access_token, token_type, expires_in } = tokenResponse.data;
        console.log('获取访问令牌成功:', { token_type, expires_in });
        console.log('DEBUG: access_token长度:', access_token ? access_token.length : 0, '首尾:', access_token ? access_token.substring(0, 6) + '****' + access_token.slice(-4) : 'null');
        
        console.log('DEBUG: 步骤2 - 开始获取用户信息');
        // 第二步：使用访问令牌获取用户信息
        const userResponse = await axios.get(GFT_CONFIG.userinfo_url, {
            headers: {
                'Authorization': `${token_type || 'Bearer'} ${access_token}`
            },
            timeout: 10000
        });
        
        console.log('DEBUG: 用户信息请求成功，状态码:', userResponse.status);
        const userInfo = userResponse.data;
        
        // 根据实际返回的数据结构解析用户信息
        const userId = userInfo.access_token?.user_id || userInfo.oa?.uid || userInfo.oa?.loginid;
        const userName = userInfo.oa?.sn || userInfo.oa?.cn || userInfo.oa?.displayname;
        const userEmail = userInfo.oa?.email || userInfo.oa?.mailaddress;
        const userDept = userInfo.oa?.['fdu-deptname'] || userInfo.oa?.dpfullname;
        
        console.log('获取用户信息成功:', { id: userId, name: userName });
        // 安全输出用户信息结构，隐藏敏感数据
        console.log('DEBUG: 用户信息结构:', {
            hasAccessToken: !!userInfo.access_token,
            hasOaInfo: !!userInfo.oa,
            userFieldsFound: { userId: !!userId, userName: !!userName, userEmail: !!userEmail, userDept: !!userDept },
            totalFields: Object.keys(userInfo).length
        });
        
        // 验证必要的用户信息
        if (!userId || !userName) {
            throw new Error(`用户信息解析失败: userId=${userId}, userName=${userName}`);
        }
        
        console.log('DEBUG: 步骤3 - 创建本地会话');
        // 第三步：创建本地会话
        const sessionId = Date.now().toString() + Math.random().toString(36);
        const now = Date.now();
        activeSessions.set(sessionId, {
            createdAt: now,
            lastAccess: now,
            user: {
                id: userId,
                name: userName,
                email: userEmail,
                department: userDept,
                type: 'sso',
                access_token: access_token // 保存访问令牌以备后用
            }
        });
        
        console.log('DEBUG: 会话创建成功，sessionId:', sessionId.substring(0, 8) + '****' + sessionId.slice(-6));
        
        // 设置会话Cookie，支持不同域名访问
        res.cookie('auth', sessionId, { 
            httpOnly: true,
            sameSite: 'lax', // 修改为lax以支持跨域名访问
            secure: false, // 生产环境设置为true
            domain: undefined // 不设置域名，让浏览器自动处理
        });
        
        console.log('DEBUG: Cookie设置完成');
        console.log(`用户 ${userName} (${userId}) SSO登录成功`);
        console.log('DEBUG: 准备返回成功响应');
        res.json({ success: true, user: { name: userName, id: userId } });
        console.log('=== DEBUG: SSO认证函数执行完成 ===');
        
    } catch (error) {
        console.log('=== DEBUG: SSO认证过程中发生错误 ===');
        console.error('SSO认证失败:', error.message);
        
        // 简化错误信息输出
        if (error.response) {
            console.error('HTTP错误:', {
                status: error.response.status,
                statusText: error.response.statusText,
                url: error.config?.url || 'unknown'
            });
        } else if (error.request) {
            console.error('网络请求错误：无响应');
        } else {
            console.error('其他错误:', error.message);
        }
        
        res.status(401).json({ 
            error: 'SSO authentication failed', 
            details: error.message 
        });
        console.log('=== DEBUG: 错误响应已发送 ===');
    }
});

// 定时清理过期会话（优化：适应开发场景的会话策略）
setInterval(() => {
    const now = Date.now();
    let cleanedCount = 0;
    
    for (const [id, session] of activeSessions.entries()) {
        const age = now - session.createdAt;
        const inactivity = now - session.lastAccess;
        
        // 开发友好的过期策略（用户优化版）：
        // - 绝对过期：12小时（支持跨时区工作、加班场景）
        // - 不活跃过期：1小时（更宽松的开发节奏）
        const MAX_AGE = 12 * 60 * 60 * 1000;     // 12小时
        const MAX_INACTIVITY = 60 * 60 * 1000;   // 1小时
        
        if (age > MAX_AGE || inactivity > MAX_INACTIVITY) {
            console.log(`清理过期会话: ${session.user?.name || 'unknown'} (${id.substring(0, 8)}****) - ${age > MAX_AGE ? '超过12小时' : '1小时无活动'}`);
            activeSessions.delete(id);
            cleanedCount++;
        }
    }
    
    if (cleanedCount > 0) {
        console.log(`定时清理完成，删除 ${cleanedCount} 个过期会话`);
    }
}, 30 * 60 * 1000); // 30分钟执行一次（进一步降低频率）

// Middleware to check for authentication (simplified like main branch)
app.use((req, res, next) => {
    // Skip authentication for login paths
    if (req.path === '/login' || req.path.startsWith('/login/')) {
        next();
        return;
    }
    
    const sessionId = req.cookies.auth;
    const now = Date.now();
    
    // Check if session exists and is valid
    if (sessionId && activeSessions.has(sessionId)) {
        const session = activeSessions.get(sessionId);
        const age = now - session.createdAt;
        const inactivity = now - session.lastAccess;
        
        // 与定时清理保持一致的过期策略（用户优化版）
        const MAX_AGE = 12 * 60 * 60 * 1000;     // 12小时
        const MAX_INACTIVITY = 60 * 60 * 1000;   // 1小时
        
        if (age > MAX_AGE || inactivity > MAX_INACTIVITY) {
            // Session expired, remove it
            console.log(`会话过期: ${session.user?.name || 'unknown'} (${sessionId.substring(0, 8)}****) - ${age > MAX_AGE ? '超过12小时' : '1小时无活动'}`);
            activeSessions.delete(sessionId);
            res.clearCookie('auth');
            res.redirect('/login');
            return;
        }
        
        // Update last access time and add user info
        session.lastAccess = now;
        req.user = session.user;
        
        console.log('DEBUG: 用户认证成功，继续到ttyd代理，用户:', req.user?.name || 'unknown');
        next();
    } else {
        // Clear invalid cookie and redirect to login
        res.clearCookie('auth');
        res.redirect('/login');
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

// 创建全局ttyd代理（恢复主分支架构）
const ttydProxy = createProxyMiddleware({
    target: 'http://127.0.0.1:7681',
    changeOrigin: true,
    ws: true, // Enable WebSocket proxying
    onProxyReq: (proxyReq, req, res) => {
        // 传递用户信息到ttyd（如果有的话）
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
            // 如果没有用户信息，设置默认值
            proxyReq.setHeader('X-WEBAUTH-USER', 'anonymous');
        }
    }
});

// 全局代理路由，在认证中间件之后应用
app.use('/', ttydProxy);

app.listen(port, () => {
    console.log(`Login server listening at http://localhost:${port}`);
});
