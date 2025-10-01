# Base image
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV OLLAMA_PATH=/mnt/data

# Use bash as default shell
SHELL ["/bin/bash", "-c"]

# Define retry_apt globally
RUN echo '#!/bin/bash' > /usr/local/bin/retry_apt && \
    echo 'while true; do \
        apt-get clean && apt-get update && \
        [ -z "$@" ] || apt-get install -y --no-install-recommends \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" "$@" && break || { \
                echo "Retrying apt-get $@ ..."; \
                rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
                sleep 1; \
        }; \
    done' >> /usr/local/bin/retry_apt && \
    chmod +x /usr/local/bin/retry_apt

# Install packages one by one with retry_apt
RUN retry_apt iputils-ping && \
    retry_apt net-tools && \
    retry_apt curl && \
    retry_apt wget && \
    retry_apt supervisor && \
    retry_apt cron && \
    retry_apt ca-certificates && \
    retry_apt gnupg && \
    retry_apt lsb-release && \
    retry_apt nginx && \
    retry_apt apache2-utils && \
    retry_apt python3 && \
    retry_apt python3-pip

RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple glances[web]

# Add NVIDIA Container Toolkit repo + keys
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
      | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
      | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
      | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
    apt-get update

# Install NVIDIA Container Toolkit
RUN retry_apt nvidia-container-toolkit

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Create folder for Ollama models
RUN mkdir -p /mnt/data && chown -R root:root /mnt/data

# Copy configs
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd
COPY glances.conf /etc/glances/glances.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy scripts
COPY start.sh /usr/local/bin/start.sh
COPY download_models.sh /usr/local/bin/download_models.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/download_models.sh

# Add cron job for weekly model updates
RUN echo "0 3 * * 0 root /usr/local/bin/download_models.sh >> /var/log/ollama_model_download.log 2>&1" \
    > /etc/cron.d/ollama_models && \
    chmod 644 /etc/cron.d/ollama_models

# Expose Ollama API port and Glances web port
EXPOSE 11434 61208

# Start container with startup script
CMD ["/usr/local/bin/start.sh"]
