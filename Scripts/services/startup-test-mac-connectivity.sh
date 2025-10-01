#!/bin/bash
# AIMaster PC Startup Script - Mac Connectivity Test (Bash Version)
# Designed to run when AIMaster starts on PC in room504
# Tests SSH connection to Mac and reports status
# Alternative to PowerShell version due to compatibility issues

# Configuration
MAC_IP="${1:-100.77.255.169}"
MAC_USER="${2:-daveboyd}"
MAC_HOSTNAME="${3:-sf-Deb-Book.local}"

SCRIPT_NAME="AIMaster Mac Connectivity Test (Bash)"
START_TIME=$(date)
LOG_FILE="/tmp/aimaster_mac_test_$(date +%Y%m%d_%H%M%S).log"
RESULT_FILE="/tmp/aimaster_mac_connectivity_status.json"

function log_and_echo() {
    local message="$1"
    local color="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] $message"
    
    # Color output if supported
    case "$color" in
        "red") echo -e "\033[31m$log_entry\033[0m" ;;
        "green") echo -e "\033[32m$log_entry\033[0m" ;;
        "yellow") echo -e "\033[33m$log_entry\033[0m" ;;
        "blue") echo -e "\033[34m$log_entry\033[0m" ;;
        "cyan") echo -e "\033[36m$log_entry\033[0m" ;;
        "magenta") echo -e "\033[35m$log_entry\033[0m" ;;
        *) echo "$log_entry" ;;
    esac
    
    echo "$log_entry" >> "$LOG_FILE"
}

# Initialize
log_and_echo "🚀 $SCRIPT_NAME" "cyan"
log_and_echo "$(printf '=%.0s' {1..50})" "cyan"
log_and_echo "Startup Time: $START_TIME"
log_and_echo "PC Environment: $(hostname)"
log_and_echo "User: $(whoami)"
log_and_echo "OS: $(uname -a)"
log_and_echo ""

log_and_echo "Target Mac Information:" "yellow"
log_and_echo "  IP Address: $MAC_IP"
log_and_echo "  Username: $MAC_USER"
log_and_echo "  Hostname: $MAC_HOSTNAME"
log_and_echo ""

# Test Results Storage
TEST_RESULTS_JSON="{
  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S)Z\",
  \"pc_info\": {
    \"hostname\": \"$(hostname)\",
    \"username\": \"$(whoami)\",
    \"os\": \"$(uname -s)\",
    \"arch\": \"$(uname -m)\"
  },
  \"mac_target\": {
    \"ip_address\": \"$MAC_IP\",
    \"username\": \"$MAC_USER\",
    \"hostname\": \"$MAC_HOSTNAME\"
  },
  \"tests\": {
  }
}"

log_and_echo "=== PHASE 1: Network Connectivity Test ===" "green"

# Test 1: Ping Test
log_and_echo "Test 1: Ping connectivity to Mac..." "cyan"
if ping -c 3 -W 5000 "$MAC_IP" > /dev/null 2>&1; then
    log_and_echo "✅ Ping to $MAC_IP: SUCCESS" "green"
    PING_STATUS="SUCCESS"
    PING_MESSAGE="Ping successful"
else
    log_and_echo "❌ Ping to $MAC_IP: FAILED" "red"
    PING_STATUS="FAILED"
    PING_MESSAGE="Ping failed"
fi

# Test 2: Port 22 (SSH) Connectivity
log_and_echo ""
log_and_echo "Test 2: SSH port (22) connectivity..." "cyan"

# Use different methods based on OS
if command -v nc > /dev/null 2>&1; then
    # Use netcat
    if nc -z -w5 "$MAC_IP" 22 2>/dev/null; then
        log_and_echo "✅ SSH port 22 to $MAC_IP: ACCESSIBLE" "green"
        SSH_PORT_STATUS="SUCCESS"
        SSH_PORT_MESSAGE="Port 22 accessible via nc"
    else
        log_and_echo "❌ SSH port 22 to $MAC_IP: NOT ACCESSIBLE" "red"
        SSH_PORT_STATUS="FAILED"
        SSH_PORT_MESSAGE="Port 22 not accessible"
    fi
elif command -v telnet > /dev/null 2>&1; then
    # Use telnet as fallback
    if timeout 5 telnet "$MAC_IP" 22 < /dev/null 2>&1 | grep -q "Connected"; then
        log_and_echo "✅ SSH port 22 to $MAC_IP: ACCESSIBLE" "green"
        SSH_PORT_STATUS="SUCCESS"
        SSH_PORT_MESSAGE="Port 22 accessible via telnet"
    else
        log_and_echo "❌ SSH port 22 to $MAC_IP: NOT ACCESSIBLE" "red"
        SSH_PORT_STATUS="FAILED"
        SSH_PORT_MESSAGE="Port 22 not accessible"
    fi
else
    log_and_echo "⚠️  No port testing tools available (nc/telnet)" "yellow"
    SSH_PORT_STATUS="SKIPPED"
    SSH_PORT_MESSAGE="No port testing tools available"
fi

log_and_echo ""
log_and_echo "=== PHASE 2: SSH Client Verification ===" "green"

# Test 3: Check for SSH client
log_and_echo "Test 3: SSH client availability..." "cyan"
if command -v ssh > /dev/null 2>&1; then
    SSH_CLIENT_PATH=$(which ssh)
    SSH_VERSION=$(ssh -V 2>&1 | head -1)
    log_and_echo "✅ SSH client found: $SSH_CLIENT_PATH" "green"
    log_and_echo "   Version: $SSH_VERSION" "green"
    SSH_CLIENT_STATUS="SUCCESS"
    SSH_CLIENT_MESSAGE="SSH client available"
else
    log_and_echo "❌ SSH client not found" "red"
    SSH_CLIENT_STATUS="FAILED"
    SSH_CLIENT_MESSAGE="SSH client not available"
fi

log_and_echo ""
log_and_echo "=== PHASE 3: SSH Connection Test ===" "green"

# Test 4: Actual SSH Connection Test
log_and_echo "Test 4: SSH connection test..." "cyan"
if [ "$SSH_CLIENT_STATUS" = "SUCCESS" ] && [ "$SSH_PORT_STATUS" = "SUCCESS" ]; then
    log_and_echo "Attempting SSH connection to $MAC_USER@$MAC_IP..."
    
    # Create SSH command with proper options
    SSH_COMMAND="ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $MAC_USER@$MAC_IP 'echo SSH_CONNECTION_SUCCESS; hostname; uptime; date'"
    
    log_and_echo "SSH Command: $SSH_COMMAND"
    
    # Execute SSH command
    SSH_OUTPUT=$(eval "$SSH_COMMAND" 2>&1)
    SSH_EXIT_CODE=$?
    
    if [ $SSH_EXIT_CODE -eq 0 ] && echo "$SSH_OUTPUT" | grep -q "SSH_CONNECTION_SUCCESS"; then
        log_and_echo "✅ SSH connection: SUCCESS" "green"
        log_and_echo "SSH Response:" "green"
        echo "$SSH_OUTPUT" | while IFS= read -r line; do
            log_and_echo "  $line"
        done
        
        SSH_CONNECTION_STATUS="SUCCESS"
        SSH_CONNECTION_MESSAGE="SSH connection successful"
        SSH_CONNECTION_RESPONSE="$SSH_OUTPUT"
    else
        log_and_echo "❌ SSH connection: FAILED" "red"
        log_and_echo "SSH Error/Output:" "red"
        echo "$SSH_OUTPUT" | while IFS= read -r line; do
            log_and_echo "  $line" "red"
        done
        
        SSH_CONNECTION_STATUS="FAILED"
        SSH_CONNECTION_MESSAGE="SSH connection failed"
        SSH_CONNECTION_ERROR="$SSH_OUTPUT"
    fi
else
    log_and_echo "⚠️  Skipping SSH connection test (prerequisites not met)" "yellow"
    SSH_CONNECTION_STATUS="SKIPPED"
    SSH_CONNECTION_MESSAGE="Prerequisites not met (SSH client or port not available)"
fi

log_and_echo ""
log_and_echo "=== PHASE 4: Additional Service Tests ===" "green"

# Test 5: VNC Port Test
log_and_echo "Test 5: VNC port (5900) test..." "cyan"
if command -v nc > /dev/null 2>&1; then
    if nc -z -w5 "$MAC_IP" 5900 2>/dev/null; then
        log_and_echo "✅ VNC port 5900: ACCESSIBLE" "green"
        VNC_PORT_STATUS="SUCCESS"
        VNC_PORT_MESSAGE="VNC port accessible"
    else
        log_and_echo "❌ VNC port 5900: NOT ACCESSIBLE" "yellow"
        VNC_PORT_STATUS="FAILED"
        VNC_PORT_MESSAGE="VNC port not accessible"
    fi
else
    log_and_echo "⚠️  VNC port test skipped (nc not available)" "yellow"
    VNC_PORT_STATUS="SKIPPED"
    VNC_PORT_MESSAGE="Port testing tool not available"
fi

# Test 6: SMB Port Test
log_and_echo ""
log_and_echo "Test 6: SMB port (445) test..." "cyan"
if command -v nc > /dev/null 2>&1; then
    if nc -z -w5 "$MAC_IP" 445 2>/dev/null; then
        log_and_echo "✅ SMB port 445: ACCESSIBLE" "green"
        SMB_PORT_STATUS="SUCCESS"
        SMB_PORT_MESSAGE="SMB port accessible"
    else
        log_and_echo "❌ SMB port 445: NOT ACCESSIBLE" "yellow"
        SMB_PORT_STATUS="FAILED"
        SMB_PORT_MESSAGE="SMB port not accessible"
    fi
else
    log_and_echo "⚠️  SMB port test skipped (nc not available)" "yellow"
    SMB_PORT_STATUS="SKIPPED"
    SMB_PORT_MESSAGE="Port testing tool not available"
fi

log_and_echo ""
log_and_echo "=== FINAL RESULTS SUMMARY ===" "magenta"

# Calculate overall status
CRITICAL_TESTS=("ping" "ssh_port" "ssh_connection")
TOTAL_TESTS=6
SUCCESSFUL_TESTS=0
CRITICAL_SUCCESSES=0

# Count successes
[ "$PING_STATUS" = "SUCCESS" ] && ((SUCCESSFUL_TESTS++)) && ((CRITICAL_SUCCESSES++))
[ "$SSH_PORT_STATUS" = "SUCCESS" ] && ((SUCCESSFUL_TESTS++)) && ((CRITICAL_SUCCESSES++))
[ "$SSH_CLIENT_STATUS" = "SUCCESS" ] && ((SUCCESSFUL_TESTS++))
[ "$SSH_CONNECTION_STATUS" = "SUCCESS" ] && ((SUCCESSFUL_TESTS++)) && ((CRITICAL_SUCCESSES++))
[ "$VNC_PORT_STATUS" = "SUCCESS" ] && ((SUCCESSFUL_TESTS++))
[ "$SMB_PORT_STATUS" = "SUCCESS" ] && ((SUCCESSFUL_TESTS++))

# Determine overall status
if [ $CRITICAL_SUCCESSES -eq 3 ]; then
    OVERALL_STATUS="FULLY_FUNCTIONAL"
    STATUS_COLOR="green"
elif [ $CRITICAL_SUCCESSES -ge 2 ]; then
    OVERALL_STATUS="MOSTLY_FUNCTIONAL"
    STATUS_COLOR="yellow"
elif [ $CRITICAL_SUCCESSES -ge 1 ]; then
    OVERALL_STATUS="LIMITED_FUNCTIONALITY"
    STATUS_COLOR="yellow"
else
    OVERALL_STATUS="NOT_FUNCTIONAL"
    STATUS_COLOR="red"
fi

SUCCESS_PERCENTAGE=$(echo "scale=1; $SUCCESSFUL_TESTS * 100 / $TOTAL_TESTS" | bc 2>/dev/null || echo "N/A")

log_and_echo "📊 Test Results Summary:" "yellow"
log_and_echo "├── Total Tests: $TOTAL_TESTS"
log_and_echo "├── Successful: $SUCCESSFUL_TESTS"
log_and_echo "├── Success Rate: ${SUCCESS_PERCENTAGE}%"
log_and_echo "├── Critical Tests: $CRITICAL_SUCCESSES/3"
log_and_echo "└── Overall Status: $OVERALL_STATUS" "$STATUS_COLOR"

log_and_echo ""
log_and_echo "📋 Individual Test Results:" "yellow"
log_and_echo "├── ✅ ping: $PING_STATUS - $PING_MESSAGE" "$([ "$PING_STATUS" = "SUCCESS" ] && echo "green" || echo "red")"
log_and_echo "├── ✅ ssh_port: $SSH_PORT_STATUS - $SSH_PORT_MESSAGE" "$([ "$SSH_PORT_STATUS" = "SUCCESS" ] && echo "green" || echo "red")"
log_and_echo "├── ✅ ssh_client: $SSH_CLIENT_STATUS - $SSH_CLIENT_MESSAGE" "$([ "$SSH_CLIENT_STATUS" = "SUCCESS" ] && echo "green" || echo "red")"
log_and_echo "├── ✅ ssh_connection: $SSH_CONNECTION_STATUS - $SSH_CONNECTION_MESSAGE" "$([ "$SSH_CONNECTION_STATUS" = "SUCCESS" ] && echo "green" || echo "red")"
log_and_echo "├── ✅ vnc_port: $VNC_PORT_STATUS - $VNC_PORT_MESSAGE" "$([ "$VNC_PORT_STATUS" = "SUCCESS" ] && echo "green" || echo "yellow")"
log_and_echo "└── ✅ smb_port: $SMB_PORT_STATUS - $SMB_PORT_MESSAGE" "$([ "$SMB_PORT_STATUS" = "SUCCESS" ] && echo "green" || echo "yellow")"

# Create detailed JSON results
cat > "$RESULT_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S)Z",
  "pc_info": {
    "hostname": "$(hostname)",
    "username": "$(whoami)",
    "os": "$(uname -s)",
    "arch": "$(uname -m)"
  },
  "mac_target": {
    "ip_address": "$MAC_IP",
    "username": "$MAC_USER",
    "hostname": "$MAC_HOSTNAME"
  },
  "tests": {
    "ping": {
      "status": "$PING_STATUS",
      "message": "$PING_MESSAGE"
    },
    "ssh_port": {
      "status": "$SSH_PORT_STATUS", 
      "message": "$SSH_PORT_MESSAGE"
    },
    "ssh_client": {
      "status": "$SSH_CLIENT_STATUS",
      "message": "$SSH_CLIENT_MESSAGE"
    },
    "ssh_connection": {
      "status": "$SSH_CONNECTION_STATUS",
      "message": "$SSH_CONNECTION_MESSAGE"
    },
    "vnc_port": {
      "status": "$VNC_PORT_STATUS",
      "message": "$VNC_PORT_MESSAGE"
    },
    "smb_port": {
      "status": "$SMB_PORT_STATUS",
      "message": "$SMB_PORT_MESSAGE"
    }
  },
  "summary": {
    "overall_status": "$OVERALL_STATUS",
    "total_tests": $TOTAL_TESTS,
    "successful_tests": $SUCCESSFUL_TESTS,
    "critical_successes": $CRITICAL_SUCCESSES,
    "success_percentage": $SUCCESS_PERCENTAGE
  }
}
EOF

log_and_echo ""
log_and_echo "💾 Saving results..." "cyan"
log_and_echo "✅ Results saved to: $RESULT_FILE" "green"

# Display connection information based on status
if [ "$OVERALL_STATUS" = "FULLY_FUNCTIONAL" ]; then
    log_and_echo ""
    log_and_echo "🎉 MAC CONNECTIVITY: FULLY OPERATIONAL!" "green"
    log_and_echo ""
    log_and_echo "🔗 Ready-to-use connection commands:" "cyan"
    log_and_echo "   SSH: ssh $MAC_USER@$MAC_IP"
    log_and_echo "   VNC: (Use VNC client to connect to $MAC_IP:5900)"
    log_and_echo "   SMB: (Access file sharing at //$MAC_IP)"
    log_and_echo ""
    log_and_echo "🚀 AIMaster can now control the Mac remotely from this PC!"
elif [ "$OVERALL_STATUS" = "MOSTLY_FUNCTIONAL" ] || [ "$OVERALL_STATUS" = "LIMITED_FUNCTIONALITY" ]; then
    log_and_echo ""
    log_and_echo "⚠️  MAC CONNECTIVITY: PARTIAL FUNCTIONALITY" "yellow"
    log_and_echo "Some services are working, but troubleshooting may be needed."
else
    log_and_echo ""
    log_and_echo "❌ MAC CONNECTIVITY: NOT FUNCTIONAL" "red"
    log_and_echo "Mac is not accessible from this PC. Check network and Mac setup."
fi

END_TIME=$(date)
DURATION=$(($(date +%s) - $(date -d "$START_TIME" +%s 2>/dev/null || echo "0")))

log_and_echo ""
log_and_echo "📄 Log file saved to: $LOG_FILE"
log_and_echo "⏰ Test completed in: ${DURATION}s"
log_and_echo ""
log_and_echo "🏁 AIMaster Mac Connectivity Test Complete!" "cyan"

# Return overall status for script chaining
echo "$OVERALL_STATUS"