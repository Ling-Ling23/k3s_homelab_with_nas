# SSL/TLS Certificates Setup

## Overview
Using cert-manager to automatically generate and manage self-signed certificates for homelab.

## Setup Steps

### 1. Install cert-manager
```bash
cd k3s/certs
bash install-cert-manager.sh
```

### 2. Create ClusterIssuer (CA)
```bash
kubectl apply -f cluster-issuer.yaml
```

Verify:
```bash
kubectl get clusterissuer
kubectl get certificate -n cert-manager homelab-ca
```

### 3. Apply TLS ingresses

**For monitoring stack:**
```bash
kubectl apply -f k3s/monitoring/ingress-tls.yaml
```

**For all services (dashboard, longhorn, etc):**
```bash
kubectl apply -f k3s/certs/ingress-tls-all.yaml
```

### 4. Verify certificates
```bash
kubectl get certificate -A
kubectl get ingress -A
```

## Access with HTTPS

All services now use HTTPS:
- https://grafana.homelab.local
- https://prometheus.homelab.local
- https://alertmanager.homelab.local
- https://dashboard.homelab.local
- https://longhorn.homelab.local

**Note:** Browsers will show "Not Secure" warning because it's self-signed. This is normal for homelab.

## Trust the CA (Optional)

To remove browser warnings, trust the homelab CA certificate on your devices.

### Export CA certificate
```bash
kubectl get secret homelab-ca-secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d > homelab-ca.crt
```

### Windows
1. Double-click `homelab-ca.crt`
2. Install Certificate → Local Machine
3. Place in "Trusted Root Certification Authorities"

### Linux
```bash
sudo cp homelab-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### macOS
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain homelab-ca.crt
```

## How It Works

1. **cert-manager** watches Ingress resources with `cert-manager.io/cluster-issuer` annotation
2. Automatically creates Certificate resource
3. Generates private key and certificate
4. Stores in Secret (referenced by ingress `secretName`)
5. NGINX serves HTTPS using the certificate
6. Auto-renews before expiry

## Troubleshooting

### Certificate not created
```bash
kubectl describe certificate <name> -n <namespace>
kubectl logs -n cert-manager deployment/cert-manager
```

### Check certificate status
```bash
kubectl get certificate -A
# Should show "Ready: True"
```

### Test HTTPS
```bash
curl -k https://grafana.homelab.local
# -k ignores self-signed warning
```
