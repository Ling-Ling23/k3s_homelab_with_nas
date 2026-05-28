# Sealed Secrets - GitOps Secret Management

## Overview
Sealed Secrets allows you to encrypt Kubernetes secrets and safely commit them to Git. The controller in your cluster decrypts them automatically.

## How It Works

```
1. You have a plaintext secret
   ↓
2. Encrypt with kubeseal CLI (uses controller's public key)
   ↓
3. Commit encrypted SealedSecret to Git (safe!)
   ↓
4. ArgoCD deploys SealedSecret
   ↓
5. Controller decrypts and creates regular Secret
   ↓
6. Your app uses the Secret
```

## Installation

### 1. Install Sealed Secrets Controller

```bash
bash k3s/sealed-secrets/deploy.sh
```

This will:
- Add Sealed Secrets Helm repo
- Install controller in `kube-system` namespace
- Wait for controller to be ready

### 2. Install kubeseal CLI

**On your local machine (Windows via WSL/Git Bash):**
```bash
# Download
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.26.0/kubeseal-0.26.0-linux-amd64.tar.gz

# Extract
tar -xvzf kubeseal-0.26.0-linux-amd64.tar.gz kubeseal

# Move to PATH
sudo mv kubeseal /usr/local/bin/
sudo chmod +x /usr/local/bin/kubeseal

# Verify
kubeseal --version
```

**On Raspberry Pi:**
```bash
ssh lingling@192.168.0.197 << 'EOF'
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.26.0/kubeseal-0.26.0-linux-arm64.tar.gz
tar -xvzf kubeseal-0.26.0-linux-arm64.tar.gz kubeseal
sudo mv kubeseal /usr/local/bin/
sudo chmod +x /usr/local/bin/kubeseal
kubeseal --version
EOF
```

## Usage

### Create a Sealed Secret

**Example: GitHub Runner Token**

```bash
# 1. Create plaintext secret YAML (don't commit!)
cat > /tmp/github-runner-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: github-runner-secret
  namespace: github-runner
type: Opaque
stringData:
  GITHUB_TOKEN: "ghp_YOUR_ACTUAL_TOKEN_HERE"
  REPO_URL: "https://github.com/Ling-Ling23/k3s_homelab_with_nas"
EOF

# 2. Encrypt it with kubeseal
kubeseal --format yaml \
  --controller-namespace kube-system \
  --controller-name sealed-secrets \
  < /tmp/github-runner-secret.yaml \
  > k3s/argocd/github-runner/sealed-secret.yaml

# 3. Delete plaintext version
rm /tmp/github-runner-secret.yaml

# 4. Commit encrypted version to Git (safe!)
git add k3s/argocd/github-runner/sealed-secret.yaml
git commit -m "Add sealed secret for GitHub runner"
git push

# 5. Apply (or let ArgoCD sync)
kubectl apply -f k3s/argocd/github-runner/sealed-secret.yaml
```

### Verify

```bash
# Check SealedSecret exists
kubectl get sealedsecret -n github-runner

# Check that Secret was created by controller
kubectl get secret github-runner-secret -n github-runner

# View the decrypted secret (be careful!)
kubectl get secret github-runner-secret -n github-runner -o yaml
```

## Update Existing Secrets

To update a secret:

```bash
# 1. Create new plaintext YAML with updated values
# 2. Seal it again (overwrites old sealed secret)
# 3. Commit and push
# 4. Controller will update the Secret
```

## Important Notes

### ⚠️ Backup Controller Keys

The controller's private key is what decrypts secrets. **Back it up!**

```bash
# Backup controller keys
kubectl get secret -n kube-system sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml

# Store this file safely (encrypted backup, password manager, etc.)
# If you lose this key, you'll need to re-seal all secrets!
```

### 🔑 Scope Options

Sealed Secrets can be scoped:
- **strict** (default): namespace + name specific
- **namespace-wide**: any name in namespace
- **cluster-wide**: any namespace, any name

For this setup, we use **strict** (most secure).

### 🔄 Key Rotation

Controller keys rotate every 30 days by default. Old keys are kept for decryption. This is automatic and transparent.

## Common Commands

```bash
# Get public key (for encrypting on different machine)
kubeseal --fetch-cert > pub-cert.pem

# Seal with specific cert file
kubeseal --cert pub-cert.pem --format yaml < secret.yaml > sealed-secret.yaml

# Seal from stdin
echo -n "my-password" | kubectl create secret generic my-secret --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal --format yaml > sealed-secret.yaml

# Re-encrypt existing secret
kubectl get secret my-secret -o yaml | kubeseal --format yaml > sealed-secret.yaml
```

## Migrate GitHub Runner Secret

Once Sealed Secrets is installed:

```bash
# 1. Get existing secret (if it exists)
kubectl get secret github-runner-secret -n github-runner -o yaml > /tmp/old-secret.yaml

# 2. Seal it
kubeseal --format yaml < /tmp/old-secret.yaml > k3s/argocd/github-runner/sealed-secret.yaml

# 3. Clean up
rm /tmp/old-secret.yaml

# 4. Update ArgoCD app to include sealed-secret.yaml in the path
git add k3s/argocd/github-runner/sealed-secret.yaml
git commit -m "Add sealed secret for GitHub runner"
git push

# 5. ArgoCD will sync and controller will create the secret
```

## Troubleshooting

### Secret not being decrypted?

```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check SealedSecret status
kubectl describe sealedsecret -n github-runner github-runner-secret
```

### "No key could decrypt secret"

This means:
- Secret was sealed with different controller
- Controller keys were lost/changed
- Need to re-seal with current controller

Solution: Re-seal the secret with `kubeseal --fetch-cert`

### Update not working?

Controller watches for changes, but might take 30-60 seconds. Force sync:

```bash
kubectl delete sealedsecret -n github-runner github-runner-secret
kubectl apply -f k3s/argocd/github-runner/sealed-secret.yaml
```

## Best Practices

1. ✅ **Always delete plaintext secrets** after sealing
2. ✅ **Backup controller keys** in secure location
3. ✅ **Use strict scoping** for security
4. ✅ **Commit sealed secrets to Git**
5. ✅ **Never commit plaintext secrets**
6. ✅ **Rotate secrets periodically**

## Next Steps

1. Install Sealed Secrets controller
2. Install kubeseal CLI
3. Seal your GitHub runner secret
4. Commit to Git
5. Deploy via ArgoCD
6. Repeat for other secrets (Grafana, etc.)

## Resources

- [Sealed Secrets GitHub](https://github.com/bitnami-labs/sealed-secrets)
- [Documentation](https://sealed-secrets.netlify.app/)
