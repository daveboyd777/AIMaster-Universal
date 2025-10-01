#!/bin/bash
# AIMaster Universal Orchestrator - Network Utilities Library
# Cross-platform network testing and operations

# Network configuration
DEFAULT_TIMEOUT=10
DEFAULT_RETRY_COUNT=3
DEFAULT_PORTS=(22 80 443 3389 5900)
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222")

function check_internet_connectivity() {
    local timeout="${1:-$DEFAULT_TIMEOUT}"
    local test_hosts=("google.com" "cloudflare.com" "8.8.8.8")
    
    log_debug "Testing internet connectivity with timeout ${timeout}s"
    
    for host in "${test_hosts[@]}"; do
        if ping_host "$host" 1 "$timeout"; then
            log_debug "Internet connectivity confirmed via $host"
            return 0
        fi
    done
    
    log_debug "Internet connectivity test failed"
    return 1
}

function ping_host() {
    local host="$1"
    local count="${2:-1}"
    local timeout="${3:-$DEFAULT_TIMEOUT}"
    
    log_debug "Pinging $host (count=$count, timeout=${timeout}s)"
    
    local platform=$(detect_platform)
    local ping_cmd
    
    case "$platform" in
        "macOS"|"Linux")
            ping_cmd="ping -c $count -W $timeout"
            ;;
        "Windows")
            # Windows ping syntax (for Git Bash/WSL)
            ping_cmd="ping -n $count -w ${timeout}000"
            ;;
        *)
            ping_cmd="ping -c $count -W $timeout"
            ;;
    esac
    
    if $ping_cmd "$host" >/dev/null 2>&1; then
        log_debug "Ping successful: $host"
        return 0
    else
        log_debug "Ping failed: $host"
        return 1
    fi
}

function test_port_connectivity() {
    local host="$1"
    local port="$2"
    local timeout="${3:-$DEFAULT_TIMEOUT}"
    local protocol="${4:-tcp}"  # tcp, udp
    
    log_debug "Testing port connectivity: $host:$port ($protocol, timeout=${timeout}s)"
    
    # Try different methods based on available tools
    if command -v nc >/dev/null 2>&1; then
        test_port_with_netcat "$host" "$port" "$timeout" "$protocol"
    elif command -v telnet >/dev/null 2>&1; then
        test_port_with_telnet "$host" "$port" "$timeout"
    elif command -v bash >/dev/null 2>&1; then
        test_port_with_bash "$host" "$port" "$timeout"
    else
        log_error "No tools available for port testing"
        return 1
    fi
}

function test_port_with_netcat() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    local protocol="$4"
    
    local nc_opts="-z"  # Zero I/O mode
    [[ "$protocol" == "udp" ]] && nc_opts="$nc_opts -u"
    
    if timeout "$timeout" nc $nc_opts "$host" "$port" 2>/dev/null; then
        log_debug "Port test successful (netcat): $host:$port"
        return 0
    else
        log_debug "Port test failed (netcat): $host:$port"
        return 1
    fi
}

function test_port_with_telnet() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    
    # Telnet only works with TCP
    if timeout "$timeout" bash -c "echo | telnet $host $port" 2>/dev/null | grep -q "Connected"; then
        log_debug "Port test successful (telnet): $host:$port"
        return 0
    else
        log_debug "Port test failed (telnet): $host:$port"
        return 1
    fi
}

function test_port_with_bash() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    
    # Bash TCP pseudo-device (only works with TCP)
    if timeout "$timeout" bash -c "exec 3<>/dev/tcp/$host/$port && exec 3<&-" 2>/dev/null; then
        log_debug "Port test successful (bash): $host:$port"
        return 0
    else
        log_debug "Port test failed (bash): $host:$port"
        return 1
    fi
}

function scan_common_ports() {
    local host="$1"
    local timeout="${2:-5}"
    local -a ports=("${@:3}")
    
    # Use default ports if none specified
    [[ ${#ports[@]} -eq 0 ]] && ports=("${DEFAULT_PORTS[@]}")
    
    log_info "Scanning common ports on $host (timeout=${timeout}s)"
    
    local open_ports=()
    local closed_ports=()
    
    for port in "${ports[@]}"; do
        log_debug "Testing port $port..."
        if test_port_connectivity "$host" "$port" "$timeout"; then
            open_ports+=("$port")
            echo "  ✅ Port $port: Open"
        else
            closed_ports+=("$port")
            echo "  ❌ Port $port: Closed/Filtered"
        fi
    done
    
    echo
    echo "Port Scan Results for $host:"
    echo "  Open ports: ${open_ports[*]:-none}"
    echo "  Closed/filtered ports: ${closed_ports[*]:-none}"
    
    return 0
}

function test_ssh_connectivity() {
    local host="$1"
    local port="${2:-22}"
    local username="${3:-}"
    local timeout="${4:-$DEFAULT_TIMEOUT}"
    local key_file="${5:-}"
    
    log_debug "Testing SSH connectivity: ${username}@${host}:${port}"
    
    # First check if SSH port is open
    if ! test_port_connectivity "$host" "$port" "$timeout"; then
        log_error "SSH port $port is not accessible on $host"
        return 1
    fi
    
    log_success "SSH port $port is accessible on $host"
    
    # If username provided, try to establish SSH connection
    if [[ -n "$username" ]]; then
        local ssh_opts=("-o" "ConnectTimeout=$timeout" "-o" "BatchMode=yes" "-o" "StrictHostKeyChecking=no")
        
        # Add key file if specified
        [[ -n "$key_file" && -f "$key_file" ]] && ssh_opts+=("-i" "$key_file")
        
        log_debug "Attempting SSH connection test..."
        
        # Test SSH connection with a simple command
        if timeout "$timeout" ssh "${ssh_opts[@]}" -p "$port" "${username}@${host}" "echo 'SSH connection test successful'" 2>/dev/null; then
            log_success "SSH connection established successfully"
            return 0
        else
            log_warn "SSH port is open but connection failed (authentication/other issues)"
            return 2  # Port open but connection failed
        fi
    fi
    
    return 0
}

function test_http_connectivity() {
    local url="$1"
    local timeout="${2:-$DEFAULT_TIMEOUT}"
    local expected_status="${3:-200}"
    
    log_debug "Testing HTTP connectivity: $url (timeout=${timeout}s)"
    
    local http_tool=""
    
    if command -v curl >/dev/null 2>&1; then
        http_tool="curl"
    elif command -v wget >/dev/null 2>&1; then
        http_tool="wget"
    else
        log_error "No HTTP tools (curl/wget) available"
        return 1
    fi
    
    case "$http_tool" in
        "curl")
            local status_code
            status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$timeout" "$url" 2>/dev/null)
            
            if [[ "$status_code" == "$expected_status" ]]; then
                log_success "HTTP test successful: $url (status: $status_code)"
                return 0
            else
                log_warn "HTTP test failed: $url (status: $status_code, expected: $expected_status)"
                return 1
            fi
            ;;
        "wget")
            if timeout "$timeout" wget --spider --quiet "$url" 2>/dev/null; then
                log_success "HTTP test successful: $url"
                return 0
            else
                log_warn "HTTP test failed: $url"
                return 1
            fi
            ;;
    esac
}

function test_dns_resolution() {
    local hostname="$1"
    local dns_server="${2:-}"
    local timeout="${3:-$DEFAULT_TIMEOUT}"
    
    log_debug "Testing DNS resolution: $hostname"
    [[ -n "$dns_server" ]] && log_debug "Using DNS server: $dns_server"
    
    local dns_tool=""
    local dns_opts=()
    
    if command -v nslookup >/dev/null 2>&1; then
        dns_tool="nslookup"
    elif command -v dig >/dev/null 2>&1; then
        dns_tool="dig"
    elif command -v host >/dev/null 2>&1; then
        dns_tool="host"
    else
        log_warn "No DNS tools available, trying basic resolution"
        # Fallback to ping test
        if ping_host "$hostname" 1 "$timeout"; then
            log_success "Basic name resolution successful: $hostname"
            return 0
        else
            log_error "Basic name resolution failed: $hostname"
            return 1
        fi
    fi
    
    case "$dns_tool" in
        "nslookup")
            local result
            if [[ -n "$dns_server" ]]; then
                result=$(timeout "$timeout" nslookup "$hostname" "$dns_server" 2>/dev/null)
            else
                result=$(timeout "$timeout" nslookup "$hostname" 2>/dev/null)
            fi
            
            if echo "$result" | grep -q "Address:.*[0-9]"; then
                local ip_address
                ip_address=$(echo "$result" | grep "Address:" | tail -1 | awk '{print $2}')
                log_success "DNS resolution successful: $hostname -> $ip_address"
                return 0
            else
                log_error "DNS resolution failed: $hostname"
                return 1
            fi
            ;;
        "dig")
            local dig_opts=()
            [[ -n "$dns_server" ]] && dig_opts+=("@$dns_server")
            dig_opts+=("+time=$timeout" "+tries=1" "+short")
            
            local result
            result=$(dig "${dig_opts[@]}" "$hostname" A 2>/dev/null)
            
            if [[ -n "$result" && "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                log_success "DNS resolution successful: $hostname -> $result"
                return 0
            else
                log_error "DNS resolution failed: $hostname"
                return 1
            fi
            ;;
        "host")
            local host_opts=()
            [[ -n "$dns_server" ]] && host_opts+=("$hostname" "$dns_server")
            [[ ${#host_opts[@]} -eq 0 ]] && host_opts+=("$hostname")
            
            local result
            result=$(timeout "$timeout" host "${host_opts[@]}" 2>/dev/null)
            
            if echo "$result" | grep -q "has address"; then
                local ip_address
                ip_address=$(echo "$result" | grep "has address" | head -1 | awk '{print $NF}')
                log_success "DNS resolution successful: $hostname -> $ip_address"
                return 0
            else
                log_error "DNS resolution failed: $hostname"
                return 1
            fi
            ;;
    esac
}

function get_local_ip() {
    local interface="${1:-}"
    local platform=$(detect_platform)
    
    case "$platform" in
        "macOS")
            if [[ -n "$interface" ]]; then
                ifconfig "$interface" 2>/dev/null | grep "inet " | head -1 | awk '{print $2}'
            else
                # Get IP of default route interface
                local default_interface
                default_interface=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
                [[ -n "$default_interface" ]] && get_local_ip "$default_interface"
            fi
            ;;
        "Linux")
            if command -v ip >/dev/null 2>&1; then
                if [[ -n "$interface" ]]; then
                    ip addr show "$interface" 2>/dev/null | grep "inet " | head -1 | awk '{print $2}' | cut -d'/' -f1
                else
                    # Get IP of default route interface
                    ip route get 8.8.8.8 2>/dev/null | grep src | awk '{print $7}' | head -1
                fi
            else
                if [[ -n "$interface" ]]; then
                    ifconfig "$interface" 2>/dev/null | grep "inet " | head -1 | awk '{print $2}'
                else
                    hostname -I 2>/dev/null | awk '{print $1}'
                fi
            fi
            ;;
        "Windows")
            # For Windows environments (Git Bash, WSL)
            if command -v ipconfig >/dev/null 2>&1; then
                ipconfig | grep "IPv4 Address" | head -1 | cut -d':' -f2 | tr -d ' '
            else
                hostname -I 2>/dev/null | awk '{print $1}'
            fi
            ;;
        *)
            hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown"
            ;;
    esac
}

function get_public_ip() {
    local timeout="${1:-$DEFAULT_TIMEOUT}"
    local services=("ifconfig.me" "ipecho.net/plain" "icanhazip.com" "ipinfo.io/ip")
    
    log_debug "Retrieving public IP address"
    
    for service in "${services[@]}"; do
        local url="http://$service"
        
        if command -v curl >/dev/null 2>&1; then
            local result
            result=$(curl -s --connect-timeout "$timeout" "$url" 2>/dev/null | tr -d '\n\r' | head -1)
            if [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                log_debug "Public IP retrieved from $service: $result"
                echo "$result"
                return 0
            fi
        elif command -v wget >/dev/null 2>&1; then
            local result
            result=$(timeout "$timeout" wget -qO- "$url" 2>/dev/null | tr -d '\n\r' | head -1)
            if [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                log_debug "Public IP retrieved from $service: $result"
                echo "$result"
                return 0
            fi
        fi
    done
    
    log_warn "Failed to retrieve public IP address"
    echo "unknown"
    return 1
}

function test_network_speed() {
    local test_file_url="${1:-http://speedtest.ftp.otenet.gr/files/test1Mb.db}"
    local timeout="${2:-30}"
    
    log_info "Testing network download speed..."
    
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl not available for speed test"
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    local start_time
    start_time=$(date +%s)
    
    if curl -s --connect-timeout "$timeout" -o "$temp_file" "$test_file_url" 2>/dev/null; then
        local end_time
        end_time=$(date +%s)
        
        local duration=$((end_time - start_time))
        local file_size
        file_size=$(stat -f%z "$temp_file" 2>/dev/null || stat -c%s "$temp_file" 2>/dev/null || echo "0")
        
        if [[ $duration -gt 0 && $file_size -gt 0 ]]; then
            local speed_bps=$((file_size / duration))
            local speed_kbps=$((speed_bps / 1024))
            local speed_mbps=$((speed_kbps / 1024))
            
            echo "Download Speed Test Results:"
            echo "  File size: $(format_bytes "$file_size")"
            echo "  Duration: ${duration}s"
            echo "  Speed: ${speed_bps} B/s (${speed_kbps} KB/s, ${speed_mbps} MB/s)"
        else
            log_error "Invalid speed test results"
        fi
        
        rm -f "$temp_file"
    else
        log_error "Speed test download failed"
        rm -f "$temp_file"
        return 1
    fi
}

function format_bytes() {
    local bytes="$1"
    
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024)) KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576)) MB"
    else
        echo "$((bytes / 1073741824)) GB"
    fi
}

function comprehensive_network_test() {
    local target_host="${1:-google.com}"
    local target_port="${2:-80}"
    local username="${3:-}"
    
    log_banner "Comprehensive Network Test"
    
    echo "Target: $target_host:$target_port"
    [[ -n "$username" ]] && echo "SSH User: $username"
    echo
    
    # Basic connectivity
    log_section "Basic Connectivity"
    echo -n "Internet connectivity: "
    if check_internet_connectivity; then
        echo "✅ Available"
    else
        echo "❌ Unavailable"
    fi
    
    echo -n "Target host ping: "
    if ping_host "$target_host" 1 5; then
        echo "✅ Responding"
    else
        echo "❌ Not responding"
    fi
    
    # DNS Resolution
    log_section "DNS Resolution"
    echo "Testing DNS resolution for $target_host:"
    if test_dns_resolution "$target_host"; then
        echo "✅ DNS resolution successful"
    else
        echo "❌ DNS resolution failed"
    fi
    
    # Port Testing
    log_section "Port Connectivity"
    echo -n "Target port ($target_port): "
    if test_port_connectivity "$target_host" "$target_port" 10; then
        echo "✅ Open"
    else
        echo "❌ Closed/Filtered"
    fi
    
    # SSH Testing (if username provided)
    if [[ -n "$username" && "$target_port" == "22" ]]; then
        log_section "SSH Connectivity"
        echo "Testing SSH connection as $username:"
        case $(test_ssh_connectivity "$target_host" "$target_port" "$username" 15; echo $?) in
            0)
                echo "✅ SSH connection successful"
                ;;
            1)
                echo "❌ SSH port not accessible"
                ;;
            2)
                echo "⚠️  SSH port open but connection failed"
                ;;
        esac
    fi
    
    # Network Information
    log_section "Network Information"
    local local_ip
    local_ip=$(get_local_ip)
    echo "Local IP: ${local_ip:-unknown}"
    
    local public_ip
    public_ip=$(get_public_ip 10)
    echo "Public IP: ${public_ip:-unknown}"
    
    # Common Port Scan
    log_section "Common Port Scan"
    scan_common_ports "$target_host" 3 22 80 443 3389 5900
    
    log_success "Network test completed"
}

# Network monitoring functions
function monitor_connection() {
    local host="$1"
    local interval="${2:-5}"
    local duration="${3:-60}"
    
    log_info "Monitoring connection to $host for ${duration}s (interval: ${interval}s)"
    
    local start_time
    start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local success_count=0
    local fail_count=0
    
    while [[ $(date +%s) -lt $end_time ]]; do
        local current_time
        current_time=$(date '+%H:%M:%S')
        
        if ping_host "$host" 1 3; then
            echo "[$current_time] ✅ $host - OK"
            ((success_count++))
        else
            echo "[$current_time] ❌ $host - FAILED"
            ((fail_count++))
        fi
        
        sleep "$interval"
    done
    
    echo
    echo "Connection Monitoring Results:"
    echo "  Success: $success_count"
    echo "  Failures: $fail_count"
    echo "  Success Rate: $(( success_count * 100 / (success_count + fail_count) ))%"
}

function trace_route() {
    local host="$1"
    local max_hops="${2:-30}"
    
    log_info "Tracing route to $host (max hops: $max_hops)"
    
    if command -v traceroute >/dev/null 2>&1; then
        traceroute -m "$max_hops" "$host"
    elif command -v tracert >/dev/null 2>&1; then
        tracert -h "$max_hops" "$host"
    else
        log_error "No traceroute tools available"
        return 1
    fi
}