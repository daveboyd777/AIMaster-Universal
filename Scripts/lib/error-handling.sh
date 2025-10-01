#!/bin/bash
# AIMaster Universal Orchestrator - Error Handling Library
# Robust error handling and recovery mechanisms

# Error handling configuration
ERROR_LOG_FILE=""
EXIT_ON_ERROR=true
STACK_TRACE_ENABLED=true
ERROR_RECOVERY_ENABLED=true
MAX_RETRY_ATTEMPTS=3
RETRY_DELAY=1

# Error tracking
declare -a ERROR_STACK=()
declare -a FUNCTION_STACK=()
LAST_ERROR_CODE=0
LAST_ERROR_MESSAGE=""
ERROR_COUNT=0

function init_error_handling() {
    local error_log="${1:-}"
    local exit_on_error="${2:-true}"
    
    ERROR_LOG_FILE="$error_log"
    EXIT_ON_ERROR="$exit_on_error"
    
    # Set up error trapping
    set -eE  # Exit on error and inherit error trap
    trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[@]}"' ERR
    trap 'cleanup_on_exit' EXIT
    
    # Set up debug trap for function tracking if stack trace is enabled
    if [[ "$STACK_TRACE_ENABLED" == "true" ]]; then
        trap 'track_function_entry' DEBUG
    fi
}

function handle_error() {
    local exit_code="$1"
    local line_number="$2"
    local bash_lineno="$3"
    local command="$4"
    shift 4
    local function_stack=("$@")
    
    LAST_ERROR_CODE="$exit_code"
    LAST_ERROR_MESSAGE="Command failed: $command"
    ((ERROR_COUNT++))
    
    # Build error context
    local error_context="Error in script $(basename "${BASH_SOURCE[1]}") at line $line_number"
    if [[ ${#function_stack[@]} -gt 1 ]]; then
        error_context="$error_context in function ${function_stack[1]}"
    fi
    
    # Log error details
    log_error "Error #$ERROR_COUNT: $error_context"
    log_error "Exit code: $exit_code"
    log_error "Failed command: $command"
    
    # Add to error stack
    ERROR_STACK+=("$error_context: $command (exit $exit_code)")
    
    # Write to error log if configured
    if [[ -n "$ERROR_LOG_FILE" ]]; then
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR #$ERROR_COUNT"
            echo "Context: $error_context"
            echo "Exit Code: $exit_code"
            echo "Command: $command"
            echo "Line: $line_number"
            if [[ "$STACK_TRACE_ENABLED" == "true" ]]; then
                echo "Function Stack: ${function_stack[*]}"
                echo "Call Stack:"
                print_stack_trace
            fi
            echo "---"
        } >> "$ERROR_LOG_FILE"
    fi
    
    # Print stack trace if enabled
    if [[ "$STACK_TRACE_ENABLED" == "true" ]]; then
        print_stack_trace
    fi
    
    # Attempt error recovery if enabled
    if [[ "$ERROR_RECOVERY_ENABLED" == "true" ]]; then
        if attempt_error_recovery "$exit_code" "$command"; then
            log_success "Error recovery successful"
            return 0
        fi
    fi
    
    # Exit if configured to do so
    if [[ "$EXIT_ON_ERROR" == "true" ]]; then
        log_error "Exiting due to error (EXIT_ON_ERROR=true)"
        exit "$exit_code"
    fi
    
    return "$exit_code"
}

function track_function_entry() {
    local current_function="${FUNCNAME[1]:-main}"
    
    # Only track actual function calls, not every line
    if [[ "${#FUNCNAME[@]}" -gt "${#FUNCTION_STACK[@]}" ]]; then
        FUNCTION_STACK+=("$current_function")
    fi
}

function print_stack_trace() {
    log_error "Stack trace:"
    
    local i
    for ((i=${#BASH_SOURCE[@]}-1; i>=1; i--)); do
        local file="${BASH_SOURCE[i]}"
        local line="${BASH_LINENO[i-1]}"
        local func="${FUNCNAME[i]}"
        
        if [[ -n "$func" && "$func" != "main" ]]; then
            log_error "  at $func() in $(basename "$file"):$line"
        else
            log_error "  at $(basename "$file"):$line"
        fi
    done
}

function attempt_error_recovery() {
    local exit_code="$1"
    local failed_command="$2"
    
    log_info "Attempting error recovery for: $failed_command"
    
    # Common recovery strategies based on exit codes
    case "$exit_code" in
        1)
            log_debug "General error - attempting basic recovery"
            return 1  # No specific recovery for general errors
            ;;
        2)
            log_debug "Command not found or invalid usage"
            # Could attempt to install missing command or fix syntax
            return 1
            ;;
        126)
            log_debug "Permission denied or not executable"
            if [[ "$failed_command" =~ \.sh$ ]]; then
                log_info "Attempting to make script executable"
                chmod +x "$failed_command" 2>/dev/null && return 0
            fi
            return 1
            ;;
        127)
            log_debug "Command not found"
            # Could attempt to install missing command
            return 1
            ;;
        130)
            log_debug "Script terminated by Ctrl+C"
            return 1  # User interruption - don't recover
            ;;
        *)
            log_debug "Unknown error code: $exit_code"
            return 1
            ;;
    esac
}

function safe_execute() {
    local command="$1"
    local max_attempts="${2:-$MAX_RETRY_ATTEMPTS}"
    local retry_delay="${3:-$RETRY_DELAY}"
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Executing (attempt $attempt/$max_attempts): $command"
        
        if eval "$command"; then
            log_debug "Command succeeded on attempt $attempt"
            return 0
        else
            local exit_code=$?
            log_warn "Command failed on attempt $attempt with exit code $exit_code"
            
            if [[ $attempt -lt $max_attempts ]]; then
                log_info "Retrying in ${retry_delay}s..."
                sleep "$retry_delay"
                ((attempt++))
                
                # Exponential backoff
                retry_delay=$((retry_delay * 2))
            else
                log_error "Command failed after $max_attempts attempts"
                return $exit_code
            fi
        fi
    done
}

function safe_source() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        log_error "Cannot source file - not found: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        log_error "Cannot source file - not readable: $file"
        return 1
    fi
    
    log_debug "Sourcing file: $file"
    
    # Source with error handling
    if source "$file"; then
        log_debug "Successfully sourced: $file"
        return 0
    else
        local exit_code=$?
        log_error "Failed to source file: $file (exit code: $exit_code)"
        return $exit_code
    fi
}

function safe_cd() {
    local directory="$1"
    
    if [[ ! -d "$directory" ]]; then
        log_error "Directory does not exist: $directory"
        return 1
    fi
    
    log_debug "Changing directory to: $directory"
    
    if cd "$directory"; then
        log_debug "Successfully changed to: $(pwd)"
        return 0
    else
        local exit_code=$?
        log_error "Failed to change directory to: $directory"
        return $exit_code
    fi
}

function safe_mkdir() {
    local directory="$1"
    local mode="${2:-755}"
    
    if [[ -d "$directory" ]]; then
        log_debug "Directory already exists: $directory"
        return 0
    fi
    
    log_debug "Creating directory: $directory"
    
    if mkdir -p "$directory"; then
        chmod "$mode" "$directory" 2>/dev/null || true
        log_debug "Successfully created directory: $directory"
        return 0
    else
        local exit_code=$?
        log_error "Failed to create directory: $directory"
        return $exit_code
    fi
}

function safe_remove() {
    local path="$1"
    local force="${2:-false}"
    
    if [[ ! -e "$path" ]]; then
        log_debug "Path does not exist (nothing to remove): $path"
        return 0
    fi
    
    log_debug "Removing: $path"
    
    local rm_cmd="rm"
    [[ "$force" == "true" ]] && rm_cmd="rm -f"
    [[ -d "$path" ]] && rm_cmd="rm -rf"
    
    if $rm_cmd "$path"; then
        log_debug "Successfully removed: $path"
        return 0
    else
        local exit_code=$?
        log_error "Failed to remove: $path"
        return $exit_code
    fi
}

function check_prerequisites() {
    local -a required_commands=("$@")
    local missing_commands=()
    
    log_debug "Checking prerequisites: ${required_commands[*]}"
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        
        # Suggest installation based on platform
        local platform=$(detect_platform 2>/dev/null || echo "unknown")
        local package_manager=$(detect_package_manager 2>/dev/null || echo "unknown")
        
        if [[ "$package_manager" != "unknown" && "$package_manager" != "none" ]]; then
            log_info "Try installing with: $package_manager install ${missing_commands[*]}"
        fi
        
        return 1
    fi
    
    log_debug "All prerequisites satisfied"
    return 0
}

function validate_file() {
    local file="$1"
    local check_readable="${2:-true}"
    local check_executable="${3:-false}"
    
    if [[ ! -f "$file" ]]; then
        log_error "File does not exist: $file"
        return 1
    fi
    
    if [[ "$check_readable" == "true" && ! -r "$file" ]]; then
        log_error "File is not readable: $file"
        return 1
    fi
    
    if [[ "$check_executable" == "true" && ! -x "$file" ]]; then
        log_error "File is not executable: $file"
        return 1
    fi
    
    log_debug "File validation passed: $file"
    return 0
}

function validate_directory() {
    local directory="$1"
    local check_writable="${2:-false}"
    
    if [[ ! -d "$directory" ]]; then
        log_error "Directory does not exist: $directory"
        return 1
    fi
    
    if [[ ! -r "$directory" ]]; then
        log_error "Directory is not readable: $directory"
        return 1
    fi
    
    if [[ "$check_writable" == "true" && ! -w "$directory" ]]; then
        log_error "Directory is not writable: $directory"
        return 1
    fi
    
    log_debug "Directory validation passed: $directory"
    return 0
}

function get_error_summary() {
    cat << EOF
Error Summary:
==============
Total Errors: $ERROR_COUNT
Last Error Code: $LAST_ERROR_CODE
Last Error Message: $LAST_ERROR_MESSAGE

Recent Errors:
EOF
    
    local i
    local start_index=$((${#ERROR_STACK[@]} - 5))  # Show last 5 errors
    [[ $start_index -lt 0 ]] && start_index=0
    
    for ((i=start_index; i<${#ERROR_STACK[@]}; i++)); do
        echo "  $((i+1)). ${ERROR_STACK[i]}"
    done
}

function reset_error_state() {
    ERROR_STACK=()
    FUNCTION_STACK=()
    LAST_ERROR_CODE=0
    LAST_ERROR_MESSAGE=""
    ERROR_COUNT=0
    
    log_debug "Error state reset"
}

function disable_error_handling() {
    set +eE
    trap - ERR
    trap - DEBUG
    log_debug "Error handling disabled"
}

function enable_error_handling() {
    set -eE
    trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[@]}"' ERR
    
    if [[ "$STACK_TRACE_ENABLED" == "true" ]]; then
        trap 'track_function_entry' DEBUG
    fi
    
    log_debug "Error handling enabled"
}

function cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exiting with error code: $exit_code"
        
        if [[ $ERROR_COUNT -gt 0 ]]; then
            get_error_summary
        fi
    else
        log_debug "Script completed successfully"
    fi
    
    # Cleanup logging if available
    if command -v cleanup_logging >/dev/null 2>&1; then
        cleanup_logging
    fi
    
    return $exit_code
}

function set_error_config() {
    local config_name="$1"
    local config_value="$2"
    
    case "$config_name" in
        "exit_on_error"|"EXIT_ON_ERROR")
            EXIT_ON_ERROR="$config_value"
            ;;
        "stack_trace"|"STACK_TRACE_ENABLED")
            STACK_TRACE_ENABLED="$config_value"
            ;;
        "error_recovery"|"ERROR_RECOVERY_ENABLED")
            ERROR_RECOVERY_ENABLED="$config_value"
            ;;
        "max_retry"|"MAX_RETRY_ATTEMPTS")
            MAX_RETRY_ATTEMPTS="$config_value"
            ;;
        "retry_delay"|"RETRY_DELAY")
            RETRY_DELAY="$config_value"
            ;;
        *)
            log_warn "Unknown error configuration: $config_name"
            return 1
            ;;
    esac
    
    log_debug "Error config updated: $config_name=$config_value"
}