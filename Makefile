# Build the local Claude Code container image and install the host scripts.
#
#   make build                 # build my-claude-code:latest (latest claude-code)
#   make build VERSION=2.1.162  # pin a specific claude-code version
#   make rebuild               # build with --no-cache
#   make USER_ID=1001 build    # bake a specific uid (defaults to your own)
#   sudo make install          # copy host scripts to /usr/local/bin
#   make user-install          # copy host scripts to ~/.local/bin (+ PATH)
#
# install / user-install also create ~/.config/claude-docker.conf from
# config.example if it does not exist; uninstall / user-uninstall remove it.

IMAGE   ?= my-claude-code
VERSION ?= latest
USER_ID ?= $(shell id -u)

# Host-side scripts to install (dgx-open lives inside the image, not the host).
BINS := claude claude-login-watcher

PREFIX      ?= /usr/local
BINDIR      ?= $(PREFIX)/bin
USER_BINDIR ?= $(HOME)/.local/bin

# Per-user config file. Resolve the invoking user's home even under sudo, and
# honour CLAUDE_DOCKER_CONFIG / XDG_CONFIG_HOME the same way the `claude` script
# does. The template is config.example; existing configs are never overwritten.
CFG_HOME := $(if $(SUDO_USER),$(shell getent passwd $(SUDO_USER) | cut -d: -f6),$(HOME))
CFG_DIR  := $(if $(XDG_CONFIG_HOME),$(XDG_CONFIG_HOME),$(CFG_HOME)/.config)
CONFIG   := $(if $(CLAUDE_DOCKER_CONFIG),$(CLAUDE_DOCKER_CONFIG),$(CFG_DIR)/claude-docker.conf)

# Tag with the resolved version and always with :latest (the run script uses
# the untagged name, which resolves to :latest).
TAGS := -t $(IMAGE):$(VERSION) -t $(IMAGE):latest

.DEFAULT_GOAL := build
.PHONY: build rebuild clean install uninstall user-install user-uninstall \
        install-config uninstall-config

build:
	docker build \
	  --build-arg VERSION=$(VERSION) \
	  --build-arg USER_ID=$(USER_ID) \
	  $(TAGS) \
	  .

rebuild:
	docker build --no-cache --pull \
	  --build-arg VERSION=$(VERSION) \
	  --build-arg USER_ID=$(USER_ID) \
	  $(TAGS) \
	  .

clean:
	-docker image rm $(IMAGE):$(VERSION) $(IMAGE):latest

# Create the user config from the template if it does not already exist.
# Never overwrites an existing config. Under sudo, writes to (and chowns to)
# the invoking user's home.
install-config:
	@install -d "$(dir $(CONFIG))"
	@if [ -e "$(CONFIG)" ]; then \
		echo "Config already exists, keeping it: $(CONFIG)"; \
	else \
		install -m 0644 config.example "$(CONFIG)"; \
		echo "Created config: $(CONFIG)"; \
	fi
	@if [ "$$(id -u)" = 0 ] && [ -n "$(SUDO_USER)" ]; then \
		chown "$(SUDO_USER)" "$(CONFIG)" "$(dir $(CONFIG))" 2>/dev/null || true; \
	fi

# Remove the user config.
uninstall-config:
	@rm -f "$(CONFIG)"
	@echo "Removed config: $(CONFIG)"

# System-wide install. Needs write access to $(BINDIR), so run with sudo:
#   sudo make install
install: install-config
	install -d "$(BINDIR)"
	install -m 0755 $(BINS) "$(BINDIR)"
	@echo "Installed $(BINS) to $(BINDIR)"

# Remove the system-wide install (run with sudo, mirrors `install`).
uninstall: uninstall-config
	for b in $(BINS); do rm -f "$(BINDIR)/$$b"; done
	@echo "Removed $(BINS) from $(BINDIR)"

# Per-user install into ~/.local/bin, ensuring it is on PATH.
user-install: install-config
	install -d "$(USER_BINDIR)"
	install -m 0755 $(BINS) "$(USER_BINDIR)"
	@echo "Installed $(BINS) to $(USER_BINDIR)"
	@if echo ":$$PATH:" | grep -q ":$(USER_BINDIR):"; then \
		echo "$(USER_BINDIR) is already on PATH."; \
	else \
		case "$$(basename "$${SHELL:-/bin/sh}")" in \
			zsh)  rc="$(HOME)/.zshrc" ;; \
			bash) rc="$(HOME)/.bashrc" ;; \
			*)    rc="$(HOME)/.profile" ;; \
		esac; \
		touch "$$rc"; \
		if grep -qF '.local/bin' "$$rc"; then \
			echo "$$rc already references .local/bin; not modifying it."; \
		else \
			printf '\n# added by claude-code-docker (make user-install)\nexport PATH="$$HOME/.local/bin:$$PATH"\n' >> "$$rc"; \
			echo "Added $(USER_BINDIR) to PATH in $$rc"; \
		fi; \
		echo "Run 'source $$rc' or open a new shell to pick it up."; \
	fi

# Remove the per-user install and the PATH line we added (matched by our
# marker comment, so a hand-written entry of yours is left untouched).
user-uninstall: uninstall-config
	for b in $(BINS); do rm -f "$(USER_BINDIR)/$$b"; done
	@echo "Removed $(BINS) from $(USER_BINDIR)"
	@for rc in "$(HOME)/.zshrc" "$(HOME)/.bashrc" "$(HOME)/.profile"; do \
		if [ -f "$$rc" ] && grep -qF 'added by claude-code-docker (make user-install)' "$$rc"; then \
			tmp="$$rc.cc-tmp"; \
			grep -vF -e '# added by claude-code-docker (make user-install)' \
			         -e 'export PATH="$$HOME/.local/bin:$$PATH"' "$$rc" > "$$tmp" \
			  && mv "$$tmp" "$$rc" \
			  && echo "Removed PATH entry from $$rc"; \
		fi; \
	done
