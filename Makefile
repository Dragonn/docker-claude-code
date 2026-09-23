# Build the local Claude Code container image and install the host scripts.
#
#   make build                 # build my-claude-code:latest (latest claude-code)
#   make build VERSION=2.1.162  # pin a specific claude-code version
#   make rebuild               # build with --no-cache
#   make USER_ID=1001 build    # bake a specific uid (defaults to your own)
#   sudo make install          # copy host scripts to /usr/local/bin
#   make user-install          # copy host scripts to ~/.local/bin (+ PATH)

IMAGE   ?= my-claude-code
VERSION ?= latest
USER_ID ?= $(shell id -u)

# Host-side scripts to install (dgx-open lives inside the image, not the host).
BINS := claude claude-login-watcher

PREFIX      ?= /usr/local
BINDIR      ?= $(PREFIX)/bin
USER_BINDIR ?= $(HOME)/.local/bin

# Tag with the resolved version and always with :latest (the run script uses
# the untagged name, which resolves to :latest).
TAGS := -t $(IMAGE):$(VERSION) -t $(IMAGE):latest

.DEFAULT_GOAL := build
.PHONY: build rebuild clean install uninstall user-install user-uninstall

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

# System-wide install. Needs write access to $(BINDIR), so run with sudo:
#   sudo make install
install:
	install -d "$(BINDIR)"
	install -m 0755 $(BINS) "$(BINDIR)"
	@echo "Installed $(BINS) to $(BINDIR)"

# Remove the system-wide install (run with sudo, mirrors `install`).
uninstall:
	for b in $(BINS); do rm -f "$(BINDIR)/$$b"; done
	@echo "Removed $(BINS) from $(BINDIR)"

# Per-user install into ~/.local/bin, ensuring it is on PATH.
user-install:
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
user-uninstall:
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
