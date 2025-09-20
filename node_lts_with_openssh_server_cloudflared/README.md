# node_lts_with_openssh_server_cloudflared

This Docker image provides a lightweight Alpine-based container running an OpenSSH server, a Cloudflared Access proxy, and a Cloudflared tunnel, managed by Supervisor. It includes Node.js, npm, pnpm, and pm2 for Node.js application support, and log rotation for production reliability. The container is designed for secure SSH access and secure proxying/tunneling to services via Cloudflare Zero Trust.

## Features

- **OpenSSH Server**: Runs on port 22 (mapped to host port 2222) with key-based authentication, ensuring secure remote access.
- **Cloudflared Proxy**: Configurable via `PROXY_*` environment variables to proxy traffic through Cloudflare Access (e.g., `es.example.com` to `tcp://localhost:9200`).
- **Cloudflared Tunnel**: Establishes a secure tunnel using a `TUNNEL_TOKEN` for Cloudflare Zero Trust connectivity.
- **Supervisor**: Manages `sshd`, `cloudflared` (tunnel), `PROXY_*` (proxies), and `logrotate` processes with automatic restarts for reliability.
- **Log Rotation**: Uses `logrotate` to manage `/var/log/*.log` files, preventing disk exhaustion in long-running deployments.
- **Multi-Architecture**: Supports `linux/amd64` and `linux/arm64` platforms for broad compatibility.

## Prerequisites

- **Docker**: Ensure Docker is installed and running.
- **Cloudflare Zero Trust**:
  - A valid `TUNNEL_TOKEN` for the Cloudflared tunnel, obtained from the Cloudflare Zero Trust dashboard.
  - Valid `service-token-id` and `service-token-secret` for Cloudflare Access, used in `PROXY_1`.
- **SSH Key Pair**: A public/private key pair (e.g., `web1.pub`/`web1.key`) for SSH authentication.

## Build Instructions

Build and push the multi-architecture image to a Docker registry:

```bash
docker buildx build \
  --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t okn2015/node_lts_with_openssh_server_cloudflared:vxxx \
  . \
  --push
```

```
docker run -d \
  --name nodessh \
  --restart unless-stopped \
  -p 2222:22 \
  -p 3000:3000 \
  -p 9200:9200 \
  -p 9201:9201 \
  -v log_volume:/var/log \
  -e PUBLIC_KEY="$(cat ./web1.pub)" \
  -e SSH_USER=myuser \
  -e APP_PATH=/app \
  -e PROXY_1="hostname=es.example.com&listener=localhost:9201&destination=tcp://localhost:9200&service-token-id=628bb2cbfce8f71bd5fc29e860c98872.access&service-token-secret=6414503014075ecd08007e90230d8016fb557edf3e42d99e1234567890abcdef" \
  -e TUNNEL_TOKEN="tunnel token here..." \
  node-ssh

```

# Environment Variables

- **PUBLIC_KEY**: The SSH public key for authentication (e.g., contents of `web1.pub`). **Required**.
- **SSH_USER**: The SSH user name (default: `sshuser`). **Required**.
- **APP_PATH**: Directory for application files (default: `/app`). **Required**.
- **PROXY_1**: Configures a Cloudflared Access proxy.  
  **Format**:

#Example:

```
hostname=es.example.com&listener=localhost:9201&destination=tcp://localhost:9200&service-token-id=628bb2cbfce8f71bd5fc29e860c98872.access&service-token-secret=6414503014075ecd08007e90230d8016fb557edf3e42d99a35fde026aa0dc429
```
