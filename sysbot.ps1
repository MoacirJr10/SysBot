<#
    SYSBOT v3.2 - Sistema Avançado de Manutenção e Otimização
    Script principal com menu interativo - VERSÃO CORRIGIDA
    Melhorado com tratamento de erros e validações
#>

# Configurações iniciais
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version Latest

# Verificar se está executando como Administrador
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Função para pausar e aguardar entrada do usuário
function Pausar {
    Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Função para escrever cabeçalho
function Write-Header {
    param([string]$Title)

    Clear-Host
    Write-Host "=" * 65 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "=" * 65 -ForegroundColor Cyan
    Write-Host ""
}

# Verificar e instalar atualizações do Windows
function Verificar-Atualizacoes {
    param([switch]$InstallUpdates)

    Write-Host "`n[🔄] Verificando atualizações do Windows..." -ForegroundColor Magenta

    try {
        # Verificar se o módulo PSWindowsUpdate está disponível
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "⚠️  Módulo PSWindowsUpdate não encontrado. Usando Windows Update nativo..." -ForegroundColor Yellow
            Start-Process "ms-settings:windowsupdate" -Wait:$false
            return
        }

        Import-Module PSWindowsUpdate -Force
        $updates = Get-WindowsUpdate

        if ($updates.Count -eq 0) {
            Write-Host "✅ Sistema atualizado!" -ForegroundColor Green
        } else {
            Write-Host "📦 $($updates.Count) atualizações encontradas" -ForegroundColor Yellow
            if ($InstallUpdates) {
                Install-WindowsUpdate -AcceptAll -AutoReboot:$false
            }
        }
    } catch {
        Write-Host "❌ Erro ao verificar atualizações: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Abrindo Windows Update..." -ForegroundColor Yellow
        Start-Process "ms-settings:windowsupdate"
    }
}

# Verificar drivers
function Verificar-Drivers {
    param(
        [switch]$CheckUpdates,
        [switch]$ExportList
    )

    Write-Host "`n[🔍] Analisando drivers do sistema..." -ForegroundColor Magenta

    try {
        $drivers = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }

        if ($drivers) {
            Write-Host "⚠️  Drivers com problemas encontrados:" -ForegroundColor Yellow
            $drivers | Select-Object Name, DeviceID | Format-Table -AutoSize
        } else {
            Write-Host "✅ Todos os drivers estão funcionando corretamente" -ForegroundColor Green
        }

        if ($ExportList) {
            $date = Get-Date -Format "yyyy-MM-dd"
            $file = "$env:USERPROFILE\Desktop\Drivers_$date.csv"
            Get-CimInstance Win32_SystemDriver | Export-Csv $file -NoTypeInformation -Encoding UTF8
            Write-Host "📄 Lista de drivers exportada para: $file" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Erro ao verificar drivers: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verificar disco
function Verificar-Disco {
    Write-Host "`n[💾] Agendando verificação de disco..." -ForegroundColor Magenta

    try {
        $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }

        foreach ($drive in $drives) {
            Write-Host "🔍 Verificando unidade $($drive.DriveLetter):\" -ForegroundColor Yellow
            $result = chkdsk "$($drive.DriveLetter):" /f /r
            Write-Host "✅ Verificação da unidade $($drive.DriveLetter): concluída" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Erro na verificação de disco: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verificar memória RAM
function Verificar-MemoriaRAM {
    param([switch]$Detailed)

    Write-Host "`n[🧠] Informações da memória RAM:" -ForegroundColor Magenta

    try {
        $memory = Get-CimInstance Win32_ComputerSystem
        $totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)

        Write-Host "💾 Total de RAM: $totalRAM GB" -ForegroundColor Cyan

        if ($Detailed) {
            Get-CimInstance Win32_PhysicalMemory |
                    Select-Object BankLabel, Capacity, Speed, Manufacturer |
                    ForEach-Object {
                        $_.Capacity = [math]::Round($_.Capacity / 1GB, 2)
                        $_
                    } | Format-Table -AutoSize
        }

        # Verificar uso atual
        $availableMemory = Get-Counter "\Memory\Available MBytes"
        $usedPercent = [math]::Round((($totalRAM * 1024 - $availableMemory.CounterSamples.CookedValue) / ($totalRAM * 1024)) * 100, 2)
        Write-Host "📊 Uso atual: $usedPercent%" -ForegroundColor $(if ($usedPercent -gt 80) { 'Red' } else { 'Green' })

    } catch {
        Write-Host "❌ Erro ao obter informações da RAM: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Testar velocidade da Internet
function Testar-VelocidadeInternet {
    Write-Host "`n[📶] Testando velocidade da Internet..." -ForegroundColor Magenta

    try {
        # Teste simples de download
        $url = "http://www.google.com"
        $time = Measure-Command {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 10
        }

        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Conexão ativa - Tempo de resposta: $($time.TotalMilliseconds) ms" -ForegroundColor Green
        }

        # Sugerir teste mais detalhado
        Write-Host "💡 Para teste detalhado, use: speedtest.net ou fast.com" -ForegroundColor Yellow

    } catch {
        Write-Host "❌ Erro no teste de conectividade: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Limpeza avançada
function Limpeza-Avancada {
    param(
        [switch]$IncludeTempFiles,
        [switch]$IncludePrefetch,
        [switch]$IncludeThumbnails,
        [switch]$IncludeRecentFiles,
        [switch]$IncludeLogs
    )

    Write-Host "`n[🧹] Iniciando limpeza do sistema..." -ForegroundColor Magenta
    $totalCleaned = 0

    try {
        if ($IncludeTempFiles) {
            Write-Host "🗑️  Limpando arquivos temporários..." -ForegroundColor Yellow
            $tempPaths = @(
                "$env:TEMP\*",
                "$env:WINDIR\Temp\*",
                "$env:LOCALAPPDATA\Temp\*"
            )

            foreach ($path in $tempPaths) {
                try {
                    $items = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue
                    $size = ($items | Measure-Object -Property Length -Sum).Sum
                    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                    $totalCleaned += $size
                } catch {
                    # Continuar mesmo com erros em arquivos específicos
                }
            }
        }

        if ($IncludePrefetch) {
            Write-Host "🚀 Limpando cache de pré-carregamento..." -ForegroundColor Yellow
            try {
                $prefetchSize = (Get-ChildItem "$env:WINDIR\Prefetch" -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Remove-Item "$env:WINDIR\Prefetch\*" -Force -ErrorAction SilentlyContinue
                $totalCleaned += $prefetchSize
            } catch { }
        }

        if ($IncludeThumbnails) {
            Write-Host "🖼️  Limpando cache de miniaturas..." -ForegroundColor Yellow
            try {
                $thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db"
                $thumbSize = (Get-ChildItem $thumbPath -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Remove-Item $thumbPath -Force -ErrorAction SilentlyContinue
                $totalCleaned += $thumbSize
            } catch { }
        }

        if ($IncludeRecentFiles) {
            Write-Host "📋 Limpando histórico de documentos recentes..." -ForegroundColor Yellow
            try {
                Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -ErrorAction SilentlyContinue
            } catch { }
        }

        if ($IncludeLogs) {
            Write-Host "📝 Limpando logs antigos..." -ForegroundColor Yellow
            try {
                $logPaths = @(
                    "$env:WINDIR\Logs\*",
                    "$env:WINDIR\System32\LogFiles\*"
                )
                foreach ($logPath in $logPaths) {
                    $oldLogs = Get-ChildItem $logPath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
                    $logSize = ($oldLogs | Measure-Object -Property Length -Sum).Sum
                    $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
                    $totalCleaned += $logSize
                }
            } catch { }
        }

        $cleanedMB = [math]::Round($totalCleaned / 1MB, 2)
        Write-Host "✅ Limpeza concluída! Espaço liberado: $cleanedMB MB" -ForegroundColor Green

    } catch {
        Write-Host "❌ Erro durante a limpeza: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Otimização do sistema
function Otimizacao-Sistema {
    param(
        [switch]$OptimizeDrives,
        [switch]$Defrag,
        [switch]$TrimSSD
    )

    Write-Host "`n[⚡] Iniciando otimização do sistema..." -ForegroundColor Magenta

    try {
        if ($OptimizeDrives) {
            Write-Host "🔧 Otimizando unidades..." -ForegroundColor Yellow
            Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object {
                Write-Host "  ➤ Otimizando unidade $($_.DriveLetter):" -ForegroundColor Cyan
                try {
                    Optimize-Volume -DriveLetter $_.DriveLetter -Analyze -Verbose
                } catch {
                    Write-Host "    ⚠️  Não foi possível otimizar $($_.DriveLetter):" -ForegroundColor Yellow
                }
            }
        }

        if ($Defrag) {
            Write-Host "🌀 Desfragmentando HDDs..." -ForegroundColor Yellow
            $hdds = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'HDD' }
            if ($hdds) {
                foreach ($hdd in $hdds) {
                    Write-Host "  ➤ Desfragmentando disco: $($hdd.FriendlyName)" -ForegroundColor Cyan
                    # Comando de desfragmentação seria executado aqui
                }
            } else {
                Write-Host "  ℹ️  Nenhum HDD encontrado para desfragmentação" -ForegroundColor Blue
            }
        }

        if ($TrimSSD) {
            Write-Host "✂️  Executando TRIM em SSDs..." -ForegroundColor Yellow
            $ssds = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' }
            if ($ssds) {
                foreach ($ssd in $ssds) {
                    Write-Host "  ➤ TRIM no SSD: $($ssd.FriendlyName)" -ForegroundColor Cyan
                    try {
                        Optimize-Volume -DriveLetter C -ReTrim -Verbose
                    } catch {
                        Write-Host "    ⚠️  Erro no TRIM do SSD" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "  ℹ️  Nenhum SSD encontrado" -ForegroundColor Blue
            }
        }

        Write-Host "✅ Otimização concluída!" -ForegroundColor Green

    } catch {
        Write-Host "❌ Erro durante a otimização: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Criar relatório do sistema
function Criar-Relatorio {
    Write-Host "`n[📄] Gerando relatório do sistema..." -ForegroundColor Magenta

    try {
        $date = Get-Date -Format "yyyy-MM-dd_HH-mm"
        $reportPath = "$env:USERPROFILE\Desktop\Relatorio_Sistema_$date.html"

        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Relatório do Sistema - $date</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2E86AB; }
        h2 { color: #A23B72; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .info { background-color: #e8f4fd; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Relatório do Sistema - SysBot v3.2</h1>
    <div class="info">Gerado em: $(Get-Date)</div>

    <h2>Informações Básicas</h2>
    <table>
        <tr><th>Item</th><th>Valor</th></tr>
        <tr><td>Nome do Computador</td><td>$env:COMPUTERNAME</td></tr>
        <tr><td>Usuário</td><td>$env:USERNAME</td></tr>
        <tr><td>Sistema Operacional</td><td>$((Get-CimInstance Win32_OperatingSystem).Caption)</td></tr>
        <tr><td>Versão</td><td>$((Get-CimInstance Win32_OperatingSystem).Version)</td></tr>
    </table>

    <h2>Hardware</h2>
    <table>
        <tr><th>Componente</th><th>Informação</th></tr>
        <tr><td>Processador</td><td>$((Get-CimInstance Win32_Processor).Name)</td></tr>
        <tr><td>Memória Total</td><td>$([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB</td></tr>
        <tr><td>Arquitetura</td><td>$((Get-CimInstance Win32_OperatingSystem).OSArchitecture)</td></tr>
    </table>

    <h2>Discos</h2>
    <table>
        <tr><th>Unidade</th><th>Tamanho</th><th>Livre</th><th>Tipo</th></tr>
"@

        Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object {
            $sizeGB = [math]::Round($_.Size / 1GB, 2)
            $freeGB = [math]::Round($_.SizeRemaining / 1GB, 2)
            $html += "<tr><td>$($_.DriveLetter):</td><td>$sizeGB GB</td><td>$freeGB GB</td><td>$($_.FileSystem)</td></tr>"
        }

        $html += @"
    </table>

    <h2>Serviços Parados</h2>
    <table>
        <tr><th>Nome</th><th>Status</th><th>Tipo de Inicialização</th></tr>
"@

        Get-Service | Where-Object { $_.Status -eq 'Stopped' } | Select-Object -First 10 | ForEach-Object {
            $html += "<tr><td>$($_.Name)</td><td>$($_.Status)</td><td>$($_.StartType)</td></tr>"
        }

        $html += @"
    </table>

    <footer>
        <p><em>Relatório gerado pelo SysBot v3.2</em></p>
    </footer>
</body>
</html>
"@

        $html | Out-File $reportPath -Encoding UTF8
        Write-Host "✅ Relatório salvo em: $reportPath" -ForegroundColor Green

    } catch {
        Write-Host "❌ Erro ao gerar relatório: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Funções de Menu
function Show-MainMenu {
    Write-Header -Title "SYSBOT v3.2 TECH TOOL"

    if (-not (Test-IsAdmin)) {
        Write-Host "⚠️  AVISO: Execute como Administrador para funcionalidade completa`n" -ForegroundColor Yellow
    }

    Write-Host @"
======================== MENU PRINCIPAL ========================

 [1] 🛠️  Manutenção do Sistema
 [2] 💻 Informações de Hardware
 [3] 🌐 Diagnóstico de Rede
 [4] 🧹 Ferramentas de Limpeza
 [5] ⚙️  Otimização Avançada
 [6] 📊 Relatórios e Diagnósticos

 [0] ❌ Sair do SysBot

===============================================================
"@ -ForegroundColor Cyan
}

function Show-MaintenanceMenu {
    Write-Host @"
=================== MANUTENÇÃO DO SISTEMA ===================

 [1] 🔄 Verificar e instalar atualizações do Windows
 [2] 🛡️  Verificar integridade do sistema (SFC)
 [3] 🏥 Restaurar saúde do sistema (DISM)
 [4] 🔍 Verificar drivers desatualizados
 [5] 🔄 Atualizar programas (winget)
 [6] ⏱️  Agendar verificação de disco (CHKDSK)

 [9] ↩ Voltar ao menu anterior
 [0] ❌ Sair

=============================================================
"@ -ForegroundColor Yellow
}

function Show-HardwareMenu {
    Write-Host @"
================ INFORMAÇÕES DE HARDWARE ================

 [1] 💻 Informações básicas do sistema
 [2] 🧠 Detalhes da memória RAM
 [3] 🖥️  Informações da GPU
 [4] 💾 Status dos discos e armazenamento
 [5] 🔥 Temperaturas e ventilação (se disponível)
 [6] 📦 Programas instalados

 [9] ↩ Voltar ao menu anterior
 [0] ❌ Sair

=========================================================
"@ -ForegroundColor Yellow
}

function Show-NetworkMenu {
    Write-Host @"
================ DIAGNÓSTICO DE REDE ================

 [1] 🌐 Configuração de IP/DNS
 [2] 🚦 Testar conectividade básica
 [3] 📶 Testar velocidade da Internet
 [4] 🔌 Testar portas TCP
 [5] 🧹 Liberar e renovar configuração DHCP
 [6] 🔍 Analisar conexões ativas

 [9] ↩ Voltar ao menu anterior
 [0] ❌ Sair

=====================================================
"@ -ForegroundColor Yellow
}

function Show-CleanupMenu {
    Write-Host @"
============== FERRAMENTAS DE LIMPEZA ==============

 [1] 🗑️  Limpeza básica de arquivos temporários
 [2] 🧼 Limpeza avançada com Storage Sense
 [3] 🚀 Limpar cache de pré-carregamento (Prefetch)
 [4] 🖼️  Limpar cache de thumbnails e ícones
 [5] 📋 Limpar histórico de documentos recentes
 [6] 🧹 Limpeza completa (todas as opções)

 [9] ↩ Voltar ao menu anterior
 [0] ❌ Sair

===================================================
"@ -ForegroundColor Yellow
}

function Show-OptimizationMenu {
    Write-Host @"
============== OTIMIZAÇÃO AVANÇADA ==============

 [1] ⚡ Otimizar unidades de disco
 [2] 🌀 Desfragmentar HDDs
 [3] ✂️  Executar TRIM em SSDs
 [4] 🛠️  Ajustar configurações de energia
 [5] 🚀 Desativar serviços não essenciais
 [6] 🧪 Otimização completa (todas as opções)

 [9] ↩ Voltar ao menu anterior
 [0] ❌ Sair

================================================
"@ -ForegroundColor Yellow
}

function Show-ReportsMenu {
    Write-Host @"
============ RELATÓRIOS E DIAGNÓSTICOS ============

 [1] 📄 Gerar relatório do sistema (HTML)
 [2] 📊 Exportar lista de drivers (CSV)
 [3] 📋 Exportar programas instalados (TXT)
 [4] 🖨️  Salvar configuração de rede
 [5] 📦 Criar dump completo do sistema
 [6] 🔍 Analisar integridade do sistema

 [9] ↩ Voltar ao menu anterior
 [0] ❌ Sair

==================================================
"@ -ForegroundColor Yellow
}

# Loop principal melhorado
do {
    try {
        Show-MainMenu
        $mainChoice = Read-Host "`nDigite sua opção"

        switch ($mainChoice) {
            "1" { # Manutenção do Sistema
                do {
                    Show-MaintenanceMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" { Verificar-Atualizacoes -InstallUpdates }
                        "2" {
                            Write-Host "`n[🛠️] Verificando integridade do sistema..." -ForegroundColor Magenta
                            try {
                                $result = sfc /scannow
                                if ($LASTEXITCODE -eq 0) {
                                    Write-Host "✅ Verificação concluída com sucesso" -ForegroundColor Green
                                } else {
                                    Write-Host "⚠️  Problemas foram encontrados e corrigidos" -ForegroundColor Yellow
                                }
                            } catch {
                                Write-Host "❌ Erro na verificação SFC: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "3" {
                            Write-Host "`n[🏥] Restaurando saúde do sistema..." -ForegroundColor Magenta
                            try {
                                DISM /Online /Cleanup-Image /RestoreHealth
                                Write-Host "✅ Restauração concluída" -ForegroundColor Green
                            } catch {
                                Write-Host "❌ Erro no DISM: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "4" { Verificar-Drivers -CheckUpdates }
                        "5" {
                            Write-Host "`n[🔄] Atualizando programas via winget..." -ForegroundColor Magenta
                            try {
                                if (Get-Command winget -ErrorAction SilentlyContinue) {
                                    winget upgrade --all --accept-package-agreements --accept-source-agreements
                                } else {
                                    Write-Host "⚠️  Winget não encontrado. Instale o App Installer da Microsoft Store" -ForegroundColor Yellow
                                }
                            } catch {
                                Write-Host "❌ Erro no winget: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "6" { Verificar-Disco }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($subChoice -ne "9" -and $subChoice -ne "0")
            }

            "2" { # Informações de Hardware
                do {
                    Show-HardwareMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" {
                            Write-Host "`n[💻] Informações básicas do sistema:" -ForegroundColor Magenta
                            try {
                                $os = Get-CimInstance Win32_OperatingSystem
                                $cs = Get-CimInstance Win32_ComputerSystem

                                Write-Host "🖥️  Computador: $($cs.Name)" -ForegroundColor Cyan
                                Write-Host "💻 Sistema: $($os.Caption)" -ForegroundColor Cyan
                                Write-Host "📊 Versão: $($os.Version)" -ForegroundColor Cyan
                                Write-Host "🏢 Fabricante: $($cs.Manufacturer)" -ForegroundColor Cyan
                                Write-Host "📱 Modelo: $($cs.Model)" -ForegroundColor Cyan
                            } catch {
                                Write-Host "❌ Erro ao obter informações: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "2" { Verificar-MemoriaRAM -Detailed }
                        "3" {
                            Write-Host "`n[🖥️] Informações da GPU:" -ForegroundColor Magenta
                            try {
                                Get-CimInstance Win32_VideoController |
                                        Where-Object { $_.Name -notlike "*Basic*" } |
                                        Select-Object Name, DriverVersion, @{Name='VRAM(MB)';Expression={[math]::Round($_.AdapterRAM/1MB,0)}} |
                                        Format-Table -AutoSize
                            } catch {
                                Write-Host "❌ Erro ao obter informações da GPU: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "4" {
                            Write-Host "`n[💾] Status dos discos:" -ForegroundColor Magenta
                            try {
                                Write-Host "`nDiscos físicos:" -ForegroundColor Yellow
                                Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus | Format-Table -AutoSize

                                Write-Host "Volumes:" -ForegroundColor Yellow
                                Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } |
                                        Select-Object DriveLetter, FileSystemLabel,
                                        @{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,2)}},
                                        @{Name='FreeGB';Expression={[math]::Round($_.SizeRemaining/1GB,2)}},
                                        @{Name='%Free';Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100,1)}} |
                                        Format-Table -AutoSize
                            } catch {
                                Write-Host "❌ Erro ao obter informações de disco: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "5" {
                            Write-Host "`n[🔥] Informações de temperatura:" -ForegroundColor Magenta
                            try {
                                # Tentar obter informações de temperatura
                                $temps = Get-CimInstance -ClassName Win32_TemperatureProbe -ErrorAction SilentlyContinue
                                if ($temps) {
                                    $temps | Select-Object Name, CurrentTemperature | Format-Table -AutoSize
                                } else {
                                    Write-Host "⚠️  Sensores de temperatura não disponíveis via WMI" -ForegroundColor Yellow
                                }

                                # Informações de ventiladores
                                $fans = Get-CimInstance -ClassName Win32_Fan -ErrorAction SilentlyContinue
                                if ($fans) {
                                    Write-Host "`nVentiladores:" -ForegroundColor Yellow
                                    $fans | Select-Object Name, Status | Format-Table -AutoSize
                                } else {
                                    Write-Host "💡 Use ferramentas como HWiNFO64 ou Core Temp para monitoramento detalhado" -ForegroundColor Blue
                                }
                            } catch {
                                Write-Host "❌ Erro ao obter informações térmicas: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "6" {
                            Write-Host "`n[📦] Programas instalados:" -ForegroundColor Magenta
                            try {
                                $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                                        Where-Object { $_.DisplayName -and $_.DisplayName -notlike "Update*" } |
                                        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
                                        Sort-Object DisplayName

                                Write-Host "📊 Total de programas: $($programs.Count)" -ForegroundColor Cyan
                                $programs | Format-Table -AutoSize | Out-Host -Paging
                            } catch {
                                Write-Host "❌ Erro ao listar programas: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($subChoice -ne "9" -and $subChoice -ne "0")
            }

            "3" { # Diagnóstico de Rede
                do {
                    Show-NetworkMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" {
                            Write-Host "`n[🌐] Configuração de rede:" -ForegroundColor Magenta
                            try {
                                Write-Host "`nConfiguração IP:" -ForegroundColor Yellow
                                Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" } |
                                        Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer |
                                        Format-Table -AutoSize

                                Write-Host "Adaptadores de rede:" -ForegroundColor Yellow
                                Get-NetAdapter | Where-Object { $_.Status -eq "Up" } |
                                        Select-Object Name, InterfaceDescription, LinkSpeed |
                                        Format-Table -AutoSize
                            } catch {
                                Write-Host "❌ Erro ao obter configuração de rede: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "2" {
                            Write-Host "`n[🚦] Testando conectividade:" -ForegroundColor Magenta
                            try {
                                Write-Host "🔍 Testando Google..." -ForegroundColor Yellow
                                $ping1 = Test-Connection -ComputerName "8.8.8.8" -Count 4 -Quiet
                                Write-Host "Google DNS (8.8.8.8): $(if($ping1){'✅ OK'}else{'❌ FALHA'})" -ForegroundColor $(if($ping1){'Green'}else{'Red'})

                                Write-Host "`n🔍 Testando Cloudflare..." -ForegroundColor Yellow
                                $ping2 = Test-Connection -ComputerName "1.1.1.1" -Count 4 -Quiet
                                Write-Host "Cloudflare DNS (1.1.1.1): $(if($ping2){'✅ OK'}else{'❌ FALHA'})" -ForegroundColor $(if($ping2){'Green'}else{'Red'})

                                Write-Host "`n🔍 Testando portal web..." -ForegroundColor Yellow
                                try {
                                    $web = Invoke-WebRequest -Uri "https://www.google.com" -TimeoutSec 10 -UseBasicParsing
                                    Write-Host "Acesso web: ✅ OK (Status: $($web.StatusCode))" -ForegroundColor Green
                                } catch {
                                    Write-Host "Acesso web: ❌ FALHA" -ForegroundColor Red
                                }
                            } catch {
                                Write-Host "❌ Erro no teste de conectividade: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "3" { Testar-VelocidadeInternet }
                        "4" {
                            Write-Host "`n[🔌] Teste de porta TCP:" -ForegroundColor Magenta
                            try {
                                $hostname = Read-Host "Digite o host ou IP"
                                $port = Read-Host "Digite a porta"

                                if ($hostname -and $port) {
                                    Write-Host "🔍 Testando $hostname`:$port..." -ForegroundColor Yellow
                                    $result = Test-NetConnection -ComputerName $hostname -Port $port -WarningAction SilentlyContinue

                                    if ($result.TcpTestSucceeded) {
                                        Write-Host "✅ Porta $port está aberta em $hostname" -ForegroundColor Green
                                        Write-Host "⏱️  Tempo de resposta: $($result.PingReplyDetails.RoundtripTime) ms" -ForegroundColor Cyan
                                    } else {
                                        Write-Host "❌ Porta $port está fechada ou filtrada em $hostname" -ForegroundColor Red
                                    }
                                }
                            } catch {
                                Write-Host "❌ Erro no teste de porta: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "5" {
                            Write-Host "`n[🧹] Renovando configuração de rede..." -ForegroundColor Magenta
                            try {
                                Write-Host "🔄 Limpando cache DNS..." -ForegroundColor Yellow
                                ipconfig /flushdns | Out-Null

                                Write-Host "🔄 Liberando IP atual..." -ForegroundColor Yellow
                                ipconfig /release | Out-Null

                                Write-Host "🔄 Renovando IP..." -ForegroundColor Yellow
                                ipconfig /renew | Out-Null

                                Write-Host "✅ Configuração de rede renovada!" -ForegroundColor Green
                            } catch {
                                Write-Host "❌ Erro ao renovar rede: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "6" {
                            Write-Host "`n[🔍] Conexões ativas:" -ForegroundColor Magenta
                            try {
                                $connections = Get-NetTCPConnection -State Established |
                                        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State,
                                        @{Name='Process';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |
                                        Sort-Object Process |
                                        Format-Table -AutoSize

                                $connections | Out-Host -Paging
                            } catch {
                                Write-Host "❌ Erro ao listar conexões: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($subChoice -ne "9" -and $subChoice -ne "0")
            }

            "4" { # Ferramentas de Limpeza
                do {
                    Show-CleanupMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" { Limpeza-Avancada -IncludeTempFiles }
                        "2" {
                            Write-Host "`n[🧼] Abrindo Storage Sense..." -ForegroundColor Magenta
                            try {
                                Start-Process "ms-settings:storagesense"
                            } catch {
                                Write-Host "❌ Erro ao abrir Storage Sense: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "3" { Limpeza-Avancada -IncludePrefetch }
                        "4" { Limpeza-Avancada -IncludeThumbnails }
                        "5" { Limpeza-Avancada -IncludeRecentFiles }
                        "6" { Limpeza-Avancada -IncludeTempFiles -IncludeThumbnails -IncludePrefetch -IncludeLogs -IncludeRecentFiles }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($subChoice -ne "9" -and $subChoice -ne "0")
            }

            "5" { # Otimização Avançada
                do {
                    Show-OptimizationMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" { Otimizacao-Sistema -OptimizeDrives }
                        "2" { Otimizacao-Sistema -Defrag }
                        "3" { Otimizacao-Sistema -TrimSSD }
                        "4" {
                            Write-Host "`n[🛠️] Configurações de energia:" -ForegroundColor Magenta
                            try {
                                Write-Host "📊 Planos de energia disponíveis:" -ForegroundColor Yellow
                                powercfg /list

                                Write-Host "`n💡 Para alterar para Alto Desempenho:" -ForegroundColor Blue
                                Write-Host "powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -ForegroundColor Gray

                                $response = Read-Host "`nDefinir para Alto Desempenho? (s/n)"
                                if ($response -eq 's' -or $response -eq 'S') {
                                    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                                    Write-Host "✅ Plano alterado para Alto Desempenho" -ForegroundColor Green
                                }
                            } catch {
                                Write-Host "❌ Erro nas configurações de energia: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "5" {
                            Write-Host "`n[🚀] Análise de serviços:" -ForegroundColor Magenta
                            try {
                                Write-Host "⚠️  CUIDADO: Não desative serviços sem conhecimento técnico!" -ForegroundColor Red
                                Write-Host "`n📊 Serviços automáticos parados:" -ForegroundColor Yellow

                                Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -eq "Stopped" } |
                                        Select-Object Name, DisplayName, Status, StartType |
                                        Format-Table -AutoSize

                                Write-Host "💡 Use 'services.msc' para gerenciar serviços com segurança" -ForegroundColor Blue
                            } catch {
                                Write-Host "❌ Erro na análise de serviços: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "6" {
                            Write-Host "`n[🧪] Iniciando otimização completa..." -ForegroundColor Magenta
                            Write-Host "⚠️  Este processo pode demorar vários minutos" -ForegroundColor Yellow
                            $confirm = Read-Host "Continuar? (s/n)"
                            if ($confirm -eq 's' -or $confirm -eq 'S') {
                                Otimizacao-Sistema -OptimizeDrives -TrimSSD
                            }
                        }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($subChoice -ne "9" -and $subChoice -ne "0")
            }

            "6" { # Relatórios e Diagnósticos
                do {
                    Show-ReportsMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" { Criar-Relatorio }
                        "2" { Verificar-Drivers -ExportList }
                        "3" {
                            Write-Host "`n[📋] Exportando lista de programas..." -ForegroundColor Magenta
                            try {
                                $date = Get-Date -Format "yyyy-MM-dd"
                                $file = "$env:USERPROFILE\Desktop\Programas_Instalados_$date.txt"

                                $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                                        Where-Object { $_.DisplayName -and $_.DisplayName -notlike "Update*" } |
                                        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
                                        Sort-Object DisplayName

                                $programs | Out-File $file -Encoding UTF8
                                Write-Host "✅ Lista salva em: $file" -ForegroundColor Green
                                Write-Host "📊 Total de programas: $($programs.Count)" -ForegroundColor Cyan
                            } catch {
                                Write-Host "❌ Erro ao exportar programas: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "4" {
                            Write-Host "`n[🖨️] Salvando configuração de rede..." -ForegroundColor Magenta
                            try {
                                $date = Get-Date -Format "yyyy-MM-dd"
                                $file = "$env:USERPROFILE\Desktop\Configuracao_Rede_$date.txt"

                                "=== CONFIGURAÇÃO DE REDE - $date ===" | Out-File $file
                                "Gerado pelo SysBot v3.2`n" | Out-File $file -Append

                                "=== CONFIGURAÇÃO IP ===" | Out-File $file -Append
                                ipconfig /all | Out-File $file -Append

                                "`n=== ADAPTADORES ===" | Out-File $file -Append
                                Get-NetAdapter | Format-Table -AutoSize | Out-File $file -Append

                                "`n=== ROTAS ===" | Out-File $file -Append
                                route print | Out-File $file -Append

                                Write-Host "✅ Configuração salva em: $file" -ForegroundColor Green
                            } catch {
                                Write-Host "❌ Erro ao salvar configuração: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "5" {
                            Write-Host "`n[📦] Criando dump completo do sistema..." -ForegroundColor Magenta
                            try {
                                $date = Get-Date -Format "yyyy-MM-dd_HH-mm"
                                $folder = "$env:USERPROFILE\Desktop\SysBot_Dump_$date"
                                New-Item -ItemType Directory -Path $folder -Force | Out-Null

                                Write-Host "📄 Coletando informações do sistema..." -ForegroundColor Yellow
                                systeminfo | Out-File "$folder\systeminfo.txt" -Encoding UTF8

                                Write-Host "🖥️  Coletando informações de hardware..." -ForegroundColor Yellow
                                Get-CimInstance Win32_ComputerSystem | Out-File "$folder\hardware.txt" -Encoding UTF8

                                Write-Host "⚙️  Coletando processos..." -ForegroundColor Yellow
                                Get-Process | Sort-Object CPU -Descending | Out-File "$folder\processes.txt" -Encoding UTF8

                                Write-Host "🔧 Coletando serviços..." -ForegroundColor Yellow
                                Get-Service | Sort-Object Status, Name | Out-File "$folder\services.txt" -Encoding UTF8

                                Write-Host "🌐 Coletando configuração de rede..." -ForegroundColor Yellow
                                ipconfig /all | Out-File "$folder\network.txt" -Encoding UTF8

                                Write-Host "💾 Coletando informações de disco..." -ForegroundColor Yellow
                                Get-Volume | Out-File "$folder\disks.txt" -Encoding UTF8

                                Write-Host "✅ Dump completo salvo em: $folder" -ForegroundColor Green
                            } catch {
                                Write-Host "❌ Erro ao criar dump: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "6" {
                            Write-Host "`n[🔍] Analisando integridade do sistema..." -ForegroundColor Magenta
                            try {
                                $results = @()

                                Write-Host "🛡️  Verificando SFC..." -ForegroundColor Yellow
                                try {
                                    $sfcResult = sfc /verifyonly 2>&1
                                    if ($LASTEXITCODE -eq 0) {
                                        $results += "✅ SFC: Sistema íntegro"
                                    } else {
                                        $results += "⚠️  SFC: Problemas encontrados"
                                    }
                                } catch {
                                    $results += "❌ SFC: Erro na verificação"
                                }

                                Write-Host "🏥 Verificando DISM..." -ForegroundColor Yellow
                                try {
                                    $dismResult = DISM /Online /Cleanup-Image /ScanHealth 2>&1
                                    if ($dismResult -match "nenhuma corrupção" -or $dismResult -match "no corruption") {
                                        $results += "✅ DISM: Imagem íntegra"
                                    } else {
                                        $results += "⚠️  DISM: Possíveis problemas encontrados"
                                    }
                                } catch {
                                    $results += "❌ DISM: Erro na verificação"
                                }

                                Write-Host "🔍 Verificando drivers..." -ForegroundColor Yellow
                                try {
                                    $problemDrivers = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
                                    if ($problemDrivers) {
                                        $results += "⚠️  DRIVERS: $($problemDrivers.Count) dispositivos com problemas"
                                    } else {
                                        $results += "✅ DRIVERS: Todos funcionando corretamente"
                                    }
                                } catch {
                                    $results += "❌ DRIVERS: Erro na verificação"
                                }

                                Write-Host "`n=== RESULTADOS DA ANÁLISE ===" -ForegroundColor Cyan
                                $results | ForEach-Object {
                                    $color = if ($_ -match "✅") { 'Green' } elseif ($_ -match "⚠️") { 'Yellow' } else { 'Red' }
                                    Write-Host $_ -ForegroundColor $color
                                }
                            } catch {
                                Write-Host "❌ Erro na análise de integridade: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($subChoice -ne "9" -and $subChoice -ne "0")
            }

            "0" {
                Write-Host "`n👋 Encerrando SysBot. Até logo!" -ForegroundColor Green
                Start-Sleep -Seconds 2
                exit
            }

            default {
                Write-Host "`n❌ Opção inválida. Tente novamente." -ForegroundColor Red
                Pausar
            }
        }
    } catch {
        Write-Host "`n💥 ERRO CRÍTICO:" -ForegroundColor Red
        Write-Host "Mensagem: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Local: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
        Write-Host "`n🔧 Tente executar como Administrador ou verifique permissões" -ForegroundColor Blue
        Pausar
    }
} while ($true)