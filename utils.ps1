# utils.ps1 - Módulo de funções para SYSBOT v3.1

function Write-Header {
    Clear-Host
    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "             ███████╗██╗   ██╗███████╗             " -ForegroundColor Cyan
    Write-Host "             ██╔════╝██║   ██║██╔════╝             " -ForegroundColor Cyan
    Write-Host "             █████╗  ██║   ██║█████╗               " -ForegroundColor Cyan
    Write-Host "             ██╔══╝  ██║   ██║██╔══╝               " -ForegroundColor Cyan
    Write-Host "             ██║     ╚██████╔╝███████╗             " -ForegroundColor Cyan
    Write-Host "             ╚═╝      ╚═════╝ ╚══════╝             " -ForegroundColor Cyan
    Write-Host "                  SYSBOT v3.1 TECH TOOL            " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Cyan
}

function Pausar {
    Write-Host "`n>> Pressione qualquer tecla para continuar..." -ForegroundColor Yellow
    [void][System.Console]::ReadKey($true)
}

function Verificar-MemoriaRAM {
    Write-Host "`n[🧠] Verificando uso de memória RAM..." -ForegroundColor Magenta
    try {
        $dados = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($dados.TotalVisibleMemorySize / 1MB, 2)
        $livre = [math]::Round($dados.FreePhysicalMemory / 1MB, 2)
        $uso = [math]::Round($total - $livre, 2)
        $percentual = if ($total -ne 0) { [math]::Round(($uso / $total) * 100, 2) } else { 0 }
        Write-Host "`n🧠 Total: $total GB | Em Uso: $uso GB ($percentual`%)" -ForegroundColor White
    } catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Verificar-Atualizacoes {
    Write-Host "`n[🔄] Verificando atualizações do Windows..." -ForegroundColor Magenta
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host " Instalando módulo PSWindowsUpdate..." -ForegroundColor Yellow
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -AllowClobber
        }
        Import-Module PSWindowsUpdate -Force
        Get-WindowsUpdate -AcceptAll -Install -AutoReboot
    } catch {
        Write-Host "Erro ao verificar atualizações: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Limpeza-Basica {
    Write-Host "`n[🧹] Executando limpeza básica..." -ForegroundColor Magenta
    try {
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
    } catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Otimizacao-Disco {
    Write-Host "`n[💾] Otimizando discos..." -ForegroundColor Magenta
    try {
        Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
            Write-Host " Otimizando unidade $($_.DriveLetter):" -ForegroundColor Cyan
            Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -Verbose
        }
    } catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Verificar-Drivers {
    Write-Host "`n[🔍] Verificando drivers desatualizados..." -ForegroundColor Magenta
    try {
        Get-WmiObject Win32_PnPSignedDriver |
                Where-Object { $_.DriverProviderName -and $_.DriverDate } |
                Sort-Object DriverDate -Descending |
                Select-Object -First 10 DeviceName, DriverVersion, @{Name='Data';Expression={ $_.DriverDate.ToShortDateString() }} |
                Format-Table -AutoSize
    } catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Verificar-Disco {
    Write-Host "`n[🧪] Agendando verificação de disco (CHKDSK)..." -ForegroundColor Magenta
    try {
        cmd /c "chkntfs /d" | Out-Null
        cmd /c "chkntfs /c C:" | Out-Null
        Write-Host " Verificação agendada para o próximo reinício." -ForegroundColor Yellow
    } catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Criar-Relatorio {
    Write-Host "`n[📄] Gerando relatório do sistema..." -ForegroundColor Magenta
    try {
        $data = Get-Date -Format "yyyy-MM-dd_HH-mm"
        $relatorio = "C:\SysBot-Relatorio_$data.txt"

        @"
===== RELATÓRIO SYSBOT v3.1 =====
Data: $(Get-Date)
Usuário: $env:USERNAME
Sistema: $((Get-CimInstance Win32_OperatingSystem).Caption)

[MEMÓRIA RAM]
"@ | Out-File $relatorio -Encoding UTF8

        $dados = Get-CimInstance Win32_OperatingSystem
        $total = [math]::Round($dados.TotalVisibleMemorySize / 1MB, 2)
        $livre = [math]::Round($dados.FreePhysicalMemory / 1MB, 2)
        $uso = [math]::Round($total - $livre, 2)
        $percentual = [math]::Round(($uso / $total) * 100, 2)
        "Total: $total GB | Em Uso: $uso GB ($percentual`%)" | Out-File $relatorio -Append -Encoding UTF8

        "`n[DRIVERS RECENTES]" | Out-File $relatorio -Append -Encoding UTF8
        Get-WmiObject Win32_PnPSignedDriver |
                Where-Object { $_.DriverProviderName -and $_.DriverDate } |
                Sort-Object DriverDate -Descending |
                Select-Object -First 10 DeviceName, DriverVersion, @{Name='Data';Expression={ $_.DriverDate.ToShortDateString() }} |
                Format-Table -AutoSize | Out-String | Out-File $relatorio -Append -Encoding UTF8

        "`n[UNIDADES DE DISCO]" | Out-File $relatorio -Append -Encoding UTF8
        Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
            "Unidade $($_.DriveLetter): $($_.FileSystemLabel) - Livre: $([math]::Round($_.SizeRemaining / 1GB, 2)) GB" |
                    Out-File $relatorio -Append -Encoding UTF8
        }

        Write-Host "`n✅ Relatório salvo em: $relatorio" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao gerar relatório: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Export-ModuleMember -Function `
    Write-Header, Pausar, Verificar-MemoriaRAM, Verificar-Atualizacoes, `
    Limpeza-Basica, Otimizacao-Disco, Verificar-Drivers, Verificar-Disco, Criar-Relatorio
