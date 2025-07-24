# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Tasks

### Build and Run
- **Build Docker Image**: `./build.sh`
- **Start Container**: `./start.sh`
- **Stop Container**: `docker stop cloud-code-dev`
- **View Logs**: `docker logs cloud-code-dev`

### Key Services
- **ttyd Web Terminal**: Accessible at `http://localhost:7681`
- **Cloud Code Dev**: Runs `ccr start` inside the container

## High-Level Architecture
- **Dockerized Environment**: Uses Debian base with Node.js `${NODE_VERSION}`
- **ttyd Terminal**: Served on port 7681 with persistent session
- **Dependency Versions**: Managed through `versions.env` for consistent builds
- **Configuration**: `/root/.claude-code-router/config.json` mounted from host