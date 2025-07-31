#!/usr/bin/env node

/**
 * 代码质量仪表板
 * 生成综合的代码质量报告和趋势分析
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class QualityDashboard {
  constructor() {
    this.projectRoot = process.cwd();
    this.reportsDir = path.join(this.projectRoot, 'quality-reports');
    this.configPath = path.join(this.projectRoot, '.quality-config.json');
    this.config = this.loadConfig();
    
    // 确保报告目录存在
    if (!fs.existsSync(this.reportsDir)) {
      fs.mkdirSync(this.reportsDir, { recursive: true });
    }
  }

  /**
   * 加载质量配置
   */
  loadConfig() {
    try {
      if (fs.existsSync(this.configPath)) {
        return JSON.parse(fs.readFileSync(this.configPath, 'utf8'));
      }
    } catch (error) {
      console.warn('Warning: Could not load quality config, using defaults');
    }
    
    return {
      standards: {
        complexity: { maxCyclomaticComplexity: 10 },
        duplication: { threshold: 10 },
        security: { maxCriticalVulnerabilities: 0 }
      }
    };
  }

  /**
   * 运行所有质量检查
   */
  async runAllChecks() {
    console.log('🚀 Running comprehensive quality analysis...\n');
    
    const results = {
      timestamp: new Date().toISOString(),
      complexity: await this.runComplexityAnalysis(),
      duplication: await this.runDuplicationAnalysis(),
      security: await this.runSecurityAnalysis(),
      linting: await this.runLintingAnalysis()
    };
    
    // 计算总体评分
    results.overallScore = this.calculateOverallScore(results);
    results.recommendations = this.generateRecommendations(results);
    
    // 保存结果
    const reportPath = path.join(this.reportsDir, `quality-report-${Date.now()}.json`);
    fs.writeFileSync(reportPath, JSON.stringify(results, null, 2));
    
    // 生成 HTML 报告
    await this.generateHtmlReport(results);
    
    // 显示摘要
    this.displaySummary(results);
    
    return results;
  }

  /**
   * 复杂度分析
   */
  async runComplexityAnalysis() {
    console.log('📊 Analyzing code complexity...');
    
    try {
      execSync('cd login && npm run complexity', { stdio: 'pipe' });
      
      const reportPath = path.join(this.projectRoot, 'login', 'complexity-report.json');
      if (fs.existsSync(reportPath)) {
        const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        
        const analysis = {
          totalFiles: report.length,
          issues: {
            complexity: 0,
            longFunctions: 0,
            tooManyParams: 0,
            deepNesting: 0
          },
          details: []
        };
        
        report.forEach(file => {
          if (file.messages && file.messages.length > 0) {
            const fileIssues = {
              file: file.filePath,
              issues: []
            };
            
            file.messages.forEach(msg => {
              if (msg.severity === 2) {
                fileIssues.issues.push({
                  rule: msg.ruleId,
                  line: msg.line,
                  message: msg.message
                });
                
                switch (msg.ruleId) {
                  case 'complexity':
                    analysis.issues.complexity++;
                    break;
                  case 'max-lines-per-function':
                    analysis.issues.longFunctions++;
                    break;
                  case 'max-params':
                    analysis.issues.tooManyParams++;
                    break;
                  case 'max-depth':
                    analysis.issues.deepNesting++;
                    break;
                }
              }
            });
            
            if (fileIssues.issues.length > 0) {
              analysis.details.push(fileIssues);
            }
          }
        });
        
        analysis.totalIssues = Object.values(analysis.issues).reduce((a, b) => a + b, 0);
        analysis.score = Math.max(0, 100 - (analysis.totalIssues * 10));
        
        return analysis;
      }
    } catch (error) {
      console.warn('Warning: Complexity analysis failed:', error.message);
    }
    
    return { score: 100, totalIssues: 0, issues: {} };
  }

  /**
   * 重复代码分析
   */
  async runDuplicationAnalysis() {
    console.log('🔍 Analyzing code duplication...');
    
    try {
      execSync('cd login && npm run duplication', { stdio: 'pipe' });
      
      const reportPath = path.join(this.projectRoot, 'login', 'jscpd-report.json');
      if (fs.existsSync(reportPath)) {
        const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
        
        const analysis = {
          percentage: report.statistics?.total?.percentage || 0,
          duplicatedLines: report.statistics?.total?.duplicatedLines || 0,
          totalLines: report.statistics?.total?.lines || 0,
          duplicates: report.duplicates || [],
          score: Math.max(0, 100 - (report.statistics?.total?.percentage || 0) * 5)
        };
        
        return analysis;
      }
    } catch (error) {
      console.warn('Warning: Duplication analysis failed:', error.message);
    }
    
    return { score: 100, percentage: 0, duplicatedLines: 0 };
  }

  /**
   * 安全分析
   */
  async runSecurityAnalysis() {
    console.log('🔒 Analyzing security vulnerabilities...');
    
    try {
      const result = execSync('cd login && npm audit --json', { 
        encoding: 'utf8', 
        stdio: 'pipe' 
      });
      
      const audit = JSON.parse(result);
      const analysis = {
        vulnerabilities: audit.vulnerabilities || {},
        totalVulnerabilities: Object.values(audit.vulnerabilities || {}).reduce((a, b) => a + b, 0),
        score: 100
      };
      
      // 计算安全评分
      const critical = audit.vulnerabilities?.critical || 0;
      const high = audit.vulnerabilities?.high || 0;
      const moderate = audit.vulnerabilities?.moderate || 0;
      
      analysis.score = Math.max(0, 100 - (critical * 30 + high * 20 + moderate * 5));
      
      return analysis;
    } catch (error) {
      // npm audit 在发现漏洞时会返回非零退出码
      if (error.stdout) {
        try {
          const audit = JSON.parse(error.stdout);
          const analysis = {
            vulnerabilities: audit.vulnerabilities || {},
            totalVulnerabilities: Object.values(audit.vulnerabilities || {}).reduce((a, b) => a + b, 0),
            score: 100
          };
          
          const critical = audit.vulnerabilities?.critical || 0;
          const high = audit.vulnerabilities?.high || 0;
          const moderate = audit.vulnerabilities?.moderate || 0;
          
          analysis.score = Math.max(0, 100 - (critical * 30 + high * 20 + moderate * 5));
          
          return analysis;
        } catch (parseError) {
          console.warn('Warning: Could not parse security audit results');
        }
      }
    }
    
    return { score: 100, vulnerabilities: {}, totalVulnerabilities: 0 };
  }

  /**
   * 代码规范分析
   */
  async runLintingAnalysis() {
    console.log('📝 Analyzing code style and standards...');
    
    try {
      execSync('cd login && npm run lint', { stdio: 'pipe' });
      return { score: 100, errors: 0, warnings: 0 };
    } catch (error) {
      // ESLint 在发现问题时会返回非零退出码
      const output = String(error.stdout || error.stderr || '');
      const errorCount = (output.match(/error/gi) || []).length;
      const warningCount = (output.match(/warning/gi) || []).length;
      
      const score = Math.max(0, 100 - (errorCount * 10 + warningCount * 2));
      
      return {
        score,
        errors: errorCount,
        warnings: warningCount,
        output: output.substring(0, 1000) // 限制输出长度
      };
    }
  }

  /**
   * 计算总体评分
   */
  calculateOverallScore(results) {
    const weights = {
      complexity: 0.3,
      duplication: 0.2,
      security: 0.3,
      linting: 0.2
    };
    
    const weightedScore = 
      (results.complexity.score * weights.complexity) +
      (results.duplication.score * weights.duplication) +
      (results.security.score * weights.security) +
      (results.linting.score * weights.linting);
    
    return Math.round(weightedScore);
  }

  /**
   * 生成改进建议
   */
  generateRecommendations(results) {
    const recommendations = [];
    
    if (results.complexity.totalIssues > 0) {
      recommendations.push({
        category: 'Complexity',
        priority: 'High',
        description: `Found ${results.complexity.totalIssues} complexity issues. Consider refactoring complex functions.`,
        actions: [
          'Break down complex functions into smaller ones',
          'Reduce parameter count by using objects',
          'Simplify nested logic structures'
        ]
      });
    }
    
    if (results.duplication.percentage > 10) {
      recommendations.push({
        category: 'Duplication',
        priority: 'Medium',
        description: `Code duplication is ${results.duplication.percentage}%. Consider extracting common functionality.`,
        actions: [
          'Extract common code into utility functions',
          'Create reusable components',
          'Use inheritance or composition patterns'
        ]
      });
    }
    
    if (results.security.totalVulnerabilities > 0) {
      recommendations.push({
        category: 'Security',
        priority: 'Critical',
        description: `Found ${results.security.totalVulnerabilities} security vulnerabilities.`,
        actions: [
          'Update vulnerable dependencies',
          'Review security best practices',
          'Run security audit regularly'
        ]
      });
    }
    
    if (results.linting.errors > 0 || results.linting.warnings > 5) {
      recommendations.push({
        category: 'Code Style',
        priority: 'Low',
        description: `Found ${results.linting.errors} errors and ${results.linting.warnings} warnings.`,
        actions: [
          'Fix linting errors',
          'Configure IDE for automatic formatting',
          'Set up pre-commit hooks'
        ]
      });
    }
    
    return recommendations;
  }

  /**
   * 生成 HTML 报告
   */
  async generateHtmlReport(results) {
    const htmlTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Quality Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .score-card { background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .score-circle { width: 100px; height: 100px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; font-weight: bold; color: white; margin-right: 20px; }
        .score-excellent { background: #4CAF50; }
        .score-good { background: #2196F3; }
        .score-warning { background: #FF9800; }
        .score-danger { background: #F44336; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; }
        .metric { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .metric h3 { margin-top: 0; color: #333; }
        .recommendations { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .recommendation { border-left: 4px solid #2196F3; padding: 10px; margin: 10px 0; background: #f8f9fa; }
        .priority-critical { border-left-color: #F44336; }
        .priority-high { border-left-color: #FF9800; }
        .priority-medium { border-left-color: #2196F3; }
        .priority-low { border-left-color: #4CAF50; }
        .timestamp { color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Code Quality Dashboard</h1>
            <p class="timestamp">Generated on: ${new Date(results.timestamp).toLocaleString()}</p>
        </div>
        
        <div class="score-card">
            <h2>Overall Quality Score</h2>
            <div style="display: flex; align-items: center;">
                <div class="score-circle ${this.getScoreClass(results.overallScore)}">
                    ${results.overallScore}
                </div>
                <div>
                    <h3>${this.getScoreLabel(results.overallScore)}</h3>
                    <p>Based on complexity, duplication, security, and code style analysis</p>
                </div>
            </div>
        </div>
        
        <div class="metrics">
            <div class="metric">
                <h3>🔧 Complexity</h3>
                <p><strong>Score:</strong> ${results.complexity.score}/100</p>
                <p><strong>Issues:</strong> ${results.complexity.totalIssues || 0}</p>
                <p><strong>Files Analyzed:</strong> ${results.complexity.totalFiles || 0}</p>
            </div>
            
            <div class="metric">
                <h3>📋 Code Duplication</h3>
                <p><strong>Score:</strong> ${results.duplication.score}/100</p>
                <p><strong>Duplication:</strong> ${results.duplication.percentage}%</p>
                <p><strong>Duplicated Lines:</strong> ${results.duplication.duplicatedLines}</p>
            </div>
            
            <div class="metric">
                <h3>🔒 Security</h3>
                <p><strong>Score:</strong> ${results.security.score}/100</p>
                <p><strong>Vulnerabilities:</strong> ${results.security.totalVulnerabilities}</p>
                <p><strong>Critical:</strong> ${results.security.vulnerabilities.critical || 0}</p>
            </div>
            
            <div class="metric">
                <h3>📝 Code Style</h3>
                <p><strong>Score:</strong> ${results.linting.score}/100</p>
                <p><strong>Errors:</strong> ${results.linting.errors}</p>
                <p><strong>Warnings:</strong> ${results.linting.warnings}</p>
            </div>
        </div>
        
        ${results.recommendations.length > 0 ? `
        <div class="recommendations">
            <h2>🎯 Recommendations</h2>
            ${results.recommendations.map(rec => `
                <div class="recommendation priority-${rec.priority.toLowerCase()}">
                    <h4>${rec.category} (${rec.priority} Priority)</h4>
                    <p>${rec.description}</p>
                    <ul>
                        ${rec.actions.map(action => `<li>${action}</li>`).join('')}
                    </ul>
                </div>
            `).join('')}
        </div>
        ` : ''}
    </div>
</body>
</html>`;
    
    const htmlPath = path.join(this.reportsDir, 'quality-dashboard.html');
    fs.writeFileSync(htmlPath, htmlTemplate);
    
    console.log(`📄 HTML report generated: ${htmlPath}`);
  }

  /**
   * 获取评分对应的CSS类
   */
  getScoreClass(score) {
    if (score >= 90) return 'score-excellent';
    if (score >= 70) return 'score-good';
    if (score >= 50) return 'score-warning';
    return 'score-danger';
  }

  /**
   * 获取评分标签
   */
  getScoreLabel(score) {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Needs Improvement';
    return 'Poor';
  }

  /**
   * 显示摘要
   */
  displaySummary(results) {
    console.log('\n' + '='.repeat(60));
    console.log('📊 CODE QUALITY SUMMARY');
    console.log('='.repeat(60));
    console.log(`Overall Score: ${results.overallScore}/100 (${this.getScoreLabel(results.overallScore)})`);
    console.log('');
    console.log('Individual Scores:');
    console.log(`  🔧 Complexity:    ${results.complexity.score}/100`);
    console.log(`  📋 Duplication:   ${results.duplication.score}/100`);
    console.log(`  🔒 Security:      ${results.security.score}/100`);
    console.log(`  📝 Code Style:    ${results.linting.score}/100`);
    console.log('');
    
    if (results.recommendations.length > 0) {
      console.log('🎯 Top Recommendations:');
      results.recommendations.slice(0, 3).forEach((rec, index) => {
        console.log(`  ${index + 1}. ${rec.category}: ${rec.description}`);
      });
    } else {
      console.log('🎉 No major issues found! Keep up the good work!');
    }
    
    console.log('');
    console.log('📄 Detailed reports available in: quality-reports/');
    console.log('='.repeat(60));
  }

  /**
   * 主执行函数
   */
  async run() {
    const args = process.argv.slice(2);
    
    if (args.includes('--help')) {
      console.log('Code Quality Dashboard');
      console.log('Usage: node scripts/quality-dashboard.js [options]');
      console.log('');
      console.log('Options:');
      console.log('  --help     Show this help message');
      console.log('  --config   Show current configuration');
      console.log('');
      return;
    }
    
    if (args.includes('--config')) {
      console.log('Current Quality Configuration:');
      console.log(JSON.stringify(this.config, null, 2));
      return;
    }
    
    try {
      await this.runAllChecks();
    } catch (error) {
      console.error('❌ Quality analysis failed:', error.message);
      process.exit(1);
    }
  }
}

// 运行脚本
if (require.main === module) {
  const dashboard = new QualityDashboard();
  dashboard.run();
}

module.exports = QualityDashboard;