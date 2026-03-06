# TO DO

## now
- velero make it run and then move to argocd

## later
- before destroy store sealed secrets (especially self hosted GH runner would require new setup)
    kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ~/sealed-secrets-backup.yaml
- move logging, mon to argocd
- mention in readme - manual configuration needed for nas - basic config for k3s, minio download  for valero (download via container manager) (minio guide - https://yarboroughtechnologies.com/how-to-install-minio-on-synology-docker/ + Log in to MinIO web UI (http://$NASIP:9000) and create a bucket named exactly as in your Velero config (likely velero-backups).)


## ansible to do
- not sure about sealed secrets backup so runner is fine after destroy, maybe if no backup we need to create those secrets with ansible vault