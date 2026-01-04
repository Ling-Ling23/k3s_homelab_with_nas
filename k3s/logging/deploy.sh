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
helm repo add fluent https://fluent.github.io/helm-charts
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
  --wait \
  --timeout 5m

# Wait for Loki to be ready
echo "Waiting for Loki to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/loki-gateway -n $NAMESPACE || true

# Install Fluent Bit
echo ""
echo "Installing Fluent Bit..."
helm upgrade --install fluent-bit fluent/fluent-bit \
  --namespace $NAMESPACE \
  --values "$SCRIPT_DIR/helm_values/fluent-bit-values.yaml" \
  --wait \
  --timeout 5m

echo ""
echo "=========================================="
echo "Logging Stack deployed successfully!"
echo "=========================================="
echo ""
echo "Components installed:"
echo "  ✅ Loki (log aggregation)"
echo "  ✅ Fluent Bit (log collection)"
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
