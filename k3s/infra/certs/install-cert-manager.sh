#!/bin/bash
# Install cert-manager and configure self-signed CA

set -e

SCRIPT_DIR="$(dirname "$0")"

echo "=========================================="
echo "Installing cert-manager"
echo "=========================================="

# Install cert-manager CRDs and controller
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml

echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager-webhook -n cert-manager
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager-cainjector -n cert-manager

echo ""
echo "=========================================="
echo "Creating ClusterIssuer and CA"
echo "=========================================="

# Apply ClusterIssuer configuration
kubectl apply -f "$SCRIPT_DIR/cluster-issuer.yaml"

# Wait for CA certificate to be ready
echo "Waiting for homelab CA certificate..."
kubectl wait --for=condition=ready --timeout=60s \
  certificate/homelab-ca -n cert-manager

echo ""
echo "=========================================="
echo "cert-manager setup complete!"
echo "=========================================="
echo ""
echo "✅ cert-manager installed"
echo "✅ Self-signed CA created"
echo ""
echo "Next: Apply TLS ingresses for your services"
echo "  kubectl apply -f k3s/monitoring/ingress-tls.yaml"
echo "  kubectl apply -f k3s/certs/ingress-tls-all.yaml"
echo ""
