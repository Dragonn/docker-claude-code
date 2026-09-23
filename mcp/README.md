# Local MCP servers

A tiny `make`-based manager for running MCP servers in Docker on the host and
registering them with Claude Code running inside the container.

Because Claude Code runs inside a container, it reaches the servers on the host
via the docker bridge gateway (`172.17.0.1`), not `localhost` — see `MCP_HOST`
in the [`Makefile`](./Makefile).

## Usage

```sh
make run      # start the enabled servers as docker containers
make setup    # print the `claude mcp add ...` commands to register them
make status   # show container state
make stop     # stop & remove them
```

Enable a different set for a single invocation:

```sh
make ENABLED="context7 playwright prometheus" run
```

## Included servers

| Name            | Needs config           | Notes                                        |
|-----------------|------------------------|----------------------------------------------|
| `context7`      | none                   | Up-to-date library docs (enabled by default) |
| `playwright`    | none                   | Headless browser automation (default)        |
| `prometheus`    | `PROMETHEUS_URL`       | Read-only PromQL — example, disabled         |
| `elasticsearch` | `ES_URL` + `ES_API_KEY`| Read-only log search — example, disabled      |
| `grafana`       | `GRAFANA_URL` + token  | Read-only dashboards — example, disabled      |

`prometheus`, `elasticsearch` and `grafana` are included as templates: set their
URL (and token, where required) and add them to `ENABLED`. Put tokens in
`*-token.txt` files (git-ignored) rather than committing them.
