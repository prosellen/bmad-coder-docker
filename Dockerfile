# syntax=docker/dockerfile:1
FROM codercom/enterprise-base:ubuntu

# --- Build arguments ---
ARG NODE_VERSION=24
ARG INSTALL_BMAD_CLI=true
ARG BMAD_CLI_VERSION=6.0.0-alpha.15

# Use bash for the shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
  && rm -rf /var/lib/apt/lists/*

# --- Install mise (runtime manager) ---
RUN install -dm 755 /etc/apt/keyrings \
  && curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null \
  && echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list \
  && apt-get update \
  && apt-get install -y mise

# --- BMAD stack tooling (copied in) ---
ENV BMAD_STACK_DIR=/opt/bmad/stacks

COPY bmad/bin/bmad-stack /home/coder/.local/bin/bmad-stack
RUN chmod 0755 /home/coder/.local/bin/bmad-stack \
 && sed -i 's/\r$//' /home/coder/.local/bin/bmad-stack

COPY bmad/stacks/ /opt/bmad/stacks/
RUN chmod -R a+rX /opt/bmad/stacks

USER coder

# --- Install Node.js (required for BMAD CLI / npx; BMAD recommends Node 20+) ---
# Use nvm to install Node.js so we can more easily switch versions later if needed.
ENV NVM_DIR=/home/coder/.local/bin/.nvm
RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
RUN echo node > /home/coder/.nvmrc
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION"

# --- Optional: install BMAD CLI globally (v6 alpha example) ---
# Enable by building with: --build-arg INSTALL_BMAD_CLI=true
# Pin the CLI version via:  --build-arg BMAD_CLI_VERSION=6.0.0-alpha.15
RUN if [ "$INSTALL_BMAD_CLI" = "true" ]; then \
    source $NVM_DIR/nvm.sh \
    && npm install -g "bmad-method@${BMAD_CLI_VERSION}" \
    && npm cache clean --force; \
  fi

RUN mkdir -p /home/coder/project
WORKDIR /home/coder

CMD ["/bin/bash"]
