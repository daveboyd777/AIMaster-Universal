#!/bin/bash
# AIMaster Universal Orchestrator - Platform Detection Library
# Cross-platform detection and compatibility utilities

# Global platform variables
PLATFORM=""
ARCHITECTURE=""
OS_VERSION=""
DISTRO=""
PACKAGE_MANAGER=""
SHELL_TYPE=""
USER_HOME=""
TEMP_DIR=""

function detect_platform() {
    if [[ -z "$PLATFORM" ]]; then
        case "$OSTYPE" in
            darwin*)
                PLATFORM="macOS"
                ;;
            linux*)
                PLATFORM="Linux"
                ;;
            msys*|cygwin*|mingw*)
                PLATFORM="Windows"
                ;;
            freebsd*)
                PLATFORM="FreeBSD"
                ;;
            *)
                PLATFORM="Unknown"
                ;;
        esac
    fi
    echo "$PLATFORM"
}

function detect_architecture() {
    if [[ -z "$ARCHITECTURE" ]]; then
        local arch=$(uname -m 2>/dev/null || echo "unknown")
        case "$arch" in
            x86_64|amd64)
                ARCHITECTURE="x64"
                ;;
            aarch64|arm64)
                ARCHITECTURE="arm64"
                ;;
            armv7l)
                ARCHITECTURE="arm32"
                ;;
            i386|i686)
                ARCHITECTURE="x86"
                ;;
            *)
                ARCHITECTURE="$arch"
                ;;
        esac
    fi
    echo "$ARCHITECTURE"
}

function detect_os_version() {
    if [[ -z "$OS_VERSION" ]]; then
        local platform=$(detect_platform)
        
        case "$platform" in
            "macOS")
                OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
                ;;
            "Linux")
                if [[ -f /etc/os-release ]]; then
                    OS_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
                elif command -v lsb_release >/dev/null 2>&1; then
                    OS_VERSION=$(lsb_release -rs 2>/dev/null)
                else
                    OS_VERSION=$(uname -r 2>/dev/null || echo "unknown")
                fi
                ;;
            "Windows")
                # For Git Bash, WSL, etc.
                if command -v wmic >/dev/null 2>&1; then
                    OS_VERSION=$(wmic os get Version /value 2>/dev/null | grep Version | cut -d'=' -f2 | tr -d '\r')
                elif [[ -f /proc/version ]]; then
                    # WSL case
                    OS_VERSION=$(grep -o "Microsoft.*" /proc/version | head -1)
                else
                    OS_VERSION="unknown"
                fi
                ;;
            *)
                OS_VERSION="unknown"
                ;;
        esac
    fi
    echo "$OS_VERSION"
}

function detect_distro() {
    if [[ -z "$DISTRO" ]]; then
        local platform=$(detect_platform)
        
        case "$platform" in
            "Linux")
                if [[ -f /etc/os-release ]]; then
                    DISTRO=$(grep ^ID= /etc/os-release | cut -d'=' -f2 | tr -d '"')
                elif [[ -f /etc/redhat-release ]]; then
                    DISTRO="redhat"
                elif [[ -f /etc/debian_version ]]; then
                    DISTRO="debian"
                elif command -v lsb_release >/dev/null 2>&1; then
                    DISTRO=$(lsb_release -si 2>/dev/null | tr '[:upper:]' '[:lower:]')
                else
                    DISTRO="unknown"
                fi
                ;;
            "macOS")
                DISTRO="macos"
                ;;
            "Windows")
                DISTRO="windows"
                ;;
            *)
                DISTRO="unknown"
                ;;
        esac
    fi
    echo "$DISTRO"
}

function detect_package_manager() {
    if [[ -z "$PACKAGE_MANAGER" ]]; then
        local platform=$(detect_platform)
        local distro=$(detect_distro)
        
        # Check in order of preference
        if command -v brew >/dev/null 2>&1; then
            PACKAGE_MANAGER="brew"
        elif command -v apt >/dev/null 2>&1; then
            PACKAGE_MANAGER="apt"
        elif command -v yum >/dev/null 2>&1; then
            PACKAGE_MANAGER="yum"
        elif command -v dnf >/dev/null 2>&1; then
            PACKAGE_MANAGER="dnf"
        elif command -v pacman >/dev/null 2>&1; then
            PACKAGE_MANAGER="pacman"
        elif command -v zypper >/dev/null 2>&1; then
            PACKAGE_MANAGER="zypper"
        elif command -v pkg >/dev/null 2>&1; then
            PACKAGE_MANAGER="pkg"
        elif command -v choco >/dev/null 2>&1; then
            PACKAGE_MANAGER="choco"
        elif command -v winget >/dev/null 2>&1; then
            PACKAGE_MANAGER="winget"
        else
            PACKAGE_MANAGER="none"
        fi
    fi
    echo "$PACKAGE_MANAGER"
}

function detect_shell_type() {
    if [[ -z "$SHELL_TYPE" ]]; then
        if [[ -n "$BASH_VERSION" ]]; then
            SHELL_TYPE="bash"
        elif [[ -n "$ZSH_VERSION" ]]; then
            SHELL_TYPE="zsh"
        elif [[ "$0" == *"fish" ]]; then
            SHELL_TYPE="fish"
        elif [[ "$0" == *"dash" ]]; then
            SHELL_TYPE="dash"
        elif [[ -n "$SHELL" ]]; then
            SHELL_TYPE=$(basename "$SHELL")
        else
            SHELL_TYPE="unknown"
        fi
    fi
    echo "$SHELL_TYPE"
}

function get_user_home() {
    if [[ -z "$USER_HOME" ]]; then
        local platform=$(detect_platform)
        
        case "$platform" in
            "Windows")
                # Try various Windows home directory patterns
                if [[ -n "$USERPROFILE" ]]; then
                    USER_HOME="$USERPROFILE"
                elif [[ -n "$HOME" ]]; then
                    USER_HOME="$HOME"
                else
                    USER_HOME="/c/Users/$USER"
                fi
                ;;
            *)
                USER_HOME="${HOME:-/home/$USER}"
                ;;
        esac
    fi
    echo "$USER_HOME"
}

function get_temp_dir() {
    if [[ -z "$TEMP_DIR" ]]; then
        local platform=$(detect_platform)
        
        case "$platform" in
            "Windows")
                TEMP_DIR="${TEMP:-/tmp}"
                ;;
            *)
                TEMP_DIR="${TMPDIR:-/tmp}"
                ;;
        esac
    fi
    echo "$TEMP_DIR"
}

function is_macos() {
    [[ "$(detect_platform)" == "macOS" ]]
}

function is_linux() {
    [[ "$(detect_platform)" == "Linux" ]]
}

function is_windows() {
    [[ "$(detect_platform)" == "Windows" ]]
}

function is_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

function is_arm() {
    local arch=$(detect_architecture)
    [[ "$arch" == "arm64" || "$arch" == "arm32" ]]
}

function is_x64() {
    [[ "$(detect_architecture)" == "x64" ]]
}

function has_command() {
    command -v "$1" >/dev/null 2>&1
}

function get_cpu_count() {
    local platform=$(detect_platform)
    
    case "$platform" in
        "macOS")
            sysctl -n hw.ncpu 2>/dev/null || echo "1"
            ;;
        "Linux")
            nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1"
            ;;
        "Windows")
            echo "${NUMBER_OF_PROCESSORS:-1}"
            ;;
        *)
            echo "1"
            ;;
    esac
}

function get_memory_info() {
    local platform=$(detect_platform)
    
    case "$platform" in
        "macOS")
            local mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
            echo $((mem_bytes / 1024 / 1024))  # Convert to MB
            ;;
        "Linux")
            if [[ -f /proc/meminfo ]]; then
                grep MemTotal /proc/meminfo | awk '{print int($2/1024)}'
            else
                echo "0"
            fi
            ;;
        "Windows")
            if has_command wmic; then
                wmic computersystem get TotalPhysicalMemory /value 2>/dev/null | \
                    grep TotalPhysicalMemory | \
                    cut -d'=' -f2 | \
                    awk '{print int($1/1024/1024)}' | \
                    tr -d '\r'
            else
                echo "0"
            fi
            ;;
        *)
            echo "0"
            ;;
    esac
}

function get_disk_space() {
    local path="${1:-$(pwd)}"
    local platform=$(detect_platform)
    
    case "$platform" in
        "macOS"|"Linux")
            df -h "$path" 2>/dev/null | awk 'NR==2 {print $4}' || echo "unknown"
            ;;
        "Windows")
            # For Windows/WSL environments
            if has_command df; then
                df -h "$path" 2>/dev/null | awk 'NR==2 {print $4}' || echo "unknown"
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

function get_network_interfaces() {
    local platform=$(detect_platform)
    
    case "$platform" in
        "macOS")
            ifconfig 2>/dev/null | grep "^[a-z]" | cut -d: -f1 | tr '\n' ' '
            ;;
        "Linux")
            if has_command ip; then
                ip link show 2>/dev/null | grep "^[0-9]" | awk '{print $2}' | tr -d ':' | tr '\n' ' '
            else
                ifconfig 2>/dev/null | grep "^[a-z]" | cut -d' ' -f1 | tr '\n' ' '
            fi
            ;;
        "Windows")
            # Basic interface detection for Windows environments
            if has_command ipconfig; then
                ipconfig 2>/dev/null | grep "adapter" | cut -d' ' -f4- | tr '\n' ' '
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

function check_internet_connectivity() {
    # Try multiple methods to check internet connectivity
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
            return 0
        fi
    done
    
    return 1
}

function get_platform_info() {
    cat << EOF
Platform Information:
=====================
Platform: $(detect_platform)
Architecture: $(detect_architecture)
OS Version: $(detect_os_version)
Distribution: $(detect_distro)
Package Manager: $(detect_package_manager)
Shell: $(detect_shell_type)
User Home: $(get_user_home)
Temp Directory: $(get_temp_dir)
CPU Cores: $(get_cpu_count)
Memory (MB): $(get_memory_info)
Disk Space: $(get_disk_space)
Network Interfaces: $(get_network_interfaces)
Internet: $(check_internet_connectivity && echo "Available" || echo "Unavailable")
EOF
}

function is_platform_supported() {
    local platform=$(detect_platform)
    
    case "$platform" in
        "macOS"|"Linux"|"Windows")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function get_platform_specific_path() {
    local unix_path="$1"
    local platform=$(detect_platform)
    
    case "$platform" in
        "Windows")
            # Convert Unix-style paths to Windows-style for certain contexts
            if [[ "$unix_path" =~ ^/c/ ]]; then
                echo "${unix_path/\/c\//C:\\}" | tr '/' '\\'
            else
                echo "$unix_path"
            fi
            ;;
        *)
            echo "$unix_path"
            ;;
    esac
}

function get_executable_extension() {
    local platform=$(detect_platform)
    
    case "$platform" in
        "Windows")
            echo ".exe"
            ;;
        *)
            echo ""
            ;;
    esac
}

function normalize_line_endings() {
    local file="$1"
    local platform=$(detect_platform)
    
    case "$platform" in
        "Windows")
            # Convert to Windows line endings if needed
            if has_command unix2dos; then
                unix2dos "$file" 2>/dev/null
            fi
            ;;
        *)
            # Convert to Unix line endings
            if has_command dos2unix; then
                dos2unix "$file" 2>/dev/null
            fi
            ;;
    esac
}