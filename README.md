# BMAD Method Docker Image

## Overview

This repository contains the Docker image configuration for the **BMAD Method Test Project** at CGI Germany. It provides multi-architecture base images that are consumed by Coder Templates to provision development workspaces.

The BMAD (Build, Measure, Analyze, Design) Method is implemented through pre-configured stacks that include development tools, environment configurations, and VS Code extensions tailored for specific technology stacks.

### Architecture

The image uses a **global installation model** to avoid shadowing issues with Kubernetes persistent volume mounts:
- **Global Tools**: Java, Node.js, Python, and other runtimes are installed to system paths (via MISE)
- **Configuration at `/usr/local/config`**: MISE configuration and BMAD files stored outside the user home directory
- **Runtime Initialization**: User configurations are copied to the persistent volume at workspace startup
- **Volume Mount Safe**: The `/home/coder` directory can be mounted as a persistent volume without hiding installed tools

## What It Provides

### Multi-Architecture Docker Images
- **Platforms**: Supports both `linux/arm64` and `linux/amd64`
- **Registry**: Published to `ghcr.io/prosellen/bmad-coder-docker`
- **Purpose**: Base images for Coder workspace environments

### BMAD Method Files
- **Stack Management**: `bmad/bin/bmad-stack` script for managing development stacks
- **Core Files**: `bmad/bmad-files/` containing BMAD methodology resources
- **Pre-configured Stacks**:
  - `node-web`: Node.js web development stack
  - `python-fastapi`: Python FastAPI development stack

### Stack Components
Each stack includes:
- `mise.toml`: Environment configuration for MISE (polyglot environment manager)
- `extensions.txt`: VS Code extensions specific to the stack
- Pre-configured tool versions and dependencies

## Installation Model

### Global Tool Installation
Tools are installed globally during the Docker build process:
- Located at paths managed by MISE (typically `/root/.mise/installs` or similar)
- Available to all users automatically
- MISE shims configured in `/etc/bash.bashrc` and `/etc/bash.bash_profile`
- Environment variable `MISE_GLOBAL_CONFIG_FILE` points to `/usr/local/config/mise.toml`

### Configuration Storage
- **System Config**: `/usr/local/config/mise.toml` (global configuration)
- **BMAD Files**: `/usr/local/config/project/` (BMAD methodology files)
- **User Config**: Copied to `$HOME/mise.toml` at workspace startup (if not already present)
- **User Project**: `/home/coder/project/` (persistent volume mount in Coder)

### Persistence in Coder Workspaces
When used with Coder:
1. The persistent volume is mounted to `/home/coder`
2. Startup script copies BMAD files from `/usr/local/config/project/` to `$HOME/project/`
3. User configurations persist across workspace restarts
4. Global tools remain available without re-installation

## How to Use

### Building the Docker Image

For AMD64 (x86_64):
```bash
docker build --platform linux/amd64 -t ghcr.io/prosellen/bmad-coder-docker:latest .
```

For ARM64 (Apple Silicon, ARM servers):
```bash
docker build --platform linux/arm64 -t ghcr.io/prosellen/bmad-coder-docker:latest .
```

### Using with Coder Templates

This image is designed to be referenced in Coder Templates (maintained in a separate repository). During workspace creation:

1. The Docker image is pulled as the base environment
2. Global tools (Java, Node.js, Python, etc.) are immediately available
3. BMAD files are copied to the workspace's persistent volume at startup
4. User configurations are initialized in the persistent volume
5. VS Code extensions are installed automatically via the Coder template

**Key Benefit**: Unlike previous approaches, the persistent volume mount does not shadow any installed tools or configurations, because everything is installed globally outside of `/home/coder`.

### Adding New Stacks

To add a new development stack:

1. Create a new directory under `bmad/stacks/` with a descriptive name
2. Add `mise.toml` with required tool versions:
   ```toml
   [tools]
   node = "20.11.0"
   python = "3.12.0"
   ```
3. Add `extensions.txt` with VS Code extension IDs (one per line)
4. The main `config/mise.toml` will be updated separately to define global tools
5. Rebuild the Docker image

## Dependencies

### Required Tools
- **Docker**: For building and running the images
- **MISE**: Polyglot environment manager (included in the image)
- **Coder**: For workspace provisioning (deployment environment)

### Build-Time Dependencies
- Base: Ubuntu latest
- MISE: Installed via https://mise.run
- Build tools: Git, curl, build-essential, and other utilities
- Locale: German (de_DE.UTF-8) configured by default

### Runtime Dependencies
- Stack-specific tools defined in `config/mise.toml`
- Base system utilities installed in the Dockerfile
- VS Code Server (provided by Coder)
- BMAD stack files available at `/usr/local/config/project/`

### Related Repositories
- **Coder Templates Repository**: Contains templates that consume these Docker images for workspace creation
  - Handles copying BMAD files to persistent volume
  - Manages startup initialization scripts
  - Configures VS Code and extensions

---

**CGI Germany Internal Project** - Part of the BMAD Method implementation for software development workflows.
