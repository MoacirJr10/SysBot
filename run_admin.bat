@echo off
:: SysBot Launcher v3.0 - Manutenção Avançada do Sistema
title SysBot - Ferramentas de Sistema Avançadas
color 0A
setlocal enabledelayedexpansion

:: Verificar e solicitar privilégios de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilégios de administrador...
    powershell -Command "Start-Process -Verb RunAs -FilePath '%~dpnx0' -ArgumentList '%*'"
    exit /b
)

:: Configurar caminhos
set "ROOT_DIR=%~dp0"
set "LOG_DIR=%ROOT_DIR%logs"
set "DATA_HORA=%date%_%time::=-%"
set "DATA_HORA=%DATA_HORA:/=-%"
set "DATA_HORA=%DATA_HORA: =%"

:: Criar diretório de logs se não existir
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:menu_principal
cls
echo.
echo ===============================================
echo        SYSBOT - FERRAMENTAS DE SISTEMA
echo ===============================================
echo.
echo 1. Atualização e Manutenção do Sistema
echo 2. Informações de Hardware
echo 3. Diagnóstico de Rede
echo 4. Ferramentas de Limpeza
echo 5. Sair
echo.
set /p opcao=Selecione uma opção [1-5]:

if "%opcao%"=="1" goto atualizacao_sistema
if "%opcao%"=="2" goto informacoes_hardware
if "%opcao%"=="3" goto ferramentas_rede
if "%opcao%"=="4" goto limpeza_sistema
if "%opcao%"=="5" exit /b
goto menu_principal

:atualizacao_sistema
cls
echo.
echo ===== ATUALIZAÇÃO E MANUTENÇÃO DO SISTEMA =====
echo.
echo 1. Verificar Atualizações do Windows
echo 2. Atualizar pacotes via Winget
echo 3. Verificar Integridade do Sistema (SFC)
echo 4. Verificar Saúde da Imagem (DISM)
echo 5. Voltar ao Menu Principal
echo.
set /p opcao_atualizacao=Selecione uma opção [1-5]:

if "%opcao_atualizacao%"=="1" (
    echo.
    echo [VERIFICANDO ATUALIZAÇÕES DO WINDOWS...]
    echo Registrando em %LOG_DIR%\atualizacoes_%DATA_HORA%.log
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -Wait 'powershell' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"& {$ErrorActionPreference=\"Stop\"; try { $session = New-Object -ComObject Microsoft.Update.Session; $searcher = $session.CreateUpdateSearcher(); Write-Host \"Buscando atualizações...\" -ForegroundColor Cyan; $result = $searcher.Search(\"IsInstalled=0\"); if ($result.Updates.Count -gt 0) { Write-Host \"Encontradas $($result.Updates.Count) atualizações\" -ForegroundColor Yellow; $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl; $result.Updates | ForEach-Object { $updatesToInstall.Add($_) | Out-Null }; $installer = $session.CreateUpdateInstaller(); $installer.Updates = $updatesToInstall; Write-Host \"Instalando atualizações...\" -ForegroundColor Cyan; $installationResult = $installer.Install(); if ($installationResult.ResultCode -eq 2) { Write-Host \"Atualizações instaladas com sucesso!\" -ForegroundColor Green } else { Write-Host \"Falha na instalação\" -ForegroundColor Red } } else { Write-Host \"Nenhuma atualização disponível\" -ForegroundColor Green } } catch { Write-Host \"Erro: $_\" -ForegroundColor Red } }\"' > \"%LOG_DIR%\atualizacoes_%DATA_HORA%.log\" 2>&1"
    type "%LOG_DIR%\atualizacoes_%DATA_HORA%.log"
    pause
)
if "%opcao_atualizacao%"=="2" (
    echo.
    echo [ATUALIZANDO PACOTES VIA WINGET...]
    echo Registrando em %LOG_DIR%\winget_%DATA_HORA%.log
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -Wait 'powershell' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"& {Write-Host \"Atualizando pacotes via Winget...\" -ForegroundColor Cyan; winget upgrade --all --accept-package-agreements --accept-source-agreements; if ($LASTEXITCODE -eq 0) { Write-Host \"Atualização de pacotes concluída\" -ForegroundColor Green } else { Write-Host \"Falha na atualização de pacotes\" -ForegroundColor Red } }\"' > \"%LOG_DIR%\winget_%DATA_HORA%.log\" 2>&1"
    type "%LOG_DIR%\winget_%DATA_HORA%.log"
    pause
)
if "%opcao_atualizacao%"=="3" (
    echo.
    echo [VERIFICANDO INTEGRIDADE DO SISTEMA...]
    echo Registrando em %LOG_DIR%\sfc_%DATA_HORA%.log
    sfc /scannow > "%LOG_DIR%\sfc_%DATA_HORA%.log" 2>&1
    type "%LOG_DIR%\sfc_%DATA_HORA%.log"
    pause
)
if "%opcao_atualizacao%"=="4" (
    echo.
    echo [VERIFICANDO SAÚDE DA IMAGEM DO SISTEMA...]
    echo Registrando em %LOG_DIR%\dism_%DATA_HORA%.log
    DISM /Online /Cleanup-Image /RestoreHealth > "%LOG_DIR%\dism_%DATA_HORA%.log" 2>&1
    type "%LOG_DIR%\dism_%DATA_HORA%.log"
    pause
)
goto atualizacao_sistema

:informacoes_hardware
cls
echo.
echo ===== INFORMAÇÕES DE HARDWARE =====
echo.
echo 1. Informações do Sistema
echo 2. Detalhes da CPU
echo 3. Detalhes da GPU
echo 4. Informações de Memória
echo 5. Informações de Armazenamento
echo 6. Relatório Completo de Hardware
echo 7. Voltar ao Menu Principal
echo.
set /p opcao_hardware=Selecione uma opção [1-7]:

if "%opcao_hardware%"=="1" (
    echo.
    echo [INFORMAÇÕES DO SISTEMA]
    systeminfo | findstr /B /C:"Nome do SO" /C:"Versão do SO" /C:"Fabricante" /C:"Modelo" /C:"Tipo do Sistema" /C:"Versão do BIOS" /C:"Diretório do Windows" /C:"Localidade"
    pause
)
if "%opcao_hardware%"=="2" (
    echo.
    echo [INFORMAÇÕES DA CPU]
    wmic cpu get name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed,L2CacheSize,L3CacheSize /format:list
    pause
)
if "%opcao_hardware%"=="3" (
    echo.
    echo [INFORMAÇÕES DA GPU]
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject Win32_VideoController | Select-Object Name, @{Name='MemoriaGB';Expression={[math]::Round($_.AdapterRAM/1GB,2)}}, DriverVersion, @{Name='Resolucao';Expression={$_.CurrentHorizontalResolution.ToString() + 'x' + $_.CurrentVerticalResolution.ToString()}} | Format-List"
    pause
)
if "%opcao_hardware%"=="4" (
    echo.
    echo [INFORMAÇÕES DE MEMÓRIA]
    wmic memorychip get capacity,partnumber,speed,devicelocator,manufacturer /format:list
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$os = Get-WmiObject Win32_OperatingSystem; $total = [math]::Round($os.TotalVisibleMemorySize/1MB,2); $free = [math]::Round($os.FreePhysicalMemory/1MB,2); $used = $total - $free; $pct = [math]::Round(($used/$total)*100,2); Write-Host \"Total: $total GB | Usado: $used GB ($pct%%) | Livre: $free GB\" -ForegroundColor Cyan"
    pause
)
if "%opcao_hardware%"=="5" (
    echo.
    echo [INFORMAÇÕES DE ARMAZENAMENTO]
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{Name='TamanhoGB';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus, OperationalStatus | Format-Table -AutoSize; Write-Host \"`nPartições:\"; Get-Partition | Select-Object DriveLetter, @{Name='TamanhoGB';Expression={[math]::Round($_.Size/1GB,2)}}, Type | Format-Table -AutoSize"
    pause
)
if "%opcao_hardware%"=="6" (
    echo.
    echo [RELATÓRIO COMPLETO DE HARDWARE]
    echo Gerando relatório em %LOG_DIR%\hardware_%DATA_HORA%.log
    (
        echo === INFORMAÇÕES DO SISTEMA ===
        systeminfo
        echo.
        echo === INFORMAÇÕES DA CPU ===
        wmic cpu get /format:list
        echo.
        echo === INFORMAÇÕES DE MEMÓRIA ===
        wmic memorychip get /format:list
        echo.
        echo === INFORMAÇÕES DE ARMAZENAMENTO ===
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | Select-Object * | Format-List; Get-Partition | Select-Object * | Format-List"
        echo.
        echo === INFORMAÇÕES DA GPU ===
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject Win32_VideoController | Select-Object * | Format-List"
    ) > "%LOG_DIR%\hardware_%DATA_HORA%.log" 2>&1
    type "%LOG_DIR%\hardware_%DATA_HORA%.log" | more
    pause
)
goto informacoes_hardware

:ferramentas_rede
cls
echo.
echo ===== DIAGNÓSTICO DE REDE =====
echo.
echo 1. Testar Conexão com a Internet
echo 2. Mostrar Conexões Ativas
echo 3. Limpar Cache DNS
echo 4. Teste de Velocidade da Internet
echo 5. Informações do Adaptador de Rede
echo 6. Voltar ao Menu Principal
echo.
set /p opcao_rede=Selecione uma opção [1-6]:

if "%opcao_rede%"=="1" (
    echo.
    echo [TESTANDO CONEXÃO COM A INTERNET...]
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$teste = Test-NetConnection -ComputerName google.com -InformationLevel Detailed; if ($teste.PingSucceeded) { Write-Host \"Conexão com a Internet: OK\" -ForegroundColor Green; Write-Host \"Latência: $($teste.PingReplyDetails.RoundtripTime) ms\" -ForegroundColor Cyan } else { Write-Host \"Sem conexão com a Internet\" -ForegroundColor Red }"
    pause
)
if "%opcao_rede%"=="2" (
    echo.
    echo [CONEXÕES DE REDE ATIVAS]
    netstat -ano | findstr ESTABLISHED
    pause
)
if "%opcao_rede%"=="3" (
    echo.
    echo [LIMPANDO CACHE DNS...]
    ipconfig /flushdns
    if %errorlevel% equ 0 (
        echo Cache DNS limpo com sucesso.
    ) else (
        echo Falha ao limpar cache DNS.
    )
    pause
)
if "%opcao_rede%"=="4" (
    echo.
    echo [TESTANDO VELOCIDADE DA INTERNET...]
    echo Isso pode levar alguns instantes...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$url = 'https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip'; $output = '$env:TEMP\speedtest.zip'; $ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing; Expand-Archive -Path $output -DestinationPath '$env:TEMP\speedtest' -Force; cd '$env:TEMP\speedtest'; .\speedtest.exe --accept-license --accept-gdpr; Remove-Item '$env:TEMP\speedtest' -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item $output -ErrorAction SilentlyContinue } catch { Write-Host \"Erro: $_\" -ForegroundColor Red }"
    pause
)
if "%opcao_rede%"=="5" (
    echo.
    echo [INFORMAÇÕES DO ADAPTADOR DE REDE]
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress | Format-Table -AutoSize"
    pause
)
goto ferramentas_rede

:limpeza_sistema
cls
echo.
echo ===== FERRAMENTAS DE LIMPEZA =====
echo.
echo 1. Limpar Arquivos Temporários
echo 2. Limpar Cache do Windows Update
echo 3. Limpar Pontos de Restauração
echo 4. Limpeza de Disco
echo 5. Voltar ao Menu Principal
echo.
set /p opcao_limpeza=Selecione uma opção [1-5]:

if "%opcao_limpeza%"=="1" (
    echo.
    echo [LIMPANDO ARQUIVOS TEMPORÁRIOS...]
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$pastasTemp = @('$env:TEMP', '$env:SystemRoot\Temp', '$env:LOCALAPPDATA\Temp'); $totalLiberado = 0; foreach ($pasta in $pastasTemp) { if (Test-Path $pasta) { $arquivos = Get-ChildItem $pasta -Recurse -Force -ErrorAction SilentlyContinue; $tamanho = ($arquivos | Measure-Object -Property Length -Sum).Sum; $arquivos | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; $totalLiberado += $tamanho } }; $gbLiberados = [math]::Round($totalLiberado/1GB, 2); Write-Host \"Liberados $gbLiberados GB de arquivos temporários\" -ForegroundColor Green"
    pause
)
if "%opcao_limpeza%"=="2" (
    echo.
    echo [LIMPANDO CACHE DO WINDOWS UPDATE...]
    net stop wuauserv
    del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*"
    net start wuauserv
    echo Cache do Windows Update limpo.
    pause
)
if "%opcao_limpeza%"=="3" (
    echo.
    echo [LIMPANDO PONTOS DE RESTAURAÇÃO...]
    vssadmin delete shadows /all /quiet
    echo Pontos de restauração antigos removidos.
    pause
)
if "%opcao_limpeza%"=="4" (
    echo.
    echo [EXECUTANDO LIMPEZA DE DISCO...]
    cleanmgr /sageset:65535
    cleanmgr /sagerun:65535
    echo Limpeza de disco concluída.
    pause
)
goto limpeza_sistema