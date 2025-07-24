#!/bin/bash

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
    -v $(pwd):/workspace \
    --restart unless-stopped \
    ${IMAGE_NAME}:${VERSION}

echo "✅ 容器启动成功！"
echo "📦 使用镜像: ${IMAGE_NAME}:${VERSION}"
echo "🌐 登录页面: http://localhost"
echo "📁 工作目录已挂载到 /workspace"
echo ""
echo "💡 使用说明:"
echo "   访问 http://localhost 进入登录页面"
echo "   默认账号: admin / password"
echo ""
echo "🛠️  管理命令:"
echo "   停止: docker stop ${CONTAINER_NAME}"
echo "   重启: docker restart ${CONTAINER_NAME}"
echo "   日志: docker logs ${CONTAINER_NAME}"
