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

- **Gateway** - Main API server on port 8642, with multi-agent profile support
- **Dashboard** - Web UI on port 9119
- **PVC** - 10Gi persistent storage for shared data

### Multi-Agent Profiles

The gateway runs multiple agent containers simultaneously, each with an optional profile flag:

| Agent | Profile | Command |
|-------|---------|---------|
| `gateway-hermes` | (default) | `hermes gateway run` |
| `gateway-coder` | `coder` | `hermes --profile=coder gateway run` |
| `gateway-devops` | `devops` | `hermes --profile=devops gateway run` |

Control which agents are active via `values.yaml`:

```yaml
gateway:
  agents:
    - name: gateway-hermes
      enabled: true
    - name: gateway-coder
      enabled: true      # set false to disable
    - name: gateway-devops
      enabled: true
```

Configure API keys and resources in `charts/hermes/values.yaml`.

## Usage

```bash
docker run --rm ghcr.io/cn-jwsong/hermes:latest hermes
```
