@echo off
REM Double-click launcher for new-script.ps1: runs it interactively (prompts for
REM a name, re-prompts on a collision), bypassing the execution policy for this
REM one process, and pauses so you can read the result.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0new-script.ps1"
echo.
pause
