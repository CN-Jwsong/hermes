---
name: container-image-builder
description: Build container images and push to GitHub Container Registry (GHCR) using scheduled GitHub Actions workflows
license: MIT
metadata:
  audience: developers
  workflow: github-actions
---

## What I do

- Generate Dockerfiles optimized for container images
- Create GitHub Actions workflows for daily scheduled image builds
- Configure GHCR (ghcr.io) as the container registry
- Set up image tagging with `latest` and date-based tags
- Handle authentication and push permissions for GHCR

## When to use me

Use this skill when you need to:
- Set up automated daily container image builds
- Push container images to GitHub Container Registry (ghcr.io)
- Create or update GitHub Actions workflows for CI/CD container builds
- Configure scheduled builds with cron triggers

## Dockerfile Template

Use this as the base Dockerfile:

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMES_HOME=/root/.hermes
ENV HERMES_INSTALL_DIR=/root/.hermes/hermes-agent

# Base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ffmpeg \
    ripgrep \
    python3 \
    python3-venv \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Clone Hermes Agent
RUN git clone https://github.com/NousResearch/hermes-agent.git $HERMES_INSTALL_DIR

WORKDIR $HERMES_INSTALL_DIR

# Create virtual environment (matches install.sh default behavior)
RUN python3 -m venv .venv
ENV PATH="$HERMES_INSTALL_DIR/.venv/bin:$PATH"

# Install Python dependencies
RUN pip install --upgrade pip \
    && pip install -e .

# Add hermes to PATH
RUN ln -s $HERMES_INSTALL_DIR/.venv/bin/hermes /usr/local/bin/hermes

# Initialize shell
RUN echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc

# Default entrypoint
CMD ["hermes"]
```

## GitHub Actions Workflow Template

Create `.github/workflows/build-and-push.yml` with the following content:

```yaml
name: Build and Push Container Image

on:
  schedule:
    # Run daily at 00:00 UTC
    - cron: '0 0 * * *'
  workflow_dispatch:
    # Allow manual trigger
    inputs:
      tag:
        description: 'Custom image tag (optional)'
        required: false
        type: string

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

permissions:
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=raw,value=latest
            type=schedule,pattern={{date 'YYYYMMDD'}}
            type=raw,value=${{ inputs.tag }},enable=${{ github.event_name == 'workflow_dispatch' && inputs.tag != '' }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
```

## Setup Instructions

1. **Create the Dockerfile**
   - Place the Dockerfile at the repository root
   - Modify the base image, dependencies, or entrypoint as needed

2. **Create the workflow file**
   - Create `.github/workflows/build-and-push.yml`
   - The workflow triggers daily at 00:00 UTC via cron
   - Manual trigger is also available via `workflow_dispatch`

3. **Enable Actions permissions**
   - Go to repository Settings > Actions > General
   - Ensure "Allow GitHub Actions to create and approve pull requests" is enabled
   - Under "Workflow permissions", set to "Read and write permissions"

4. **Verify GHCR access**
   - The `GITHUB_TOKEN` secret is provided automatically
   - Ensure the repository has `packages: write` permission (configured in the workflow)

5. **Test the workflow**
   - Trigger manually from the Actions tab to verify the build and push
   - Check that the image appears at `ghcr.io/<owner>/<repo>`

## Customization Options

- **Change schedule**: Modify the `cron` expression in the workflow (use https://crontab.guru/ for help)
- **Multi-platform builds**: The template already builds for `linux/amd64` and `linux/arm64`
- **Add build args**: Add `build-args` to the `docker/build-push-action` step
- **Custom context**: Change the `context` field if your Dockerfile is in a subdirectory
- **Image retention**: Configure GitHub Actions to manage package versions and storage

## Troubleshooting

- **Permission denied on push**: Verify `packages: write` permission in the workflow and repository settings
- **Build fails on arm64**: Some packages may not support multi-arch; consider building only for `linux/amd64`
- **Cron not triggering**: GitHub Actions schedules may experience delays; check the Actions tab for run history
- **Image not found**: Confirm the image name format is `ghcr.io/<owner>/<repo>` (lowercase)
