const path = require('path');
const fs = require('fs').promises;
const AuthProvider = require('../../auth-provider');

/**
 * 本地开发认证提供者
 * 用于开发环境，不需要真实的认证
 */
class LocalAuthProvider extends AuthProvider {
    constructor() {
        super({
            maxAge: 24 * 60 * 60 * 1000,      // 24小时（开发环境更宽松）
            maxInactivity: 4 * 60 * 60 * 1000  // 4小时
        });
    }

    async initialize() {
        console.log('🔧 本地开发认证模式已启用');
        console.log('⚠️  警告：此模式仅用于开发环境，生产环境请使用SSO认证');
    }

    async getLoginPage() {
        const loginPath = path.join(__dirname, 'login.html');
        return await fs.readFile(loginPath, 'utf-8');
    }

    async getClientConfig() {
        return {
            mode: 'local',
            message: '开发模式：使用任意用户名密码登录'
        };
    }

    async authenticate(req, res) {
        const { username, password } = req.body;
        
        if (!username || !password) {
            throw new Error('用户名和密码不能为空');
        }
        
        // 开发模式：接受任何非空的用户名密码
        console.log(`🔓 本地认证: 用户 ${username} 登录`);
        
        return {
            id: `local_${username}`,
            name: username,
            email: `${username}@local.dev`,
            department: 'Development',
            type: 'local'
        };
    }

    getRoutes() {
        return [
            {
                method: 'post',
                path: '/login/local',
                handler: async (req, res) => {
                    // 本地认证由AuthManager统一处理，这里只是占位
                }
            }
        ];
    }

    async validateSession(session) {
        // 调用父类的默认验证逻辑
        const isValid = await super.validateSession(session);
        
        if (!isValid && session.user?.type === 'local') {
            console.log(`⏰ 本地开发会话过期: ${session.user.name}`);
        }
        
        return isValid;
    }
}

module.exports = LocalAuthProvider;