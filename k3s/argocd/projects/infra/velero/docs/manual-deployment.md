# Velero Deployment (Helm + S3-Compatible NAS/MinIO)

This guide installs Velero using Helm and stores backups in an S3-compatible endpoint (Synology/MinIO).

## Prerequisites

- `kubectl` connected to your cluster
- `helm` installed
- S3-compatible bucket created (example: `velero-backups`)
- Access key + secret key from Synology/MinIO

## Info
- Velero backs up Kubernetes resources and optionally persistent volume data.
By default, it saves: Namespaces, deployments, services, configmaps, secrets, CRDs, etc.
All objects in the selected namespaces (or cluster-wide if you choose).
Optionally, persistent volume snapshots (if configured and supported).

## ArgoCD notes

- Velero Helm install is managed by `k3s/argocd/apps/velero.yaml`.
- Helm values are loaded from `k3s/argocd/velero/helm_values/velero-values.yaml`.
- Ensure `cloud-credentials` secret exists in namespace `velero` before syncing the app.
- Keep smoke-test manifests for manual validation; do not auto-sync restore manifests continuously.



## 8) Run a restore test (recommended)

```bash
velero restore create --from-backup smoke-test
velero restore describe --details <restore-name>
```


## 1) Create credentials file

Create a temporary credentials file on your control machine:

see PW SAFE for correct password
```bash
cat > credentials-velero <<'EOF'
[default]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_KEY
EOF
```

## 2)
```bash
cd /home/lingling/k3s_homelab_with_nas/
kubectl -n velero create secret generic cloud-credentials \
  --from-file=cloud=credentials-velero \
  --dry-run=client -o yaml | \
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system --format yaml > k3s/argocd/velero/cloud-credentials-sealedsecret.yaml

lingling@raspi1:~/k3s_homelab_with_nas/k3s/velero $ kaf namespace.yaml 
namespace/velero created
kaf /home/lingling/k3s_homelab_with_nas/k3s/argocd/velero/cloud-credentials-sealedsecret.yaml 
kg secret -n velero                 cloud-credentials  
```

## 3) install with helm
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update
helm upgrade --install velero vmware-tanzu/velero -n velero -f velero-values.yaml

## 4) verify
kubectl -n velero get backupstoragelocations
kubectl -n velero describe backupstoragelocation default
kubectl -n velero get backups
kubectl -n velero logs deploy/velero

## 5) cleanup local credentials file

rm -f credentials-velero

## 6) run smoke test
kaf smoke-test.yaml
kubectl -n velero get backups.velero.io
kubectl -n velero describe backups.velero.io smoke-test

## 7) daily backups
kaf backup-schedule.yaml
kubectl -n velero describe schedules.velero.io daily-backup
kubectl -n velero get schedules.velero.io

## 8) Run a restore test (recommended)
kaf smoke-tests/restore-smoke.yaml
kubectl -n velero get restores.velero.io
kubectl -n velero describe restores.velero.io smoke-test-restore



## Troubleshooting

### BackupStorageLocation is unavailable

- Verify `s3Url`, bucket name, access key, and secret key
- Check DNS/network reachability from cluster to NAS/MinIO endpoint
- Check Velero logs


### Plugin errors

- Confirm AWS plugin initContainer is present in `velero-values.yaml`
- Re-run Helm upgrade after values changes

```bash
helm upgrade --install velero vmware-tanzu/velero -n velero -f k3s/velero/velero-values.yaml --wait
```
