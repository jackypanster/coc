# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Code on Cloud (CoC) is a containerized development environment providing a web-based terminal with tmux session management, xterm.js frontend, SSO authentication and Claude Code integration.

## Common Commands

### Building and Running
```bash
# Build base image (only needed once or when dependencies change)
./build-base.sh

# Quick build using cached base image
./build.sh

# Full rebuild (base + application)
./build-full.sh

# Start with local authentication (development)
AUTH_PROVIDER=local ./start.sh

# Start with SSO authentication (production)
./start.sh  # defaults to SSO
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

# tmux commands (Ctrl+A is prefix)
Ctrl+A | # Split vertical
Ctrl+A - # Split horizontal  
Ctrl+A c # New window
Ctrl+A n # Next window
```

## Architecture

### Container Structure
- **Multi-stage Docker build** for optimization:
  - `Dockerfile.base`: Stable dependencies (Node.js, Python, tools, tmux)
  - `Dockerfile.optimized`: Application layer
  - Base image cached at `registry.cn-beijing.aliyuncs.com/zhibinpan/coc-base:latest`

### Authentication System (Pluggable)
- **AuthProvider Interface**: Base class for all authentication implementations
- **AuthManager**: Loads and manages authentication providers
- **Authentication Modes**:
  - `AUTH_PROVIDER=sso`: Enterprise SSO (OAuth2.0) - Production
  - `AUTH_PROVIDER=local`: Local development mode - Any username/password
  - Custom providers can be added in `login/auth-providers/`

### Authentication Flow
1. User accesses web terminal → Nginx checks authentication
2. Unauthenticated → Redirect to login page
3. Authentication via selected provider (SSO/Local/Custom)
4. Session cookie set → Access granted to terminal (xterm.js + tmux)

### Key Components
- **Login Server** (`login/server.js`): Express app with pluggable auth
- **Auth Providers** (`login/auth-providers/`): Modular authentication implementations
- **Nginx** (`login/nginx.conf`): Reverse proxy routing and auth enforcement
- **Terminal Stack**:
  - **xterm.js**: Frontend terminal emulator in `login/terminal.html`
  - **ttyd**: WebSocket terminal server on port 7681
  - **tmux**: Session management with persistence
- **Session Management**: Configurable per auth provider

## Configuration

### Environment Variables
- Authentication mode: `AUTH_PROVIDER=sso|local` (default: sso)
- SSO credentials: Set in `.env` file (GFT_CLIENT_ID, GFT_CLIENT_SECRET)
- Versions: Managed in `versions.env` (NODE_VERSION, CLAUDE_VERSION, etc.)
- Claude Code Router: Configure in `config.json`

### Important Files
- `login/server.js`: Main server with authentication hooks
- `login/terminal.html`: xterm.js based terminal interface
- `login/auth-provider.js`: Authentication provider interface
- `login/auth-manager.js`: Authentication management system
- `tmux.conf`: tmux configuration for development
- `login/auth-providers/`: Authentication implementations (SSO, Local, etc.)
- `doc/auth-provider-guide.md`: Guide for creating custom auth providers
- `doc/sso-integration.md`: SSO setup guide
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