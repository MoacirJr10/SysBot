@echo off
:: Define a cor do terminal para verde claro
color 0A

:: Exibe cabeçalho de início
echo ==============================
echo     INICIANDO O SYSBOT
echo ==============================
echo.
echo Executando o SysBot como Administrador...
echo Aguarde, o processo está sendo iniciado...
echo.

:: Executa o script PowerShell como Administrador
powershell -ExecutionPolicy Bypass -NoProfile -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0..\scripts\sysbot.ps1\"' -Verb RunAs"

:: Exibe mensagem de fim
echo.
echo ==============================
echo     SysBot Finalizado
echo ==============================
echo.

pause
