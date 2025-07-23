#!/bin/bash

# 加载版本配置
source ./versions.env

echo "🌟 启动 Claude 开发环境..."

# 检查镜像是否存在
if ! docker images | grep -q "${IMAGE_NAME}"; then
    echo "❌ 镜像不存在，请先运行 ./build.sh"
    exit 1
fi

# 启动容器，挂载当前目录到 /app
docker run -d \
    --name claude-dev \
    -p 7681:7681 \
    -v $(pwd):/app \
    --restart unless-stopped \
    ${IMAGE_NAME}:${VERSION}

echo "✅ 容器启动成功！"
echo "📦 使用镜像: ${IMAGE_NAME}:${VERSION}"
echo "🌐 ttyd 终端: http://localhost:7681"
echo "� 工作目录已挂载到 /app"
echo ""
echo "💡 使用说明:"
echo "   访问 http://localhost:7681 进入 Web 终端"
echo ""
echo "🛠️  管理命令:"
echo "   停止: docker stop claude-dev"
echo "   重启: docker restart claude-dev"
echo "   日志: docker logs claude-dev"
