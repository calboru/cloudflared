# Cloudflared Multi-Tunnel Docker Image

This repository provides a Docker image for running [Cloudflared](https://github.com/cloudflare/cloudflared) with support for multiple tunnels, managed by [Supervisor](http://supervisord.org/).

## Features

- **Multi-tunnel support:** Easily run multiple Cloudflared tunnels in a single container.
- **Dynamic tunnel management:** Add or remove tunnels at runtime using a provided shell script.
- **Supervisor integration:** Each tunnel is managed as a separate Supervisor process for reliability and easy monitoring.

## Usage

### Environment Variables

To configure tunnels at startup, set environment variables in the format:

This is a Cloudflared image with multi tunnel implementation with supervisor. Add TUNNEL\_(descriptive key) in the environment values it will run the tunnels at startup. You can add tunnel by using the container terminal with command add_tunnel.sh shell script parameters are TUNNEL_NAME and TUNNEL_TOKEN it will create relevant supervisor configuration.

## To build and push to Docker Hub

docker buildx build \
 --no-cache \
 --platform linux/amd64,linux/arm64 \
 -t okn2015/cloudflared:lts \
 . \
 --push
