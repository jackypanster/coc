#!/bin/bash

# 版本一致性测试脚本
# 用于验证 versions.env 和构建结果的版本一致性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试结果记录
TEST_RESULTS=()

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 测试结果记录函数
record_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "✅ $test_name"
        TEST_RESULTS+=("PASS: $test_name")
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "❌ $test_name"
        if [ -n "$details" ]; then
            log_error "   详情: $details"
        fi
        TEST_RESULTS+=("FAIL: $test_name - $details")
    fi
}

# 备份原始文件
backup_original_files() {
    log_info "备份原始配置文件..."
    
    if [ -f "versions.env" ]; then
        cp versions.env versions.env.backup
        log_info "已备份 versions.env -> versions.env.backup"
    fi
}

# 恢复原始文件
restore_original_files() {
    log_info "恢复原始配置文件..."
    
    if [ -f "versions.env.backup" ]; then
        mv versions.env.backup versions.env
        log_info "已恢复 versions.env"
    fi
    
    # 清理测试文件
    rm -f versions.env.test versions.env.invalid versions.env.missing-vars
}

# 创建测试用的 versions.env 文件
create_test_versions_file() {
    local filename="$1"
    local content="$2"
    
    echo "$content" > "$filename"
}

# 验证 versions.env 文件格式
test_versions_env_format() {
    log_info "测试 1: 验证 versions.env 文件格式"
    
    if [ ! -f "versions.env" ]; then
        record_test_result "versions.env 文件存在性检查" "FAIL" "文件不存在"
        return
    fi
    
    record_test_result "versions.env 文件存在性检查" "PASS"
    
    # 检查必需变量
    local required_vars=("NODE_VERSION" "CLAUDE_CODE_VERSION" "CLAUDE_ROUTER_VERSION" "VERSION" "IMAGE_NAME")
    local missing_vars=()
    
    source ./versions.env
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        record_test_result "必需变量完整性检查" "FAIL" "缺失变量: ${missing_vars[*]}"
    else
        record_test_result "必需变量完整性检查" "PASS"
    fi
    
    # 验证版本格式
    if [[ ! $NODE_VERSION =~ ^[0-9]+$ ]]; then
        record_test_result "NODE_VERSION 格式验证" "FAIL" "无效格式: $NODE_VERSION"
    else
        record_test_result "NODE_VERSION 格式验证" "PASS"
    fi
    
    if [[ ! $CLAUDE_CODE_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        record_test_result "CLAUDE_CODE_VERSION 格式验证" "FAIL" "无效格式: $CLAUDE_CODE_VERSION"
    else
        record_test_result "CLAUDE_CODE_VERSION 格式验证" "PASS"
    fi
    
    if [[ ! $CLAUDE_ROUTER_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        record_test_result "CLAUDE_ROUTER_VERSION 格式验证" "FAIL" "无效格式: $CLAUDE_ROUTER_VERSION"
    else
        record_test_result "CLAUDE_ROUTER_VERSION 格式验证" "PASS"
    fi
    
    if [[ ! $IMAGE_NAME =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
        record_test_result "IMAGE_NAME 格式验证" "FAIL" "无效格式: $IMAGE_NAME"
    else
        record_test_result "IMAGE_NAME 格式验证" "PASS"
    fi
}

# 测试缺失文件场景
test_missing_file_scenario() {
    log_info "测试 2: 缺失文件场景"
    
    # 临时移动 versions.env
    if [ -f "versions.env" ]; then
        mv versions.env versions.env.temp
    fi
    
    # 测试构建脚本行为
    if ./build-base.sh > /dev/null 2>&1; then
        record_test_result "缺失文件时构建脚本行为" "FAIL" "应该失败但成功了"
    else
        record_test_result "缺失文件时构建脚本行为" "PASS"
    fi
    
    # 恢复文件
    if [ -f "versions.env.temp" ]; then
        mv versions.env.temp versions.env
    fi
}

# 测试无效格式场景
test_invalid_format_scenarios() {
    log_info "测试 3: 无效格式场景"
    
    # 备份原始文件
    cp versions.env versions.env.temp
    
    # 测试无效的 NODE_VERSION
    create_test_versions_file "versions.env" "
# Docker 镜像版本
VERSION=v1.0.0
IMAGE_NAME=cloud-code-dev

# NPM 包版本
CLAUDE_CODE_VERSION=1.0.64
CLAUDE_ROUTER_VERSION=1.0.31

# Node.js 版本 - 无效格式
NODE_VERSION=v20
"
    
    if ./build-base.sh > /dev/null 2>&1; then
        record_test_result "无效 NODE_VERSION 格式检测" "FAIL" "应该失败但成功了"
    else
        record_test_result "无效 NODE_VERSION 格式检测" "PASS"
    fi
    
    # 测试无效的语义版本
    create_test_versions_file "versions.env" "
# Docker 镜像版本
VERSION=v1.0.0
IMAGE_NAME=cloud-code-dev

# NPM 包版本 - 无效格式
CLAUDE_CODE_VERSION=1.0
CLAUDE_ROUTER_VERSION=1.0.31

# Node.js 版本
NODE_VERSION=20
"
    
    if ./build-base.sh > /dev/null 2>&1; then
        record_test_result "无效语义版本格式检测" "FAIL" "应该失败但成功了"
    else
        record_test_result "无效语义版本格式检测" "PASS"
    fi
    
    # 测试无效的镜像名称
    create_test_versions_file "versions.env" "
# Docker 镜像版本
VERSION=v1.0.0
IMAGE_NAME=Invalid-Name-With-CAPS

# NPM 包版本
CLAUDE_CODE_VERSION=1.0.64
CLAUDE_ROUTER_VERSION=1.0.31

# Node.js 版本
NODE_VERSION=20
"
    
    if ./build-base.sh > /dev/null 2>&1; then
        record_test_result "无效镜像名称格式检测" "FAIL" "应该失败但成功了"
    else
        record_test_result "无效镜像名称格式检测" "PASS"
    fi
    
    # 恢复原始文件
    mv versions.env.temp versions.env
}

# 测试缺失变量场景
test_missing_variables_scenario() {
    log_info "测试 4: 缺失变量场景"
    
    # 备份原始文件
    cp versions.env versions.env.temp
    
    # 创建缺失变量的配置文件
    create_test_versions_file "versions.env" "
# Docker 镜像版本
VERSION=v1.0.0
IMAGE_NAME=cloud-code-dev

# NPM 包版本 - 缺失 CLAUDE_ROUTER_VERSION
CLAUDE_CODE_VERSION=1.0.64

# Node.js 版本
NODE_VERSION=20
"
    
    if ./build-base.sh > /dev/null 2>&1; then
        record_test_result "缺失变量检测" "FAIL" "应该失败但成功了"
    else
        record_test_result "缺失变量检测" "PASS"
    fi
    
    # 恢复原始文件
    mv versions.env.temp versions.env
}

# 测试构建结果版本一致性
test_build_version_consistency() {
    log_info "测试 5: 构建结果版本一致性"
    
    # 确保有有效的 versions.env
    if [ ! -f "versions.env" ]; then
        record_test_result "构建版本一致性测试" "FAIL" "versions.env 文件不存在"
        return
    fi
    
    source ./versions.env
    
    # 检查基础镜像是否存在
    BASE_IMAGE_NAME="code-on-cloud-base"
    BASE_TAG="${VERSION}"
    
    if docker image inspect ${BASE_IMAGE_NAME}:${BASE_TAG} > /dev/null 2>&1; then
        log_info "发现基础镜像: ${BASE_IMAGE_NAME}:${BASE_TAG}"
        
        # 检查镜像中的版本信息
        local node_version_in_image=$(docker run --rm ${BASE_IMAGE_NAME}:${BASE_TAG} node --version | sed 's/v//')
        local expected_node_version="${NODE_VERSION}"
        
        # 比较主版本号（因为 Node.js 版本可能包含补丁版本）
        local node_major_in_image=$(echo $node_version_in_image | cut -d. -f1)
        
        if [ "$node_major_in_image" = "$expected_node_version" ]; then
            record_test_result "镜像中 Node.js 版本一致性" "PASS"
        else
            record_test_result "镜像中 Node.js 版本一致性" "FAIL" "期望: $expected_node_version, 实际: $node_major_in_image"
        fi
        
        # 检查环境变量
        local claude_code_version_in_image=$(docker run --rm ${BASE_IMAGE_NAME}:${BASE_TAG} printenv CLAUDE_CODE_VERSION)
        local claude_router_version_in_image=$(docker run --rm ${BASE_IMAGE_NAME}:${BASE_TAG} printenv CLAUDE_ROUTER_VERSION)
        
        if [ "$claude_code_version_in_image" = "$CLAUDE_CODE_VERSION" ]; then
            record_test_result "镜像中 CLAUDE_CODE_VERSION 一致性" "PASS"
        else
            record_test_result "镜像中 CLAUDE_CODE_VERSION 一致性" "FAIL" "期望: $CLAUDE_CODE_VERSION, 实际: $claude_code_version_in_image"
        fi
        
        if [ "$claude_router_version_in_image" = "$CLAUDE_ROUTER_VERSION" ]; then
            record_test_result "镜像中 CLAUDE_ROUTER_VERSION 一致性" "PASS"
        else
            record_test_result "镜像中 CLAUDE_ROUTER_VERSION 一致性" "FAIL" "期望: $CLAUDE_ROUTER_VERSION, 实际: $claude_router_version_in_image"
        fi
        
    else
        log_warning "基础镜像不存在，跳过镜像版本一致性测试"
        record_test_result "基础镜像存在性检查" "FAIL" "镜像 ${BASE_IMAGE_NAME}:${BASE_TAG} 不存在"
    fi
}

# 测试所有构建脚本的版本处理
test_all_build_scripts() {
    log_info "测试 6: 所有构建脚本的版本处理"
    
    # 测试 build-base.sh
    if [ -f "build-base.sh" ] && [ -x "build-base.sh" ]; then
        # 检查脚本是否包含版本验证逻辑
        if grep -q "validate_all_versions" build-base.sh; then
            record_test_result "build-base.sh 包含版本验证" "PASS"
        else
            record_test_result "build-base.sh 包含版本验证" "FAIL" "缺少版本验证函数"
        fi
        
        if grep -q "source.*versions.env" build-base.sh; then
            record_test_result "build-base.sh 加载版本配置" "PASS"
        else
            record_test_result "build-base.sh 加载版本配置" "FAIL" "未找到版本配置加载"
        fi
    else
        record_test_result "build-base.sh 可执行性检查" "FAIL" "文件不存在或不可执行"
    fi
    
    # 测试 build.sh
    if [ -f "build.sh" ] && [ -x "build.sh" ]; then
        if grep -q "source.*versions.env" build.sh; then
            record_test_result "build.sh 加载版本配置" "PASS"
        else
            record_test_result "build.sh 加载版本配置" "FAIL" "未找到版本配置加载"
        fi
    else
        record_test_result "build.sh 可执行性检查" "FAIL" "文件不存在或不可执行"
    fi
    
    # 测试 build-full.sh
    if [ -f "build-full.sh" ] && [ -x "build-full.sh" ]; then
        if grep -q "source.*versions.env" build-full.sh; then
            record_test_result "build-full.sh 加载版本配置" "PASS"
        else
            record_test_result "build-full.sh 加载版本配置" "FAIL" "未找到版本配置加载"
        fi
    else
        record_test_result "build-full.sh 可执行性检查" "FAIL" "文件不存在或不可执行"
    fi
}

# 测试 Dockerfile.base 版本参数
test_dockerfile_version_args() {
    log_info "测试 7: Dockerfile.base 版本参数"
    
    if [ ! -f "Dockerfile.base" ]; then
        record_test_result "Dockerfile.base 存在性检查" "FAIL" "文件不存在"
        return
    fi
    
    record_test_result "Dockerfile.base 存在性检查" "PASS"
    
    # 检查是否移除了硬编码默认值
    local args_with_defaults=$(grep -c "ARG.*=" Dockerfile.base || true)
    
    if [ "$args_with_defaults" -gt 0 ]; then
        record_test_result "Dockerfile.base 移除硬编码默认值" "FAIL" "发现 $args_with_defaults 个带默认值的 ARG"
    else
        record_test_result "Dockerfile.base 移除硬编码默认值" "PASS"
    fi
    
    # 检查必需的 ARG 声明
    local required_args=("NODE_VERSION" "CLAUDE_CODE_VERSION" "CLAUDE_ROUTER_VERSION")
    
    for arg in "${required_args[@]}"; do
        if grep -q "ARG $arg" Dockerfile.base; then
            record_test_result "Dockerfile.base ARG $arg 声明" "PASS"
        else
            record_test_result "Dockerfile.base ARG $arg 声明" "FAIL" "缺少 ARG 声明"
        fi
    done
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    local report_file="version-consistency-test-report.txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$report_file" << EOF
版本一致性测试报告
==================

测试时间: $timestamp
测试环境: $(uname -s) $(uname -r)
Docker 版本: $(docker --version)

测试统计
--------
总测试数: $TOTAL_TESTS
通过测试: $PASSED_TESTS
失败测试: $FAILED_TESTS
成功率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%

详细结果
--------
EOF
    
    for result in "${TEST_RESULTS[@]}"; do
        echo "$result" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

建议
----
EOF
    
    if [ $FAILED_TESTS -gt 0 ]; then
        cat >> "$report_file" << EOF
❌ 发现 $FAILED_TESTS 个失败的测试，建议：
1. 检查 versions.env 文件格式是否正确
2. 确保所有构建脚本都正确加载版本配置
3. 验证 Dockerfile.base 是否移除了硬编码默认值
4. 重新构建基础镜像以确保版本一致性
EOF
    else
        cat >> "$report_file" << EOF
✅ 所有测试通过！版本管理系统工作正常。
EOF
    fi
    
    log_success "测试报告已生成: $report_file"
}

# 主测试函数
main() {
    echo "========================================"
    echo "        版本一致性测试套件"
    echo "========================================"
    echo ""
    
    log_info "开始版本一致性测试..."
    
    # 备份原始文件
    backup_original_files
    
    # 执行所有测试
    test_versions_env_format
    test_missing_file_scenario
    test_invalid_format_scenarios
    test_missing_variables_scenario
    test_build_version_consistency
    test_all_build_scripts
    test_dockerfile_version_args
    
    # 恢复原始文件
    restore_original_files
    
    # 生成报告
    generate_test_report
    
    echo ""
    echo "========================================"
    echo "           测试结果摘要"
    echo "========================================"
    echo ""
    log_info "总测试数: $TOTAL_TESTS"
    log_success "通过测试: $PASSED_TESTS"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        log_error "失败测试: $FAILED_TESTS"
        echo ""
        log_error "测试失败！请查看详细报告: version-consistency-test-report.txt"
        exit 1
    else
        log_success "失败测试: $FAILED_TESTS"
        echo ""
        log_success "🎉 所有测试通过！版本管理系统工作正常。"
        exit 0
    fi
}

# 运行主函数
main "$@"