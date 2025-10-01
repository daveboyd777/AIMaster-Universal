#!/usr/bin/env bats

# AIMaster Mac Connectivity Tests
# Replaces PowerShell Pester tests with Bats for cross-platform compatibility

# Test configuration
MAC_IP="100.77.255.169"
MAC_USER="daveboyd"
MAC_HOSTNAME="sf-Deb-Book.local"

setup() {
    # Set up test environment
    load_helpers_if_available
    
    # Ensure we have required tools
    if ! command -v ping >/dev/null 2>&1; then
        skip "ping command not available"
    fi
    
    if ! command -v nc >/dev/null 2>&1; then
        skip "nc (netcat) command not available"
    fi
    
    if ! command -v ssh >/dev/null 2>&1; then
        skip "ssh command not available"
    fi
}

load_helpers_if_available() {
    # Load bats helpers if available (optional)
    if [[ -f "test/libs/bats-assert/load.bash" ]]; then
        load "test/libs/bats-assert/load"
    fi
    
    if [[ -f "test/libs/bats-file/load.bash" ]]; then
        load "test/libs/bats-file/load"
    fi
}

# Helper functions for consistent testing
run_with_timeout() {
    local timeout_duration="$1"
    shift
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "$@"
    else
        # Fallback timeout implementation
        (
            "$@" &
            local pid=$!
            sleep "$timeout_duration" && kill $pid 2>/dev/null &
            local timeout_pid=$!
            wait $pid 2>/dev/null
            local exit_code=$?
            kill $timeout_pid 2>/dev/null
            exit $exit_code
        )
    fi
}

# Basic connectivity tests (equivalent to Pester Describe/Context)
@test "should ping Mac successfully" {
    # Equivalent to: Test-Connection -ComputerName $MacIP -Count 1
    run ping -c 1 -W 5 "$MAC_IP"
    
    # Assert success
    [ "$status" -eq 0 ]
    
    # Assert expected output patterns
    [[ "$output" =~ "1 packets transmitted, 1 received" ]] || 
    [[ "$output" =~ "1 packets transmitted, 1 packets received" ]]
}

@test "should resolve Mac hostname via ping" {
    # Test hostname resolution
    run ping -c 1 -W 5 "$MAC_HOSTNAME"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1 packet" ]]
}

@test "should connect to SSH port 22" {
    # Equivalent to: Test-NetConnection -ComputerName $MacIP -Port 22
    run run_with_timeout 10 nc -z "$MAC_IP" 22
    
    [ "$status" -eq 0 ]
}

@test "should connect to VNC port 5900" {
    # Test VNC port accessibility
    run run_with_timeout 5 nc -z "$MAC_IP" 5900
    
    [ "$status" -eq 0 ]
}

@test "should connect to SMB port 445" {
    # Test SMB file sharing port
    run run_with_timeout 5 nc -z "$MAC_IP" 445
    
    [ "$status" -eq 0 ]
}

@test "should have SSH client available" {
    # Verify SSH client exists and is functional
    run which ssh
    [ "$status" -eq 0 ]
    
    # Test SSH version output
    run ssh -V
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # SSH -V returns 1 on some systems
    [[ "$output" =~ "OpenSSH" ]] || [[ "$stderr" =~ "OpenSSH" ]]
}

@test "should establish SSH connection to Mac" {
    # Full SSH connection test - equivalent to comprehensive PowerShell SSH test
    run run_with_timeout 15 ssh -o ConnectTimeout=10 \
                              -o BatchMode=yes \
                              -o StrictHostKeyChecking=no \
                              -o UserKnownHostsFile=/dev/null \
                              "$MAC_USER@$MAC_IP" \
                              "echo 'SSH_TEST_SUCCESS'"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SSH_TEST_SUCCESS" ]]
}

@test "should get Mac system information via SSH" {
    # Test SSH command execution - more complex than basic connection
    run run_with_timeout 15 ssh -o ConnectTimeout=10 \
                              -o BatchMode=yes \
                              -o StrictHostKeyChecking=no \
                              -o UserKnownHostsFile=/dev/null \
                              "$MAC_USER@$MAC_IP" \
                              "hostname; uptime | head -1"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$MAC_HOSTNAME" ]]
    [[ "$output" =~ "up" ]]
}

# Performance and reliability tests
@test "should ping Mac with reasonable latency" {
    run ping -c 3 -W 5 "$MAC_IP"
    
    [ "$status" -eq 0 ]
    
    # Extract average ping time (macOS format)
    local ping_avg
    if [[ "$output" =~ avg[^0-9]*([0-9]+\.[0-9]+) ]]; then
        ping_avg="${BASH_REMATCH[1]}"
        # Ping should be less than 100ms (adjust threshold as needed)
        [ "$(echo "$ping_avg < 100" | bc -l 2>/dev/null || echo 1)" -eq 1 ]
    fi
}

@test "should handle connection timeout gracefully" {
    # Test timeout behavior with non-existent port
    run run_with_timeout 5 nc -z "$MAC_IP" 9999
    
    # Should fail (exit code != 0) but within timeout
    [ "$status" -ne 0 ]
}

# Integration test with orchestrator
@test "should work with orchestrator test-mac command" {
    # Test the full orchestrator integration
    local orchestrator_script="Scripts/orchestrator.sh"
    
    if [[ ! -x "$orchestrator_script" ]]; then
        skip "Orchestrator script not available or not executable"
    fi
    
    run run_with_timeout 120 "$orchestrator_script" test-mac
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AIMaster Universal Orchestrator" ]]
    [[ "$output" =~ "Service completed successfully" ]]
}

# Configuration and environment tests
@test "should have valid Mac connectivity configuration" {
    # Test that we have valid configuration
    [ -n "$MAC_IP" ]
    [ -n "$MAC_USER" ]
    [ -n "$MAC_HOSTNAME" ]
    
    # Basic IP format validation
    [[ "$MAC_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

@test "should have network connectivity" {
    # Basic internet connectivity test
    run ping -c 1 -W 5 8.8.8.8
    [ "$status" -eq 0 ]
}

# Teardown for cleanup if needed
teardown() {
    # Clean up any test artifacts if necessary
    # Currently no cleanup needed for these network tests
    :
}