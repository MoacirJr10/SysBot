@echo off
title SYSBOT - Ferramentas Avancadas de Sistema
chcp 65001 >nul

:: 1. Verifica se o script está sendo executado como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de administrador...
    rem Reinicia o script com privilégios de administrador
    powershell -NoProfile -Command "Start-Process -FilePath '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 2. Executa o script principal do PowerShell
echo Carregando SysBot...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sysbot.ps1"

echo.
pause
