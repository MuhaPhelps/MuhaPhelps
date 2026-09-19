@echo off
cd /d "%~dp0"
start "PocketBase API" cmd /k call "%~dp0START_BACKEND.bat"
timeout /t 5 /nobreak > nul
call "%~dp0START_APP.bat"
