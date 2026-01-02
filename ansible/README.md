# k3s Homelab Ansible Setup

This Ansible setup will configure and deploy a k3s Kubernetes cluster on your Raspberry Pis.

## Prerequisites

1. **Raspberry Pi Setup**:
   - Raspberry Pi OS (64-bit recommended)
   - SSH enabled
   - Static IP addresses configured
   - SSH key authentication set up

2. **On Your Laptop**:
   - Ansible installed: `pip install ansible`
   - SSH access to your Raspberry Pis

## Initial Configuration

### 1. Update Inventory

Edit `inventory/hosts.yml` and update:
- IP addresses for your Raspberry Pi(s)
- Uncomment worker nodes when you add more Pis

### 2. Update Variables

Edit `group_vars/all.yml`:
- Change `k3s_token` to a strong random token
- Update `timezone` to your location
- Adjust `k3s_server_ip` if needed

### 3. Set Up SSH Key Authentication

From your laptop:
```bash
ssh-copy-id pi@192.168.1.100  # Replace with your Pi's IP
```

Test connection:
```bash
ssh pi@192.168.1.100
```

## Usage

### Deploy k3s Cluster

From the `ansible` directory:

```bash
# Test connection to all hosts
ansible all -m ping

# Deploy the cluster (takes ~10-15 minutes)
ansible-playbook playbooks/setup-k3s.yml

# Check cluster status
ansible-playbook playbooks/check-cluster.yml
```

### Access Your Cluster

The kubeconfig file is automatically downloaded to `~/.kube/k3s-homelab-config`

Use it with kubectl:
```bash
# Set environment variable
export KUBECONFIG=~/.kube/k3s-homelab-config

# Or use --kubeconfig flag
kubectl --kubeconfig ~/.kube/k3s-homelab-config get nodes

# Check cluster
kubectl get nodes
kubectl get pods -A
```

### Add Worker Nodes

When you get more Raspberry Pis:

1. Update `inventory/hosts.yml` - uncomment and configure worker nodes
2. Run the playbook again:
   ```bash
   ansible-playbook playbooks/setup-k3s.yml
   ```

### Reset Cluster

To completely remove k3s and start fresh:
```bash
ansible-playbook playbooks/reset-k3s.yml
```

## Playbooks

- **setup-k3s.yml**: Full cluster installation
  - Prepares all nodes (updates, packages, cgroups)
  - Installs k3s master
  - Installs k3s workers
  - Downloads kubeconfig to your laptop

- **check-cluster.yml**: Verify cluster status
  - Shows nodes, pods, and cluster info

- **reset-k3s.yml**: Remove k3s completely
  - Uninstalls k3s from all nodes
  - Cleans up configuration files

## Customization

### Disable Traefik and ServiceLB

By default, Traefik ingress controller and ServiceLB are disabled (configured in `group_vars/all.yml`).

You can install alternatives:
- **Ingress**: nginx-ingress, Traefik via Helm
- **LoadBalancer**: MetalLB, kube-vip

### Change k3s Version

Update `k3s_version` in `group_vars/all.yml` then re-run the setup playbook.

### Master Node Options

Modify `k3s_master_extra_args` in `group_vars/all.yml` to add more k3s server options.

## Troubleshooting

### Connection Issues
```bash
# Test connectivity
ansible all -m ping

# Check SSH manually
ssh pi@192.168.1.100
```

### k3s Not Starting
```bash
# Check logs on the Pi
ssh pi@192.168.1.100
sudo journalctl -u k3s -f
```

### Reboot Required
After the first run, the Pis may need a reboot for cgroup changes:
```bash
ansible k3s_cluster -m reboot -b
```

## Next Steps

1. Deploy ingress controller (MetalLB + nginx)
2. Set up storage (NFS, Longhorn)
3. Deploy applications via kubectl/Helm
4. Set up GitOps with ArgoCD/Flux

## Useful Commands

```bash
# Run specific tags
ansible-playbook playbooks/setup-k3s.yml --tags preparation

# Run only on master
ansible-playbook playbooks/setup-k3s.yml --limit master

# Dry run (check mode)
ansible-playbook playbooks/setup-k3s.yml --check

# Verbose output
ansible-playbook playbooks/setup-k3s.yml -vv
```
