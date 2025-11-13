<#
.SYNOPSIS
    Disables all Windows Firewall profiles (Domain, Public, and Private).

.DESCRIPTION
    This script disables the Windows Firewall for all network profiles
    after verifying administrative privileges. Includes logging and error handling.

.NOTES
    Author: Emanuel Leite
    Version: 1.1
#>

# --- Helper Function ---
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp][$Type] $Message"
}

# --- Step 1: Verify admin privileges ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "You must run this script as Administrator." "ERROR"
    exit 1
}

# --- Step 2: Display current firewall status ---
try {
    Write-Log "Checking current firewall profiles..."
    $profiles = Get-NetFirewallProfile | Select-Object Name, Enabled
    $profiles | Format-Table

    # Check if all profiles are already disabled
    if ($profiles.Enabled -notcontains $true) {
        Write-Log "All firewall profiles are already disabled. No action required."
        exit 1
    }

    Write-Log "Some profiles are still enabled. Proceeding to disable them..."
} catch {
    Write-Log "Failed to retrieve current firewall status: $($_.Exception.Message)" "ERROR"
    exit 1
}

# --- Step 3: Confirm action ---
Write-Host ""
$confirmation = Read-Host "⚠️ Are you sure you want to disable ALL Windows Firewall profiles? (Y/N)"
if ($confirmation -notin @("Y", "y", "Yes", "yes")) {
    Write-Log "Operation cancelled by user."
    exit 0
}

# --- Step 4: Disable all firewall profiles ---
try {
    Write-Log "Disabling all Windows Firewall profiles..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction Stop
    Write-Log "✅ Windows Firewall has been disabled for Domain, Public, and Private profiles."
} catch {
    Write-Log "Failed to disable firewall profiles: $($_.Exception.Message)" "ERROR"
    exit 1
}

# --- Step 5: Verify new status ---
try {
    Write-Log "Verifying firewall status after change..."
    Get-NetFirewallProfile | Select-Object Name, Enabled | Format-Table
    Write-Log "Firewall status verification complete."
} catch {
    Write-Log "Failed to verify firewall status: $($_.Exception.Message)" "WARNING"
}