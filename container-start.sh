#!/bin/bash

# Load environment variables if .env file exists
if [ -f "/app/.env" ]; then
    echo "📋 Loading environment variables from .env file..."
    # More robust way to load .env file
    set -a  # automatically export all variables
    source /app/.env
    set +a  # disable automatic export
    echo "✅ .env file loaded successfully"
else
    echo "⚠️  .env file not found at /app/.env, using environment variables"
fi

# Debug: Show current environment variables (without secrets)
echo "🔍 Current SSO configuration:"
echo "- GFT_OAUTH_URL: ${GFT_OAUTH_URL:-'not set'}"
echo "- GFT_CLIENT_ID: ${GFT_CLIENT_ID:-'not set'}"
echo "- GFT_CLIENT_SECRET: ${GFT_CLIENT_SECRET:+'***set***'}"

# Validate required SSO configuration
if [ -z "$GFT_CLIENT_ID" ] || [ -z "$GFT_CLIENT_SECRET" ]; then
    echo "❌ Error: Missing required SSO configuration"
    echo "Please set the following environment variables:"
    echo "- GFT_CLIENT_ID: SSO application ID"
    echo "- GFT_CLIENT_SECRET: SSO application secret"
    echo "- GFT_OAUTH_URL: SSO login URL (optional, has default)"
    echo "- GFT_TOKEN_URL: SSO token exchange URL (optional, has default)"
    echo "- GFT_USERINFO_URL: SSO user info URL (optional, has default)"
    echo ""
    echo "You can either:"
    echo "1. Set environment variables when running docker"
    echo "2. Create a .env file in the project root"
    exit 1
fi

echo "✅ SSO configuration validated: Client ID = $GFT_CLIENT_ID"

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
