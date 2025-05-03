function Write-Header {
    Clear-Host
    Write-Host "`n================== SYSBOT v3.1 ==================" -ForegroundColor Cyan
    Write-Host " Manutenção e Otimização do Sistema Windows"
    Write-Host "=================================================" -ForegroundColor Cyan
}

function Pausar {
    Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)
}

# Função: Verificar uso de memória RAM
function Verificar-MemoriaRAM {
    Write-Host "`n[🧠] Verificando uso de memória RAM..." -ForegroundColor Magenta
    try {
        $dados = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($dados.TotalVisibleMemorySize / 1MB, 2)
        $livre = [math]::Round($dados.FreePhysicalMemory / 1MB, 2)
        $uso = [math]::Round($total - $livre, 2)
        $percentual = [math]::Round(($uso / $total) * 100, 2)
        Write-Host " Total: $total GB | Em Uso: $uso GB ($percentual`%)" -ForegroundColor White
    } catch {
        Write-Host " Erro ao verificar memória: $_" -ForegroundColor Red
    }
}

# Função: Verificar e instalar atualizações do Windows
function Verificar-Atualizacoes {
    Write-Host "`n[🔄] Verificando atualizações do Windows..." -ForegroundColor Magenta
    try {
        if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
            Import-Module PSWindowsUpdate
        } else {
            Write-Host " Módulo PSWindowsUpdate não encontrado. Instalando..." -ForegroundColor Yellow
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
            Import-Module PSWindowsUpdate
        }
        Get-WindowsUpdate -AcceptAll -Install -AutoReboot
    } catch {
        Write-Host " Erro ao verificar atualizações: $_" -ForegroundColor Red
    }
}

# Função: Limpeza básica do sistema
function Limpeza-Basica {
    Write-Host "`n[🧹] Executando limpeza básica..." -ForegroundColor Magenta
    try {
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
    } catch {
        Write-Host " Erro ao executar limpeza: $_" -ForegroundColor Red
    }
}

# Função: Otimizar discos fixos
function Otimizacao-Disco {
    Write-Host "`n[💾] Otimizando discos..." -ForegroundColor Magenta
    try {
        Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
            Write-Host " Otimizando unidade $($_.DriveLetter):"
            Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -Verbose
        }
    } catch {
        Write-Host " Erro ao otimizar discos: $_" -ForegroundColor Red
    }
}

# Função: Verificar drivers recentes
function Verificar-Drivers {
    Write-Host "`n[🔍] Verificando drivers desatualizados..." -ForegroundColor Magenta
    try {
        $drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DriverProviderName } | Sort-Object DriverDate -Descending
        $drivers | Select-Object DeviceName, DriverVersion, DriverDate -First 10 | Format-Table -AutoSize
    } catch {
        Write-Host " Erro ao listar drivers: $_" -ForegroundColor Red
    }
}

# Função: Verificar integridade do disco
function Verificar-Disco {
    Write-Host "`n[🧪] Verificando integridade do disco..." -ForegroundColor Magenta
    try {
        Write-Host " Rodando chkdsk no próximo reinício..." -ForegroundColor Yellow
        cmd /c "chkntfs /d"
        cmd /c "chkntfs /c C:"
    } catch {
        Write-Host " Erro ao agendar verificação de disco: $_" -ForegroundColor Red
    }
}

# Função: Gerar relatório completo do sistema
function Criar-Relatorio {
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
        $percentual = [math]::Round(($uso / $total) * 100, 2)
        " Total: $total GB | Em Uso: $uso GB ($percentual`%)" | Out-File $relatorio -Append

        "`n[DRIVERS RECENTES]" | Out-File $relatorio -Append
        Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DriverProviderName } |
                Sort-Object DriverDate -Descending |
                Select-Object DeviceName, DriverVersion, DriverDate -First 10 |
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

# Menu principal
do {
    Write-Header
    Write-Host " Selecione uma opção:" -ForegroundColor Yellow
    Write-Host " [1] Verificar memória RAM"
    Write-Host " [2] Verificar atualizações do Windows"
    Write-Host " [3] Executar limpeza básica"
    Write-Host " [4] Otimizar discos"
    Write-Host " [5] Verificar drivers recentes"
    Write-Host " [6] Verificar disco (chkdsk)"
    Write-Host " [7] Gerar relatório do sistema"
    Write-Host " [0] Sair"
    $opcao = Read-Host "`nDigite o número da opção desejada"

    switch ($opcao) {
        "1" { Verificar-MemoriaRAM; Pausar }
        "2" { Verificar-Atualizacoes; Pausar }
        "3" { Limpeza-Basica; Pausar }
        "4" { Otimizacao-Disco; Pausar }
        "5" { Verificar-Drivers; Pausar }
        "6" { Verificar-Disco; Pausar }
        "7" { Criar-Relatorio; Pausar }
        "0" { Write-Host "`nSaindo do SysBot..." -ForegroundColor Cyan }
        default { Write-Host "`nOpção inválida. Tente novamente." -ForegroundColor Red; Pausar }
    }
} while ($opcao -ne "0")
