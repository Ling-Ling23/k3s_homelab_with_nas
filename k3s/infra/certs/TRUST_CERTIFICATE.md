# Trust Homelab CA Certificate on Windows

## Quick Steps

### 1. Export CA certificate from cluster
```bash
# SSH to your Pi
ssh lingling@192.168.0.197
cd ~/k3s_homelab_with_nas/k3s/certs
bash export-ca.sh
```

This creates `homelab-ca.crt` file.

### 2. Copy certificate to Windows
Use SFTP or WinSCP to download the file, or:
```bash
# From your Windows machine in WSL/Git Bash
scp lingling@192.168.0.197:~/k3s_homelab_with_nas/k3s/certs/homelab-ca.crt ~/Desktop/
```

### 3. Install certificate on Windows

#### Option A: GUI (Recommended)
1. Double-click `homelab-ca.crt` on your Desktop
2. Click **"Install Certificate"**
3. Select **"Local Machine"** (requires Administrator)
4. Click **"Next"**
5. Choose **"Place all certificates in the following store"**
6. Click **"Browse"** → Select **"Trusted Root Certification Authorities"**
7. Click **"Next"** → **"Finish"**
8. Click **"Yes"** on the security warning

#### Option B: PowerShell (requires Admin)
```powershell
# Run PowerShell as Administrator
Import-Certificate -FilePath "$env:USERPROFILE\Desktop\homelab-ca.crt" -CertStoreLocation Cert:\LocalMachine\Root
```

### 4. Restart browser
Close and reopen your browser (Chrome, Edge, Firefox).

### 5. Verify
Visit https://grafana.homelab.local - the padlock should be green with no warnings!

## What This Does

- Adds your homelab CA to Windows Trusted Root Certification Authorities
- All certificates signed by this CA are now trusted
- Works for all `*.homelab.local` domains
- Eliminates "Not Secure" warnings

## Certificate Details

You can view the certificate details:
```bash
openssl x509 -in homelab-ca.crt -text -noout
```

## Trust on Other Devices (Optional)

### Linux
```bash
sudo cp homelab-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### macOS
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain homelab-ca.crt
```

### Android
1. Settings → Security → Encryption & credentials
2. Install a certificate → CA certificate
3. Select the file

### iOS
1. Email the file to yourself or use AirDrop
2. Open the file → Install profile
3. Settings → General → About → Certificate Trust Settings
4. Enable trust for the certificate

## Troubleshooting

### Certificate not appearing in browser
- Clear browser cache
- Fully restart browser (close all windows)
- Check certificate is in correct store: `certmgr.msc` → Trusted Root Certification Authorities

### Still showing warning
- Verify certificate was installed to "Local Machine" not "Current User"
- Check hosts file has correct IPs
- Try different browser

### Firefox not trusting certificate
Firefox uses its own certificate store. Either:
- Go to Firefox settings → Privacy & Security → Certificates → View Certificates
- Import the CA certificate manually
- Or use Firefox policy to use Windows certificate store

## Revoke Trust (if needed)

1. Open `certmgr.msc` (Windows + R)
2. Navigate to: Trusted Root Certification Authorities → Certificates
3. Find "homelab-ca"
4. Right-click → Delete

## Security Note

This CA certificate is only trusted on your device. It doesn't affect security for external websites. Anyone with physical access to this certificate file could potentially create trusted certificates for your machine, so keep it safe.
