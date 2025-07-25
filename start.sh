#!/bin/bash

# 从versions.env加载镜像版本信息
source versions.env

# 加载本地.env文件中的环境变量
if [ -f ".env" ]; then
    echo "📋 Loading SSO configuration from .env file..."
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
    echo "✅ Environment variables loaded"
else
    echo "⚠️  .env file not found, using system environment variables"
fi

set -e

# 加载版本配置
if [ ! -f "versions.env" ]; then
    echo "❌ 未找到 versions.env 文件"
    exit 1
fi

source ./versions.env

CONTAINER_NAME="cloud-code-dev"

echo "🌟 启动 Coding Dev 环境..."

# 停止并删除已存在的容器
if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "停止并删除已存在的容器..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi

# 启动容器，挂载工作目录但保护登录服务器的依赖
docker run -d \
    --name ${CONTAINER_NAME} \
    -p 80:80 \
    -v "$(pwd):/workspace" \
    -e GFT_OAUTH_URL="${GFT_OAUTH_URL}" \
    -e GFT_TOKEN_URL="${GFT_TOKEN_URL}" \
    -e GFT_USERINFO_URL="${GFT_USERINFO_URL}" \
    -e GFT_CLIENT_ID="${GFT_CLIENT_ID}" \
    -e GFT_CLIENT_SECRET="${GFT_CLIENT_SECRET}" \
    -e GFT_REDIRECT_URI="${GFT_REDIRECT_URI}" \
    --restart unless-stopped \
    ${IMAGE_NAME}:${VERSION}

echo "✅ 容器启动成功！"
echo "📦 使用镜像: ${IMAGE_NAME}:${VERSION}"
echo "🌐 登录页面: http://localhost"
echo "📁 工作目录已挂载到 /workspace"
echo ""
echo "🎯 设计理念:"
echo "   • 容器提供完整开发工具环境 (Node.js, Python, Git, 编译器等)"
echo "   • 您的代码保存在主机本地，通过 /workspace 访问"
echo "   • 轻量化设计：工具在容器，数据在主机，性能最佳"
echo ""
echo "💡 使用说明:"
echo "   1. 访问 http://localhost 进入SSO登录页面"
echo "   2. 登录后获得Web终端，具备完整开发环境"
echo "   3. 在 /workspace 中编辑您的本地代码"
echo "   4. 使用容器内的工具 (npm, python, git 等) 进行开发"
echo ""
echo "🛠️  管理命令:"
echo "   停止: docker stop ${CONTAINER_NAME}"
echo "   重启: docker restart ${CONTAINER_NAME}"
echo "   日志: docker logs ${CONTAINER_NAME}"
