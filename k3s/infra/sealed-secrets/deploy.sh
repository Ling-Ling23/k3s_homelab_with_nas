#!/bin/bash
# Deploy Sealed Secrets Controller using Helm

set -e

NAMESPACE="kube-system"
RELEASE_NAME="sealed-secrets"
HELM_REPO="sealed-secrets"
CHART="sealed-secrets/sealed-secrets"
VALUES_FILE="$(dirname "$0")/helm_values/sealed-secrets-values.yaml"

echo "=========================================="
echo "Deploying Sealed Secrets Controller"
echo "=========================================="

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed"
    echo "Install with: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi

# Add Helm repository
echo "Adding Sealed Secrets Helm repository..."
helm repo add $HELM_REPO https://bitnami-labs.github.io/sealed-secrets

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Install or upgrade Sealed Secrets
echo "Installing Sealed Secrets Controller with Helm..."
helm upgrade --install $RELEASE_NAME $CHART \
    --namespace $NAMESPACE \
    --values $VALUES_FILE \
    --wait

echo ""
echo "=========================================="
echo "Sealed Secrets Controller deployed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Install kubeseal CLI on your local machine:"
echo "   wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.26.0/kubeseal-0.26.0-linux-amd64.tar.gz"
echo "   tar -xvzf kubeseal-0.26.0-linux-amd64.tar.gz kubeseal"
echo "   sudo mv kubeseal /usr/local/bin/"
echo ""
echo "2. Verify controller is running:"
echo "   kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=sealed-secrets"
echo ""
echo "3. Test encryption:"
echo "   kubeseal --fetch-cert"
echo ""
echo "4. Create your first sealed secret:"
echo "   See README.md for examples"
echo ""
echo "5. BACKUP controller keys:"
echo "   kubectl get secret -n $NAMESPACE sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml"
echo ""
