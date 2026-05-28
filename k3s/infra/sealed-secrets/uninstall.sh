#!/bin/bash
# Uninstall Sealed Secrets Controller

set -e

NAMESPACE="kube-system"
RELEASE_NAME="sealed-secrets"

echo "=========================================="
echo "Uninstalling Sealed Secrets Controller"
echo "=========================================="

echo "⚠️  WARNING: This will remove the controller but NOT the secrets it created."
echo "⚠️  Sealed secrets in Git will no longer be decryptable without the controller keys!"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Backing up controller keys first..."
kubectl get secret -n $NAMESPACE -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-keys-backup-$(date +%Y%m%d-%H%M%S).yaml
echo "✓ Keys backed up to sealed-secrets-keys-backup-*.yaml"

echo ""
echo "Uninstalling Helm release..."
helm uninstall $RELEASE_NAME --namespace $NAMESPACE

echo ""
echo "Sealed Secrets Controller uninstalled."
echo ""
echo "Note: Regular Secrets created by the controller are still in the cluster."
echo "Note: To re-enable, redeploy and restore the backed-up keys."
