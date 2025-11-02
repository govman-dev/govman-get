@echo off
setlocal EnableDelayedExpansion

:: Govman Uninstallation Script for Windows
:: This script removes Govman and its associated files

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

:: Main uninstallation
:main
set "GOVMAN_HOME=%USERPROFILE%\.govman"

:: Check if Govman is installed
if not exist "%GOVMAN_HOME%" (
    call :error "Govman does not appear to be installed (%GOVMAN_HOME% not found)"
    exit /b 1
)

:: Confirm uninstallation
set /p CONFIRM="This will remove Govman and all installed Go versions. Continue? [y/N] "
if /i "%CONFIRM%" neq "y" (
    call :info "Uninstallation cancelled"
    exit /b 0
)

:: Remove from PATH
call :info "Removing Govman from PATH..."
for /f "tokens=2* delims= " %%a in ('reg query "HKCU\Environment" /v "Path" 2^>nul') do set "OLD_PATH=%%b"
set "NEW_PATH=!OLD_PATH:%GOVMAN_HOME%\bin;=!"
setx PATH "%NEW_PATH%"

:: Remove shell integration
call :info "Removing Command Prompt integration..."
set "GOVMAN_CMD=%GOVMAN_HOME%\bin\govman.cmd"
if exist "%GOVMAN_CMD%" del "%GOVMAN_CMD%"

:: Remove from registry
reg delete "HKCU\Software\Microsoft\Command Processor" /v "AutoRun" /f 2>nul

:: Remove Govman directory
call :info "Removing Govman installation directory..."
rd /s /q "%GOVMAN_HOME%" 2>nul

if %ERRORLEVEL% neq 0 (
    call :error "Failed to remove Govman directory"
    exit /b 1
)

call :success "Govman has been uninstalled successfully!"
call :info "Please restart your command prompt for the changes to take effect"

exit /b 0

:end
endlocal
