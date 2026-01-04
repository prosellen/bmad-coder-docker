# syntax=docker/dockerfile:1
FROM codercom/enterprise-base:ubuntu

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    jq \
    unzip \
    gzip \
    openssh-client \
    build-essential \
    bash \
    nodejs \
    npm \
  && rm -rf /var/lib/apt/lists/*

# # --- Install Node.js (required for BMAD CLI / npx; BMAD recommends Node 20+) ---
# # Uses NodeSource to get a current Node 20.x on Ubuntu.
# RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
#   && apt-get update \
#   && apt-get install -y --no-install-recommends nodejs \
#   && corepack enable \
#   && rm -rf /var/lib/apt/lists/*

# --- Optional: install BMAD CLI globally (v6 alpha example) ---
# Enable by building with: --build-arg INSTALL_BMAD_CLI=true
# Pin the CLI version via:  --build-arg BMAD_CLI_VERSION=6.0.0-alpha.7
ARG INSTALL_BMAD_CLI=false
ARG BMAD_CLI_VERSION=6.0.0-alpha.7
RUN if [ "$INSTALL_BMAD_CLI" = "true" ]; then \
      npm install -g "bmad-method@${BMAD_CLI_VERSION}" \
      && npm cache clean --force; \
    fi

# --- Install mise (runtime manager) ---
RUN install -dm 755 /etc/apt/keyrings \
  && curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null \
  && echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list \
  && apt-get update \
  && apt-get install -y mise

# Shell activation for terminals
RUN echo '\n# mise (runtime manager)\nif command -v mise >/dev/null 2>&1; then eval "$(mise activate bash)"; fi\n' >> /etc/bash.bashrc

# --- BMAD stack tooling (copied in) ---
ENV BMAD_STACK_DIR=/opt/bmad/stacks

COPY bmad/bin/bmad-stack /usr/local/bin/bmad-stack
RUN chmod 0755 /usr/local/bin/bmad-stack \
 && sed -i 's/\r$//' /usr/local/bin/bmad-stack

COPY bmad/stacks/ /opt/bmad/stacks/
RUN chmod -R a+rX /opt/bmad/stacks

USER coder
WORKDIR /home/coder