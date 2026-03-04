# ArgoCD Setup

## Overview
ArgoCD is deployed to manage applications via GitOps. Changes pushed to Git are automatically synced to the cluster.

## Access
- **Web UI:** https://argocd.home.local
- **Username:** admin
- **Password:** Get with: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`

## Directory Structure
```
argocd/
├── apps/               # ArgoCD Application manifests
│   └── demo-app.yaml   # Demo application definition
├── demo-app/           # Demo app Kubernetes manifests
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── helm_values/
│   └── argocd-values.yaml
├── deploy.sh
└── README.md
```

## Quick Start

### 1. Deploy ArgoCD
```bash
bash k3s/argocd/deploy.sh
```

### 2. Access ArgoCD UI
Login to https://argocd.home.local with admin credentials
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
### 3. Deploy Demo App

**Important:** Update `apps/demo-app.yaml` with your Git repository URL first!

Then apply:
```bash
kubectl apply -f k3s/argocd/apps/demo-app.yaml
```

Or via ArgoCD UI:
- Click "+ NEW APP"
- Fill in the form with your repo details
- Click "CREATE"

### 4. Access Demo App
After sync completes, visit: https://demo.home.local

## How It Works

1. **Git as Source of Truth:** All manifests are stored in Git
2. **ArgoCD Watches:** ArgoCD monitors your Git repo for changes
3. **Auto-Sync:** Changes are automatically applied to cluster
4. **Self-Heal:** If someone manually changes the cluster, ArgoCD reverts it

## Common Commands

```bash
# Get ArgoCD apps
kubectl get applications -n argocd

# Check sync status
kubectl get application demo-app -n argocd -o yaml

# Manual sync (if auto-sync is disabled)
kubectl patch application demo-app -n argocd -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}' --type merge

# View logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

## Next Steps

Once you're comfortable with the demo:
1. Convert existing deployments (monitoring, longhorn) to ArgoCD apps
2. Set up proper Git workflow (branches, PRs)
3. Implement Secret Management (Sealed Secrets)
4. Configure RBAC and projects

## Troubleshooting

### App not syncing?
```bash
# Check ArgoCD application status
kubectl describe application demo-app -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Cannot access UI?
```bash
# Check ingress
kubectl get ingress -n argocd

# Port-forward as backup
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Authentication failed?
Reset admin password:
```bash
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -bnBC 10 "" YOUR_NEW_PASSWORD | tr -d ':\n')'"}}'
```
