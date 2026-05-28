#!/bin/bash
# Export homelab CA certificate to trust on Windows

set -e

OUTPUT_DIR="$(dirname "$0")"
CA_FILE="$OUTPUT_DIR/homelab-ca.crt"

echo "=========================================="
echo "Exporting Homelab CA Certificate"
echo "=========================================="
echo ""

# Check if cert-manager is installed
if ! kubectl get namespace cert-manager &> /dev/null; then
    echo "Error: cert-manager namespace not found"
    echo "Make sure cert-manager is installed first"
    exit 1
fi

# Extract CA certificate
echo "Extracting CA certificate..."
kubectl get secret homelab-ca-secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d > "$CA_FILE"

echo "✅ CA certificate saved to: $CA_FILE"
echo ""
echo "=========================================="
echo "Next Steps - Trust the CA on Windows"
echo "=========================================="
echo ""
echo "1. Copy the file to your Windows machine:"
echo "   The file is at: $CA_FILE"
echo ""
echo "2. On Windows, double-click the .crt file"
echo ""
echo "3. Click 'Install Certificate'"
echo ""
echo "4. Select 'Local Machine' (requires admin)"
echo ""
echo "5. Choose 'Place all certificates in the following store'"
echo ""
echo "6. Click 'Browse' and select:"
echo "   'Trusted Root Certification Authorities'"
echo ""
echo "7. Click 'Next' and 'Finish'"
echo ""
echo "8. Restart your browser"
echo ""
echo "After this, all *.homelab.local sites will be trusted!"
echo ""
