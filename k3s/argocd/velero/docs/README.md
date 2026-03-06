# Velero on Argo CD (Helm + S3-Compatible MinIO/NAS)

This folder is the GitOps source for Velero in your cluster.
Argo CD installs Velero from the Helm chart and uses values from this repo.

## What this manages

- Velero Helm values in `helm_values/velero-values.yaml`
- Velero namespace in `namespace.yaml`
- Daily backup schedule in `backup-schedule.yaml`
- Manual smoke-test manifests in `smoke-tests/`

Argo CD application manifest:

- `k3s/argocd/apps/velero.yaml`

## Prerequisites

- Sealed Secrets controller is running
- S3 bucket exists (example: `velero-backups`)
- MinIO/S3 credentials are known
- MinIO endpoint is reachable from cluster nodes

## 1) Create or update Velero credentials (SealedSecret)

Run from repo root:

```bash
cat > credentials-velero <<'EOF'
[default]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_KEY
EOF

kubectl -n velero create secret generic cloud-credentials \
  --from-file=cloud=credentials-velero \
  --dry-run=client -o yaml | \
kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  --format yaml > k3s/argocd/velero/cloud-credentials-sealedsecret.yaml

rm -f credentials-velero
```

Commit `k3s/argocd/velero/cloud-credentials-sealedsecret.yaml` to Git.

## 2) Deploy with Argo CD

```bash
kubectl apply -f k3s/argocd/apps/velero.yaml
```

## 3) Verify Velero is healthy

```bash
kubectl -n argocd get application velero
kubectl -n velero get pods
kubectl -n velero get backupstoragelocations
kubectl -n velero describe backupstoragelocation default
```

Expected: `BackupStorageLocation` phase is `Available`.

## 4) Run smoke backup test (manual)

```bash
kubectl apply -f k3s/argocd/velero/smoke-tests/smoke-test.yaml
kubectl -n velero get backups.velero.io
kubectl -n velero describe backups.velero.io smoke-test
```

## 5) Run smoke restore test (manual)

```bash
kubectl apply -f k3s/argocd/velero/smoke-tests/restore-smoke.yaml
kubectl -n velero get restores.velero.io
kubectl -n velero describe restores.velero.io smoke-test-restore
```

Restore warnings about existing resources are normal during smoke tests.

## 6) Daily backups

`backup-schedule.yaml` is synced by Argo CD.

Verify schedule:

```bash
kubectl -n velero get schedules.velero.io
kubectl -n velero describe schedules.velero.io daily-backup
```

## Troubleshooting

### InvalidAccessKeyId

- `aws_access_key_id` in `cloud-credentials` does not match MinIO access key
- Recreate and reseal `cloud-credentials-sealedsecret.yaml`

### NoSuchBucket

- Bucket configured in `helm_values/velero-values.yaml` does not exist
- Create it in MinIO (example: `velero-backups`)

### BackupStorageLocation is Unavailable

- Check endpoint in `helm_values/velero-values.yaml` (`s3Url`)
- Confirm network path from cluster to MinIO
- Check logs: `kubectl -n velero logs deploy/velero`
