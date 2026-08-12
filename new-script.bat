@echo off
REM Double-click launcher for new-script.ps1: prompts for a name, then scaffolds
REM a new script into scripts\. Runs PowerShell with the execution policy
REM bypassed for this one process, and pauses so you can read the result.
setlocal
set /p "name=Name for the new script: "
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0new-script.ps1" -Name "%name%"
echo.
pause
