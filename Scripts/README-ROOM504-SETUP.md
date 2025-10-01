# AIMaster Room504 PC - Mac Connectivity Setup

## 🎯 Purpose
This directory contains scripts to test Mac connectivity from the PC in room504 when AIMaster starts up.

## 📁 Files Overview

| File | Purpose | How to Use |
|------|---------|------------|
| `startup-test-mac-connectivity.ps1` | Main PowerShell test script | Run automatically or manually |
| `test-mac-from-pc.bat` | Windows batch launcher | Double-click to run |
| `aimaster-startup-with-mac-test.ps1` | AIMaster integration script | Place in startup directory |
| `README-ROOM504-SETUP.md` | This instruction file | Read for setup info |

## 🚀 Quick Start Instructions

### Option 1: Manual Test (Immediate)
1. Copy these files to the PC in room504
2. Double-click `test-mac-from-pc.bat`
3. Watch the test results

### Option 2: AIMaster Integration (Automatic)
1. Copy all files to your AIMaster directory on the PC
2. Update your AIMaster startup script to call `aimaster-startup-with-mac-test.ps1`
3. AIMaster will automatically test Mac connectivity on startup

### Option 3: PowerShell Direct
```powershell
# Run from PowerShell
.\startup-test-mac-connectivity.ps1

# Or with custom parameters
.\startup-test-mac-connectivity.ps1 -MacIP "100.77.255.169" -MacUser "daveboyd"
```

## 🎯 Target Mac Information
- **IP Address**: `100.77.255.169`
- **Hostname**: `sf-Deb-Book.local`
- **Username**: `daveboyd`
- **SSH Port**: `22`
- **VNC Port**: `5900`
- **SMB Port**: `445`

## 📊 What the Test Checks

### ✅ Critical Tests (Must Pass)
1. **Ping Test**: Basic network connectivity
2. **SSH Port (22)**: SSH service accessibility
3. **SSH Connection**: Actual SSH login and command execution

### 🔍 Additional Tests (Nice to Have)
4. **SSH Client**: Windows OpenSSH client availability
5. **VNC Port (5900)**: Screen sharing accessibility
6. **SMB Port (445)**: File sharing accessibility

## 🎯 Expected Results

### ✅ Success Scenarios
- **FULLY_FUNCTIONAL**: All tests pass, Mac is completely accessible
- **MOSTLY_FUNCTIONAL**: Critical tests pass, some optional services may be unavailable
- **LIMITED_FUNCTIONALITY**: Basic connectivity works but SSH may have issues

### ❌ Failure Scenarios
- **NOT_FUNCTIONAL**: Mac is not reachable from PC
- **ERROR**: Script errors or configuration issues
- **SCRIPT_NOT_FOUND**: Setup files missing

## 📄 Log Files Location
- **Windows**: `%TEMP%\aimaster_mac_test_YYYYMMDD_HHMMSS.log`
- **Status File**: `%TEMP%\aimaster_mac_connectivity_status.json`

## 🔧 Troubleshooting

### If Tests Fail:
1. **Check Network**: Ensure PC and Mac are on same network
2. **Verify Mac IP**: IP address may have changed
3. **Mac SSH Service**: Ensure SSH is enabled on Mac
4. **Firewall**: Check Windows firewall isn't blocking SSH
5. **SSH Client**: Install OpenSSH client if missing

### Common Issues:
| Issue | Solution |
|-------|----------|
| "SSH client not found" | Install OpenSSH: `Add-WindowsCapability -Online -Name OpenSSH.Client*` |
| "Port 22 not accessible" | Check Mac SSH settings and firewall |
| "Ping failed" | Verify network connectivity and IP address |
| "PowerShell execution policy" | Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |

## 🚀 Integration with AIMaster

### Startup Integration
Add this to your main AIMaster startup script:
```powershell
# Test Mac connectivity on startup
$MacStatus = & ".\Scripts\aimaster-startup-with-mac-test.ps1"

if ($MacStatus -eq "SUCCESS_WITH_MAC") {
    Write-Host "🎉 Mac is accessible! Remote control ready." -ForegroundColor Green
} else {
    Write-Host "⚠️  Mac connectivity issues detected." -ForegroundColor Yellow
}
```

### Environment Variables
After running, these variables will be available:
- `$env:AIMASTER_MAC_STATUS` - Overall connectivity status
- `$env:AIMASTER_MAC_IP` - Mac IP address
- `$env:AIMASTER_MAC_USER` - Mac username
- `$env:AIMASTER_MAC_HOSTNAME` - Mac hostname

## 🎯 Success Indicators

When everything works correctly, you should see:
```
🎉 MAC CONNECTIVITY: FULLY OPERATIONAL!

🔗 Ready-to-use connection commands:
   SSH: ssh daveboyd@100.77.255.169
   VNC: mstsc /v:100.77.255.169:5900 (or use VNC client)
   SMB: \\100.77.255.169 (Windows Explorer)

🚀 AIMaster can now control the Mac remotely from this PC!
```

## 📞 Support

If you encounter issues:
1. Check the generated log files for detailed error messages
2. Verify all prerequisite files are in place
3. Test network connectivity manually: `ping 100.77.255.169`
4. Test SSH manually: `ssh daveboyd@100.77.255.169`

---

**🎯 Goal**: When you restart AIMaster in room504, you should see automatic Mac connectivity testing and confirmation that remote Mac control is ready!