# Claude Code Docker Wrapper

Run [Claude Code](https://www.claude.com/product/claude-code) in a Docker container.

Avoid installing Node and running `npm install -g` to use Claude Code. Instead, simply run the Docker container and mount your config files and current working directory.

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

## Automated Builds

Docker images are automatically published to [Docker Hub](https://hub.docker.com/r/peterkuczera/claude-code) daily via GitHub Actions. The workflow:
- Checks for new Claude Code versions on npm every day at midnight UTC
- Only builds and publishes if a new version is detected
- Tags images with both the version number and `latest`
- Builds multi-platform images (linux/amd64, linux/arm64)

### GitHub Secrets Required

To enable automated publishing, configure these secrets in your GitHub repository settings:

- `DOCKER_HUB_USERNAME` - Your Docker Hub username
- `DOCKER_HUB_TOKEN` - A Docker Hub access token (create at https://hub.docker.com/settings/security)

### Manual Builds

You can trigger builds manually via the "Actions" tab in GitHub:
- **Normal run**: Checks for new npm version and only builds if a new version is found
- **Force rebuild**: Check the "Force rebuild" option to rebuild and republish even if the version already exists (useful when you've made changes to the Dockerfile or build configuration)

## Technical Details

- Base image: `node:22-trixie-slim`
- Claude Code version is fetched dynamically from the npm registry at build time
- Auto-updater is disabled (`DISABLE_AUTOUPDATER=1`) for version consistency
- Container runs as the `claude` user (renamed from `node`, non-root)
- Container is automatically removed after exit (`--rm`)
- Path preservation: The container maintains the same absolute paths as the host
