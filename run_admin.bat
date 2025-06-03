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

:: Corrigir formato de data e hora
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "DATA_HORA=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"

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
    echo Esta operacao pode demorar alguns minutos...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Install-Module PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber -ErrorAction SilentlyContinue; Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue; if (Get-Module PSWindowsUpdate) { Get-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-File '!log!' -Encoding UTF8 } else { 'Modulo PSWindowsUpdate nao disponivel. Use Windows Update manualmente.' | Out-File '!log!' -Encoding UTF8 } } catch { $_.Exception.Message | Out-File '!log!' -Append -Encoding UTF8 }"
    if exist "!log!" type "!log!"
    pause
)
if %opt_at%==2 (
    set "log=%LOG_DIR%\winget_update_%DATA_HORA%.log"
    echo Atualizando programas via winget...
    echo Verificando se winget esta disponivel...
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        winget upgrade --all --accept-package-agreements --accept-source-agreements > "!log!" 2>&1
    ) else (
        echo winget nao encontrado. Instale o App Installer da Microsoft Store. > "!log!"
    )
    type "!log!"
    pause
)
if %opt_at%==3 (
    set "log=%LOG_DIR%\sfc_%DATA_HORA%.log"
    echo Verificando integridade do sistema com SFC...
    echo Esta operacao pode demorar varios minutos...
    sfc /scannow > "!log!" 2>&1
    type "!log!"
    pause
)
if %opt_at%==4 (
    set "log=%LOG_DIR%\dism_%DATA_HORA%.log"
    echo Restaurando saude do sistema com DISM...
    echo Esta operacao pode demorar varios minutos...
    DISM /Online /Cleanup-Image /RestoreHealth > "!log!" 2>&1
    type "!log!"
    pause
)
if %opt_at%==5 (
    set "log=%LOG_DIR%\drivers_%DATA_HORA%.log"
    echo Verificando drivers do sistema...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null -and $_.DriverVersion -ne $null } | Select-Object DeviceName, DriverVersion, Manufacturer | Sort-Object DeviceName | Format-Table -AutoSize | Out-File '!log!' -Encoding UTF8 } catch { 'Erro ao obter informacoes de drivers: ' + $_.Exception.Message | Out-File '!log!' -Encoding UTF8 }"
    if exist "!log!" type "!log!" | more
    pause
)
if %opt_at%==6 goto menu
goto atualizacao

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
    echo === INFORMACOES DO SISTEMA ===
    systeminfo | findstr /B /C:"Nome do SO" /C:"Versao do SO" /C:"Fabricante" /C:"Modelo" /C:"Tipo do sistema" /C:"Versao do BIOS" /C:"Localidade" /C:"Memoria fisica total"
    pause
)
if %opt_hw%==2 (
    echo === CPU ===
    wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /format:table
    echo.
    echo === GPU ===
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-CimInstance Win32_VideoController | Where-Object { $_.Name -ne $null } | Select Name, DriverVersion, @{Name='VRAM_MB';Expression={[math]::Round($_.AdapterRAM/1MB,0)}} | Format-Table -AutoSize } catch { Write-Host 'Erro ao obter informacoes de GPU' }"
    echo.
    echo === MEMORIA ===
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $memoria = Get-CimInstance Win32_PhysicalMemory; $so = Get-CimInstance Win32_OperatingSystem; $totalGB = [math]::Round($so.TotalVisibleMemorySize/1MB,2); $livreGB = [math]::Round($so.FreePhysicalMemory/1MB,2); $usadoGB = $totalGB - $livreGB; $memoria | Select Manufacturer, PartNumber, Speed, @{Name='Capacidade_GB';Expression={[math]::Round($_.Capacity/1GB,2)}} | Format-Table -AutoSize; Write-Host ('Total: {0} GB | Usado: {1} GB | Livre: {2} GB' -f $totalGB, $usadoGB, $livreGB) } catch { Write-Host 'Erro ao obter informacoes de memoria' }"
    echo.
    echo === DISCO ===
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-PhysicalDisk | Select FriendlyName, MediaType, @{Name='Tamanho_GB';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus | Format-Table -AutoSize; Get-PSDrive -PSProvider FileSystem | Select Name, @{Name='Usado_GB';Expression={[math]::Round($_.Used/1GB,2)}}, @{Name='Livre_GB';Expression={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize } catch { Write-Host 'Erro ao obter informacoes de disco' }"
    pause
)
if %opt_hw%==3 (
    echo === PROGRAMAS INSTALADOS ===
    echo Carregando lista de programas instalados...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -ne $null -and $_.DisplayName -ne '' } | Select DisplayName, DisplayVersion, Publisher | Sort DisplayName | Format-Table -AutoSize | Out-String -Width 120 } catch { Write-Host 'Erro ao obter lista de programas' }" | more
    pause
)
if %opt_hw%==4 (
    echo === TEMPERATURAS E VENTOINHAS ===
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace 'root/wmi' -ErrorAction SilentlyContinue; if ($temp) { $temp | ForEach-Object { $celsius = [math]::Round(($_.CurrentTemperature / 10) - 273.15, 2); Write-Host ('Zona Termica: {0} - Temperatura: {1}°C' -f $_.InstanceName, $celsius) } } else { Write-Host 'Informacoes de temperatura nao disponiveis via WMI' }; $fans = Get-WmiObject Win32_Fan -ErrorAction SilentlyContinue; if ($fans) { $fans | Select Name, Status | Format-Table -AutoSize } else { Write-Host 'Informacoes de ventoinhas nao disponiveis' } } catch { Write-Host 'Erro ao obter informacoes termicas' }"
    pause
)
if %opt_hw%==5 (
    set "relatorio=%LOG_DIR%\relatorio_completo_%DATA_HORA%.txt"
    echo Gerando relatorio completo...
    (
        echo ==== RELATORIO DE HARDWARE/SOFTWARE ====
        echo Data/Hora: %DATA_HORA%
        echo.
        echo === INFORMACOES DO SISTEMA ===
        systeminfo
        echo.
        echo === CPU ===
        wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /format:list
        echo.
        echo === MEMORIA ===
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_PhysicalMemory | Select Manufacturer,PartNumber,Speed,@{Name='Capacidade_GB';Expression={[math]::Round($_.Capacity/1GB,2)}} | Format-List"
        echo.
        echo === DISCO ===
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | Format-List; Get-PSDrive -PSProvider FileSystem | Format-List"
    ) > "!relatorio!" 2>&1
    echo Relatorio salvo em: !relatorio!
    echo Deseja visualizar o relatorio? (S/N)
    choice /c SN /n /m "Resposta: "
    if !errorlevel! equ 1 type "!relatorio!" | more
    pause
)
if %opt_hw%==6 goto menu
goto hardware

:rede
cls
echo ========== DIAGNOSTICO DE REDE ==========
echo.
echo [1] Configuracao de Rede
echo [2] Testar Conexao com Google
echo [3] Testar Porta Especifica
echo [4] Renovar Configuracao de Rede
echo [5] Teste Basico de Velocidade
echo [6] Analisar Conexoes Ativas
echo [7] Voltar
echo.
choice /c 1234567 /n /m "Escolha uma opcao: "
set "opt_net=%errorlevel%"

if %opt_net%==1 (
    echo === CONFIGURACAO DE REDE ===
    ipconfig /all | findstr /i "adaptador ethernet conexao dhcp gateway dns"
    echo.
    echo === ROTAS ===
    route print | findstr /i "0.0.0.0"
    pause
)
if %opt_net%==2 (
    echo === TESTE DE CONECTIVIDADE ===
    echo Testando ping para Google...
    ping -n 4 8.8.8.8
    echo.
    echo Testando resolucao DNS...
    nslookup google.com
    echo.
    echo Testando conectividade HTTP...
    powershell -NoProfile -Command "try { $response = Invoke-WebRequest -Uri 'https://www.google.com' -UseBasicParsing -TimeoutSec 10; Write-Host 'Conexao HTTPS bem-sucedida - Status:' $response.StatusCode -ForegroundColor Green } catch { Write-Host 'Falha na conexao HTTPS:' $_.Exception.Message -ForegroundColor Red }"
    pause
)
if %opt_net%==3 (
    set /p "host=Digite o host (ex: google.com): "
    set /p "porta=Digite a porta (ex: 80): "
    if "!host!"=="" set "host=google.com"
    if "!porta!"=="" set "porta=80"
    echo Testando conexao para !host!:!porta!...
    powershell -NoProfile -Command "$host='!host!'; $porta=!porta!; try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.ConnectAsync($host, $porta).Wait(5000); if ($tcp.Connected) { Write-Host 'Conexao bem-sucedida para' $host':' $porta -ForegroundColor Green; $tcp.Close() } else { Write-Host 'Timeout na conexao para' $host':' $porta -ForegroundColor Yellow } } catch { Write-Host 'Falha na conexao para' $host':' $porta '-' $_.Exception.Message -ForegroundColor Red }"
    pause
)
if %opt_net%==4 (
    echo === RENOVANDO CONFIGURACAO DE REDE ===
    echo Liberando cache DNS...
    ipconfig /flushdns
    echo.
    echo Liberando IP atual...
    ipconfig /release
    echo.
    echo Renovando IP...
    ipconfig /renew
    echo.
    echo Reiniciando adaptador de rede...
    powershell -NoProfile -Command "try { Get-NetAdapter | Where-Object Status -eq 'Up' | Restart-NetAdapter -Confirm:$false; Write-Host 'Adaptadores reiniciados com sucesso' -ForegroundColor Green } catch { Write-Host 'Erro ao reiniciar adaptadores:' $_.Exception.Message -ForegroundColor Red }"
    pause
)
if %opt_net%==5 (
    echo === TESTE BASICO DE VELOCIDADE ===
    echo Realizando teste de download simples...
    set "log=%LOG_DIR%\speedtest_%DATA_HORA%.log"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; try { $start = Get-Date; $response = Invoke-WebRequest -Uri 'https://www.google.com' -UseBasicParsing -TimeoutSec 30; $end = Get-Date; $tempo = ($end - $start).TotalMilliseconds; $tamanho = $response.Content.Length; Write-Host ('Tempo de resposta: {0:F2} ms' -f $tempo); Write-Host ('Tamanho da resposta: {0} bytes' -f $tamanho); $resultado = 'Data: ' + (Get-Date) + [Environment]::NewLine + 'Tempo: ' + [string]$tempo + ' ms' + [Environment]::NewLine + 'Tamanho: ' + [string]$tamanho + ' bytes'; $resultado | Out-File '!log!' -Encoding UTF8 } catch { Write-Host 'Erro no teste:' $_.Exception.Message -ForegroundColor Red; 'Erro: ' + $_.Exception.Message | Out-File '!log!' -Encoding UTF8 }"
    if exist "!log!" (
        echo.
        echo === RESULTADO SALVO ===
        type "!log!"
    )
    pause
)
if %opt_net%==6 (
    echo === CONEXOES ATIVAS ===
    netstat -ano | findstr ESTABLISHED | more
    echo.
    echo === PROCESSOS COM CONEXOES ===
    powershell -NoProfile -Command "try { Get-NetTCPConnection -State Established | Select LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess | Sort-Object OwningProcess | Format-Table -AutoSize } catch { Write-Host 'Erro ao obter conexoes TCP' }"
    pause
)
if %opt_net%==7 goto menu
goto rede

:limpeza
cls
echo ========== FERRAMENTAS DE LIMPEZA ==========
echo.
echo [1] Limpeza de Arquivos Temporarios
echo [2] Executar Limpeza de Disco
echo [3] Limpar Cache do Sistema
echo [4] Limpar Thumbnails e IconCache
echo [5] Otimizar Unidades
echo [6] Voltar
echo.
choice /c 123456 /n /m "Escolha uma opcao: "
set "opt_clean=%errorlevel%"

if %opt_clean%==1 (
    echo === LIMPEZA DE ARQUIVOS TEMPORARIOS ===
    echo Limpando arquivos temporarios do usuario...
    if exist "%TEMP%" (
        del /q /f /s "%TEMP%\*" >nul 2>&1
        for /d %%i in ("%TEMP%\*") do rd /s /q "%%i" >nul 2>&1
    )
    echo.
    echo Limpando arquivos temporarios do sistema...
    if exist "%SystemRoot%\Temp" (
        del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
        for /d %%i in ("%SystemRoot%\Temp\*") do rd /s /q "%%i" >nul 2>&1
    )
    echo.
    echo Limpando arquivos temporarios locais...
    if exist "%LOCALAPPDATA%\Temp" (
        del /q /f /s "%LOCALAPPDATA%\Temp\*" >nul 2>&1
        for /d %%i in ("%LOCALAPPDATA%\Temp\*") do rd /s /q "%%i" >nul 2>&1
    )
    echo Limpeza de arquivos temporarios concluida.
    pause
)
if %opt_clean%==2 (
    echo === EXECUTANDO LIMPEZA DE DISCO ===
    echo Abrindo ferramenta de Limpeza de Disco...
    cleanmgr /sagerun:1
    pause
)
if %opt_clean%==3 (
    echo === LIMPEZA DE CACHE DO SISTEMA ===
    echo Limpando Prefetch...
    if exist "%SystemRoot%\Prefetch" (
        del /f /s /q "%SystemRoot%\Prefetch\*" >nul 2>&1
    )
    echo.
    echo Limpando arquivos recentes...
    if exist "%APPDATA%\Microsoft\Windows\Recent" (
        del /f /s /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
    )
    echo.
    echo Limpando logs do sistema...
    if exist "%SystemRoot%\Logs" (
        del /f /s /q "%SystemRoot%\Logs\*" >nul 2>&1
    )
    echo Limpeza de cache concluida.
    pause
)
if %opt_clean%==4 (
    echo === LIMPEZA DE CACHE VISUAL ===
    echo Limpando cache de thumbnails...
    if exist "%LOCALAPPDATA%\Microsoft\Windows\Explorer" (
        del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1
    )
    echo.
    echo Limpando cache de icones...
    if exist "%LOCALAPPDATA%\IconCache.db" (
        del /f /q "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
    )
    echo.
    echo Reiniciando Windows Explorer para aplicar mudancas...
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 2 >nul
    start explorer.exe
    echo Cache visual limpo.
    pause
)
if %opt_clean%==5 (
    echo === OTIMIZACAO DE UNIDADES ===
    echo Verificando unidades disponiveis...
    powershell -NoProfile -Command "try { $drives = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.FileSystem -eq 'NTFS' }; foreach ($drive in $drives) { Write-Host ('Otimizando unidade {0}:' -f $drive.DriveLetter); Optimize-Volume -DriveLetter $drive.DriveLetter -Defrag -Verbose } } catch { Write-Host 'Erro na otimizacao:' $_.Exception.Message -ForegroundColor Red }"
    echo Otimizacao concluida.
    pause
)
if %opt_clean%==6 goto menu
goto limpeza

:extras
cls
echo ========== FERRAMENTAS ADICIONAIS ==========
echo.
echo [1] Gerenciador de Tarefas
echo [2] Ver Processos Detalhados
echo [3] Editor de Registro
echo [4] Gerenciador de Dispositivos
echo [5] Gerenciador de Servicos
echo [6] Visualizador de Eventos
echo [7] Informacoes do Sistema (msinfo32)
echo [8] Voltar
echo.
choice /c 12345678 /n /m "Escolha uma opcao: "
set "opt_ex=%errorlevel%"

if %opt_ex%==1 (
    echo Abrindo Gerenciador de Tarefas...
    start taskmgr
)
if %opt_ex%==2 (
    echo === PROCESSOS DO SISTEMA ===
    echo Top 20 processos por uso de CPU:
    powershell -NoProfile -Command "try { Get-Process | Sort-Object CPU -Descending | Select -First 20 -Property Id, Name, @{Name='CPU_Tempo';Expression={$_.CPU}}, @{Name='Memoria_MB';Expression={[math]::Round($_.WorkingSet/1MB,2)}}, Description | Format-Table -AutoSize } catch { Write-Host 'Erro ao obter processos' }"
    pause
)
if %opt_ex%==3 (
    echo Abrindo Editor de Registro...
    echo AVISO: Tenha cuidado ao editar o registro!
    timeout /t 3 >nul
    start regedit
)
if %opt_ex%==4 (
    echo Abrindo Gerenciador de Dispositivos...
    start devmgmt.msc
)
if %opt_ex%==5 (
    echo Abrindo Gerenciador de Servicos...
    start services.msc
)
if %opt_ex%==6 (
    echo Abrindo Visualizador de Eventos...
    start eventvwr.msc
)
if %opt_ex%==7 (
    echo Abrindo Informacoes do Sistema...
    start msinfo32
)
if %opt_ex%==8 goto menu
goto extras