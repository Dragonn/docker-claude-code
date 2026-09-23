FROM node:22-trixie-slim

ARG VERSION
ARG USER_ID=1000

RUN apt-get update && \
    apt-get install --no-install-recommends --assume-yes \
        git git-delta vim sudo \
        curl wget jq ripgrep less ca-certificates \
        libxml2-utils \
        python3 python3-pip python3-venv && \
    ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" \
        -o /usr/local/bin/yq && \
    chmod 0755 /usr/local/bin/yq && \
    yq --version && \
    curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" \
        -o /usr/local/bin/kubectl && \
    chmod 0755 /usr/local/bin/kubectl && \
    kubectl version --client && \
    curl -fsSL "https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_${ARCH}.zip" \
        -o /tmp/pup.zip && \
    python3 -c "import zipfile; zipfile.ZipFile('/tmp/pup.zip').extractall('/usr/local/bin')" && \
    chmod 0755 /usr/local/bin/pup && \
    pup --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    npm install -g @anthropic-ai/claude-code@${VERSION} && \
    claude --version && \
    npm cache clean --force && \
    rm -rf /tmp/* && \
    usermod -l claude -d /home/claude -m node && \
    usermod -u ${USER_ID} claude && \
    groupmod -n claude node && \
    groupmod -g ${USER_ID} claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    git config --system pager.diff delta && \
    git config --system pager.log delta && \
    git config --system pager.show delta

USER claude
ENV DISABLE_AUTOUPDATER=1
ENV COLORTERM=truecolor
WORKDIR /mnt/claude
ENTRYPOINT ["/usr/local/bin/claude"]
