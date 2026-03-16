# K3s Homelab - Next Steps & Roadmap

## ✅ Completed
- [x] K3s cluster setup (Raspberry Pi x3, single master)
- [x] Longhorn storage (distributed)
- [x] NFS storage (Synology)
- [x] MetalLB load balancer
- [x] NGINX Ingress controller
- [x] Kubernetes Dashboard
- [x] Prometheus monitoring stack
- [x] Grafana dashboards
- [x] cert-manager with self-signed CA
- [x] TLS/SSL for all services
- [x] ArgoCD GitOps (deployed with Helm, demo app running)
- [x] Centralized Logging (Loki + Promtail)
- [x] Sealed Secrets (controller deployed, kubeseal installed, keys backed up & vault-encrypted)
- [x] Velero + MinIO backup/restore (BSL available, smoke backup + restore validated, daily schedule in place)
- [x] GitHub Actions self-hosted runner (deployed in cluster)
- [x] ArgoCD app-of-apps bootstrap (new apps in `k3s/argocd/apps` auto-registered)

## 🎯 Priority Queue

### 0. Deploy real apps via ArgoCD (NOW)
**Why:** You have the platform foundation done; now validate it with real workloads.
**Complexity:** Medium
**Time:** 1-2 weekends

**Recommended order:**
1. Uptime Kuma (simple, immediate value, alerting)
2. Gitea (stateful app + ingress + persistence + backups)
3. Immich or Nextcloud (heavier app, storage + performance tuning)

**Success criteria:**
- App has namespace, ingress, PVC, resource requests/limits
- Secrets are managed with Sealed Secrets
- App has backup policy (Velero scope + restore test)
- App has dashboard + basic alert in Grafana/Prometheus

### 1. ~~GitOps with ArgoCD~~ ✅ COMPLETED
**Status:** Helm-deployed ArgoCD, app-of-apps bootstrap, demo app and platform apps managed from Git.

### 2. ~~Centralized Logging (Loki + Promtail)~~ ✅ COMPLETED
**Status:** Logs aggregated and visible in Grafana.

### 3. ~~Backup & Disaster Recovery (Velero)~~ ✅ COMPLETED
**Status:** Velero running with MinIO backend, daily schedule configured, smoke backup/restore validated.

### 4. Secrets hardening (next refinement)
**Rule:** Sealed Secrets for app/runtime secrets, Ansible Vault for infra/bootstrap secrets.
**Optional next step:** Evaluate External Secrets Operator + Vault once current setup feels routine.

---

## 🔒 Security & Access

### 4. SSO/Authentication (Authelia)
**Why:** Centralized login, 2FA, better security
**Complexity:** Medium-High
**Time:** 3-4 hours

**What you'll learn:**
- OAuth2/OpenID Connect
- Single Sign-On (SSO)
- Two-factor authentication
- LDAP integration (optional)

**Protects:**
- All ingress services
- Grafana, Longhorn, Dashboard, etc.

---

### 5. External Access (Tailscale)
**Why:** Secure remote access without port forwarding
**Complexity:** Low
**Time:** 1 hour

**What you'll learn:**
- WireGuard VPN
- Zero-trust networking
- Mesh networking

**Benefits:**
- Access homelab from anywhere
- No exposed ports
- Encrypted tunnel

---

### 6. ~~Secret Management (Sealed Secrets)~~ ✅ COMPLETED
**Status:** Sealed Secrets controller deployed in `kube-system`, kubeseal CLI installed on cluster nodes, controller TLS keypair backed up locally and encrypted in Ansible Vault.
**What you learned:**
- Encrypted secrets safe for Git commits
- Sealed Secrets controller and kubeseal workflow
- Key backup and disaster recovery for secrets
- Ansible Vault for encrypting sensitive backup files

**Next:** External Secrets Operator (ESO) + Vault if you need dynamic secret rotation, or skip to Authelia/Tailscale

---

## 📦 Infrastructure

### 7. Private Container Registry (Harbor)
**Why:** Store private images, scan vulnerabilities
**Complexity:** Medium
**Time:** 2-3 hours

**What you'll learn:**
- Container registry
- Image scanning
- RBAC for images
- Image replication

**Resources needed:**
- 20GB+ NFS storage
- PostgreSQL (or use NFS)

---

### 8. Database Operator (CloudNativePG or Zalando Postgres)
**Why:** Run production-grade databases in K8s
**Complexity:** Medium-High
**Time:** 2-4 hours

**What you'll learn:**
- StatefulSets for databases
- Database operators
- Automated backups
- High availability databases

**Use cases:**
- Applications needing databases
- Learn DB management in K8s

---

## 🚀 CI/CD & Automation

### 9. ~~GitHub Actions Self-Hosted Runner~~ ✅ COMPLETED
**Why:** Build and test in your own cluster
**Complexity:** Low-Medium
**Time:** 1-2 hours

**What you'll learn:**
- CI/CD pipelines
- Self-hosted runners
- Container building
- Automated testing

**Benefits:**
- Free CI/CD minutes
- Full control over build environment
- Faster builds (local network)
- **Status:** Runner deployed and registered; credentials managed via Sealed Secrets workflow.

---

### 10. Tekton Pipelines
**Why:** Kubernetes-native CI/CD
**Complexity:** High
**Time:** 4-6 hours

**What you'll learn:**
- Cloud-native CI/CD
- Pipeline as Code
- Tekton triggers
- Advanced K8s patterns

**When:** After mastering GitOps/ArgoCD

---

## 🎮 Fun Projects

### 11. Media Server Stack
**Why:** Leverage NAS storage, learn complex deployments
**Complexity:** Medium
**Time:** 3-5 hours

**Components:**
- Plex or Jellyfin (media server)
- Radarr (movies)
- Sonarr (TV shows)
- Prowlarr (indexer)
- qBittorrent or Transmission

**Storage:** All on NFS (Synology)

---

### 12. Home Assistant on K8s
**Why:** Smart home automation, learn IoT + K8s
**Complexity:** Medium
**Time:** 2-3 hours

**What you'll learn:**
- IoT integration
- StatefulSet deployments
- USB device passthrough

---

### 13. Game Server Hosting
**Why:** Learn about game server management
**Complexity:** Low-Medium
**Time:** 1-2 hours

**Options:**
- Minecraft server
- Valheim server
- Terraria server

**What you'll learn:**
- Persistent game states
- Network configuration
- Resource management

---

## 📚 Learning & Observability

### 14. Distributed Tracing (Jaeger/Tempo)
**Why:** Complete observability (metrics, logs, traces)
**Complexity:** High
**Time:** 3-4 hours

**What you'll learn:**
- Distributed tracing
- Service mesh concepts
- Request flow visualization

**When:** After Loki is set up

---

### 15. Service Mesh (Linkerd or Istio)
**Why:** Advanced traffic management, security, observability
**Complexity:** Very High
**Time:** 6-10 hours

**What you'll learn:**
- mTLS between services
- Traffic splitting
- Advanced routing
- Circuit breakers

**When:** When you have many microservices

---

## 🏗️ Infrastructure as Code

### 16. Terraform for K8s Resources
**Why:** Manage infrastructure as code
**Complexity:** Medium
**Time:** 2-3 hours

**What you'll learn:**
- IaC principles
- Terraform providers
- State management

---

### 17. Policy Management (OPA Gatekeeper)
**Why:** Enforce cluster policies, prevent misconfigurations
**Complexity:** Medium-High
**Time:** 2-3 hours

**What you'll learn:**
- Policy as Code
- Admission controllers
- Compliance enforcement

**Examples:**
- Require resource limits
- Block privileged pods
- Enforce naming conventions

---

## 🔧 Advanced Topics

### 18. Multi-Cluster Management
**Why:** Learn cluster federation
**Complexity:** Very High
**Time:** 8-10 hours

**When:** When you have multiple clusters (Pi + cloud)

---

### 19. Cost Management (Kubecost)
**Why:** Understand resource costs
**Complexity:** Low
**Time:** 1 hour

**What you'll learn:**
- Resource allocation tracking
- Cost optimization
- Capacity planning

---

### 20. Chaos Engineering (Chaos Mesh)
**Why:** Test cluster resilience
**Complexity:** High
**Time:** 3-4 hours

**What you'll learn:**
- Fault injection
- Resilience testing
- Disaster scenarios

**When:** When cluster is mature and stable

---

## 📋 Recommended Learning Path

### Phase 1: DevOps Fundamentals ✅ COMPLETE
1. ✅ GitOps with ArgoCD
2. ✅ Centralized Logging (Loki + Promtail)
3. ✅ Secret Management (Sealed Secrets)

### Phase 2: Security & Access ✅ COMPLETE
4. ✅ Backup & Disaster Recovery (Velero)
5. ⬜ External Access (Tailscale)
6. ⬜ SSO/Authentication (Authelia)

### Phase 3: App Platform Buildout (Current)
7. ⬜ Deploy 2-3 real apps via ArgoCD (with PVC + ingress + alerts)
8. ✅ CI/CD Pipeline baseline (GitHub Actions Runner)
9. ⬜ Database Operator (CloudNativePG)

### Phase 4: Production-Grade (Month 3+)
10. ⬜ Distributed Tracing (Jaeger/Tempo)
11. ⬜ Policy Management (OPA Gatekeeper)
12. ⬜ Service Mesh (Linkerd - when needed)

### Side Projects (Anytime)
- Media Server Stack
- Home Assistant
- Game Servers

---

## 🎓 Learning Resources

### Books
- "Kubernetes Patterns" by Bilgin Ibryam
- "Production Kubernetes" by Josh Rosso et al.

### Online
- ArgoCD documentation: https://argo-cd.readthedocs.io/
- Grafana Loki: https://grafana.com/docs/loki/
- CNCF Landscape: https://landscape.cncf.io/

### Practice
- Killer.sh CKA/CKAD practice
- Kubernetes the Hard Way (for deep understanding)

---

## 💡 Quick Wins (Low effort, high value)

1. **k9s** - Terminal UI for K8s (30 min)
2. **Kubectx/Kubens** - Context/namespace switching (15 min)
3. **Kustomize** - Better YAML management (1 hour)
4. **Helm Diff plugin** - Preview changes (15 min)
5. **Stern** - Multi-pod log tailing (15 min)

---

## 📝 Notes

- **Resource limits:** Raspberry Pi has limited resources, be selective
- **Start small:** Master basics before advanced topics
- **Document everything:** Keep this file updated with your progress

---

**Last Updated:** March 7, 2026
**Current Focus:** Deploy real apps on top of the platform (ArgoCD + Sealed Secrets + Velero-backed recovery)
