# GitHub Actions Self-Hosted Runner

## Overview
Deploy a self-hosted GitHub Actions runner in your K3s cluster to run CI/CD workflows locally.

## Benefits
- ✅ **Free CI/CD** - No GitHub Actions minutes limit
- ✅ **Fast builds** - Local network access to NAS
- ✅ **Full control** - Install any tools you need
- ✅ **Access local resources** - Can push to local Harbor registry

## Prerequisites
1. GitHub Personal Access Token (PAT) with `repo` scope
2. ArgoCD deployed

## Setup Steps

### 1. Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
4. Click "Generate token"
5. **Copy the token** (you won't see it again!)

### 2. Create Kubernetes Secret

**On your local machine:**

```bash
# Create a temporary secret file (DO NOT commit this!)
cat > /tmp/github-runner-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: github-runner-secret
  namespace: github-runner
type: Opaque
stringData:
  GITHUB_TOKEN: "YOUR_GITHUB_PAT_HERE"
  REPO_URL: "https://github.com/Ling-Ling23/k3s_homelab_with_nas"
EOF

# Apply to cluster
kubectl create namespace github-runner
kubectl apply -f /tmp/github-runner-secret.yaml

# Delete the temporary file
rm /tmp/github-runner-secret.yaml
```

**Or via SSH:**

```bash
ssh lingling@192.168.0.197 "kubectl create namespace github-runner && \
kubectl create secret generic github-runner-secret -n github-runner \
  --from-literal=GITHUB_TOKEN='YOUR_TOKEN_HERE' \
  --from-literal=REPO_URL='https://github.com/Ling-Ling23/k3s_homelab_with_nas'"
```

### 3. Deploy via ArgoCD

**Option A: Via kubectl**
```bash
kubectl apply -f k3s/argocd/apps/github-runner.yaml
```

**Option B: Via ArgoCD UI**
1. Open https://argocd.home.local
2. Click "+ NEW APP"
3. Fill in:
   - Application Name: `github-runner`
   - Project: `default`
   - Repository URL: `https://github.com/Ling-Ling23/k3s_homelab_with_nas.git`
   - Path: `k3s/argocd/github-runner`
   - Cluster: `https://kubernetes.default.svc`
   - Namespace: `github-runner`
4. Click "CREATE"

### 4. Verify Deployment

```bash
# Check runner pod
kubectl get pods -n github-runner

# Check logs
kubectl logs -n github-runner -l app=github-runner -f

# Should see: "Listening for Jobs"
```

### 5. Verify in GitHub

1. Go to: https://github.com/Ling-Ling23/k3s_homelab_with_nas/settings/actions/runners
2. You should see your self-hosted runner with status **"Idle"** or **"Active"**

## Usage

### Create a Workflow

Create `.github/workflows/test.yml`:

```yaml
name: Test Self-Hosted Runner

on:
  push:
    branches: [ develop ]

jobs:
  test:
    runs-on: self-hosted  # Use your runner!
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Test
      run: |
        echo "Running on self-hosted runner!"
        kubectl version --client
        ls -la
```

Push to GitHub and watch it run on your cluster!

## Scaling

To run multiple runners:

```bash
# Edit deployment.yaml
replicas: 3

# Commit and push - ArgoCD will sync
```

## Troubleshooting

### Runner not appearing in GitHub?

```bash
# Check logs for errors
kubectl logs -n github-runner -l app=github-runner

# Common issues:
# - Invalid token
# - Wrong repo URL
# - Network connectivity
```

### Token expired?

```bash
# Update secret with new token
kubectl delete secret github-runner-secret -n github-runner
kubectl create secret generic github-runner-secret -n github-runner \
  --from-literal=GITHUB_TOKEN='NEW_TOKEN' \
  --from-literal=REPO_URL='https://github.com/Ling-Ling23/k3s_homelab_with_nas'

# Restart pods
kubectl rollout restart deployment/github-runner -n github-runner
```

### Pods crashing?

```bash
# Check resource limits (Pi has limited CPU/RAM)
kubectl describe pod -n github-runner -l app=github-runner
```

## Security Notes

⚠️ **Important:**
- Never commit the secret YAML with your token!
- Rotate tokens periodically
- Consider using Sealed Secrets (ROADMAP #6) for better secret management
- Limit token scope to minimum required

## Cleanup

```bash
# Delete via ArgoCD
kubectl delete application github-runner -n argocd

# Or manually
kubectl delete namespace github-runner
```

## Next Steps

1. ✅ Deploy the runner
2. Create test workflow
3. Build Docker images locally
4. Set up Harbor registry (#7 in ROADMAP)
5. Implement full CI/CD pipeline

## Resources

- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Image: myoung34/github-runner](https://github.com/myoung34/docker-github-actions-runner)
