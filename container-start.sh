#!/bin/bash

echo "🖥️  启动 ttyd Web 终端..."
ttyd -p 7681 -i 0.0.0.0 --writable bash &
TTYD_PID=$!

# 等待 ttyd 启动
sleep 2
echo "✅ ttyd 已启动 (PID: $TTYD_PID) - http://localhost:7681"

echo "🚀 启动 Cloud Code Dev 服务..."
ccr start
