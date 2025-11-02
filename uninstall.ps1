# Govman Uninstallation# Remove Govman directory and configurations
function Remove-GovmanInstallation {
    $govmanHome = "$env:USERPROFILE\.govman"
    
    if (-not (Test-Path $govmanHome)) {
        Write-Error "Govman does not appear to be installed ($govmanHome not found)"
    }
    
    Write-Info "Removing Govman installation directory..."
    Remove-Item -Path $govmanHome -Recurse -Force
    
    # Clean up PowerShell profile
    Write-Info "Cleaning up PowerShell profile..."
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (Test-Path $profilePath) {
        $profileContent = Get-Content -Raw $profilePath
        if ($profileContent -match "(?ms)# GOVMAN - Go Version Manager.*?# END GOVMAN") {
            $newContent = $profileContent -replace "(?ms)# GOVMAN - Go Version Manager.*?# END GOVMAN\r?\n?", ""
            $newContent = $newContent.TrimEnd()
            $newContent | Set-Content -Path $profilePath -Force
            Write-Info "Removed Govman configuration from PowerShell profile"
        }
    }
} PowerShell
# This script removes Govman and its associated files

# Ensure we stop on errors
$ErrorActionPreference = "Stop"

# Helper functions for colorized output
function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

# Remove Govman directories and files
function Remove-GovmanInstallation {
    $govmanHome = "$env:USERPROFILE\.govman"
    
    if (-not (Test-Path $govmanHome)) {
        Write-Error "Govman does not appear to be installed ($govmanHome not found)"
    }
    
    Write-Info "Removing Govman installation directory..."
    Remove-Item -Path $govmanHome -Recurse -Force
}

# Remove Govman from PATH
function Remove-GovmanFromPath {
    Write-Info "Removing Govman from PATH..."
    
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $govmanBinPath = "$env:USERPROFILE\.govman\bin"
    
    if ($userPath -like "*$govmanBinPath*") {
        $newPath = ($userPath -split ';' | Where-Object { $_ -ne $govmanBinPath }) -join ';'
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = $newPath
    }
}

# Main uninstallation
function Uninstall-Govman {
    Write-Info "Uninstalling Govman..."
    
    Remove-GovmanFromPath
    Remove-GovmanInstallation
    
    Write-Success "Govman has been uninstalled successfully!"
    Write-Info "Please restart your terminal for the changes to take effect"
}

# Confirm uninstallation
$confirmation = Read-Host "This will remove Govman and all installed Go versions. Continue? [y/N]"
if ($confirmation -match '^[Yy]') {
    Uninstall-Govman
} else {
    Write-Info "Uninstallation cancelled"
}
