#!/usr/bin/env node

/**
 * 定期 Code Review 提醒脚本
 * 用于检查项目状态并发送提醒
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class ReviewReminder {
  constructor() {
    this.projectRoot = process.cwd();
    this.lastReviewFile = path.join(this.projectRoot, '.last-review');
    this.reminderConfig = {
      // 提醒间隔（天）
      reminderInterval: 7,
      // 复杂度阈值
      complexityThreshold: 10,
      // 文件变更阈值
      fileChangeThreshold: 5
    };
  }

  /**
   * 检查是否需要进行 Code Review
   */
  shouldTriggerReview() {
    const lastReviewDate = this.getLastReviewDate();
    const daysSinceLastReview = this.getDaysSince(lastReviewDate);
    const recentChanges = this.getRecentChanges();
    
    console.log(`📊 Review Status Check:`);
    console.log(`   Last review: ${lastReviewDate ? lastReviewDate.toDateString() : 'Never'}`);
    console.log(`   Days since last review: ${daysSinceLastReview}`);
    console.log(`   Recent file changes: ${recentChanges.length}`);
    
    // 检查时间间隔
    if (daysSinceLastReview >= this.reminderConfig.reminderInterval) {
      console.log(`⏰ Time-based reminder: ${daysSinceLastReview} days since last review`);
      return true;
    }
    
    // 检查文件变更数量
    if (recentChanges.length >= this.reminderConfig.fileChangeThreshold) {
      console.log(`📝 Change-based reminder: ${recentChanges.length} files changed recently`);
      return true;
    }
    
    return false;
  }

  /**
   * 获取最后一次 Review 日期
   */
  getLastReviewDate() {
    try {
      if (fs.existsSync(this.lastReviewFile)) {
        const timestamp = fs.readFileSync(this.lastReviewFile, 'utf8').trim();
        return new Date(parseInt(timestamp));
      }
    } catch (error) {
      console.warn('Warning: Could not read last review date:', error.message);
    }
    return null;
  }

  /**
   * 计算距离指定日期的天数
   */
  getDaysSince(date) {
    if (!date) return Infinity;
    const now = new Date();
    const diffTime = Math.abs(now - date);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  /**
   * 获取最近的文件变更
   */
  getRecentChanges() {
    try {
      // 获取最近7天的 git 变更
      const gitLog = execSync('git log --since="7 days ago" --name-only --pretty=format: | sort | uniq', 
        { encoding: 'utf8', cwd: this.projectRoot });
      
      return gitLog.split('\n')
        .filter(line => line.trim())
        .filter(file => file.endsWith('.js') || file.endsWith('.json') || file.endsWith('.md'));
    } catch (error) {
      console.warn('Warning: Could not get git changes:', error.message);
      return [];
    }
  }

  /**
   * 运行快速复杂度检查
   */
  runQuickComplexityCheck() {
    console.log('\n🔍 Running quick complexity check...');
    
    try {
      // 运行 ESLint 复杂度检查
      execSync('cd login && npm run complexity', 
        { encoding: 'utf8', cwd: this.projectRoot, stdio: 'pipe' });
      
      // 检查是否有复杂度报告文件
      const reportPath = path.join(this.projectRoot, 'login', 'complexity-report.json');
      if (fs.existsSync(reportPath)) {
        const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        
        // 统计各种复杂度问题
        const complexityIssues = this.analyzeComplexityReport(report);
        
        if (complexityIssues.total > 0) {
          console.log(`⚠️  Found ${complexityIssues.total} complexity issues:`);
          console.log(`   - High complexity functions: ${complexityIssues.complexity}`);
          console.log(`   - Long functions: ${complexityIssues.longFunctions}`);
          console.log(`   - Functions with too many parameters: ${complexityIssues.tooManyParams}`);
          console.log(`   - Deep nesting: ${complexityIssues.deepNesting}`);
          return true;
        }
      }
      
      console.log('✅ No high complexity issues found');
      return false;
    } catch (error) {
      console.warn('Warning: Could not run complexity check:', error.message);
      return false;
    }
  }

  /**
   * 分析复杂度报告
   */
  analyzeComplexityReport(report) {
    const issues = {
      complexity: 0,
      longFunctions: 0,
      tooManyParams: 0,
      deepNesting: 0,
      total: 0
    };

    report.forEach(file => {
      if (file.messages) {
        file.messages.forEach(msg => {
          if (msg.severity === 2) { // Error level
            switch (msg.ruleId) {
              case 'complexity':
                issues.complexity++;
                break;
              case 'max-lines-per-function':
                issues.longFunctions++;
                break;
              case 'max-params':
                issues.tooManyParams++;
                break;
              case 'max-depth':
                issues.deepNesting++;
                break;
            }
          }
        });
      }
    });

    issues.total = issues.complexity + issues.longFunctions + issues.tooManyParams + issues.deepNesting;
    return issues;
  }

  /**
   * 运行代码重复检查
   */
  runDuplicationCheck() {
    console.log('\n🔍 Running code duplication check...');
    
    try {
      execSync('cd login && npm run duplication', 
        { encoding: 'utf8', cwd: this.projectRoot, stdio: 'pipe' });
      
      const reportPath = path.join(this.projectRoot, 'login', 'jscpd-report.json');
      if (fs.existsSync(reportPath)) {
        const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        const duplicationPercentage = report.statistics?.total?.percentage || 0;
        
        if (duplicationPercentage > 10) {
          console.log(`⚠️  Code duplication: ${duplicationPercentage}% (threshold: 10%)`);
          return true;
        } else {
          console.log(`✅ Code duplication: ${duplicationPercentage}% (within threshold)`);
        }
      }
      
      return false;
    } catch (error) {
      console.warn('Warning: Could not run duplication check:', error.message);
      return false;
    }
  }

  /**
   * 运行安全检查
   */
  runSecurityCheck() {
    console.log('\n🔍 Running security audit...');
    
    try {
      const result = execSync('cd login && npm audit --json', 
        { encoding: 'utf8', cwd: this.projectRoot, stdio: 'pipe' });
      
      const audit = JSON.parse(result);
      const highVulns = audit.vulnerabilities?.high || 0;
      const criticalVulns = audit.vulnerabilities?.critical || 0;
      
      if (highVulns > 0 || criticalVulns > 0) {
        console.log(`⚠️  Security vulnerabilities found:`);
        console.log(`   - Critical: ${criticalVulns}`);
        console.log(`   - High: ${highVulns}`);
        return true;
      } else {
        console.log('✅ No high or critical security vulnerabilities found');
      }
      
      return false;
    } catch (error) {
      // npm audit returns non-zero exit code when vulnerabilities are found
      if (error.stdout) {
        try {
          const audit = JSON.parse(error.stdout);
          const highVulns = audit.vulnerabilities?.high || 0;
          const criticalVulns = audit.vulnerabilities?.critical || 0;
          
          if (highVulns > 0 || criticalVulns > 0) {
            console.log(`⚠️  Security vulnerabilities found:`);
            console.log(`   - Critical: ${criticalVulns}`);
            console.log(`   - High: ${highVulns}`);
            return true;
          }
        } catch (parseError) {
          console.warn('Warning: Could not parse security audit results');
        }
      }
      return false;
    }
  }

  /**
   * 发送提醒通知
   */
  sendReminder(reasons = []) {
    console.log('\n📢 CODE REVIEW REMINDER');
    console.log('========================');
    console.log('It\'s time for a code review! Reasons:');
    
    reasons.forEach(reason => {
      console.log(`  • ${reason}`);
    });
    
    console.log('\nRecommended actions:');
    console.log('  1. Run full quality analysis: cd login && npm run quality-check');
    console.log('  2. Generate detailed reports: cd login && npm run quality-report');
    console.log('  3. Review recent changes for KISS principle compliance');
    console.log('  4. Check for refactoring opportunities');
    console.log('  5. Update documentation if needed');
    console.log('  6. Address any security vulnerabilities');
    console.log('\nDetailed commands:');
    console.log('  • Complexity analysis: cd login && npm run complexity:html');
    console.log('  • Duplication analysis: cd login && npm run duplication:html');
    console.log('  • Security audit: cd login && npm run security');
    console.log('\nTo mark review as completed, run: node scripts/review-reminder.js --mark-completed');
  }

  /**
   * 标记 Review 已完成
   */
  markReviewCompleted() {
    const now = Date.now();
    fs.writeFileSync(this.lastReviewFile, now.toString());
    console.log('✅ Review marked as completed on', new Date(now).toDateString());
  }

  /**
   * 主执行函数
   */
  run() {
    const args = process.argv.slice(2);
    
    if (args.includes('--mark-completed')) {
      this.markReviewCompleted();
      return;
    }
    
    if (args.includes('--force')) {
      this.sendReminder(['Forced review requested']);
      return;
    }
    
    const reasons = [];
    
    // 检查是否需要提醒
    if (this.shouldTriggerReview()) {
      const lastReviewDate = this.getLastReviewDate();
      const daysSinceLastReview = this.getDaysSince(lastReviewDate);
      
      if (daysSinceLastReview >= this.reminderConfig.reminderInterval) {
        reasons.push(`${daysSinceLastReview} days since last review`);
      }
      
      const recentChanges = this.getRecentChanges();
      if (recentChanges.length >= this.reminderConfig.fileChangeThreshold) {
        reasons.push(`${recentChanges.length} files changed recently`);
      }
    }
    
    // 运行各种质量检查
    if (this.runQuickComplexityCheck()) {
      reasons.push('High complexity issues detected');
    }
    
    if (this.runDuplicationCheck()) {
      reasons.push('Code duplication threshold exceeded');
    }
    
    if (this.runSecurityCheck()) {
      reasons.push('Security vulnerabilities found');
    }
    
    if (reasons.length > 0) {
      this.sendReminder(reasons);
    } else {
      console.log('✅ No review reminder needed at this time');
    }
  }
}

// 运行脚本
if (require.main === module) {
  const reminder = new ReviewReminder();
  reminder.run();
}

module.exports = ReviewReminder;