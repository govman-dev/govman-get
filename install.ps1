# Govman Installation Script for PowerShell
# This script installs the Govman Go Version Manager

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

# Detect OS architecture
function Get-OSArchitecture {
    $arch = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
    switch ($arch) {
        "AMD64" { return "amd64" }
        "ARM64" { return "arm64" }
        default { return "386" }
    }
}

# Setup directories
function Initialize-GovmanDirectories {
    $govmanHome = "$env:USERPROFILE\.govman"
    
    Write-Info "Creating Govman directories..."
    
    New-Item -ItemType Directory -Force -Path "$govmanHome\bin" | Out-Null
    New-Item -ItemType Directory -Force -Path "$govmanHome\versions" | Out-Null
    New-Item -ItemType Directory -Force -Path "$govmanHome\cache" | Out-Null
    
    return $govmanHome
}

# Download and install binary
function Install-GovmanBinary {
    param([string]$GovmanHome)
    
    $arch = Get-OSArchitecture
    $binaryName = "govman-windows-$arch.exe"
    
    Write-Info "Detecting latest version..."
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/justjundana/govman/releases/latest"
    $asset = $latestRelease.assets | Where-Object { $_.name -eq $binaryName }
    
    if (-not $asset) {
        Write-Error "Could not find binary for your platform: Windows/$arch"
    }
    
    Write-Info "Downloading Govman..."
    $downloadPath = "$GovmanHome\bin\govman.exe"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath
    
    # Add to PATH
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $govmanBinPath = "$GovmanHome\bin"
    
    if ($userPath -notlike "*$govmanBinPath*") {
        Write-Info "Adding Govman to PATH..."
        $newPath = "$govmanBinPath;$userPath"
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = "$govmanBinPath;$env:Path"
    }
}

# Add or update Govman configuration in PowerShell profile
function Update-GovmanProfile {
    param([string]$GovmanHome)
    
    Write-Info "Updating PowerShell profile..."
    
    # Get the PowerShell profile path
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path -Parent $profilePath
    
    # Create profile directory if it doesn't exist
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Read existing profile content
    $profileContent = ""
    if (Test-Path $profilePath) {
        $profileContent = Get-Content -Raw $profilePath
    }
    
    # Remove existing GOVMAN block if present
    if ($profileContent -match "(?ms)# GOVMAN - Go Version Manager.*?# END GOVMAN") {
        $profileContent = $profileContent -replace "(?ms)# GOVMAN - Go Version Manager.*?# END GOVMAN\r?\n?", ""
    }
    
    # Create new GOVMAN block
    $govmanBlock = @"

# GOVMAN - Go Version Manager
`$env:Path = "`$GovmanHome\bin;`$env:Path"

# Auto-switch Go versions function
function Switch-GovmanVersion {
    if (Test-Path .govman-version) {
        `$version = Get-Content .govman-version -Raw
        `$version = `$version.Trim()
        if (`$version) {
            Write-Host "Auto-switching to Go `$version (required by .govman-version)"
            & govman.exe use `$version
        }
    }
}

# Set up location change monitoring
`$GovmanPrevPath = Get-Location
function Prompt {
    `$currentPath = Get-Location
    if (`$currentPath.Path -ne `$script:GovmanPrevPath.Path) {
        `$script:GovmanPrevPath = `$currentPath
        Switch-GovmanVersion
    }
    # Return the default PowerShell prompt
    "PS `$(`$executionContext.SessionState.Path.CurrentLocation)`$('>' * (`$nestedPromptLevel + 1)) "
}

# Initialize on startup
Switch-GovmanVersion
# END GOVMAN

"@
    
    # Append new block to profile
    $profileContent += $govmanBlock
    $profileContent | Set-Content -Path $profilePath -Force
    
    Write-Info "PowerShell profile updated at: $profilePath"
}

# Initialize Govman
function Initialize-Govman {
    param([string]$GovmanHome)
    
    Write-Info "Initializing Govman..."
    Update-GovmanProfile -GovmanHome $GovmanHome
    
    # Initialize govman
    & "$GovmanHome\bin\govman.exe" init --force
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to initialize Govman"
    }
}

# Main installation
function Install-Govman {
    Write-Info "Installing Govman..."
    
    $govmanHome = Initialize-GovmanDirectories
    Install-GovmanBinary -GovmanHome $govmanHome
    Initialize-Govman -GovmanHome $govmanHome
    
    Write-Success "Govman has been installed successfully!"
    Write-Info "Please restart your terminal to use Govman"
    Write-Info "Run 'govman --help' to get started"
}

# Start installation
Install-Govman
