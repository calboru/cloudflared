```
docker run -d \
 -e CF_TUNNEL_1_HOST=elastic1.example.com \
 -e CF_TUNNEL_1_URL=localhost:9200 \
 -e CF_TUNNEL_1_LISTENER=127.0.0.1:9200 \
 -e CF_TUNNEL_1_TOKEN_ID=abc123 \
 -e CF_TUNNEL_1_TOKEN_SECRET=def456 \
 -e CF_TUNNEL_2_HOST=elastic2.example.com \
 -e CF_TUNNEL_2_URL=localhost:9201 \
 -e CF_TUNNEL_2_LISTENER=127.0.0.1:9201 \
 -e CF_TUNNEL_2_TOKEN_ID=ghi789 \
 -e CF_TUNNEL_2_TOKEN_SECRET=jkl012 \
 -e PUBLIC_KEY="public key here" \
 -e TUNNEL_TOKEN="tunnel token here" \
 -e APP_PATH=/app \
 -e SSH_USER=sshuser \
 -p 22:22 \
 -p 3000:3000 \
image-name
```

# Example: start a local listener that Cloudflare will use to forward traffic from local to remote

```
cloudflared access tcp \
 --hostname elastic.example.com \
 --url localhost:9200 \
 --listener 127.0.0.1:9200 \
 --service-token-id "$CF_ACCESS_TOKEN_ID" \
  --service-token-secret "$CF_ACCESS_TOKEN_SECRET"
```

```



docker buildx build \
 --no-cache \
 --platform linux/amd64,linux/arm64 \
 -t okn2015/node_lts_with_openssh_server_cloudflared:v1 \
 . \
 --push


```

cloudflared tunnel run --token eyJhIjoiODRiMGQzZGQxZTJjZGE2ZTM5ZjU5ZjQ3YTZhODNhZjMiLCJ0IjoiYmFiYWZmODItNmFhNC00ZTk5LTk1MTUtMTIxNTJiZmY4NzU3IiwicyI6Ik16UmpaRFEzTXpjdE1HVXdOUzAwWTJZd0xXSTNaR0V0TlRnMlpqY3pNbVUyTURkaCJ9
