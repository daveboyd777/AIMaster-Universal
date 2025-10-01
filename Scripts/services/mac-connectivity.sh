#!/bin/bash
# AIMaster Mac Connection Test Script

MAC_IP="$1"
MAC_USER="$2"

if [ -z "$MAC_IP" ] || [ -z "$MAC_USER" ]; then
    echo "Usage: $0 <ip_address> <username>"
    echo "Example: $0 100.77.255.169 daveboyd"
    exit 1
fi

echo "🧪 Testing Mac Connection: $MAC_USER@$MAC_IP"
echo "============================================"

# Test SSH
echo "Testing SSH..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes "$MAC_USER@$MAC_IP" "echo 'SSH: OK'; hostname; uptime" 2>/dev/null; then
    echo "✅ SSH connection successful"
else
    echo "❌ SSH connection failed"
fi

# Test VNC port
echo ""
echo "Testing VNC port 5900..."
if nc -z "$MAC_IP" 5900 2>/dev/null; then
    echo "✅ VNC port 5900 accessible"
else
    echo "❌ VNC port 5900 not accessible"
fi

# Test file sharing
echo ""
echo "Testing SMB file sharing..."
if nc -z "$MAC_IP" 445 2>/dev/null; then
    echo "✅ SMB port 445 accessible"
else
    echo "❌ SMB port 445 not accessible"
fi

echo ""
echo "Connection test completed."
