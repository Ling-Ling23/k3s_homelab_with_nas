# Infrastructure Lifecycle Management

Guide for destroying and rebuilding your K3s homelab infrastructure.

## Table of Contents
- [Destroy/Rebuild Options](#destroyrebuild-options)
- [Current Workflow](#current-workflow)
- [Recommended Path](#recommended-path)
- [Detailed Procedures](#detailed-procedures)

---

## Destroy/Rebuild Options

### 1. Ansible (You Already Have It!)
**Best for:** Full infrastructure automation including OS-level setup

**Pros:**
- Handles everything from SSH keys to K3s to app deployment
- Idempotent and repeatable
- Version controlled playbooks

**Cons:**
- Need to maintain playbooks for each change
- Not real-time sync (manual runs)

**Current Status:** ✅ Partially implemented
- Have: `reset-k3s.yml`, `setup-k3s.yml`
- Need: Application deployment playbooks

---

### 2. GitOps with ArgoCD/Flux
**Best for:** Application-level automation (not cluster itself)

**How it works:**
- All YAML manifests stored in Git
- ArgoCD/Flux automatically syncs cluster state to Git
- Declarative: cluster always matches Git repo

**Pros:**
- Single source of truth in Git
- Automatic drift correction
- Audit trail via Git history
- Easy rollbacks

**Cons:**
- Requires initial setup
- Doesn't handle cluster creation
- Learning curve for GitOps concepts

**Current Status:** ⏳ On roadmap (see ROADMAP.md)

---

### 3. Helm Umbrella Chart
**Best for:** Deploying all apps as one unit

**How it works:**
```yaml
# Chart.yaml
dependencies:
  - name: kube-prometheus-stack
    repository: https://prometheus-community.github.io/helm-charts
  - name: loki
    repository: https://grafana.github.io/helm-charts
```

**Pros:**
- Simple version-controlled releases
- One command to install/uninstall all apps
- Built-in rollback

**Cons:**
- Limited to Helm-based apps
- Doesn't handle infrastructure (K3s, NFS)
- Complexity for mixed environments

**Current Status:** ❌ Not implemented

---

### 4. Shell Scripts (Quick & Dirty)
**Best for:** Rapid prototyping, simple homelabs

**Example:**
```bash
# deploy-all.sh
./k3s/nfs/deploy.sh
./k3s/monitoring/deploy.sh
./k3s/logging/deploy.sh
```

**Pros:**
- Simple, no learning curve
- Flexible and hackable
- Good for quick iterations

**Cons:**
- Not idempotent
- Brittle error handling
- Hard to maintain at scale

**Current Status:** ✅ Partially implemented (individual deploy.sh scripts)

---

### 5. Terraform + Helm Provider
**Best for:** Infrastructure as Code with state management

**How it works:**
```hcl
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
}
```

**Pros:**
- State management (knows what's deployed)
- Plan before apply (preview changes)
- Idempotent operations
- Supports multiple providers

**Cons:**
- Learning curve
- Overkill for single-cluster homelab
- State file management

**Current Status:** ❌ Not implemented

---

### 6. Velero Backup/Restore
**Best for:** Disaster recovery, not day-to-day rebuilds

**How it works:**
- Backup entire cluster state to S3/NFS
- Includes PVCs, secrets, configs
- Restore from backup point-in-time

**Pros:**
- Perfect for "oh no" moments
- Includes persistent data
- Scheduled backups

**Cons:**
- Not for config changes
- Requires backup storage
- Restoration takes time

**Current Status:** ⏳ On roadmap (see ROADMAP.md)

---

### 7. K3s Built-in Reset
**Best for:** Complete nuclear option

**Commands:**
```bash
# Server node
sudo /usr/local/bin/k3s-uninstall.sh

# Agent nodes
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
NOTE : 
To Actually Delete NAS Data for k3s
# SSH to Synology or use GUI
rm -rf /volume1/k3s-storage/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


**Pros:**
- Clean slate
- Simple and fast
- No leftover state

**Cons:**
- Loses everything
- Manual rebuild required
- No rollback

**Current Status:** ✅ Available (built into K3s)

---

## Current Workflow

### Destroy Procedure

**Option A: Selective (Keep cluster, remove apps)**
```bash
# Delete specific namespaces
kubectl delete namespace monitoring
kubectl delete namespace logging
kubectl delete namespace longhorn-system

# Or delete via Helm
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall loki -n logging
```

**Option B: Complete (Destroy everything)**
```bash
# 1. Run Ansible reset playbook
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/reset-k3s.yml

# 2. (Optional) Clean NFS data on Synology
# SSH to Synology or via GUI:
# Delete contents of /volume1/k3s-storage/*
```

### Build Procedure

**Step 1: Install K3s Cluster**
```bash
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/setup-k3s.yml
```

**Step 2: Setup Storage**
```bash
cd k3s/nfs
kubectl apply -f nfs-csi-driver.yaml
kubectl apply -f storageclass.yaml
```

**Step 3: Install cert-manager**
```bash
cd k3s/certs
bash install-cert-manager.sh
kubectl apply -f cluster-issuer.yaml
```

**Step 4: Deploy Monitoring Stack**
```bash
cd k3s/monitoring
bash deploy.sh
kubectl apply -f prometheus-rules.yaml
kubectl apply -f grafana-dashboard-configmap.yaml
kubectl apply -f ingress-tls.yaml
```

**Step 5: Deploy Logging Stack**
```bash
cd k3s/logging
bash deploy.sh
kubectl apply -f loki-datasource.yaml
```

**Step 6: Deploy Other Services**
```bash
# Longhorn
kubectl apply -f k3s/longhorn/longhorn-ingress.yaml

# Kubernetes Dashboard
kubectl apply -f k3s/nginx_ingress/dashboard-admin-user.yaml
kubectl apply -f k3s/nginx_ingress/dashboard-ingress.yaml
```

---

## Recommended Path

### Short-term (Now)
**Use Ansible for cluster, scripts for apps**

1. ✅ Use existing `reset-k3s.yml` and `setup-k3s.yml`
2. 🔨 Create `ansible/playbooks/deploy-all-apps.yml`:
   - Orchestrates all app deployments
   - Calls individual deploy.sh scripts
   - Handles dependencies (cert-manager before monitoring, etc.)
3. Keep individual `deploy.sh` scripts as building blocks

**Benefits:**
- Builds on what you have
- Low effort, high value
- Easy to understand and maintain

---

### Medium-term (Next 2-4 weeks)
**Implement GitOps with ArgoCD**

1. Install ArgoCD to cluster
2. Move all Kubernetes manifests to Git structure:
   ```
   k3s/
   ├── apps/
   │   ├── monitoring/
   │   ├── logging/
   │   └── storage/
   └── argocd/
       └── applications/
   ```
3. Create ArgoCD Application manifests
4. Let ArgoCD handle app deployment/updates
5. Still use Ansible for cluster creation/destruction

**Benefits:**
- Git as single source of truth
- Automatic sync and drift detection
- Easy rollbacks via Git
- Production-ready pattern

---

### Long-term (Production-ready)
**Full automation with backup**

1. **ArgoCD** for application management
2. **Ansible** for infrastructure provisioning
3. **Velero** for backup/restore
4. **Monitoring** for alerts on drift/failures
5. Document runbooks for common scenarios

**Benefits:**
- Resilient to failures
- Easy to replicate
- Audit trail for all changes
- Quick disaster recovery

---

## Detailed Procedures

### Create Ansible Deploy-All Playbook

```yaml
# ansible/playbooks/deploy-all-apps.yml
---
- name: Deploy all applications to K3s cluster
  hosts: k3s_masters
  gather_facts: no
  tasks:
    - name: Copy manifests to cluster
      copy:
        src: "{{ playbook_dir }}/../../k3s/"
        dest: "/home/{{ ansible_user }}/k3s/"
        
    - name: Deploy NFS StorageClass
      shell: |
        kubectl apply -f /home/{{ ansible_user }}/k3s/nfs/
      
    - name: Install cert-manager
      shell: |
        cd /home/{{ ansible_user }}/k3s/certs
        bash install-cert-manager.sh
        
    - name: Deploy monitoring stack
      shell: |
        cd /home/{{ ansible_user }}/k3s/monitoring
        bash deploy.sh
        kubectl apply -f prometheus-rules.yaml
        kubectl apply -f grafana-dashboard-configmap.yaml
        kubectl apply -f ingress-tls.yaml
        
    - name: Deploy logging stack
      shell: |
        cd /home/{{ ansible_user }}/k3s/logging
        bash deploy.sh
```

### Quick Reference Commands

**Check what's deployed:**
```bash
kubectl get all --all-namespaces
helm list --all-namespaces
kubectl get pvc --all-namespaces
```

**Backup before destroy:**
```bash
# Export all resources
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Export PVCs (data won't be backed up, just definitions)
kubectl get pvc --all-namespaces -o yaml > pvc-backup.yaml
```

**Monitor deployment:**
```bash
# Watch pods come up
watch kubectl get pods --all-namespaces

# Check for issues
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

---

## Integration with Existing Setup

### Files that support lifecycle management

**Ansible:**
- `ansible/playbooks/reset-k3s.yml` - Cluster destruction
- `ansible/playbooks/setup-k3s.yml` - Cluster creation
- `ansible/inventory/hosts.yml` - Node inventory
- `ansible/group_vars/all.yml` - Configuration

**K3s Manifests:**
- `k3s/*/deploy.sh` - Individual component deployment
- `k3s/nfs/storageclass.yaml` - Storage setup
- `k3s/certs/install-cert-manager.sh` - Certificate automation
- `k3s/monitoring/prometheus-values.yaml` - Monitoring config
- `k3s/logging/loki-values.yaml` - Logging config

**Documentation:**
- `docs/ROADMAP.md` - Future plans (ArgoCD, Velero)
- `README.md` - Project overview

---

## Next Steps

1. **Immediate:** Test current destroy/rebuild workflow
2. **This week:** Create Ansible deploy-all playbook
3. **Next sprint:** Implement ArgoCD (see ROADMAP.md)
4. **Future:** Add Velero for backup/restore

---

## Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Ansible K3s Role](https://github.com/PyratLabs/ansible-role-k3s)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Velero Documentation](https://velero.io/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
