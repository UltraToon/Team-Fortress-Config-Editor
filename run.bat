@echo off
setlocal enabledelayedexpansion

:: Define variables
set "repoURL=https://raw.githubusercontent.com/UltraToon/Team-Fortress-Config-Editor/main"
set "scriptName=TeamFortressConfigEditor.ps1"

:: Download the latest script
echo Downloading %scriptName%...
powershell -command "& { Invoke-WebRequest -Uri '%repoURL%/%scriptName%' -OutFile '%scriptName%' }"

:: Check if the download was successful
if %errorlevel% neq 0 (
    echo Failed to download %scriptName%.
    pause
    exit /b 1
)

:: Execute the downloaded script
echo Running %scriptName%...
start powershell -executionpolicy bypass -file "%scriptName%"

:: Check if the execution was successful
if %errorlevel% neq 0 (
    echo Failed to run %scriptName%.
    pause
    exit /b 1
)
exit /b 0