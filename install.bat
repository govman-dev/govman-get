@echo off
setlocal EnableDelayedExpansion

:: Govman Installation Script for Windows
:: This script installs the Govman Go Version Manager

:: Colors for output
set "BLUE=[94m"
set "GREEN=[92m"
set "RED=[91m"
set "NC=[0m"

:: Helper functions for output
:info
echo %BLUE%INFO:%NC% %~1
exit /b 0

:success
echo %GREEN%SUCCESS:%NC% %~1
exit /b 0

:error
echo %RED%ERROR:%NC% %~1
exit /b 1

:: Detect architecture
:detect_arch
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set ARCH=amd64
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set ARCH=arm64
) else (
    set ARCH=386
)
exit /b 0

:: Main installation
:main
call :info "Installing Govman..."

:: Create directories
set "GOVMAN_HOME=%USERPROFILE%\.govman"
mkdir "%GOVMAN_HOME%\bin" 2>nul
mkdir "%GOVMAN_HOME%\versions" 2>nul
mkdir "%GOVMAN_HOME%\cache" 2>nul

:: Detect architecture
call :detect_arch

:: Download latest release
set "BINARY_NAME=govman-windows-%ARCH%.exe"
call :info "Downloading Govman binary..."

:: Use PowerShell to download binary
powershell -Command "$ProgressPreference = 'SilentlyContinue'; $latestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/justjundana/govman/releases/latest'; $asset = $latestRelease.assets | Where-Object { $_.name -eq '%BINARY_NAME%' }; if ($asset) { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%GOVMAN_HOME%\bin\govman.exe' } else { exit 1 }"

if %ERRORLEVEL% neq 0 (
    call :error "Failed to download Govman binary"
    exit /b 1
)

:: Add to PATH
call :info "Adding Govman to PATH..."
setx PATH "%GOVMAN_HOME%\bin;%PATH%"

:: Configure shell integration
call :info "Setting up Command Prompt integration..."

:: Create a batch file to initialize Govman environment
set "GOVMAN_CMD=%GOVMAN_HOME%\bin\govman.cmd"
(
    echo @echo off
    echo REM GOVMAN - Go Version Manager
    echo setlocal enabledelayedexpansion
    echo.
    echo REM Add Govman to PATH
    echo set "PATH=%GOVMAN_HOME%\bin;%%PATH%%"
    echo.
    echo REM Auto-switch Go versions
    echo if exist .govman-version (
    echo     for /f "tokens=*" %%v in (.govman-version^) do (
    echo         govman.exe use %%v ^> nul 2^>^&1
    echo         if !errorlevel! neq 0 (
    echo             echo Warning: Failed to switch to Go %%v
    echo         ^)
    echo     ^)
    echo ^)
    echo.
    echo REM END GOVMAN
) > "%GOVMAN_CMD%"

:: Add to registry for Command Prompt initialization
reg add "HKCU\Software\Microsoft\Command Processor" /v "AutoRun" /t REG_SZ /d "%GOVMAN_CMD%" /f

:: Initialize Govman
call :info "Initializing Govman..."
"%GOVMAN_HOME%\bin\govman.exe" init --force

if %ERRORLEVEL% neq 0 (
    call :error "Failed to initialize Govman"
    exit /b 1
)

call :success "Govman has been installed successfully!"
call :info "Please restart your command prompt to use Govman"
call :info "Run 'govman --help' to get started"

exit /b 0

:end
endlocal
