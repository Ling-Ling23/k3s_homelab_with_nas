# Prometheus Alert Rules for Raspberry Pi Cluster

## Overview
Custom alerting rules specifically designed for monitoring Raspberry Pi K3s cluster.

## Apply Rules

```bash
kubectl apply -f prometheus-rules.yaml
```

Verify:
```bash
kubectl get prometheusrules -n monitoring
```

## Alert Categories

### 1. Hardware Monitoring

**Temperature Alerts:**
- `RaspberryPiHighTemperature` - Temperature > 70°C for 5 minutes
- `RaspberryPiCriticalTemperature` - Temperature > 80°C for 2 minutes (risk of throttling)

**CPU Alerts:**
- `RaspberryPiHighCPU` - CPU usage > 85% for 10 minutes

**Memory Alerts:**
- `RaspberryPiHighMemory` - Memory usage > 85% for 5 minutes
- `RaspberryPiCriticalMemory` - Memory usage > 95% for 2 minutes

### 2. Storage Monitoring

**Disk Space:**
- `RaspberryPiLowDiskSpace` - Root filesystem > 75% full
- `RaspberryPiCriticalDiskSpace` - Root filesystem > 90% full

**SD Card Health:**
- `RaspberryPiHighDiskIO` - High disk I/O (SD card wear warning)

### 3. Network Monitoring

- `RaspberryPiHighNetworkErrors` - Network errors detected
- `RaspberryPiHighNetworkUsage` - Bandwidth near 1Gbps limit

### 4. Kubernetes Health

**Node Health:**
- `KubernetesNodeNotReady` - Node not ready for 5+ minutes
- `KubernetesNodeMemoryPressure` - Node under memory pressure
- `KubernetesNodeDiskPressure` - Node under disk pressure

**Pod Health:**
- `KubernetesPodCrashLooping` - Pod restarting frequently
- `KubernetesPodNotReady` - Pod not running for 10+ minutes
- `KubernetesHighPodMemory` - Pod using > 90% of memory limit

## View Alerts in Grafana

1. Go to https://grafana.homelab.local
2. Alerting → Alert rules
3. Filter by namespace: `monitoring`

## View Active Alerts in Prometheus

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Visit: http://localhost:9090/alerts

## Customize Thresholds

Edit [prometheus-rules.yaml](prometheus-rules.yaml) and adjust values:

```yaml
# Example: Change temperature threshold
- alert: RaspberryPiHighTemperature
  expr: node_hwmon_temp_celsius > 75  # Changed from 70
  for: 5m
```

Apply changes:
```bash
kubectl apply -f prometheus-rules.yaml
```

## Alert Severity Levels

- **critical** - Immediate action required (PagerDuty, SMS)
- **warning** - Attention needed (Slack, Email)
- **info** - Informational (Log only)

## Test Alerts

### Simulate high CPU:
```bash
kubectl run cpu-stress --image=polinux/stress --restart=Never -- stress --cpu 4 --timeout 600s
```

### Check memory usage:
```bash
kubectl top nodes
```

### Check temperature:
```bash
ssh lingling@192.168.0.197
vcgencmd measure_temp
```

## Alert Routing (Optional)

To route alerts to Slack, Email, etc., configure Alertmanager:

Edit Prometheus stack values:
```yaml
alertmanager:
  config:
    route:
      receiver: 'slack'
      group_by: ['alertname', 'cluster']
    receivers:
      - name: 'slack'
        slack_configs:
          - api_url: 'YOUR_SLACK_WEBHOOK_URL'
            channel: '#alerts'
```

## Silence Alerts (Temporary)

In Grafana:
1. Alerting → Silences
2. New Silence
3. Add matcher (e.g., `alertname=RaspberryPiHighTemperature`)
4. Set duration

Or via CLI:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# Create silence
amtool silence add alertname=RaspberryPiHighTemperature --duration=2h --alertmanager.url=http://localhost:9093
```

## Common Pi Temperature Ranges

- **< 50°C** - Excellent (idle)
- **50-60°C** - Good (light load)
- **60-70°C** - Normal (moderate load)
- **70-80°C** - High (heavy load, consider cooling)
- **> 80°C** - Critical (CPU throttling starts at 80-85°C)

## Improve Pi Cooling

If temperature alerts trigger frequently:
1. Add heatsinks to CPU
2. Install fan (5V GPIO-powered)
3. Improve case ventilation
4. Reduce CPU frequency (not recommended for K3s)
5. Move to air-conditioned room

## Recording Rules (Optional)

For frequently used queries, add recording rules to improve performance:

```yaml
- name: raspberry-pi-aggregations
  interval: 30s
  rules:
  - record: node:cpu_utilization:avg
    expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
  
  - record: node:memory_utilization:percent
    expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

## Next Steps

1. Set up Alertmanager routing (Slack, Email, etc.)
2. Create Grafana dashboards for Pi monitoring
3. Add custom alerts for your specific workloads
4. Set up alert acknowledgment workflow

## Resources

- Prometheus alerting docs: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
- PromQL examples: https://prometheus.io/docs/prometheus/latest/querying/examples/
- Best practices: https://prometheus.io/docs/practices/alerting/
