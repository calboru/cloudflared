FROM python:latest

SHELL ["/bin/bash", "-c"]

# Update and install required packages with retries per package
RUN apt-get update && \
    for pkg in openssh-server iputils-ping nano curl git rsync wget nginx apache2-utils; do \
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

# Install Python packages globally (your app)
RUN pip install --no-cache-dir -r requirements.txt

# Install Glances + passlib
RUN pip install --no-cache-dir glances[web] passlib

# SSH config
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Copy entrypoint and Nginx files
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod 644 /etc/nginx/.htpasswd

# Expose ports: SSH, Python apps, Glances/Nginx
EXPOSE 22 5000-5010 61208

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
