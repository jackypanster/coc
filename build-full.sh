#!/bin/bash

set -e

# 加载版本配置
if [ ! -f "versions.env" ]; then
    echo "❌ 未找到 versions.env 文件"
    exit 1
fi

source ./versions.env

echo "🏗️  完整构建流程开始..."
echo "📝 镜像版本: ${IMAGE_NAME}:${VERSION}"
echo "📝 Node.js: ${NODE_VERSION}"
echo "📝 Claude Code: ${CLAUDE_CODE_VERSION}"
echo "📝 Claude Router: ${CLAUDE_ROUTER_VERSION}"
echo ""

# 启用 BuildKit 以支持缓存挂载
export DOCKER_BUILDKIT=1

echo "🚀 步骤 1/2: 构建基础镜像..."
./build-base.sh

echo ""
echo "🚀 步骤 2/2: 构建业务镜像..."
./build.sh

echo ""
echo "✅ 完整构建流程完成！"
echo "💡 提示："
echo "   - 基础镜像已缓存，后续只需运行 ./build.sh 即可快速构建"
echo "   - 使用 ./start.sh 启动容器"
