FROM node:22-trixie-slim

ARG VERSION
RUN apt-get update && \
    apt-get install --no-install-recommends --assume-yes git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    npm install -g @anthropic-ai/claude-code@${VERSION} && \
    claude --version && \
    usermod -l claude -d /home/claude -m node && \
    groupmod -n claude node

USER claude
ENV DISABLE_AUTOUPDATER=1
WORKDIR /mnt/claude
ENTRYPOINT ["/usr/local/bin/claude"]
