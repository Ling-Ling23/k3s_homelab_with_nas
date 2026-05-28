#!/bin/bash
# Uninstall Loki + Fluent Bit logging stack

set -e

NAMESPACE="logging"

echo "Uninstalling Logging Stack..."

# Uninstall Fluent Bit
helm uninstall fluent-bit -n $NAMESPACE || true

# Uninstall Loki
helm uninstall loki -n $NAMESPACE || true

# Delete PVCs
echo "Deleting PVCs..."
kubectl delete pvc -n $NAMESPACE --all || true

# Delete namespace
echo "Deleting namespace..."
kubectl delete namespace $NAMESPACE || true

echo "Logging Stack uninstalled!"
