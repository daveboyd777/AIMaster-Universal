# AIMaster Universal Cross-Platform Orchestrator

A bash-based orchestration framework that replaces PowerShell dependencies with cross-platform compatibility, providing reliable network connectivity testing and system management across macOS, Linux, and Windows.

## 🚀 Features

- **Cross-Platform Compatibility**: Runs natively on macOS, Linux, and Windows (via Git Bash/WSL)
- **Robust Network Testing**: Comprehensive connectivity tests for SSH, VNC, SMB, and HTTP
- **Intelligent Service Management**: Modular service architecture with timeout and retry capabilities  
- **Advanced Logging**: Structured logging with colors, timestamps, and multiple output formats
- **JSON Configuration**: Flexible configuration management with validation
- **Error Handling**: Comprehensive error recovery and retry mechanisms
- **Testing Framework**: Bats-based testing suite replacing broken PowerShell/Pester on macOS

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

## ⚡ Quick Start

```bash
# Clone and set up
git clone <repository-url>
cd AIMaster-Universal

# Make orchestrator executable
chmod +x Scripts/orchestrator.sh

# Run version check
./Scripts/orchestrator.sh version

# Check system status
./Scripts/orchestrator.sh status

# Test Mac connectivity (if Mac is available)
./Scripts/orchestrator.sh test-mac

# Show all available commands
./Scripts/orchestrator.sh --help
```

## 🛠️ Installation

### Prerequisites

#### macOS
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install bats-core coreutils jq curl wget netcat

# Verify installation
bats --version
```

#### Linux (Ubuntu/Debian)
```bash
# Install required packages
sudo apt-get update
sudo apt-get install -y bats jq curl wget netcat-openbsd

# Verify installation
bats --version
```

#### Windows
```bash
# Option 1: Use Git Bash (recommended)
# Install Git for Windows: https://git-scm.com/download/win

# Option 2: Use WSL
wsl --install

# Option 3: PowerShell (if stable)
# Install PowerShell 7+: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows
```

### Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd AIMaster-Universal
   ```

2. **Set Permissions**
   ```bash
   chmod +x Scripts/orchestrator.sh
   find Scripts/services -name "*.sh" -exec chmod +x {} \;
   find tests -name "*.bats" -exec chmod +x {} \;
   ```

3. **Create Required Directories**
   ```bash
   mkdir -p ~/.aimaster/logs
   ```

4. **Verify Installation**
   ```bash
   ./Scripts/orchestrator.sh version
   ```

## 📖 Usage

### Basic Commands

```bash
# Show version and system information
./Scripts/orchestrator.sh version

# Display comprehensive system status
./Scripts/orchestrator.sh status
./Scripts/orchestrator.sh status -v  # Verbose mode

# Show configuration
./Scripts/orchestrator.sh config

# Display help
./Scripts/orchestrator.sh --help
```

### Network Testing

```bash
# Test Mac connectivity (full suite)
./Scripts/orchestrator.sh test-mac

# Run all connectivity tests
./Scripts/orchestrator.sh test

# Discover available systems
./Scripts/orchestrator.sh discover
./Scripts/orchestrator.sh discover --parallel  # Parallel mode
```

### Service Management

```bash
# Run specific service
./Scripts/orchestrator.sh service startup-test-mac-connectivity.sh

# Start orchestrator services
./Scripts/orchestrator.sh start

# Stop all services
./Scripts/orchestrator.sh stop
```

### Advanced Options

```bash
# Set custom timeout
./Scripts/orchestrator.sh --timeout 60 test-mac

# Verbose logging
./Scripts/orchestrator.sh -v status

# Quiet mode
./Scripts/orchestrator.sh -q test

# Custom configuration file
./Scripts/orchestrator.sh -c /path/to/config.json status
```

## 🧪 Testing

### Running Tests

The project uses [Bats (Bash Automated Testing System)](https://bats-core.readthedocs.io/) for testing, replacing the broken PowerShell/Pester setup on macOS.

```bash
# Run all tests
bats tests/

# Run specific test suites
bats tests/unit/                    # Unit tests
bats tests/integration/             # Integration tests

# Run specific test file
bats tests/unit/test_orchestrator.bats

# Run tests with specific filter
bats tests/integration/test_mac_connectivity.bats --filter "should ping Mac successfully"

# Verbose output
bats tests/ --verbose-run

# TAP format output
bats tests/ --formatter tap

# Parallel test execution
bats tests/ --jobs 4
```

### Test Categories

#### Unit Tests
- **`test_platform_detection.bats`**: Tests platform detection, architecture, OS version
- **`test_network_utils.bats`**: Tests network utilities, connectivity functions  
- **`test_orchestrator.bats`**: Tests orchestrator core functionality

#### Integration Tests
- **`test_mac_connectivity.bats`**: Comprehensive Mac connectivity testing

### Current Test Coverage

```bash
# Check current test results
bats tests/unit/test_platform_detection.bats     # 18 tests
bats tests/unit/test_orchestrator.bats           # 23 tests  
bats tests/integration/test_mac_connectivity.bats # 13 tests

# Total: 54+ tests covering core functionality
```

## 🏗️ Architecture

### Directory Structure

```
AIMaster-Universal/
├── Scripts/
│   ├── orchestrator.sh           # Main orchestration engine
│   ├── lib/                      # Core libraries
│   │   ├── logging.sh           # Logging framework
│   │   ├── platform-detection.sh # Platform detection
│   │   ├── error-handling.sh    # Error handling & recovery
│   │   ├── json-utils.sh        # JSON parsing utilities
│   │   └── network-utils.sh     # Network testing utilities
│   ├── services/                # Service modules
│   │   ├── startup-test-mac-connectivity.sh
│   │   └── mac-connectivity.sh
│   └── config/                  # Configuration files
│       ├── orchestrator.json    # Main configuration
│       └── testing-strategy.md  # Testing documentation
├── tests/                       # Test suites
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── fixtures/               # Test data
├── .github/
│   └── workflows/              # CI/CD workflows
└── README.md                   # This file
```

### Core Components

#### Orchestrator (`orchestrator.sh`)
- Main entry point and command dispatcher
- Service lifecycle management
- Configuration handling
- Cross-platform timeout implementation

#### Libraries (`lib/`)
- **Logging**: Structured logging with colors and multiple outputs
- **Platform Detection**: OS, architecture, and capability detection
- **Error Handling**: Comprehensive error recovery and retry logic
- **JSON Utils**: JSON parsing and manipulation (jq/python/node/bash fallbacks)
- **Network Utils**: Network connectivity testing and monitoring

#### Services (`services/`)
- Modular service architecture
- Self-contained executables
- Standardized input/output interfaces
- Timeout and retry support

## ⚙️ Configuration

### Default Configuration

The orchestrator automatically creates a default configuration file:

```json
{
  "orchestrator": {
    "version": "1.0.0",
    "platform": "macOS",
    "log_level": "INFO",
    "parallel_execution": true,
    "timeout_seconds": 30
  },
  "services": {
    "mac_connectivity": {
      "enabled": true,
      "script": "startup-test-mac-connectivity.sh",
      "timeout": 60,
      "retry_count": 3
    }
  },
  "targets": {
    "mac": {
      "ip_address": "100.77.255.169",
      "username": "daveboyd",
      "hostname": "sf-Deb-Book.local"
    }
  }
}
```

### Customization

```bash
# Use custom configuration
./Scripts/orchestrator.sh -c /path/to/custom-config.json status

# View current configuration
./Scripts/orchestrator.sh config

# Configuration is automatically created on first run
./Scripts/orchestrator.sh version  # Creates default config
```

## 🔧 Development

### Adding New Services

1. **Create Service Script**
   ```bash
   # Create new service in Scripts/services/
   touch Scripts/services/my-new-service.sh
   chmod +x Scripts/services/my-new-service.sh
   ```

2. **Implement Service**
   ```bash
   #!/bin/bash
   # My New Service
   echo "Service executing..."
   # Your service logic here
   exit 0
   ```

3. **Add to Configuration**
   ```json
   {
     "services": {
       "my_new_service": {
         "enabled": true,
         "script": "my-new-service.sh",
         "timeout": 30,
         "retry_count": 2
       }
     }
   }
   ```

4. **Test Service**
   ```bash
   ./Scripts/orchestrator.sh service my-new-service.sh
   ```

### Adding New Tests

1. **Create Test File**
   ```bash
   touch tests/unit/test_my_feature.bats
   chmod +x tests/unit/test_my_feature.bats
   ```

2. **Write Tests**
   ```bash
   #!/usr/bin/env bats
   
   setup() {
     source "Scripts/lib/my-library.sh"
   }
   
   @test "should test my feature" {
     run my_function "test_input"
     [ "$status" -eq 0 ]
     [[ "$output" =~ "expected_output" ]]
   }
   ```

3. **Run Tests**
   ```bash
   bats tests/unit/test_my_feature.bats
   ```

### CI/CD Integration

The project includes comprehensive CI/CD workflows for cross-platform testing:

- **macOS**: Native Bats testing with Homebrew dependencies
- **Linux**: Bats testing with apt-get dependencies  
- **Windows**: PowerShell/Pester testing with Git Bash fallback

## 🐛 Troubleshooting

### Common Issues

#### PowerShell Stack Overflow (macOS)
```bash
# Problem: PowerShell crashes with stack overflow on macOS 15.7.1
# Solution: Use bash orchestrator instead
./Scripts/orchestrator.sh version  # Uses bash, not PowerShell
```

#### Missing Dependencies
```bash
# macOS
brew install bats-core coreutils jq

# Linux
sudo apt-get install bats jq curl wget netcat-openbsd

# Test dependencies
bats --version
jq --version
```

#### Permission Errors
```bash
# Fix script permissions
chmod +x Scripts/orchestrator.sh
find Scripts/services -name "*.sh" -exec chmod +x {} \;
find tests -name "*.bats" -exec chmod +x {} \;
```

#### Network Connectivity Issues
```bash
# Test basic connectivity
ping -c 1 google.com

# Test specific Mac connectivity
./Scripts/orchestrator.sh test-mac

# Run connectivity diagnostics
bats tests/integration/test_mac_connectivity.bats --filter "should have network connectivity"
```

#### Configuration Issues
```bash
# Reset configuration
rm Scripts/config/orchestrator.json
./Scripts/orchestrator.sh version  # Recreates default config

# Validate configuration
./Scripts/orchestrator.sh config
```

### Debug Mode

```bash
# Enable verbose logging
./Scripts/orchestrator.sh -v status

# Enable debug logging in tests
VERBOSE=true bats tests/unit/test_orchestrator.bats
```

### Log Files

```bash
# View orchestrator logs
ls ~/.aimaster/logs/

# View latest log
tail -f ~/.aimaster/logs/orchestrator_*.log

# View service logs
cat /tmp/aimaster_mac_test_*.log
```

## 📚 Additional Resources

- [Bats Testing Framework](https://bats-core.readthedocs.io/)
- [JSON Processing with jq](https://stedolan.github.io/jq/)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)
- [Cross-Platform Shell Scripting](https://wiki.bash-hackers.org/scripting/bashchanges)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `bats tests/`
5. Submit a pull request

## 📝 License

This project is part of the AIMaster automation framework.

---

**Status**: ✅ Active Development | 🧪 54+ Tests | 🌍 Cross-Platform | 📈 CI/CD Ready