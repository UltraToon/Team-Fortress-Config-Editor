@echo off
setlocal enabledelayedexpansion

ver | find "10." > nul
if %errorlevel% neq 0 (
    echo Windows 10 and above only, please upgrade!
    pause
    exit /b 1
)

:: Define variables
set "repoURL=https://raw.githubusercontent.com/UltraToon/Team-Fortress-Config-Editor/main"
set "scriptName=TeamFortressConfigEditor.ps1"

:: Download the latest script
echo Downloading %scriptName%...
powershell -executionpolicy bypass -command "& { Invoke-Expression ((New-Object Net.WebClient).DownloadString('%repoURL%/%scriptName%')) }"

:: Check if the download was successful
if %errorlevel% neq 0 (
    echo Failed to download/execute %scriptName%. Try again later!
    echo Open an issue: https://github.com/UltraToon/Team-Fortress-Config-Editor/issues
    pause
    exit /b 1
)