#!/bin/bash

# 设置代码质量自动化工具
# 包括 cron 任务和 git hooks
# 用法: ./scripts/setup-cron.sh

PROJECT_ROOT=$(pwd)
SCRIPT_PATH="$PROJECT_ROOT/scripts/review-reminder.js"

echo "🚀 Setting up code quality automation tools..."

# 检查脚本是否存在
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: review-reminder.js not found at $SCRIPT_PATH"
    exit 1
fi

# 确保脚本可执行
chmod +x "$SCRIPT_PATH"

# 1. 设置 Git Hooks
echo ""
echo "🔧 Setting up Git hooks..."

# 检查是否已经配置了 git hooks 路径
CURRENT_HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || echo "")

if [ "$CURRENT_HOOKS_PATH" != ".githooks" ]; then
    git config core.hooksPath .githooks
    echo "✅ Git hooks path configured to .githooks"
else
    echo "✅ Git hooks path already configured"
fi

# 确保 hooks 可执行
if [ -f ".githooks/pre-commit" ]; then
    chmod +x .githooks/pre-commit
    echo "✅ Pre-commit hook configured"
else
    echo "⚠️  Pre-commit hook not found"
fi

# 2. 设置 Cron 任务
echo ""
echo "⏰ Setting up automated review reminders..."

# 创建 cron 任务
CRON_JOB="0 9 * * 1 cd $PROJECT_ROOT && node scripts/review-reminder.js >> /tmp/code-review-reminder.log 2>&1"

# 检查是否已经存在相同的 cron 任务
if crontab -l 2>/dev/null | grep -q "review-reminder.js"; then
    echo "⚠️  Cron job already exists. Updating..."
    # 移除旧的任务
    crontab -l 2>/dev/null | grep -v "review-reminder.js" | crontab -
fi

# 添加新的 cron 任务
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "✅ Cron job added successfully!"
echo "📅 Schedule: Every Monday at 9:00 AM"
echo "📝 Log file: /tmp/code-review-reminder.log"

# 3. 验证设置
echo ""
echo "🔍 Verifying setup..."

# 检查 Git hooks
if git config core.hooksPath | grep -q ".githooks"; then
    echo "✅ Git hooks: Configured"
else
    echo "❌ Git hooks: Not configured"
fi

# 检查 Cron 任务
if crontab -l 2>/dev/null | grep -q "review-reminder.js"; then
    echo "✅ Cron job: Configured"
else
    echo "❌ Cron job: Not configured"
fi

# 检查依赖
if [ -d "login/node_modules" ]; then
    echo "✅ Dependencies: Installed"
else
    echo "⚠️  Dependencies: Not installed (run 'cd login && npm install')"
fi

# 4. 显示使用说明
echo ""
echo "📚 Usage Instructions:"
echo ""
echo "Manual Commands:"
echo "  node scripts/review-reminder.js           # Check if review is needed"
echo "  node scripts/review-reminder.js --force   # Force review reminder"
echo "  node scripts/quality-dashboard.js         # Generate quality report"
echo "  cd login && npm run quality-check         # Run all quality checks"
echo ""
echo "Git Integration:"
echo "  git commit                                 # Triggers pre-commit checks"
echo "  git commit --no-verify                    # Bypass pre-commit checks (not recommended)"
echo ""
echo "Automation:"
echo "  • Pre-commit hooks run automatically on 'git commit'"
echo "  • Review reminders run every Monday at 9:00 AM"
echo "  • CI/CD quality checks run on push/PR"
echo ""
echo "Configuration Files:"
echo "  • .quality-config.json                    # Quality standards"
echo "  • .kiro/review-process.md                 # Review process documentation"
echo "  • login/.eslintrc.js                      # ESLint configuration"
echo ""
echo "To remove automation:"
echo "  git config --unset core.hooksPath         # Remove git hooks"
echo "  crontab -l | grep -v 'review-reminder.js' | crontab -  # Remove cron job"