@echo off
:: SysBot Launcher v3.2 - Manutencao Avancada do Sistema
title SysBot - Ferramentas Avancadas de Sistema
color 0A
setlocal enabledelayedexpansion

:: Definir codificacao sem caracteres especiais problemáticos
chcp 850 >nul

:: Verificar e solicitar privilegios de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de administrador...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~dpnx0' -ArgumentList '%*'"
    exit /b
)

:: Variaveis de diretorio e data/hora
set "ROOT_DIR=%~dp0"
set "LOG_DIR=%ROOT_DIR%logs"
set "DATA_HORA=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "DATA_HORA=%DATA_HORA: =0%"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:menu_principal
cls
echo.
echo ===============================================
echo         SYSBOT - FERRAMENTAS DE SISTEMA
echo ===============================================
echo.
echo 1. Atualizacao e Manutencao do Sistema
echo 2. Informacoes de Hardware
echo 3. Diagnostico de Rede
echo 4. Ferramentas de Limpeza
echo 5. Sair
echo.
choice /c 12345 /n /m "Selecione uma opcao: "
set "opcao=%errorlevel%"

if %opcao%==1 goto atualizacao_sistema
if %opcao%==2 goto informacoes_hardware
if %opcao%==3 goto ferramentas_rede
if %opcao%==4 goto limpeza_sistema
if %opcao%==5 exit /b
goto menu_principal

:: ====================================================
:atualizacao_sistema
cls
echo.
echo ===== ATUALIZACAO E MANUTENCAO DO SISTEMA =====
echo.
echo 1. Verificar Atualizacoes do Windows
echo 2. Atualizar Pacotes via Winget
echo 3. Verificar Integridade do Sistema (SFC)
echo 4. Verificar Saude da Imagem (DISM)
echo 5. Voltar ao Menu Principal
echo.
choice /c 12345 /n /m "Selecione uma opcao: "
set "opcao_atualizacao=%errorlevel%"

if %opcao_atualizacao%==1 (
    echo.
    echo [VERIFICANDO ATUALIZACOES DO WINDOWS...]
    echo Registrando em %LOG_DIR%\atualizacoes_%DATA_HORA%.log
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%LOG_DIR%\atualizacoes_%DATA_HORA%.log'; UsoClient StartInteractiveScan; Stop-Transcript"
    type "%LOG_DIR%\atualizacoes_%DATA_HORA%.log"
    pause
)
if %opcao_atualizacao%==2 (
    echo.
    echo [ATUALIZANDO PACOTES VIA WINGET...]
    echo Registrando em %LOG_DIR%\winget_%DATA_HORA%.log
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%LOG_DIR%\winget_%DATA_HORA%.log'; winget upgrade --all --accept-package-agreements --accept-source-agreements; Stop-Transcript"
    type "%LOG_DIR%\winget_%DATA_HORA%.log"
    pause
)
if %opcao_atualizacao%==3 (
    echo.
    echo [VERIFICANDO INTEGRIDADE DO SISTEMA...]
    echo Registrando em %LOG_DIR%\sfc_%DATA_HORA%.log
    sfc /scannow > "%LOG_DIR%\sfc_%DATA_HORA%.log" 2>&1
    type "%LOG_DIR%\sfc_%DATA_HORA%.log"
    pause
)
if %opcao_atualizacao%==4 (
    echo.
    echo [VERIFICANDO SAUDE DA IMAGEM DO SISTEMA...]
    echo Registrando em %LOG_DIR%\dism_%DATA_HORA%.log
    DISM /Online /Cleanup-Image /RestoreHealth > "%LOG_DIR%\dism_%DATA_HORA%.log" 2>&1
    type "%LOG_DIR%\dism_%DATA_HORA%.log"
    pause
)
goto menu_principal

:: ====================================================
:informacoes_hardware
cls
echo.
echo ===== INFORMACOES DE HARDWARE =====
echo.
echo 1. Informacoes do Sistema
echo 2. Detalhes da CPU
echo 3. Detalhes da GPU
echo 4. Informacoes de Memoria
echo 5. Informacoes de Armazenamento
echo 6. Relatorio Completo de Hardware
echo 7. Voltar ao Menu Principal
echo.
choice /c 1234567 /n /m "Selecione uma opcao: "
set "opcao_hardware=%errorlevel%"

if %opcao_hardware%==1 (
    systeminfo | findstr /B /C:"Nome do SO" /C:"Versao do SO" /C:"Fabricante" /C:"Modelo" /C:"Tipo do sistema" /C:"Versao do BIOS" /C:"Diretorio do Windows" /C:"Localidade"
    pause
)
if %opcao_hardware%==2 (
    wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed,L2CacheSize,L3CacheSize /format:list
    pause
)
if %opcao_hardware%==3 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject Win32_VideoController | Select-Object Name, @{Name='MemoriaGB';Expression={[math]::Round($_.AdapterRAM/1GB,2)}}, DriverVersion | Format-List"
    pause
)
if %opcao_hardware%==4 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$mem = Get-CimInstance Win32_PhysicalMemory; $os = Get-CimInstance Win32_OperatingSystem; ^
    $total = [math]::Round($os.TotalVisibleMemorySize/1MB,2); $free = [math]::Round($os.FreePhysicalMemory/1MB,2); ^
    $used = $total - $free; ^
    Write-Host 'Detalhes dos Modulos de Memoria:'; ^
    $mem | Select-Object Manufacturer, PartNumber, Speed, Capacity | Format-Table -AutoSize; ^
    Write-Host ''; Write-Host 'Resumo: Total: ' $total 'GB | Usado: ' $used 'GB | Livre: ' $free 'GB'"
    pause
)
if %opcao_hardware%==5 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{Name='TamanhoGB';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus | Format-Table -AutoSize"
    pause
)
if %opcao_hardware%==6 (
    echo Gerando relatorio em %LOG_DIR%\hardware_%DATA_HORA%.log
    (
        echo === INFORMACOES DO SISTEMA ===
        systeminfo
        echo.
        echo === CPU ===
        wmic cpu get /format:list
        echo.
        echo === MEMORIA ===
        powershell -Command "Get-CimInstance Win32_PhysicalMemory | Format-List"
        echo.
        echo === GPU ===
        powershell -Command "Get-WmiObject Win32_VideoController | Format-List"
        echo.
        echo === DISCO ===
        powershell -Command "Get-PhysicalDisk | Format-List"
    ) > "%LOG_DIR%\hardware_%DATA_HORA%.log"
    type "%LOG_DIR%\hardware_%DATA_HORA%.log" | more
    pause
)
goto menu_principal

:: ====================================================
:ferramentas_rede
cls
echo.
echo ===== DIAGNOSTICO DE REDE =====
echo.
echo 1. Testar Conexao com a Internet
echo 2. Mostrar Conexoes Ativas
echo 3. Limpar Cache DNS
echo 4. Teste de Velocidade da Internet
echo 5. Informacoes do Adaptador de Rede
echo 6. Voltar ao Menu Principal
echo.
choice /c 123456 /n /m "Selecione uma opcao: "
set "opcao_rede=%errorlevel%"

if %opcao_rede%==1 (
    powershell -Command "Test-NetConnection google.com"
    pause
)
if %opcao_rede%==2 (
    netstat -ano | findstr ESTABLISHED
    pause
)
if %opcao_rede%==3 (
    ipconfig /flushdns
    echo Cache DNS limpo com sucesso.
    pause
)
if %opcao_rede%==4 (
    echo [TESTANDO VELOCIDADE DA INTERNET...]
    powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Command speedtest -ErrorAction SilentlyContinue)) { winget install --id=Ookla.Speedtest -e --accept-source-agreements --accept-package-agreements }; speedtest"
    pause
)
if %opcao_rede%==5 (
    powershell -Command "Get-NetAdapter | Select Name, Status, LinkSpeed | Format-Table -AutoSize"
    pause
)
goto menu_principal

:: ====================================================
:limpeza_sistema
cls
echo.
echo ===== FERRAMENTAS DE LIMPEZA =====
echo.
echo 1. Limpar Arquivos Temporarios
echo 2. Limpar Cache do Windows Update
echo 3. Limpar Pontos de Restauracao
echo 4. Limpeza de Disco
echo 5. Voltar ao Menu Principal
echo.
choice /c 12345 /n /m "Selecione uma opcao: "
set "opcao_limpeza=%errorlevel%"

if %opcao_limpeza%==1 (
    powershell -Command "$temp = @($env:TEMP, \"$env:SystemRoot\Temp\", \"$env:LOCALAPPDATA\Temp\"); $temp | ForEach-Object { Get-ChildItem $_ -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }; Write-Host 'Arquivos temporarios removidos.'"
    pause
)
if %opcao_limpeza%==2 (
    net stop wuauserv
    del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*"
    net start wuauserv
    echo Cache do Windows Update limpo.
    pause
)
if %opcao_limpeza%==3 (
    vssadmin delete shadows /all /quiet
    echo Pontos de restauracao removidos.
    pause
)
if %opcao_limpeza%==4 (
    cleanmgr /sagerun:1
    pause
)
goto menu_principal
