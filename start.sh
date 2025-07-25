#!/bin/bash

# 从versions.env加载镜像版本信息
source versions.env

# 检查login/.env文件是否存在（用于提示）
if [ ! -f "login/.env" ]; then
    echo "❌ 错误: 未找到 login/.env 文件"
    echo "请复制 login/.env.example 为 login/.env 并配置相应参数"
    exit 1
fi
echo "✅ 发现 login/.env 配置文件"

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

# 启动容器，简洁设计：只挂载工作目录，SSO配置已内置
docker run -d \
    --name ${CONTAINER_NAME} \
    -p 80:80 \
    -v "$(pwd):/workspace" \
    --restart unless-stopped \
    ${IMAGE_NAME}:${VERSION}

echo "✅ 容器启动成功！"
echo "📦 使用镜像: ${IMAGE_NAME}:${VERSION}"
echo "📁 工作目录已挂载到 /workspace"
echo ""
echo "🎯 设计理念:"
echo "   • 容器提供完整开发工具环境 (Node.js, Python, Git, 编译器等)"
echo "   • 您的代码保存在主机本地，通过 /workspace 访问"
echo "   • 轻量化设计：工具在容器，数据在主机，性能最佳"
echo ""
echo "💡 使用说明:"
echo "   1. 登录后获得Web终端，具备完整开发环境"
echo "   2. 在 /workspace 中编辑您的本地代码"
echo "   3. 使用容器内的工具 (npm, python, git 等) 进行开发"
echo ""
echo "🛠️  管理命令:"
echo "   停止: docker stop ${CONTAINER_NAME}"
echo "   重启: docker restart ${CONTAINER_NAME}"
echo "   日志: docker logs ${CONTAINER_NAME}"
