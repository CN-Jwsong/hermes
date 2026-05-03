---
name: helm-deploy
description: Deploy and manage Helm charts for Kubernetes applications, including Hermes infrastructure
license: MIT
metadata:
  audience: developers
  workflow: kubernetes
---

## What I do

- Deploy Kubernetes applications using Helm charts
- Manage chart values, upgrades, and rollbacks
- Configure namespaces, secrets, deployments, and services
- Handle persistent volume claims and resource limits

## When to use me

Use this skill when you need to:
- Install or upgrade Helm charts on a Kubernetes cluster
- Modify deployment configurations via `values.yaml`
- Troubleshoot Helm release issues
- Manage multi-component Kubernetes deployments

## Hermes Chart Structure

```
charts/hermes/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── namespace.yaml
    ├── secrets.yaml
    ├── pvc.yaml
    ├── gateway-deployment.yaml
    ├── gateway-service.yaml
    ├── dashboard-deployment.yaml
    └── dashboard-service.yaml
```

## Installation

```bash
helm install hermes ./charts/hermes -n hermes --create-namespace
```

## Upgrade

```bash
helm upgrade hermes ./charts/hermes -n hermes
```

## Uninstall

```bash
helm uninstall hermes -n hermes
```

## Key Configuration

Edit `values.yaml` to customize:

- `image.repository` and `image.tag` - Container image
- `secrets.*` - API keys and tokens
- `gateway.resources` and `dashboard.resources` - CPU/memory limits
- `persistence.size` and `persistence.storageClass` - Storage configuration
- `namespace` - Target Kubernetes namespace
