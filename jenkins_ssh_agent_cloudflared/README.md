# Jenkins SSH Agent with Cloudflared Proxy

This Docker image allows you to connect Jenkins agents via SSH using Cloudflare Tunnel (`cloudflared`) without exposing ports publicly. You can define multiple proxy hosts using environment variables, which are automatically added to the `~/.ssh/config`.

---

## Environment Variables

Define proxy hosts using the following format:
PROXY_HOST_n=<ssh_alias>,<ssh_user>,<destination_port>,<target_host>

### Example

```bash
PROXY_HOST_1=example.com,ssh,22,localhost
PROXY_HOST_2=agent2.tokumei.network,jenkins,2222,127.0.0.1

```

```
# BEGIN MANAGED PROXY HOSTS (cloudflared) - DO NOT EDIT

Host example.com
User ssh
ProxyCommand cloudflared access tcp --hostname %h --destination localhost:22

Host agent2.tokumei.network
User jenkins
ProxyCommand cloudflared access tcp --hostname %h --destination 127.0.0.1:2222

# END MANAGED PROXY HOSTS (cloudflared)

```

%h will be replaced with the Host alias when you connect using ssh.

# Build and Push Docker Image

Build a multi-architecture Docker image and push to Docker Hub:

```

docker buildx build \
 --no-cache \
 --platform linux/amd64,linux/arm64 \
 -t okn2015/jenkins_ssh_agent_cloudflared:latest \
 . \
 --push

```

#Usage

```
docker run -e PROXY_HOST_1=example.com,ssh,22,localhost \
           -e PROXY_HOST_2=agent2.tokumei.network,jenkins,2222,localhost \
           -it okn2015/jenkins_ssh_agent_cloudflared:latest

```

# Notes

- The add_proxy_hosts.sh script automatically updates the SSH config on container startup.

- Ensure cloudflared is installed and available in the container (/usr/local/bin/cloudflared).

- You can add as many proxy hosts as needed by incrementing PROXY_HOST_1, PROXY_HOST_2, etc.
