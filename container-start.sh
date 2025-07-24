#!/bin/bash

# Start ttyd in the background, listening on a local-only port
echo "🚀 Starting ttyd service..."
cd /workspace && ttyd --port 7681 --interface 127.0.0.1 --writable bash > /var/log/ttyd.log 2>&1 &
TTYD_PID=$!
sleep 2
echo "✅ ttyd is running (PID: $TTYD_PID) on port 7681"

# Start the login server in the background
echo "🚀 Starting login server..."
(cd /app/login && node server.js > /var/log/login.log 2>&1) &
LOGIN_PID=$!
sleep 2
echo "✅ Login server is running (PID: $LOGIN_PID) on port 3000"

# Start Nginx in the foreground
echo "🚀 Starting Nginx reverse proxy..."
nginx -g 'daemon off;'

# Basic process management
wait $TTYD_PID
wait $LOGIN_PID
