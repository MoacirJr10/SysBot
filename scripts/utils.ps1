<#
.SYNOPSIS
    Módulo de utilitários avançados para o SysBot
.DESCRIPTION
    Contém funções para diagnóstico e manutenção do sistema
#>

# Função para verificar uso de memória
function Get-MemoryUsage {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $free = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $used = $total - $free
        $percentUsed = [math]::Round(($used / $total) * 100, 2)

        return [PSCustomObject]@{
            Total        = $total
            Used         = $used
            Free         = $free
            PercentUsed  = $percentUsed
        }
    } catch {
        Write-Error "Erro ao verificar memória: $_"
        return $null
    }
}

# Função para verificar portas abertas
function Get-OpenPorts {
    param (
        [int]$TopCount = 10
    )

    try {
        $connections = @()
        $netstat = netstat -ano | Select-String "ESTABLISHED"

        foreach ($line in $netstat) {
            $parts = $line -replace '\s+', ' ' -split ' '
            if ($parts.Length -ge 5) {
                $proc = Get-Process -Id $parts[4] -ErrorAction SilentlyContinue
                $connections += [PSCustomObject]@{
                    Protocol      = $parts[0]
                    LocalAddress  = $parts[1]
                    ForeignAddress= $parts[2]
                    State         = $parts[3]
                    PID           = $parts[4]
                    ProcessName   = if ($proc) { $proc.Name } else { "Desconhecido" }
                }
            }
        }

        $grouped = $connections | Group-Object -Property ForeignAddress |
                Sort-Object -Property Count -Descending |
                Select-Object -First $TopCount -Property Count, Name,
                @{Name="Process"; Expression={($_.Group[0].ProcessName)}}

        return $grouped
    } catch {
        Write-Error "Erro ao verificar portas abertas: $_"
        return $null
    }
}

# Função para verificar erros do sistema
function Get-SystemErrors {
    param (
        [int]$HoursBack = 24
    )

    try {
        $startTime = (Get-Date).AddHours(-$HoursBack)
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = @('System', 'Application')
            Level     = @(1, 2)  # Error and Critical
            StartTime = $startTime
        } -MaxEvents 100 | Where-Object { $_.TimeCreated -ge $startTime }

        if ($events) {
            $errorSummary = $events | Group-Object -Property Id, ProviderName |
                    Sort-Object -Property Count -Descending |
                    Select-Object Count,
                    @{Name="ID"; Expression={($_.Name -split ',')[0]}},
                    @{Name="Source"; Expression={($_.Name -split ',')[1]}},
                    @{Name="Message"; Expression={($_.Group[0].Message -split "`n")[0]}}

            return $errorSummary
        }

        return @()
    } catch {
        Write-Error "Erro ao verificar eventos do sistema: $_"
        return $null
    }
}

# Função para verificar serviços críticos
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
                $startMode = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$service'" -ErrorAction SilentlyContinue).StartMode
                $results += [PSCustomObject]@{
                    Name      = $svc.DisplayName
                    Status    = $svc.Status
                    StartType = $startMode
                    IsOK      = ($svc.Status -eq "Running")
                }
            } else {
                $results += [PSCustomObject]@{
                    Name      = $service
                    Status    = "Não encontrado"
                    StartType = "N/A"
                    IsOK      = $false
                }
            }
        } catch {
            Write-Error "Erro ao verificar serviço $service : $_"
        }
    }

    return $results
}

# Exportar funções
Export-ModuleMember -Function Get-MemoryUsage, Get-OpenPorts, Get-SystemErrors, Test-CriticalServices
