#!/bin/bash
# Deploy Prometheus Stack using Helm with values file

set -e

NAMESPACE="monitoring"
RELEASE_NAME="kube-prometheus-stack"
HELM_REPO="prometheus-community"
CHART="prometheus-community/kube-prometheus-stack"
VALUES_FILE="$(dirname "$0")/helm_values/prometheus-values.yaml"

echo "=========================================="
echo "Deploying Prometheus Stack"
echo "=========================================="

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed"
    echo "Install with: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi

# Add Helm repository
echo "Adding Prometheus Helm repository..."
helm repo add $HELM_REPO https://prometheus-community.github.io/helm-charts

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Create namespace
echo "Creating namespace: $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade Prometheus Stack
echo "Installing/Upgrading Prometheus Stack..."
helm upgrade --install $RELEASE_NAME $CHART \
  --namespace $NAMESPACE \
  --values $VALUES_FILE \
  --wait \
  --timeout 10m

echo ""
echo "=========================================="
echo "Prometheus Stack deployed successfully!"
echo "=========================================="
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "Access Grafana:"
echo "  URL: http://grafana.homelab.local"
echo "  Username: admin"
echo "  Password: admin (change this!)"
echo ""
echo "Access Prometheus (port-forward):"
echo "  kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-prometheus 9090:9090"
echo "  URL: http://localhost:9090"
echo ""

# Deploy additional manifests
echo "Deploying Grafana dashboard..."
kubectl apply -f "$(dirname "$0")/grafana-dashboard-configmap.yaml"

echo ""
echo "Dashboard will appear in Grafana in a few moments!"
