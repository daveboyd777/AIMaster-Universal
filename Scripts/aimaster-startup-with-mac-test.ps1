# AIMaster Startup Integration Script
# Automatically tests Mac connectivity when AIMaster starts on PC
# Place this in AIMaster startup directory or call from main startup script

param(
    [Parameter(Mandatory=$false)]
    [switch]$Silent = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$AIMasterPath = $null
)

Write-Host "🚀 AIMaster Startup with Mac Connectivity Test" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$StartupTime = Get-Date
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Configuration
$MacTestScript = Join-Path $ScriptDir "startup-test-mac-connectivity.ps1"
$LogDir = if ($env:TEMP) { $env:TEMP } else { $env:USERPROFILE }
$StartupLogFile = Join-Path $LogDir "aimaster_startup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-StartupLog {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    if (-not $Silent) {
        Write-Host $logEntry -ForegroundColor $Color
    }
    Add-Content -Path $StartupLogFile -Value $logEntry
}

Write-StartupLog "AIMaster Startup Initiated" "Green"
Write-StartupLog "PC: $env:COMPUTERNAME"
Write-StartupLog "User: $env:USERNAME"
Write-StartupLog "Startup Time: $StartupTime"
Write-StartupLog "Script Directory: $ScriptDir"

# Phase 1: Basic AIMaster Environment Setup
Write-StartupLog ""
Write-StartupLog "=== PHASE 1: AIMaster Environment Setup ===" "Green"

# Check if AIMaster path is provided or try to detect
if (-not $AIMasterPath) {
    $PossiblePaths = @(
        "C:\AIMaster",
        "C:\AIMaster-Universal", 
        "$env:USERPROFILE\AIMaster",
        "$env:USERPROFILE\AIMaster-Universal",
        "D:\AIMaster",
        "$env:ProgramFiles\AIMaster"
    )
    
    foreach ($path in $PossiblePaths) {
        if (Test-Path $path) {
            $AIMasterPath = $path
            Write-StartupLog "Found AIMaster at: $AIMasterPath" "Green"
            break
        }
    }
}

if ($AIMasterPath -and (Test-Path $AIMasterPath)) {
    Write-StartupLog "✅ AIMaster directory: $AIMasterPath" "Green"
    $env:AIMASTER_HOME = $AIMasterPath
} else {
    Write-StartupLog "⚠️  AIMaster directory not found - using current directory" "Yellow"
    $env:AIMASTER_HOME = $ScriptDir
}

# Phase 2: Mac Connectivity Test
Write-StartupLog ""
Write-StartupLog "=== PHASE 2: Mac Connectivity Test ===" "Green"

$MacTestSuccess = $false
$MacTestStatus = "UNKNOWN"

if (Test-Path $MacTestScript) {
    Write-StartupLog "Found Mac connectivity test script: $MacTestScript" "Green"
    
    try {
        Write-StartupLog "Executing Mac connectivity test..." "Cyan"
        
        # Run the Mac test script and capture the result
        $MacTestOutput = & $MacTestScript 2>&1
        $MacTestStatus = $MacTestOutput[-1] # Last line should be the return value
        
        if ($MacTestStatus -eq "FULLY_FUNCTIONAL") {
            Write-StartupLog "✅ Mac connectivity test: SUCCESS - Mac is fully accessible" "Green"
            $MacTestSuccess = $true
        } elseif ($MacTestStatus -in @("MOSTLY_FUNCTIONAL", "LIMITED_FUNCTIONALITY")) {
            Write-StartupLog "⚠️  Mac connectivity test: PARTIAL - Some Mac services accessible" "Yellow"
            $MacTestSuccess = $true
        } else {
            Write-StartupLog "❌ Mac connectivity test: FAILED - Mac not accessible" "Red"
            $MacTestSuccess = $false
        }
        
        # Log summary of test output
        if (-not $Silent) {
            Write-StartupLog "Mac Test Summary:" "Cyan"
            $MacTestOutput | Select-Object -Last 10 | ForEach-Object {
                Write-StartupLog "  $_" "Gray"
            }
        }
        
    } catch {
        Write-StartupLog "❌ Error running Mac connectivity test: $($_.Exception.Message)" "Red"
        $MacTestSuccess = $false
        $MacTestStatus = "ERROR"
    }
} else {
    Write-StartupLog "❌ Mac connectivity test script not found: $MacTestScript" "Red"
    Write-StartupLog "Expected location: $MacTestScript" "Yellow"
    $MacTestSuccess = $false
    $MacTestStatus = "SCRIPT_NOT_FOUND"
}

# Phase 3: AIMaster Services Initialization
Write-StartupLog ""
Write-StartupLog "=== PHASE 3: AIMaster Services Initialization ===" "Green"

# Set environment variables for AIMaster
$env:AIMASTER_MAC_STATUS = $MacTestStatus
$env:AIMASTER_MAC_IP = "100.77.255.169"
$env:AIMASTER_MAC_USER = "daveboyd"
$env:AIMASTER_MAC_HOSTNAME = "sf-Deb-Book.local"

Write-StartupLog "Environment variables set:" "Cyan"
Write-StartupLog "  AIMASTER_HOME: $env:AIMASTER_HOME"
Write-StartupLog "  AIMASTER_MAC_STATUS: $env:AIMASTER_MAC_STATUS"
Write-StartupLog "  AIMASTER_MAC_IP: $env:AIMASTER_MAC_IP"

# Check for additional AIMaster scripts
$AIMasterScripts = @(
    "aimaster-init.ps1",
    "aimaster-startup.ps1", 
    "Initialize-AIMaster.ps1"
)

$FoundAIMasterScript = $false
foreach ($scriptName in $AIMasterScripts) {
    $scriptPath = Join-Path $ScriptDir $scriptName
    if (Test-Path $scriptPath) {
        Write-StartupLog "Found AIMaster script: $scriptPath" "Green"
        try {
            Write-StartupLog "Executing AIMaster initialization: $scriptName" "Cyan"
            & $scriptPath
            Write-StartupLog "✅ AIMaster script executed successfully" "Green"
            $FoundAIMasterScript = $true
            break
        } catch {
            Write-StartupLog "❌ Error executing AIMaster script: $($_.Exception.Message)" "Red"
        }
    }
}

if (-not $FoundAIMasterScript) {
    Write-StartupLog "ℹ️  No additional AIMaster initialization scripts found" "Yellow"
}

# Phase 4: Startup Summary and Status Report
Write-StartupLog ""
Write-StartupLog "=== PHASE 4: Startup Summary ===" "Magenta"

$StartupDuration = (Get-Date) - $StartupTime
$OverallSuccess = $true

# Determine overall startup status
if ($MacTestSuccess) {
    $StartupStatus = "SUCCESS_WITH_MAC"
    Write-StartupLog "🎉 AIMaster Startup: COMPLETE WITH MAC ACCESS" "Green"
} else {
    $StartupStatus = "SUCCESS_NO_MAC"
    Write-StartupLog "⚠️  AIMaster Startup: COMPLETE WITHOUT MAC ACCESS" "Yellow" 
}

# Create startup status file
$StatusFile = Join-Path $LogDir "aimaster_startup_status.json"
$StatusData = @{
    timestamp = $StartupTime.ToString("yyyy-MM-ddTHH:mm:ss")
    duration_seconds = [math]::Round($StartupDuration.TotalSeconds, 2)
    pc_info = @{
        computer_name = $env:COMPUTERNAME
        username = $env:USERNAME
        domain = $env:USERDOMAIN
    }
    startup_status = $StartupStatus
    mac_connectivity = @{
        status = $MacTestStatus
        success = $MacTestSuccess
        ip_address = $env:AIMASTER_MAC_IP
        test_script_found = (Test-Path $MacTestScript)
    }
    aimaster = @{
        home_directory = $env:AIMASTER_HOME
        additional_script_executed = $FoundAIMasterScript
    }
    files = @{
        startup_log = $StartupLogFile
        status_file = $StatusFile
    }
}

try {
    $StatusData | ConvertTo-Json -Depth 4 | Out-File -FilePath $StatusFile -Encoding UTF8
    Write-StartupLog "✅ Status file saved: $StatusFile" "Green"
} catch {
    Write-StartupLog "❌ Failed to save status file: $($_.Exception.Message)" "Red"
}

# Final summary
Write-StartupLog ""
Write-StartupLog "📊 AIMaster Startup Summary:" "Yellow"
Write-StartupLog "├── Duration: $([math]::Round($StartupDuration.TotalSeconds, 1)) seconds"
Write-StartupLog "├── Overall Status: $StartupStatus"
Write-StartupLog "├── Mac Connectivity: $MacTestStatus"
Write-StartupLog "├── AIMaster Home: $((Split-Path -Leaf $env:AIMASTER_HOME))"
Write-StartupLog "└── Log File: $(Split-Path -Leaf $StartupLogFile)"

if ($MacTestSuccess) {
    Write-StartupLog ""
    Write-StartupLog "🚀 READY: AIMaster can now remotely control the Mac!" "Green"
    Write-StartupLog "💡 Try these commands:" "Cyan"
    Write-StartupLog "   ssh daveboyd@100.77.255.169" "Cyan"
    Write-StartupLog "   # Or use the connection scripts in the AIMaster directory" "Gray"
} else {
    Write-StartupLog ""
    Write-StartupLog "⚠️  Mac connectivity issues detected." "Yellow"
    Write-StartupLog "💡 Troubleshooting:" "Cyan"
    Write-StartupLog "   1. Ensure Mac is powered on and connected to network" "Gray"
    Write-StartupLog "   2. Check if Mac IP address has changed (currently: 100.77.255.169)" "Gray"
    Write-StartupLog "   3. Verify Mac SSH service is running" "Gray"
}

Write-StartupLog ""
Write-StartupLog "🏁 AIMaster Startup Complete!" "Cyan"
Write-StartupLog "Startup completed at: $(Get-Date)"

# Display quick status if not running silently
if (-not $Silent) {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "🎯 QUICK STATUS:" -ForegroundColor Yellow
    Write-Host "   PC: $env:COMPUTERNAME" -ForegroundColor White
    Write-Host "   Mac Status: $MacTestStatus" -ForegroundColor $(if ($MacTestSuccess) { "Green" } else { "Red" })
    Write-Host "   Duration: $([math]::Round($StartupDuration.TotalSeconds, 1))s" -ForegroundColor White
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
}

return $StartupStatus