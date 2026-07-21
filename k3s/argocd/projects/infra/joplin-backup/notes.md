# Joplin Backup CronJob

Backs up the Synology NAS folder `/volume1/joplin` to a private GitHub repo
once a day, using a plain NFS volume mount (read-only) + a CronJob.

kubectl create job -n joplin-backup joplin-backup-manual-1 --from=cronjob/joplin-backup
k -n joplin-backup delete job joplin-backup-manual-1

## Prerequisites

### 1. NFS export on Synology
Control Panel → Shared Folder → `joplin` → Edit → NFS Permissions → Add rule:
- Server: your k3s node subnet or specific node IPs (e.g. 192.168.0.197-199)
- Privilege: Read Only (backup job never needs to write)
- Squash: Map all users to admin (or guest, since it's read-only)

Verify from a node:
```bash
showmount -e 192.168.0.191
```
You should see `/volume1/joplin` listed.

### 2. Create a private GitHub repo for the backup
e.g. `Ling-Ling23/joplin-backup`, private, with an initial commit on `main`
(so `git clone --branch main` doesn't fail on an empty repo).

### 3. Create a GitHub Personal Access Token (PAT)
Fine-grained PAT scoped to only the `joplin-backup` repo, with **Contents:
Read and write** permission. Store it somewhere safe.

### 4. Seal the secret

```bash
cat > /tmp/joplin-backup-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: joplin-backup-secret
  namespace: joplin-backup
type: Opaque
stringData:
  GIT_USERNAME: "your-github-username"
  GIT_TOKEN: "github_pat_xxx"
EOF

kubeseal --format yaml \
  --controller-namespace kube-system \
  --controller-name sealed-secrets \
  < /tmp/joplin-backup-secret.yaml \
  > k3s/argocd/projects/infra/joplin-backup/sealed-secret.yaml

rm /tmp/joplin-backup-secret.yaml

git add k3s/argocd/projects/infra/joplin-backup/sealed-secret.yaml
git commit -m "Add sealed secret for joplin-backup"
git push
```

Once committed, register the app in ArgoCD by adding
`k3s/argocd/apps/joplin-backup.yaml` (already included in this change) — the
app-of-apps will pick it up automatically.

## Manual test

Trigger a one-off run without waiting for the schedule:
```bash
kubectl create job -n joplin-backup joplin-backup-manual --from=cronjob/joplin-backup
kubectl logs -n joplin-backup -l job-name=joplin-backup-manual -f
```

## Notes
- The GIT_REPO_PATH / GIT_BRANCH env vars in `cronjob.yaml` are not secret —
  edit them directly if your backup repo name/owner differs.
- Data is mounted **read-only**; the job never writes back to the NAS.
- History is kept as git commits, so old Joplin states are recoverable via
  `git log` / `git checkout <commit>` in the backup repo.
- Consider making the backup repo's history less noisy by squashing periodically,
  or just let git compress it (it's mostly small text/markdown-like data).
