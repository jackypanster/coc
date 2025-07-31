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
