# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Code on Cloud (CoC) is a containerized development environment providing a web-based terminal (ttyd) with SSO authentication and Claude Code integration.

## Common Commands

### Building and Running
```bash
# Build base image (only needed once or when dependencies change)
./build-base.sh

# Quick build using cached base image
./build.sh

# Full rebuild (base + application)
./build-full.sh

# Start the container (mounts current directory to /workspace)
./start.sh
```

### Development Inside Container
```bash
# Run Python scripts
uv run script.py

# Node.js development
npm install
npm run dev
npm test

# Claude Code commands
claude
claude-code-router
```

## Architecture

### Container Structure
- **Multi-stage Docker build** for optimization:
  - `Dockerfile.base`: Stable dependencies (Node.js, Python, tools)
  - `Dockerfile.optimized`: Application layer
  - Base image cached at `registry.cn-beijing.aliyuncs.com/zhibinpan/coc-base:latest`

### Authentication Flow
1. User accesses web terminal → Nginx checks authentication
2. Unauthenticated → Redirect to login page (pixel-art UI)
3. SSO authentication via iframe and PostMessage
4. Session cookie set → Access granted to ttyd terminal

### Key Components
- **Login Server** (`login/server.js`): Express app handling SSO OAuth2.0 flow
- **Nginx** (`login/nginx.conf`): Reverse proxy routing and auth enforcement
- **ttyd**: Web terminal server running on port 7681
- **Session Management**: 12-hour max session, 1-hour inactivity timeout

## Configuration

### Environment Variables
- SSO credentials: Set in `.env` file (CLIENT_ID, CLIENT_SECRET, DOMAIN)
- Versions: Managed in `versions.env` (NODE_VERSION, CLAUDE_VERSION, etc.)
- Claude Code Router: Configure in `config.json`

### Important Files
- `login/server.js`: Authentication logic and session management
- `login/login.html`: SSO integration UI
- `sso-integration.md`: Complete SSO setup guide
- `versions.env`: Component version management

## Testing and Debugging

### SSO Authentication
- Check logs: `docker logs coc`
- Verify `.env` configuration
- Test SSO redirect URLs match configuration

### Container Access
- Web terminal: http://localhost (after authentication)
- Direct container shell: `docker exec -it coc /bin/bash`

## Security Considerations
- Never commit `.env` files with credentials
- Session cookies are HTTP-only
- SSO tokens validated server-side
- Sensitive data masked in logs

## Development Tips
- Volume mount at `/workspace` persists code changes
- All development tools pre-installed in container
- Use `uv` for Python package management
- Claude Code available globally in terminal