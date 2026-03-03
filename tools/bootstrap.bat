@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0bootstrap.ps1" %*
exit /b %ERRORLEVEL%
