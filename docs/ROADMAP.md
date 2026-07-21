# K3s Homelab - Next Steps & Roadmap

## ✅ Completed
- [x] K3s cluster setup (Raspberry Pi x3, single master)
- [x] Longhorn storage (distributed block storage)
- [x] NFS storage (Synology CSI driver)
- [x] MetalLB load balancer
- [x] NGINX Ingress controller
- [x] Kubernetes Dashboard
- [x] Prometheus + Grafana monitoring stack
- [x] cert-manager with self-signed CA
- [x] TLS/SSL for all ingress services
- [x] ArgoCD GitOps (Helm-deployed, app-of-apps bootstrap)
- [x] Centralized logging (Loki + Promtail + canary probes)
- [x] Sealed Secrets (controller, kubeseal, keys backed up & vault-encrypted)
- [x] Velero + MinIO backup/restore (daily schedule, smoke restore validated)
- [x] GitHub Actions self-hosted runner (deployed; ⚠️ currently CrashLoopBackOff — needs token rotation)
- [x] ArgoCD app-of-apps bootstrap (new apps in `k3s/argocd/apps` auto-registered)
- [x] Dashy dashboard
- [x] Joplin (deployed via Syn Nas)
- [x] Home Assistant (StatefulSet on k3s)
- [x] ResourceQuota + LimitRange per namespace (all active namespaces)

## 🔥 Immediate Fixes

### Fix: github-runner CrashLoopBackOff
**Why:** 6601 restarts over 74 days — the runner registration token has almost certainly expired. GitHub registration tokens are single-use and short-lived; they cannot be reused after the initial runner registration.
**Fix:**
1. Go to GitHub → repo Settings → Actions → Runners → New self-hosted runner → copy the token
2. Re-seal the secret locally: `kubectl create secret generic github-runner-secret --dry-run=client -o yaml | kubeseal`
3. Replace `sealed-secret.yaml` in `k3s/argocd/projects/infra/github-runner/` and push to Git
4. ArgoCD will sync and restart the pod

---

## 🎯 Next Up

### 0. Tailscale so my Joplin can sync over the internet

### 1. Calico CNI (replace Flannel)
**Why:** K3s ships with Flannel which silently ignores `NetworkPolicy` resources. Calico is the most battle-tested CNI plugin and enables real pod-level network segmentation — a core production security primitive.
**Complexity:** High (cluster-level change, brief downtime)
**Time:** 2-4 hours

**Migration plan:**
1. Take a full Velero backup first
2. On all nodes: reinstall K3s with `--flannel-backend=none --disable-network-policy`
3. Deploy Calico via `tigera-operator` Helm chart with ARM64 image overrides
4. Apply `Installation` CR with `calicoNetwork.ipPools` matching your existing pod CIDR
5. Validate: pod networking, DNS (CoreDNS), Ingress, Longhorn cross-node replication

**What you unlock:**
- `NetworkPolicy` resources are actually enforced
- `GlobalNetworkPolicy` for cluster-wide default-deny rules
- BGP routing mode (optional, educational)
- Calico `NetworkSet` for IP-based policies

**Caveats:**
- k3s's embedded network policy controller must be disabled (`--disable-network-policy`)
- Longhorn uses cross-node replication — test carefully after CNI switch
- Use `tigera-operator` Helm chart; some chart versions ship AMD64-only image defaults — override in values for ARM64

---

### 2. Network Policies (after Calico)
**Why:** Once Calico is in place, enforce zero-trust between namespaces. Currently any pod can reach any other pod in the cluster.
**Complexity:** Medium
**Time:** 2-3 hours

**Policies to start with:**
- Default-deny ingress per namespace
- Allow `ingress-nginx` → app pods only
- Allow `monitoring` namespace → scrape targets (port 9090, 9100, etc.)
- Allow `logging` namespace → Loki ingest only
- Isolate `github-runner` — no egress except GitHub API

**Where to put them:** add `networkpolicy.yaml` alongside each app's existing files in `k3s/argocd/projects/`

---

### 3. Uptime Kuma
**Why:** Lightweight status monitoring for every ingress endpoint. Fires alerts when a service goes down — immediate practical value.
**Complexity:** Low
**Time:** 1-2 hours

**What you get:**
- HTTP / TCP / ping checks for all your services
- Telegram / Slack / email alert channels
- Status page (internal or public)

**Pattern:** Same ArgoCD layout as Dashy — Namespace, Deployment, PVC (Longhorn), Ingress, Sealed Secret for admin password, Velero label.


---

### 5. Authelia (SSO / 2FA)
**Why:** Centralised authentication in front of all internal ingresses — removes per-app passwords and adds 2FA.
**Complexity:** Medium-High
**Time:** 3-5 hours

**What you'll learn:**
- OAuth2 / OpenID Connect flows
- `nginx.ingress.kubernetes.io/auth-url` annotation pattern (forward-auth)
- TOTP 2FA
- Session storage with Redis

**Protects:** Grafana, Dashy, Trilium, Longhorn UI, Kubernetes Dashboard, ArgoCD

---

### 6. Tailscale (remote access)
**Why:** Access the homelab from anywhere without opening firewall ports.
**Complexity:** Low
**Time:** 1 hour

**Options:**
- Tailscale sidecar in k3s as a subnet router (exposes whole cluster CIDR)
- Tailscale directly on the Pi OS (simpler, outside k3s)

**What you'll learn:**
- WireGuard / zero-trust mesh networking
- Split-DNS for `.homelab.local` on remote devices
- ACL rules on the Tailscale admin console

---

## 📦 Platform Improvements

### 7. CloudNativePG (Postgres Operator)
**Why:** Gitea, and Immich all need Postgres. Running it properly in k3s teaches operator patterns, StatefulSet lifecycle, and backup integration.
**Complexity:** Medium-High
**Time:** 2-4 hours

**What you'll learn:**
- Kubernetes operators and CRDs
- Streaming replication
- CNPG Barman cloud backup → MinIO (same bucket as Velero)
- PgBouncer connection pooling

---

### 8. Kyverno (Policy Engine)
**Why:** Lightweight admission controller. Enforces cluster hygiene rules as code — pairs well with the ResourceQuotas already in place. Simpler than OPA Gatekeeper for homelab use.
**Complexity:** Medium
**Time:** 2-3 hours

**Starter policies:**
- Require `resources.requests` + `resources.limits` on all containers
- Disallow `image:latest` tags
- Require `app` label on all Deployments
- Disallow `hostPath` volumes outside `kube-system`
- Auto-add default labels via mutating policy

---

### 9. RBAC Hardening
**Why:** Everything currently runs under default service accounts. Adding per-app RBAC teaches a core k8s security concept and is a CKA/CKAD exam topic.
**Complexity:** Medium
**Time:** 2-3 hours

**What to do:**
- Create least-privilege `ServiceAccount` + `Role` / `RoleBinding` per app
- Audit with `kubectl auth can-i --list --as system:serviceaccount:<ns>:<sa>`
- Restrict ArgoCD's service account scope to only its managed namespaces

---

## 🚀 Apps to Deploy

### 10. Gitea (self-hosted Git)
**Why:** Stateful app with Postgres, ingress, TLS, PVC, SSH, and webhooks. Good all-round complexity test for the platform. Can trigger ArgoCD deploys via webhook.
**Complexity:** Medium
**Time:** 2-4 hours

**Requires:** CloudNativePG (or SQLite to start), Ingress (HTTP + SSH port via MetalLB), Sealed Secret for admin, Velero backup scope

---

### 11. Immich (photo backup)
**Why:** Uses NFS heavily, has a machine-learning worker (stress-tests ARM64 CPU limits), and needs Postgres + Redis. Real-world load test for the cluster.
**Complexity:** Medium-High
**Time:** 3-5 hours

**Requires:** CloudNativePG, Redis, large NFS PVC. The `machine-learning` microservice is optional — disable it initially on Pi to save memory.

---

---

## 🔬 Advanced / Learning

### 13. Grafana Tempo (Distributed Tracing)
**Why:** Completes the observability trio — metrics (Prometheus), logs (Loki), traces (Tempo). All three integrate natively in Grafana with exemplar linking.
**Complexity:** Medium
**Time:** 2-3 hours

**When:** Once you have 2+ real apps running and want to trace requests across services.

---

### 14. Harbor (Private Container Registry)
**Why:** Store and scan your own container images. Pairs naturally with the GitHub Actions runner for end-to-end build → push → deploy pipelines.
**Complexity:** Medium
**Time:** 2-3 hours

**Requires:** PostgreSQL, Redis, 20GB+ NFS storage. ARM64 images available.

---

### 15. Tekton Pipelines
**Why:** Kubernetes-native CI/CD alternative to GitHub Actions. Fully in-cluster, no external connectivity needed.
**Complexity:** High
**Time:** 4-6 hours

**When:** After Harbor is deployed and you want to build + push images without leaving the cluster.

---

### 16. Chaos Mesh
**Why:** Inject pod failures, network delays, and node CPU pressure to validate cluster resilience and alert thresholds.
**Complexity:** High
**Time:** 3-4 hours

**When:** After Authelia, CloudNativePG, and at least one stateful app are stable.

---

### 17. Kubecost (Resource Cost Visibility)
**Why:** Low effort. Shows CPU/memory cost per namespace — useful for right-sizing the ResourceQuotas now in place.
**Complexity:** Low
**Time:** 1 hour

---

### 18. Service Mesh (Linkerd)
**Why:** mTLS between all pods, traffic splitting, retries, circuit breakers.
**Complexity:** Very High
**Time:** 6-10 hours

**When:** When you have several microservices and want to go beyond Network Policies for east-west security.

---

## 📋 Recommended Learning Path

### Phase 1: Platform Foundation ✅ COMPLETE
K3s, storage (Longhorn + NFS), MetalLB, NGINX, cert-manager, ArgoCD, Loki, Sealed Secrets, Velero, GitHub runner, Dashy, Trilium, Home Assistant, ResourceQuotas

### Phase 2: Platform Hardening (Current)
1. ✅ ResourceQuota + LimitRange
2. ⬜ Fix github-runner token
3. ⬜ Calico CNI migration
4. ⬜ Network Policies
5. ⬜ Kyverno policies
6. ⬜ RBAC hardening

### Phase 3: Real Apps
7. ⬜ Uptime Kuma
9. ⬜ CloudNativePG
10. ⬜ Gitea
11. ⬜ Immich or Nextcloud

### Phase 4: Security & Access
12. ⬜ Authelia SSO
13. ⬜ Tailscale

### Phase 5: Observability & Advanced
14. ⬜ Grafana Tempo
15. ⬜ Harbor registry
16. ⬜ Chaos Mesh

### Side Projects (Anytime)
- Jellyfin / media stack
- Game servers (Minecraft etc.)

---

## 🎓 Learning Resources

### Books
- "Kubernetes Patterns" — Bilgin Ibryam
- "Production Kubernetes" — Josh Rosso et al.

### Online
- Calico docs: https://docs.tigera.io/calico/latest/
- ArgoCD docs: https://argo-cd.readthedocs.io/
- CNPG docs: https://cloudnative-pg.io/documentation/
- Kyverno policies: https://kyverno.io/policies/
- CNCF Landscape: https://landscape.cncf.io/

### Practice
- Killer.sh CKA/CKAD simulator
- Kubernetes the Hard Way (deep understanding)

---

## 💡 Quick Wins (Low effort, high value)

1. **k9s** — Terminal UI for k8s (30 min)
2. **kubectx / kubens** — Fast context and namespace switching (15 min)
3. **Stern** — Multi-pod log tailing (15 min)
4. **Helm Diff plugin** — Preview chart changes before ArgoCD sync (15 min)
5. **Kustomize** — Overlay-based YAML management, no Helm needed (1 hour)

---

## 📝 Notes

- **Calico on ARM64:** use `tigera-operator` Helm chart; some chart versions default to AMD64-only images — override `node.image` and `cni.image` in values for ARM64
- **github-runner CrashLoopBackOff:** GitHub registration tokens are single-use; rotate via GitHub UI → re-seal → push to Git
- **Resource limits:** all active namespaces now have `ResourceQuota` + `LimitRange`; tune values after deploying new apps using `kubectl describe resourcequota -n <ns>`
- **Home Assistant → Prometheus:** HA requires a long-lived token to expose `/api/prometheus` — see [HA Prometheus integration](https://www.home-assistant.io/integrations/prometheus/)
- **Velero before Calico:** always take a full backup before CNI changes

---

**Last Updated:** May 29, 2026
**Current Focus:** Platform hardening (fix runner, Calico CNI, Network Policies) → real apps (Uptime Kuma, Gitea)
