# Claude Code in Docker

Run [Claude Code](https://www.claude.com/product/claude-code) in a Docker container. No Node.js installation required. Uses [`peterkuczera/claude-code`](https://hub.docker.com/r/peterkuczera/claude-code) on Docker Hub, automatically updated with new Claude Code releases.

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

The `claude` script runs a Docker container with:
- Your config files (`~/.claude`, `~/.claude.json`) mounted so API keys and settings persist
- Your current directory mounted so Claude Code can access your project files
- Your user ID so files created have correct ownership

The latest image is automatically pulled, so you always get the newest Claude Code version.

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

## Building Locally

For contributors or those wanting to customize the image:

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
