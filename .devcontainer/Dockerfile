FROM ubuntu:22.04

# Custom Ruby/Rails Dockerfile for Developer Containers

# Set build arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set environment variables
ENV LANG=en_US.utf8 \
    SHELL=/bin/bash \
    TZ=$TZ \
    USERNAME=$USERNAME \
    USER_UID=$USER_UID \
    USER_GID=$USER_GID

# Install locales and set timezone
RUN apt-get update && apt-get install -y locales tzdata \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Install dependencies
RUN apt-get install -y git curl libssl-dev \
    libreadline-dev zlib1g-dev autoconf bison build-essential \
    libyaml-dev libreadline-dev libncurses5-dev libffi-dev \
    libgdbm-dev nano vim patch rustc libreadline6-dev libgmp-dev \
    libgdbm6 libdb-dev uuid-dev libpq-dev imagemagick libmagickwand-dev \
    sudo

# Create non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update \
    && apt-get install -y ngrok

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch to the new user
USER $USERNAME

# Install rbenv and ruby-build
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
    && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
    && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
    && export PATH="$HOME/.rbenv/bin:$PATH" \
    && eval "$(rbenv init -)" \
    && git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
    && ~/.rbenv/bin/rbenv install 3.1.2 \
    && ~/.rbenv/bin/rbenv global 3.1.2

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node

# Install gems
RUN ~/.rbenv/shims/gem install ruby-lsp bundler tzinfo-data

# Rehash rbenv
RUN ~/.rbenv/bin/rbenv rehash

WORKDIR /workspaces
SHELL ["/bin/bash", "-c"]