@echo off
title SYSBOT - Ferramentas Avançadas de Sistema
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
echo [5] Verificar Drivers Desatualizados
echo [6] Voltar
echo.
choice /c 123456 /n /m "Escolha uma opcao: "
set "opt_at=%errorlevel%"

if %opt_at%==1 (
    set "log=%LOG_DIR%\windows_update_%DATA_HORA%.log"
    echo Verificando e instalando atualizacoes do Windows...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Install-Module PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction SilentlyContinue; Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File '%log%' -Encoding UTF8"
    type "%log%" & pause
)
if %opt_at%==2 (
    set "log=%LOG_DIR%\winget_update_%DATA_HORA%.log"
    echo Atualizando programas via winget...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "winget upgrade --all --accept-package-agreements --accept-source-agreements | Out-File '%log%' -Encoding UTF8"
    type "%log%" & pause
)
if %opt_at%==3 (
    set "log=%LOG_DIR%\sfc_%DATA_HORA%.log"
    echo Verificando integridade do sistema com SFC...
    sfc /scannow > "%log%"
    type "%log%" & pause
)
if %opt_at%==4 (
    set "log=%LOG_DIR%\dism_%DATA_HORA%.log"
    echo Restaurando saude do sistema com DISM...
    DISM /Online /Cleanup-Image /RestoreHealth > "%log%"
    type "%log%" & pause
)
if %opt_at%==5 (
    set "log=%LOG_DIR%\drivers_%DATA_HORA%.log"
    echo Verificando drivers desatualizados...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null -and $_.DriverVersion -ne $null } | Select-Object DeviceName, DriverVersion, Manufacturer | Sort-Object DeviceName | Format-Table -AutoSize | Out-File '%log%' -Encoding UTF8"
    type "%log%" | more & pause
)
goto menu

:hardware
cls
echo ======= INFORMACOES DE HARDWARE E SOFTWARE =======
echo.
echo [1] Informacoes do Sistema
echo [2] CPU, GPU, Memoria, Disco
echo [3] Programas Instalados
echo [4] Temperaturas e Ventoinhas (se disponivel)
echo [5] Gerar Relatorio Completo
echo [6] Voltar
echo.
choice /c 123456 /n /m "Escolha uma opcao: "
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
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_VideoController | Select Name, DriverVersion, @{Name='VRAM(MB)';Expression={$_.AdapterRAM/1MB}} | Format-Table -AutoSize"
    echo.
    echo --- MEMORIA ---
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=Get-CimInstance Win32_PhysicalMemory; $o=Get-CimInstance Win32_OperatingSystem; $t=[math]::Round($o.TotalVisibleMemorySize/1MB,2); $f=[math]::Round($o.FreePhysicalMemory/1MB,2); $u=$t-$f; $m | Select Manufacturer,PartNumber,Speed,@{Name='GB';Expression={[math]::Round($_.Capacity/1GB,2)}} | Format-Table; Write-Host ('Total: {0} GB | Usado: {1} GB | Livre: {2} GB' -f $t,$u,$f)"
    echo.
    echo --- DISCO ---
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | Select FriendlyName,MediaType,Size,HealthStatus | Format-Table; Get-PSDrive -PSProvider FileSystem | Select Name, @{Name='TamanhoGB';Expression={[math]::Round($_.Used/1GB,2)}}, @{Name='LivreGB';Expression={[math]::Round($_.Free/1GB,2)}} | Format-Table"
    pause
)
if %opt_hw%==3 (
    echo Programas instalados (32 e 64 bits):
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -ne $null } | Select DisplayName, DisplayVersion, Publisher, InstallDate | Sort DisplayName | Format-Table -AutoSize | Out-String -Width 300" | more
    pause
)
if %opt_hw%==4 (
    echo --- TEMPERATURAS (se disponivel) ---
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace 'root/wmi' | Select InstanceName, CurrentTemperature | Format-Table; Get-WmiObject Win32_Fan | Select Name, Status | Format-Table"
    pause
)
if %opt_hw%==5 (
    set "relatorio=%LOG_DIR%\relatorio_completo_%DATA_HORA%.txt"
    (
        echo ==== RELATORIO DE HARDWARE/SOFTWARE ====
        echo --- SISTEMA ---
        systeminfo
        echo.
        echo --- CPU ---
        wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /format:list
        echo.
        echo --- GPU ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_VideoController | Select Name, DriverVersion, @{Name='VRAM(MB)';Expression={$_.AdapterRAM/1MB}} | Format-List | Out-String"
        echo.
        echo --- MEMORIA ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_PhysicalMemory | Select Manufacturer,PartNumber,Speed,@{Name='GB';Expression={[math]::Round($_.Capacity/1GB,2)}} | Format-Table | Out-String"
        echo.
        echo --- DISCO ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | Select FriendlyName,MediaType,Size,HealthStatus | Format-Table | Out-String; Get-PSDrive -PSProvider FileSystem | Select Name, Used, Free | Format-Table | Out-String"
        echo.
        echo --- SOFTWARE INSTALADO ---
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -ne $null } | Select DisplayName, DisplayVersion, Publisher, InstallDate | Sort DisplayName | Format-Table -AutoSize | Out-String"
    ) > "%relatorio%"
    type "%relatorio%" | more
    pause
)
goto menu

:rede
cls
echo ========== DIAGNOSTICO DE REDE ==========
echo.
echo [1] IP, Gateway, DNS
echo [2] Testar Conexao com Google
echo [3] Testar Porta (com PowerShell)
echo [4] Liberar Cache DNS e Renovar IP
echo [5] Testar Velocidade da Internet
echo [6] Analisar Conexoes de Rede
echo [7] Voltar
echo.
choice /c 1234567 /n /m "Escolha uma opcao: "
set "opt_net=%errorlevel%"

if %opt_net%==1 (
    echo --- Configuracao de Rede ---
    ipconfig /all | findstr /R "IPv4 Gateway DNS"
    echo.
    echo --- Conexoes Ativas ---
    netstat -ano | findstr ESTABLISHED
    pause
)
if %opt_net%==2 (
    echo Testando conexao com Google (ping)...
    ping -n 4 www.google.com
    echo.
    echo Testando conexao com Google (HTTP)...
    powershell -NoProfile -Command "try { $response = Invoke-WebRequest -Uri 'http://www.google.com' -UseBasicParsing -DisableKeepAlive; Write-Host 'Conexao HTTP bem-sucedida' -ForegroundColor Green } catch { Write-Host 'Falha na conexao HTTP' -ForegroundColor Red }"
    pause
)
if %opt_net%==3 (
    set /p host="Digite o host (ex: google.com): "
    set /p porta="Digite a porta (ex: 80): "
    powershell -NoProfile -Command "try { (New-Object System.Net.Sockets.TcpClient('%host%',%porta%)).Close(); Write-Host 'Conexao bem-sucedida na porta %porta%' -ForegroundColor Green } catch { Write-Host 'Falha na conexao na porta %porta%' -ForegroundColor Red }"
    pause
)
if %opt_net%==4 (
    echo Liberando cache DNS...
    ipconfig /flushdns
    echo.
    echo Renovando configuracao IP...
    ipconfig /release
    ipconfig /renew
    echo.
    echo Verificando rotas...
    route print
    pause
)
if %opt_net%==5 (
    echo Testando velocidade da Internet (aguarde alguns segundos)...
    set "log=%LOG_DIR%\speedtest_%DATA_HORA%.log"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; $result = Invoke-WebRequest -Uri 'https://speedtest.net' -UseBasicParsing; $downloadUrl = 'https://speedtest.net/speedtest.ashx'; $uploadUrl = 'https://speedtest.net/speedtest-upload.php'; $start = Get-Date; $download = (Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing).Content; $downloadTime = (Get-Date) - $start; $downloadSize = $download.Length; $downloadSpeed = [math]::Round(($downloadSize * 8 / $downloadTime.TotalSeconds) / 1e6, 2); $start = Get-Date; $upload = Invoke-WebRequest -Uri $uploadUrl -Method Post -Body ([byte[]]::new(1e6)) -UseBasicParsing; $uploadTime = (Get-Date) - $start; $uploadSize = 1e6; $uploadSpeed = [math]::Round(($uploadSize * 8 / $uploadTime.TotalSeconds) / 1e6, 2); Write-Host ('Velocidade Download: {0} Mbps' -f $downloadSpeed); Write-Host ('Velocidade Upload: {0} Mbps' -f $uploadSpeed); Add-Content -Path '%log%' -Value ('Data: {0}' -f (Get-Date)); Add-Content -Path '%log%' -Value ('Download: {0} Mbps' -f $downloadSpeed); Add-Content -Path '%log%' -Value ('Upload: {0} Mbps' -f $uploadSpeed)"
    type "%log%"
    pause
)
if %opt_net%==6 (
    echo --- Conexoes Ativas ---
    netstat -ano | findstr ESTABLISHED
    echo.
    echo --- Processos com Conexoes ---
    powershell -NoProfile -Command "Get-NetTCPConnection -State Established | Select LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess | Sort-Object OwningProcess | Format-Table -AutoSize"
    pause
)
goto menu

:limpeza
cls
echo ========== FERRAMENTAS DE LIMPEZA ==========
echo.
echo [1] Limpeza de Arquivos Temporarios
echo [2] Limpeza com Storage Sense
echo [3] Limpar Prefetch, Logs, Recentes
echo [4] Limpar Thumbnails e IconCache
echo [5] Otimizar Unidades (Defrag)
echo [6] Voltar
echo.
choice /c 123456 /n /m "Escolha uma opcao: "
set "opt_clean=%errorlevel%"

if %opt_clean%==1 (
    echo Limpando arquivos temporarios...
    del /q /f /s "%TEMP%\*" >nul 2>&1
    del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
    del /q /f /s "%LOCALAPPDATA%\Temp\*" >nul 2>&1
    echo Arquivos temporários removidos.
    pause
)
if %opt_clean%==2 (
    echo Configurando Storage Sense...
    powershell -Command "Start-Process 'ms-settings:storagesense' -Wait"
)
if %opt_clean%==3 (
    echo Limpando arquivos de sistema...
    del /f /s /q "%SystemRoot%\Prefetch\*" >nul 2>&1
    del /f /s /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
    del /f /s /q "%SystemRoot%\Logs\*" >nul 2>&1
    echo Limpeza concluida.
    pause
)
if %opt_clean%==4 (
    echo Limpando cache de thumbnails e icones...
    del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1
    del /f /s /q "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
    echo Cache limpo.
    pause
)
if %opt_clean%==5 (
    echo Otimizando unidades de disco...
    powershell -NoProfile -Command "Optimize-Volume -DriveLetter C -Defrag -Verbose"
    echo Otimizacao concluida.
    pause
)
goto menu

:extras
cls
echo ========== FERRAMENTAS ADICIONAIS ==========
echo.
echo [1] Gerenciador de Tarefas
echo [2] Ver Processos com PowerShell
echo [3] Abrir Editor de Registro
echo [4] Gerenciador de Dispositivos
echo [5] Gerenciador de Servicos
echo [6] Verificar Eventos do Sistema
echo [7] Voltar
echo.
choice /c 1234567 /n /m "Escolha uma opcao: "
set "opt_ex=%errorlevel%"

if %opt_ex%==1 start taskmgr
if %opt_ex%==2 (
    powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select -First 30 -Property Id,Name,CPU,WorkingSet,Description | Format-Table -AutoSize" & pause
)
if %opt_ex%==3 start regedit
if %opt_ex%==4 start devmgmt.msc
if %opt_ex%==5 start services.msc
if %opt_ex%==6 (
    echo Abrindo Visualizador de Eventos...
    eventvwr.msc
    pause
)
goto menu