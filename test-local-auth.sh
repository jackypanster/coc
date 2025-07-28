#!/bin/bash

echo "🧪 测试本地认证模式"
echo "========================"

# 检查容器是否运行
if ! docker ps | grep -q coc; then
    echo "❌ 容器未运行，请先启动容器: AUTH_PROVIDER=local ./start.sh"
    exit 1
fi

echo "✅ 容器正在运行"

# 测试登录页面
echo -n "📄 测试登录页面访问... "
if curl -s http://localhost/login | grep -q "LOCAL DEV MODE"; then
    echo "✅ 成功"
else
    echo "❌ 失败"
    exit 1
fi

# 测试认证端点
echo -n "🔐 测试本地认证... "
RESPONSE=$(curl -s -X POST http://localhost/login/local \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass"}' \
  -c cookies.txt)

if echo "$RESPONSE" | grep -q "success"; then
    echo "✅ 成功"
    echo "   响应: $RESPONSE"
else
    echo "❌ 失败"
    echo "   响应: $RESPONSE"
    exit 1
fi

# 测试认证后访问
echo -n "🌐 测试认证后访问主页... "
if curl -s -b cookies.txt http://localhost/ | grep -q "ttyd"; then
    echo "✅ 成功"
else
    echo "❌ 失败"
    exit 1
fi

# 清理
rm -f cookies.txt

echo ""
echo "🎉 所有测试通过！本地认证模式工作正常。"
echo ""
echo "提示："
echo "- 生产环境请使用 AUTH_PROVIDER=sso"
echo "- 查看详细日志: docker logs coc"