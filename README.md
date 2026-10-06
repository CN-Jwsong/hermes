# Hermes Infrastructure Base Images

This repository contains base images for Hermes and a Helm chart for deploying it on Kubernetes.

## Container Image

The Helm chart deploys the official upstream image:

```
nousresearch/hermes-agent:latest
```

This repository also builds and publishes its own image daily:

```
ghcr.io/cn-jwsong/hermes:latest
```

## Automated Builds

A GitHub Actions workflow runs daily at 00:00 UTC to:

- Pull the latest Hermes Agent source code
- Build the container image
- Push to GitHub Container Registry (GHCR)

You can also trigger a manual build from the **Actions** tab.

The scheduled workflow runs from the default branch, so the published image is always built from `main`.

## Kubernetes Deployment (Helm)

A Helm chart is included for deploying Hermes on Kubernetes:

```bash
helm install hermes ./charts/hermes -n hermes --create-namespace
helm upgrade hermes ./charts/hermes -n hermes
```

The chart deploys:

- **Gateway** - API server on port 8642, with multi-agent profile support
- **Dashboard** - Web UI on port 9119
- **PVC** - 10Gi persistent storage for shared data

### Official Docker startup parameters

The container spec follows the official image
([Docker guide](https://hermes-agent.nousresearch.com/docs/user-guide/docker), `docker-compose.yml`):

| | Official | Chart |
|---|---|---|
| Image | `nousresearch/hermes-agent:latest` | same |
| Entry point | `/opt/hermes/docker/entrypoint-dispatch.sh` → s6 `/init` as PID 1 | **not overridden** — only `args` is set |
| Data volume | `~/.hermes:/opt/data` | PVC at `/opt/data` (`HERMES_HOME` default) |
| Gateway | `command: ["gateway", "run"]` | `args: ["gateway", "run"]` |
| Dashboard | `["dashboard", "--host", "0.0.0.0", "--port", "9119", "--no-open", "--skip-build"]` | same |
| Gateway API bind | `API_SERVER_HOST=0.0.0.0` + `API_SERVER_KEY` | set in `hermes-secrets` |
| Dashboard auth | `HERMES_DASHBOARD_BASIC_AUTH_*` | set in `hermes-secrets` |

Because the entry point is preserved, the image behaves exactly as documented:

- s6-overlay `/init` is PID 1 → the supervision tree, the zombie reaper and the
  stage2 bootstrap (UID/GID remap, data-volume `chown`, config seeding, skills sync)
  all run as upstream intends. Only `command:` overrides would break this, so the
  chart sets `args:` only.
- The container starts as root, drops to the `hermes` user via `s6-setuidgid`, and
  ownership of a root-written PVC is repaired on first boot.
- A container whose args start with `dashboard` is recognised as dashboard-only by
  `hermes_cli.container_boot`, which skips gateway reconciliation — so the dashboard
  Deployment never starts a second gateway against the shared volume.

Notes:

- **`API_SERVER_KEY` is mandatory.** The API server adapter only starts when the key
  is usable (at least 16 characters, not a placeholder). Without it nothing listens on
  8642, so the gateway Service and the dashboard health probe both fail.
- **`API_SERVER_HOST=0.0.0.0` is mandatory in Kubernetes.** It defaults to `127.0.0.1`,
  which a ClusterIP Service cannot reach.
- **The dashboard binds `0.0.0.0`, so it always needs an auth provider.**
  `HERMES_DASHBOARD_INSECURE` / `--insecure` have been no-ops since the June 2026
  hardening; the chart supplies username/password + a stable session secret instead.
- **`--skip-build` is belt and braces.** The image already sets `HERMES_WEB_DIST`, so
  no build is attempted either way.
- If the volume already contains an `API_SERVER_KEY` line in `.env`, that value wins
  over the container env (`.env` is loaded with `override=True`).

### Multi-Agent Profiles

Containers in one pod share the network namespace, so every agent needs its own
`API_SERVER_PORT`. The first enabled agent's port must equal `gateway.service.port`
(it is the Service `targetPort`).

| Agent | Profile | Port | Args |
|-------|---------|------|------|
| `gateway-hermes` | (default) | 8642 | `gateway run` |
| `gateway-coder` | `coder` | 8643 | `--profile=coder gateway run` |
| `gateway-devops` | `devops` | 8644 | `--profile=devops gateway run` |

Control which agents are active via `values.yaml`:

```yaml
gateway:
  agents:
    - name: gateway-hermes
      port: 8642
      enabled: true
    - name: gateway-coder
      port: 8643
      enabled: true      # set false to disable
    - name: gateway-devops
      port: 8644
      enabled: true
```

### Resources

`gateway.resources` is applied to **each** agent container, so the gateway pod's total
is the sum over enabled agents (3 agents = 6Gi memory limit, `3.84` CPU limit).

| Workload | Requests | Limits |
|---|---|---|
| `gateway` (per agent) | 512m / 1Gi | 1280m / 2Gi |
| `dashboard` | 256m / 512Mi | 1280m / 1.5Gi |

### Deployment notes

- The gateway and dashboard pods both mount the same `ReadWriteOnce` PVC, so they must
  land on the same node (use `ReadWriteMany` or pod affinity if your storage requires it).
- The dashboard reads gateway liveness over `GATEWAY_HEALTH_URL` (HTTP). Upstream notes
  that a dashboard in a separate PID namespace cannot detect the gateway process directly.
- The chart does not set `securityContext`; the official image needs root at boot for
  its bootstrap and drops privileges itself.
- Set `secrets.openaiApiKey` before installing; GitHub push protection rejects real keys.

## Usage

```bash
docker run --rm nousresearch/hermes-agent:latest hermes
```
