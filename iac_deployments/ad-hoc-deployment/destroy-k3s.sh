#!/bin/bash
# Complete K3s Infrastructure Destruction Script
# WARNING: This will DESTROY everything K3s related!

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${RED}=========================================="
echo "K3s COMPLETE DESTRUCTION SCRIPT"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING ⚠️${NC}"
echo "This will completely remove:"
echo "  - K3s cluster"
echo "  - All deployments (ArgoCD, Monitoring, Logging, etc.)"
echo "  - Longhorn storage data"
echo "  - All PVCs and data"
echo "  - Configuration files"
echo "  - iptables rules"
echo ""
read -p "Are you ABSOLUTELY SURE? Type 'DESTROY' to continue: " confirm

if [ "$confirm" != "DESTROY" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting destruction in 5 seconds... (Ctrl+C to abort)${NC}"
sleep 5

# Create backup directory
BACKUP_DIR="$HOME/k3s-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo ""
echo -e "${GREEN}Step 1: Backing up critical data...${NC}"

# Backup kubeconfig
if [ -f ~/.kube/config ]; then
    cp ~/.kube/config "$BACKUP_DIR/kubeconfig.yaml"
    echo "✓ Backed up kubeconfig"
fi

# Backup sealed secrets controller keys (if exists)
if command -v kubectl &> /dev/null; then
    kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > "$BACKUP_DIR/sealed-secrets-keys.yaml" 2>/dev/null || true
    echo "✓ Backed up sealed secrets keys (if they exist)"
fi

# Backup Longhorn backups location info
if [ -d /var/lib/longhorn ]; then
    ls -la /var/lib/longhorn > "$BACKUP_DIR/longhorn-structure.txt" 2>/dev/null || true
    echo "✓ Backed up Longhorn directory structure"
fi

echo ""
echo -e "${GREEN}Step 2: Stopping K3s services...${NC}"

# Kill all K3s processes
if [ -f /usr/local/bin/k3s-killall.sh ]; then
    echo "Running k3s-killall.sh..."
    /usr/local/bin/k3s-killall.sh || true
    echo "✓ K3s processes killed"
else
    echo "⚠️  k3s-killall.sh not found, skipping"
fi

echo ""
echo -e "${GREEN}Step 3: Uninstalling K3s...${NC}"

# Uninstall K3s server
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    echo "Running k3s-uninstall.sh..."
    /usr/local/bin/k3s-uninstall.sh || true
    echo "✓ K3s server uninstalled"
fi

# Uninstall K3s agent (if worker node)
if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
    echo "Running k3s-agent-uninstall.sh..."
    /usr/local/bin/k3s-agent-uninstall.sh || true
    echo "✓ K3s agent uninstalled"
fi

echo ""
echo -e "${GREEN}Step 4: Removing K3s directories...${NC}"

# Remove K3s directories
sudo rm -rf /var/lib/rancher/k3s
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /etc/rancher
sudo rm -rf ~/.kube
echo "✓ K3s directories removed"

# Remove Longhorn data (WARNING: This deletes all storage data!)
echo ""
read -p "Delete Longhorn storage data? (yes/no): " delete_longhorn
if [ "$delete_longhorn" = "yes" ]; then
    sudo rm -rf /var/lib/longhorn
    echo "✓ Longhorn data removed"
else
    echo "⚠️  Longhorn data preserved at /var/lib/longhorn"
fi

# Remove containerd data
sudo rm -rf /var/lib/rancher
echo "✓ Rancher directories removed"

echo ""
echo -e "${GREEN}Step 5: Cleaning up network configuration...${NC}"

# Remove CNI plugins
sudo rm -rf /opt/cni
sudo rm -rf /etc/cni
echo "✓ CNI configuration removed"

# Clean up iptables rules (K3s specific)
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
echo "✓ iptables rules flushed"

# Remove virtual network interfaces
for iface in $(ip link show | grep 'cni\|flannel\|veth' | awk '{print $2}' | sed 's/:.*//'); do
    sudo ip link delete "$iface" 2>/dev/null || true
done
echo "✓ Virtual network interfaces removed"

echo ""
echo -e "${GREEN}Step 6: Unmounting any remaining filesystems...${NC}"

# Unmount K3s related mounts
mount | grep '/var/lib/rancher\|/run/k3s' | awk '{print $3}' | while read -r mount_point; do
    sudo umount "$mount_point" 2>/dev/null || true
done
echo "✓ K3s mounts unmounted"

echo ""
echo -e "${GREEN}Step 7: Removing systemd service files...${NC}"

# Remove systemd services
sudo rm -f /etc/systemd/system/k3s*.service
sudo systemctl daemon-reload
echo "✓ Systemd services removed"

echo ""
echo -e "${GREEN}Step 8: Cleaning up logs...${NC}"

# Remove logs
sudo rm -rf /var/log/pods
sudo rm -rf /var/log/containers
echo "✓ Pod logs removed"

echo ""
echo -e "${GREEN}Step 9: Final cleanup...${NC}"

# Remove any leftover files
sudo find /tmp -name 'k3s*' -delete 2>/dev/null || true
sudo find /tmp -name 'etcd*' -delete 2>/dev/null || true
echo "✓ Temp files cleaned"

# Clean up firewall rules (if ufw is used)
if command -v ufw &> /dev/null; then
    sudo ufw status | grep '6443\|10250\|2379\|2380' | while read -r rule; do
        sudo ufw delete allow 6443 2>/dev/null || true
        sudo ufw delete allow 10250 2>/dev/null || true
    done
    echo "✓ Firewall rules cleaned (if any)"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "K3s DESTRUCTION COMPLETE!"
echo "==========================================${NC}"
echo ""
echo "Summary:"
echo "  - K3s cluster destroyed"
echo "  - All data removed (except NFS on Synology)"
echo "  - Network configuration cleaned"
echo "  - System ready for fresh install"
echo ""
echo "Backups saved to: $BACKUP_DIR"
echo ""
echo "To reinstall K3s, run:"
echo "  TBD"
echo ""
echo "Reboot recommended:"
echo "  sudo reboot"
echo ""
