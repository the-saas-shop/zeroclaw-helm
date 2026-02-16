# zeroclaw-helm

Helm chart for deploying [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) on Kubernetes.

## Usage

```bash
helm lint ./chart/zeroclaw
helm install zeroclaw ./chart/zeroclaw --set secret.apiKey="sk-..."
```

See full chart docs in `chart/zeroclaw/README.md`.
