#!/bin/bash

set -e

# 加载版本配置
if [ ! -f "versions.env" ]; then
    echo "❌ 未找到 versions.env 文件"
    exit 1
fi

source ./versions.env

BASE_IMAGE_NAME="code-on-cloud-base"
BASE_TAG="${VERSION}"

# 检查基础镜像是否存在
if ! docker image inspect ${BASE_IMAGE_NAME}:${BASE_TAG} > /dev/null 2>&1; then
    echo "⚠️  基础镜像 ${BASE_IMAGE_NAME}:${BASE_TAG} 不存在"
    echo "🔧 请先运行 ./build-base.sh 构建基础镜像"
    echo "💡 或者使用 ./build-full.sh 进行完整构建"
    exit 1
fi

echo "🚀 基于基础镜像快速构建 ${IMAGE_NAME}:${VERSION}..."
echo "📦 使用基础镜像: ${BASE_IMAGE_NAME}:${BASE_TAG}"

# 启用 BuildKit 以支持缓存挂载
export DOCKER_BUILDKIT=1

# 使用优化的 Dockerfile 进行快速构建
docker build \
    --progress=plain \
    --build-arg BASE_VERSION=${VERSION} \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION} \
    --build-arg CLAUDE_ROUTER_VERSION=${CLAUDE_ROUTER_VERSION} \
    -f Dockerfile.optimized \
    -t ${IMAGE_NAME}:${VERSION} .

echo "✅ 快速构建完成！"
echo "📝 镜像版本: ${IMAGE_NAME}:${VERSION}"
echo "⚡ 构建时间大大缩短（基于预构建基础镜像）"
echo "🎯 使用 ./start.sh 启动容器"
