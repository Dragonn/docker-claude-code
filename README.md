# Claude Code in Docker

Run [Claude Code](https://www.claude.com/product/claude-code) in Docker without installing Node.js or npm.

```bash
claude --help
```

That's it. No `npm install -g`, no Node.js version conflicts.

## Installation

Run this one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/peterkuczera/docker-claude-code/refs/heads/main/install.sh | bash
```

Then run Claude Code from any project directory:

```bash
cd ~/my-project
claude
```

[View install script](https://raw.githubusercontent.com/peterkuczera/docker-claude-code/refs/heads/main/install.sh)

## How It Works

The `claude` script runs a Docker container that mounts:
- **Your config** (`~/.claude`, `~/.claude.json`) - API keys and settings persist
- **Current directory** - At the same absolute path inside the container
- **Your user ID** - Files created have correct ownership

The container automatically pulls the latest image, so you always get the newest Claude Code version.

## Examples

```bash
claude                    # Interactive mode
claude --help             # Show help
claude --version          # Show version
claude "fix the bug"      # Run a prompt directly
```

## Troubleshooting

**Running from system directories blocked**

The script blocks mounting `/`, `/etc`, `/usr`, etc. Run from a user directory instead.

## Updates

Images are published to [Docker Hub](https://hub.docker.com/r/peterkuczera/claude-code) automatically when new Claude Code versions are released. The `--pull=always` flag in the script ensures you get the latest version.

To update manually:
```bash
docker pull peterkuczera/claude-code:latest
```

## Building Locally

Build the image yourself:

```bash
git clone https://github.com/peterkuczera/docker-claude-code.git
cd docker-claude-code
./bin/build
```

Then install the wrapper to use your local build:

```bash
DOCKER_IMAGE=claude-code:latest ./install.sh
```

See [CLAUDE.md](CLAUDE.md) for development details and architecture.

## License

docker-claude-code is released under the [MIT License](https://opensource.org/license/mit).
