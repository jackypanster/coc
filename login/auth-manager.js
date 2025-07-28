const path = require('path');
const crypto = require('crypto');

/**
 * 认证管理器
 * 负责加载和管理认证提供者
 */
class AuthManager {
    constructor(providerType = 'sso') {
        this.providerType = providerType;
        this.provider = null;
        this.sessions = new Map(); // sessionId -> { createdAt, lastAccess, user }
        
        // 启动会话清理定时器
        this.startSessionCleanup();
    }

    /**
     * 初始化认证提供者
     */
    async initialize() {
        console.log(`🔐 初始化认证提供者: ${this.providerType}`);
        
        try {
            // 动态加载认证提供者
            const ProviderClass = require(`./auth-providers/${this.providerType}`);
            this.provider = new ProviderClass();
            await this.provider.initialize();
            
            console.log(`✅ 认证提供者 ${this.providerType} 初始化成功`);
        } catch (error) {
            console.error(`❌ 无法加载认证提供者 ${this.providerType}:`, error.message);
            
            // 降级到本地认证
            if (this.providerType !== 'local') {
                console.log('⚠️  降级到本地认证模式');
                const LocalProvider = require('./auth-providers/local');
                this.provider = new LocalProvider();
                await this.provider.initialize();
            } else {
                throw error;
            }
        }
    }

    /**
     * 获取登录页面处理器
     */
    getLoginHandler() {
        return async (req, res) => {
            try {
                const html = await this.provider.getLoginPage();
                res.send(html);
            } catch (error) {
                console.error('获取登录页面失败:', error);
                res.status(500).send('登录页面加载失败');
            }
        };
    }

    /**
     * 获取客户端配置处理器
     */
    getConfigHandler() {
        return async (req, res) => {
            try {
                const config = await this.provider.getClientConfig();
                res.json(config);
            } catch (error) {
                console.error('获取客户端配置失败:', error);
                res.status(500).json({ error: '配置加载失败' });
            }
        };
    }

    /**
     * 获取认证处理器
     */
    getAuthHandler() {
        return async (req, res) => {
            try {
                // 调用认证提供者进行认证
                const userInfo = await this.provider.authenticate(req, res);
                
                if (userInfo) {
                    // 创建会话
                    const sessionId = this.createSession(userInfo);
                    
                    // 设置会话Cookie
                    res.cookie('auth', sessionId, { 
                        httpOnly: true,
                        sameSite: 'lax',
                        secure: false, // 生产环境应设置为true
                        domain: undefined
                    });
                    
                    console.log(`✅ 用户 ${userInfo.name} (${userInfo.id}) 登录成功`);
                    res.json({ success: true, user: { name: userInfo.name, id: userInfo.id } });
                } else {
                    res.status(401).json({ error: '认证失败' });
                }
            } catch (error) {
                console.error('认证处理失败:', error);
                res.status(401).json({ error: '认证失败', details: error.message });
            }
        };
    }

    /**
     * 获取认证中间件
     */
    getMiddleware() {
        return async (req, res, next) => {
            // 跳过登录相关路径
            if (req.path === '/login' || req.path.startsWith('/login/')) {
                return next();
            }
            
            const sessionId = req.cookies.auth;
            
            if (sessionId && this.sessions.has(sessionId)) {
                const session = this.sessions.get(sessionId);
                
                // 验证会话有效性
                const isValid = await this.provider.validateSession(session);
                
                if (isValid) {
                    // 更新最后访问时间
                    session.lastAccess = Date.now();
                    req.user = session.user;
                    return next();
                } else {
                    // 会话过期
                    console.log(`会话过期: ${session.user?.name || 'unknown'}`);
                    this.sessions.delete(sessionId);
                }
            }
            
            // 清除无效Cookie并重定向到登录页
            res.clearCookie('auth');
            res.redirect('/login');
        };
    }

    /**
     * 获取登出处理器
     */
    getLogoutHandler() {
        return async (req, res) => {
            const sessionId = req.cookies.auth;
            
            if (sessionId && this.sessions.has(sessionId)) {
                const session = this.sessions.get(sessionId);
                
                // 调用认证提供者的登出方法
                await this.provider.logout(session);
                
                // 删除会话
                this.sessions.delete(sessionId);
            }
            
            res.clearCookie('auth');
            res.redirect('/login');
        };
    }

    /**
     * 获取认证提供者的自定义路由
     */
    getProviderRoutes() {
        return this.provider ? this.provider.getRoutes() : [];
    }

    /**
     * 创建会话
     */
    createSession(userInfo) {
        const sessionId = Date.now().toString() + Math.random().toString(36);
        const now = Date.now();
        
        this.sessions.set(sessionId, {
            createdAt: now,
            lastAccess: now,
            user: userInfo
        });
        
        return sessionId;
    }

    /**
     * 启动会话清理定时器
     */
    startSessionCleanup() {
        setInterval(async () => {
            let cleanedCount = 0;
            
            for (const [sessionId, session] of this.sessions.entries()) {
                const isValid = await this.provider.validateSession(session);
                
                if (!isValid) {
                    this.sessions.delete(sessionId);
                    cleanedCount++;
                }
            }
            
            if (cleanedCount > 0) {
                console.log(`🧹 清理了 ${cleanedCount} 个过期会话`);
            }
        }, 30 * 60 * 1000); // 30分钟
    }
}

module.exports = AuthManager;