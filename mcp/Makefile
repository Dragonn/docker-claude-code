# Local MCP servers manager
#
#   make setup   # print `claude mcp add` commands for enabled servers
#   make run     # ensure enabled servers are running in docker containers
#   make stop    # stop & remove enabled servers' containers
#   make status  # show container state of enabled servers
#
# Enable/disable which servers are managed (space separated):
#   make ENABLED="context7 playwright" run
#
# The defaults below are servers that need no credentials and run out of the
# box. prometheus/elasticsearch/grafana are included as examples of how to wire
# up a server that needs a URL and/or a token; they stay disabled until you
# fill in their URL/token (and add them to ENABLED).

ENABLED ?= context7 playwright

# Host that Claude Code uses to reach these servers. Claude itself runs inside
# a docker container, so `localhost` there is the container, not the host —
# 172.17.0.1 is the docker bridge gateway (the host as seen from a container).
MCP_HOST  ?= 172.17.0.1
# Scope for `claude mcp add` (local | user | project). `user` makes the servers
# available in every project and avoids mixed-scope endpoint conflicts.
MCP_SCOPE ?= user

# --- per-server config ---------------------------------------------------
# context7 — up-to-date library docs. Public, no credentials.
CONTEXT7_PORT       ?= 3001

# Playwright MCP — browser automation (navigate, click, screenshot, etc.).
# Official Microsoft image; runs headless chromium as a long-lived HTTP service.
# --allowed-hosts is needed because Claude reaches it via $(MCP_HOST), not the
# host the server binds to (the default allowlist).
PLAYWRIGHT_IMAGE    ?= mcr.microsoft.com/playwright/mcp
PLAYWRIGHT_PORT     ?= 3002

# Prometheus/Thanos (metrics) MCP — read-only PromQL queries.
# Example only: set PROMETHEUS_URL to your own endpoint before enabling.
PROMETHEUS_IMAGE    ?= ghcr.io/pab1it0/prometheus-mcp-server:latest
PROMETHEUS_URL      ?=
PROMETHEUS_PORT     ?= 3003

# Elasticsearch (logs, read-only search) MCP.
# Example only: set ES_URL + ES_API_KEY (or ES_USERNAME/ES_PASSWORD) to enable.
ES_IMAGE            ?= docker.elastic.co/mcp/elasticsearch
ES_URL              ?=
ES_API_KEY          ?=
ES_PORT             ?= 3004

# Grafana MCP — runs read-only (--disable-write). Datasource proxy query tools
# (query_prometheus/loki/sql/influxdb) stay enabled (they are reads). Needs a
# service-account token in $(GRAFANA_TOKEN_FILE) and your Grafana URL.
# Example only: set GRAFANA_URL and drop a token in the file to enable.
GRAFANA_IMAGE       ?= grafana/mcp-grafana
GRAFANA_URL         ?=
GRAFANA_TOKEN_FILE  ?= grafana-token.txt
GRAFANA_PORT        ?= 3005
# -------------------------------------------------------------------------

.DEFAULT_GOAL := help

.PHONY: help setup run stop status \
        setup-context7 run-context7 stop-context7 \
        setup-playwright run-playwright stop-playwright \
        setup-prometheus run-prometheus stop-prometheus \
        setup-elasticsearch run-elasticsearch stop-elasticsearch \
        setup-grafana run-grafana stop-grafana

help:
	@echo "Local MCP servers manager"
	@echo ""
	@echo "  make setup    print 'claude mcp add' commands for enabled servers"
	@echo "  make run      ensure enabled servers run in docker containers"
	@echo "  make stop     stop & remove enabled servers' containers"
	@echo "  make status   show container state of enabled servers"
	@echo ""
	@echo "Enabled servers: $(ENABLED)"
	@echo "Override with e.g.: make ENABLED=\"context7 playwright\" run"

# --- aggregate targets (fan out over $(ENABLED)) -------------------------
setup: $(addprefix setup-,$(ENABLED))
	@echo ""
	@echo "Run the command(s) above to register the server(s) with Claude Code."

run: $(addprefix run-,$(ENABLED))

stop: $(addprefix stop-,$(ENABLED))

status:
	@for name in $(ENABLED); do \
		case $$name in \
			context7) c=context7-mcp ;; \
			playwright) c=playwright-mcp ;; \
			prometheus) c=prometheus-mcp ;; \
			elasticsearch) c=elasticsearch-mcp ;; \
			grafana) c=grafana-mcp ;; \
			*) c=$$name ;; \
		esac; \
		state=$$(docker inspect -f '{{.State.Status}}' $$c 2>/dev/null || echo "not created"); \
		printf '  %-14s %s\n' "$$name" "$$state"; \
	done

# --- context7 ------------------------------------------------------------
setup-context7:
	@printf 'claude mcp add --scope $(MCP_SCOPE) --transport http context7 %s\n' \
		"http://$(MCP_HOST):$(CONTEXT7_PORT)/mcp"

run-context7:
	@if [ -n "$$(docker ps -q -f name=^context7-mcp$$)" ]; then \
		echo "context7-mcp already running at http://localhost:$(CONTEXT7_PORT)/mcp"; \
	else \
		docker rm -f context7-mcp >/dev/null 2>&1 || true; \
		docker run -d --name context7-mcp -p $(CONTEXT7_PORT):$(CONTEXT7_PORT) \
			node:22-alpine \
			npx -y @upstash/context7-mcp --transport http --port $(CONTEXT7_PORT) && \
		echo "context7-mcp started at http://localhost:$(CONTEXT7_PORT)/mcp"; \
	fi

stop-context7:
	@docker rm -f context7-mcp >/dev/null 2>&1 && echo "context7-mcp stopped" || echo "context7-mcp not running"

# --- playwright (browser automation) -------------------------------------
setup-playwright:
	@printf 'claude mcp add --scope $(MCP_SCOPE) --transport http playwright %s\n' \
		"http://$(MCP_HOST):$(PLAYWRIGHT_PORT)/mcp"

run-playwright:
	@if [ -n "$$(docker ps -q -f name=^playwright-mcp$$)" ]; then \
		echo "playwright-mcp already running at http://localhost:$(PLAYWRIGHT_PORT)/mcp"; \
	else \
		docker rm -f playwright-mcp >/dev/null 2>&1 || true; \
		docker run -d --name playwright-mcp --init -p $(PLAYWRIGHT_PORT):8931 \
			--entrypoint node \
			$(PLAYWRIGHT_IMAGE) \
			/app/cli.js --headless --browser chromium --no-sandbox \
				--host 0.0.0.0 --port 8931 \
				--allowed-hosts "$(MCP_HOST):$(PLAYWRIGHT_PORT)" && \
		echo "playwright-mcp started at http://localhost:$(PLAYWRIGHT_PORT)/mcp"; \
	fi

stop-playwright:
	@docker rm -f playwright-mcp >/dev/null 2>&1 && echo "playwright-mcp stopped" || echo "playwright-mcp not running"

# --- prometheus (metrics, read-only) -------------------------------------
setup-prometheus:
	@printf 'claude mcp add --scope $(MCP_SCOPE) --transport http prometheus %s\n' \
		"http://$(MCP_HOST):$(PROMETHEUS_PORT)/mcp"

run-prometheus:
	@if [ -z "$(PROMETHEUS_URL)" ]; then \
		echo "prometheus: PROMETHEUS_URL is blank — set it (edit Makefile or 'make PROMETHEUS_URL=... run-prometheus'), skipping"; \
	elif [ -n "$$(docker ps -q -f name=^prometheus-mcp$$)" ]; then \
		echo "prometheus-mcp already running at http://localhost:$(PROMETHEUS_PORT)/mcp"; \
	else \
		docker rm -f prometheus-mcp >/dev/null 2>&1 || true; \
		docker run -d --name prometheus-mcp -p $(PROMETHEUS_PORT):8080 \
			-e PROMETHEUS_URL=$(PROMETHEUS_URL) \
			-e PROMETHEUS_MCP_SERVER_TRANSPORT=http \
			-e PROMETHEUS_MCP_BIND_HOST=0.0.0.0 \
			-e PROMETHEUS_MCP_BIND_PORT=8080 \
			$(PROMETHEUS_IMAGE) && \
		echo "prometheus-mcp started at http://localhost:$(PROMETHEUS_PORT)/mcp -> $(PROMETHEUS_URL)"; \
	fi

stop-prometheus:
	@docker rm -f prometheus-mcp >/dev/null 2>&1 && echo "prometheus-mcp stopped" || echo "prometheus-mcp not running"

# --- elasticsearch (logs, read-only search) ------------------------------
setup-elasticsearch:
	@printf 'claude mcp add --scope $(MCP_SCOPE) --transport http elasticsearch %s\n' \
		"http://$(MCP_HOST):$(ES_PORT)/mcp"

run-elasticsearch:
	@if [ -z "$(ES_URL)" ]; then \
		echo "elasticsearch: ES_URL is blank — set ES_URL and ES_API_KEY (edit Makefile or 'make ES_URL=... ES_API_KEY=... run-elasticsearch'), skipping"; \
	elif [ -n "$$(docker ps -q -f name=^elasticsearch-mcp$$)" ]; then \
		echo "elasticsearch-mcp already running at http://localhost:$(ES_PORT)/mcp"; \
	else \
		docker rm -f elasticsearch-mcp >/dev/null 2>&1 || true; \
		docker run -d --name elasticsearch-mcp -p $(ES_PORT):8080 \
			-e ES_URL=$(ES_URL) \
			-e ES_API_KEY=$(ES_API_KEY) \
			$(ES_IMAGE) http && \
		echo "elasticsearch-mcp started at http://localhost:$(ES_PORT)/mcp -> $(ES_URL)"; \
	fi

stop-elasticsearch:
	@docker rm -f elasticsearch-mcp >/dev/null 2>&1 && echo "elasticsearch-mcp stopped" || echo "elasticsearch-mcp not running"

# --- grafana (dashboards, datasources, alerts; read-only) ----------------
setup-grafana:
	@printf 'claude mcp add --scope $(MCP_SCOPE) --transport http grafana %s\n' \
		"http://$(MCP_HOST):$(GRAFANA_PORT)/mcp"

run-grafana:
	@if [ -z "$(GRAFANA_URL)" ]; then \
		echo "grafana: GRAFANA_URL is blank — set it and drop a service-account token in $(GRAFANA_TOKEN_FILE), skipping"; \
	elif [ ! -f "$(GRAFANA_TOKEN_FILE)" ]; then \
		echo "grafana: $(GRAFANA_TOKEN_FILE) not found — put a Grafana service-account token in it, skipping"; \
	elif [ -n "$$(docker ps -q -f name=^grafana-mcp$$)" ]; then \
		echo "grafana-mcp already running at http://localhost:$(GRAFANA_PORT)/mcp"; \
	else \
		docker rm -f grafana-mcp >/dev/null 2>&1 || true; \
		docker run -d --name grafana-mcp -p $(GRAFANA_PORT):8000 \
			-e GRAFANA_URL=$(GRAFANA_URL) \
			-e GRAFANA_SERVICE_ACCOUNT_TOKEN="$$(tr -d '\r\n' < "$(GRAFANA_TOKEN_FILE)")" \
			$(GRAFANA_IMAGE) -t streamable-http -address 0.0.0.0:8000 \
				-allowed-hosts "$(MCP_HOST):$(GRAFANA_PORT)" --disable-write && \
		echo "grafana-mcp started (read-only) at http://localhost:$(GRAFANA_PORT)/mcp -> $(GRAFANA_URL)"; \
	fi

stop-grafana:
	@docker rm -f grafana-mcp >/dev/null 2>&1 && echo "grafana-mcp stopped" || echo "grafana-mcp not running"
