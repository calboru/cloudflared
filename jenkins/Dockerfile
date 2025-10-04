FROM jenkins/jenkins

USER root

ENV JENKINS_HOME=/mnt/data

# Make jenkins UID/GID match root
RUN usermod -u 0 -o jenkins && \
    groupmod -g 0 -o jenkins

# ---------------------------
# retry_apt globally
# ---------------------------
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

RUN /usr/local/bin/retry_apt curl
RUN /usr/local/bin/retry_apt bash
RUN /usr/local/bin/retry_apt iputils-ping
RUN /usr/local/bin/retry_apt nano
RUN /usr/local/bin/retry_apt python3
RUN /usr/local/bin/retry_apt python3-pip
RUN /usr/local/bin/retry_apt nginx
RUN /usr/local/bin/retry_apt apache2-utils
 
RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple glances[web] supervisor

# Now Jenkins runs as UID 0 but username is still 'jenkins'
USER jenkins
 
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd
COPY glances.conf /etc/glances/glances.conf

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 8080 50000 61208

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]