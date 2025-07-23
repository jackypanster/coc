#!/bin/bash

echo "🎯 启动 Claude 开发环境服务..."

ccr start &

# 启动 ttyd - 最小配置
ttyd -p 7681 -i 0.0.0.0 --writable bash
