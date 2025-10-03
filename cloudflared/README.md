# Cloudflared Alpine Docker

A lightweight Alpine-based Docker image to run **Cloudflared tunnels**, **SSH access**, and **Glances web monitoring** under **Supervisor**. Supports dynamic `PROXY_*` tunnels and runtime injection of SSH keys and Cloudflared certificates.

---

## Features

- Runs **Cloudflared tunnels** and **PROXY commands** with dynamic Supervisor configs.
- SSH access with **public key authentication**.
- Includes **Glances web monitoring**.
- Lightweight **Alpine Linux** base.
- Multi-architecture support: `amd64` and `arm64`.
- Automatic handling of `TUNNEL_TOKEN` and `CLOUDFLARED_CERT`.

---

## Environment Variables

| Variable                | Description                                                 | Required |
| ----------------------- | ----------------------------------------------------------- | -------- |
| `PUBLIC_KEY`            | SSH public key for user access                              | ✅       |
| `SSH_USER`              | Username for SSH access (default: `sshuser`)                | ⚪       |
| `CLOUDFLARED_CERT`      | Contents of Cloudflared certificate (`cert.pem`)            | ✅       |
| `TUNNEL_TOKEN`          | Cloudflared tunnel token                                    | ✅       |
| `PROXY_1, PROXY_2, ...` | Optional Cloudflared proxy commands to run under Supervisor | ⚪       |

## How to create Cloudflared cert

Execute following command and get the cert from its location pass it to CLOUDFLARED_CERT env

```
cloudflared tunnel login
```

**Notes:**

- `PROXY_*` commands are expected as **full command strings**, for example:
  ```bash
  PROXY_1="/mnt/data/cloudflared access tcp --hostname example.com --destination tcp://web:22 --listener localhost:2222"
  ```

| Port  | Service        |
| ----- | -------------- |
| 22    | SSH            |
| 61208 | Glances web UI |

## How to build and push to Docker Hub?

```
docker buildx build \
  --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t yourusername/cloudflared:v1.0 \
  . \
  --push
```

## How to run the container locally?

```
docker run -d \
  -e PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  -e CLOUDFLARED_CERT="$(cat cert.pem)" \
  -e TUNNEL_TOKEN="your_tunnel_token" \
  -e PROXY_1="your_proxy_command" \
  -p 22:22 \
  -p 61208:61208 \
  yourusername/cloudflared:v1.0

```

## Check the status of the services

### Run inside the container shell or ssh into it first

```
/opt/venv/bin/supervisorctl -s http://127.0.0.1:9001 -u admin -p admin status

```

## Reload services

### Run inside the container shell or ssh into it first

```
/opt/venv/bin/supervisorctl -s http://127.0.0.1:9001 -u admin -p admin update

```

### How to create .htaccess password to reset Glancer access password ?

```
htpasswd -c /etc/nginx/.htpasswd admin

```

Replace the value in .htpasswd file
