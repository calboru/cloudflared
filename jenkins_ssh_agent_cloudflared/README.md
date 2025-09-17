docker buildx build \
 --no-cache \
 --platform linux/amd64,linux/arm64 \
 -t okn2015/jenkins_ssh_agent_cloudflared:latest \
 . \
 --push
