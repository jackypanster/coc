module.exports = {
  env: {
    node: true,
    es2021: true,
  },
  extends: [
    'eslint:recommended',
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module',
  },
  rules: {
    // KISS 原则相关规则 - 复杂度控制
    'complexity': ['error', { max: 10 }], // 圈复杂度不超过10
    'max-lines-per-function': ['error', { max: 50, skipBlankLines: true, skipComments: true }], // 函数不超过50行
    'max-params': ['error', { max: 5 }], // 参数不超过5个
    'max-depth': ['error', { max: 4 }], // 嵌套深度不超过4层
    'max-nested-callbacks': ['error', { max: 3 }], // 回调嵌套不超过3层
    'max-lines': ['warn', { max: 300, skipBlankLines: true, skipComments: true }], // 文件行数限制
    'max-statements': ['warn', { max: 20 }], // 语句数量限制
    'max-statements-per-line': ['error', { max: 1 }], // 每行语句数限制
    
    // 代码质量规则
    'prefer-const': 'error',
    'no-var': 'error',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'no-console': 'warn',
    'no-debugger': 'error',
    'no-alert': 'error',
    
    // 简洁性规则
    'no-else-return': 'error', // 避免不必要的 else
    'no-lonely-if': 'error', // 避免孤立的 if
    'no-unneeded-ternary': 'error', // 避免不必要的三元运算符
    'prefer-template': 'error', // 优先使用模板字符串
    'object-shorthand': 'error', // 对象简写
    'prefer-arrow-callback': 'error', // 优先使用箭头函数
    
    // 可读性规则
    'camelcase': 'error',
    'consistent-return': 'error',
    'no-magic-numbers': ['warn', { 
      ignore: [0, 1, -1, 2, 10, 100, 1000],
      ignoreArrayIndexes: true,
      enforceConst: true
    }],
    'no-multiple-empty-lines': ['error', { max: 2, maxEOF: 1 }],
    'semi': ['error', 'always'],
    'quotes': ['error', 'single', { avoidEscape: true }],
    'comma-dangle': ['error', 'always-multiline'],
    'indent': ['error', 2, { SwitchCase: 1 }],
    
    // 函数设计规则
    'func-style': ['error', 'declaration', { allowArrowFunctions: true }],
    'no-param-reassign': 'error',
    'prefer-rest-params': 'error',
    'prefer-spread': 'error',
    
    // 错误处理规则
    'no-throw-literal': 'error',
    'prefer-promise-reject-errors': 'error',
    
    // 性能相关规则
    'no-loop-func': 'error',
    'no-await-in-loop': 'warn',
  },
  overrides: [
    {
      files: ['**/*.test.js', '**/*.spec.js'],
      rules: {
        'no-magic-numbers': 'off', // 测试文件中允许魔法数字
        'max-lines-per-function': 'off', // 测试函数可以更长
      }
    }
  ]
};