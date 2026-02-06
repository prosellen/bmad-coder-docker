# syntax=docker/dockerfile:1
FROM ubuntu:latest

# --- Build arguments ---
ARG NODE_VERSION=24
ARG PROJECT_DIR=/home/coder/project
ARG USER=coder
ARG BMAD_VERSION=6

# Use bash for the shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Initial setup ---
# Install base dependencies
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    sudo \
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
    rsync \
    locales
RUN rm -rf /var/lib/apt/lists/*

# --- Install additional dependencies for building software ---
# These are needed to build Python from source via mise
RUN apt-get update && sudo apt-get install -y --no-install-recommends \
  libssl-dev zlib1g-dev xz-utils libbz2-dev liblzma-dev \
  libffi-dev libsqlite3-dev lsb-release \
  && sudo rm -rf /var/lib/apt/lists/*

WORKDIR "/root/"

# --- Create configuration directory ---
# We are going to add the full user home directory to the Kubernetes PVC
# This will shadow everything that is in the user directory, making everything that is
# stored in there "invisible".
# As a workaround, we store everything that will be needed in that PVC in this config
# directory and move it into the users home directory AFTER the PVC is created
RUN mkdir -p /usr/local/config/

# --- Install mise (https://mise.run) to enable easy runtime installation ---
# Install mise via the install script
RUN curl https://mise.run | MISE_INSTALL_PATH=/usr/bin/mise sh
# Configure mise for all users (bash)
RUN echo 'eval "$(/usr/bin/mise activate bash)"' >> /etc/bash.bashrc
RUN echo 'eval "$(/usr/bin/mise activate bash  --shims)"' >> /etc/bash.bash_profile

# --- Copy in BMAD files to the config directory ---
# We copy the BMAD stack tooling and files into the config directory so they can be
# moved into the user's home directory after the PVC is mounted
# Select BMAD version based on build arg: v4.44.3 or v6.0.0-Beta.7
COPY bmad/v${BMAD_VERSION}.*/ /usr/local/config/project/
RUN chmod -R a+rX /usr/local/config/project/

# --- Copy templating scripts and templates ---
COPY config/scripts/ /usr/local/config/scripts/
RUN chmod +x /usr/local/config/scripts/*.py

COPY config/templates/ /usr/local/config/templates/
RUN chmod -R a+rX /usr/local/config/templates/ 

# # Copy the script to install new tools using mise
# COPY config/bin/ /usr/local/config/.local/bin/
# RUN chmod 0755 /usr/local/config/.local/bin \
#  && sed -i 's/\r$//' /usr/local/config/.local/bin

# # Copy the script to install new tools using mise
# COPY config/stacks/ /usr/local/config/.local/stacks/
# RUN chmod -R a+rX /usr/local/config/.local/stacks/

# --- Locale setup ---
# # Set locale to German (de_DE.UTF-8)
RUN locale-gen de_DE.UTF-8 \
  && update-locale LANG=de_DE.UTF-8   
ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de_DE.UTF-8
ENV LC_ALL=de_DE.UTF-8  

# --- Create local user (default: "coder") ---
RUN useradd -m --uid=1001 --shell /bin/bash -G sudo ${USER} 
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 440 /etc/sudoers.d/${USER}
# Create project directory for the user
RUN mkdir -p /home/${USER}/project
# Set ownership of home directory to the user
RUN chown -R ${USER}:${USER} /home/${USER}

# # Let's add a fancy prompt!
# RUN echo "PS1='CGI BMAD \[\033[1;36m\]\h \[\033[1;34m\]\W\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'" > /home/${USER}/.bashrc && \
#     chown ${USER}:${USER} /home/${USER}/.bashrc

# Switch to the new user
USER ${USER}

# Set working directory
WORKDIR "/home/${USER}"
