# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker containerization wrapper for Claude Code. It builds a Docker image that runs the `@anthropic-ai/claude-code` npm package in an isolated container environment.

## Architecture

The repository consists of three main components:

1. **Dockerfile**: Builds a container based on `node:22-trixie-slim`, installs Claude Code globally via npm, renames the default `node` user to `claude`, and sets the entrypoint to run the `claude` command
2. **bin/build**: Shell script that builds the Docker image and tags it with the version number (defined in `version` variable) and as `latest`
3. **bin/claude**: Shell script that runs the Claude Code container with appropriate volume mounts for configuration and the current working directory. Includes safety checks to prevent mounting dangerous system directories.

## Common Commands

### Build the Docker image
```bash
./bin/build
```

This builds the Docker image and tags it as both `claude-code:${version}` and `claude-code:latest`.

### Run Claude Code in Docker
```bash
./bin/claude [arguments]
```

This runs Claude Code in a container with:
- Configuration files mounted from `~/.claude`, `~/.claude.json`, and `~/.claude.json.backup`
- Current directory mounted at the same absolute path inside the container (preserves host path structure)
- Runs as the current user (via `--user "$(id -u):$(id -g)"`)
- Interactive TTY mode enabled
- Container auto-removed after exit

## Key Details

- **Version Management**: The Claude Code version is fetched dynamically from the npm registry API at build time. The `bin/build` script queries `https://registry.npmjs.org/@anthropic-ai/claude-code/latest` to get the latest version, which is then passed as a build arg to the Dockerfile and used for image tagging.
- **Auto-updater**: Disabled via `DISABLE_AUTOUPDATER=1` environment variable (Dockerfile:10) to ensure consistent versioning in the containerized environment.
- **Path Preservation**: Unlike typical Docker setups, the container preserves the host's absolute path structure. If you run from `/home/user/project`, the container working directory is also `/home/user/project`.
- **Safety Checks**: The `bin/claude` script (lines 8-14) prevents running from dangerous system directories like `/`, `/etc`, `/usr`, etc., to avoid accidentally mounting critical system paths.

## Bash Script Conventions

All bash scripts in this repository follow these conventions:

- **Variable Quoting**: Always use `"${variable}"` (quoted with curly braces) for consistency and safety
- **Variable Naming**:
  - Use lowercase or snake_case for script-local variables: `version`, `host_path`, `context`
  - Use UPPERCASE for environment variables: `HOME`, `VERSION`, `DISABLE_AUTOUPDATER`
- **Error Handling**: All scripts use `set -euo pipefail` for strict error handling
- **Shebang**: Use `#!/usr/bin/env bash` for portability
