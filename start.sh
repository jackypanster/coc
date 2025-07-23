#!/bin/bash
set -e

# 加载版本配置
source ./versions.env

echo "🌟 启动 Cloud Code Dev 环境..."

# 启动容器，挂载当前目录到 /app
docker run -d \
    --name cloud-code-dev \
    -p 7681:7681 \
    -v $(pwd):/app \
    --restart unless-stopped \
    ${IMAGE_NAME}:${VERSION}

echo "✅ 容器启动成功！"
echo "📦 使用镜像: ${IMAGE_NAME}:${VERSION}"
echo "🌐 ttyd 终端: http://localhost:7681"
echo "📁 工作目录已挂载到 /app"
echo ""
echo "💡 使用说明:"
echo "   访问 http://localhost:7681 进入 Web 终端"
echo ""
echo "🛠️  管理命令:"
echo "   停止: docker stop cloud-code-dev"
echo "   重启: docker restart cloud-code-dev"
echo "   日志: docker logs cloud-code-dev"
