@echo off
rem pullall - git pull --ff-only every repo in %USERPROFILE%\.ai-setup\repos.local.txt. Options: -FetchOnly, -List <file>
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pullall.ps1" %*
