# 0) If Argo app already exists, remove it first so autosync doesn't recreate Velero while cleaning
kubectl -n argocd delete application velero --ignore-not-found

# 1) Delete Velero custom resources (cleanup before uninstall)
kubectl -n velero delete restores.velero.io --all --ignore-not-found
kubectl -n velero delete backups.velero.io --all --ignore-not-found
kubectl -n velero delete schedules.velero.io --all --ignore-not-found
kubectl -n velero delete backuprepositories.velero.io --all --ignore-not-found
kubectl -n velero delete podvolumebackups.velero.io --all --ignore-not-found
kubectl -n velero delete podvolumerestores.velero.io --all --ignore-not-found
kubectl -n velero delete datauploads.velero.io --all --ignore-not-found
kubectl -n velero delete datadownloads.velero.io --all --ignore-not-found

# 2) Uninstall Helm release
helm -n velero uninstall velero || true

# 3) Delete namespace (removes secrets, pods, schedules, etc.)
kubectl delete namespace velero --ignore-not-found --wait=true

# 4) Full reset: remove Velero CRDs too
kubectl delete crd \
  backups.velero.io \
  backuprepositories.velero.io \
  backupstoragelocations.velero.io \
  deletebackuprequests.velero.io \
  downloadrequests.velero.io \
  podvolumebackups.velero.io \
  podvolumerestores.velero.io \
  restores.velero.io \
  schedules.velero.io \
  serverstatusrequests.velero.io \
  volumesnapshotlocations.velero.io \
  datauploads.velero.io \
  datadownloads.velero.io \
  --ignore-not-found

# 5) Verify
kubectl get ns velero
kubectl get crd | grep velero || echo "No Velero CRDs left"