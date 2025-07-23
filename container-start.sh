#!/bin/bash

echo "🎯 启动 Claude 开发环境服务..."

# 只启动 ttyd (Web 终端)
echo "🖥️  启动 ttyd Web 终端..."
echo "🌐 ttyd 终端: http://localhost:7681"

ttyd -p 7681 -i 0.0.0.0 bash
