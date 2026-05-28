# Deploy NFS CSI Driver
# Source: https://github.com/kubernetes-csi/csi-driver-nfs

# Install NFS CSI Driver
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh

# Or manually apply manifests:
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/v4.9.0/rbac-csi-nfs.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/v4.9.0/csi-nfs-driverinfo.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/v4.9.0/csi-nfs-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/v4.9.0/csi-nfs-node.yaml

# Verify installation
kubectl get pods -n kube-system | grep csi-nfs
