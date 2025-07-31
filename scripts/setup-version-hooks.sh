#!/bin/bash

# 设置版本一致性 Git hooks 的脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SETUP]${NC} $1"
}

log_error() {
    echo -e "${RED}[SETUP]${NC} $1"
}

# 获取脚本目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 设置 Git hooks
setup_git_hooks() {
    log_info "设置 Git hooks..."
    
    # 检查是否在 Git 仓库中
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        log_error "当前目录不是 Git 仓库"
        return 1
    fi
    
    # 创建 .git/hooks 目录（如果不存在）
    mkdir -p "$PROJECT_ROOT/.git/hooks"
    
    # 设置 pre-commit hook
    local pre_commit_source="$PROJECT_ROOT/.githooks/pre-commit"
    local pre_commit_target="$PROJECT_ROOT/.git/hooks/pre-commit"
    
    if [ -f "$pre_commit_source" ]; then
        # 备份现有的 pre-commit hook（如果存在）
        if [ -f "$pre_commit_target" ]; then
            log_warning "发现现有的 pre-commit hook，备份为 pre-commit.backup"
            cp "$pre_commit_target" "$pre_commit_target.backup"
        fi
        
        # 复制新的 pre-commit hook
        cp "$pre_commit_source" "$pre_commit_target"
        chmod +x "$pre_commit_target"
        
        log_success "✅ pre-commit hook 已安装"
    else
        log_error "❌ 源文件不存在: $pre_commit_source"
        return 1
    fi
    
    return 0
}

# 验证 hooks 安装
verify_hooks_installation() {
    log_info "验证 hooks 安装..."
    
    local pre_commit_hook="$PROJECT_ROOT/.git/hooks/pre-commit"
    
    if [ -f "$pre_commit_hook" ] && [ -x "$pre_commit_hook" ]; then
        log_success "✅ pre-commit hook 已正确安装并可执行"
        
        # 测试 hook 是否能正常运行
        log_info "测试 pre-commit hook..."
        
        # 创建一个临时的暂存更改来测试 hook
        if git status --porcelain | grep -q "versions.env"; then
            log_info "检测到 versions.env 的更改，测试 hook..."
            
            # 暂存 versions.env 文件
            git add versions.env
            
            # 运行 pre-commit hook
            if "$pre_commit_hook"; then
                log_success "✅ pre-commit hook 测试通过"
            else
                log_warning "⚠️  pre-commit hook 测试失败，但这可能是正常的（取决于当前文件状态）"
            fi
            
            # 取消暂存
            git reset HEAD versions.env
        else
            log_info "没有版本相关文件的更改，跳过 hook 测试"
        fi
        
        return 0
    else
        log_error "❌ pre-commit hook 安装失败或不可执行"
        return 1
    fi
}

# 创建测试结果目录
create_test_directories() {
    log_info "创建测试相关目录..."
    
    local test_dirs=("test-results" "test-results/version-tests")
    
    for dir in "${test_dirs[@]}"; do
        local full_path="$PROJECT_ROOT/$dir"
        if [ ! -d "$full_path" ]; then
            mkdir -p "$full_path"
            log_success "✅ 创建目录: $dir"
        else
            log_info "目录已存在: $dir"
        fi
    done
    
    # 创建 .gitignore 条目（如果需要）
    local gitignore="$PROJECT_ROOT/.gitignore"
    if [ -f "$gitignore" ]; then
        if ! grep -q "test-results/" "$gitignore"; then
            echo "" >> "$gitignore"
            echo "# 测试结果目录" >> "$gitignore"
            echo "test-results/" >> "$gitignore"
            log_success "✅ 已添加 test-results/ 到 .gitignore"
        fi
    fi
}

# 显示使用说明
show_usage_instructions() {
    echo ""
    echo "========================================"
    echo "        版本一致性工具使用说明"
    echo "========================================"
    echo ""
    log_info "已安装的工具："
    echo "   📋 test-version-consistency.sh - 完整的版本一致性测试套件"
    echo "   🔧 scripts/ci-version-test.sh - CI/CD 环境测试脚本"
    echo "   🪝 .git/hooks/pre-commit - Git 预提交检查"
    echo ""
    log_info "使用方法："
    echo "   1. 运行完整测试："
    echo "      ./test-version-consistency.sh"
    echo ""
    echo "   2. 运行 CI/CD 测试："
    echo "      ./scripts/ci-version-test.sh"
    echo ""
    echo "   3. Git 提交时自动检查："
    echo "      git commit -m \"your message\""
    echo "      (pre-commit hook 会自动运行)"
    echo ""
    echo "   4. 跳过 pre-commit 检查（不推荐）："
    echo "      git commit --no-verify -m \"your message\""
    echo ""
    log_info "测试覆盖范围："
    echo "   ✅ versions.env 文件格式验证"
    echo "   ✅ 构建脚本版本处理验证"
    echo "   ✅ Dockerfile.base 硬编码检查"
    echo "   ✅ 构建结果版本一致性验证"
    echo "   ✅ 错误场景测试（缺失文件、无效格式等）"
    echo ""
    log_info "故障排除："
    echo "   - 如果测试失败，查看生成的报告文件"
    echo "   - 确保 versions.env 格式正确"
    echo "   - 验证 Dockerfile.base 没有硬编码默认值"
    echo "   - 检查构建脚本语法"
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "      版本一致性工具安装程序"
    echo "========================================"
    echo ""
    
    log_info "开始设置版本一致性工具..."
    log_info "项目根目录: $PROJECT_ROOT"
    
    local setup_failed=0
    
    # 1. 设置 Git hooks
    if ! setup_git_hooks; then
        setup_failed=1
    fi
    
    # 2. 验证安装
    if ! verify_hooks_installation; then
        setup_failed=1
    fi
    
    # 3. 创建测试目录
    create_test_directories
    
    if [ $setup_failed -eq 1 ]; then
        echo ""
        log_error "❌ 安装过程中出现错误！"
        log_error "请检查上述错误信息并重新运行安装程序"
        exit 1
    fi
    
    echo ""
    log_success "🎉 版本一致性工具安装完成！"
    
    # 显示使用说明
    show_usage_instructions
    
    exit 0
}

# 运行主函数
main "$@"