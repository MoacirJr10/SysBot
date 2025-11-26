@echo off
title SYSBOT - MODO DE DEPURACAO
chcp 65001 >nul

:: 1. Verifica se o script está sendo executado como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 2. Executa o script principal em modo de depuracao
echo Carregando SysBot em modo de depuracao...
echo A janela do PowerShell permanecera aberta para analise de erros.

powershell -NoExit -ExecutionPolicy Bypass -Command "& '%~dp0sysbot.ps1'"

echo.
pause
