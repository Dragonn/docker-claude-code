# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker containerization wrapper for Claude Code. It builds a Docker image that runs the `@anthropic-ai/claude-code` npm package in an isolated container environment and provides an installer for end users.

## Architecture

The repository consists of three main components:

1. **Dockerfile**: Builds a container based on `node:22-trixie-slim`, installs Claude Code globally via npm, renames the default `node` user to `claude`, and sets the entrypoint to run the `claude` command
2. **bin/build**: Shell script that builds the Docker image and tags it with the version number (fetched dynamically from npm) and as `latest`
3. **install.sh**: Installer that creates a wrapper script at `~/.local/bin/claude` and adds `~/.local/bin` to PATH if needed. The wrapper script runs the Docker container with appropriate volume mounts and safety checks.

## Common Commands

### Build the Docker image locally
```bash
./bin/build
```

This builds the Docker image and tags it as both `claude-code:${version}` and `claude-code:latest`.

### Install the wrapper script for local testing
```bash
DOCKER_IMAGE=claude-code:latest bash install.sh
```

This installs the wrapper script configured to use your locally built image instead of the published one.

### Run without installing (for quick testing)
```bash
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -v "${HOME}/.claude:${HOME}/.claude" \
  -v "${HOME}/.claude.json:${HOME}/.claude.json" \
  -v "$(pwd):$(pwd)" \
  -w "$(pwd)" \
  -e HOME="${HOME}" \
  claude-code:latest
```

## Key Details

- **Version Management**: The Claude Code version is fetched dynamically from the npm registry API at build time. The `bin/build` script queries `https://registry.npmjs.org/@anthropic-ai/claude-code/latest` to get the latest version, which is then passed as a build arg to the Dockerfile and used for image tagging.
- **Auto-updater**: Disabled via `DISABLE_AUTOUPDATER=1` environment variable to ensure consistent versioning in the containerized environment.
- **Path Preservation**: Unlike typical Docker setups, the container preserves the host's absolute path structure. If you run from `/home/user/project`, the container working directory is also `/home/user/project`.
- **Safety Checks**: The installed wrapper script prevents running from dangerous system directories like `/`, `/etc`, `/usr`, etc., to avoid accidentally mounting critical system paths.
- **Installation Approach**: The `install.sh` script installs a standalone wrapper script to `~/.local/bin/claude` rather than modifying shell configs with functions. It only appends to shell config if `~/.local/bin` is not already in PATH.
- **Docker Image Override**: Set the `DOCKER_IMAGE` environment variable when running `install.sh` to use a different image (useful for local development: `DOCKER_IMAGE=claude-code:latest bash install.sh`).

## Bash Script Conventions

All bash scripts in this repository follow these conventions:

- **Variable Quoting**: Always use `"${variable}"` (quoted with curly braces) for consistency and safety
- **Variable Naming**:
  - Use lowercase or snake_case for script-local variables: `version`, `host_path`, `context`
  - Use UPPERCASE for environment variables: `HOME`, `VERSION`, `DISABLE_AUTOUPDATER`
- **Error Handling**: All scripts use `set -euo pipefail` for strict error handling
- **Shebang**: Use `#!/usr/bin/env bash` for portability
