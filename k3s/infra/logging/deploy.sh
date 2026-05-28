#!/bin/bash
# Deploy Loki + Fluent Bit logging stack

set -e

NAMESPACE="logging"
SCRIPT_DIR="$(dirname "$0")"

echo "=========================================="
echo "Deploying Logging Stack (Loki + Fluent Bit)"
echo "=========================================="

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed"
    exit 1
fi

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
echo "Creating namespace: $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install Loki
echo ""
echo "Installing Loki..."
helm upgrade --install loki grafana/loki \
  --namespace $NAMESPACE \
  --values "$SCRIPT_DIR/helm_values/loki-values.yaml" \
  --timeout 10m \
  --debug

# Check Loki pods status
echo ""
echo "Checking Loki deployment status..."
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=loki

# Wait for Loki to be ready (but don't fail if gateway doesn't exist)
echo ""
echo "Waiting for Loki pod to be ready..."
kubectl wait --for=condition=ready --timeout=300s \
  pod -l app.kubernetes.io/name=loki -n $NAMESPACE || echo "Warning: Loki not ready yet, continuing..."

# Install Promtail
echo ""
echo "Installing Promtail..."
helm upgrade --install promtail grafana/promtail \
  --namespace $NAMESPACE \
  --values "$SCRIPT_DIR/helm_values/promtail-values.yaml" \
  --timeout 5m

echo ""
echo "=========================================="
echo "Logging Stack deployed successfully!"
echo "=========================================="
echo ""
echo "Components installed:"
echo "  ✅ Loki (log aggregation)"
echo "  ✅ Promtail (log collection)"
echo ""
echo "Next steps:"
echo "1. Add Loki datasource to Grafana:"
echo "   - URL: http://loki-gateway.logging.svc.cluster.local"
echo "   - Or run: kubectl apply -f $SCRIPT_DIR/loki-datasource.yaml"
echo ""
echo "2. Access Grafana and explore logs:"
echo "   - URL: https://grafana.homelab.local"
echo "   - Go to Explore → Select Loki datasource"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
