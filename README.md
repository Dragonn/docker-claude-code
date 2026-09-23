# Claude Code in Docker

Run [Claude Code](https://www.claude.com/product/claude-code) in a locally-built
Docker container. No Node.js on the host. The image bundles a handful of
everyday CLI tools, supports **headless OAuth login** (no browser, no published
ports), read-only reference mounts, and an optional set of local **MCP servers**.

## Install

Build the image and install the host scripts:

```bash
git clone https://github.com/Dragonn/docker-claude-code
cd docker-claude-code
make build            # build my-claude-code:latest
make user-install     # install scripts to ~/.local/bin (+ PATH)
# or: sudo make install   # system-wide to /usr/local/bin
```

`make build` accepts `VERSION=` to pin a claude-code release and `USER_ID=` to
bake a uid (defaults to your own, so bind-mounted files stay correctly owned).

Then run from any project directory:

```bash
cd ~/my-project
claude
```

## Usage

```bash
claude                         # interactive
claude "fix the bug"           # run a prompt
claude -R ../reference-repo    # extra read-only mount at /mnt/ro/reference-repo
```

- Mounts your project (cwd), `~/.claude` and `~/.claude.json` into the container.
- `-R/--ro-mount DIR` (repeatable) exposes a host dir read-only at
  `/mnt/ro/<basename>`.
- All user settings live in a single sourced config file,
  `~/.config/claude-docker.conf` (override with `CLAUDE_DOCKER_CONFIG`).
  `make install` / `make user-install` create it from
  [`config.example`](config.example) if absent (never overwriting an existing
  one), and the uninstall targets remove it. Set the image, always-on
  documentation mounts (`doc_mounts`), and extra `docker run` args there.
  Run `make config` to open it in your editor (`$VISUAL`/`$EDITOR`).
- Refuses to run from system directories (`/`, `/etc`, `/usr`, …).

## Headless login

Log in from a container with no browser and no published ports (any number of
containers can log in at once). On the host, start the watcher **before** you run
`/login`:

```bash
claude-login-watcher            # watches ~/.claude by default
```

Inside the container, `/login` hands the OAuth URL to `dgx-open` (the container's
`$BROWSER`), which writes it to a bind-mounted file. The watcher opens it in a
real browser, catches the callback, and delivers the code back into the container
via `docker exec`.

## Bundled tools

The image includes: `git` (+ delta), `vim`, `sudo`, `curl`, `wget`, `jq`, `yq`,
`ripgrep`, `less`, `kubectl`, `pup`, `python3`, and `libxml2-utils`.

## MCP servers

`mcp/` has a small `make`-based manager for running MCP servers in Docker and
registering them with Claude Code. `context7` and `playwright` work out of the
box; `prometheus`, `elasticsearch` and `grafana` are included as URL/token-gated
templates. See [mcp/README.md](mcp/README.md).

## Uninstall

```bash
make user-uninstall     # or: sudo make uninstall
make clean              # remove the local image
```

## License

Released under the [MIT License](https://opensource.org/license/mit).
