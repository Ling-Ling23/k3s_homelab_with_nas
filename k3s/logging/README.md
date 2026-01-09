# Centralized Logging with Promtail + Loki

## Overview
Complete logging stack for collecting, aggregating, and querying logs from all cluster pods and nodes.

**Stack:**
- **Promtail** - Lightweight log collector (DaemonSet on every node) - ARM-compatible
- **Loki** - Log aggregation and storage
- **Grafana** - Log visualization and querying (already installed)

## Quick Start

### Deploy Logging Stack
```bash
cd k3s/logging
bash deploy.sh
```

### Add Loki to Grafana
```bash
kubectl apply -f loki-datasource.yaml
```

Or manually in Grafana:
1. Go to https://grafana.homelab.local
2. Configuration → Data Sources → Add data source
3. Select Loki
4. URL: `http://loki.logging.svc.cluster.local:3100`
5. Save & Test

## Verify Deployment

```bash
# Check pods
kubectl get pods -n logging

# Expected:
# promtail-xxxxx (DaemonSet - one per node)
# loki-0 (StatefulSet)
# loki-canary-xxxxx (DaemonSet)

# Check Promtail logs (excluding readiness probe spam)
kubectl logs -n logging -l app.kubernetes.io/name=promtail | grep -v 'GET /ready' | tail -50

# Check Loki logs
kubectl logs -n logging loki-0 -c loki -f
```

## Query Logs in Grafana

### Access Grafana Explore
1. Go to https://grafana.homelab.local
2. Click Explore (compass icon)
3. Select "Loki" datasource

### Example LogQL Queries

**All logs from a namespace:**
```logql
{namespace="monitoring"}
```

**Logs from specific pod:**
```logql
{namespace="monitoring", pod=~"prometheus.*"}
```

**Logs containing "error":**
```logql
{namespace="monitoring"} |= "error"
```

**Logs from last 5 minutes:**
```logql
{namespace="default"} | json | line_format "{{.log}}"
```

**Count errors by namespace:**
```logql
sum by (namespace) (count_over_time({job="fluentbit"} |= "error" [5m]))
```

**Filter by log level:**
```logql
{namespace="monitoring"} | json | level="error"
```

## Configuration

### Retention Period
Edit [loki-values.yaml](loki-values.yaml):
```yaml
limits_config:
  retention_period: 168h  # 7 days (default)
```

### Storage Size
Edit [loki-values.yaml](loki-values.yaml):
```yaml
singleBinary:
  persistence:
    size: 10Gi  # Adjust based on log volume
```

### Promtail Pipeline Stages
Edit [promtail-values.yaml](helm_values/promtail-values.yaml) to add custom parsing/filtering in the `pipeline_stages` section.

## Storage Usage

Monitor Loki storage:
```bash
kubectl exec -n logging loki-0 -- du -sh /var/loki
```

## Troubleshooting

### No logs appearing in Grafana

**1. Check Promtail is running:**
```bash
kubectl get pods -n logging -l app.kubernetes.io/name=promtail
```

**2. Check Promtail logs:**
```bash
kubectl logs -n logging -l app.kubernetes.io/name=promtail --tail=50 | grep -v 'GET /ready'
```

**3. Verify Loki is receiving logs:**
```bash
kubectl logs -n logging loki-0 -c loki --tail=50
```

**4. Test Loki API:**
```bash
kubectl port-forward -n logging svc/loki 3100:3100
curl http://localhost:3100/ready
curl http://localhost:3100/loki/api/v1/labels
```

### Promtail not collecting logs

Check permissions:
```bash
kubectl describe daemonset promtail -n logging
```

Verify volume mounts:
```bash
kubectl get pod -n logging -l app.kubernetes.io/name=promtail -o yaml | grep -A 10 volumeMounts
```

### Promtail shows 0/1 Ready

This is normal - Promtail's readiness probe is strict but logs are still being collected. Check that logs appear in Grafana Explore.

### High memory usage

Reduce limits in [promtail-values.yaml](helm_values/promtail-values.yaml):
```yaml
resources:
  limits:
    memory: 64Mi  # Reduce from 128Mi
```

### Loki pod not starting

Check PVC status:
```bash
kubectl get pvc -n logging
kubectl describe pvc storage-loki-0 -n logging
```

Verify NFS storage is working:
```bash
kubectl get storageclass nfs-synology
```

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Pod A     │     │   Pod B     │     │   Pod C     │
│  (logs)     │     │  (logs)     │     │  (logs)     │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Promtail   │  (DaemonSet - collects)
                    │  (~64Mi mem)│
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │    Loki     │  (aggregates & stores)
                    │ SingleBinary│
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   Grafana   │  (query & visualize)
                    └─────────────┘
```

## Performance

**Promtail resource usage (per node):**
- CPU: ~50m (idle) to 100m (peak)
- Memory: ~64Mi (idle) to 128Mi (peak)

**Loki resource usage:**
- CPU: ~100m (idle) to 300m (peak)
- Memory: ~256Mi (SingleBinary mode)
- Storage: Depends on log volume (~1-2GB per day typical)

## Log Retention Calculator

**Estimate storage needs:**
- Low volume: ~500MB/day → 3.5GB/week
- Medium volume: ~1GB/day → 7GB/week
- High volume: ~2GB/day → 14GB/week

Adjust retention and storage accordingly.

## Alerts (Optional)

Create alerts in Grafana based on log patterns:
1. Go to Grafana → Alerting → Alert rules
2. Create alert with LogQL query
3. Example: Alert on error rate increase

```logql
rate({namespace="production"} |= "error" [5m]) > 10
```

## Next Steps

- Create custom Grafana dashboards for log visualization
- Set up log-based alerts
- Explore log patterns and troubleshoot issues
- Consider adding log sampling for high-volume apps

## Uninstall

```bash
bash uninstall.sh
```

## Resources

- Loki docs: https://grafana.com/docs/loki/
- Fluent Bit docs: https://docs.fluentbit.io/
- LogQL guide: https://grafana.com/docs/loki/latest/logql/
