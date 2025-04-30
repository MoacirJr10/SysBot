<#
.SYNOPSIS
    Script principal do SysBot - Versão 3.1
.DESCRIPTION
    Realiza operações de manutenção do sistema com funções corrigidas e otimizadas
#>

# Configuração inicial
$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot
$RootDir = Split-Path -Parent $ScriptRoot
$LogDir = Join-Path -Path $RootDir -ChildPath "logs"

# Função para registrar logs
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    if (-not (Test-Path -Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $logFile = Join-Path -Path $LogDir -ChildPath "sysbot_$(Get-Date -Format 'yyyy-MM-dd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    $logEntry | Out-File -FilePath $logFile -Append

    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        default   { Write-Host $logEntry }
    }
}

# Verificação de admin
function Test-IsAdmin {
    try {
        $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Log "Erro ao verificar privilégios: $_" -Level "ERROR"
        return $false
    }
}

# Função para verificar memória RAM (corrigida)
function Get-MemoryUsage {
    try {
        $os = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop
        $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $free = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $used = $total - $free
        $percentUsed = [math]::Round(($used / $total) * 100, 2)

        return @{
            Total = $total
            Used = $used
            Free = $free
            PercentUsed = $percentUsed
        }
    } catch {
        Write-Log "Erro ao verificar memória RAM: $_" -Level "ERROR"
        return $null
    }
}

# Função para atualizar o sistema (corrigida)
function Update-System {
    try {
        Write-Log "Iniciando verificação de atualizações..." -Level "INFO"

        # Para Windows 10/11
        if (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue) {
            $updates = Get-WindowsUpdate -AcceptAll -AutoReboot:$false -ErrorAction Stop
            if ($updates) {
                $installResult = Install-WindowsUpdate -AcceptAll -AutoReboot:$false -ErrorAction Stop
                Write-Log "Atualizações instaladas: $($installResult.Count)" -Level "INFO"
                return $true
            } else {
                Write-Log "Nenhuma atualização disponível" -Level "INFO"
                return $true
            }
        }
        # Para versões mais antigas
        else {
            $session = New-Object -ComObject Microsoft.Update.Session -ErrorAction Stop
            $searcher = $session.CreateUpdateSearcher()
            $result = $searcher.Search("IsInstalled=0")

            if ($result.Updates.Count -gt 0) {
                Write-Log "Encontradas $($result.Updates.Count) atualizações" -Level "INFO"
                $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
                $result.Updates | ForEach-Object { $updatesToInstall.Add($_) | Out-Null }

                $installer = $session.CreateUpdateInstaller()
                $installer.Updates = $updatesToInstall
                $installationResult = $installer.Install()

                if ($installationResult.ResultCode -eq 2) {
                    Write-Log "Atualizações instaladas com sucesso!" -Level "INFO"
                    return $true
                } else {
                    Write-Log "Falha na instalação" -Level "WARNING"
                    return $false
                }
            } else {
                Write-Log "Nenhuma atualização disponível" -Level "INFO"
                return $true
            }
        }
    } catch {
        Write-Log "Erro durante atualização do sistema: $_" -Level "ERROR"
        return $false
    }
}

# Função para atualizar definições de segurança (corrigida)
function Update-SecurityDefinitions {
    try {
        if (Get-Command Update-MpSignature -ErrorAction SilentlyContinue) {
            Write-Log "Atualizando definições do Windows Defender..." -Level "INFO"
            Update-MpSignature -UpdateSource MicrosoftUpdateServer -ErrorAction Stop
            return $true
        }
        else {
            Write-Log "Windows Defender não disponível" -Level "WARNING"
            return $false
        }
    } catch {
        Write-Log "Erro ao atualizar definições de segurança: $_" -Level "ERROR"
        return $false
    }
}

# Função para limpar arquivos temporários (melhorada)
function Clean-TempFiles {
    param (
        [switch]$Advanced
    )

    try {
        Write-Log "Iniciando limpeza de arquivos temporários..." -Level "INFO"
        $bytesRemoved = 0
        $filesRemoved = 0

        # Pastas básicas para limpar
        $tempFolders = @(
            [System.IO.Path]::GetTempPath(),
            "$env:SystemRoot\Temp",
            "$env:TEMP"
        )

        # Adicionar pastas avançadas se solicitado
        if ($Advanced) {
            $tempFolders += @(
                "$env:SystemRoot\SoftwareDistribution\Download",
                "$env:SystemRoot\Prefetch",
                "$env:LOCALAPPDATA\Temp"
            )
        }

        foreach ($folder in $tempFolders) {
            try {
                if (Test-Path -Path $folder) {
                    Write-Log "Limpando pasta: $folder" -Level "INFO"
                    $filesToRemove = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue |
                            Where-Object { $_.FullName -notlike "*$($LogDir)*" }

                    # Calcular tamanho total antes de remover
                    $size = ($filesToRemove | Measure-Object -Property Length -Sum).Sum
                    $bytesRemoved += $size
                    $filesRemoved += $filesToRemove.Count

                    # Remover arquivos
                    $filesToRemove | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Log "Erro ao limpar $folder : $_" -Level "WARNING"
            }
        }

        $mbRemoved = [math]::Round($bytesRemoved / 1MB, 2)
        Write-Log "Limpeza concluída: $filesRemoved arquivos removidos ($mbRemoved MB)" -Level "INFO"
        return @{
            BytesRemoved = $bytesRemoved
            FilesRemoved = $filesRemoved
            MBRemoved = $mbRemoved
        }
    } catch {
        Write-Log "Erro durante limpeza de arquivos temporários: $_" -Level "ERROR"
        return $false
    }
}

# Função para limpar cache DNS (corrigida)
function Clear-DNSCache {
    try {
        Write-Log "Limpando cache DNS..." -Level "INFO"
        ipconfig /flushdns | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Cache DNS limpo com sucesso" -Level "INFO"
            return $true
        } else {
            Write-Log "Falha ao limpar cache DNS" -Level "WARNING"
            return $false
        }
    } catch {
        Write-Log "Erro ao limpar cache DNS: $_" -Level "ERROR"
        return $false
    }
}

# Função para verificar portas abertas (melhorada)
function Get-OpenPorts {
    param (
        [int]$TopCount = 10
    )

    try {
        Write-Log "Verificando conexões de rede ativas..." -Level "INFO"

        $netstat = netstat -ano | Select-String "ESTABLISHED" | ForEach-Object {
            $line = $_ -replace '\s+', ' ' -split ' '
            [PSCustomObject]@{
                Protocol = $line[1]
                LocalAddress = $line[2]
                ForeignAddress = $line[3]
                State = $line[4]
                PID = $line[5]
            }
        }

        if ($netstat) {
            $topConnections = $netstat | Group-Object -Property ForeignAddress |
                    Sort-Object -Property Count -Descending |
                    Select-Object -First $TopCount -Property Count, Name,
                    @{Name="Process"; Expression={(Get-Process -Id $_.Group[0].PID -ErrorAction SilentlyContinue).Name}}

            return $topConnections
        } else {
            Write-Log "Nenhuma conexão encontrada" -Level "INFO"
            return $null
        }
    } catch {
        Write-Log "Erro ao verificar portas abertas: $_" -Level "ERROR"
        return $null
    }
}

# Função para verificar erros nos logs do sistema (melhorada)
function Get-SystemErrors {
    param (
        [int]$HoursBack = 24
    )

    try {
        $startTime = (Get-Date).AddHours(-$HoursBack)
        Write-Log "Buscando erros do sistema nas últimas $HoursBack horas..." -Level "INFO"

        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'System', 'Application'
            Level = 1, 2  # Error e Critical
            StartTime = $startTime
        } -MaxEvents 50 -ErrorAction SilentlyContinue | Where-Object {
            $_.TimeCreated -ge $startTime
        }

        if ($events) {
            $errorSummary = $events | Group-Object -Property Id, ProviderName |
                    Sort-Object -Property Count -Descending |
                    Select-Object Count,
                    @{Name="ID"; Expression={($_.Name -split ',')[0]}},
                    @{Name="Source"; Expression={($_.Name -split ',')[1]}},
                    @{Name="Message"; Expression={($_.Group[0].Message -split "`n")[0]}}

            Write-Log "Encontrados $($events.Count) erros nos logs do sistema" -Level "WARNING"
            return $errorSummary
        } else {
            Write-Log "Nenhum erro encontrado nos logs do sistema nas últimas $HoursBack horas" -Level "INFO"
            return $null
        }
    } catch {
        Write-Log "Erro ao buscar logs do sistema: $_" -Level "ERROR"
        return $null
    }
}

# Função para verificar serviços críticos (melhorada)
function Test-CriticalServices {
    $criticalServices = @(
        "wuauserv",      # Windows Update
        "WinDefend",     # Windows Defender
        "wscsvc",        # Security Center
        "Dhcp",          # DHCP Client
        "Dnscache",      # DNS Client
        "EventLog",      # Event Log
        "MpsSvc"         # Windows Firewall
    )

    $results = @()

    foreach ($service in $criticalServices) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue

            if ($svc) {
                $results += [PSCustomObject]@{
                    Name = $svc.DisplayName
                    Status = $svc.Status
                    StartType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$service'").StartMode
                    IsOK = ($svc.Status -eq "Running")
                }
            } else {
                $results += [PSCustomObject]@{
                    Name = $service
                    Status = "Não encontrado"
                    StartType = "N/A"
                    IsOK = $false
                }
                Write-Log "Serviço crítico '$service' não foi encontrado" -Level "WARNING"
            }
        } catch {
            Write-Log "Erro ao verificar serviço $service : $_" -Level "ERROR"
        }
    }

    return $results
}

# Função para otimizar discos (nova)
function Optimize-Disks {
    try {
        Write-Log "Otimizando volumes..." -Level "INFO"
        $optimizedVolumes = @()

        if (Get-Command Optimize-Volume -ErrorAction SilentlyContinue) {
            Get-Volume | Where-Object {
                $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $null
            } | ForEach-Object {
                try {
                    Write-Log "Otimizando volume $($_.DriveLetter)..." -Level "INFO"
                    Optimize-Volume -DriveLetter $_.DriveLetter -ErrorAction Stop
                    $optimizedVolumes += $_.DriveLetter
                } catch {
                    Write-Log "Erro ao otimizar volume $($_.DriveLetter): $_" -Level "WARNING"
                }
            }
        } else {
            Write-Log "Cmdlet Optimize-Volume não disponível" -Level "WARNING"
            return $null
        }

        if ($optimizedVolumes.Count -gt 0) {
            Write-Log "Otimização concluída para volumes: $($optimizedVolumes -join ', ')" -Level "INFO"
            return $optimizedVolumes
        } else {
            Write-Log "Nenhum volume otimizado" -Level "WARNING"
            return $null
        }
    } catch {
        Write-Log "Erro durante otimização de volumes: $_" -Level "ERROR"
        return $null
    }
}

# Função para gerar relatório do sistema (melhorada)
function Generate-SystemReport {
    param (
        [switch]$Brief,
        [switch]$Detailed
    )

    try {
        Write-Log "Gerando relatório do sistema..." -Level "INFO"

        # Informações básicas do sistema
        $osInfo = Get-WmiObject Win32_OperatingSystem
        $computerInfo = Get-WmiObject Win32_ComputerSystem
        $biosInfo = Get-WmiObject Win32_BIOS
        $memory = Get-MemoryUsage

        # Uso de disco
        $diskInfo = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } |
                Select-Object DriveLetter, FileSystemLabel,
                @{Name="Size(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}},
                @{Name="Free(GB)"; Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
                @{Name="Free%"; Expression={[math]::Round(($_.SizeRemaining / $_.Size) * 100, 2)}}

        # Processos que mais consomem recursos
        $topProcessesCPU = Get-Process | Sort-Object -Property CPU -Descending |
                Select-Object -First 5 -Property ProcessName, Id, CPU
        $topProcessesMem = Get-Process | Sort-Object -Property WorkingSet -Descending |
                Select-Object -First 5 -Property ProcessName, Id,
                @{Name="Memory(MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}}

        # Exibir relatório
        if ($Brief) {
            Write-Host "`n=== RELATÓRIO RESUMIDO ===" -ForegroundColor Green
            Write-Host "Sistema Operacional: $($osInfo.Caption) ($($osInfo.Version))"
            Write-Host "Fabricante: $($computerInfo.Manufacturer)"
            Write-Host "Modelo: $($computerInfo.Model)"
            Write-Host "Processador: $($computerInfo.SystemFamily)"
            Write-Host "Memória: $($memory.Total) MB total ($($memory.Used) MB usado - $($memory.PercentUsed)%)"

            Write-Host "`nDiscos:" -ForegroundColor Yellow
            $diskInfo | Format-Table -AutoSize

            Write-Host "`nProcessos (CPU):" -ForegroundColor Yellow
            $topProcessesCPU | Format-Table -AutoSize

            Write-Host "`nProcessos (Memória):" -ForegroundColor Yellow
            $topProcessesMem | Format-Table -AutoSize
        }

        if ($Detailed) {
            Write-Host "`n=== RELATÓRIO COMPLETO ===" -ForegroundColor Cyan
            Write-Host "`n► INFORMAÇÕES DO SISTEMA" -ForegroundColor Yellow
            Write-Host "  Nome: $($computerInfo.Name)"
            Write-Host "  Domínio: $($computerInfo.Domain)"
            Write-Host "  Fabricante: $($computerInfo.Manufacturer)"
            Write-Host "  Modelo: $($computerInfo.Model)"
            Write-Host "  Tipo: $($computerInfo.SystemType)"
            Write-Host "  Número de Processadores: $($computerInfo.NumberOfProcessors)"
            Write-Host "  Número de Núcleos: $($computerInfo.NumberOfLogicalProcessors)"

            Write-Host "`n► SISTEMA OPERACIONAL" -ForegroundColor Yellow
            Write-Host "  Nome: $($osInfo.Caption)"
            Write-Host "  Versão: $($osInfo.Version)"
            Write-Host "  Build: $($osInfo.BuildNumber)"
            Write-Host "  Arquitetura: $($osInfo.OSArchitecture)"
            Write-Host "  Diretório: $($osInfo.WindowsDirectory)"
            Write-Host "  Último Boot: $($osInfo.LastBootUpTime)"
            Write-Host "  Tempo de Atividade: $((Get-Date) - $osInfo.ConvertToDateTime($osInfo.LastBootUpTime))"

            Write-Host "`n► BIOS" -ForegroundColor Yellow
            Write-Host "  Fabricante: $($biosInfo.Manufacturer)"
            Write-Host "  Versão: $($biosInfo.SMBIOSBIOSVersion)"
            Write-Host "  Data: $($biosInfo.ReleaseDate)"
            Write-Host "  Serial: $($biosInfo.SerialNumber)"

            Write-Host "`n► MEMÓRIA" -ForegroundColor Yellow
            Write-Host "  Total: $($memory.Total) MB"
            Write-Host "  Usada: $($memory.Used) MB ($($memory.PercentUsed)%)"
            Write-Host "  Livre: $($memory.Free) MB"

            Write-Host "`n► DISCOS" -ForegroundColor Yellow
            $diskInfo | Format-Table -AutoSize

            Write-Host "`n► PROCESSOS (TOP 5 CPU)" -ForegroundColor Yellow
            $topProcessesCPU | Format-Table -AutoSize

            Write-Host "`n► PROCESSOS (TOP 5 MEMÓRIA)" -ForegroundColor Yellow
            $topProcessesMem | Format-Table -AutoSize

            Write-Host "`n► SERVIÇOS CRÍTICOS" -ForegroundColor Yellow
            Test-CriticalServices | Format-Table -AutoSize
        }

        return $true
    } catch {
        Write-Log "Erro ao gerar relatório do sistema: $_" -Level "ERROR"
        return $false
    }
}

# Exportar funções para uso no script principal
Export-ModuleMember -Function *