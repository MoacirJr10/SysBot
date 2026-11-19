@echo off
setlocal DisableDelayedExpansion
title SysBot
set "SYSBOT_LAUNCHER=%~f0"
set "SYSBOT_SCRIPT=%~dp0sysbot.ps1"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%PS%" (
    echo Windows PowerShell 5.1 nao encontrado.
    pause
    exit /b 1
)
if not exist "%SYSBOT_SCRIPT%" (
    echo sysbot.ps1 nao encontrado. Extraia todos os arquivos antes de executar.
    pause
    exit /b 1
)

"%PS%" -NoProfile -NonInteractive -Command "$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo Solicitando privilegios de administrador...
    "%PS%" -NoProfile -NonInteractive -Command "try { Start-Process -FilePath $env:SYSBOT_LAUNCHER -Verb RunAs -ErrorAction Stop } catch { Write-Error $_; exit 1 }"
    if errorlevel 1 (
        echo Nao foi possivel obter privilegios administrativos.
        pause
        exit /b 1
    )
    exit /b 0
)

echo Carregando SysBot...
"%PS%" -NoProfile -File "%SYSBOT_SCRIPT%"
set "SYSBOT_EXIT=%ERRORLEVEL%"
if not "%SYSBOT_EXIT%"=="0" (
    echo SysBot retornou codigo %SYSBOT_EXIT%.
    echo Verifique a mensagem acima, a politica de scripts e as permissoes.
    pause
)
exit /b %SYSBOT_EXIT%
