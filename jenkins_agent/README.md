# Jenkins SSH Agent with Cloudflared Proxy

## Run following in the container to see the limits.

If it is too low, agent may fail and would cause the container restart

```
# Log current sysctl settings for debugging
echo "Current inotify max_user_instances: $(cat /proc/sys/fs/inotify/max_user_instances)"
echo "Current inotify max_user_watches: $(cat /proc/sys/fs/inotify/max_user_watches)"

# Log ulimit for debugging
echo "Current ulimit -n: $(ulimit -n)"


## Environment Variables

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

# Notes
```
