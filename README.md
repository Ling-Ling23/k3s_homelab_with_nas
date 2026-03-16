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

## Automation model

- **Primary deployment method:** Ansible
- **Infrastructure deployment:** `ansible/playbooks/*.yml`
- **Platform orchestration:** `ansible/playbooks/master-deploy-k3s.yml`
- **App delivery:** ArgoCD applications under `k3s/argocd/apps/`

This means cluster setup and platform services are automated with Ansible, while ongoing app sync/deploy is handled by ArgoCD.

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
	$METALLB_IP dashboard.homelab.local longhorn.homelab.local grafana.homelab.local prometheus.homelab.local alertmanager.homelab.local argocd.home.local demo.home.local home-assistant.homelab.local

### 2) Configure inventory and vars

1. Update host IPs/users in `ansible/inventory/hosts.yml`
2. Set cluster/global variables in `ansible/group_vars/all.yml`
3. Ensure SSH keys are configured for Ansible access

### 3) Deploy with Ansible

```bash
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/master-deploy-k3s.yml
```

### 4) Verify cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Repository layout

```text
ansible/                  # Infrastructure and platform automation
	inventory/              # Node inventory
	group_vars/             # Shared variables
	playbooks/              # Deployment/reset playbooks
k3s/                      # Kubernetes manifests, Helm values, component configs
	argocd/                 # ArgoCD config, apps, sample workloads
	monitoring/             # Prometheus/Grafana configs
	logging/                # Loki/Promtail configs
	sealed-secrets/         # Sealed Secrets configs
docs/                     # Roadmap, deployment notes, infrastructure lifecycle
scripts/                  # Destroy/reset helper scripts
```

## Documentation

- Main Ansible guide: [ansible/README.md](ansible/README.md)
- Deployment notes: [docs/steps_deployment.md](docs/steps_deployment.md)
- Roadmap and progress: [docs/ROADMAP.md](docs/ROADMAP.md)
- Lifecycle/operations notes: [docs/infrastructure-lifecycle.md](docs/infrastructure-lifecycle.md)
