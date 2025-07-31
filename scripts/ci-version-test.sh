#!/bin/bash

# CI/CD 版本一致性测试脚本
# 用于持续集成环境中的自动化版本验证

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"

# 创建测试结果目录
mkdir -p "$TEST_RESULTS_DIR"

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1"
}

# 运行版本一致性测试
run_version_consistency_test() {
    log_info "运行版本一致性测试..."
    
    cd "$PROJECT_ROOT"
    
    if [ ! -f "test-version-consistency.sh" ]; then
        log_error "版本一致性测试脚本不存在"
        return 1
    fi
    
    # 运行测试并捕获输出
    local test_output_file="$TEST_RESULTS_DIR/version-consistency-$(date '+%Y%m%d-%H%M%S').log"
    
    if ./test-version-consistency.sh > "$test_output_file" 2>&1; then
        log_success "版本一致性测试通过"
        
        # 复制报告到测试结果目录
        if [ -f "version-consistency-test-report.txt" ]; then
            cp "version-consistency-test-report.txt" "$TEST_RESULTS_DIR/"
        fi
        
        return 0
    else
        log_error "版本一致性测试失败"
        
        # 显示测试输出的最后几行
        echo "测试输出的最后 20 行："
        tail -20 "$test_output_file"
        
        # 复制失败报告
        if [ -f "version-consistency-test-report.txt" ]; then
            cp "version-consistency-test-report.txt" "$TEST_RESULTS_DIR/failed-report-$(date '+%Y%m%d-%H%M%S').txt"
        fi
        
        return 1
    fi
}

# 验证构建脚本语法
validate_build_scripts() {
    log_info "验证构建脚本语法..."
    
    local scripts=("build-base.sh" "build.sh" "build-full.sh")
    local failed_scripts=()
    
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_ROOT/$script" ]; then
            if bash -n "$PROJECT_ROOT/$script"; then
                log_success "✅ $script 语法正确"
            else
                log_error "❌ $script 语法错误"
                failed_scripts+=("$script")
            fi
        else
            log_error "❌ $script 文件不存在"
            failed_scripts+=("$script")
        fi
    done
    
    if [ ${#failed_scripts[@]} -gt 0 ]; then
        log_error "以下脚本验证失败: ${failed_scripts[*]}"
        return 1
    fi
    
    return 0
}

# 检查 versions.env 文件
check_versions_env() {
    log_info "检查 versions.env 文件..."
    
    if [ ! -f "$PROJECT_ROOT/versions.env" ]; then
        log_error "versions.env 文件不存在"
        return 1
    fi
    
    # 检查文件是否可读
    if [ ! -r "$PROJECT_ROOT/versions.env" ]; then
        log_error "versions.env 文件不可读"
        return 1
    fi
    
    # 检查必需变量
    local required_vars=("NODE_VERSION" "CLAUDE_CODE_VERSION" "CLAUDE_ROUTER_VERSION" "VERSION" "IMAGE_NAME")
    local missing_vars=()
    
    source "$PROJECT_ROOT/versions.env"
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "versions.env 缺少必需变量: ${missing_vars[*]}"
        return 1
    fi
    
    log_success "versions.env 文件检查通过"
    return 0
}

# 生成 JUnit XML 格式的测试报告
generate_junit_report() {
    local test_name="$1"
    local test_result="$2"
    local test_time="$3"
    local error_message="$4"
    
    local junit_file="$TEST_RESULTS_DIR/junit-version-test.xml"
    
    if [ ! -f "$junit_file" ]; then
        cat > "$junit_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="VersionConsistencyTests" tests="0" failures="0" errors="0" time="0">
EOF
    fi
    
    # 移除结束标签
    sed -i '' '/<\/testsuite>/d' "$junit_file"
    sed -i '' '/<\/testsuites>/d' "$junit_file"
    
    # 添加测试用例
    if [ "$test_result" = "PASS" ]; then
        cat >> "$junit_file" << EOF
    <testcase name="$test_name" time="$test_time"/>
EOF
    else
        cat >> "$junit_file" << EOF
    <testcase name="$test_name" time="$test_time">
      <failure message="$error_message"/>
    </testcase>
EOF
    fi
    
    # 添加结束标签
    cat >> "$junit_file" << EOF
  </testsuite>
</testsuites>
EOF
}

# 主函数
main() {
    log_info "开始 CI/CD 版本一致性测试..."
    log_info "项目根目录: $PROJECT_ROOT"
    log_info "测试结果目录: $TEST_RESULTS_DIR"
    
    local start_time=$(date +%s)
    local overall_result=0
    
    # 1. 检查 versions.env 文件
    local check_start=$(date +%s)
    if check_versions_env; then
        local check_time=$(($(date +%s) - check_start))
        generate_junit_report "check_versions_env" "PASS" "$check_time" ""
    else
        local check_time=$(($(date +%s) - check_start))
        generate_junit_report "check_versions_env" "FAIL" "$check_time" "versions.env file validation failed"
        overall_result=1
    fi
    
    # 2. 验证构建脚本语法
    local syntax_start=$(date +%s)
    if validate_build_scripts; then
        local syntax_time=$(($(date +%s) - syntax_start))
        generate_junit_report "validate_build_scripts" "PASS" "$syntax_time" ""
    else
        local syntax_time=$(($(date +%s) - syntax_start))
        generate_junit_report "validate_build_scripts" "FAIL" "$syntax_time" "Build script syntax validation failed"
        overall_result=1
    fi
    
    # 3. 运行版本一致性测试
    local test_start=$(date +%s)
    if run_version_consistency_test; then
        local test_time=$(($(date +%s) - test_start))
        generate_junit_report "version_consistency_test" "PASS" "$test_time" ""
    else
        local test_time=$(($(date +%s) - test_start))
        generate_junit_report "version_consistency_test" "FAIL" "$test_time" "Version consistency test failed"
        overall_result=1
    fi
    
    local total_time=$(($(date +%s) - start_time))
    
    if [ $overall_result -eq 0 ]; then
        log_success "🎉 所有 CI/CD 测试通过！总耗时: ${total_time}s"
        
        # 创建成功标记文件
        echo "SUCCESS" > "$TEST_RESULTS_DIR/ci-test-result.txt"
        echo "$(date '+%Y-%m-%d %H:%M:%S')" >> "$TEST_RESULTS_DIR/ci-test-result.txt"
        echo "Total time: ${total_time}s" >> "$TEST_RESULTS_DIR/ci-test-result.txt"
    else
        log_error "❌ CI/CD 测试失败！总耗时: ${total_time}s"
        
        # 创建失败标记文件
        echo "FAILURE" > "$TEST_RESULTS_DIR/ci-test-result.txt"
        echo "$(date '+%Y-%m-%d %H:%M:%S')" >> "$TEST_RESULTS_DIR/ci-test-result.txt"
        echo "Total time: ${total_time}s" >> "$TEST_RESULTS_DIR/ci-test-result.txt"
    fi
    
    log_info "测试结果已保存到: $TEST_RESULTS_DIR"
    
    exit $overall_result
}

# 运行主函数
main "$@"