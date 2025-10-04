FROM python:latest

SHELL ["/bin/bash", "-c"]

# Update and install required packages with retries per package
RUN apt-get update && \
    for pkg in openssh-server iputils-ping cron nano curl git rsync wget nginx apache2-utils; do \
        echo "Installing $pkg ..."; \
        until apt-get install -y --no-install-recommends "$pkg"; do \
            echo "Retrying $pkg ..."; \
            sleep 3; \
        done; \
    done && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Glances and Supervisor
RUN pip install --no-cache-dir "glances[web]" supervisor

 


# Copy config and entrypoint files
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd
COPY supervisord.conf /etc/supervisord.conf
COPY sshd_config /etc/ssh/sshd_config

# Permissions
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod 644 /etc/nginx/.htpasswd

# Expose ports: SSH, app ports, Glances/Nginx
EXPOSE 22 5000-5010 61208

# Entrypoint runs setup and then starts supervisord
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
