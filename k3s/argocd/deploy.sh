#!/bin/bash
# Deploy ArgoCD using Helm with values file

set -e

NAMESPACE="argocd"
RELEASE_NAME="argocd"
HELM_REPO="argo"
CHART="argo/argo-cd"
VALUES_FILE="$(dirname "$0")/helm_values/argocd-values.yaml"

echo "=========================================="
echo "Deploying ArgoCD"
echo "=========================================="

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed"
    echo "Install with: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi

# Add Helm repository
echo "Adding ArgoCD Helm repository..."
helm repo add $HELM_REPO https://argoproj.github.io/argo-helm

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Create namespace if it doesn't exist
echo "Creating namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade ArgoCD
echo "Installing ArgoCD with Helm..."
helm upgrade --install $RELEASE_NAME $CHART \
    --namespace $NAMESPACE \
    --values $VALUES_FILE \
    --wait

echo ""
echo "=========================================="
echo "ArgoCD deployed successfully!"
echo "=========================================="
echo ""
echo "Get the initial admin password:"
echo "kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Port forward to access UI:"
echo "kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"
echo ""
echo "Or access via Ingress (if configured):"
echo "https://argocd.home.local"
echo ""
echo "Login with:"
echo "  Username: admin"
echo "  Password: (use command above)"
echo ""
echo "Install ArgoCD CLI (optional):"
echo "  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "  chmod +x argocd"
echo "  sudo mv argocd /usr/local/bin/"
echo ""
