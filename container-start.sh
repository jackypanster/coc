#!/bin/bash

# Load environment variables if .env file exists
if [ -f "/app/.env" ]; then
    echo "📋 Loading environment variables from .env file..."
    # More robust way to load .env file
    set -a  # automatically export all variables
    source /app/.env
    set +a  # disable automatic export
    echo "✅ .env file loaded successfully"
else
    echo "⚠️  .env file not found at /app/.env, using environment variables"
fi

# Debug: Show current environment variables (without secrets)
echo "🔍 Current SSO configuration:"
echo "- GFT_OAUTH_URL: ${GFT_OAUTH_URL:-'not set'}"
echo "- GFT_CLIENT_ID: ${GFT_CLIENT_ID:-'not set'}"
echo "- GFT_CLIENT_SECRET: ${GFT_CLIENT_SECRET:+'***set***'}"

# Validate required SSO configuration
if [ -z "$GFT_CLIENT_ID" ] || [ -z "$GFT_CLIENT_SECRET" ]; then
    echo "❌ Error: Missing required SSO configuration"
    echo "Please set the following environment variables:"
    echo "- GFT_CLIENT_ID: SSO application ID"
    echo "- GFT_CLIENT_SECRET: SSO application secret"
    echo "- GFT_OAUTH_URL: SSO login URL (optional, has default)"
    echo "- GFT_TOKEN_URL: SSO token exchange URL (optional, has default)"
    echo "- GFT_USERINFO_URL: SSO user info URL (optional, has default)"
    echo ""
    echo "You can either:"
    echo "1. Set environment variables when running docker"
    echo "2. Create a .env file in the project root"
    exit 1
fi

echo "✅ SSO configuration validated: Client ID = $GFT_CLIENT_ID"

# Start ttyd in the background, listening on a local-only port
# 设计理念：容器提供工具环境，用户代码在主机，通过/workspace挂载访问
echo "🚀 Starting ttyd service..."
echo "📝 Container provides development tools (Node.js, Python, Git, etc.)"
echo "📝 User code mounted at /workspace from host directory"
echo "📝 This design keeps container lightweight and data persistent"

# 在/workspace启动ttyd，使用-w参数明确设置工作目录
# 监听所有接口以支持不同域名访问（localhost, 127.0.0.1, local.gf.com.cn）
ttyd --port 7681 --interface 0.0.0.0 --writable -w /workspace bash &
TTYD_PID=$!
sleep 2
echo "✅ ttyd is running (PID: $TTYD_PID) on port 7681"
echo "✅ Terminal ready: container tools + host code = perfect development environment"

# Start the login server in the background
echo "🚀 Starting login server..."
echo "📝 Login server logs will appear below:"
(cd /app/login && node server.js) &
LOGIN_PID=$!
sleep 2
echo "✅ Login server is running (PID: $LOGIN_PID) on port 3000"

# Start Nginx in the background
echo "🚀 Starting Nginx reverse proxy..."
nginx -g 'daemon off;' &
NGINX_PID=$!
sleep 2
echo "✅ Nginx is running (PID: $NGINX_PID) on port 80"

echo "📝 All service logs will be visible via 'docker logs -f'"
echo "🎯 Services started: ttyd($TTYD_PID), login($LOGIN_PID), nginx($NGINX_PID)"

# Set up signal handling for graceful shutdown
trap 'echo "🛑 Shutting down services..."; kill $TTYD_PID $LOGIN_PID $NGINX_PID 2>/dev/null; exit' TERM INT

# Simple approach: just wait for the main processes
# If any process dies, the container will exit and Docker can restart it
echo "⚙️ Container ready! All logs will appear below."
echo "---"

# Wait for any of the background processes to exit
wait
