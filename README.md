# Hermes Infrastructure Base Images

This repository contains base images for Hermes. Images are automatically rebuilt and pushed daily to stay in sync with the latest official Hermes code upgrades.

## Image

The latest image is available at:

```
ghcr.io/cn-jwsong/hermes:latest
```

## Automated Builds

A GitHub Actions workflow runs daily at 00:00 UTC to:

- Pull the latest Hermes Agent source code
- Build the container image
- Push to GitHub Container Registry (GHCR)

You can also trigger a manual build from the **Actions** tab.

## Usage

```bash
docker run --rm ghcr.io/cn-jwsong/hermes:latest hermes
```
