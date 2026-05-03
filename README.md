# Hermes Infrastructure Base Images

This repository contains base images for Hermes. Images are automatically rebuilt and pushed daily to stay in sync with the latest official Hermes code upgrades.

## Container Image

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

## Kubernetes Deployment (Helm)

A Helm chart is included for deploying Hermes on Kubernetes:

```bash
helm install hermes ./charts/hermes -n hermes --create-namespace
helm upgrade hermes ./charts/hermes -n hermes
```

The chart deploys:

- **Gateway** - Main API server on port 8642
- **Dashboard** - Web UI on port 9119
- **PVC** - 10Gi persistent storage for shared data

Configure API keys and resources in `charts/hermes/values.yaml`.

## Usage

```bash
docker run --rm ghcr.io/cn-jwsong/hermes:latest hermes
```
