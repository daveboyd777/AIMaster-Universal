function Connect-Mac {
    <#
    .SYNOPSIS
    Connect to Mac system via various methods
    
    .DESCRIPTION
    Provides multiple connection methods to the Mac system including SSH, VNC, and file sharing
    
    .PARAMETER Method
    Connection method: SSH, VNC, SMB, Test, Info
    
    .PARAMETER IP
    Mac IP address (default: 100.77.255.169)
    
    .PARAMETER User  
    Username (default: daveboyd)
    
    .EXAMPLE
    Connect-Mac -Method SSH
    Connect-Mac -Method VNC
    Connect-Mac -Method Test
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("SSH", "VNC", "SMB", "Test", "Info")]
        [string]$Method = "SSH",
        
        [Parameter(Mandatory=$false)]
        [string]$IP = "100.77.255.169",
        
        [Parameter(Mandatory=$false)]
        [string]$User = "daveboyd"
    )
    
    $MacHostname = "sf-Deb-Book.local"
    
    Write-Host "🔗 AIMaster Mac Connection" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host "Mac: $MacHostname ($IP)" -ForegroundColor Green
    Write-Host "User: $User" -ForegroundColor Green
    Write-Host ""
    
    switch ($Method) {
        "SSH" {
            Write-Host "Connecting via SSH..." -ForegroundColor Yellow
            if (Get-Command ssh -ErrorAction SilentlyContinue) {
                ssh "$User@$IP"
            } else {
                Write-Host "SSH client not found. Please install OpenSSH." -ForegroundColor Red
            }
        }
        "VNC" {
            Write-Host "VNC Connection Details:" -ForegroundColor Yellow
            Write-Host "Address: vnc://$IP:5900" -ForegroundColor Green
            Write-Host "Password hint: aimaster123" -ForegroundColor Green
            
            if ($IsWindows) {
                Write-Host "Use a VNC client like RealVNC, TightVNC, or UltraVNC" -ForegroundColor Cyan
            } elseif ($IsMacOS) {
                Write-Host "Opening Finder connection..." -ForegroundColor Cyan
                Start-Process "vnc://$IP:5900"
            } else {
                Write-Host "Use a VNC client like Remmina or TigerVNC" -ForegroundColor Cyan
            }
        }
        "SMB" {
            Write-Host "File Sharing Connection:" -ForegroundColor Yellow
            Write-Host "Address: smb://$IP" -ForegroundColor Green
            
            if ($IsWindows) {
                Write-Host "Opening Windows Explorer..." -ForegroundColor Cyan
                Start-Process "\\"
            } elseif ($IsMacOS) {
                Write-Host "Opening Finder..." -ForegroundColor Cyan
                Start-Process "smb://$IP"
            } else {
                Write-Host "Mount with: sudo mount -t cifs //$IP/share /mnt/mac" -ForegroundColor Cyan
            }
        }
        "Test" {
            Write-Host "Testing connections..." -ForegroundColor Yellow
            
            # Test SSH
            Write-Host "Testing SSH..." -ForegroundColor Cyan
            try {
                $sshResult = ssh -o ConnectTimeout=5 -o BatchMode=yes "$User@$IP" "echo 'SSH: OK'; hostname" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ SSH connection successful" -ForegroundColor Green
                    Write-Host "Response: $sshResult" -ForegroundColor Gray
                } else {
                    Write-Host "❌ SSH connection failed" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ SSH test error: $_" -ForegroundColor Red
            }
            
            # Test VNC port
            Write-Host "Testing VNC port 5900..." -ForegroundColor Cyan
            try {
                $vnc = Test-NetConnection -ComputerName $IP -Port 5900 -WarningAction SilentlyContinue
                if ($vnc.TcpTestSucceeded) {
                    Write-Host "✅ VNC port 5900 accessible" -ForegroundColor Green
                } else {
                    Write-Host "❌ VNC port 5900 not accessible" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ VNC test error: $_" -ForegroundColor Red
            }
            
            # Test SMB port
            Write-Host "Testing SMB port 445..." -ForegroundColor Cyan
            try {
                $smb = Test-NetConnection -ComputerName $IP -Port 445 -WarningAction SilentlyContinue
                if ($smb.TcpTestSucceeded) {
                    Write-Host "✅ SMB port 445 accessible" -ForegroundColor Green
                } else {
                    Write-Host "❌ SMB port 445 not accessible" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ SMB test error: $_" -ForegroundColor Red
            }
        }
        "Info" {
            Write-Host "Mac Connection Information:" -ForegroundColor Yellow
            Write-Host "- SSH: ssh $User@$IP" -ForegroundColor Green
            Write-Host "- VNC: vnc://$IP:5900" -ForegroundColor Green
            Write-Host "- SMB: smb://$IP (Mac/Linux) or \\ (Windows)" -ForegroundColor Green
            Write-Host "- Local: ssh $User@localhost" -ForegroundColor Green
            Write-Host ""
            Write-Host "Available Methods:" -ForegroundColor Yellow
            Write-Host "- Connect-Mac -Method SSH" -ForegroundColor Cyan
            Write-Host "- Connect-Mac -Method VNC" -ForegroundColor Cyan
            Write-Host "- Connect-Mac -Method SMB" -ForegroundColor Cyan
            Write-Host "- Connect-Mac -Method Test" -ForegroundColor Cyan
        }
    }
}

# Create alias for convenience
New-Alias -Name "mac" -Value "Connect-Mac" -Force -ErrorAction SilentlyContinue

Export-ModuleMember -Function Connect-Mac -Alias mac
