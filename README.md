# BMAD Method Docker Image

## Overview

This repository contains the Docker image configuration for the **BMAD Method Test Project** at CGI Germany. It provides multi-architecture base images that are consumed by Coder Templates to provision development workspaces.

The BMAD (Build, Measure, Analyze, Design) Method is implemented through pre-configured stacks that include development tools, environment configurations, and VS Code extensions tailored for specific technology stacks.

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
2. BMAD files are copied to the workspace directory
3. MISE initializes the development environment based on the selected stack
4. VS Code extensions are installed automatically

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
4. Rebuild the Docker image

## Dependencies

### Required Tools
- **Docker**: For building and running the images
- **MISE**: Polyglot environment manager (included in the image)
- **Coder**: For workspace provisioning (deployment environment)

### Runtime Dependencies
- Base image dependencies as specified in the Dockerfile
- Stack-specific tools defined in each `mise.toml`
- VS Code Server (provided by Coder)

### Related Repositories
- **Coder Templates Repository**: Contains templates that consume these Docker images for workspace creation

---

**CGI Germany Internal Project** - Part of the BMAD Method implementation for software development workflows.
