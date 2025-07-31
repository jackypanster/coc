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
