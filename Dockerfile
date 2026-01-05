# syntax=docker/dockerfile:1
FROM codercom/enterprise-base:ubuntu

USER root

# --- Build arguments ---
ARG NODE_VERSION=24
ARG PROJECT_DIR=/home/coder/project

# Use bash for the shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
# Configure mise for all users (bash)
RUN echo 'eval "$(/usr/bin/mise activate bash)"' >> /etc/bash.bashrc
RUN echo 'eval "$(/usr/bin/mise activate bash  --shims)"' >> /etc/bash.bash_profile

# --- Install NodeJS with the selected version via mise ---
RUN mise install "nodejs@${NODE_VERSION}" \
  && mise use "nodejs@${NODE_VERSION}" --global

# --- BMAD stack tooling (copied in) ---
ENV BMAD_STACK_DIR=/opt/bmad/stacks

COPY bmad/bin/bmad-stack /usr/local/bin/bmad-stack
RUN chmod 0755 /usr/local/bin/bmad-stack \
 && sed -i 's/\r$//' /usr/local/bin/bmad-stack

COPY bmad/stacks/ /opt/bmad/stacks/
RUN chmod -R a+rX /opt/bmad/stacks

# # --- Optional: install BMAD CLI globally (v6 alpha example) ---
# # Enable by building with: --build-arg INSTALL_BMAD_CLI=true
# # Pin the CLI version via:  --build-arg BMAD_CLI_VERSION=6.0.0-alpha.15
# RUN if [ "$INSTALL_BMAD_CLI" = "true" ]; then \
#     source $NVM_DIR/nvm.sh \
#     && npm install -g "bmad-method@${BMAD_CLI_VERSION}" \
#     && bmad install --full --ide vscode --directory .\
#     && npm cache clean --force; \
#   fi

USER coder
CMD ["/bin/bash"]
WORKDIR /home/coder
