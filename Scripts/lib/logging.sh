#!/bin/bash
# AIMaster Universal Orchestrator - Logging Library
# Cross-platform logging functionality with colors and structured output

# Color definitions for different platforms
if [[ "$OSTYPE" =~ ^darwin ]]; then
    # macOS colors
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly MAGENTA='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly GRAY='\033[0;37m'
    readonly NC='\033[0m' # No Color
else
    # Linux/Windows colors
    readonly RED='\e[31m'
    readonly GREEN='\e[32m'
    readonly YELLOW='\e[33m'
    readonly BLUE='\e[34m'
    readonly MAGENTA='\e[35m'
    readonly CYAN='\e[36m'
    readonly WHITE='\e[37m'
    readonly GRAY='\e[90m'
    readonly NC='\e[0m' # No Color
fi

# Log levels
readonly LOG_LEVEL_ERROR=0
readonly LOG_LEVEL_WARN=1
readonly LOG_LEVEL_INFO=2
readonly LOG_LEVEL_DEBUG=3

# Global logging configuration
CURRENT_LOG_LEVEL=${LOG_LEVEL_INFO}
LOG_FILE=""
ENABLE_COLORS=true
ENABLE_TIMESTAMPS=true
LOG_TO_FILE=false
LOG_TO_CONSOLE=true

# Emoji/symbol definitions for different log levels
readonly EMOJI_ERROR="❌"
readonly EMOJI_WARN="⚠️"
readonly EMOJI_INFO="ℹ️"
readonly EMOJI_SUCCESS="✅"
readonly EMOJI_DEBUG="🐛"
readonly EMOJI_TRACE="🔍"

function init_logging() {
    local log_file="${1:-}"
    
    if [[ -n "$log_file" ]]; then
        LOG_FILE="$log_file"
        LOG_TO_FILE=true
        
        # Create log directory if it doesn't exist
        local log_dir=$(dirname "$log_file")
        mkdir -p "$log_dir"
        
        # Initialize log file with header
        {
            echo "==============================================="
            echo "AIMaster Universal Orchestrator Log"
            echo "Started: $(date)"
            echo "Platform: $(uname -s)"
            echo "Architecture: $(uname -m)"
            echo "Shell: $BASH_VERSION"
            echo "==============================================="
        } > "$log_file"
    fi
    
    # Detect if output supports colors
    if [[ ! -t 1 ]] || [[ "${NO_COLOR:-}" == "1" ]] || [[ "${TERM:-}" == "dumb" ]]; then
        ENABLE_COLORS=false
    fi
    
    # Check for quiet or verbose modes
    [[ "${QUIET:-false}" == "true" ]] && LOG_TO_CONSOLE=false
    [[ "${VERBOSE:-false}" == "true" ]] && CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
}

function set_log_level() {
    local level="$1"
    case "$level" in
        ERROR|error|0)
            CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR
            ;;
        WARN|warn|1)
            CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN
            ;;
        INFO|info|2)
            CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
            ;;
        DEBUG|debug|3)
            CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
            ;;
        *)
            log_warn "Unknown log level: $level, using INFO"
            CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
            ;;
    esac
}

function get_timestamp() {
    if [[ "$ENABLE_TIMESTAMPS" == "true" ]]; then
        date '+%Y-%m-%d %H:%M:%S'
    fi
}

function format_log_message() {
    local level="$1"
    local emoji="$2"
    local color="$3"
    local message="$4"
    local timestamp=""
    
    [[ "$ENABLE_TIMESTAMPS" == "true" ]] && timestamp="$(get_timestamp) "
    
    if [[ "$ENABLE_COLORS" == "true" && "$LOG_TO_CONSOLE" == "true" ]]; then
        echo -e "${timestamp}${color}[${level}]${NC} ${emoji} ${message}"
    else
        echo "${timestamp}[${level}] ${emoji} ${message}"
    fi
}

function write_to_log() {
    local message="$1"
    
    if [[ "$LOG_TO_FILE" == "true" && -n "$LOG_FILE" ]]; then
        echo "$(get_timestamp) $message" >> "$LOG_FILE"
    fi
}

function log_error() {
    [[ $CURRENT_LOG_LEVEL -lt $LOG_LEVEL_ERROR ]] && return
    
    local message="$1"
    local formatted_message
    
    formatted_message=$(format_log_message "ERROR" "$EMOJI_ERROR" "$RED" "$message")
    
    [[ "$LOG_TO_CONSOLE" == "true" ]] && echo "$formatted_message" >&2
    write_to_log "[ERROR] $EMOJI_ERROR $message"
}

function log_warn() {
    [[ $CURRENT_LOG_LEVEL -lt $LOG_LEVEL_WARN ]] && return
    
    local message="$1"
    local formatted_message
    
    formatted_message=$(format_log_message "WARN" "$EMOJI_WARN" "$YELLOW" "$message")
    
    [[ "$LOG_TO_CONSOLE" == "true" ]] && echo "$formatted_message"
    write_to_log "[WARN] $EMOJI_WARN $message"
}

function log_info() {
    [[ $CURRENT_LOG_LEVEL -lt $LOG_LEVEL_INFO ]] && return
    
    local message="$1"
    local formatted_message
    
    formatted_message=$(format_log_message "INFO" "$EMOJI_INFO" "$BLUE" "$message")
    
    [[ "$LOG_TO_CONSOLE" == "true" ]] && echo "$formatted_message"
    write_to_log "[INFO] $EMOJI_INFO $message"
}

function log_success() {
    [[ $CURRENT_LOG_LEVEL -lt $LOG_LEVEL_INFO ]] && return
    
    local message="$1"
    local formatted_message
    
    formatted_message=$(format_log_message "SUCCESS" "$EMOJI_SUCCESS" "$GREEN" "$message")
    
    [[ "$LOG_TO_CONSOLE" == "true" ]] && echo "$formatted_message"
    write_to_log "[SUCCESS] $EMOJI_SUCCESS $message"
}

function log_debug() {
    [[ $CURRENT_LOG_LEVEL -lt $LOG_LEVEL_DEBUG ]] && return
    
    local message="$1"
    local formatted_message
    
    formatted_message=$(format_log_message "DEBUG" "$EMOJI_DEBUG" "$GRAY" "$message")
    
    [[ "$LOG_TO_CONSOLE" == "true" ]] && echo "$formatted_message"
    write_to_log "[DEBUG] $EMOJI_DEBUG $message"
}

function log_trace() {
    [[ $CURRENT_LOG_LEVEL -lt $LOG_LEVEL_DEBUG ]] && return
    
    local message="$1"
    local formatted_message
    
    formatted_message=$(format_log_message "TRACE" "$EMOJI_TRACE" "$CYAN" "$message")
    
    [[ "$LOG_TO_CONSOLE" == "true" ]] && echo "$formatted_message"
    write_to_log "[TRACE] $EMOJI_TRACE $message"
}

# Progress/status logging functions
function log_progress() {
    local current="$1"
    local total="$2"
    local task="${3:-}"
    local percentage=$((current * 100 / total))
    
    local progress_bar=""
    local bar_length=20
    local filled=$((percentage * bar_length / 100))
    
    for ((i=0; i<bar_length; i++)); do
        if [[ $i -lt $filled ]]; then
            progress_bar+="█"
        else
            progress_bar+="░"
        fi
    done
    
    local message="[$progress_bar] ${percentage}% (${current}/${total})"
    [[ -n "$task" ]] && message="$message - $task"
    
    if [[ "$ENABLE_COLORS" == "true" && "$LOG_TO_CONSOLE" == "true" ]]; then
        echo -ne "\r${BLUE}[PROGRESS]${NC} $message"
    else
        echo -ne "\r[PROGRESS] $message"
    fi
    
    # Add newline when complete
    [[ $current -eq $total ]] && echo
    
    write_to_log "[PROGRESS] $message"
}

function log_step() {
    local step_number="$1"
    local total_steps="$2"
    local description="$3"
    
    local message="Step $step_number/$total_steps: $description"
    
    if [[ "$ENABLE_COLORS" == "true" && "$LOG_TO_CONSOLE" == "true" ]]; then
        echo -e "${MAGENTA}[STEP ${step_number}/${total_steps}]${NC} 🔧 ${description}"
    else
        echo "[STEP $step_number/$total_steps] 🔧 $description"
    fi
    
    write_to_log "[STEP $step_number/$total_steps] 🔧 $description"
}

# Structured logging functions
function log_json() {
    local level="$1"
    local json_data="$2"
    
    case "$level" in
        error)
            log_error "JSON: $json_data"
            ;;
        warn)
            log_warn "JSON: $json_data"
            ;;
        info)
            log_info "JSON: $json_data"
            ;;
        debug)
            log_debug "JSON: $json_data"
            ;;
        *)
            log_info "JSON: $json_data"
            ;;
    esac
}

function log_command() {
    local command="$1"
    local exit_code="${2:-0}"
    
    if [[ $exit_code -eq 0 ]]; then
        log_debug "Command executed: $command"
    else
        log_error "Command failed (exit $exit_code): $command"
    fi
}

function log_duration() {
    local start_time="$1"
    local end_time="$2"
    local task_name="${3:-Task}"
    
    local duration=$((end_time - start_time))
    local formatted_duration
    
    if [[ $duration -lt 60 ]]; then
        formatted_duration="${duration}s"
    elif [[ $duration -lt 3600 ]]; then
        formatted_duration="$((duration / 60))m $((duration % 60))s"
    else
        formatted_duration="$((duration / 3600))h $(((duration % 3600) / 60))m $((duration % 60))s"
    fi
    
    log_info "$task_name completed in $formatted_duration"
}

# Banner/header functions
function log_banner() {
    local message="$1"
    local width="${2:-60}"
    local char="${3:-=}"
    
    local border=$(printf "%*s" "$width" | tr ' ' "$char")
    local padding=$(((width - ${#message} - 2) / 2))
    local padded_message=$(printf "%*s %s %*s" "$padding" "" "$message" "$padding" "")
    
    if [[ "$ENABLE_COLORS" == "true" && "$LOG_TO_CONSOLE" == "true" ]]; then
        echo -e "${CYAN}${border}${NC}"
        echo -e "${CYAN}${padded_message}${NC}"
        echo -e "${CYAN}${border}${NC}"
    else
        echo "$border"
        echo "$padded_message"
        echo "$border"
    fi
    
    write_to_log "$border"
    write_to_log "$padded_message"
    write_to_log "$border"
}

function log_section() {
    local title="$1"
    local subtitle="${2:-}"
    
    echo
    if [[ "$ENABLE_COLORS" == "true" && "$LOG_TO_CONSOLE" == "true" ]]; then
        echo -e "${WHITE}📋 $title${NC}"
        [[ -n "$subtitle" ]] && echo -e "${GRAY}   $subtitle${NC}"
    else
        echo "📋 $title"
        [[ -n "$subtitle" ]] && echo "   $subtitle"
    fi
    echo
    
    write_to_log "📋 $title"
    [[ -n "$subtitle" ]] && write_to_log "   $subtitle"
}

# Cleanup function
function cleanup_logging() {
    if [[ "$LOG_TO_FILE" == "true" && -n "$LOG_FILE" ]]; then
        {
            echo "==============================================="
            echo "Log session ended: $(date)"
            echo "==============================================="
        } >> "$LOG_FILE"
    fi
}