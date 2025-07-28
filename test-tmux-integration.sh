#!/bin/bash

echo "🧪 Testing tmux and xterm.js integration..."
echo ""

# Check if base image needs rebuild
echo "1️⃣ Checking if base image needs rebuild (tmux added)..."
if docker image inspect code-on-cloud-base:v1.0.0 > /dev/null 2>&1; then
    echo "   ⚠️  Base image exists. You may need to run ./build-base.sh to add tmux"
else
    echo "   ❌ Base image not found. Please run ./build-base.sh first"
    exit 1
fi

echo ""
echo "2️⃣ Building application image with tmux config..."
./build.sh

echo ""
echo "3️⃣ Starting container with tmux integration..."
./start.sh

echo ""
echo "✅ Container started with tmux integration!"
echo ""
echo "📋 Test steps:"
echo "   1. Open http://localhost in your browser"
echo "   2. Login with any username/password (local mode)"
echo "   3. You should see the new xterm.js terminal interface"
echo "   4. Terminal should automatically start in tmux session 'main'"
echo "   5. Try tmux shortcuts:"
echo "      - Ctrl+A then | : Split vertical"
echo "      - Ctrl+A then - : Split horizontal"
echo "      - Ctrl+A then c : New window"
echo "      - Ctrl+A then n : Next window"
echo ""
echo "🔍 To check container logs:"
echo "   docker logs -f cloud-code-dev"