# 版本一致性测试系统

## 概述

版本一致性测试系统是为了确保 `versions.env` 文件与 Docker 构建结果之间版本信息一致性而设计的自动化测试套件。该系统包含多个测试脚本和工具，用于验证版本管理的正确性并防止版本不一致问题。

## 系统组件

### 1. 主要测试脚本

#### `test-version-consistency.sh`
完整的版本一致性测试套件，包含以下测试：

- **文件格式验证**: 检查 `versions.env` 文件格式和必需变量
- **错误场景测试**: 测试缺失文件、无效格式、缺失变量等场景
- **构建脚本验证**: 验证所有构建脚本的版本处理逻辑
- **Docker 镜像一致性**: 检查构建结果与配置文件的版本一致性
- **Dockerfile 参数检查**: 验证 Dockerfile.base 是否移除了硬编码默认值

**使用方法**:
```bash
./test-version-consistency.sh
```

**输出**: 
- 控制台测试结果
- `version-consistency-test-report.txt` 详细报告

#### `scripts/ci-version-test.sh`
CI/CD 环境专用的测试脚本，适用于持续集成流程：

- 生成 JUnit XML 格式的测试报告
- 创建测试结果文件用于 CI/CD 系统集成
- 包含构建脚本语法验证
- 支持自动化测试流程

**使用方法**:
```bash
./scripts/ci-version-test.sh
```

**输出**:
- `test-results/junit-version-test.xml` - JUnit 格式报告
- `test-results/ci-test-result.txt` - 测试结果摘要
- `test-results/version-consistency-*.log` - 详细日志

### 2. Git Hooks

#### `.githooks/pre-commit`
Git 预提交钩子，在提交前自动验证版本一致性：

- 检测版本相关文件的更改
- 验证 `versions.env` 格式
- 检查 Dockerfile.base 配置
- 验证构建脚本语法

**安装方法**:
```bash
./scripts/setup-version-hooks.sh
```

**手动安装**:
```bash
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 3. 安装和设置工具

#### `scripts/setup-version-hooks.sh`
自动化安装脚本，用于设置完整的版本一致性测试环境：

- 安装 Git pre-commit hook
- 创建测试结果目录
- 验证安装结果
- 显示使用说明

## 测试覆盖范围

### 1. 版本格式验证

- **NODE_VERSION**: 必须是有效的数字（如：20, 18, 16）
- **CLAUDE_CODE_VERSION**: 必须符合语义版本格式（如：1.0.54）
- **CLAUDE_ROUTER_VERSION**: 必须符合语义版本格式（如：1.0.26）
- **VERSION**: 版本标签格式（如：v1.0.0）
- **IMAGE_NAME**: Docker 镜像名称格式（如：cloud-code-dev）

### 2. 错误场景测试

- **缺失文件**: `versions.env` 文件不存在
- **缺失变量**: 必需的版本变量未定义
- **无效格式**: 版本号格式不符合要求
- **构建失败**: 版本号导致的构建错误

### 3. 构建脚本验证

- **版本加载**: 所有构建脚本正确加载 `versions.env`
- **版本验证**: `build-base.sh` 包含版本验证逻辑
- **语法检查**: 所有脚本语法正确
- **错误处理**: 脚本在错误情况下正确失败

### 4. Docker 配置检查

- **参数声明**: Dockerfile.base 包含所有必需的 ARG 声明
- **无硬编码**: 移除所有硬编码的默认值
- **镜像一致性**: 构建结果与配置文件版本一致

## 使用指南

### 日常开发流程

1. **修改版本配置**:
   ```bash
   # 编辑 versions.env 文件
   vim versions.env
   ```

2. **运行测试验证**:
   ```bash
   # 完整测试
   ./test-version-consistency.sh
   
   # 或者快速 CI 测试
   ./scripts/ci-version-test.sh
   ```

3. **提交更改**:
   ```bash
   git add versions.env
   git commit -m "更新版本配置"
   # pre-commit hook 会自动运行验证
   ```

### CI/CD 集成

在 CI/CD 流程中添加版本一致性检查：

```yaml
# GitHub Actions 示例
- name: 版本一致性测试
  run: ./scripts/ci-version-test.sh

- name: 上传测试报告
  uses: actions/upload-artifact@v2
  if: always()
  with:
    name: test-results
    path: test-results/
```

### 故障排除

#### 常见错误及解决方案

1. **版本格式错误**:
   ```
   错误: NODE_VERSION 格式错误: v20 (应为数字)
   解决: 将 NODE_VERSION=v20 改为 NODE_VERSION=20
   ```

2. **缺失变量**:
   ```
   错误: versions.env 缺少必需变量: CLAUDE_CODE_VERSION
   解决: 在 versions.env 中添加缺失的变量
   ```

3. **硬编码默认值**:
   ```
   错误: Dockerfile.base 包含硬编码默认值
   解决: 移除 ARG 指令中的默认值，如 ARG NODE_VERSION=20 改为 ARG NODE_VERSION
   ```

4. **构建脚本语法错误**:
   ```
   错误: build-base.sh 语法错误
   解决: 使用 bash -n build-base.sh 检查语法问题
   ```

#### 调试技巧

1. **查看详细报告**:
   ```bash
   cat version-consistency-test-report.txt
   ```

2. **检查测试日志**:
   ```bash
   ls test-results/
   cat test-results/version-consistency-*.log
   ```

3. **手动验证版本**:
   ```bash
   source versions.env
   echo "Node: $NODE_VERSION, Claude Code: $CLAUDE_CODE_VERSION"
   ```

4. **跳过 pre-commit 检查**（仅调试时使用）:
   ```bash
   git commit --no-verify -m "临时提交"
   ```

## 测试报告格式

### 控制台输出
```
========================================
        版本一致性测试套件
========================================

[INFO] 开始版本一致性测试...
[SUCCESS] ✅ versions.env 文件存在性检查
[SUCCESS] ✅ 必需变量完整性检查
...
[INFO] 总测试数: 21
[SUCCESS] 通过测试: 21
[SUCCESS] 失败测试: 0
```

### 文本报告
```
版本一致性测试报告
==================

测试时间: 2025-07-31 18:18:02
测试环境: Darwin 24.5.0
Docker 版本: Docker version 28.3.3

测试统计
--------
总测试数: 21
通过测试: 21
失败测试: 0
成功率: 100%

详细结果
--------
PASS: versions.env 文件存在性检查
PASS: 必需变量完整性检查
...
```

### JUnit XML 报告
```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="VersionConsistencyTests" tests="3" failures="0" errors="0" time="2">
    <testcase name="check_versions_env" time="0"/>
    <testcase name="validate_build_scripts" time="1"/>
    <testcase name="version_consistency_test" time="1"/>
  </testsuite>
</testsuites>
```

## 最佳实践

### 1. 版本管理
- 使用语义版本控制（Semantic Versioning）
- 保持版本号格式一致
- 定期验证版本号的有效性

### 2. 测试策略
- 在每次版本更改后运行完整测试
- 在 CI/CD 流程中集成自动化测试
- 使用 pre-commit hook 防止错误提交

### 3. 团队协作
- 确保所有团队成员安装了 pre-commit hook
- 定期更新测试脚本以覆盖新的场景
- 在版本更改时通知相关团队成员

### 4. 监控和维护
- 定期检查测试报告
- 监控 CI/CD 测试结果
- 及时修复发现的版本不一致问题

## 扩展和定制

### 添加新的版本变量
1. 在 `versions.env` 中添加新变量
2. 更新测试脚本中的 `required_vars` 数组
3. 在 Dockerfile.base 中添加相应的 ARG 声明
4. 更新构建脚本以传递新的构建参数

### 添加新的验证规则
1. 在测试脚本中添加新的验证函数
2. 更新 pre-commit hook 以包含新的检查
3. 在 CI 测试中添加相应的测试用例

### 集成其他工具
- 可以将测试结果发送到监控系统
- 集成到代码质量检查工具中
- 添加通知机制（如 Slack、邮件等）

## 技术细节

### 依赖项
- Bash 4.0+
- Docker
- Git
- sed, grep, awk 等标准 Unix 工具

### 兼容性
- macOS (Darwin)
- Linux
- Windows (通过 WSL 或 Git Bash)

### 性能考虑
- 测试脚本运行时间通常在 1-5 秒内
- pre-commit hook 对提交性能影响最小
- CI 测试可以并行运行以提高效率

## 更新日志

### v1.0.0 (2025-07-31)
- 初始版本发布
- 包含完整的测试套件
- 支持 Git pre-commit hook
- 提供 CI/CD 集成支持
- 包含详细的文档和使用指南