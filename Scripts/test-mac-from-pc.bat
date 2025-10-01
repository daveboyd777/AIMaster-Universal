@echo off
REM AIMaster Mac Connectivity Test - Windows Batch Launcher
REM Run this from Windows PC in room504 to test Mac connectivity

echo ========================================
echo   AIMaster Mac Connectivity Test
echo ========================================
echo.
echo Testing connection to Mac (100.77.255.169)...
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell available'" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell not found!
    echo Please ensure PowerShell is installed.
    pause
    exit /b 1
)

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0startup-test-mac-connectivity.ps1"

REM Check the result
if errorlevel 1 (
    echo.
    echo WARNING: Test completed with some issues.
) else (
    echo.
    echo Test completed successfully!
)

echo.
echo Press any key to close this window...
pause >nul