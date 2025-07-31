#!/bin/bash

set -e

# 显示版本格式帮助信息
show_version_format_help() {
    echo ""
    echo "📋 版本格式要求："
    echo "   NODE_VERSION: 有效的 Node.js 版本号 (数字)"
    echo "     ✅ 正确示例: 20, 18, 16"
    echo "     ❌ 错误示例: v20, 20.0, latest"
    echo ""
    echo "   CLAUDE_CODE_VERSION: 语义版本格式 (x.y.z)"
    echo "     ✅ 正确示例: 1.0.64, 2.1.0, 0.9.15"
    echo "     ❌ 错误示例: v1.0.64, 1.0, 1.0.64-beta"
    echo ""
    echo "   CLAUDE_ROUTER_VERSION: 语义版本格式 (x.y.z)"
    echo "     ✅ 正确示例: 1.0.31, 2.0.0, 0.8.5"
    echo "     ❌ 错误示例: v1.0.31, 1.0, 1.0.31-alpha"
    echo ""
    echo "   VERSION: 版本标签 (通常以 v 开头)"
    echo "     ✅ 正确示例: v1.0.0, v2.1.3, v0.9.0"
    echo ""
    echo "   IMAGE_NAME: Docker 镜像名称"
    echo "     ✅ 正确示例: cloud-code-dev, my-app, service-name"
    echo "     ❌ 错误示例: 包含大写字母或特殊字符"
}

# 显示修复建议
show_repair_suggestions() {
    local error_type=$1
    local var_name=$2
    local current_value=$3
    
    echo ""
    echo "🔧 修复建议："
    
    case $error_type in
        "missing_file")
            echo "   1. 在项目根目录创建 versions.env 文件"
            echo "   2. 复制以下模板内容到文件中："
            echo ""
            echo "      # Docker 镜像版本"
            echo "      VERSION=v1.0.0"
            echo "      IMAGE_NAME=cloud-code-dev"
            echo ""
            echo "      # NPM 包版本"
            echo "      CLAUDE_CODE_VERSION=1.0.64"
            echo "      CLAUDE_ROUTER_VERSION=1.0.31"
            echo ""
            echo "      # Node.js 版本"
            echo "      NODE_VERSION=20"
            echo ""
            echo "   3. 根据实际需要调整版本号"
            ;;
        "missing_vars")
            echo "   1. 打开 versions.env 文件"
            echo "   2. 添加缺失的变量到文件中"
            echo "   3. 确保每个变量都有正确的值"
            echo "   4. 保存文件后重新运行构建"
            ;;
        "invalid_node_version")
            echo "   1. 打开 versions.env 文件"
            echo "   2. 将 $var_name 修改为有效的数字"
            echo "   3. 推荐的 Node.js 版本: 18, 20, 22"
            echo "   4. 当前无效值: '$current_value'"
            echo "   5. 修复示例: $var_name=20"
            ;;
        "invalid_semantic_version")
            echo "   1. 打开 versions.env 文件"
            echo "   2. 将 $var_name 修改为 x.y.z 格式"
            echo "   3. 确保每个部分都是数字"
            echo "   4. 当前无效值: '$current_value'"
            echo "   5. 修复示例: $var_name=1.0.64"
            ;;
        "invalid_image_name")
            echo "   1. 打开 versions.env 文件"
            echo "   2. 确保 $var_name 只包含小写字母、数字和连字符"
            echo "   3. 不能以连字符开头或结尾"
            echo "   4. 当前无效值: '$current_value'"
            echo "   5. 修复示例: $var_name=cloud-code-dev"
            ;;
    esac
}

# 版本验证函数
validate_node_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+$ ]]; then
        echo "❌ NODE_VERSION 格式错误"
        echo "   当前值: '$version'"
        echo "   要求: 必须是有效的数字"
        echo "   常用版本: 16, 18, 20, 22"
        show_repair_suggestions "invalid_node_version" "NODE_VERSION" "$version"
        return 1
    fi
    
    # 检查是否是常见的 Node.js 版本
    if [[ $version -lt 16 ]]; then
        echo "⚠️  警告: NODE_VERSION=$version 可能过旧"
        echo "   推荐使用 Node.js 16 或更高版本"
        echo "   当前 LTS 版本: 18, 20"
    fi
    
    return 0
}

validate_semantic_version() {
    local version=$1
    local var_name=$2
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ $var_name 格式错误"
        echo "   当前值: '$version'"
        echo "   要求: 必须符合语义版本格式 (x.y.z)"
        echo "   每个部分必须是数字，用点分隔"
        show_repair_suggestions "invalid_semantic_version" "$var_name" "$version"
        return 1
    fi
    return 0
}

validate_image_name() {
    local name=$1
    if [[ ! $name =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
        echo "❌ IMAGE_NAME 格式错误"
        echo "   当前值: '$name'"
        echo "   要求: 只能包含小写字母、数字和连字符"
        echo "   不能以连字符开头或结尾"
        show_repair_suggestions "invalid_image_name" "IMAGE_NAME" "$name"
        return 1
    fi
    return 0
}

validate_required_variables() {
    local missing_vars=()
    local empty_vars=()
    
    # 检查必需的版本变量是否存在且非空
    [ -z "$NODE_VERSION" ] && missing_vars+=("NODE_VERSION")
    [ -z "$CLAUDE_CODE_VERSION" ] && missing_vars+=("CLAUDE_CODE_VERSION")
    [ -z "$CLAUDE_ROUTER_VERSION" ] && missing_vars+=("CLAUDE_ROUTER_VERSION")
    [ -z "$VERSION" ] && missing_vars+=("VERSION")
    [ -z "$IMAGE_NAME" ] && missing_vars+=("IMAGE_NAME")
    
    # 检查变量是否为空字符串
    [ -n "$NODE_VERSION" ] && [ "$NODE_VERSION" = "" ] && empty_vars+=("NODE_VERSION")
    [ -n "$CLAUDE_CODE_VERSION" ] && [ "$CLAUDE_CODE_VERSION" = "" ] && empty_vars+=("CLAUDE_CODE_VERSION")
    [ -n "$CLAUDE_ROUTER_VERSION" ] && [ "$CLAUDE_ROUTER_VERSION" = "" ] && empty_vars+=("CLAUDE_ROUTER_VERSION")
    [ -n "$VERSION" ] && [ "$VERSION" = "" ] && empty_vars+=("VERSION")
    [ -n "$IMAGE_NAME" ] && [ "$IMAGE_NAME" = "" ] && empty_vars+=("IMAGE_NAME")
    
    if [ ${#missing_vars[@]} -gt 0 ] || [ ${#empty_vars[@]} -gt 0 ]; then
        echo "❌ versions.env 配置错误"
        
        if [ ${#missing_vars[@]} -gt 0 ]; then
            echo ""
            echo "   缺少以下必需的版本变量:"
            for var in "${missing_vars[@]}"; do
                echo "     - $var"
            done
        fi
        
        if [ ${#empty_vars[@]} -gt 0 ]; then
            echo ""
            echo "   以下变量值为空:"
            for var in "${empty_vars[@]}"; do
                echo "     - $var"
            done
        fi
        
        show_version_format_help
        show_repair_suggestions "missing_vars"
        return 1
    fi
    return 0
}

validate_all_versions() {
    echo "🔍 验证版本配置..."
    echo "   文件: versions.env"
    echo ""
    
    # 验证必需变量存在
    if ! validate_required_variables; then
        return 1
    fi
    
    # 验证 NODE_VERSION 格式
    echo "🔍 验证 NODE_VERSION..."
    if ! validate_node_version "$NODE_VERSION"; then
        return 1
    fi
    echo "   ✅ NODE_VERSION=$NODE_VERSION (有效)"
    
    # 验证语义版本格式
    echo "🔍 验证 CLAUDE_CODE_VERSION..."
    if ! validate_semantic_version "$CLAUDE_CODE_VERSION" "CLAUDE_CODE_VERSION"; then
        return 1
    fi
    echo "   ✅ CLAUDE_CODE_VERSION=$CLAUDE_CODE_VERSION (有效)"
    
    echo "🔍 验证 CLAUDE_ROUTER_VERSION..."
    if ! validate_semantic_version "$CLAUDE_ROUTER_VERSION" "CLAUDE_ROUTER_VERSION"; then
        return 1
    fi
    echo "   ✅ CLAUDE_ROUTER_VERSION=$CLAUDE_ROUTER_VERSION (有效)"
    
    # 验证镜像名称格式
    echo "🔍 验证 IMAGE_NAME..."
    if ! validate_image_name "$IMAGE_NAME"; then
        return 1
    fi
    echo "   ✅ IMAGE_NAME=$IMAGE_NAME (有效)"
    
    # 验证 VERSION 格式（可选，但提供建议）
    echo "🔍 验证 VERSION..."
    if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "   ⚠️  VERSION=$VERSION (建议使用 vx.y.z 格式，如 v1.0.0)"
    else
        echo "   ✅ VERSION=$VERSION (有效)"
    fi
    
    echo ""
    echo "✅ 所有版本配置验证通过"
    echo "📋 配置摘要:"
    echo "   Node.js: $NODE_VERSION"
    echo "   Claude Code: $CLAUDE_CODE_VERSION"
    echo "   Claude Router: $CLAUDE_ROUTER_VERSION"
    echo "   镜像版本: $VERSION"
    echo "   镜像名称: $IMAGE_NAME"
    echo ""
    return 0
}

# 加载版本配置
if [ ! -f "versions.env" ]; then
    echo "❌ 配置文件缺失"
    echo "   未找到 versions.env 文件"
    echo "   当前目录: $(pwd)"
    echo "   预期位置: $(pwd)/versions.env"
    echo ""
    show_repair_suggestions "missing_file"
    echo ""
    echo "❌ 构建终止: 缺少必需的配置文件"
    exit 1
fi

echo "📁 加载版本配置文件: versions.env"

source ./versions.env

# 验证版本配置
if ! validate_all_versions; then
    echo ""
    echo "❌ 版本验证失败，构建终止"
    echo ""
    echo "🔧 快速修复步骤:"
    echo "   1. 检查 versions.env 文件是否存在"
    echo "   2. 确保所有必需变量都已定义"
    echo "   3. 验证版本号格式是否正确"
    echo "   4. 修复后重新运行: ./build-base.sh"
    echo ""
    echo "📞 需要帮助？查看项目文档或联系开发团队"
    exit 1
fi

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
