# AIMaster Testing Strategy: Pester to Bats Migration

## Overview
Due to PowerShell stack overflow issues on macOS, we're migrating from Pester to Bats for cross-platform testing.

## Bats (Bash Automated Testing System)

### Advantages
- ✅ Pure bash - no PowerShell dependency
- ✅ Cross-platform compatibility (macOS, Linux, Windows via Git Bash/WSL)
- ✅ Similar syntax to Pester for easy migration
- ✅ Active development and maintenance
- ✅ Excellent CI/CD integration
- ✅ Rich assertion library
- ✅ Parallel test execution support

### Installation Options

#### Option A: Homebrew (macOS/Linux)
```bash
brew install bats-core bats-file bats-assert
```

#### Option B: Git Submodule
```bash
git submodule add https://github.com/bats-core/bats-core.git test/libs/bats-core
git submodule add https://github.com/bats-core/bats-assert.git test/libs/bats-assert  
git submodule add https://github.com/bats-core/bats-file.git test/libs/bats-file
```

#### Option C: Manual Installation
```bash
mkdir -p test/libs
git clone https://github.com/bats-core/bats-core.git test/libs/bats-core
git clone https://github.com/bats-core/bats-assert.git test/libs/bats-assert
git clone https://github.com/bats-core/bats-file.git test/libs/bats-file
```

### Migration Path: Pester → Bats

#### Pester Test Example
```powershell
Describe "Mac Connectivity Tests" {
    Context "Network Tests" {
        It "Should ping Mac successfully" {
            Test-Connection -ComputerName $MacIP -Count 1 | Should -Not -BeNullOrEmpty
        }
        
        It "Should connect to SSH port" {
            Test-NetConnection -ComputerName $MacIP -Port 22 | Should -Have -Property "TcpTestSucceeded" -Value $true
        }
    }
}
```

#### Equivalent Bats Test
```bash
#!/usr/bin/env bats

load 'test/libs/bats-assert/load'
load 'test/libs/bats-file/load'

setup() {
    MAC_IP="100.77.255.169"
    MAC_USER="daveboyd"
}

@test "should ping Mac successfully" {
    run ping -c 1 "$MAC_IP"
    assert_success
    assert_output --partial "1 packets transmitted, 1 received"
}

@test "should connect to SSH port" {
    run timeout 5 bash -c "exec 3<>/dev/tcp/$MAC_IP/22 && exec 3<&-"
    assert_success
}

@test "should establish SSH connection" {
    run ssh -o ConnectTimeout=5 -o BatchMode=yes "$MAC_USER@$MAC_IP" "echo 'connection test'"
    assert_success
    assert_output "connection test"
}
```

## Testing Architecture

### Directory Structure
```
AIMaster-Universal/
├── Scripts/
│   ├── orchestrator.sh
│   ├── lib/
│   ├── services/
│   └── config/
└── tests/
    ├── libs/               # Bats framework
    │   ├── bats-core/
    │   ├── bats-assert/
    │   └── bats-file/
    ├── unit/              # Unit tests
    │   ├── test_orchestrator.bats
    │   ├── test_network.bats
    │   └── test_platform.bats
    ├── integration/       # Integration tests  
    │   ├── test_mac_connectivity.bats
    │   ├── test_services.bats
    │   └── test_cross_platform.bats
    └── fixtures/          # Test data
        ├── config/
        └── mock_responses/
```

### Test Categories

#### 1. Unit Tests
- Individual function testing
- Library validation
- Configuration parsing
- Error handling

#### 2. Integration Tests
- End-to-end connectivity tests
- Service orchestration tests
- Cross-platform compatibility tests
- Network functionality tests

#### 3. System Tests
- Full deployment validation
- Performance testing
- Long-running connectivity monitoring
- Real environment validation

## Platform-Specific Testing Strategy

### macOS Testing (Primary Environment)
- **Framework**: Bats
- **Scope**: Full test suite
- **Tools**: Native macOS commands + GNU tools via Homebrew
- **CI/CD**: GitHub Actions with macOS runners

### Windows Testing (PC Room504)  
- **Framework**: Choice between:
  - **Option A**: Pester (if PowerShell is stable)
  - **Option B**: Bats via Git Bash/WSL
  - **Option C**: Hybrid approach
- **Scope**: Windows-specific tests + cross-platform validation
- **Tools**: Windows native commands or Unix-like via Git Bash

### Linux Testing (Future)
- **Framework**: Bats
- **Scope**: Full test suite + Linux-specific features
- **Tools**: Native Linux commands
- **CI/CD**: GitHub Actions with Ubuntu runners

## Migration Strategy

### Phase 1: Core Framework Setup ✅
- [x] Set up bash orchestrator
- [x] Create cross-platform libraries
- [ ] Install Bats framework
- [ ] Create basic test structure

### Phase 2: Basic Test Migration
- [ ] Convert existing Mac connectivity tests
- [ ] Create network utility tests
- [ ] Set up error handling tests
- [ ] Validate platform detection tests

### Phase 3: Advanced Testing
- [ ] Create integration test suite
- [ ] Set up continuous testing
- [ ] Add performance benchmarks
- [ ] Create deployment validation tests

### Phase 4: Windows Integration
- [ ] Evaluate PowerShell stability on Windows
- [ ] Choose Windows testing approach
- [ ] Create Windows-specific tests
- [ ] Set up cross-platform validation

## Recommended Approach

### Immediate Actions
1. **Install Bats on macOS** (brew install bats-core)
2. **Create basic test structure**
3. **Convert critical Mac connectivity tests**
4. **Set up automated test execution**

### For Windows PC (Room504)
1. **Test PowerShell stability** 
2. **If PowerShell works**: Keep existing Pester tests
3. **If PowerShell fails**: Install Git Bash + Bats
4. **Create hybrid approach** for maximum compatibility

### Benefits of This Approach
- ✅ Eliminates PowerShell dependency issues
- ✅ Maintains test quality and coverage
- ✅ Enables cross-platform testing
- ✅ Provides consistent testing experience
- ✅ Supports CI/CD integration
- ✅ Easier maintenance and development

### Testing Command Examples
```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/integration/test_mac_connectivity.bats

# Run tests with verbose output
bats --verbose-run tests/

# Run tests in parallel
bats --jobs 4 tests/

# Generate JUnit XML for CI
bats --formatter junit tests/ > test-results.xml
```

This strategy provides a robust, maintainable testing solution that works reliably across all platforms while maintaining the testing rigor of the original Pester-based approach.