# AIMaster PC Startup Script - Mac Connectivity Test
# Designed to run when AIMaster starts on PC in room504
# Tests SSH connection to Mac and reports status

param(
    [Parameter(Mandatory=$false)]
    [string]$MacIP = "100.77.255.169",
    
    [Parameter(Mandatory=$false)]
    [string]$MacUser = "daveboyd",
    
    [Parameter(Mandatory=$false)]
    [string]$MacHostname = "sf-Deb-Book.local"
)

# Configuration
$ScriptName = "AIMaster Mac Connectivity Test"
$StartupTime = Get-Date
$LogFile = "$env:TEMP\aimaster_mac_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$ResultFile = "$env:TEMP\aimaster_mac_connectivity_status.json"

function Write-LogAndHost {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Write-Host $logEntry -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logEntry
}

# Initialize
Write-LogAndHost "🚀 $ScriptName" "Cyan"
Write-LogAndHost "=" * 50 "Cyan"
Write-LogAndHost "Startup Time: $StartupTime"
Write-LogAndHost "PC Environment: $env:COMPUTERNAME"
Write-LogAndHost "User: $env:USERNAME"
Write-LogAndHost "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-LogAndHost ""

Write-LogAndHost "Target Mac Information:" "Yellow"
Write-LogAndHost "  IP Address: $MacIP"
Write-LogAndHost "  Username: $MacUser"
Write-LogAndHost "  Hostname: $MacHostname"
Write-LogAndHost ""

# Test Results Storage
$TestResults = @{
    timestamp = $StartupTime.ToString("yyyy-MM-ddTHH:mm:ss")
    pc_info = @{
        computer_name = $env:COMPUTERNAME
        username = $env:USERNAME
        domain = $env:USERDOMAIN
        powershell_version = $PSVersionTable.PSVersion.ToString()
    }
    mac_target = @{
        ip_address = $MacIP
        username = $MacUser
        hostname = $MacHostname
    }
    tests = @{}
    overall_status = "UNKNOWN"
}

Write-LogAndHost "=== PHASE 1: Network Connectivity Test ===" "Green"

# Test 1: Ping Test
Write-LogAndHost "Test 1: Ping connectivity to Mac..." "Cyan"
try {
    $pingResult = Test-Connection -ComputerName $MacIP -Count 3 -Quiet
    if ($pingResult) {
        Write-LogAndHost "✅ Ping to $MacIP: SUCCESS" "Green"
        $TestResults.tests.ping = @{ status = "SUCCESS"; message = "Ping successful" }
    } else {
        Write-LogAndHost "❌ Ping to $MacIP: FAILED" "Red"
        $TestResults.tests.ping = @{ status = "FAILED"; message = "Ping failed" }
    }
} catch {
    Write-LogAndHost "❌ Ping test error: $($_.Exception.Message)" "Red"
    $TestResults.tests.ping = @{ status = "ERROR"; message = $_.Exception.Message }
}

# Test 2: Port 22 (SSH) Connectivity
Write-LogAndHost ""
Write-LogAndHost "Test 2: SSH port (22) connectivity..." "Cyan"
try {
    $sshPortTest = Test-NetConnection -ComputerName $MacIP -Port 22 -WarningAction SilentlyContinue
    if ($sshPortTest.TcpTestSucceeded) {
        Write-LogAndHost "✅ SSH port 22 to $MacIP: ACCESSIBLE" "Green"
        $TestResults.tests.ssh_port = @{ 
            status = "SUCCESS"
            message = "Port 22 accessible"
            latency_ms = $sshPortTest.PingReplyDetails.RoundtripTime
        }
    } else {
        Write-LogAndHost "❌ SSH port 22 to $MacIP: NOT ACCESSIBLE" "Red"
        $TestResults.tests.ssh_port = @{ status = "FAILED"; message = "Port 22 not accessible" }
    }
} catch {
    Write-LogAndHost "❌ SSH port test error: $($_.Exception.Message)" "Red"
    $TestResults.tests.ssh_port = @{ status = "ERROR"; message = $_.Exception.Message }
}

Write-LogAndHost ""
Write-LogAndHost "=== PHASE 2: SSH Client Verification ===" "Green"

# Test 3: Check for SSH client
Write-LogAndHost "Test 3: SSH client availability..." "Cyan"
$sshCommand = Get-Command ssh -ErrorAction SilentlyContinue
if ($sshCommand) {
    Write-LogAndHost "✅ SSH client found: $($sshCommand.Source)" "Green"
    $TestResults.tests.ssh_client = @{ 
        status = "SUCCESS"
        message = "SSH client available"
        path = $sshCommand.Source
        version = (ssh -V 2>&1 | Out-String).Trim()
    }
} else {
    Write-LogAndHost "❌ SSH client not found - OpenSSH may not be installed" "Red"
    $TestResults.tests.ssh_client = @{ status = "FAILED"; message = "SSH client not available" }
}

Write-LogAndHost ""
Write-LogAndHost "=== PHASE 3: SSH Connection Test ===" "Green"

# Test 4: Actual SSH Connection Test
Write-LogAndHost "Test 4: SSH connection test..." "Cyan"
if ($sshCommand -and $TestResults.tests.ssh_port.status -eq "SUCCESS") {
    try {
        Write-LogAndHost "Attempting SSH connection to $MacUser@$MacIP..."
        
        # Create a test command that should work without prompting
        $sshTestCommand = "ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL $MacUser@$MacIP `"echo 'SSH_CONNECTION_SUCCESS'; hostname; uptime; date`""
        
        Write-LogAndHost "SSH Command: $sshTestCommand" "Gray"
        
        # Execute the SSH command
        $sshResult = Invoke-Expression $sshTestCommand 2>&1
        $sshExitCode = $LASTEXITCODE
        
        if ($sshExitCode -eq 0 -and $sshResult -like "*SSH_CONNECTION_SUCCESS*") {
            Write-LogAndHost "✅ SSH connection: SUCCESS" "Green"
            Write-LogAndHost "SSH Response:" "Green"
            $sshResult | ForEach-Object { Write-LogAndHost "  $_" "Gray" }
            
            $TestResults.tests.ssh_connection = @{
                status = "SUCCESS"
                message = "SSH connection successful"
                response = $sshResult -join "`n"
                exit_code = $sshExitCode
            }
        } else {
            Write-LogAndHost "❌ SSH connection: FAILED" "Red"
            Write-LogAndHost "SSH Error/Output:" "Red"
            $sshResult | ForEach-Object { Write-LogAndHost "  $_" "Red" }
            
            $TestResults.tests.ssh_connection = @{
                status = "FAILED"
                message = "SSH connection failed"
                error_output = $sshResult -join "`n"
                exit_code = $sshExitCode
            }
        }
    } catch {
        Write-LogAndHost "❌ SSH connection error: $($_.Exception.Message)" "Red"
        $TestResults.tests.ssh_connection = @{
            status = "ERROR"
            message = $_.Exception.Message
        }
    }
} else {
    Write-LogAndHost "⚠️  Skipping SSH connection test (prerequisites not met)" "Yellow"
    $TestResults.tests.ssh_connection = @{
        status = "SKIPPED"
        message = "Prerequisites not met (SSH client or port not available)"
    }
}

Write-LogAndHost ""
Write-LogAndHost "=== PHASE 4: Additional Service Tests ===" "Green"

# Test 5: VNC Port Test
Write-LogAndHost "Test 5: VNC port (5900) test..." "Cyan"
try {
    $vncPortTest = Test-NetConnection -ComputerName $MacIP -Port 5900 -WarningAction SilentlyContinue
    if ($vncPortTest.TcpTestSucceeded) {
        Write-LogAndHost "✅ VNC port 5900: ACCESSIBLE" "Green"
        $TestResults.tests.vnc_port = @{ status = "SUCCESS"; message = "VNC port accessible" }
    } else {
        Write-LogAndHost "❌ VNC port 5900: NOT ACCESSIBLE" "Yellow"
        $TestResults.tests.vnc_port = @{ status = "FAILED"; message = "VNC port not accessible" }
    }
} catch {
    Write-LogAndHost "❌ VNC port test error: $($_.Exception.Message)" "Red"
    $TestResults.tests.vnc_port = @{ status = "ERROR"; message = $_.Exception.Message }
}

# Test 6: SMB Port Test
Write-LogAndHost ""
Write-LogAndHost "Test 6: SMB port (445) test..." "Cyan"
try {
    $smbPortTest = Test-NetConnection -ComputerName $MacIP -Port 445 -WarningAction SilentlyContinue
    if ($smbPortTest.TcpTestSucceeded) {
        Write-LogAndHost "✅ SMB port 445: ACCESSIBLE" "Green"
        $TestResults.tests.smb_port = @{ status = "SUCCESS"; message = "SMB port accessible" }
    } else {
        Write-LogAndHost "❌ SMB port 445: NOT ACCESSIBLE" "Yellow"
        $TestResults.tests.smb_port = @{ status = "FAILED"; message = "SMB port not accessible" }
    }
} catch {
    Write-LogAndHost "❌ SMB port test error: $($_.Exception.Message)" "Red"
    $TestResults.tests.smb_port = @{ status = "ERROR"; message = $_.Exception.Message }
}

Write-LogAndHost ""
Write-LogAndHost "=== FINAL RESULTS SUMMARY ===" "Magenta"

# Calculate overall status
$successfulTests = 0
$totalTests = $TestResults.tests.Count
$criticalTests = @("ping", "ssh_port", "ssh_connection")
$criticalSuccesses = 0

foreach ($testName in $TestResults.tests.Keys) {
    $testResult = $TestResults.tests[$testName]
    if ($testResult.status -eq "SUCCESS") {
        $successfulTests++
        if ($testName -in $criticalTests) {
            $criticalSuccesses++
        }
    }
}

# Determine overall status
if ($criticalSuccesses -eq $criticalTests.Count) {
    $overallStatus = "FULLY_FUNCTIONAL"
    $statusColor = "Green"
} elseif ($criticalSuccesses -ge 2) {
    $overallStatus = "MOSTLY_FUNCTIONAL" 
    $statusColor = "Yellow"
} elseif ($criticalSuccesses -ge 1) {
    $overallStatus = "LIMITED_FUNCTIONALITY"
    $statusColor = "Yellow"
} else {
    $overallStatus = "NOT_FUNCTIONAL"
    $statusColor = "Red"
}

$TestResults.overall_status = $overallStatus
$TestResults.summary = @{
    total_tests = $totalTests
    successful_tests = $successfulTests  
    critical_successes = $criticalSuccesses
    critical_total = $criticalTests.Count
    success_percentage = [math]::Round(($successfulTests / $totalTests) * 100, 1)
}

Write-LogAndHost "📊 Test Results Summary:" "Yellow"
Write-LogAndHost "├── Total Tests: $totalTests"
Write-LogAndHost "├── Successful: $successfulTests"
Write-LogAndHost "├── Success Rate: $($TestResults.summary.success_percentage)%"
Write-LogAndHost "├── Critical Tests: $criticalSuccesses/$($criticalTests.Count)"
Write-LogAndHost "└── Overall Status: $overallStatus" $statusColor

Write-LogAndHost ""
Write-LogAndHost "📋 Individual Test Results:" "Yellow"
foreach ($testName in $TestResults.tests.Keys | Sort-Object) {
    $test = $TestResults.tests[$testName]
    $icon = if ($test.status -eq "SUCCESS") { "✅" } elseif ($test.status -eq "FAILED") { "❌" } else { "⚠️" }
    $color = if ($test.status -eq "SUCCESS") { "Green" } elseif ($test.status -eq "FAILED") { "Red" } else { "Yellow" }
    Write-LogAndHost "├── $icon $testName`: $($test.status) - $($test.message)" $color
}

# Save results to JSON file
Write-LogAndHost ""
Write-LogAndHost "💾 Saving results..." "Cyan"
try {
    $TestResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultFile -Encoding UTF8
    Write-LogAndHost "✅ Results saved to: $ResultFile" "Green"
} catch {
    Write-LogAndHost "❌ Failed to save results: $($_.Exception.Message)" "Red"
}

# Display connection information if successful
if ($overallStatus -eq "FULLY_FUNCTIONAL") {
    Write-LogAndHost ""
    Write-LogAndHost "🎉 MAC CONNECTIVITY: FULLY OPERATIONAL!" "Green"
    Write-LogAndHost ""
    Write-LogAndHost "🔗 Ready-to-use connection commands:" "Cyan"
    Write-LogAndHost "   SSH: ssh $MacUser@$MacIP"
    Write-LogAndHost "   VNC: mstsc /v:$MacIP`:5900 (or use VNC client)"
    Write-LogAndHost "   SMB: \\$MacIP (Windows Explorer)"
    Write-LogAndHost ""
    Write-LogAndHost "🚀 AIMaster can now control the Mac remotely from this PC!"
} elseif ($overallStatus -in @("MOSTLY_FUNCTIONAL", "LIMITED_FUNCTIONALITY")) {
    Write-LogAndHost ""
    Write-LogAndHost "⚠️  MAC CONNECTIVITY: PARTIAL FUNCTIONALITY" "Yellow"
    Write-LogAndHost "Some services are working, but troubleshooting may be needed."
} else {
    Write-LogAndHost ""
    Write-LogAndHost "❌ MAC CONNECTIVITY: NOT FUNCTIONAL" "Red"
    Write-LogAndHost "Mac is not accessible from this PC. Check network and Mac setup."
}

Write-LogAndHost ""
Write-LogAndHost "📄 Log file saved to: $LogFile"
Write-LogAndHost "⏰ Test completed in: $((Get-Date) - $StartupTime)"
Write-LogAndHost ""
Write-LogAndHost "🏁 AIMaster Mac Connectivity Test Complete!" "Cyan"

# Return overall status for script chaining
return $overallStatus