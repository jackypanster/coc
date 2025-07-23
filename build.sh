#!/bin/bash
set -e

# 加载版本配置
source ./versions.env

echo "🚀 开始构建 Docker 镜像 ${IMAGE_NAME}:${VERSION}..."

# 启用 BuildKit 以支持缓存挂载
export DOCKER_BUILDKIT=1

# 构建镜像，传递构建参数
docker build \
    --progress=plain \
    --build-arg CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION} \
    --build-arg CLAUDE_ROUTER_VERSION=${CLAUDE_ROUTER_VERSION} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --cache-from ${IMAGE_NAME}:${VERSION} \
    -t ${IMAGE_NAME}:${VERSION} \
    -t ${IMAGE_NAME}:latest .

echo "✅ 镜像构建完成！"
echo "📝 镜像版本: ${IMAGE_NAME}:${VERSION}"
echo "📝 Claude Code: ${CLAUDE_CODE_VERSION}"
echo "📝 Claude Router: ${CLAUDE_ROUTER_VERSION}"
echo "🎯 使用 ./start.sh 启动容器"
