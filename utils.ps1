<#
    utils.ps1 - Módulo de funções para SYSBOT v3.2
    Atualizado para sincronizar com o script batch principal
    Adicionadas novas funcionalidades e melhorias de segurança
#>

function Write-Header {
    [CmdletBinding()]
    param(
        [string]$Title = "SYSBOT v3.2 TECH TOOL"
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
    [void][System.Console]::ReadKey($true)
}

function Testar-Admin {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Verificar-MemoriaRAM {
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )

    Write-Host "`n[🧠] Verificando uso de memória RAM..." -ForegroundColor Magenta
    try {
        $dados = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($dados.TotalVisibleMemorySize / 1MB, 2)
        $livre = [math]::Round($dados.FreePhysicalMemory / 1MB, 2)
        $uso = [math]::Round($total - $livre, 2)
        $percentual = if ($total -ne 0) { [math]::Round(($uso / $total) * 100, 2) } else { 0 }

        if ($Detailed) {
            $ramModules = Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer, PartNumber,
            @{Name='CapacityGB';Expression={[math]::Round($_.Capacity/1GB,2)}}, Speed, BankLabel

            Write-Host "`n🧠 Total: $total GB | Em Uso: $uso GB ($percentual`%)" -ForegroundColor White
            $ramModules | Format-Table -AutoSize
        } else {
            Write-Host "`n🧠 Total: $total GB | Em Uso: $uso GB ($percentual`%)" -ForegroundColor White
        }
    } catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $true
}

function Verificar-Atualizacoes {
    [CmdletBinding()]
    param(
        [switch]$InstallUpdates
    )

    Write-Host "`n[🔄] Verificando atualizações do Windows..." -ForegroundColor Magenta
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host " Instalando módulo PSWindowsUpdate..." -ForegroundColor Yellow
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -AllowClobber -Scope CurrentUser
        }

        Import-Module PSWindowsUpdate -Force -ErrorAction Stop
        $updates = Get-WindowsUpdate

        if ($updates.Count -gt 0) {
            Write-Host " `nAtualizações disponíveis:" -ForegroundColor Yellow
            $updates | Select-Object Title, KB, Size | Format-Table -AutoSize

            if ($InstallUpdates) {
                Write-Host " `nInstalando atualizações..." -ForegroundColor Yellow
                Get-WindowsUpdate -AcceptAll -Install -AutoReboot | Out-Host
            }
        } else {
            Write-Host " `nNenhuma atualização disponível." -ForegroundColor Green
        }
    } catch {
        Write-Host "Erro ao verificar atualizações: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $true
}

function Limpeza-Avancada {
    [CmdletBinding()]
    param(
        [switch]$IncludeTempFiles,
        [switch]$IncludeThumbnails,
        [switch]$IncludePrefetch,
        [switch]$IncludeLogs
    )

    Write-Host "`n[🧹] Executando limpeza avançada..." -ForegroundColor Magenta

    try {
        # Limpeza básica do Windows
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow

        # Limpeza adicional baseada nos parâmetros
        if ($IncludeTempFiles) {
            Write-Host " Limpando arquivos temporários..." -ForegroundColor Cyan
            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        }

        if ($IncludeThumbnails) {
            Write-Host " Limpando cache de thumbnails..." -ForegroundColor Cyan
            Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
        }

        if ($IncludePrefetch) {
            Write-Host " Limpando arquivos Prefetch..." -ForegroundColor Cyan
            Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
        }

        if ($IncludeLogs) {
            Write-Host " Limpando logs antigos..." -ForegroundColor Cyan
            Remove-Item -Path "$env:SystemRoot\Logs\*" -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host " `n✅ Limpeza concluída com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "Erro durante a limpeza: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $true
}

function Otimizacao-Sistema {
    [CmdletBinding()]
    param(
        [switch]$OptimizeDrives,
        [switch]$Defrag,
        [switch]$TrimSSD
    )

    Write-Host "`n[⚙️] Otimizando sistema..." -ForegroundColor Magenta

    try {
        if ($OptimizeDrives) {
            Write-Host " Otimizando unidades de disco..." -ForegroundColor Cyan
            Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object {
                Write-Host "  Processando unidade $($_.DriveLetter):" -ForegroundColor White
                Optimize-Volume -DriveLetter $_.DriveLetter -Verbose
            }
        }

        if ($Defrag) {
            Write-Host " Desfragmentando HDDs..." -ForegroundColor Cyan
            Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -and $_.MediaType -eq 'HDD' } | ForEach-Object {
                Write-Host "  Desfragmentando $($_.DriveLetter):" -ForegroundColor White
                Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -Verbose
            }
        }

        if ($TrimSSD) {
            Write-Host " Executando TRIM em SSDs..." -ForegroundColor Cyan
            Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -and $_.MediaType -eq 'SSD' } | ForEach-Object {
                Write-Host "  TRIM em $($_.DriveLetter):" -ForegroundColor White
                Optimize-Volume -DriveLetter $_.DriveLetter -ReTrim -Verbose
            }
        }

        Write-Host " `n✅ Otimização concluída com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "Erro durante a otimização: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $true
}

function Verificar-Drivers {
    [CmdletBinding()]
    param(
        [switch]$CheckUpdates,
        [switch]$ExportList
    )

    Write-Host "`n[🔍] Verificando drivers..." -ForegroundColor Magenta

    try {
        $drivers = Get-WmiObject Win32_PnPSignedDriver |
                Where-Object { $_.DeviceName -and $_.DriverVersion } |
                Sort-Object DriverDate -Descending |
                Select-Object DeviceName, Manufacturer, DriverVersion,
                @{Name='DriverDate';Expression={$_.DriverDate.ToShortDateString()}}

        Write-Host " `nDrivers instalados (últimos 10):" -ForegroundColor Yellow
        $drivers | Select-Object -First 10 | Format-Table -AutoSize

        if ($CheckUpdates) {
            Write-Host " `nVerificando drivers desatualizados..." -ForegroundColor Yellow
            # Implementação futura para verificar atualizações de drivers
        }

        if ($ExportList) {
            $date = Get-Date -Format "yyyy-MM-dd"
            $filePath = "$env:USERPROFILE\Desktop\Drivers_List_$date.csv"
            $drivers | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
            Write-Host " `nLista de drivers exportada para: $filePath" -ForegroundColor Green
        }
    } catch {
        Write-Host "Erro ao verificar drivers: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $true
}

function Testar-VelocidadeInternet {
    [CmdletBinding()]
    param(
        [int]$TestDuration = 10
    )

    Write-Host "`n[🌐] Testando velocidade da Internet..." -ForegroundColor Magenta

    try {
        Write-Host " Baixando ferramenta SpeedTest CLI..." -ForegroundColor Cyan
        $progressPreference = 'silentlyContinue'
        Invoke-WebRequest -Uri "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip" -OutFile "$env:TEMP\speedtest.zip"

        if (-not (Test-Path "$env:TEMP\speedtest.zip")) {
            throw "Falha ao baixar o SpeedTest CLI"
        }

        Expand-Archive -Path "$env:TEMP\speedtest.zip" -DestinationPath "$env:TEMP\speedtest" -Force
        $speedtest = "$env:TEMP\speedtest\speedtest.exe"

        if (-not (Test-Path $speedtest)) {
            throw "Arquivo speedtest.exe não encontrado"
        }

        Write-Host " Executando teste de velocidade (pode levar alguns minutos)..." -ForegroundColor Cyan
        $result = & $speedtest --format=json --accept-license --accept-gdpr
        $jsonResult = $result | ConvertFrom-Json

        Write-Host " `n📊 Resultados do SpeedTest:" -ForegroundColor Yellow
        Write-Host "  Download: $([math]::Round($jsonResult.download.bandwidth/125000, 2)) Mbps" -ForegroundColor White
        Write-Host "  Upload: $([math]::Round($jsonResult.upload.bandwidth/125000, 2)) Mbps" -ForegroundColor White
        Write-Host "  Ping: $($jsonResult.ping.latency) ms" -ForegroundColor White
        Write-Host "  Provedor: $($jsonResult.isp)" -ForegroundColor White

        # Limpeza
        Remove-Item -Path "$env:TEMP\speedtest.zip" -Force
        Remove-Item -Path "$env:TEMP\speedtest" -Recurse -Force
    } catch {
        Write-Host "Erro ao testar velocidade: $($_.Exception.Message)" -ForegroundColor Red

        # Método alternativo simples
        Write-Host " `nExecutando teste alternativo..." -ForegroundColor Yellow
        $url = "https://speedtest.net/speedtest.ashx"
        $size = 10MB  # Tamanho do arquivo de teste

        # Teste de download
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $data = Invoke-WebRequest -Uri $url -Method Head
        $sw.Stop()

        $speed = ($size * 8) / $sw.Elapsed.TotalSeconds / 1e6  # Convertendo para Mbps
        Write-Host "  Velocidade aproximada: $([math]::Round($speed, 2)) Mbps" -ForegroundColor White
        return $false
    }
    return $true
}

function Criar-Relatorio {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "$env:USERPROFILE\Desktop"
    )

    Write-Host "`n[📄] Gerando relatório do sistema..." -ForegroundColor Magenta

    try {
        $date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $reportPath = Join-Path -Path $OutputPath -ChildPath "SysBot_Relatorio_$date.html"

        # CSS para o relatório HTML
        $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Relatório SYSBOT - $date</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        h2 { color: #3498db; border-bottom: 1px solid #eee; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th { background-color: #3498db; color: white; text-align: left; padding: 8px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .warning { color: #f39c12; }
        .error { color: #e74c3c; }
        .success { color: #2ecc71; }
    </style>
</head>
<body>
    <h1>Relatório SYSBOT - $(Get-Date)</h1>
"@

        # Informações do sistema
        $os = Get-CimInstance Win32_OperatingSystem
        $computer = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS

        $htmlSystemInfo = @"
    <h2>Informações do Sistema</h2>
    <table>
        <tr><th>Item</th><th>Valor</th></tr>
        <tr><td>Sistema Operacional</td><td>$($os.Caption) ($($os.OSArchitecture))</td></tr>
        <tr><td>Versão</td><td>$($os.Version)</td></tr>
        <tr><td>Fabricante</td><td>$($computer.Manufacturer)</td></tr>
        <tr><td>Modelo</td><td>$($computer.Model)</td></tr>
        <tr><td>Processador</td><td>$($computer.NumberOfLogicalProcessors) núcleos</td></tr>
        <tr><td>Memória Total</td><td>$([math]::Round($computer.TotalPhysicalMemory/1GB, 2)) GB</td></tr>
        <tr><td>BIOS</td><td>$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)</td></tr>
    </table>
"@

        # Informações de memória
        $memory = Get-CimInstance Win32_OperatingSystem
        $totalRAM = [math]::Round($memory.TotalVisibleMemorySize/1MB, 2)
        $freeRAM = [math]::Round($memory.FreePhysicalMemory/1MB, 2)
        $usedRAM = $totalRAM - $freeRAM
        $ramUsage = [math]::Round(($usedRAM/$totalRAM)*100, 2)

        $htmlMemory = @"
    <h2>Uso de Memória</h2>
    <table>
        <tr><th>Total</th><th>Em Uso</th><th>Livre</th><th>Uso</th></tr>
        <tr>
            <td>$totalRAM GB</td>
            <td>$usedRAM GB</td>
            <td>$freeRAM GB</td>
            <td>$ramUsage%</td>
        </tr>
    </table>
"@

        # Informações de disco
        $disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size, HealthStatus
        $volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } |
                Select-Object DriveLetter, FileSystemLabel,
                @{Name='TotalGB';Expression={[math]::Round($_.Size/1GB, 2)}},
                @{Name='FreeGB';Expression={[math]::Round($_.SizeRemaining/1GB, 2)}}

        $htmlDisks = @"
    <h2>Discos Físicos</h2>
    <table>
        <tr><th>Nome</th><th>Tipo</th><th>Tamanho</th><th>Saúde</th></tr>
        $($disks | ForEach-Object {
            "<tr><td>$($_.FriendlyName)</td><td>$($_.MediaType)</td><td>$([math]::Round($_.Size/1GB, 2)) GB</td><td>$($_.HealthStatus)</td></tr>"
        })
    </table>
    
    <h2>Volumes</h2>
    <table>
        <tr><th>Unidade</th><th>Rótulo</th><th>Tamanho</th><th>Livre</th></tr>
        $($volumes | ForEach-Object {
            "<tr><td>$($_.DriveLetter):</td><td>$($_.FileSystemLabel)</td><td>$($_.TotalGB) GB</td><td>$($_.FreeGB) GB</td></tr>"
        })
    </table>
"@

        # Drivers
        $drivers = Get-WmiObject Win32_PnPSignedDriver |
                Where-Object { $_.DeviceName -and $_.DriverVersion } |
                Sort-Object DriverDate -Descending |
                Select-Object -First 10 DeviceName, Manufacturer, DriverVersion,
                @{Name='DriverDate';Expression={$_.DriverDate.ToShortDateString()}}

        $htmlDrivers = @"
    <h2>Últimos Drivers Instalados</h2>
    <table>
        <tr><th>Dispositivo</th><th>Fabricante</th><th>Versão</th><th>Data</th></tr>
        $($drivers | ForEach-Object {
            "<tr><td>$($_.DeviceName)</td><td>$($_.Manufacturer)</td><td>$($_.DriverVersion)</td><td>$($_.DriverDate)</td></tr>"
        })
    </table>
"@

        # Finalizar HTML
        $htmlFooter = @"
    <h2>Recomendações</h2>
    <ul>
        <li>Verifique regularmente as atualizações do sistema</li>
        <li>Mantenha pelo menos 15% de espaço livre em cada unidade</li>
        <li>Faça backups periódicos dos seus dados importantes</li>
    </ul>
</body>
</html>
"@

        # Combinar todas as seções e salvar
        $fullHtml = $htmlHeader + $htmlSystemInfo + $htmlMemory + $htmlDisks + $htmlDrivers + $htmlFooter
        $fullHtml | Out-File -FilePath $reportPath -Encoding UTF8

        Write-Host " `n✅ Relatório gerado com sucesso: $reportPath" -ForegroundColor Green
        return $reportPath
    } catch {
        Write-Host "Erro ao gerar relatório: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Export-ModuleMember -Function *