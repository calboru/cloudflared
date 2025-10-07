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
RUN python3 -m pip install --no-cache-dir --break-system-packages glances[web] passlib

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
ENV NVM_VERSION=v0.40.1
ENV NODE_VERSION=lts/*

# Option 1: Use specific nvm version (recommended for stability)
RUN mkdir -p $NVM_DIR && \
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash && \
    bash -lc "source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default && \
    npm install -g npm pnpm pm2 && \
    node -v && npm -v && pnpm -v && pm2 -v && \
    echo 'Default Node.js version:' && nvm version default" && \
    ls -la $NVM_DIR/nvm.sh $NVM_DIR/bash_completion $NVM_DIR/versions/node

 
# ----------------------------
# Stage 3: Final image
# ----------------------------
FROM base

# Copy NVM from builder
COPY --from=node-builder /home/developer/.nvm /home/developer/.nvm

# Ensure correct permissions
RUN chown -R developer:developer /home/developer/.nvm && chmod -R u+rwX /home/developer/.nvm

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

# NVM initialization for zsh (developer user only)
RUN printf '%s\n' \
      '# NVM initialization' \
      'export NVM_DIR="/home/developer/.nvm"' \
      '[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' \
      '[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"' \
      'alias hash="whence -p" 2>/dev/null' \
      'autoload -Uz +X bashcompinit && bashcompinit' \
      '[ -s "$NVM_DIR/nvm.sh" ] && { nvm use default >/dev/null 2>&1 || { nvm install lts/* && nvm alias default lts/* && nvm use lts/*; } }' \
      > /home/developer/.nvm.zsh && \
    echo '[ -f /home/developer/.nvm.zsh ] && source /home/developer/.nvm.zsh' >> /home/developer/.zshrc && \
    echo '[ -f /home/developer/.nvm.zsh ] && source /home/developer/.nvm.zsh' >> /home/developer/.zprofile && \
    chown -R developer:developer /home/developer/.nvm.zsh /home/developer/.zshrc /home/developer/.zprofile && \
    # Debug: Verify nvm and node installation
    ls -la /home/developer/.nvm/nvm.sh /home/developer/.nvm/bash_completion /home/developer/.nvm/versions/node || true && \
    # Run as developer to verify installation
    su - developer -c "source /home/developer/.nvm.zsh && nvm -v && node -v && npm -v && pnpm -v && pm2 -v && nvm version default" || true

RUN for d in .cache .npm .config .local .pnpm-store; do \
      mkdir -p /home/developer/$d && \
      chown -R developer:developer /home/developer/$d && \
      chmod -R 700 /home/developer/$d; \
    done


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