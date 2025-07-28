/**
 * 认证提供者接口基类
 * 所有认证实现都应该继承此类并实现相应方法
 */
class AuthProvider {
    constructor(config = {}) {
        this.config = config;
    }

    /**
     * 获取登录页面HTML内容
     * @returns {Promise<string>} HTML内容
     */
    async getLoginPage() {
        throw new Error('getLoginPage() must be implemented by subclass');
    }

    /**
     * 获取前端需要的配置信息（不包含敏感数据）
     * @returns {Promise<Object>} 配置对象
     */
    async getClientConfig() {
        return {};
    }

    /**
     * 处理认证请求
     * @param {Object} req - Express请求对象
     * @param {Object} res - Express响应对象
     * @returns {Promise<Object|null>} 成功返回用户信息，失败返回null
     */
    async authenticate(req, res) {
        throw new Error('authenticate() must be implemented by subclass');
    }

    /**
     * 验证会话是否有效
     * @param {Object} session - 会话数据
     * @returns {Promise<boolean>} 是否有效
     */
    async validateSession(session) {
        const now = Date.now();
        const age = now - session.createdAt;
        const inactivity = now - session.lastAccess;
        
        // 默认会话策略
        const MAX_AGE = this.config.maxAge || 12 * 60 * 60 * 1000; // 12小时
        const MAX_INACTIVITY = this.config.maxInactivity || 60 * 60 * 1000; // 1小时
        
        return age <= MAX_AGE && inactivity <= MAX_INACTIVITY;
    }

    /**
     * 处理登出
     * @param {Object} session - 会话数据
     * @returns {Promise<void>}
     */
    async logout(session) {
        // 默认实现：无需特殊处理
    }

    /**
     * 获取认证路由配置
     * @returns {Array<Object>} Express路由配置数组
     */
    getRoutes() {
        return [];
    }

    /**
     * 初始化认证提供者
     * @returns {Promise<void>}
     */
    async initialize() {
        // 默认实现：无需初始化
    }
}

module.exports = AuthProvider;