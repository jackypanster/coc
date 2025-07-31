#!/bin/bash

set -e

# 加载版本配置
if [ ! -f "versions.env" ]; then
    echo "❌ 配置文件缺失"
    echo "   未找到 versions.env 文件"
    echo "   当前目录: $(pwd)"
    echo "   预期位置: $(pwd)/versions.env"
    echo ""
    echo "🔧 修复建议:"
    echo "   1. 确保在项目根目录下运行此脚本"
    echo "   2. 检查 versions.env 文件是否存在"
    echo "   3. 如果文件不存在，请先运行 ./build-base.sh 查看完整的修复指南"
    echo ""
    echo "❌ 构建终止: 缺少必需的配置文件"
    exit 1
fi

echo "📁 加载版本配置文件: versions.env"

source ./versions.env

BASE_IMAGE_NAME="code-on-cloud-base"
BASE_TAG="${VERSION}"

# 检查基础镜像是否存在
echo "🔍 检查基础镜像: ${BASE_IMAGE_NAME}:${BASE_TAG}"
if ! docker image inspect ${BASE_IMAGE_NAME}:${BASE_TAG} > /dev/null 2>&1; then
    echo "❌ 基础镜像缺失"
    echo "   镜像名称: ${BASE_IMAGE_NAME}:${BASE_TAG}"
    echo "   状态: 不存在"
    echo ""
    echo "🔧 修复建议:"
    echo "   选项 1 (推荐): 构建基础镜像"
    echo "     ./build-base.sh"
    echo ""
    echo "   选项 2: 完整构建流程"
    echo "     ./build-full.sh"
    echo ""
    echo "   选项 3: 检查可用的基础镜像"
    echo "     docker images | grep ${BASE_IMAGE_NAME}"
    echo ""
    echo "💡 提示: 基础镜像包含稳定依赖，通常只需构建一次"
    echo ""
    echo "❌ 构建终止: 缺少必需的基础镜像"
    exit 1
fi
echo "   ✅ 基础镜像存在"

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
