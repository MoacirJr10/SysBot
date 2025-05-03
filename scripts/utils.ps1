function Verificar-MemoriaDetalhada {
    Write-Host "`n[🧠] Verificando uso detalhado da memória RAM..." -ForegroundColor Cyan
    try {
        $dados = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($dados.TotalVisibleMemorySize / 1MB, 2)
        $livre = [math]::Round($dados.FreePhysicalMemory / 1MB, 2)
        $uso = $total - $livre
        $percentual = [math]::Round(($uso / $total) * 100, 2)

        Write-Host " ➜ Total: $total GB | Em Uso: $uso GB ($percentual`%) | Livre: $livre GB" -ForegroundColor White
    } catch {
        Write-Host " ❌ Erro ao verificar memória: $_" -ForegroundColor Red
    }
}

# Função para listar as portas abertas
function Verificar-PortasAbertas {
    param (
        [int]$Quantidade = 10
    )
    Write-Host "`n[🌐] Verificando portas abertas (Top $Quantidade)..." -ForegroundColor Cyan
    try {
        $conexoes = @()
        $netstat = netstat -ano | Select-String "ESTABLISHED"

        foreach ($linha in $netstat) {
            $partes = $linha -replace '\s+', ' ' -split ' '
            if ($partes.Length -ge 5) {
                $proc = Get-Process -Id $partes[4] -ErrorAction SilentlyContinue
                $conexoes += [PSCustomObject]@{
                    Protocolo = $partes[0]
                    EndLocal  = $partes[1]
                    EndRemoto = $partes[2]
                    Estado    = $partes[3]
                    PID       = $partes[4]
                    Processo  = if ($proc) { $proc.Name } else { "Desconhecido" }
                }
            }
        }

        $agrupado = $conexoes | Group-Object -Property EndRemoto |
                Sort-Object -Property Count -Descending |
                Select-Object -First $Quantidade -Property Count, Name,
                @{Name="Processo"; Expression={($_.Group[0].Processo)}}

        if ($agrupado) {
            $agrupado | Format-Table -AutoSize
        } else {
            Write-Host " Nenhuma conexão estabelecida encontrada." -ForegroundColor Yellow
        }
    } catch {
        Write-Host " ❌ Erro ao verificar portas: $_" -ForegroundColor Red
    }
}

# Função para buscar erros recentes no sistema
function Verificar-ErrosSistema {
    param (
        [int]$Horas = 24
    )
    Write-Host "`n[🚨] Verificando erros do sistema nas últimas $Horas horas..." -ForegroundColor Cyan
    try {
        $inicio = (Get-Date).AddHours(-$Horas)
        $eventos = Get-WinEvent -FilterHashtable @{
            LogName   = @('System', 'Application')
            Level     = @(1, 2)  # Error e Critical
            StartTime = $inicio
        } -MaxEvents 100 | Where-Object { $_.TimeCreated -ge $inicio }

        if ($eventos) {
            $resumo = $eventos | Group-Object -Property Id, ProviderName |
                    Sort-Object -Property Count -Descending |
                    Select-Object Count,
                    @{Name="ID"; Expression={($_.Name -split ',')[0]}},
                    @{Name="Fonte"; Expression={($_.Name -split ',')[1]}},
                    @{Name="Mensagem"; Expression={($_.Group[0].Message -split "`n")[0]}}

            $resumo | Format-Table -AutoSize
        } else {
            Write-Host " ✅ Nenhum erro crítico encontrado nas últimas $Horas horas." -ForegroundColor Green
        }
    } catch {
        Write-Host " ❌ Erro ao buscar eventos do sistema: $_" -ForegroundColor Red
    }
}

# Função para checar serviços críticos
function Verificar-ServicosCriticos {
    Write-Host "`n[🔒] Verificando serviços críticos do sistema..." -ForegroundColor Cyan
    $servicosCriticos = @(
        "wuauserv",   # Windows Update
        "WinDefend",  # Windows Defender
        "wscsvc",     # Security Center
        "Dhcp",       # DHCP Client
        "Dnscache",   # DNS Client
        "EventLog",   # Event Log
        "MpsSvc"      # Windows Firewall
    )

    foreach ($servico in $servicosCriticos) {
        try {
            $svc = Get-Service -Name $servico -ErrorAction SilentlyContinue

            if ($svc) {
                $cim = Get-CimInstance -ClassName Win32_Service -Filter "Name='$servico'" -ErrorAction SilentlyContinue
                $modo = if ($cim) { $cim.StartMode } else { "Desconhecido" }
                $statusOK = ($svc.Status -eq "Running")
                $cor = if ($statusOK) { "Green" } else { "Red" }

                Write-Host " ➜ $($svc.DisplayName): $($svc.Status) (Início: $modo)" -ForegroundColor $cor
            } else {
                Write-Host " ❌ $servico: Não encontrado!" -ForegroundColor Red
            }
        } catch {
            Write-Host " ❌ Erro ao verificar serviço $servico: $_" -ForegroundColor Red
        }
    }
}

# Exportar funções
Export-ModuleMember -Function Verificar-MemoriaDetalhada, Verificar-PortasAbertas, Verificar-ErrosSistema, Verificar-ServicosCriticos
