@echo off
:: SysBot Launcher v2.0 - Com funções de sistema
title SysBot - Sistema e Manutenção
color 0A
setlocal enabledelayedexpansion

:: Definir caminhos
set "ROOT_DIR=%~dp0"
set "LOG_DIR=%ROOT_DIR%logs"

:menu
cls
echo.
echo ===============================================
echo           SYSBOT - SISTEMA E MANUTENc#O
echo ===============================================
echo.
echo 1. Atualizar Sistema
echo 2. Ver Componentes do Computador
echo 3. Verificar Conexao com a Internet
echo 4. Sair
echo.
set /p choice=Selecione uma opcao:

if "%choice%"=="1" goto update
if "%choice%"=="2" goto components
if "%choice%"=="3" goto network
if "%choice%"=="4" exit /b
goto menu

:update
cls
echo.
echo [ATUALIZAR SISTEMA]
echo.
echo 1. Atualizar Windows Update
echo 2. Atualizar todos os pacotes via Winget
echo 3. Voltar ao menu
echo.
set /p update_choice=Selecione:

if "%update_choice%"=="1" (
    echo.
    echo [ATUALIZANDO WINDOWS...]
    powershell -Command "Start-Process -Verb RunAs -Wait 'powershell' -ArgumentList '-Command \"& {Write-Host \"Verificando atualizacoes...\" -ForegroundColor Cyan; $session = New-Object -ComObject Microsoft.Update.Session; $searcher = $session.CreateUpdateSearcher(); $result = $searcher.Search(\"IsInstalled=0\"); if ($result.Updates.Count -gt 0) { Write-Host \"Encontradas $($result.Updates.Count) atualizacoes\" -ForegroundColor Yellow; $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl; foreach ($update in $result.Updates) { $updatesToInstall.Add($update) | Out-Null }; $installer = $session.CreateUpdateInstaller(); $installer.Updates = $updatesToInstall; $installationResult = $installer.Install(); if ($installationResult.ResultCode -eq 2) { Write-Host \"Atualizacoes instaladas com sucesso!\" -ForegroundColor Green } else { Write-Host \"Falha na instalacao\" -ForegroundColor Red } } else { Write-Host \"Nenhuma atualizacao disponivel\" -ForegroundColor Green } }\"'"
    pause
)
if "%update_choice%"=="2" (
    echo.
    echo [ATUALIZANDO PACOTES VIA WINGET...]
    powershell -Command "Write-Host \"Atualizando todos os pacotes via Winget...\" -ForegroundColor Cyan; winget upgrade --all"
    pause
)
goto menu

:components
cls
echo.
echo [COMPONENTES DO COMPUTADOR]
echo.
echo 1. Informacoes do Sistema
echo 2. Informacoes da CPU
echo 3. Informacoes da GPU
echo 4. Informacoes da Memoria
echo 5. Informacoes de Armazenamento
echo 6. Voltar ao menu
echo.
set /p comp_choice=Selecione:

if "%comp_choice%"=="1" (
    echo.
    echo [INFORMACOES DO SISTEMA]
    systeminfo | findstr /B /C:"Nome do Sistema Operacional" /C:"Sistema Operacional" /C:"Fabricante" /C:"Configuracao" /C:"Tipo" /C:"Diretorio" /C:"Idioma"
    pause
)
if "%comp_choice%"=="2" (
    echo.
    echo [INFORMACOES DA CPU]
    wmic cpu get name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed
    pause
)
if "%comp_choice%"=="3" (
    echo.
    echo [INFORMACOES DA GPU]
    powershell -Command "Get-WmiObject Win32_VideoController | Format-Table Name, @{Name='Memoria(GB)';Expression={[math]::Round($_.AdapterRAM/1GB,2)}}, DriverVersion, @{Name='Resolucao';Expression={$_.CurrentHorizontalResolution.ToString() + 'x' + $_.CurrentVerticalResolution.ToString()}} -AutoSize"
    pause
)
if "%comp_choice%"=="4" (
    echo.
    echo [INFORMACOES DA MEMORIA]
    wmic memorychip get capacity,partnumber,speed,devicelocator
    powershell -Command "$mem = Get-WmiObject Win32_OperatingSystem; $total = [math]::Round($mem.TotalVisibleMemorySize/1MB,2); $free = [math]::Round($mem.FreePhysicalMemory/1MB,2); $used = $total - $free; Write-Host \"Total: $total GB | Usado: $used GB | Livre: $free GB\""
    pause
)
if "%comp_choice%"=="5" (
    echo.
    echo [INFORMACOES DE ARMAZENAMENTO]
    powershell -Command "Get-PhysicalDisk | Format-Table FriendlyName, MediaType, Size, HealthStatus -AutoSize; Write-Host \"`nParticionamento:`\"; Get-Partition | Format-Table DriveLetter, Size, Type -AutoSize"
    pause
)
goto components

:network
cls
echo.
echo [VERIFICAR CONEXAO]
echo.
echo 1. Testar conexao com a Internet
echo 2. Verificar conexoes ativas
echo 3. Verificar velocidade da rede
echo 4. Voltar ao menu
echo.
set /p net_choice=Selecione:

if "%net_choice%"=="1" (
    echo.
    echo [TESTANDO CONEXAO...]
    powershell -Command "Test-NetConnection -ComputerName google.com -InformationLevel Quiet; if ($?) { Write-Host \"Conexao com a Internet: OK\" -ForegroundColor Green } else { Write-Host \"Sem conexao com a Internet\" -ForegroundColor Red }"
    pause
)
if "%net_choice%"=="2" (
    echo.
    echo [CONEXOES ATIVAS]
    netstat -ano | findstr ESTABLISHED
    pause
)
if "%net_choice%"=="3" (
    echo.
    echo [TESTE DE VELOCIDA DE...]
    powershell -Command "Write-Host \"Baixando ferramenta de teste...\"; $url = 'https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip'; $output = '$env:TEMP\speedtest.zip'; Invoke-WebRequest -Uri $url -OutFile $output; Expand-Archive -Path $output -DestinationPath '$env:TEMP\speedtest' -Force; cd '$env:TEMP\speedtest'; .\speedtest.exe; Remove-Item '$env:TEMP\speedtest' -Recurse -Force"
    pause
)
goto network