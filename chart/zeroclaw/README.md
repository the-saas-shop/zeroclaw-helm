# ZeroClaw Helm Chart

This chart deploys [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) on Kubernetes.

It is built from upstream runtime behavior:
- Docker image expects data under `/zeroclaw-data`
- Runs in `gateway` (webhook only) or `daemon` (full runtime) mode, both on port `3000` by default
- `API_KEY` and provider settings are passed by environment variables

## Prerequisites

- Kubernetes 1.24+
- Helm 3.12+
- A StorageClass (or an existing PVC) if persistence is enabled

## Install

```bash
helm install zeroclaw ./chart/zeroclaw \
  --set secret.apiKey="sk-..."
```

Or use an existing secret:

```bash
helm install zeroclaw ./chart/zeroclaw \
  --set secret.create=false \
  --set secret.existingSecret=zeroclaw-api \
  --set secret.existingSecretKey=API_KEY
```

## Upgrade

```bash
helm upgrade zeroclaw ./chart/zeroclaw -f my-values.yaml
```

## Uninstall

```bash
helm uninstall zeroclaw
```

## Configuration Notes

- **Runtime mode**: set `config.mode` to choose the runtime:
  - `gateway` (default) — HTTP webhook server only. You call `POST /webhook` to interact.
  - `daemon` — full autonomous runtime: gateway + channels (Telegram, Discord, …) + heartbeat + memory. The upstream daemon binds to `127.0.0.1:8080` internally (ignoring host/port config), so the chart automatically adds an `alpine/socat` sidecar that forwards `0.0.0.0:<service.targetPort>` → `127.0.0.1:8080`.
- **Pairing**: set `config.requirePairing: true` to enable the 6-digit pairing flow for bearer tokens. Defaults to `false` for Kubernetes (network-level auth via ClusterIP/ingress is usually sufficient).
- **Persistence**: data is mounted at `/zeroclaw-data` (config and workspace live there).
- **API key**: always injected into `API_KEY` from a Kubernetes Secret (generated or existing).
- **Runtime config**: set Docker-style env vars under `config` in values.
- **Security**: container runs as non-root (`65534`) with dropped Linux capabilities.

## Key Values

| Key                         | Type   | Default                            | Description                                  |
| --------------------------- | ------ | ---------------------------------- | -------------------------------------------- |
| `image.repository`          | string | `ghcr.io/theonlyhennygod/zeroclaw` | ZeroClaw image repository                    |
| `image.tag`                 | string | `latest`                           | ZeroClaw image tag                           |
| `replicaCount`              | int    | `1`                                | Deployment replica count                     |
| `service.type`              | string | `ClusterIP`                        | Kubernetes Service type                      |
| `service.port`              | int    | `3000`                             | Service port                                 |
| `secret.create`             | bool   | `true`                             | Create a chart-managed secret                |
| `secret.existingSecret`     | string | `""`                               | Existing secret name containing API key      |
| `secret.apiKey`             | string | `""`                               | API key value used when chart creates secret |
| `secret.existingSecretKey`  | string | `API_KEY`                          | Secret key used for the `API_KEY` env var    |
| `config.mode`               | string | `gateway`                          | `gateway` (webhook only) or `daemon` (full)  |
| `config.provider`           | string | `openrouter`                       | Value for `PROVIDER` env var                 |
| `config.allowPublicBind`    | bool   | `true`                             | Value for `ZEROCLAW_ALLOW_PUBLIC_BIND`       |
| `config.requirePairing`     | bool   | `false`                            | Require pairing code for bearer token        |
| `config.model`              | string | `""`                               | Optional `ZEROCLAW_MODEL` override           |
| `persistence.enabled`       | bool   | `true`                             | Enable PVC for `/zeroclaw-data`              |
| `persistence.existingClaim` | string | `""`                               | Use existing PVC instead of creating         |
| `persistence.size`          | string | `10Gi`                             | PVC requested size                           |
| `persistence.storageClass`  | string | `""`                               | StorageClass override                        |
| `ingress.enabled`           | bool   | `false`                            | Create Ingress                               |
| `httpRoute.enabled`         | bool   | `false`                            | Create Gateway API HTTPRoute                 |
| `httpRoute.parentRefs`      | list   | `[]`                               | Parent Gateway references for HTTPRoute      |
| `httpRoute.hostnames`       | list   | `[]`                               | Hostnames matched by HTTPRoute               |
| `resources`                 | object | `{}`                               | Optional CPU/memory requests and limits      |

## Example values.yaml

```yaml
# Gateway mode (default) — webhook API only
config:
  mode: gateway
  provider: openrouter
  allowPublicBind: true
  model: anthropic/claude-sonnet-4-20250514

secret:
  create: false
  existingSecret: zeroclaw-api
  existingSecretKey: API_KEY
```

```yaml
# Daemon mode — full autonomous runtime with channels
config:
  mode: daemon
  provider: anthropic
  model: anthropic/claude-sonnet-4-20250514

secret:
  create: true
  apiKey: "sk-..."
```

## Exposing ZeroClaw

Use either `Ingress` **or** Gateway API `HTTPRoute` (mutually exclusive):

```yaml
# Ingress
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: zeroclaw.example.com
      paths:
        - path: /
          pathType: Prefix
```

```yaml
# Gateway API HTTPRoute
httpRoute:
  enabled: true
  parentRefs:
    - name: public-gateway
      namespace: gateway-system
      sectionName: http
  hostnames:
    - zeroclaw.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
```

## Health checks

The chart uses `/health` for readiness/liveness probes.

## Testing

Run:

```bash
helm lint ./chart/zeroclaw
helm template zeroclaw ./chart/zeroclaw >/dev/null
```

You can also run:

```bash
helm test zeroclaw
```
