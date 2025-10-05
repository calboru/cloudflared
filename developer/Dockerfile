# ----------------------------
# Stage 1: Base + system packages
# ----------------------------
FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# retry_apt globally
RUN echo '#!/bin/bash' > /usr/local/bin/retry_apt && \
    echo 'while true; do apt-get clean && apt-get update && [ -z "$@" ] || apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@" && break || { echo "Retrying apt-get $@ ..."; rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; sleep 1; }; done' >> /usr/local/bin/retry_apt && \
    chmod +x /usr/local/bin/retry_apt

# Update sources & upgrade
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        echo "deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
        echo "deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list; \
    else \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list; \
    fi && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Install system packages one at a time
RUN retry_apt aptitude
RUN retry_apt ca-certificates
RUN retry_apt sudo
RUN retry_apt curl
RUN retry_apt wget
RUN retry_apt zsh
RUN retry_apt openssh-server
RUN retry_apt socat
RUN retry_apt nano
RUN retry_apt iputils-ping
RUN retry_apt net-tools
RUN retry_apt git
RUN retry_apt unzip
RUN retry_apt gnupg
RUN retry_apt locales
RUN retry_apt cron
RUN retry_apt supervisor
RUN retry_apt python3
RUN retry_apt python3-pip
RUN retry_apt python3-venv
RUN retry_apt python3-dev
RUN retry_apt build-essential
RUN retry_apt libeigen3-dev
RUN retry_apt nginx
RUN retry_apt apache2-utils
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen && update-locale LANG=en_US.UTF-8
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Supervisor setup
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# Python packages
RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple glances[web] passlib

# cloudflared
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        curl -fsSL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    elif [ "$ARCH" = "arm64" ]; then \
        curl -fsSL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && chmod +x /usr/local/bin/cloudflared

# Developer user & SSH
RUN useradd -m -s /bin/zsh developer && passwd -d developer && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN mkdir -p /home/developer/.ssh && chown -R developer:developer /home/developer/.ssh && chmod 700 /home/developer/.ssh

# Copy configs
COPY sshd_config /etc/ssh/sshd_config
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd
COPY glances.conf /etc/glances/glances.conf

# ----------------------------
# Stage 2: Node + NVM builder
# ----------------------------
FROM base AS node-builder

USER developer
WORKDIR /home/developer
ENV NVM_DIR=/home/developer/.nvm
ENV NODE_VERSION=lts/*

RUN mkdir -p $NVM_DIR && \
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash && \
    bash -c "export NVM_DIR=$NVM_DIR && source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && npm install -g npm pnpm pm2"

# ----------------------------
# Stage 3: Final image
# ----------------------------
FROM base

# Copy NVM from builder
COPY --from=node-builder /home/developer/.nvm /home/developer/.nvm

# Ensure correct permissions for NVM
RUN chown -R developer:developer /home/developer/.nvm && \
    chmod -R u+rwX /home/developer/.nvm

# oh-my-zsh + plugins
RUN export ZSH="/home/developer/.oh-my-zsh" && \
    export HOME="/home/developer" && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-/home/developer/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-/home/developer/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    sed -i 's|ZSH=.*|ZSH=/home/developer/.oh-my-zsh|' /home/developer/.zshrc && \
    sed -i 's|source \$ZSH/oh-my-zsh.sh|source /home/developer/.oh-my-zsh/oh-my-zsh.sh|' /home/developer/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' /home/developer/.zshrc && \
    chown -R developer:developer /home/developer/.oh-my-zsh /home/developer/.zshrc

# Persist NVM environment
RUN echo '' >> /home/developer/.zshrc && \
    echo '# NVM setup' >> /home/developer/.zshrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/developer/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/developer/.zshrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/developer/.zshrc

# Switch to developer
USER developer
WORKDIR /home/developer

# Switch back to root
USER root

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple -r /tmp/requirements.txt

# Expose ports
EXPOSE 22 61208 3000-3010 5000-5010
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]