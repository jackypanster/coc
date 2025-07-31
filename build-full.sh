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
    echo "   3. 如果文件不存在，请参考项目文档创建配置文件"
    echo ""
    echo "❌ 构建终止: 缺少必需的配置文件"
    exit 1
fi

echo "📁 加载版本配置文件: versions.env"

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
