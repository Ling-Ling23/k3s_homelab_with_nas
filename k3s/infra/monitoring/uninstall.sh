#!/bin/bash
# Uninstall Prometheus Stack

set -e

NAMESPACE="monitoring"
RELEASE_NAME="kube-prometheus-stack"

echo "Uninstalling Prometheus Stack..."
helm uninstall $RELEASE_NAME -n $NAMESPACE

echo "Deleting PVCs (Prometheus and Grafana data)..."
kubectl delete pvc -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME

echo "Deleting namespace..."
kubectl delete namespace $NAMESPACE

echo "Prometheus Stack uninstalled!"
