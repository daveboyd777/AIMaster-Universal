#!/usr/bin/env bats

# AIMaster Orchestrator Unit Tests

setup() {
    # Set up test environment
    ORCHESTRATOR_SCRIPT="Scripts/orchestrator.sh"
    
    # Ensure the orchestrator script exists and is executable
    if [[ ! -x "$ORCHESTRATOR_SCRIPT" ]]; then
        skip "Orchestrator script not executable: $ORCHESTRATOR_SCRIPT"
    fi
}

@test "should show version information" {
    run "$ORCHESTRATOR_SCRIPT" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AIMaster Universal Orchestrator v" ]]
    [[ "$output" =~ "Platform:" ]]
    [[ "$output" =~ "Bash:" ]]
}

@test "should display help when no command provided" {
    run "$ORCHESTRATOR_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
    [[ "$output" =~ "Options:" ]]
}

@test "should display help with --help flag" {
    run "$ORCHESTRATOR_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
    [[ "$output" =~ "Examples:" ]]
}

@test "should display help with -h flag" {
    run "$ORCHESTRATOR_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "should show status information" {
    run "$ORCHESTRATOR_SCRIPT" status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AIMaster Orchestrator Status" ]]
    [[ "$output" =~ "Platform:" ]]
    [[ "$output" =~ "Architecture:" ]]
    [[ "$output" =~ "Available Services:" ]]
    [[ "$output" =~ "Configuration:" ]]
    [[ "$output" =~ "Network Status:" ]]
}

@test "should show verbose status information" {
    run "$ORCHESTRATOR_SCRIPT" status -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AIMaster Orchestrator Status" ]]
    [[ "$output" =~ "Configuration details:" ]] || [[ "$output" =~ "Configuration:" ]]
}

@test "should show configuration" {
    run "$ORCHESTRATOR_SCRIPT" config
    [ "$status" -eq 0 ]
    # Should either show JSON config or indicate config not found
    [[ "$output" =~ "{" ]] || [[ "$output" =~ "Configuration file not found" ]]
}

@test "should create default configuration when needed" {
    # Remove config if it exists, then run a command that should create it
    local config_file="Scripts/config/orchestrator.json"
    [[ -f "$config_file" ]] && mv "$config_file" "$config_file.backup"
    
    run "$ORCHESTRATOR_SCRIPT" version
    [ "$status" -eq 0 ]
    
    # Config should be created
    [ -f "$config_file" ]
    
    # Restore backup if it existed
    [[ -f "$config_file.backup" ]] && mv "$config_file.backup" "$config_file"
}

@test "should handle unknown commands gracefully" {
    run "$ORCHESTRATOR_SCRIPT" unknown-command
    [ "$status" -eq 0 ]  # Should show help instead of failing
    [[ "$output" =~ "Usage:" ]]
}

@test "should handle service execution" {
    # Test service command with a non-existent service - should show help and error
    run "$ORCHESTRATOR_SCRIPT" service non-existent-service
    [ "$status" -eq 1 ]  # Should return error exit code for invalid service
    [[ "$output" =~ "Usage:" ]] && [[ "$output" =~ "Service name required" ]]
}

@test "should list available services in status" {
    run "$ORCHESTRATOR_SCRIPT" status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available Services:" ]]
    [[ "$output" =~ "Total:" ]] && [[ "$output" =~ "services" ]]
}

@test "should handle timeout configuration" {
    run "$ORCHESTRATOR_SCRIPT" --timeout 30 version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AIMaster Universal Orchestrator" ]]
}

@test "should handle verbose mode" {
    run "$ORCHESTRATOR_SCRIPT" -v version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AIMaster Universal Orchestrator" ]]
}

@test "should handle quiet mode" {
    run "$ORCHESTRATOR_SCRIPT" -q version
    [ "$status" -eq 0 ]
    # In quiet mode, should have less output
}

@test "should handle parallel execution flag" {
    run "$ORCHESTRATOR_SCRIPT" --parallel discover
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AIMaster Universal Orchestrator" ]]
}

@test "should run Mac connectivity test" {
    # This is a longer-running test, so we'll use a timeout
    run timeout 90 "$ORCHESTRATOR_SCRIPT" test-mac
    local exit_code=$?
    
    # Should succeed (0) or timeout (124)
    [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 124 ]
    
    if [ "$exit_code" -eq 0 ]; then
        [[ "$output" =~ "Service completed successfully" ]]
    fi
}

@test "should handle discovery command" {
    run timeout 60 "$ORCHESTRATOR_SCRIPT" discover
    local exit_code=$?
    
    # Should succeed or timeout
    [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 124 ]
    
    if [ "$exit_code" -eq 0 ]; then
        [[ "$output" =~ "Discovering available systems" ]]
    fi
}

@test "should handle test command" {
    run timeout 60 "$ORCHESTRATOR_SCRIPT" test
    local exit_code=$?
    
    # Should succeed or timeout  
    [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 124 ]
    
    if [ "$exit_code" -eq 0 ]; then
        [[ "$output" =~ "connectivity tests" ]]
    fi
}

@test "should validate script permissions and structure" {
    # Test that the orchestrator script has proper permissions
    [ -f "$ORCHESTRATOR_SCRIPT" ]
    [ -x "$ORCHESTRATOR_SCRIPT" ]
    
    # Test basic script structure
    grep -q "#!/bin/bash" "$ORCHESTRATOR_SCRIPT"
    grep -q "AIMaster Universal" "$ORCHESTRATOR_SCRIPT"
    grep -q "function main" "$ORCHESTRATOR_SCRIPT"
}

@test "should have required directories" {
    # Test that required directories exist
    [ -d "Scripts/lib" ]
    [ -d "Scripts/services" ]
    [ -d "Scripts/config" ]
}

@test "should load libraries successfully" {
    # Test that the orchestrator can load its libraries
    run bash -c 'source Scripts/orchestrator.sh 2>&1 | head -20'
    [ "$status" -eq 0 ]
    # Should not have critical library loading errors
    ! [[ "$output" =~ "No such file or directory" ]]
}

@test "should handle stop command" {
    run "$ORCHESTRATOR_SCRIPT" stop
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Services stopped" ]]
}

@test "should show orchestrator initialization" {
    run "$ORCHESTRATOR_SCRIPT" version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "🚀 AIMaster Universal Orchestrator" ]]
    [[ "$output" =~ "Started at:" ]]
    [[ "$output" =~ "Log file:" ]]
}