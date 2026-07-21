# K3s Homelab with NAS

Production-style homelab for Raspberry Pi using K3s, managed as infrastructure-as-code with Ansible and GitOps.

## What this repository does

- Provisions and manages a K3s cluster on Raspberry Pi nodes
- Uses Ansible playbooks for repeatable cluster and platform deployment
- Runs core platform services (storage, ingress, certs, monitoring, logging, secrets)
- Uses ArgoCD for GitOps application delivery

## Current deployed stack

- K3s cluster on Raspberry Pi
- Longhorn distributed storage
- NFS storage integration (Synology NAS)
- MetalLB load balancer
- NGINX Ingress Controller
- cert-manager with internal/self-signed CA
- Kubernetes Dashboard
- Prometheus + Grafana monitoring
- Loki + Promtail logging
- Sealed Secrets (with key backup + vault encryption workflow)
- ArgoCD (GitOps) with sample app
- GitHub Actions self-hosted runner (in-cluster)
- Joplin NAS data backup CronJob (NFS → GitHub, daily)

## Automation model

- **Cluster + platform bootstrap:** Ansible (`iac_deployments/ansible/playbooks/`)
- **Platform orchestration:** `iac_deployments/ansible/playbooks/master-deploy-k3s.yml`
- **App delivery + ongoing sync:** ArgoCD (app-of-apps pattern under `k3s/argocd/apps/`)

Ansible handles one-time cluster setup and core platform services (K3s, Longhorn, cert-manager, MetalLB, Sealed Secrets, ArgoCD). Once ArgoCD is bootstrapped, monitoring, logging, and all other applications are managed via GitOps.

## Important note: GitHub runner requires manual registration

Most of the infrastructure is automated with Ansible, but the GitHub Actions self-hosted runner needs a manual bootstrap step.

- Generate a runner registration token in your GitHub repository (`Settings -> Actions -> Runners`)
- Create/update the runner secret and seal it with Sealed Secrets
- Apply the sealed secret and restart the runner pod/deployment

This is expected because runner registration tokens are short-lived and repository-specific.

## Quick start

### 1) Prerequisites

- Python + Ansible on your control machine
- SSH connectivity to Raspberry Pi node(s)
- Raspberry Pi OS 64-bit on nodes
- Update system hosts file with:
	$METALLB_IP dashboard.homelab.local longhorn.homelab.local grafana.homelab.local prometheus.homelab.local alertmanager.homelab.local argocd.homelab.local demo.homelab.local home-assistant.homelab.local

### 2) Configure inventory and vars

1. Update host IPs/users in `iac_deployments/ansible/inventory/hosts.yml`
2. Set cluster/global variables in `iac_deployments/ansible/group_vars/all.yml`
3. Ensure SSH keys are configured for Ansible access

### 3) Deploy with Ansible

```bash
cd iac_deployments/ansible
ansible-playbook -i inventory/hosts.yml playbooks/master-deploy-k3s.yml
```

### 4) Verify cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Repository layout

```text
iac_deployments/
	ansible/                # Infrastructure and platform automation
		inventory/            # Node inventory
		group_vars/           # Shared variables
		playbooks/            # Deployment/reset playbooks
k3s/
	infra/                  # Helm values + manifests for platform services
		certs/                # cert-manager config
		longhorn/             # Longhorn storage config
		metallb/              # MetalLB config
		nfs/                  # NFS storage config
		sealed-secrets/       # Sealed Secrets config
	argocd/                 # ArgoCD bootstrap and app definitions
		app-of-apps.yaml      # Root bootstrap Application (apply once manually)
		apps/                 # ArgoCD Application CRDs (one per app)
		argocd/               # ArgoCD self-managed config (AppProjects)
		projects/             # Helm values for ArgoCD-managed apps
			infra/            # monitoring/, logging/, joplin-backup/ values
			personal/         # dashy/, trilium/ values
docs/                     # Roadmap, deployment notes, infrastructure lifecycle
```

## Documentation

- Main Ansible guide: [iac_deployments/ansible/README.md](iac_deployments/ansible/README.md)
- Roadmap and progress: [docs/ROADMAP.md](docs/ROADMAP.md)
- Lifecycle/operations notes: [docs/infra/infrastructure-lifecycle.md](docs/infra/infrastructure-lifecycle.md)
