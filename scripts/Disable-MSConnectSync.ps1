<#
.SYNOPSIS
    Disables Azure AD Connect synchronization in a Microsoft 365 tenant.

.DESCRIPTION
    This script disables the sync cycle in Azure AD Connect and sets the tenant
    to disable on-premises synchronization via Microsoft Graph API.

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

# --- Step 1: Verify current sync status ---
try {
    $scheduler = Get-ADSyncScheduler
    Write-Log "Current sync status: $($scheduler.SyncCycleEnabled)"
} catch {
    Write-Log "Could not retrieve ADSyncScheduler. Is Azure AD Connect installed?" "ERROR"
    exit 1
}

# --- Step 2: Disable local sync cycle ---
try {
    Write-Log "Disabling local sync cycle..."
    Set-ADSyncScheduler -SyncCycleEnabled $false
    Write-Log "Sync cycle disabled successfully."
} catch {
    Write-Log "Failed to disable the sync cycle: $($_.Exception.Message)" "ERROR"
    exit 1
}

# --- Step 3: Ensure Microsoft Graph modules are installed ---
$modules = @("Microsoft.Graph", "Microsoft.Graph.Beta")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        try {
            Write-Log "Installing module $module..."
            Install-Module $module -AllowClobber -Force -ErrorAction Stop
        } catch {
            Write-Log "Failed to install $module: $($_.Exception.Message)" "ERROR"
            exit 1
        }
    } else {
        Write-Log "Module $module already installed."
    }
}

# --- Step 4: Connect to Microsoft Graph ---
try {
    Write-Log "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes "Organization.ReadWrite.All"
    Write-Log "Connected to Microsoft Graph successfully."
} catch {
    Write-Log "Failed to connect to Microsoft Graph: $($_.Exception.Message)" "ERROR"
    exit 1
}

# --- Step 5: Verify and disable synchronization ---
try {
    $org = Get-MgOrganization | Select-Object Id, DisplayName, OnPremisesSyncEnabled
    Write-Log "Organization: $($org.DisplayName)"
    Write-Log "Current OnPremisesSyncEnabled: $($org.OnPremisesSyncEnabled)"

    if ($org.OnPremisesSyncEnabled -eq $true) {
        Write-Log "Disabling on-premises synchronization..."
        $body = @{ OnPremisesSyncEnabled = $false }
        Update-MgOrganization -OrganizationId $org.Id -BodyParameter $body
        Write-Log "On-premises synchronization disabled successfully."
    } else {
        Write-Log "On-premises synchronization is already disabled."
    }
} catch {
    Write-Log "Failed to update synchronization status: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Log "Sync disable process completed successfully."


