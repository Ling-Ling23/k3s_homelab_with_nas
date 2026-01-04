# NFS Storage Setup Guide

## Prerequisites
1. Configure Synology NFS share:
   - Control Panel → Shared Folder → Create folder `k3s-storage`
   - Control Panel → File Services → Enable NFS
   - Edit folder → NFS Permissions → Add rule:
     - Server: 192.168.0.197 (raspi1)  # ! add later other pis
     - Privilege: Read/Write
     - Squash: Map all users to admin

2. Install NFS client on Raspberry Pi:
   ```bash
   ssh lingling@192.168.0.197
   sudo apt update
   sudo apt install nfs-common -y
   ```

## Installation Steps

### 1. Install NFS CSI Driver
```bash
# Quick install (recommended) - Download and run install script
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh | bash -s master --

# OR apply manifests directly
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/rbac-csi-nfs.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/csi-nfs-driverinfo.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/csi-nfs-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/csi-nfs-node.yaml
```

### 2. Verify NFS CSI Driver
```bash
kubectl get pods -n kube-system | grep csi-nfs
```

Expected output:
```
csi-nfs-controller-xxx   4/4     Running
csi-nfs-node-xxx         3/3     Running
```

### 3. Update StorageClass with your Synology IP
Edit `k3s/nfs/storageclass.yaml`:
- Change `server: 192.168.0.XXX` to your Synology IP
- Update `share:` path if different

### 4. Apply StorageClass
```bash
kubectl apply -f k3s/nfs/storageclass.yaml
```

### 5. Verify StorageClass
```bash
kubectl get storageclass nfs-synology
```

### 6. Test NFS Storage (Optional)
```bash
# Create test PVC and pod
kubectl apply -f k3s/nfs/test-pvc.yaml

# Check PVC status
kubectl get pvc test-nfs-pvc

# Check pod logs
kubectl logs test-nfs-pod

# Verify file on Synology (should see test.txt in k3s-storage folder)

# Cleanup test
kubectl delete -f k3s/nfs/test-pvc.yaml
```

## Usage in Applications

### Example: Prometheus with NFS storage
```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: nfs-synology  # Use NFS instead of longhorn
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi  # Can use larger size on NAS
```

### Example: Custom application
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can access
  storageClassName: nfs-synology
  resources:
    requests:
      storage: 100Gi
```

## Storage Strategy

- **Longhorn (Pi SD card)**: Small, fast volumes for configs, system data
- **NFS (Synology)**: Large data volumes, databases, media files

## Troubleshooting

### PVC stuck in Pending
```bash
kubectl describe pvc <pvc-name>
kubectl logs -n kube-system -l app=csi-nfs-controller
```

### Check NFS mount on Pi
```bash
ssh lingling@192.168.0.197
showmount -e <SYNOLOGY_IP>
```

### Test manual NFS mount
```bash
ssh lingling@192.168.0.197
sudo mkdir -p /mnt/test
sudo mount -t nfs <SYNOLOGY_IP>:/volume1/k3s-storage /mnt/test
ls -la /mnt/test
sudo umount /mnt/test
```
