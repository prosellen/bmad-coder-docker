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
    locales \
  && rm -rf /var/lib/apt/lists/*

# --- Install mise (runtime manager) ---
# RUN install -dm 755 /etc/apt/keyrings \
#   && curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null \
#   && echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list \
#   && apt-get update \
#   && apt-get install -y mise

# Install mise via the install script
RUN curl https://mise.run | MISE_INSTALL_PATH=/usr/bin/mise sh

# # Configure mise for all users (bash)
RUN echo 'eval "$(/usr/bin/mise activate bash)"' >> /etc/bash.bashrc
RUN echo 'eval "$(/usr/bin/mise activate bash  --shims)"' >> /etc/bash.bash_profile

# # --- Install NodeJS with the selected version via mise ---
# RUN mise install "nodejs@${NODE_VERSION}" \
#   && mise use "nodejs@${NODE_VERSION}" --global

# --- BMAD stack tooling (copied in) ---
ENV BMAD_STACK_DIR=/opt/bmad/stacks

# Copies the bmad-stack script and makes it executable
COPY bmad/bin/bmad-stack /usr/local/bin/bmad-stack
RUN chmod 0755 /usr/local/bin/bmad-stack \
 && sed -i 's/\r$//' /usr/local/bin/bmad-stack

# Copies the BMAD Stack definitions
COPY bmad/stacks/ /opt/bmad/stacks/
RUN chmod -R a+rX /opt/bmad/stacks

# Copies the main BMAD files so we do not have to npm install them each time
COPY bmad/bmad-files/ /opt/bmad/bmad-files/
RUN chmod -R a+rX /opt/bmad/bmad-files

USER coder

ENV LANG de_DE.UTF-8  
ENV LANGUAGE de_DE:de 
ENV LC_ALL de_DE.UTF-8     

CMD ["/bin/bash"]
WORKDIR /home/coder
