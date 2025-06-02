@echo off
title SYSBOT - Ferramentas Avancadas de Sistema
color 0A
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: Verifica se é administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~dpnx0' -ArgumentList '%*' -Verb RunAs"
    exit /b
)

:: Diretórios e timestamp
set "ROOT_DIR=%~dp0"
set "LOG_DIR=%ROOT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "DATA_HORA=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "DATA_HORA=%DATA_HORA: =0%"

:menu
cls
echo ==================================================
echo               SYSBOT - MENU PRINCIPAL
echo ==================================================
echo.
echo [1] Atualizacao e Manutencao do Sistema
echo [2] Informacoes de Hardware e Software
echo [3] Diagnostico de Rede
echo [4] Ferramentas de Limpeza
echo [5] Ferramentas Adicionais
echo [6] Sair
echo.
choice /c 123456 /n /m "Escolha uma opcao: "
set "opcao=%errorlevel%"

if %opcao%==1 goto atualizacao
if %opcao%==2 goto hardware
if %opcao%==3 goto rede
if %opcao%==4 goto limpeza
if %opcao%==5 goto extras
if %opcao%==6 exit /b
goto menu

:atualizacao
cls
echo ========== ATUALIZACAO E MANUTENCAO ==========
echo.
echo [1] Verificar Atualizacoes do Windows
echo [2] Atualizar Programas (winget)
echo [3] Verificacao SFC (Integridade)
echo [4] Restauracao DISM (Saude)
echo [5] Voltar
echo.
choice /c 12345 /n /m "Escolha uma opcao: "
set "opt_at=%errorlevel%"

if %opt_at%==1 (
    set "log=%LOG_DIR%\windows_update_%DATA_HORA%.log"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Install-Module PSWindowsUpdate -Force -Scope CurrentUser; Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -AutoReboot" > "%log%" 2>&1
    type "%log%" & pause
)
if %opt_at%==2 (
    set "log=%LOG_DIR%\winget_update_%DATA_HORA%.log"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "winget upgrade --all --accept-package-agreements --accept-source-agreements" > "%log%" 2>&1
    type "%log%" & pause
)
if %opt_at%==3 (
    set "log=%LOG_DIR%\sfc_%DATA_HORA%.log"
    sfc /scannow > "%log%" 2>&1
    type "%log%" & pause
)
if %opt_at%==4 (
    set "log=%LOG_DIR%\dism_%DATA_HORA%.log"
    DISM /Online /Cleanup-Image /RestoreHealth > "%log%" 2>&1
    type "%log%" & pause
)
goto menu

:hardware
cls
echo ======= INFORMACOES DE HARDWARE E SOFTWARE =======
echo.
echo [1] Informacoes do Sistema
echo [2] CPU, GPU, Memoria, Disco
echo [3] Programas Instalados
echo [4] Gerar Relatorio Completo
echo [5] Voltar
echo.
choice /c 12345 /n /m "Escolha uma opcao: "
set "opt_hw=%errorlevel%"

if %opt_hw%==1 systeminfo | findstr /B /C:"Nome do SO" /C:"Versao do SO" /C:"Fabricante" /C:"Modelo" /C:"Tipo do sistema" /C:"Versao do BIOS" /C:"Localidade" & pause
if %opt_hw%==2 (
    echo --- CPU ---
    wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed
    echo.
    echo --- GPU ---
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_VideoController | Select Name, DriverVersion | Format-Table -AutoSize"
    echo.
    echo --- MEMORIA ---
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=Get-CimInstance Win32_PhysicalMemory; $o=Get-CimInstance Win32_OperatingSystem; $t=[math]::Round($o.TotalVisibleMemorySize/1MB,2); $f=[math]::Round($o.FreePhysicalMemory/1MB,2); $u=$t-$f; $m | Select Manufacturer,Speed,@{Name='GB';Expression={[math]::Round($_.Capacity/1GB,2)}} | Format-Table; Write-Host ('Total: {0} GB | Usado: {1} GB | Livre: {2} GB' -f $t,$u,$f)"
    echo.
    echo --- DISCO ---
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PSDrive -PSProvider FileSystem | Select Name, @{Name='TamanhoGB';Expression={[math]::Round($_.Used/1GB,2)}}, @{Name='LivreGB';Expression={[math]::Round($_.Free/1GB,2)}} | Format-Table"
    pause
)
if %opt_hw%==3 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName, DisplayVersion, Publisher | Sort DisplayName | Format-Table -AutoSize | Out-String" | more
    pause
)
if %opt_hw%==4 (
    set "relatorio=%LOG_DIR%\relatorio_completo_%DATA_HORA%.txt"
    (
        echo ==== RELATORIO DE HARDWARE/SOFTWARE ====
        echo --- SISTEMA ---
        systeminfo
        echo --- CPU ---
        wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors
        echo --- MEMORIA ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_PhysicalMemory | Select Manufacturer,Speed,@{Name='GB';Expression={[math]::Round($_.Capacity/1GB,2)}} | Format-Table | Out-String"
        echo --- GPU ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_VideoController | Select Name, DriverVersion | Format-List | Out-String"
        echo --- DISCO ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PSDrive -PSProvider FileSystem | Select Name, Used, Free | Format-Table | Out-String"
        echo --- SOFTWARE INSTALADO ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName, DisplayVersion, Publisher | Out-String"
    ) > "%relatorio%"
    type "%relatorio%" | more
    pause
)
goto menu
