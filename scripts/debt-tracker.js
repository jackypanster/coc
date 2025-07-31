#!/usr/bin/env node

/**
 * 技术债务跟踪和管理工具
 * 用于识别、记录和跟踪技术债务
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class DebtTracker {
  constructor() {
    this.projectRoot = process.cwd();
    this.reportsDir = path.join(this.projectRoot, 'quality-reports');
    this.debtFile = path.join(this.reportsDir, 'technical-debt.json');
    
    // 确保报告目录存在
    if (!fs.existsSync(this.reportsDir)) {
      fs.mkdirSync(this.reportsDir, { recursive: true });
    }
  }

  /**
   * 扫描技术债务
   */
  async scanDebt() {
    console.log('🔍 Scanning for technical debt...\n');
    
    const debt = {
      timestamp: new Date().toISOString(),
      summary: {
        total: 0,
        critical: 0,
        high: 0,
        medium: 0,
        low: 0
      },
      categories: {
        complexity: [],
        duplication: [],
        security: [],
        codeSmells: [],
        architecture: []
      }
    };
    
    // 1. 复杂度债务
    const complexityDebt = await this.scanComplexityDebt();
    debt.categories.complexity = complexityDebt;
    
    // 2. 重复代码债务
    const duplicationDebt = await this.scanDuplicationDebt();
    debt.categories.duplication = duplicationDebt;
    
    // 3. 安全债务
    const securityDebt = await this.scanSecurityDebt();
    debt.categories.security = securityDebt;
    
    // 4. 代码异味债务
    const codeSmellsDebt = await this.scanCodeSmellsDebt();
    debt.categories.codeSmells = codeSmellsDebt;
    
    // 5. 架构债务
    const architectureDebt = await this.scanArchitectureDebt();
    debt.categories.architecture = architectureDebt;
    
    // 计算汇总信息
    this.calculateSummary(debt);
    
    // 保存债务报告
    fs.writeFileSync(this.debtFile, JSON.stringify(debt, null, 2));
    
    // 显示结果
    this.displayDebtSummary(debt);
    
    return debt;
  }

  /**
   * 扫描复杂度相关的技术债务
   */
  async scanComplexityDebt() {
    console.log('📊 Scanning complexity debt...');
    const debt = [];
    
    try {
      execSync('cd login && npm run complexity', { stdio: 'pipe' });
      
      const reportPath = path.join(this.projectRoot, 'login', 'complexity-report.json');
      if (fs.existsSync(reportPath)) {
        const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        
        report.forEach(file => {
          if (file.messages && file.messages.length > 0) {
            file.messages.forEach(msg => {
              if (msg.severity === 2) {
                let severity = 'medium';
                let description = msg.message;
                
                // 根据规则类型确定严重程度
                switch (msg.ruleId) {
                  case 'complexity':
                    severity = 'high';
                    description = `High cyclomatic complexity (${this.extractComplexityValue(msg.message)})`;
                    break;
                  case 'max-lines-per-function':
                    severity = 'medium';
                    description = `Function too long (${this.extractLinesValue(msg.message)} lines)`;
                    break;
                  case 'max-params':
                    severity = 'medium';
                    description = `Too many parameters (${this.extractParamsValue(msg.message)})`;
                    break;
                  case 'max-depth':
                    severity = 'high';
                    description = `Nesting too deep (${this.extractDepthValue(msg.message)} levels)`;
                    break;
                }
                
                debt.push({
                  id: `complexity-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
                  type: 'complexity',
                  severity,
                  file: file.filePath,
                  line: msg.line,
                  column: msg.column,
                  rule: msg.ruleId,
                  description,
                  impact: this.calculateComplexityImpact(msg.ruleId, severity),
                  effort: this.estimateComplexityEffort(msg.ruleId, severity),
                  createdAt: new Date().toISOString()
                });
              }
            });
          }
        });
      }
    } catch (error) {
      console.warn('Warning: Could not scan complexity debt:', error.message);
    }
    
    console.log(`   Found ${debt.length} complexity issues`);
    return debt;
  }

  /**
   * 扫描代码重复相关的技术债务
   */
  async scanDuplicationDebt() {
    console.log('🔍 Scanning duplication debt...');
    const debt = [];
    
    try {
      execSync('cd login && npm run duplication', { stdio: 'pipe' });
      
      const reportPath = path.join(this.projectRoot, 'login', 'jscpd-report.json');
      if (fs.existsSync(reportPath)) {
        const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        
        if (report.duplicates && report.duplicates.length > 0) {
          report.duplicates.forEach((duplicate, index) => {
            const percentage = (duplicate.lines / duplicate.tokens) * 100;
            let severity = 'low';
            
            if (percentage > 80) severity = 'high';
            else if (percentage > 50) severity = 'medium';
            
            debt.push({
              id: `duplication-${Date.now()}-${index}`,
              type: 'duplication',
              severity,
              files: duplicate.map(d => d.name),
              lines: duplicate.lines,
              tokens: duplicate.tokens,
              percentage: Math.round(percentage),
              description: `Code duplication detected (${duplicate.lines} lines, ${Math.round(percentage)}% similarity)`,
              impact: this.calculateDuplicationImpact(duplicate.lines, percentage),
              effort: this.estimateDuplicationEffort(duplicate.lines),
              createdAt: new Date().toISOString()
            });
          });
        }
      }
    } catch (error) {
      // jscpd 在发现重复时会返回非零退出码，这是正常的
      if (error.stdout) {
        console.log('   Duplication detected, processing report...');
      } else {
        console.warn('Warning: Could not scan duplication debt:', error.message);
      }
    }
    
    console.log(`   Found ${debt.length} duplication issues`);
    return debt;
  }

  /**
   * 扫描安全相关的技术债务
   */
  async scanSecurityDebt() {
    console.log('🔒 Scanning security debt...');
    const debt = [];
    
    try {
      const result = execSync('cd login && npm audit --json', { 
        encoding: 'utf8', 
        stdio: 'pipe' 
      });
      
      const audit = JSON.parse(result);
      
      if (audit.vulnerabilities) {
        Object.entries(audit.vulnerabilities).forEach(([level, count]) => {
          if (count > 0 && ['critical', 'high', 'moderate'].includes(level)) {
            let severity = 'medium';
            if (level === 'critical') severity = 'critical';
            else if (level === 'high') severity = 'high';
            
            debt.push({
              id: `security-${level}-${Date.now()}`,
              type: 'security',
              severity,
              level,
              count,
              description: `${count} ${level} security vulnerabilities found`,
              impact: this.calculateSecurityImpact(level, count),
              effort: this.estimateSecurityEffort(level, count),
              createdAt: new Date().toISOString()
            });
          }
        });
      }
    } catch (error) {
      // npm audit 在发现漏洞时会返回非零退出码
      if (error.stdout) {
        try {
          const audit = JSON.parse(error.stdout);
          // 处理审计结果...
          console.log('   Security vulnerabilities detected');
        } catch (parseError) {
          console.warn('Warning: Could not parse security audit results');
        }
      }
    }
    
    console.log(`   Found ${debt.length} security issues`);
    return debt;
  }

  /**
   * 扫描代码异味相关的技术债务
   */
  async scanCodeSmellsDebt() {
    console.log('👃 Scanning code smells...');
    const debt = [];
    
    // 这里可以添加更多的代码异味检测逻辑
    // 例如：长参数列表、大类、重复的条件逻辑等
    
    console.log(`   Found ${debt.length} code smell issues`);
    return debt;
  }

  /**
   * 扫描架构相关的技术债务
   */
  async scanArchitectureDebt() {
    console.log('🏗️  Scanning architecture debt...');
    const debt = [];
    
    // 这里可以添加架构债务检测逻辑
    // 例如：循环依赖、违反分层架构等
    
    console.log(`   Found ${debt.length} architecture issues`);
    return debt;
  }

  /**
   * 计算汇总信息
   */
  calculateSummary(debt) {
    const allDebt = [
      ...debt.categories.complexity,
      ...debt.categories.duplication,
      ...debt.categories.security,
      ...debt.categories.codeSmells,
      ...debt.categories.architecture
    ];
    
    debt.summary.total = allDebt.length;
    debt.summary.critical = allDebt.filter(d => d.severity === 'critical').length;
    debt.summary.high = allDebt.filter(d => d.severity === 'high').length;
    debt.summary.medium = allDebt.filter(d => d.severity === 'medium').length;
    debt.summary.low = allDebt.filter(d => d.severity === 'low').length;
  }

  /**
   * 显示债务汇总
   */
  displayDebtSummary(debt) {
    console.log('\n' + '='.repeat(60));
    console.log('📊 TECHNICAL DEBT SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total Issues: ${debt.summary.total}`);
    console.log(`  🔴 Critical: ${debt.summary.critical}`);
    console.log(`  🟠 High:     ${debt.summary.high}`);
    console.log(`  🟡 Medium:   ${debt.summary.medium}`);
    console.log(`  🟢 Low:      ${debt.summary.low}`);
    console.log('');
    
    console.log('By Category:');
    console.log(`  📊 Complexity:   ${debt.categories.complexity.length}`);
    console.log(`  🔍 Duplication:  ${debt.categories.duplication.length}`);
    console.log(`  🔒 Security:     ${debt.categories.security.length}`);
    console.log(`  👃 Code Smells:  ${debt.categories.codeSmells.length}`);
    console.log(`  🏗️  Architecture: ${debt.categories.architecture.length}`);
    console.log('');
    
    if (debt.summary.total > 0) {
      console.log('🎯 Recommended Actions:');
      if (debt.summary.critical > 0) {
        console.log('  1. Address critical security vulnerabilities immediately');
      }
      if (debt.summary.high > 0) {
        console.log('  2. Refactor high complexity functions');
      }
      if (debt.categories.duplication.length > 0) {
        console.log('  3. Extract common code to reduce duplication');
      }
      console.log('  4. Create GitHub issues for tracking debt items');
      console.log('  5. Plan debt cleanup in upcoming sprints');
    } else {
      console.log('🎉 No significant technical debt detected!');
    }
    
    console.log('');
    console.log(`📄 Detailed report saved to: ${this.debtFile}`);
    console.log('='.repeat(60));
  }

  // 辅助方法
  extractComplexityValue(message) {
    const match = message.match(/complexity of (\d+)/);
    return match ? match[1] : 'unknown';
  }

  extractLinesValue(message) {
    const match = message.match(/(\d+) lines/);
    return match ? match[1] : 'unknown';
  }

  extractParamsValue(message) {
    const match = message.match(/(\d+) parameters/);
    return match ? match[1] : 'unknown';
  }

  extractDepthValue(message) {
    const match = message.match(/depth of (\d+)/);
    return match ? match[1] : 'unknown';
  }

  calculateComplexityImpact(rule, severity) {
    const impacts = {
      complexity: { high: 'High maintenance cost', medium: 'Moderate maintenance cost' },
      'max-lines-per-function': { medium: 'Reduced readability' },
      'max-params': { medium: 'Difficult to use and test' },
      'max-depth': { high: 'Hard to understand and debug' }
    };
    return impacts[rule]?.[severity] || 'Unknown impact';
  }

  estimateComplexityEffort(rule, severity) {
    const efforts = {
      complexity: { high: '4-8 hours', medium: '2-4 hours' },
      'max-lines-per-function': { medium: '2-4 hours' },
      'max-params': { medium: '1-2 hours' },
      'max-depth': { high: '3-6 hours' }
    };
    return efforts[rule]?.[severity] || '1-2 hours';
  }

  calculateDuplicationImpact(lines, percentage) {
    if (lines > 50) return 'High maintenance cost';
    if (lines > 20) return 'Moderate maintenance cost';
    return 'Low maintenance cost';
  }

  estimateDuplicationEffort(lines) {
    if (lines > 50) return '4-8 hours';
    if (lines > 20) return '2-4 hours';
    return '1-2 hours';
  }

  calculateSecurityImpact(level, count) {
    if (level === 'critical') return 'System security at risk';
    if (level === 'high') return 'Potential security vulnerabilities';
    return 'Minor security concerns';
  }

  estimateSecurityEffort(level, count) {
    if (level === 'critical') return '1-2 days';
    if (level === 'high') return '4-8 hours';
    return '1-2 hours';
  }

  /**
   * 生成 GitHub Issues
   */
  async generateGitHubIssues() {
    if (!fs.existsSync(this.debtFile)) {
      console.log('❌ No debt report found. Run scan first.');
      return;
    }
    
    const debt = JSON.parse(fs.readFileSync(this.debtFile, 'utf8'));
    const allDebt = [
      ...debt.categories.complexity,
      ...debt.categories.duplication,
      ...debt.categories.security,
      ...debt.categories.codeSmells,
      ...debt.categories.architecture
    ];
    
    // 只为高优先级债务生成 Issues
    const highPriorityDebt = allDebt.filter(d => 
      d.severity === 'critical' || d.severity === 'high'
    );
    
    console.log(`📝 Generating GitHub issues for ${highPriorityDebt.length} high-priority debt items...`);
    
    highPriorityDebt.forEach(item => {
      const issueContent = this.generateIssueContent(item);
      const fileName = `debt-issue-${item.id}.md`;
      const filePath = path.join(this.reportsDir, fileName);
      
      fs.writeFileSync(filePath, issueContent);
      console.log(`   Generated: ${fileName}`);
    });
    
    console.log('\n📋 To create GitHub issues:');
    console.log('1. Copy the content from generated .md files');
    console.log('2. Create new issues in GitHub repository');
    console.log('3. Add appropriate labels and assignees');
  }

  generateIssueContent(debt) {
    return `---
title: "[DEBT] ${debt.description}"
labels: ["technical-debt", "priority-${debt.severity}"]
---

## 技术债务信息

**类型：** ${debt.type}
**严重程度：** ${debt.severity}
**影响范围：** ${debt.file ? 'Function level' : 'Module level'}

## 问题描述

### 当前状况
${debt.description}

### 问题位置
${debt.file ? `- 文件：${debt.file}` : ''}
${debt.line ? `- 行号：${debt.line}` : ''}
${debt.rule ? `- 规则：${debt.rule}` : ''}

### 发现方式
- [x] 自动化工具检测

## 影响分析

### 影响描述
${debt.impact}

### 预估工作量
${debt.effort}

## 解决方案

### 建议方案
${this.getSolutionSuggestion(debt)}

## 优先级评估

**技术优先级：** ${debt.severity === 'critical' ? 'P0 - 立即处理' : debt.severity === 'high' ? 'P1 - 本周处理' : 'P2 - 本月处理'}

## 验收标准

### 完成标准
- [ ] 自动化检查通过
- [ ] 代码审查通过
- [ ] 单元测试通过

---

*This issue was automatically generated by debt-tracker.js*
`;
  }

  getSolutionSuggestion(debt) {
    const suggestions = {
      complexity: 'Break down the complex function into smaller, single-purpose functions',
      duplication: 'Extract common code into reusable utility functions or modules',
      security: 'Update vulnerable dependencies or apply security patches',
      codeSmells: 'Refactor code to improve readability and maintainability',
      architecture: 'Restructure modules to improve separation of concerns'
    };
    
    return suggestions[debt.type] || 'Review and refactor the identified code';
  }

  /**
   * 主执行函数
   */
  async run() {
    const args = process.argv.slice(2);
    
    if (args.includes('--help')) {
      console.log('Technical Debt Tracker');
      console.log('Usage: node scripts/debt-tracker.js [options]');
      console.log('');
      console.log('Options:');
      console.log('  --scan         Scan for technical debt');
      console.log('  --issues       Generate GitHub issue templates');
      console.log('  --report       Show current debt report');
      console.log('  --help         Show this help message');
      console.log('');
      return;
    }
    
    if (args.includes('--issues')) {
      await this.generateGitHubIssues();
      return;
    }
    
    if (args.includes('--report')) {
      if (fs.existsSync(this.debtFile)) {
        const debt = JSON.parse(fs.readFileSync(this.debtFile, 'utf8'));
        this.displayDebtSummary(debt);
      } else {
        console.log('❌ No debt report found. Run --scan first.');
      }
      return;
    }
    
    // 默认执行扫描
    await this.scanDebt();
  }
}

// 运行脚本
if (require.main === module) {
  const tracker = new DebtTracker();
  tracker.run().catch(error => {
    console.error('❌ Debt tracking failed:', error.message);
    process.exit(1);
  });
}

module.exports = DebtTracker;