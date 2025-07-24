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

echo "🏗️  构建基础镜像: ${BASE_IMAGE_NAME}:${BASE_TAG}..."

# 启用 BuildKit 以支持缓存挂载
export DOCKER_BUILDKIT=1

# 构建基础镜像
docker build \
    --progress=plain \
    --build-arg NODE_VERSION=${NODE_VERSION} \
    --build-arg CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION} \
    --build-arg CLAUDE_ROUTER_VERSION=${CLAUDE_ROUTER_VERSION} \
    -f Dockerfile.base \
    -t ${BASE_IMAGE_NAME}:${BASE_TAG} \
    .

echo "✅ 基础镜像构建完成！"
echo "📝 基础镜像: ${BASE_IMAGE_NAME}:${BASE_TAG}"
echo "📝 Node.js: ${NODE_VERSION}"
echo "📝 Claude Code: ${CLAUDE_CODE_VERSION}"
echo "📝 Claude Router: ${CLAUDE_ROUTER_VERSION}"
echo ""
echo "💡 提示："
echo "   基础镜像包含了所有稳定依赖，通常只需要构建一次"
echo "   后续使用 ./build.sh 构建业务镜像会非常快速"
