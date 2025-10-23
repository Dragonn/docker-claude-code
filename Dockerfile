FROM node:22-trixie-slim

ARG VERSION
RUN npm install -g @anthropic-ai/claude-code@${VERSION} && \
    claude --version && \
    usermod -l claude -d /home/claude -m node && \
    groupmod -n claude node

USER claude
ENV DISABLE_AUTOUPDATER=1
WORKDIR /mnt/claude
ENTRYPOINT ["/usr/local/bin/claude"]
