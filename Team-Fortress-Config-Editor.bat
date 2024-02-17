@echo off
setlocal enabledelayedexpansion

ver | find "10." > nul
if %errorlevel% neq 0 (
    echo Windows 10 and above only, please upgrade!
    pause
    exit /b 1
)

set "repoURL=https://raw.githubusercontent.com/UltraToon/Team-Fortress-Config-Editor/main"
set "scriptName=main.ps1"

echo Downloading %scriptName%...
powershell -executionpolicy bypass -command "& { Invoke-Expression ((New-Object Net.WebClient).DownloadString('%repoURL%/%scriptName%')) }"

if %errorlevel% neq 0 (
    echo Failed to download/execute %scriptName%. Try again later!
    echo Open an issue: https://github.com/UltraToon/Team-Fortress-Config-Editor/issues
    pause
    exit /b 1
)
