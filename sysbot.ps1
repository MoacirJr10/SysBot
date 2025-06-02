<#
    SYSBOT v3.2 - Sistema Avançado de Manutenção e Otimização
    Script principal com menu interativo
    Atualizado para sincronizar com utils.ps1 melhorado
#>

# Configurações iniciais
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version Latest

# Caminho do módulo de utilidades
$utilsPath = Join-Path -Path $PSScriptRoot -ChildPath "utils.ps1"

# Importar módulo
if (Test-Path $utilsPath) {
    try {
        . $utilsPath
        Write-Verbose "Módulo utils.ps1 carregado com sucesso" -Verbose
    } catch {
        Write-Host "❌ Erro ao carregar utils.ps1: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Arquivo utils.ps1 não encontrado." -ForegroundColor Red
    exit 1
}

function Show-MainMenu {
    [CmdletBinding()]
    param()

    Write-Header -Title "SYSBOT v3.2 TECH TOOL"

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
    [CmdletBinding()]
    param()

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
    [CmdletBinding()]
    param()

    Write-Host @"
================ INFORMACOES DE HARDWARE ================

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
    [CmdletBinding()]
    param()

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
    [CmdletBinding()]
    param()

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
    [CmdletBinding()]
    param()

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
    [CmdletBinding()]
    param()

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

# Loop principal
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
                            sfc /scannow
                        }
                        "3" {
                            Write-Host "`n[🏥] Restaurando saúde do sistema..." -ForegroundColor Magenta
                            DISM /Online /Cleanup-Image /RestoreHealth
                        }
                        "4" { Verificar-Drivers -CheckUpdates }
                        "5" {
                            Write-Host "`n[🔄] Atualizando programas via winget..." -ForegroundColor Magenta
                            winget upgrade --all --accept-package-agreements --accept-source-agreements
                        }
                        "6" { Verificar-Disco }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($true)
            }

            "2" { # Informações de Hardware
                do {
                    Show-HardwareMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" {
                            systeminfo | Select-String -Pattern "Nome do SO","Versão","Fabricante","Modelo","Processador","Memória"
                        }
                        "2" { Verificar-MemoriaRAM -Detailed }
                        "3" {
                            Get-CimInstance Win32_VideoController |
                                    Select-Object Name, DriverVersion, @{Name='VRAM(MB)';Expression={$_.AdapterRAM/1MB}} |
                                    Format-Table -AutoSize
                        }
                        "4" {
                            Get-PhysicalDisk | Format-Table -AutoSize
                            Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } |
                                    Select-Object DriveLetter, FileSystemLabel,
                                    @{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,2)}},
                                    @{Name='FreeGB';Expression={[math]::Round($_.SizeRemaining/1GB,2)}} |
                                    Format-Table -AutoSize
                        }
                        "5" {
                            Get-CimInstance -ClassName Win32_TemperatureProbe -ErrorAction SilentlyContinue |
                                    Select-Object Name, CurrentTemperature | Format-Table -AutoSize
                            Get-CimInstance -ClassName Win32_Fan -ErrorAction SilentlyContinue |
                                    Select-Object Name, Status | Format-Table -AutoSize
                        }
                        "6" {
                            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                            HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                                    Where-Object { $_.DisplayName } |
                                    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
                                    Sort-Object DisplayName |
                                    Format-Table -AutoSize | Out-Host -Paging
                        }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($true)
            }

            "3" { # Diagnóstico de Rede
                do {
                    Show-NetworkMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" {
                            ipconfig /all | Select-String -Pattern "IPv4","Gateway","Servidores DNS"
                            Get-NetIPConfiguration | Format-Table -AutoSize
                        }
                        "2" {
                            Test-Connection -ComputerName "google.com" -Count 4
                            Test-NetConnection -ComputerName "google.com" -Port 80 -InformationLevel Detailed
                        }
                        "3" { Testar-VelocidadeInternet }
                        "4" {
                            $hostname = Read-Host "Digite o host ou IP"
                            $port = Read-Host "Digite a porta"
                            Test-NetConnection -ComputerName $hostname -Port $port
                        }
                        "5" {
                            ipconfig /flushdns
                            ipconfig /release
                            ipconfig /renew
                        }
                        "6" {
                            Get-NetTCPConnection -State Established |
                                    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess |
                                    Sort-Object OwningProcess |
                                    Format-Table -AutoSize
                        }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($true)
            }

            "4" { # Ferramentas de Limpeza
                do {
                    Show-CleanupMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" { Limpeza-Avancada -IncludeTempFiles }
                        "2" { Start-Process "ms-settings:storagesense" }
                        "3" { Limpeza-Avancada -IncludePrefetch }
                        "4" { Limpeza-Avancada -IncludeThumbnails }
                        "5" { Limpeza-Avancada -IncludeRecentFiles }
                        "6" { Limpeza-Avancada -IncludeTempFiles -IncludeThumbnails -IncludePrefetch -IncludeLogs }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($true)
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
                            powercfg /list
                            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # Alto desempenho
                        }
                        "5" {
                            # Exemplo seguro - não desativa serviços críticos
                            Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -eq "Stopped" } |
                                    Select-Object Name, DisplayName | Format-Table -AutoSize
                        }
                        "6" { Otimizacao-Sistema -OptimizeDrives -Defrag -TrimSSD }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($true)
            }

            "6" { # Relatórios e Diagnósticos
                do {
                    Show-ReportsMenu
                    $subChoice = Read-Host "`nDigite sua opção"

                    switch ($subChoice) {
                        "1" { Criar-Relatorio }
                        "2" { Verificar-Drivers -ExportList }
                        "3" {
                            $date = Get-Date -Format "yyyy-MM-dd"
                            $file = "$env:USERPROFILE\Desktop\Programas_Instalados_$date.txt"
                            Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                            HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                                    Where-Object { $_.DisplayName } |
                                    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
                                    Sort-Object DisplayName |
                                    Out-File $file -Encoding UTF8
                            Write-Host "Lista salva em: $file" -ForegroundColor Green
                        }
                        "4" {
                            $date = Get-Date -Format "yyyy-MM-dd"
                            $file = "$env:USERPROFILE\Desktop\Configuracao_Rede_$date.txt"
                            ipconfig /all | Out-File $file
                            Get-NetIPConfiguration | Out-File $file -Append
                            Write-Host "Configuração salva em: $file" -ForegroundColor Green
                        }
                        "5" {
                            $date = Get-Date -Format "yyyy-MM-dd_HH-mm"
                            $folder = "$env:USERPROFILE\Desktop\SysBot_Dump_$date"
                            New-Item -ItemType Directory -Path $folder | Out-Null

                            systeminfo > "$folder\systeminfo.txt"
                            Get-CimInstance Win32_ComputerSystem > "$folder\computer.txt"
                            Get-Process | Sort-Object CPU -Descending > "$folder\processes.txt"
                            Get-Service | Where-Object { $_.Status -ne "Running" } > "$folder\services.txt"

                            Write-Host "Dump completo salvo em: $folder" -ForegroundColor Green
                        }
                        "6" {
                            # Verificação avançada de integridade
                            Write-Host "`n[🔍] Verificando integridade do sistema..." -ForegroundColor Magenta
                            $results = @()

                            # Verificar SFC
                            try {
                                $sfc = sfc /verifyonly
                                $results += "SFC: $(if ($LASTEXITCODE -eq 0) {'OK'} else {'Problemas encontrados'})"
                            } catch {
                                $results += "SFC: Erro na verificação"
                            }

                            # Verificar DISM
                            try {
                                $dism = DISM /Online /Cleanup-Image /ScanHealth
                                $results += "DISM: $(if ($dism -match 'nenhuma corrupção') {'OK'} else {'Problemas encontrados'})"
                            } catch {
                                $results += "DISM: Erro na verificação"
                            }

                            # Exibir resultados
                            $results | ForEach-Object { Write-Host $_ }
                        }
                        "9" { break }
                        "0" { exit }
                        default { Write-Host "❌ Opção inválida" -ForegroundColor Red }
                    }

                    if ($subChoice -notin "0","9") { Pausar }
                } while ($true)
            }

            "0" {
                Write-Host "`n👋 Encerrando SysBot. Até logo!" -ForegroundColor Green
                exit
            }

            default {
                Write-Host "`n❌ Opção inválida. Tente novamente." -ForegroundColor Red
                Pausar
            }
        }
    } catch {
        Write-Host "`n❌ Ocorreu um erro: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Local: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
        Write-Host "Linha: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Pausar
    }
} while ($true)