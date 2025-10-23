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

This builds a Docker image with Claude Code version 2.0.25 and tags it as both `claude-code:2.0.25` and `claude-code:latest`.

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
- Current directory (`$PWD`) - Mounted to `/mnt/claude` as the workspace

## Passing Arguments

You can pass any Claude Code arguments directly:

```bash
./bin/claude --help
./bin/claude --version
```

## Updating the Version

To update to a different Claude Code version:

1. Edit `bin/build` and change the `version` variable
2. Rebuild the image: `./bin/build`

## Technical Details

- Base image: `node:22-trixie-slim`
- Claude Code is installed globally via npm
- Auto-updater is disabled (`DISABLE_AUTOUPDATER=1`) for version consistency
- Container runs as the `node` user (non-root)
- Container is automatically removed after exit (`--rm`)
