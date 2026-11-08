@echo off
cd /d "%~dp0"
call npm run test:api:ui

if errorlevel 1 pause
