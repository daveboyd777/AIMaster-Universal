#!/bin/bash
# AIMaster Universal Cross-Platform Orchestrator
# Main orchestration engine for cross-platform operations
# Replaces PowerShell-based orchestration with bash

# set -euo pipefail  # Strict error handling - disabled for debugging

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
SERVICES_DIR="$SCRIPT_DIR/services"
CONFIG_DIR="$SCRIPT_DIR/config"
LOGS_DIR="$HOME/.aimaster/logs"

# Ensure directories exist
mkdir -p "$LOGS_DIR"

# Fallback logging functions in case libraries fail to load
function fallback_log() { echo "[$(date '+%H:%M:%S')] $1: $2"; }
function log_info() { fallback_log "INFO" "$1"; }
function log_error() { fallback_log "ERROR" "$1" >&2; }
function log_success() { fallback_log "SUCCESS" "$1"; }
function log_warn() { fallback_log "WARN" "$1"; }
function log_debug() { [[ "${VERBOSE:-false}" == "true" ]] && fallback_log "DEBUG" "$1"; }

# Load core libraries (with error handling)
for lib in "logging.sh" "platform-detection.sh" "error-handling.sh" "json-utils.sh" "network-utils.sh"; do
    if [[ -f "$LIB_DIR/$lib" ]]; then
        if source "$LIB_DIR/$lib" 2>/dev/null; then
            log_debug "Loaded library: $lib"
        else
            log_warn "Failed to load library: $lib"
        fi
    else
        log_warn "Library not found: $lib"
    fi
done

# Fallback implementations for missing functions
if ! command -v detect_platform >/dev/null 2>&1; then
    function detect_platform() { echo "${OSTYPE:-unknown}"; }
fi
if ! command -v detect_architecture >/dev/null 2>&1; then
    function detect_architecture() { uname -m 2>/dev/null || echo "unknown"; }
fi
if ! command -v check_internet_connectivity >/dev/null 2>&1; then
    function check_internet_connectivity() { ping -c 1 google.com >/dev/null 2>&1; }
fi
if ! command -v init_logging >/dev/null 2>&1; then
    function init_logging() { log_debug "Using fallback logging"; }
fi

# Cross-platform timeout function
function run_with_timeout() {
    local timeout_duration="$1"
    shift
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "$@"
    else
        # Fallback for macOS without GNU coreutils
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

# Global configuration
ORCHESTRATOR_VERSION="2.0.0"
LOG_FILE="$LOGS_DIR/orchestrator_$(date +%Y%m%d_%H%M%S).log"
CONFIG_FILE="$CONFIG_DIR/orchestrator.json"

# Initialize logging
init_logging "$LOG_FILE"

# CI3 Framework Integration
CI3_ENABLED=${CI3_ENABLED:-false}
if [[ "$CI3_ENABLED" == "true" ]]; then
    if [[ -f "$LIB_DIR/ci3-core.sh" ]]; then
        source "$LIB_DIR/ci3-core.sh"
        log_info "🌌 I3/Atlas Framework integration enabled (inspired by interstellar comet I3/Atlas)"
    else
        log_warn "⚠️ CI3 Framework requested but ci3-core.sh not found"
    fi
fi

function show_usage() {
    cat << EOF
AIMaster Universal Cross-Platform Orchestrator v$ORCHESTRATOR_VERSION

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    start               Start the orchestrator
    stop                Stop all services
    status              Show system status
    test                Run connectivity tests
    service <name>      Run specific service
    discover            Discover available systems
    config              Show configuration
    version             Show version info

Service Commands:
    test-mac           Test Mac connectivity
    test-room504       Test Room504 PC tunneling
    find-glinet        Find GL-iNet router WiFi networks
    test-windows       Test Windows connectivity  
    test-linux         Test Linux connectivity
    test-android       Test Android connectivity

I3/Atlas Framework Commands (when enabled):
    ci3-status         Show I3/Atlas framework status
    ci3-init           Initialize I3/Atlas framework
    atlas-analyze      Analyze network topology (inspired by ATLAS observatory)
    scale-transition   Transition between cosmic scales (like comet trajectory analysis)
    3i-analysis        Run I3 analysis (exploring possible interstellar intelligence patterns)
    glinet-ci3         GL-iNet management with I3/Atlas enhancement

Options:
    -h, --help         Show this help
    -v, --verbose      Verbose logging
    -q, --quiet        Quiet mode
    -c, --config FILE  Use custom config file
    --parallel         Run services in parallel
    --timeout N        Set timeout in seconds

Examples:
    $0 start                    # Start orchestrator
    $0 test-mac                # Test Mac connectivity
    $0 service mac-connectivity # Run Mac service
    $0 discover --parallel     # Discover all systems
    $0 status -v               # Verbose status check

EOF
}

function init_orchestrator() {
    log_info "🚀 AIMaster Universal Orchestrator v$ORCHESTRATOR_VERSION"
    log_info "Platform: $(detect_platform)"
    log_info "Architecture: $(detect_architecture)"
    log_info "Started at: $(date)"
    log_info "Log file: $LOG_FILE"
    
    # Create default config if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi
}

function create_default_config() {
    log_info "Creating default configuration..."
    
    cat > "$CONFIG_FILE" << EOF
{
    "orchestrator": {
        "version": "$ORCHESTRATOR_VERSION",
        "platform": "$(detect_platform)",
        "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "log_level": "INFO",
        "parallel_execution": true,
        "timeout_seconds": 30
    },
    "services": {
        "mac_connectivity": {
            "enabled": true,
            "script": "mac-connectivity.sh",
            "timeout": 60,
            "retry_count": 3
        },
        "windows_management": {
            "enabled": true,
            "script": "windows-management.sh", 
            "timeout": 45,
            "retry_count": 2
        },
        "linux_operations": {
            "enabled": true,
            "script": "linux-operations.sh",
            "timeout": 30,
            "retry_count": 2
        },
        "android_integration": {
            "enabled": false,
            "script": "android-integration.sh",
            "timeout": 90,
            "retry_count": 1
        }
    },
    "targets": {
        "mac": {
            "ip_address": "100.77.255.169",
            "username": "daveboyd", 
            "hostname": "sf-Deb-Book.local"
        },
        "windows": {
            "ip_address": "",
            "username": "",
            "hostname": ""
        }
    }
}
EOF
    
    log_success "Default configuration created: $CONFIG_FILE"
}

function run_service() {
    local service_name="$1"
    local service_script="$SERVICES_DIR/$service_name"
    
    if [[ ! -f "$service_script" ]]; then
        log_error "Service script not found: $service_script"
        return 1
    fi
    
    if [[ ! -x "$service_script" ]]; then
        log_warn "Making service script executable: $service_script"
        chmod +x "$service_script"
    fi
    
    log_info "Running service: $service_name"
    
    # Run service with timeout and capture output
    if run_with_timeout "${TIMEOUT:-60}" "$service_script" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Service completed successfully: $service_name"
        return 0
    else
        local exit_code=$?
        log_error "Service failed with code $exit_code: $service_name"
        return $exit_code
    fi
}

function discover_systems() {
    local parallel_mode="${1:-false}"
    
    log_info "🔍 Discovering available systems..."
    
    local services=(
        "mac-connectivity.sh"
        "startup-test-mac-connectivity.sh"
        "test-room504-tunneling.sh"
    )
    
    if [[ "$parallel_mode" == "true" ]]; then
        log_info "Running discovery in parallel mode"
        
        for service in "${services[@]}"; do
            if [[ -f "$SERVICES_DIR/$service" ]]; then
                run_service "$service" &
            fi
        done
        
        # Wait for all background jobs
        wait
        log_info "Parallel discovery completed"
    else
        log_info "Running discovery in sequential mode"
        
        for service in "${services[@]}"; do
            if [[ -f "$SERVICES_DIR/$service" ]]; then
                run_service "$service"
            fi
        done
    fi
}

function show_status() {
    local verbose="${1:-false}"
    
    log_info "📊 AIMaster Orchestrator Status"
    echo "================================"
    
    # System information
    echo "Platform: $(detect_platform)"
    echo "Architecture: $(detect_architecture)"
    echo "Bash Version: $BASH_VERSION"
    echo "Script Directory: $SCRIPT_DIR"
    echo "Config File: $CONFIG_FILE"
    echo "Log File: $LOG_FILE"
    echo
    
    # Available services
    echo "Available Services:"
    if [[ -d "$SERVICES_DIR" ]]; then
        local service_count=0
        for service in "$SERVICES_DIR"/*.sh; do
            if [[ -f "$service" ]]; then
                local service_name=$(basename "$service")
                local executable_status="❌"
                [[ -x "$service" ]] && executable_status="✅"
                echo "  $executable_status $service_name"
                ((service_count++))
            fi
        done
        echo "  Total: $service_count services"
    else
        echo "  No services directory found"
    fi
    
    echo
    
    # Configuration status
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "✅ Configuration: Present"
        if [[ "$verbose" == "true" ]]; then
            echo "Configuration details:"
            if command -v jq >/dev/null 2>&1; then
                jq . "$CONFIG_FILE" 2>/dev/null || cat "$CONFIG_FILE"
            else
                cat "$CONFIG_FILE"
            fi
        fi
    else
        echo "❌ Configuration: Missing"
    fi
    
    echo
    
    # Network connectivity check
    echo "Network Status:"
    if check_internet_connectivity; then
        echo "  ✅ Internet connectivity"
    else
        echo "  ❌ Internet connectivity"
    fi
    
    # Quick Mac connectivity test
    if [[ -f "$SERVICES_DIR/startup-test-mac-connectivity.sh" ]]; then
        echo "  🧪 Testing Mac connectivity..."
        if run_with_timeout 10 "$SERVICES_DIR/startup-test-mac-connectivity.sh" >/dev/null 2>&1; then
            echo "  ✅ Mac connectivity test passed"
        else
            echo "  ❌ Mac connectivity test failed"
        fi
    fi
}

# Main execution logic
function main() {
    local command="${1:-help}"
    local verbose=false
    local quiet=false
    local parallel=false
    local timeout=""
    local -a remaining_args=()
    
    # Parse options and collect remaining arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                export VERBOSE=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                export QUIET=true
                shift
                ;;
            --parallel)
                parallel=true
                shift
                ;;
            --timeout)
                timeout="$2"
                export TIMEOUT="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            *)
                if [[ "$command" == "help" ]]; then
                    command="$1"
                elif [[ -z "$command" ]]; then
                    command="$1"
                else
                    remaining_args+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Initialize orchestrator
    init_orchestrator
    
    # Execute command
    case "$command" in
        start)
            log_info "Starting AIMaster Orchestrator..."
            discover_systems "$parallel"
            ;;
        stop)
            log_info "Stopping orchestrator services..."
            # Kill any background services
            jobs -p | xargs -r kill 2>/dev/null || true
            log_success "Services stopped"
            ;;
        status)
            show_status "$verbose"
            ;;
        test)
            log_info "Running connectivity tests..."
            discover_systems "$parallel"
            ;;
        test-mac)
            run_service "startup-test-mac-connectivity.sh"
            ;;
        test-room504)
            run_service "test-room504-tunneling.sh"
            ;;
        find-glinet)
            run_service "list-wifi-networks.sh"
            ;;
        test-windows)
            log_warn "Windows testing not yet implemented"
            ;;
        test-linux)
            log_warn "Linux testing not yet implemented"
            ;;
        test-android)
            log_warn "Android testing not yet implemented"
            ;;
        service)
            local service_name="${2:-}"
            if [[ -z "$service_name" ]]; then
                log_error "Service name required"
                show_usage
                exit 1
            fi
            run_service "$service_name"
            ;;
        discover)
            discover_systems "$parallel"
            ;;
        config)
            if [[ -f "$CONFIG_FILE" ]]; then
                if command -v jq >/dev/null 2>&1; then
                    jq . "$CONFIG_FILE"
                else
                    cat "$CONFIG_FILE"
                fi
            else
                log_error "Configuration file not found: $CONFIG_FILE"
                exit 1
            fi
            ;;
        version)
            echo "AIMaster Universal Orchestrator v$ORCHESTRATOR_VERSION"
            echo "Platform: $(detect_platform)"
            echo "Bash: $BASH_VERSION"
            if [[ "$CI3_ENABLED" == "true" ]]; then
                echo "I3/Atlas Framework: $(get_ci3_info status 2>/dev/null || echo 'available (inspired by interstellar comet I3/Atlas)')"
            fi
            ;;
        # CI3 Framework Commands
        ci3-status)
            if [[ "$CI3_ENABLED" == "true" ]]; then
                # Auto-initialize if needed
                if ! command -v show_ci3_status >/dev/null 2>&1; then
                    init_ci3_framework "$CONFIG_DIR/ci3.json" false
                    if command -v export_ci3_functions >/dev/null 2>&1; then
                        export_ci3_functions
                    fi
                fi
                
                if command -v show_ci3_status >/dev/null 2>&1; then
                    show_ci3_status
                else
                    log_error "I3/Atlas Framework functions not available after initialization"
                    exit 1
                fi
            else
                log_error "I3/Atlas Framework not enabled or not available"
                log_info "To enable I3/Atlas: export CI3_ENABLED=true"
                exit 1
            fi
            ;;
        ci3-init)
            if [[ "$CI3_ENABLED" == "true" ]] && command -v init_ci3_framework >/dev/null 2>&1; then
                init_ci3_framework "$CONFIG_DIR/ci3.json" true
                
                # Export CI3 functions for use within orchestrator
                if command -v export_ci3_functions >/dev/null 2>&1; then
                    export_ci3_functions
                else
                    log_warn "⚠️ Warning: export_ci3_functions not available"
                fi
            else
                log_error "I3/Atlas Framework not enabled or not available"
                exit 1
            fi
            ;;
        atlas-analyze)
            if [[ "$CI3_ENABLED" == "true" ]]; then
                # Auto-initialize if needed
                if ! command -v analyze_network_topology >/dev/null 2>&1; then
                    init_ci3_framework "$CONFIG_DIR/ci3.json" false
                    if command -v export_ci3_functions >/dev/null 2>&1; then
                        export_ci3_functions
                    fi
                fi
                
                if command -v analyze_network_topology >/dev/null 2>&1; then
                    local network_data="$(discover_systems false 2>/dev/null || echo '')"
                    analyze_network_topology "$network_data" "comprehensive"
                else
                    log_error "I3/Atlas Engine not available after initialization"
                    exit 1
                fi
            else
                log_error "I3/Atlas Framework not enabled"
                log_info "To enable I3/Atlas: export CI3_ENABLED=true"
                exit 1
            fi
            ;;
        scale-transition)
            if [[ "$CI3_ENABLED" == "true" ]]; then
                # Auto-initialize if needed
                if ! command -v transition_scale >/dev/null 2>&1; then
                    init_ci3_framework "$CONFIG_DIR/ci3.json" false
                    if command -v export_ci3_functions >/dev/null 2>&1; then
                        export_ci3_functions
                    fi
                fi
                
                if command -v transition_scale >/dev/null 2>&1; then
                    # Handle additional arguments properly
                    log_debug "Debug: remaining_args=(${remaining_args[*]})"
                    local target_scale="${remaining_args[0]:-ecosystem}"
                    local operation_type="${remaining_args[1]:-analysis}"
                    log_debug "Debug: target_scale='$target_scale', operation_type='$operation_type'"
                    transition_scale "$target_scale" "$operation_type"
                else
                    log_error "I3/Atlas Scale Manager not available after initialization"
                    exit 1
                fi
            else
                log_error "I3/Atlas Framework not enabled"
                log_info "To enable I3/Atlas: export CI3_ENABLED=true"
                exit 1
            fi
            ;;
        3i-analysis)
            if [[ "$CI3_ENABLED" == "true" ]]; then
                # Auto-initialize if needed
                if ! command -v analyze_network_intelligence >/dev/null 2>&1; then
                    init_ci3_framework "$CONFIG_DIR/ci3.json" false
                    if command -v export_ci3_functions >/dev/null 2>&1; then
                        export_ci3_functions
                    fi
                fi
                
                if command -v analyze_network_intelligence >/dev/null 2>&1; then
                    local network_data="$(discover_systems false 2>/dev/null || echo '')"
                    analyze_network_intelligence "$network_data"
                else
                    log_error "I3/Atlas Intelligence Framework not available after initialization"
                    exit 1
                fi
            else
                log_error "I3/Atlas Framework not enabled"
                log_info "To enable I3/Atlas: export CI3_ENABLED=true"
                exit 1
            fi
            ;;
        glinet-ci3)
            if [[ "$CI3_ENABLED" == "true" ]]; then
                log_info "🌌 GL-iNet management with I3/Atlas enhancement (cosmic-scale network analysis)"
                # Apply ecosystem perspective to GL-iNet operations
                transition_scale "ecosystem" "glinet_management" 2>/dev/null || true
                run_service "list-wifi-networks.sh"
            else
                log_error "I3/Atlas Framework not enabled"
                exit 1
            fi
            ;;
        help|*)
            show_usage
            ;;
    esac
}

# Handle script termination
trap cleanup EXIT INT TERM

function cleanup() {
    log_info "Orchestrator shutting down..."
    # Kill any background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
}

# Run main function with all arguments
main "$@"