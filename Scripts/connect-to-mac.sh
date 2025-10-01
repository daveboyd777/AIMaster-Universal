#!/bin/bash
# Quick Mac Connection Script

MAC_IP="100.77.255.169"
MAC_USER="daveboyd"
MAC_HOSTNAME="sf-Deb-Book.local"

echo "🔗 AIMaster Mac Quick Connect"
echo "============================="
echo "Mac: $MAC_HOSTNAME ($MAC_IP)"
echo "User: $MAC_USER"
echo ""

case "$1" in
    "ssh"|"")
        echo "Connecting via SSH..."
        ssh "$MAC_USER@$MAC_IP"
        ;;
    "vnc")
        echo "VNC connection string: vnc://$MAC_IP:5900"
        echo "Password hint: aimaster123"
        if command -v open >/dev/null; then
            echo "Opening VNC connection..."
            open "vnc://$MAC_IP:5900"
        fi
        ;;
    "smb"|"files")
        echo "File sharing connection: smb://$MAC_IP"
        if command -v open >/dev/null; then
            echo "Opening file sharing..."
            open "smb://$MAC_IP"
        fi
        ;;
    "test")
        echo "Running connection tests..."
        "/Users/daveboyd/AIMaster-Universal/Scripts/test-mac-connection.sh" "$MAC_IP" "$MAC_USER"
        ;;
    "info")
        echo "Mac Connection Information:"
        echo "- SSH: ssh $MAC_USER@$MAC_IP"
        echo "- VNC: vnc://$MAC_IP:5900"
        echo "- SMB: smb://$MAC_IP"
        echo "- Local: ssh $MAC_USER@localhost"
        ;;
    *)
        echo "Usage: $0 [ssh|vnc|smb|test|info]"
        echo ""
        echo "Options:"
        echo "  ssh     - SSH connection (default)"
        echo "  vnc     - VNC screen sharing"
        echo "  smb     - File sharing"
        echo "  test    - Test all connections"
        echo "  info    - Show connection info"
        ;;
esac
