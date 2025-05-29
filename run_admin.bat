@echo off
title SYSBOT - Ferramentas Avancadas de Sistema
color 0A
setlocal EnableDelayedExpansion
chcp 850 >nul

:: Verificar se esta em modo administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de administrador...
    powershell -Command "Start-Process -FilePath '%~dpnx0' -ArgumentList '%*' -Verb RunAs"
    exit /b
)

:: Diretórios e Timestamp
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
echo [5] Sair
echo.
choice /c 12345 /n /m "Escolha uma opcao: "
set "opcao=%errorlevel%"

if %opcao%==1 goto atualizacao
if %opcao%==2 goto hardware
if %opcao%==3 goto rede
if %opcao%==4 goto limpeza
if %opcao%==5 exit /b
goto menu

:atualizacao
cls
echo ========== ATUALIZACAO E MANUTENCAO ==========
echo.
echo [1] Verificar Atualizacoes do Windows
echo [2] Atualizar Pacotes (winget)
echo [3] Verificacao SFC (Integridade)
echo [4] Restauracao DISM (Saude)
echo [5] Voltar
echo.
choice /c 12345 /n /m "Escolha uma opcao: "
set "opt_at=%errorlevel%"

if %opt_at%==1 (
    set "log=%LOG_DIR%\windows_update_%DATA_HORA%.log"
    echo Verificando atualizacoes... > "%log%"
    powershell -Command "UsoClient StartScan" >> "%log%" 2>&1
    type "%log%" & pause
)
if %opt_at%==2 (
    set "log=%LOG_DIR%\winget_update_%DATA_HORA%.log"
    powershell -Command "winget upgrade --all --accept-package-agreements --accept-source-agreements" > "%log%" 2>&1
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
echo ============== INFORMACOES DE HARDWARE E SOFTWARE ===============
echo.
echo [1] Informacoes do Sistema
echo [2] CPU, GPU, Memoria, Disco
echo [3] Programas Instalados
echo [4] Gerar Relatorio Completo
echo [5] Voltar
echo.
choice /c 12345 /n /m "Escolha uma opcao: "
set "opt_hw=%errorlevel%"

if %opt_hw%==1 (
    systeminfo | findstr /B /C:"Nome do SO" /C:"Versao do SO" /C:"Fabricante" /C:"Modelo" /C:"Tipo do sistema" /C:"Versao do BIOS" /C:"Localidade"
    pause
)
if %opt_hw%==2 (
    echo --- CPU ---
    wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed
    echo.
    echo --- GPU ---
    powershell -Command "Get-CimInstance Win32_VideoController | Select Name, DriverVersion | Format-Table -AutoSize"
    echo.
    echo --- MEMORIA ---
    powershell -Command "$m=Get-CimInstance Win32_PhysicalMemory; $o=Get-CimInstance Win32_OperatingSystem; $t=[math]::Round($o.TotalVisibleMemorySize/1MB,2); $f=[math]::Round($o.FreePhysicalMemory/1MB,2); $u=$t-$f; $m | Select Manufacturer,Speed,@{Name='GB';Expression={[math]::Round($_.Capacity/1GB,2)}} | Format-Table; Write-Host ('Total: {0} GB | Usado: {1} GB | Livre: {2} GB' -f $t,$u,$f)"
    echo.
    echo --- DISCO ---
    powershell -Command "Get-PhysicalDisk | Select FriendlyName, MediaType, @{Name='TamanhoGB';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus | Format-Table"
    pause
)
if %opt_hw%==3 (
    echo Programas instalados:
    powershell -Command "Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName, DisplayVersion, Publisher | Sort DisplayName | Format-Table -AutoSize" | more
    pause
)
if %opt_hw%==4 (
    set "relatorio=%LOG_DIR%\relatorio_completo_%DATA_HORA%.txt"
    (
        echo ==== RELATORIO DE HARDWARE/SOFTWARE ====
        echo --- SISTEMA ---
        systeminfo
        echo.
        echo --- CPU ---
        wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors
        echo.
        echo --- MEMORIA ---
        powershell -Command "Get-CimInstance Win32_PhysicalMemory | Select Manufacturer,Speed,@{Name='GB';Expression={[math]::Round($_.Capacity/1GB,2)}}" | Format-Table"
        echo.
        echo --- GPU ---
        powershell -Command "Get-CimInstance Win32_VideoController | Select Name, DriverVersion | Format-List"
        echo.
        echo --- DISCO ---
        powershell -Command "Get-PhysicalDisk | Select FriendlyName, MediaType, @{Name='TamanhoGB';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus | Format-Table"
        echo.
        echo --- SOFTWARE INSTALADO ---
        powershell -Command "Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName, DisplayVersion, Publisher | Sort DisplayName"
    ) > "%relatorio%"
    type "%relatorio%" | more
    pause
)
goto menu

:rede
cls
echo ============ DIAGNOSTICO DE REDE ============
echo.
echo [1] Testar Conexao com a Internet
echo [2] Conexoes Ativas
echo [3] Limpar Cache DNS
echo [4] Teste de Velocidade (Speedtest CLI)
echo [5] Adaptadores de Rede
echo [6] Voltar
echo.
choice /c 123456 /n /m "Escolha uma opcao: "
set "opt_net=%errorlevel%"

if %opt_net%==1 powershell -Command "Test-NetConnection google.com" & pause
if %opt_net%==2 netstat -ano | findstr ESTABLISHED & pause
if %opt_net%==3 ipconfig /flushdns & echo Cache DNS limpo. & pause
if %opt_net%==4 (
    powershell -Command "if (-not (Get-Command speedtest -ErrorAction SilentlyContinue)) { winget install --id=Ookla.Speedtest.CLI -e --accept-source-agreements --accept-package-agreements }; speedtest --accept-license --accept-gdpr"
    pause
)
if %opt_net%==5 powershell -Command "Get-NetAdapter | Select Name, Status, LinkSpeed | Format-Table -AutoSize" & pause
goto menu

:limpeza
cls
echo ============ FERRAMENTAS DE LIMPEZA ============
echo.
echo [1] Apagar Arquivos Temporarios
echo [2] Limpar Cache do Windows Update
echo [3] Apagar Pontos de Restauracao
echo [4] Limpeza de Disco (cleanmgr)
echo [5] Voltar
echo.
choice /c 12345 /n /m "Escolha uma opcao: "
set "opt_limp=%errorlevel%"

if %opt_limp%==1 (
    powershell -Command "$temp=@($env:TEMP,'$env:SystemRoot\Temp','$env:LOCALAPPDATA\Temp'); $temp | ForEach-Object { Remove-Item $_\* -Recurse -Force -ErrorAction SilentlyContinue }; Write-Host 'Arquivos temporarios removidos.'"
    pause
)
if %opt_limp%==2 (
    net stop wuauserv >nul
    del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul
    net start wuauserv >nul
    echo Cache do Windows Update limpo.
    pause
)
if %opt_limp%==3 (
    vssadmin delete shadows /all /quiet
    echo Pontos de restauracao removidos.
    pause
)
if %opt_limp%==4 cleanmgr /sagerun:1 & pause
goto menu
