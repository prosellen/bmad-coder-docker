# BMAD Method Docker Image - Copilot Instructions

## Project Overview

This repository contains the Dockerfile and supporting files for the **BMAD Method Test Project** at CGI Germany. The Docker images built from this repository are designed to be used with Coder Templates, which are maintained in a separate repository.

## Architecture & Purpose

- **Purpose**: Create Docker base images for Coder workspace environments
- **Platform Support**: Both arm64 and amd64 Linux systems
- **Integration**: Docker images are consumed by Coder Templates for workspace provisioning
- **Method**: BMAD (Build, Measure, Analyze, Design) Method implementation

## Key Components

### Dockerfile
- Main build file for creating multi-architecture Docker images
- Must support both `linux/arm64` and `linux/amd64` platforms
- Contains BMAD Method files and tools needed for workspace environments

### BMAD Files Structure
- `bmad/bin/bmad-stack`: BMAD stack management script
- `bmad/bmad-files/`: Core BMAD method files
- `bmad/stacks/`: Pre-configured stack templates
  - `node-web/`: Node.js web development stack
  - `python-fastapi/`: Python FastAPI development stack

### MISE Integration
- Each stack contains `mise.toml` configuration files
- MISE (polyglot environment manager) is used for managing development environments
- Environment creation happens during workspace initialization

## Build & Deployment Workflow

1. **Build**: Docker images are built for multiple architectures
   - Command: `docker build --platform linux/amd64 -t ghcr.io/prosellen/bmad-coder-docker:latest .`
   - Images are published to GitHub Container Registry (ghcr.io)

2. **Usage**: Coder Templates reference these images to create workspaces
   - BMAD files are copied to workspace directories during workspace creation
   - MISE scripts set up the development environment based on selected stack

3. **Workspace Creation**: When a workspace is provisioned:
   - Base Docker image is pulled
   - BMAD files are copied to appropriate workspace locations
   - MISE environments are initialized based on stack configuration

## Development Guidelines

### When Modifying Dockerfiles
- Always consider multi-architecture support (arm64 and amd64)
- Ensure BMAD files are correctly copied into the image
- Test builds on both architectures when possible
- Keep image size optimized for faster workspace provisioning

### When Adding New Stacks
- Create a new directory under `bmad/stacks/`
- Include `extensions.txt` for VS Code extensions
- Include `mise.toml` for environment configuration
- Document stack purpose and dependencies

### Environment Management
- Use MISE for version management of tools (Node.js, Python, etc.)
- Keep `mise.toml` files up to date with required tool versions
- Consider dependencies required by the Coder environment

## Important Conventions

- **Image Registry**: ghcr.io/prosellen/bmad-coder-docker
- **Platform Specification**: Always specify `--platform` when building
- **Stack Naming**: Use descriptive names (e.g., `node-web`, `python-fastapi`)
- **File Permissions**: Ensure scripts in `bmad/bin/` are executable

## Related Repositories

- **Coder Templates Repository**: Contains templates that consume these Docker images
- **Workspace Integration**: Images are used as base for Coder workspace environments

## Testing

When making changes:
1. Build the Docker image locally for both architectures
2. Test with Coder Templates if possible
3. Verify BMAD files are accessible in the resulting container
4. Confirm MISE environments can be created successfully

## CGI Germany Context

This is an internal CGI Germany project supporting the BMAD methodology for software development. Consider organizational standards and security requirements when making changes.
