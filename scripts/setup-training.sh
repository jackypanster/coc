#!/bin/bash

# 团队培训环境设置脚本
# 用于初始化培训相关的工具和资源

PROJECT_ROOT=$(pwd)

echo "🎓 Setting up team training environment..."

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. 检查培训材料
print_step "Checking training materials..."

TRAINING_DIR=".kiro/training"
if [ -d "$TRAINING_DIR" ]; then
    print_success "Training directory exists"
    
    # 检查必要的培训文件
    REQUIRED_FILES=(
        "kiss-principles-guide.md"
        "best-practices-template.md"
        "quality-review-meeting-template.md"
        "training-schedule.md"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$TRAINING_DIR/$file" ]; then
            print_success "Found: $file"
        else
            print_warning "Missing: $file"
        fi
    done
else
    print_warning "Training directory not found"
    echo "Creating training directory..."
    mkdir -p "$TRAINING_DIR"
fi

# 2. 创建培训资源目录
print_step "Setting up training resource directories..."

RESOURCE_DIRS=(
    "$TRAINING_DIR/materials"
    "$TRAINING_DIR/exercises"
    "$TRAINING_DIR/examples"
    "$TRAINING_DIR/presentations"
    "$TRAINING_DIR/feedback"
)

for dir in "${RESOURCE_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "Created: $dir"
    else
        print_success "Exists: $dir"
    fi
done

# 3. 创建示例练习文件
print_step "Creating example exercises..."

# 练习1：复杂函数重构
cat > "$TRAINING_DIR/exercises/exercise-1-refactoring.md" << 'EOF'
# 练习1：复杂函数重构

## 目标
学习如何识别和重构复杂函数，应用 KISS 原则简化代码。

## 练习代码

```javascript
function processOrderData(orders, filters, options) {
  let result = [];
  for (let i = 0; i < orders.length; i++) {
    let order = orders[i];
    let shouldInclude = true;
    
    if (filters) {
      if (filters.status && order.status !== filters.status) {
        shouldInclude = false;
      }
      if (filters.minAmount && order.total < filters.minAmount) {
        shouldInclude = false;
      }
      if (filters.maxAmount && order.total > filters.maxAmount) {
        shouldInclude = false;
      }
      if (filters.dateRange) {
        let orderDate = new Date(order.date);
        let startDate = new Date(filters.dateRange.start);
        let endDate = new Date(filters.dateRange.end);
        if (orderDate < startDate || orderDate > endDate) {
          shouldInclude = false;
        }
      }
    }
    
    if (shouldInclude) {
      let processedOrder = { ...order };
      
      if (options && options.includeCustomerInfo) {
        // 复杂的客户信息处理逻辑
        if (order.customerId) {
          // 假设的客户数据获取
          processedOrder.customerName = getCustomerName(order.customerId);
          processedOrder.customerEmail = getCustomerEmail(order.customerId);
        }
      }
      
      if (options && options.calculateTax) {
        let taxRate = 0.08;
        if (order.state === 'CA') taxRate = 0.0875;
        else if (order.state === 'NY') taxRate = 0.08;
        else if (order.state === 'TX') taxRate = 0.0625;
        
        processedOrder.tax = order.subtotal * taxRate;
        processedOrder.total = order.subtotal + processedOrder.tax;
      }
      
      result.push(processedOrder);
    }
  }
  
  if (options && options.sortBy) {
    if (options.sortBy === 'date') {
      result.sort((a, b) => new Date(a.date) - new Date(b.date));
    } else if (options.sortBy === 'amount') {
      result.sort((a, b) => a.total - b.total);
    } else if (options.sortBy === 'status') {
      result.sort((a, b) => a.status.localeCompare(b.status));
    }
  }
  
  return result;
}
```

## 任务

1. 分析上述函数的复杂度问题
2. 识别可以简化的部分
3. 将函数重构为多个简单的函数
4. 确保重构后的代码更易读、易测试

## 评估标准

- [ ] 单个函数复杂度 ≤ 10
- [ ] 函数长度 ≤ 50 行
- [ ] 函数职责单一
- [ ] 代码可读性提升
- [ ] 易于单元测试

## 提交方式

1. 创建新的分支
2. 提交重构后的代码
3. 创建 Pull Request
4. 请求代码审查
EOF

print_success "Created exercise 1: Function refactoring"

# 练习2：设计简化
cat > "$TRAINING_DIR/exercises/exercise-2-design-simplification.md" << 'EOF'
# 练习2：设计简化

## 目标
学习识别过度设计，应用 KISS 原则简化系统设计。

## 场景描述

你需要设计一个用户通知系统，当前的设计过于复杂：

```javascript
// 当前的复杂设计
class NotificationManager {
  constructor() {
    this.providers = new Map();
    this.strategies = new Map();
    this.filters = new Map();
    this.transformers = new Map();
    this.validators = new Map();
  }
  
  registerProvider(name, provider) {
    this.providers.set(name, provider);
  }
  
  registerStrategy(name, strategy) {
    this.strategies.set(name, strategy);
  }
  
  async sendNotification(notification, options = {}) {
    // 复杂的处理逻辑...
  }
}

class NotificationStrategy {
  constructor(config) {
    this.config = config;
  }
  
  async execute(notification, context) {
    // 抽象方法
    throw new Error('Must implement execute method');
  }
}

class EmailNotificationStrategy extends NotificationStrategy {
  async execute(notification, context) {
    // 邮件发送逻辑
  }
}

class SMSNotificationStrategy extends NotificationStrategy {
  async execute(notification, context) {
    // 短信发送逻辑
  }
}
```

## 任务

1. 分析当前设计的复杂性问题
2. 识别不必要的抽象层
3. 设计一个更简单的解决方案
4. 确保新设计满足基本需求

## 基本需求

- 支持邮件和短信通知
- 支持不同的通知模板
- 支持批量发送
- 易于添加新的通知类型

## 评估标准

- [ ] 设计简洁明了
- [ ] 易于理解和使用
- [ ] 易于扩展
- [ ] 减少不必要的抽象
- [ ] 代码量显著减少

## 提交方式

1. 提交设计文档
2. 提供简化后的代码实现
3. 说明简化的理由和好处
EOF

print_success "Created exercise 2: Design simplification"

# 4. 创建培训反馈表单模板
print_step "Creating feedback form template..."

cat > "$TRAINING_DIR/feedback/training-feedback-template.md" << 'EOF'
# 培训反馈表

## 基本信息

**培训主题：** [培训主题]  
**培训日期：** [YYYY-MM-DD]  
**培训讲师：** [讲师姓名]  
**参与者：** [您的姓名]

## 内容评估

### 内容质量
- [ ] 优秀 - 内容丰富，实用性强
- [ ] 良好 - 内容较好，有一定帮助
- [ ] 一般 - 内容基本满足需求
- [ ] 较差 - 内容不够充实
- [ ] 很差 - 内容质量有问题

### 难度适中性
- [ ] 太简单 - 对我来说过于基础
- [ ] 适中 - 难度刚好合适
- [ ] 太难 - 理解起来有困难

### 实用性
- [ ] 非常实用 - 可以立即应用到工作中
- [ ] 比较实用 - 有一定的应用价值
- [ ] 一般实用 - 部分内容有用
- [ ] 不太实用 - 与实际工作关联不大

## 培训形式评估

### 培训方式
- [ ] 非常满意 - 形式生动有趣
- [ ] 比较满意 - 形式较好
- [ ] 一般 - 形式中规中矩
- [ ] 不太满意 - 形式单调
- [ ] 很不满意 - 形式需要改进

### 时间安排
- [ ] 很合适 - 时间安排合理
- [ ] 比较合适 - 时间基本合理
- [ ] 一般 - 时间安排中等
- [ ] 不太合适 - 时间安排有问题
- [ ] 很不合适 - 时间安排不合理

### 互动参与
- [ ] 很好 - 互动充分，参与度高
- [ ] 较好 - 有一定互动
- [ ] 一般 - 互动中等
- [ ] 较少 - 互动不够
- [ ] 很少 - 缺乏互动

## 学习效果

### 知识掌握
- [ ] 完全掌握 - 对内容理解透彻
- [ ] 基本掌握 - 对大部分内容理解
- [ ] 部分掌握 - 对部分内容理解
- [ ] 掌握较少 - 理解有限
- [ ] 基本没掌握 - 需要进一步学习

### 应用信心
- [ ] 非常有信心 - 可以立即应用
- [ ] 比较有信心 - 经过练习可以应用
- [ ] 一般 - 需要更多学习才能应用
- [ ] 信心不足 - 应用起来有困难
- [ ] 没有信心 - 不知道如何应用

## 具体反馈

### 最有价值的内容
<!-- 请描述您认为最有价值的培训内容 -->

### 需要改进的地方
<!-- 请提出具体的改进建议 -->

### 希望增加的内容
<!-- 请提出希望在后续培训中增加的内容 -->

### 其他建议
<!-- 其他任何建议或意见 -->

## 后续需求

### 希望的培训主题
- [ ] 高级重构技巧
- [ ] 架构设计原则
- [ ] 性能优化实践
- [ ] 安全编程规范
- [ ] 测试驱动开发
- [ ] 其他：[请填写]

### 培训频率偏好
- [ ] 每周一次
- [ ] 每两周一次
- [ ] 每月一次
- [ ] 按需安排

### 培训时长偏好
- [ ] 30分钟
- [ ] 1小时
- [ ] 1.5小时
- [ ] 2小时
- [ ] 其他：[请填写]

## 总体评价

**总体满意度：** ⭐⭐⭐⭐⭐ (请选择1-5星)

**推荐指数：** ⭐⭐⭐⭐⭐ (您会向同事推荐这个培训吗？)

**其他评价：**
<!-- 请提供总体评价和建议 -->

---

**提交日期：** [YYYY-MM-DD]  
**联系方式：** [如果需要进一步沟通，请留下联系方式]
EOF

print_success "Created feedback form template"

# 5. 创建培训记录跟踪文件
print_step "Creating training tracking files..."

cat > "$TRAINING_DIR/training-records.md" << 'EOF'
# 培训记录跟踪

## 培训参与记录

### 第一阶段：基础培训

#### 第1周：KISS 原则基础 (YYYY-MM-DD)
| 参与者 | 出勤 | 作业完成 | 参与度 | 备注 |
|--------|------|----------|--------|------|
| | ✅/❌ | ✅/❌ | ⭐⭐⭐⭐⭐ | |
| | ✅/❌ | ✅/❌ | ⭐⭐⭐⭐⭐ | |

#### 第2周：函数设计与复杂度控制 (YYYY-MM-DD)
| 参与者 | 出勤 | 作业完成 | 参与度 | 备注 |
|--------|------|----------|--------|------|
| | ✅/❌ | ✅/❌ | ⭐⭐⭐⭐⭐ | |
| | ✅/❌ | ✅/❌ | ⭐⭐⭐⭐⭐ | |

## 培训效果跟踪

### 代码质量指标变化

| 指标 | 培训前 | 第1周后 | 第2周后 | 第4周后 | 第8周后 |
|------|--------|---------|---------|---------|---------|
| 平均复杂度 | | | | | |
| 代码重复率 | | | | | |
| 质量评分 | | | | | |
| 技术债务数 | | | | | |

### 个人能力提升跟踪

| 团队成员 | KISS理解 | 重构能力 | 工具使用 | 质量意识 | 总体评价 |
|----------|----------|----------|----------|----------|----------|
| | 初级/中级/高级 | 初级/中级/高级 | 初级/中级/高级 | 初级/中级/高级 | |
| | 初级/中级/高级 | 初级/中级/高级 | 初级/中级/高级 | 初级/中级/高级 | |

## 最佳实践分享记录

### 分享统计
| 分享者 | 分享次数 | 主题 | 质量评分 | 应用效果 |
|--------|----------|------|----------|----------|
| | | | ⭐⭐⭐⭐⭐ | |
| | | | ⭐⭐⭐⭐⭐ | |

### 优秀分享案例
- [日期] [分享者] - [主题] - [简要描述]
- [日期] [分享者] - [主题] - [简要描述]

## 培训反馈汇总

### 满意度统计
- 平均满意度：⭐⭐⭐⭐⭐
- 推荐指数：⭐⭐⭐⭐⭐
- 参与积极性：⭐⭐⭐⭐⭐

### 改进建议汇总
1. [改进建议1]
2. [改进建议2]
3. [改进建议3]

### 后续培训需求
- [需求1] - [需求人数]
- [需求2] - [需求人数]
- [需求3] - [需求人数]
EOF

print_success "Created training records template"

# 6. 设置培训提醒
print_step "Setting up training reminders..."

# 创建培训提醒脚本
cat > "scripts/training-reminder.js" << 'EOF'
#!/usr/bin/env node

/**
 * 培训提醒脚本
 * 用于发送培训通知和跟踪培训进度
 */

const fs = require('fs');
const path = require('path');

class TrainingReminder {
  constructor() {
    this.projectRoot = process.cwd();
    this.trainingDir = path.join(this.projectRoot, '.kiro', 'training');
  }

  /**
   * 检查即将到来的培训
   */
  checkUpcomingTraining() {
    console.log('📅 Checking upcoming training sessions...');
    
    // 这里可以添加培训日程检查逻辑
    // 例如：读取培训计划，检查即将到来的培训
    
    const today = new Date();
    const dayOfWeek = today.getDay(); // 0 = Sunday, 5 = Friday
    
    if (dayOfWeek === 5) { // Friday
      console.log('🎓 Reminder: Weekly training session today at 15:00!');
      console.log('📋 Please prepare:');
      console.log('  - Review last week\'s materials');
      console.log('  - Complete assigned exercises');
      console.log('  - Prepare questions for discussion');
    } else if (dayOfWeek === 4) { // Thursday
      console.log('🔔 Reminder: Training session tomorrow (Friday) at 15:00');
      console.log('📚 Don\'t forget to:');
      console.log('  - Finish your homework');
      console.log('  - Review training materials');
    }
  }

  /**
   * 检查培训作业完成情况
   */
  checkHomeworkStatus() {
    console.log('📝 Checking homework status...');
    
    // 这里可以添加作业检查逻辑
    // 例如：检查 PR 提交情况，代码改进情况等
    
    console.log('💡 Tip: Use the following commands to check your progress:');
    console.log('  - npm run quality-check (check code quality)');
    console.log('  - node scripts/quality-dashboard.js (generate report)');
    console.log('  - git log --oneline (check recent commits)');
  }

  /**
   * 主执行函数
   */
  run() {
    console.log('🎓 Training Reminder System');
    console.log('==========================');
    
    this.checkUpcomingTraining();
    console.log('');
    this.checkHomeworkStatus();
    
    console.log('');
    console.log('📚 Training Resources:');
    console.log('  - KISS Principles Guide: .kiro/training/kiss-principles-guide.md');
    console.log('  - Training Schedule: .kiro/training/training-schedule.md');
    console.log('  - Exercise Files: .kiro/training/exercises/');
    console.log('');
    console.log('❓ Questions? Contact your training coordinator!');
  }
}

// 运行脚本
if (require.main === module) {
  const reminder = new TrainingReminder();
  reminder.run();
}

module.exports = TrainingReminder;
EOF

chmod +x "scripts/training-reminder.js"
print_success "Created training reminder script"

# 7. 验证设置
print_step "Verifying training setup..."

# 检查关键文件
CRITICAL_FILES=(
    ".kiro/training/kiss-principles-guide.md"
    ".kiro/training/training-schedule.md"
    "scripts/training-reminder.js"
)

ALL_GOOD=true
for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Verified: $file"
    else
        print_warning "Missing: $file"
        ALL_GOOD=false
    fi
done

# 8. 显示使用说明
echo ""
echo "🎉 Training environment setup complete!"
echo ""
echo "📚 Available Resources:"
echo "  📖 KISS Principles Guide: .kiro/training/kiss-principles-guide.md"
echo "  📅 Training Schedule: .kiro/training/training-schedule.md"
echo "  📝 Best Practices Template: .kiro/training/best-practices-template.md"
echo "  🏃 Exercise Files: .kiro/training/exercises/"
echo "  💬 Feedback Forms: .kiro/training/feedback/"
echo ""
echo "🔧 Useful Commands:"
echo "  node scripts/training-reminder.js     # Check training reminders"
echo "  node scripts/quality-dashboard.js     # Generate quality report"
echo "  cd login && npm run quality-check     # Run quality checks"
echo ""
echo "📋 Next Steps:"
echo "  1. Review the training schedule"
echo "  2. Read the KISS principles guide"
echo "  3. Set up weekly training sessions"
echo "  4. Start with the first exercise"
echo ""

if [ "$ALL_GOOD" = true ]; then
    print_success "All critical files are in place!"
else
    print_warning "Some files are missing. Please check the setup."
fi

echo "🚀 Happy learning!"