# Infrastructure Destruction Scripts

## Overview
Scripts for safely destroying and resetting the K3s infrastructure.

## Available Methods

### Method 1: Ansible Playbook (Recommended)
**Use when:** You want to reset the cluster across all nodes cleanly

```bash
cd ~/k3s_homelab_with_nas
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/reset-k3s.yml
```

**What it does:**
- Stops K3s services
- Uninstalls K3s
- Removes K3s directories
- Preserves your code repository

### Method 2: Complete Destruction Script
**Use when:** You want to completely wipe everything, including data

```bash
cd ~/k3s_homelab_with_nas
bash scripts/destroy-k3s.sh
```

**What it does:**
- Backs up critical data first
- Stops all K3s services
- Uninstalls K3s completely
- Removes ALL data (including Longhorn storage)
- Cleans up network configuration
- Removes iptables rules
- Unmounts filesystems
- Cleans up systemd services

⚠️ **WARNING:** This is destructive! Use for:
- Testing disaster recovery
- Starting completely fresh
- Troubleshooting major issues

## Comparison

| Feature | Ansible Reset | Destroy Script |
|---------|--------------|----------------|
| Multi-node support | ✅ Yes | ❌ Single node |
| Backup before destroy | ❌ No | ✅ Yes |
| Remove Longhorn data | ⚠️ Partial | ✅ Complete |
| Clean iptables | ❌ No | ✅ Yes |
| Network cleanup | ⚠️ Partial | ✅ Complete |
| Interactive prompts | ❌ No | ✅ Yes |
| Recommended for | Normal resets | Complete wipe |

## Before Destroying

### Backup Important Data

```bash
# Backup kubeconfig
cp ~/.kube/config ~/kubeconfig-backup.yaml

# Backup sealed secrets controller keys
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > ~/sealed-secrets-backup.yaml

# Backup ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ~/argocd-password.txt

# Export Prometheus data (if needed)
# Export Grafana dashboards
# Backup any persistent data from NFS
```

### Document Current State

```bash
# List all namespaces
kubectl get ns > ~/cluster-namespaces.txt

# List all PVCs
kubectl get pvc -A > ~/cluster-pvcs.txt

# List all services
kubectl get svc -A > ~/cluster-services.txt
```

## After Destruction

### Verify Clean State

```bash
# Check no K3s processes
ps aux | grep k3s

# Check no K3s mounts
mount | grep k3s

# Check network interfaces
ip link show

# Check iptables
sudo iptables -L -n
```

### Reinstall

```bash
cd ~/k3s_homelab_with_nas
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/setup-k3s.yml
```

### Restore Data

```bash
# Restore sealed secrets keys (do this BEFORE deploying apps!)
kubectl apply -f ~/sealed-secrets-backup.yaml

# Wait for sealed secrets controller
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sealed-secrets -n kube-system --timeout=300s

# Deploy apps via ArgoCD
kubectl apply -f k3s/argocd/apps/
```

## Safety Tips

1. ✅ **Always backup first** - Especially sealed secrets keys
2. ✅ **Test in isolated environment** if possible
3. ✅ **Document current state** before destruction
4. ✅ **Verify NFS data** is preserved (on Synology)
5. ✅ **Use Ansible reset** for normal cluster resets
6. ✅ **Use destroy script** only when necessary
7. ✅ **Reboot after destruction** for clean slate

## Common Use Cases

### Testing Disaster Recovery
```bash
# 1. Backup everything
# 2. Run destroy script
bash scripts/destroy-k3s.sh
# 3. Reinstall from scratch
# 4. Restore from backups
# 5. Verify all services
```

### Fixing Broken Cluster
```bash
# Try Ansible reset first
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/reset-k3s.yml

# If that doesn't work, use destroy script
bash scripts/destroy-k3s.sh

# Reinstall
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/setup-k3s.yml
```

### Starting Fresh Project
```bash
# Complete destruction
bash scripts/destroy-k3s.sh

# Reboot
sudo reboot

# Fresh install with new configuration
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/setup-k3s.yml
```

## Troubleshooting

### Script fails with permission errors
```bash
# Run with proper permissions
sudo bash scripts/destroy-k3s.sh
```

### Some mounts won't unmount
```bash
# Force unmount
sudo umount -l /var/lib/rancher/k3s

# Or reboot
sudo reboot
```

### Network interfaces still present after cleanup
```bash
# Reboot to fully clean network
sudo reboot
```

### Ansible playbook fails
```bash
# Check connectivity
ansible -i ansible/inventory/hosts.yml all -m ping

# Run with verbose output
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/reset-k3s.yml -vvv
```

## Recovery from Failed Destruction

If destruction script fails midway:

```bash
# 1. Stop all K3s processes manually
sudo killall k3s || true
sudo killall containerd || true

# 2. Unmount all K3s mounts
sudo umount -R /var/lib/rancher/k3s || true

# 3. Remove directories manually
sudo rm -rf /var/lib/rancher
sudo rm -rf /etc/rancher

# 4. Reboot
sudo reboot

# 5. Run destroy script again
bash scripts/destroy-k3s.sh
```
