bash -c '
set -e

echo "======================================"
echo "     PROXMOX VE 9 INSTALLER"
echo "======================================"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run as root"
    exit 1
fi

if [ "$( . /etc/os-release && echo "$VERSION_CODENAME" )" != "trixie" ]; then
    echo "ERROR: This installer requires Debian 13 Trixie"
    exit 1
fi

if ! systemd-detect-virt --vm >/dev/null 2>&1; then
    echo "WARNING: Virtualization environment not detected."
fi

echo "[1/7] Creating backup..."
mkdir -p /root/proxmox-install-backup
cp -a /etc/apt /root/proxmox-install-backup/
cp -a /etc/network /root/proxmox-install-backup/
cp -a /etc/hosts /etc/hostname /root/proxmox-install-backup/

echo "[2/7] Checking hostname..."
hostname -f

echo "[3/7] Installing required tools..."
apt-get update
apt-get install -y wget ca-certificates gnupg

echo "[4/7] Installing Proxmox repository key..."
wget -q https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg \
-O /usr/share/keyrings/proxmox-archive-keyring.gpg

echo "[5/7] Configuring Proxmox No-Subscription repository..."
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/pve-enterprise.sources

cat > /etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

echo "[6/7] Installing Proxmox VE..."
apt-get update
apt-get dist-upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
proxmox-ve postfix open-iscsi chrony

echo "[7/7] Installation completed!"

echo "======================================"
echo " PROXMOX VE INSTALLATION COMPLETED"
echo "======================================"
echo "Hostname: $(hostname -f)"
echo "Backup: /root/proxmox-install-backup"
echo
echo "IMPORTANT:"
echo "Check network bridge configuration before reboot."
echo "Reboot when ready using: reboot"
'
