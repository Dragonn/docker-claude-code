# Claude Code Docker Wrapper

A Docker containerization wrapper for [Claude Code](https://claude.ai/code), allowing you to run Claude Code in an isolated container environment.

## Prerequisites

- Docker installed and running
- Docker permissions configured (able to run `docker` commands)

## Quick Start

### 1. Build the Docker image

```bash
./bin/build
```

This automatically fetches the latest version of Claude Code from npm and builds a Docker image tagged as both `claude-code:<version>` and `claude-code:latest`.

### 2. Run Claude Code

```bash
./bin/claude
```

This starts Claude Code in a Docker container with your current directory mounted as the workspace.

## What Gets Mounted

The `bin/claude` script automatically mounts:
- `~/.claude` - Claude Code configuration directory
- `~/.claude.json` - Claude Code settings file
- `~/.claude.json.backup` - Settings backup file
- Current directory - Mounted at the same absolute path inside the container (preserves host path structure)

## Passing Arguments

You can pass any Claude Code arguments directly:

```bash
./bin/claude --help
./bin/claude --version
```

## Updating to the Latest Version

The build script automatically fetches the latest version from npm, so simply rebuild:

```bash
./bin/build
```

This will pull the latest version of Claude Code and rebuild the image.

## Technical Details

- Base image: `node:22-trixie-slim`
- Claude Code version is fetched dynamically from the npm registry at build time
- Auto-updater is disabled (`DISABLE_AUTOUPDATER=1`) for version consistency
- Container runs as the `claude` user (renamed from `node`, non-root)
- Container is automatically removed after exit (`--rm`)
- Path preservation: The container maintains the same absolute paths as the host
