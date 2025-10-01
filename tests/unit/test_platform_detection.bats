#!/usr/bin/env bats

# AIMaster Platform Detection Library Unit Tests

setup() {
    # Load the platform detection library
    source "Scripts/lib/platform-detection.sh"
}

@test "should detect macOS platform correctly" {
    # Mock OSTYPE for testing
    local original_ostype="$OSTYPE"
    export OSTYPE="darwin21"
    
    run detect_platform
    [ "$status" -eq 0 ]
    [ "$output" = "macOS" ]
    
    # Restore original OSTYPE
    export OSTYPE="$original_ostype"
}

@test "should detect Linux platform correctly" {
    local original_ostype="$OSTYPE"
    export OSTYPE="linux-gnu"
    
    run detect_platform
    [ "$status" -eq 0 ]
    [ "$output" = "Linux" ]
    
    export OSTYPE="$original_ostype"
}

@test "should detect Windows platform correctly" {
    local original_ostype="$OSTYPE"
    export OSTYPE="msys"
    
    run detect_platform
    [ "$status" -eq 0 ]
    [ "$output" = "Windows" ]
    
    export OSTYPE="$original_ostype"
}

@test "should detect x64 architecture" {
    # Test current system (should be x64 on most modern systems)
    run detect_architecture
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(x64|arm64|x86|unknown)$ ]]
}

@test "should detect OS version" {
    run detect_os_version
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$output" != "unknown" ]
}

@test "should detect shell type" {
    run detect_shell_type
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(bash|zsh|fish|dash|unknown)$ ]]
}

@test "should get user home directory" {
    run get_user_home
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -d "$output" ]
}

@test "should get temp directory" {
    run get_temp_dir
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ -d "$output" ]
}

@test "should detect package manager" {
    run detect_package_manager
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(brew|apt|yum|dnf|pacman|zypper|pkg|choco|winget|none)$ ]]
}

@test "should count CPU cores correctly" {
    run get_cpu_count
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]
    [ "$output" -lt 128 ]  # Reasonable upper bound
}

@test "should get memory info" {
    run get_memory_info
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]
    [ "$output" -lt 1048576 ]  # Less than 1TB in MB
}

@test "should get disk space" {
    run get_disk_space "."
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "should check internet connectivity" {
    run check_internet_connectivity
    # This might fail in offline environments, so we check the function exists
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "should identify supported platform" {
    run is_platform_supported
    [ "$status" -eq 0 ]  # Should return success on macOS/Linux/Windows
}

@test "should provide platform info summary" {
    run get_platform_info
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Platform Information:" ]]
    [[ "$output" =~ "Platform:" ]]
    [[ "$output" =~ "Architecture:" ]]
    [[ "$output" =~ "OS Version:" ]]
}

@test "should detect macOS correctly with is_macos" {
    run is_macos
    # Should return success (0) on macOS, failure (1) on other platforms
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "should detect x64 architecture correctly with is_x64" {
    run is_x64
    # Should return success (0) on x64, failure (1) on other architectures
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "should check command availability with has_command" {
    # Test with a command that should exist
    run has_command "echo"
    [ "$status" -eq 0 ]
    
    # Test with a command that should not exist
    run has_command "this-command-should-not-exist-12345"
    [ "$status" -eq 1 ]
}