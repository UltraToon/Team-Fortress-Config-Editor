@echo off
setlocal enabledelayedexpansion

ver | find "10." > nul
if %errorlevel% neq 0 (
    echo Windows 10 and above only, please upgrade!
    pause
    exit /b 1
)

powershell -executionpolicy bypass -command "& { Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/UltraToon/Team-Fortress-Config-Editor/main/main.ps1')) }"

if %errorlevel% neq 0 (
    echo Failed to download/execute main.ps1 (Team Fortress Config Editor). Try again later!
    echo Open an issue: https://github.com/UltraToon/Team-Fortress-Config-Editor/issues
    pause
    exit /b 1
)
