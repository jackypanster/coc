const path = require('path');
const fs = require('fs').promises;
const axios = require('axios');
const AuthProvider = require('../../auth-provider');

/**
 * SSO认证提供者
 * 实现企业内部SSO (OAuth2.0) 认证
 */
class SSOAuthProvider extends AuthProvider {
    constructor() {
        super({
            maxAge: 12 * 60 * 60 * 1000,      // 12小时
            maxInactivity: 60 * 60 * 1000     // 1小时
        });
        
        // SSO配置（从环境变量获取）
        this.ssoConfig = {
            oauth_url: process.env.GFT_OAUTH_URL,
            token_url: process.env.GFT_TOKEN_URL,
            userinfo_url: process.env.GFT_USERINFO_URL,
            client_id: process.env.GFT_CLIENT_ID,
            client_secret: process.env.GFT_CLIENT_SECRET,
            redirect_uri: process.env.GFT_REDIRECT_URI
        };
    }

    async initialize() {
        // 验证必要的环境变量
        if (!this.ssoConfig.client_id || !this.ssoConfig.client_secret) {
            throw new Error('缺少必要的SSO配置环境变量 (GFT_CLIENT_ID, GFT_CLIENT_SECRET)');
        }
        
        console.log('✅ SSO配置验证通过');
    }

    async getLoginPage() {
        const loginPath = path.join(__dirname, 'login.html');
        return await fs.readFile(loginPath, 'utf-8');
    }

    async getClientConfig() {
        return {
            oauth_url: this.ssoConfig.oauth_url,
            client_id: this.ssoConfig.client_id,
            redirect_uri: this.ssoConfig.redirect_uri,
            theme: 'mini',
            login_type: 'oa'
        };
    }

    async authenticate(req, res) {
        const { code, state, redirect_uri } = req.body;
        
        if (!code) {
            throw new Error('Missing authorization code');
        }
        
        try {
            // 第一步：用认证码换取访问令牌
            const tokenRequestData = {
                grant_type: 'code',
                client_id: this.ssoConfig.client_id,
                client_secret: this.ssoConfig.client_secret,
                code: code,
                redirect_uri: this.ssoConfig.redirect_uri
            };
            
            console.log('🔄 开始SSO认证流程...');
            const tokenResponse = await axios.post(this.ssoConfig.token_url, tokenRequestData, {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                timeout: 10000
            });
            
            const { access_token, token_type, expires_in } = tokenResponse.data;
            console.log('✅ 获取访问令牌成功');
            
            // 第二步：使用访问令牌获取用户信息
            const userResponse = await axios.get(this.ssoConfig.userinfo_url, {
                headers: {
                    'Authorization': `${token_type || 'Bearer'} ${access_token}`
                },
                timeout: 10000
            });
            
            const userInfo = userResponse.data;
            
            // 解析用户信息
            const userId = userInfo.access_token?.user_id || userInfo.oa?.uid || userInfo.oa?.loginid;
            const userName = userInfo.oa?.sn || userInfo.oa?.cn || userInfo.oa?.displayname;
            const userEmail = userInfo.oa?.email || userInfo.oa?.mailaddress;
            const userDept = userInfo.oa?.['fdu-deptname'] || userInfo.oa?.dpfullname;
            
            if (!userId || !userName) {
                throw new Error(`用户信息解析失败: userId=${userId}, userName=${userName}`);
            }
            
            console.log(`✅ 获取用户信息成功: ${userName} (${userId})`);
            
            return {
                id: userId,
                name: userName,
                email: userEmail,
                department: userDept,
                type: 'sso',
                access_token: access_token
            };
            
        } catch (error) {
            console.error('SSO认证失败:', error.message);
            if (error.response) {
                console.error('HTTP错误:', {
                    status: error.response.status,
                    statusText: error.response.statusText,
                    url: error.config?.url || 'unknown'
                });
            }
            throw error;
        }
    }

    getRoutes() {
        return [
            {
                method: 'post',
                path: '/login/sso',
                handler: async (req, res) => {
                    // SSO认证由AuthManager统一处理，这里只是占位
                }
            },
            {
                method: 'get',
                path: '/login/config',
                handler: async (req, res) => {
                    // 配置获取由AuthManager统一处理，这里只是占位
                }
            }
        ];
    }
}

module.exports = SSOAuthProvider;