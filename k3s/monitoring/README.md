# Prometheus Monitoring Stack Deployment

## Quick Start

```bash
# SSH to your Pi
ssh lingling@192.168.0.197
cd ~/k3s_homelab_with_nas/k3s/monitoring

# Deploy
bash deploy.sh

# Apply ingress
kubectl apply -f ingress.yaml
```

**Access:**
- Grafana: `http://grafana.homelab.local` (admin/admin)
- Prometheus: `http://prometheus.homelab.local`
- Alertmanager: `http://alertmanager.homelab.local`

Update hosts file: `192.168.0.200 grafana.homelab.local prometheus.homelab.local alertmanager.homelab.local`

## Configuration

Edit [prometheus-values.yaml](prometheus-values.yaml) to customize storage, retention, passwords, etc.

## Uninstall

```bash
bash uninstall.sh
```
