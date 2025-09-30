function Write-Header {
    [CmdletBinding()]
    param(
        [string]$Title = "SYSBOT TECH TOOL"
    )

    Clear-Host
    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "             ███████╗██╗   ██╗███████╗             " -ForegroundColor Cyan
    Write-Host "             ██╔════╝██║   ██║██╔════╝             " -ForegroundColor Cyan
    Write-Host "             █████╗  ██║   ██║█████╗               " -ForegroundColor Cyan
    Write-Host "             ██╔══╝  ██║   ██║██╔══╝               " -ForegroundColor Cyan
    Write-Host "             ██║     ╚██████╔╝███████╗             " -ForegroundColor Cyan
    Write-Host "             ╚═╝      ╚═════╝ ╚══════╝             " -ForegroundColor Cyan
    Write-Host "               $($Title.PadRight(20))              " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Cyan
}

function Pausar {
    [CmdletBinding()]
    param(
        [string]$Message = "Pressione qualquer tecla para continuar..."
    )

    Write-Host "`n>> $Message" -ForegroundColor Yellow
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Read-Host "Pressione Enter para continuar"
    }
}

function Test-Administrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Warning "Nao foi possivel verificar privilegios de administrador: $($_.Exception.Message)"
        return $false
    }
}

function Get-MemoryInfo {
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )

    Write-Host "`n[🧠] Verificando uso de memoria RAM..." -ForegroundColor Magenta
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedGB = [math]::Round($totalGB - $freeGB, 2)
        $percentUsed = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }

        if ($Detailed) {
            try {
                $ramModules = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction Stop |
                        Select-Object Manufacturer, PartNumber,
                        @{Name='CapacityGB';Expression={[math]::Round($_.Capacity/1GB,2)}},
                        Speed, BankLabel

                Write-Host "`n🧠 Total: $totalGB GB | Em Uso: $usedGB GB ($percentUsed%)" -ForegroundColor White
                if ($ramModules) {
                    $ramModules | Format-Table -AutoSize
                }
            }
            catch {
                Write-Host "`n🧠 Total: $totalGB GB | Em Uso: $usedGB GB ($percentUsed%)" -ForegroundColor White
                Write-Warning "Nao foi possível obter detalhes dos modulos de RAM"
            }
        } else {
            Write-Host "`n🧠 Total: $totalGB GB | Em Uso: $usedGB GB ($percentUsed%)" -ForegroundColor White
        }
        return $true
    } catch {
        Write-Host "Erro ao verificar memoria: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-WindowsUpdates {
    [CmdletBinding()]
    param(
        [switch]$InstallUpdates
    )

    Write-Host "`n[🔄] Verificando atualizacoes do Windows..." -ForegroundColor Magenta

    if (-not (Test-Administrator)) {
        Write-Host "AVISO: Privilegios de administrador necessários para verificar atualizacoes." -ForegroundColor Yellow
        return $false
    }

    try {
        # Verificar se o módulo PSWindowsUpdate está disponível
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "Instalando modulo PSWindowsUpdate..." -ForegroundColor Yellow
            try {
                Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -AllowClobber -Scope CurrentUser -ErrorAction Stop
            }
            catch {
                Write-Host "Erro ao instalar PSWindowsUpdate: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Tentando metodo alternativo..." -ForegroundColor Yellow

                # Método alternativo usando Windows Update Agent API
                $updateSession = New-Object -ComObject Microsoft.Update.Session
                $updateSearcher = $updateSession.CreateUpdateSearcher()
                $searchResult = $updateSearcher.Search("IsInstalled=0")

                if ($searchResult.Updates.Count -gt 0) {
                    Write-Host "`nEncontradas $($searchResult.Updates.Count) atualizacoes disponiveis" -ForegroundColor Yellow
                    foreach ($update in $searchResult.Updates) {
                        Write-Host "- $($update.Title)" -ForegroundColor White
                    }
                } else {
                    Write-Host "`nNenhuma atualizacao disponivel." -ForegroundColor Green
                }
                return $true
            }
        }

        Import-Module PSWindowsUpdate -Force -ErrorAction Stop
        $updates = Get-WindowsUpdate -ErrorAction Stop

        if ($updates.Count -gt 0) {
            Write-Host "`nAtualizacoes disponiveis:" -ForegroundColor Yellow
            $updates | Select-Object Title, KB, Size | Format-Table -AutoSize

            if ($InstallUpdates) {
                Write-Host "`nInstalando atualizacoes..." -ForegroundColor Yellow
                Install-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-Host
            }
        } else {
            Write-Host "`nNenhuma atualizacao disponivel." -ForegroundColor Green
        }
        return $true
    } catch {
        Write-Host "Erro ao verificar atualizacoes: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-SystemCleanup {
    [CmdletBinding()]
    param(
        [switch]$IncludeTempFiles,
        [switch]$IncludeThumbnails,
        [switch]$IncludePrefetch,
        [switch]$IncludeLogs
    )

    Write-Host "`n[🧹] Executando limpeza do sistema..." -ForegroundColor Magenta

    try {
        # Limpeza usando Disk Cleanup
        Write-Host "Executando limpeza de disco..." -ForegroundColor Cyan
        if (Test-Path "$env:SystemRoot\System32\cleanmgr.exe") {
            Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        }

        # Limpeza adicional baseada nos parâmetros
        if ($IncludeTempFiles) {
            Write-Host "Limpando arquivos temporarios..." -ForegroundColor Cyan
            $tempPaths = @(
                "$env:TEMP\*",
                "$env:SystemRoot\Temp\*",
                "$env:LOCALAPPDATA\Temp\*"
            )

            foreach ($path in $tempPaths) {
                try {
                    if (Test-Path (Split-Path $path -Parent)) {
                        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Verbose "Nao foi possível limpar: $path"
                }
            }
        }

        if ($IncludeThumbnails) {
            Write-Host "Limpando cache de thumbnails..." -ForegroundColor Cyan
            $thumbPaths = @(
                "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*",
                "$env:LOCALAPPDATA\IconCache.db"
            )

            foreach ($path in $thumbPaths) {
                try {
                    Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Verbose "Nao foi possivel remover: $path"
                }
            }
        }

        if ($IncludePrefetch -and (Test-Administrator)) {
            Write-Host "Limpando arquivos Prefetch..." -ForegroundColor Cyan
            try {
                Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Nao foi possível limpar Prefetch"
            }
        }

        if ($IncludeLogs -and (Test-Administrator)) {
            Write-Host "Limpando logs antigos..." -ForegroundColor Cyan
            $logPaths = @(
                "$env:SystemRoot\Logs\*",
                "$env:SystemRoot\System32\LogFiles\*"
            )

            foreach ($path in $logPaths) {
                try {
                    if (Test-Path (Split-Path $path -Parent)) {
                        Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
                                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
                                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Verbose "Nao foi possível limpar logs em: $path"
                }
            }
        }

        Write-Host "`n✅ Limpeza concluida!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erro durante a limpeza: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Optimize-SystemDrives {
    [CmdletBinding()]
    param(
        [switch]$OptimizeAll,
        [switch]$DefragHDD,
        [switch]$TrimSSD
    )

    Write-Host "`n[⚙️] Otimizando unidades de disco..." -ForegroundColor Magenta

    if (-not (Test-Administrator)) {
        Write-Host "AVISO: Privilegios de administrador necessarios para otimizacao." -ForegroundColor Yellow
        return $false
    }

    try {
        $volumes = Get-Volume | Where-Object {
            $_.DriveType -eq 'Fixed' -and
                    $_.DriveLetter -and
                    $_.FileSystem -in @('NTFS', 'ReFS')
        }

        if (-not $volumes) {
            Write-Host "Nenhuma unidade elegivel encontrada." -ForegroundColor Yellow
            return $false
        }

        foreach ($volume in $volumes) {
            Write-Host "Processando unidade $($volume.DriveLetter):" -ForegroundColor White

            try {
                if ($OptimizeAll) {
                    Write-Host "  Otimizando..." -ForegroundColor Cyan
                    Optimize-Volume -DriveLetter $volume.DriveLetter -Verbose -ErrorAction Stop
                }

                # Verificar tipo de mídia para operações específicas
                $physicalDisk = Get-PhysicalDisk | Where-Object {
                    $_.DeviceID -in (Get-Partition | Where-Object { $_.DriveLetter -eq $volume.DriveLetter } | ForEach-Object { $_.DiskNumber })
                }

                if ($physicalDisk) {
                    if ($DefragHDD -and $physicalDisk.MediaType -eq 'HDD') {
                        Write-Host "  Desfragmentando HDD..." -ForegroundColor Cyan
                        Optimize-Volume -DriveLetter $volume.DriveLetter -Defrag -Verbose -ErrorAction Stop
                    }

                    if ($TrimSSD -and $physicalDisk.MediaType -eq 'SSD') {
                        Write-Host "  Executando TRIM em SSD..." -ForegroundColor Cyan
                        Optimize-Volume -DriveLetter $volume.DriveLetter -ReTrim -Verbose -ErrorAction Stop
                    }
                }
            }
            catch {
                Write-Host "  Erro ao otimizar $($volume.DriveLetter): $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        Write-Host "`n✅ Otimizacao concluída!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erro durante a otimizacao: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-DriverInfo {
    [CmdletBinding()]
    param(
        [switch]$ExportList
    )

    Write-Host "`n[🔍] Verificando drivers do sistema..." -ForegroundColor Magenta

    try {
        $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop |
                Where-Object { $_.DeviceName -and $_.DriverVersion } |
                Sort-Object @{Expression={$_.DriverDate}; Descending=$true} |
                Select-Object DeviceName, Manufacturer, DriverVersion,
                @{Name='DriverDate';Expression={
                    if ($_.DriverDate) {
                        [Management.ManagementDateTimeConverter]::ToDateTime($_.DriverDate).ToString("yyyy-MM-dd")
                    } else {
                        "N/A"
                    }
                }}

        Write-Host "`nDrivers instalados (últimos 15):" -ForegroundColor Yellow
        $drivers | Select-Object -First 15 | Format-Table -AutoSize

        if ($ExportList) {
            $date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $filePath = Join-Path $env:USERPROFILE "Desktop\Drivers_List_$date.csv"
            try {
                $drivers | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
                Write-Host "`nLista de drivers exportada para: $filePath" -ForegroundColor Green
            }
            catch {
                Write-Host "Erro ao exportar lista: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        return $true
    } catch {
        Write-Host "Erro ao verificar drivers: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-InternetSpeed {
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds = 30
    )

    Write-Host "`n[🌐] Testando conectividade e velocidade..." -ForegroundColor Magenta

    try {
        # Teste básico de conectividade
        Write-Host "Testando conectividade..." -ForegroundColor Cyan
        $pingTest = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet

        if (-not $pingTest) {
            Write-Host "Sem conectividade com a internet." -ForegroundColor Red
            return $false
        }

        # Teste simples de velocidade de download
        Write-Host "Executando teste de velocidade (metodo simplificado)..." -ForegroundColor Cyan

        $testUrl = "http://speedtest.ftp.otenet.gr/files/test1Mb.db"
        $testFile = "$env:TEMP\speedtest.tmp"

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            Invoke-WebRequest -Uri $testUrl -OutFile $testFile -TimeoutSec $TimeoutSeconds -ErrorAction Stop
            $stopwatch.Stop()

            $fileSize = (Get-Item $testFile).Length
            $speedBps = $fileSize / $stopwatch.Elapsed.TotalSeconds
            $speedMbps = [math]::Round(($speedBps * 8) / 1MB, 2)

            Write-Host "`n📊 Resultado do teste:" -ForegroundColor Yellow
            Write-Host "  Velocidade aproximada: $speedMbps Mbps" -ForegroundColor White
            Write-Host "  Tempo de download: $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) segundos" -ForegroundColor White

            Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Erro no teste de velocidade: $($_.Exception.Message)" -ForegroundColor Red

            # Teste alternativo usando ping
            Write-Host "`nExecutando teste de latência..." -ForegroundColor Yellow
            $pingResult = Test-NetConnection -ComputerName "8.8.8.8" -TraceRoute
            Write-Host "  Latência: $($pingResult.PingReplyDetails.RoundtripTime) ms" -ForegroundColor White
        }

        return $true
    } catch {
        Write-Host "Erro ao testar internet: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function New-SystemReport {
    [CmdletBinding()]
    param(
        [string]$OutputPath = $env:USERPROFILE
    )

    Write-Host "`n[📄] Gerando relatorio do sistema..." -ForegroundColor Magenta

    try {
        $date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $reportPath = Join-Path -Path $OutputPath -ChildPath "SysBot_Relatorio_$date.html"

        # Coletar informações do sistema
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem
        $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1

        # CSS e estrutura HTML
        $htmlContent = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório SYSBOT - $date</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1000px;
            margin: 40px auto;
            background: #fff;
            padding: 30px 40px;
            border-radius: 10px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin-bottom: 10px;
        }
        h2 {
            color: #3498db;
            border-bottom: 2px solid #ecf0f1;
            padding-bottom: 5px;
            margin-top: 40px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 1px 5px rgba(0,0,0,0.05);
        }
        th {
            background-color: #3498db;
            color: white;
            text-align: center;
            padding: 12px;
            font-size: 15px;
        }
        td {
            border: 1px solid #eee;
            padding: 10px;
            text-align: center;
            background-color: #fff;
            font-size: 14px;
        }
        tr:nth-child(even) td {
            background-color: #f8f9fa;
        }
        .status-good {
            color: #27ae60;
            font-weight: bold;
        }
        .status-warning {
            color: #f39c12;
            font-weight: bold;
        }
        .status-error {
            color: #e74c3c;
            font-weight: bold;
        }
        .footer {
            margin-top: 40px;
            padding: 20px;
            background-color: #ecf0f1;
            border-radius: 8px;
        }
        .footer h3 {
            margin-bottom: 10px;
            color: #2c3e50;
        }
        .footer ul {
            text-align: left;
            padding-left: 20px;
        }
        .footer li {
            margin-bottom: 8px;
        }
        .footer p {
            margin-top: 20px;
            font-size: 12px;
            color: #7f8c8d;
            text-align: center;
        }
        .date {
            text-align: center;
            color: #7f8c8d;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖥️ Relatório do Sistema SYSBOT</h1>
        <p class="date">Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>

        <h2>💻 Informações Gerais</h2>
        <table>
            <tr><th>Item</th><th>Informação</th></tr>
            <tr><td>Sistema Operacional</td><td>$($os.Caption)</td></tr>
            <tr><td>Versão</td><td>$($os.Version)</td></tr>
            <tr><td>Arquitetura</td><td>$($os.OSArchitecture)</td></tr>
            <tr><td>Fabricante</td><td>$($computer.Manufacturer)</td></tr>
            <tr><td>Modelo</td><td>$($computer.Model)</td></tr>
            <tr><td>Processador</td><td>$($processor.Name)</td></tr>
            <tr><td>Núcleos Lógicos</td><td>$($processor.NumberOfLogicalProcessors)</td></tr>
            <tr><td>Memória Total</td><td>$([math]::Round($computer.TotalPhysicalMemory/1GB, 2)) GB</td></tr>
        </table>

        <h2>🧠 Status da Memória</h2>
        <table>
            <tr><th>Métrica</th><th>Valor</th></tr>
            <tr><td>Total</td><td>$([math]::Round($os.TotalVisibleMemorySize/1MB, 2)) GB</td></tr>
            <tr><td>Disponível</td><td>$([math]::Round($os.FreePhysicalMemory/1MB, 2)) GB</td></tr>
            <tr><td>Em Uso</td><td>$([math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB, 2)) GB</td></tr>
            <tr><td>Percentual de Uso</td><td>$([math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/$os.TotalVisibleMemorySize)*100, 1))%</td></tr>
        </table>

        <h2>💾 Informações de Armazenamento</h2>
        <table>
            <tr><th>Unidade</th><th>Tamanho Total</th><th>Espaço Livre</th><th>Usado</th><th>Status</th></tr>
"@

        # PowerShell loop de volumes
        $volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
        foreach ($volume in $volumes) {
            $totalGB = [math]::Round($volume.Size/1GB, 2)
            $freeGB = [math]::Round($volume.SizeRemaining/1GB, 2)
            $usedGB = $totalGB - $freeGB
            $usedPercent = if ($totalGB -gt 0) { [math]::Round(($usedGB/$totalGB)*100, 1) } else { 0 }

            $status = if ($usedPercent -lt 80) { "status-good" } elseif ($usedPercent -lt 95) { "status-warning" } else { "status-error" }

            $htmlContent += @"
            <tr>
                <td>$($volume.DriveLetter):</td>
                <td>$totalGB GB</td>
                <td>$freeGB GB</td>
                <td class='$status'>$usedPercent%</td>
                <td class='$status'>$(if ($usedPercent -lt 80) { "Bom" } elseif ($usedPercent -lt 95) { "Atenção" } else { "Crítico" })</td>
            </tr>
"@
        }

        $htmlContent += @"
        </table>

        <div class="footer">
            <h3>📋 Recomendações</h3>
            <ul>
                <li>✅ Mantenha o sistema sempre atualizado</li>
                <li>🗂️ Mantenha pelo menos 10-15% de espaço livre em cada unidade</li>
                <li>🔒 Faça backups regulares dos dados importantes</li>
                <li>🧹 Execute limpeza de sistema periodicamente</li>
                <li>🔍 Monitore o desempenho regularmente</li>
            </ul>
            <p>
                Relatório gerado pelo SYSBOT v3.2 — Ferramenta de Diagnóstico e Manutenção
            </p>
        </div>
    </div>
</body>
</html>

"@

        # Salvar o arquivo
        $htmlContent | Out-File -FilePath $reportPath -Encoding UTF8

        Write-Host "`n✅ Relatorio gerado com sucesso!" -ForegroundColor Green
        Write-Host "📄 Local: $reportPath" -ForegroundColor Cyan

        # Perguntar se deseja abrir o relatório
        $response = Read-Host "`nDeseja abrir o relatorio agora? (S/N)"
        if ($response -match '^[Ss]') {
            Start-Process $reportPath
        }

        return $reportPath
    } catch {
        Write-Host "Erro ao gerar relatório: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Exportar todas as funções do módulo
Export-ModuleMember -Function *