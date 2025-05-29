# utils.ps1 - Módulo de funções para SYSBOT v3.1

# Cabeçalho
function Write-Header {
    Clear-Host
    Write-Host "`n================== SYSBOT v3.1 ==================" -ForegroundColor Cyan
    Write-Host " Manutenção e Otimização do Sistema Windows"
    Write-Host "=================================================" -ForegroundColor Cyan
}

# Pausa
function Pausar {
    Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)
}

# Memória RAM
function Verificar-MemoriaRAM {
    Write-Host "`n[🧠] Verificando uso de memória RAM..." -ForegroundColor Magenta
    try {
        $dados = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($dados.TotalVisibleMemorySize / 1MB, 2)
        $livre = [math]::Round($dados.FreePhysicalMemory / 1MB, 2)
        $uso = [math]::Round($total - $livre, 2)
        $percentual = if ($total -ne 0) { [math]::Round(($uso / $total) * 100, 2) } else { 0 }
        Write-Host " Total: $total GB | Em Uso: $uso GB ($percentual`%)" -ForegroundColor White
    } catch {
        Write-Host " Erro ao verificar memória: $_" -ForegroundColor Red
    }
}

# Atualizações do Windows
function Verificar-Atualizacoes {
    Write-Host "`n[🔄] Verificando atualizações do Windows..." -ForegroundColor Magenta
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host " Instalando módulo PSWindowsUpdate..." -ForegroundColor Yellow
            # Permitir instalação silenciosa sem prompt (execução como admin requerida)
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -AllowClobber
        }
        Import-Module PSWindowsUpdate -Force
        # Buscar, aceitar e instalar atualizações automaticamente
        Get-WindowsUpdate -AcceptAll -Install -AutoReboot
    } catch {
        Write-Host " Erro ao verificar atualizações: $_" -ForegroundColor Red
    }
}

# Limpeza do sistema
function Limpeza-Basica {
    Write-Host "`n[🧹] Executando limpeza básica..." -ForegroundColor Magenta
    try {
        # Use parâmetro /sagerun:1, é preciso configurar previamente cleanmgr /sageset:1 manualmente
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
    } catch {
        Write-Host " Erro ao executar limpeza: $_" -ForegroundColor Red
    }
}

# Otimização de disco
function Otimizacao-Disco {
    Write-Host "`n[💾] Otimizando discos..." -ForegroundColor Magenta
    try {
        Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
            Write-Host " Otimizando unidade $($_.DriveLetter):" -ForegroundColor Cyan
            Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -Verbose
        }
    } catch {
        Write-Host " Erro ao otimizar discos: $_" -ForegroundColor Red
    }
}

# Verificação de drivers
function Verificar-Drivers {
    Write-Host "`n[🔍] Verificando drivers desatualizados..." -ForegroundColor Magenta
    try {
        Get-WmiObject Win32_PnPSignedDriver |
                Where-Object { $_.DriverProviderName -and $_.DriverDate } |
                Sort-Object DriverDate -Descending |
                Select-Object -First 10 DeviceName, DriverVersion, @{Name='DriverDate';Expression={$_.DriverDate.ToShortDateString()}} |
                Format-Table -AutoSize
    } catch {
        Write-Host " Erro ao listar drivers: $_" -ForegroundColor Red
    }
}

# Verificação de disco (agendada)
function Verificar-Disco {
    Write-Host "`n[🧪] Verificando integridade do disco..." -ForegroundColor Magenta
    try {
        Write-Host " Rodando chkdsk no próximo reinício..." -ForegroundColor Yellow
        # Reseta agendamento para chkdsk
        cmd /c "chkntfs /d" | Out-Null
        # Agenda para verificar drive C: no próximo boot
        cmd /c "chkntfs /c C:" | Out-Null
    } catch {
        Write-Host " Erro ao agendar verificação de disco: $_" -ForegroundColor Red
    }
}

# Geração de relatório
function Criar-Relatorio {
    Write-Host "`n[📄] Gerando relatório do sistema..." -ForegroundColor Magenta
    try {
        $data = Get-Date -Format "yyyy-MM-dd_HH-mm"
        $relatorio = "C:\SysBot-Relatorio_$data.txt"

        "==== RELATÓRIO SYSBOT v3.1 ====" | Out-File $relatorio
        "Data: $(Get-Date)" | Out-File $relatorio -Append
        "Usuário: $env:USERNAME" | Out-File $relatorio -Append
        "Sistema: $((Get-CimInstance Win32_OperatingSystem).Caption)" | Out-File $relatorio -Append

        "`n[MEMÓRIA RAM]" | Out-File $relatorio -Append
        $dados = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($dados.TotalVisibleMemorySize / 1MB, 2)
        $livre = [math]::Round($dados.FreePhysicalMemory / 1MB, 2)
        $uso = [math]::Round($total - $livre, 2)
        $percentual = if ($total -ne 0) { [math]::Round(($uso / $total) * 100, 2) } else { 0 }
        " Total: $total GB | Em Uso: $uso GB ($percentual`%)" | Out-File $relatorio -Append

        "`n[DRIVERS RECENTES]" | Out-File $relatorio -Append
        Get-WmiObject Win32_PnPSignedDriver |
                Where-Object { $_.DriverProviderName -and $_.DriverDate } |
                Sort-Object DriverDate -Descending |
                Select-Object -First 10 DeviceName, DriverVersion, @{Name='DriverDate';Expression={$_.DriverDate.ToShortDateString()}} |
                Format-Table -AutoSize | Out-String | Out-File $relatorio -Append

        "`n[DISCOS]" | Out-File $relatorio -Append
        Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
            " Unidade $($_.DriveLetter): $($_.FileSystemLabel) - Espaço livre: $([math]::Round($_.SizeRemaining / 1GB, 2)) GB" | Out-File $relatorio -Append
        }

        Write-Host "`n📄 Relatório gerado em: $relatorio" -ForegroundColor Green
    } catch {
        Write-Host " Erro ao gerar relatório: $_" -ForegroundColor Red
    }
}

# Exportações de funções públicas
Export-ModuleMember -Function `
    Write-Header, Pausar, Verificar-MemoriaRAM, Verificar-Atualizacoes, `
    Limpeza-Basica, Otimizacao-Disco, Verificar-Drivers, Verificar-Disco, Criar-Relatorio
