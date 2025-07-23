#!/bin/bash

echo "🎯 启动 Claude 开发环境服务..."

# 启动 ttyd (Web 终端)
echo "🖥️  启动 ttyd Web 终端..."
ttyd -p 7681 -i 0.0.0.0 bash &

# 启动 claude-code-router
echo "🔄 启动 Claude Code Router..."
ccr code

# 等待服务启动
sleep 3

echo "✅ 所有服务已启动！"
echo "🌐 ttyd 终端: http://localhost:7681"

# 保持容器运行
wait
