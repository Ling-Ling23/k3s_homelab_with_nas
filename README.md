# k3s Homelab with NAS

A complete infrastructure-as-code setup for running a k3s Kubernetes cluster on Raspberry Pis, managed from your laptop.

## Overview

This homelab setup allows you to:
- Deploy and manage a k3s cluster on Raspberry Pis (scalable from 1 to 3+ nodes)
- Configure everything via Ansible from your laptop
- Deploy applications to your cluster

## Current Status

- **Raspberry Pis**: 1 (expandable to 3)
- **k3s Version**: v1.28.5+k3s1
- **Management**: Ansible playbooks

## Quick Start

### 1. Prerequisites

- Ansible installed on your laptop: `pip install ansible`
- SSH key access to your Raspberry Pi(s)
- Raspberry Pi OS 64-bit installed

### 2. Configure

1. Update `ansible/inventory/hosts.yml` with your Pi IP address(es)
2. Change the token in `ansible/group_vars/all.yml`
3. Set up SSH key auth: `ssh-copy-id pi@YOUR_PI_IP`

### 3. Deploy

```bash
cd ansible
ansible-playbook playbooks/setup-k3s.yml
```

### 4. Access Your Cluster

```bash
export KUBECONFIG=~/.kube/k3s-homelab-config
kubectl get nodes
```

## Documentation

See [ansible/README.md](ansible/README.md) for detailed instructions.

## Structure

```
├── ansible/                    # Ansible playbooks and configuration
│   ├── inventory/             # Host definitions
│   ├── group_vars/            # Configuration variables
│   ├── playbooks/             # Ansible playbooks
│   └── README.md              # Detailed Ansible documentation
└── README.md                  # This file
```

## Roadmap

- [x] Ansible setup for k3s deployment
- [ ] Storage configuration (NAS integration)
- [ ] Ingress controller setup (MetalLB + nginx)
- [ ] GitOps with ArgoCD
- [ ] Monitoring stack (Prometheus + Grafana)
- [ ] Backup strategy
