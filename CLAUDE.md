# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Tasks

### Build and Run
- **Build Docker Image**: `./build.sh`
- **Start Container**: `./start.sh`
- **Stop Container**: `docker stop cloud-code-dev`
- **View Logs**: `docker logs cloud-code-dev`

### Testing
- **Run All Tests**: `docker exec cloud-code-dev npm test`
- **Run Single Test**: `docker exec cloud-code-dev npm test -- --testNamePattern="<test-name>"`

### Linting
- **Type Check**: `docker exec cloud-code-dev npm run typecheck`
- **Code Lint**: `docker exec cloud-code-dev npm run lint`

## High-Level Architecture
- **Dockerized Environment**: Debian base with Node.js `${NODE_VERSION}`
- **ttyd Terminal**: Persistent web terminal at `http://localhost:7681`
- **Dependency Versions**: Locked via `versions.env` for deterministic builds
- **Configuration**: Mounted config at `/root/.claude-code-router/config.json`
- **Service Structure**: Node.js application orchestrated with Docker Compose