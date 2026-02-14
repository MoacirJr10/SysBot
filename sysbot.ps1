# --- Configuracoes Iniciais ---
# SEGURANCA: Alterado para 'Continue' para que erros criticos sejam visiveis ao usuario
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version Latest

# --- Gerenciamento de Configuracao (config.json) ---
$configPath = "./config.json"
if (-not (Test-Path $configPath)) {
    $defaultConfig = @{
        daysForOldLogs = 30
        lowDiskSpaceThreshold = 15
    }
    $defaultConfig | ConvertTo-Json | Out-File $configPath -Encoding UTF8
}
$config = Get-Content $configPath | ConvertFrom-Json

# --- Gerenciamento de Logs ---
if (-not (Test-Path -Path "./logs")) { New-Item -ItemType Directory -Path "./logs" | Out-Null }
$logFile = ".\logs\SysBot-Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Start-Transcript -Path $logFile -Append

# --- Funcoes de UI Core ---

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Pausar {
    Write-Host "`n Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Menu {
    param(
        [string]$Title,
        [array]$Options,
        [hashtable]$Status
    )
    Clear-Host
    $width = 70
    
    # ASCII Art Header
    Write-Host "" -ForegroundColor Green
    Write-Host '   _____            ____        __ ' -ForegroundColor Green
    Write-Host '  / ___/__  _______/ __ )____  / /_' -ForegroundColor Green
    Write-Host '  \__ \/ / / / ___/ __  / __ \/ __/' -ForegroundColor Green
    Write-Host ' ___/ / /_/ (__  ) /_/ / /_/ / /_  ' -ForegroundColor Green
    Write-Host '/____/\__, /____/_____/\____/\__/  ' -ForegroundColor Green
    Write-Host '     /____/                        ' -ForegroundColor Green
    Write-Host ""

    # Status Box
    if ($Status) {
        $statusLine = "Status do Sistema: $($Status.Text)".PadLeft(((($width) - "Status do Sistema: $($Status.Text)".Length) / 2) + "Status do Sistema: $($Status.Text)".Length).PadRight($width)
        Write-Host $statusLine -ForegroundColor $Status.Color -BackgroundColor DarkGray
        if ($Status.Reasons) {
            foreach ($reason in $Status.Reasons) {
                Write-Host "- $reason".PadLeft(10) -ForegroundColor Gray
            }
        }
        Write-Host ""
    }

    # Menu Box
    $line = "+-" + ("-" * $width) + "-+"
    $paddedTitle = $Title.PadLeft(((($width - 2) - $Title.Length) / 2) + $Title.Length).PadRight($width - 2)

    Write-Host $line -ForegroundColor Cyan
    Write-Host "| $($paddedTitle) |" -ForegroundColor Green
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""

    foreach ($option in $Options) {
        Write-Host "  $option" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host $line -ForegroundColor Cyan

    # Footer / Credits
    if ($Title -eq "MENU PRINCIPAL") {
        Write-Host "" -ForegroundColor DarkGray
        Write-Host "    Desenvolvido por: " -NoNewline -ForegroundColor Cyan
        Write-Host "MoacirJr10" -ForegroundColor White
        Write-Host "    Estudante:" -NoNewline -ForegroundColor Cyan
        Write-Host "  Engenharia de Computacao" -ForegroundColor White
        Write-Host "    GitHub: " -NoNewline -ForegroundColor Cyan
        Write-Host "github.com/MoacirJr10" -ForegroundColor White
        Write-Host "    Sugestoes sao sempre bem-vindas!" -ForegroundColor Green
        Write-Host "" -ForegroundColor DarkGray
    }
    
    return Read-Host "`n  [>] Escolha uma opcao"
}

function Execute-Action {
    param(
        [string]$Title,
        [scriptblock]$Action,
        [switch]$IsLongRunning
    )
    Clear-Host
    $width = 70
    $line = "+-" + ("-" * $width) + "-+"
    $paddedTitle = "EXECUTANDO: $Title".PadLeft(((($width - 2) - "EXECUTANDO: $Title".Length) / 2) + "EXECUTANDO: $Title".Length).PadRight($width - 2)

    Write-Host $line -ForegroundColor Magenta
    Write-Host "| $($paddedTitle) |" -ForegroundColor White
    Write-Host $line -ForegroundColor Magenta
    Write-Host ""

    if ($IsLongRunning) {
        Write-Host "[*] Esta operacao pode levar varios minutos. Por favor, aguarde..." -ForegroundColor Cyan
        Write-Host ""
    }

    try {
        Invoke-Command -ScriptBlock $Action
        Write-Host "`n[+] Acao concluida com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "`n[-] Ocorreu um erro durante a execucao." -ForegroundColor Red
        Write-Host "    Mensagem: $($_.Exception.Message)" -ForegroundColor Red
    }
    Pausar
}

function Show-HelpScreen {
    param([string]$Title, [array]$HelpLines)
    Clear-Host
    $width = 70
    $line = "+-" + ("-" * $width) + "-+"
    $paddedTitle = $Title.PadLeft(((($width - 2) - $Title.Length) / 2) + $Title.Length).PadRight($width - 2)

    Write-Host $line -ForegroundColor Cyan
    Write-Host "| $($paddedTitle) |" -ForegroundColor Green
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""

    foreach($line in $HelpLines) {
        if ($line.StartsWith("[")) {
            Write-Host "  $line" -ForegroundColor Yellow
        } else {
            Write-Host "    $line" -ForegroundColor Gray
        }
    }
    Pausar
}


# --- FUNCOES DE LOGICA (BACKEND) ---

function Criar-PontoRestauracao {
    Write-Host "[*] Tentando criar um Ponto de Restauracao do Sistema..." -ForegroundColor Yellow
    try {
        # Verifica se a restauracao do sistema esta habilitada
        $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "SysBot_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[+] Ponto de restauracao criado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "[!] Nao foi possivel criar o ponto de restauracao." -ForegroundColor Yellow
        Write-Host "    Motivo: $($_.Exception.Message)" -ForegroundColor Gray
        Write-Host "    Dica: Verifique se a 'Protecao do Sistema' esta ativada no Windows." -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

function Get-SystemStatus {
    $status = @{ Text = "[SAUDAVEL]"; Color = "Green"; Reasons = @() }
    $reasons = @()
    try {
        $updates = Get-CimInstance -ClassName "Win32_QuickFixEngineering"
        $lastUpdateTime = ($updates | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1).InstalledOn
        if ($lastUpdateTime -lt (Get-Date).AddDays(-30)) { $reasons += "Atualizacoes do Windows nao sao instaladas ha mais de 30 dias." }
    } catch {}
    try {
        $systemDrive = Get-Volume -DriveLetter $env:SystemDrive.Substring(0,1)
        $percentFree = [math]::Round(($systemDrive.SizeRemaining / $systemDrive.Size) * 100, 2)
        if ($percentFree -lt $config.lowDiskSpaceThreshold) { $reasons += "Espaco livre em disco na unidade C: esta abaixo de $($config.lowDiskSpaceThreshold)%." }
    } catch {}
    if ($reasons.Count -gt 0) {
        $status.Text = "[ATENCAO NECESSARIA]"
        $status.Color = "Yellow"
        $status.Reasons = $reasons
    }
    return $status
}

function Verificar-Atualizacoes {
    param([switch]$InstallUpdates)
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "[!] Modulo PSWindowsUpdate nao encontrado. Usando Windows Update nativo..." -ForegroundColor Yellow
        Start-Process "ms-settings:windowsupdate" -Wait:$false; return
    }
    Import-Module PSWindowsUpdate -Force
    $updates = Get-WindowsUpdate
    if ($updates.Count -eq 0) { Write-Host "[+] Sistema atualizado!" -ForegroundColor Green }
    else { 
        Write-Host "[*] $($updates.Count) atualizacoes encontradas" -ForegroundColor Yellow
        if ($InstallUpdates) {
            Criar-PontoRestauracao
            Install-WindowsUpdate -AcceptAll -AutoReboot:$false
        }
    }
}

function Verificar-Drivers {
    $drivers = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
    if ($drivers) {
        Write-Host "[!] Drivers com problemas encontrados:" -ForegroundColor Yellow
        $drivers | Select-Object Name, DeviceID | Format-Table -AutoSize
    } else { Write-Host "[+] Todos os drivers estao funcionando corretamente" -ForegroundColor Green }
}

function Verificar-Disco {
    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
    foreach ($drive in $drives) {
        Write-Host "[*] Verificando unidade $($drive.DriveLetter):\..." -ForegroundColor Yellow
        chkdsk "$($drive.DriveLetter):" /f /r
    }
}

function Show-HardwareSummary {
    Write-Host "`n--- CPU ---" -ForegroundColor Cyan
    Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List
    Write-Host "`n--- GPU ---" -ForegroundColor Cyan
    Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Basic*" } | Select-Object Name, DriverVersion, @{Name='VRAM(MB)';Expression={[math]::Round($_.AdapterRAM/1MB,0)}} | Format-Table -AutoSize
    Write-Host "`n--- Memoria RAM ---" -ForegroundColor Cyan
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $totalMem = $osInfo.TotalVisibleMemorySize; $freeMem = $osInfo.FreePhysicalMemory; $usedMem = $totalMem - $freeMem
    $totalRAM_GB = [math]::Round($totalMem / 1MB, 2); $usedPercent = [math]::Round(($usedMem / $totalMem) * 100, 2)
    Write-Host "Total de RAM: $totalRAM_GB GB" -ForegroundColor Yellow
    Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, @{Name="Capacidade(GB)";Expression={[math]::Round($_.Capacity / 1GB, 2)}}, Speed, Manufacturer | Format-Table -AutoSize
    Write-Host "Uso atual: $usedPercent%" -ForegroundColor $(if ($usedPercent -gt 80) { 'Red' } else { 'Green' })
}

function Limpeza-Avancada {
    param([switch]$IncludeTempFiles, [switch]$IncludePrefetch, [switch]$IncludeThumbnails, [switch]$IncludeRecentFiles, [switch]$IncludeLogs)
    $totalCleaned = 0

    # SEGURANCA: Funcao auxiliar para deletar com seguranca
    function Remove-Safe {
        param($Path)
        # Verifica se o caminho existe e nao e vazio ou raiz
        if ([string]::IsNullOrWhiteSpace($Path) -or $Path.Length -lt 4 -or -not (Test-Path $Path)) { return }
        try {
            $items = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue
            $size = ($items | Measure-Object -Property Length -Sum).Sum
            # Remove apenas o conteudo, mantendo a pasta pai se possivel, ou usa wildcard
            Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
            return $size
        } catch { return 0 }
    }

    if ($IncludeTempFiles) {
        Write-Host "[*] Limpando arquivos temporarios..." -ForegroundColor Yellow
        $tempPaths = @("$env:TEMP", "$env:WINDIR\Temp", "$env:LOCALAPPDATA\Temp")
        foreach ($path in $tempPaths) {
            $totalCleaned += Remove-Safe -Path $path
        }
    }
    if ($IncludePrefetch) {
        Write-Host "[*] Limpando cache de pre-carregamento..." -ForegroundColor Yellow
        $totalCleaned += Remove-Safe -Path "$env:WINDIR\Prefetch"
    }
    if ($IncludeThumbnails) {
        Write-Host "[*] Limpando cache de miniaturas..." -ForegroundColor Yellow
        # Thumbnails sao arquivos especificos, nao pasta inteira
        $thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        if (Test-Path $thumbPath) {
            $thumbs = Get-ChildItem "$thumbPath\thumbcache_*.db" -ErrorAction SilentlyContinue
            if ($thumbs) {
                $size = ($thumbs | Measure-Object -Property Length -Sum).Sum
                $thumbs | Remove-Item -Force -ErrorAction SilentlyContinue
                $totalCleaned += $size
            }
        }
    }
    if ($IncludeRecentFiles) {
        Write-Host "[*] Limpando historico de documentos recentes..." -ForegroundColor Yellow
        $totalCleaned += Remove-Safe -Path "$env:APPDATA\Microsoft\Windows\Recent"
    }
    if ($IncludeLogs) {
        Write-Host "[*] Limpando logs antigos (mais de $($config.daysForOldLogs) dias)..." -ForegroundColor Yellow
        $logPaths = @("$env:WINDIR\Logs", "$env:WINDIR\System32\LogFiles")
        foreach ($logPath in $logPaths) {
            if (Test-Path $logPath) {
                $oldLogs = Get-ChildItem "$logPath\*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$config.daysForOldLogs) }
                if ($oldLogs) {
                    $logSize = ($oldLogs | Measure-Object -Property Length -Sum).Sum
                    $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
                    $totalCleaned += $logSize
                }
            }
        }
    }
    $cleanedMB = [math]::Round($totalCleaned / 1MB, 2)
    Write-Host "[+] Espaco liberado: $cleanedMB MB" -ForegroundColor Green
}

function Otimizacao-Sistema {
    param([switch]$OptimizeDrives, [switch]$Defrag, [switch]$TrimSSD)
    if ($OptimizeDrives) {
        Write-Host "[*] Otimizando unidades..." -ForegroundColor Yellow
        Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object { Write-Host "  > Otimizando unidade $($_.DriveLetter):" -ForegroundColor Cyan; Optimize-Volume -DriveLetter $_.DriveLetter -Analyze -Verbose }
    }
    if ($Defrag) {
        Write-Host "[*] Desfragmentando HDDs..." -ForegroundColor Yellow
        $hdds = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'HDD' }; if ($hdds) { foreach ($hdd in $hdds) { Write-Host "  > Desfragmentando disco: $($hdd.FriendlyName)" -ForegroundColor Cyan } } else { Write-Host "  [i] Nenhum HDD encontrado para desfragmentacao" -ForegroundColor Blue }
    }
    if ($TrimSSD) {
        Write-Host "[*] Executando TRIM em SSDs..." -ForegroundColor Yellow
        $ssds = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' }; if ($ssds) { foreach ($ssd in $ssds) { Write-Host "  > TRIM no SSD: $($ssd.FriendlyName)" -ForegroundColor Cyan; Optimize-Volume -DriveLetter C -ReTrim -Verbose } } else { Write-Host "  [i] Nenhum SSD encontrado" -ForegroundColor Blue }
    }
}

function Criar-Relatorio {
    $date = Get-Date -Format "yyyy-MM-dd_HH-mm"; $reportPath = "$env:USERPROFILE\Desktop\Relatorio_Sistema_$date.html"
    $html = @"
<!DOCTYPE html><html><head><title>Relatorio do Sistema - $date</title><style>body{font-family:Arial,sans-serif;margin:30px;background-color:#f9f9f9;text-align:center;}h1{color:#2E86AB;margin-bottom:5px;}h2{color:#A23B72;margin-top:30px;}.info{background-color:#e8f4fd;padding:10px;border-radius:8px;display:inline-block;margin:10px auto;font-weight:bold;}table{border-collapse:collapse;width:90%;margin:20px auto;box-shadow:0 2px 10px rgba(0,0,0,0.1);border-radius:8px;overflow:hidden;}th,td{border:1px solid #ddd;padding:10px;}th{background-color:#f2f2f2;color:#333;font-weight:bold;}td{background-color:#fff;}footer{margin-top:40px;color:#666;font-size:0.9em;}</style></head><body><h1>Relatorio do Sistema - SysBot</h1><div class="info">Gerado em: $(Get-Date)</div><h2>Informacoes Basicas</h2><table><tr><th>Item</th><th>Valor</th></tr><tr><td>Nome do Computador</td><td>$env:COMPUTERNAME</td></tr><tr><td>Usuario</td><td>$env:USERNAME</td></tr><tr><td>Sistema Operacional</td><td>$((Get-CimInstance Win32_OperatingSystem).Caption)</td></tr><tr><td>Versao</td><td>$((Get-CimInstance Win32_OperatingSystem).Version)</td></tr></table><h2>Hardware</h2><table><tr><th>Componente</th><th>Informacao</th></tr><tr><td>Processador</td><td>$((Get-CimInstance Win32_Processor).Name)</td></tr><tr><td>Memoria Total</td><td>$([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB</td></tr><tr><td>Arquitetura</td><td>$((Get-CimInstance Win32_OperatingSystem).OSArchitecture)</td></tr></table><h2>Discos</h2><table><tr><th>Unidade</th><th>Tamanho</th><th>Livre</th><th>Tipo</th></tr>
"@
    Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object { $sizeGB = [math]::Round($_.Size / 1GB, 2); $freeGB = [math]::Round($_.SizeRemaining / 1GB, 2); $html += "<tr><td>$($_.DriveLetter):</td><td>$sizeGB GB</td><td>$freeGB GB</td><td>$($_.FileSystem)</td></tr>" }
    $html += "</table><footer><p><em>Relatorio gerado pelo SysBot</em></p></footer></body></html>
"
    $html | Out-File $reportPath -Encoding UTF8; Write-Host "[+] Relatorio salvo em: $reportPath" -ForegroundColor Green
}

function Verificar-Firewall {
    $profiles = Get-NetFirewallProfile; $allEnabled = $true
    foreach ($profile in $profiles) {
        if ($profile.Enabled -ne 'True') { $allEnabled = $false; Write-Host "[!] Firewall esta DESATIVADO para o perfil: $($profile.Name)" -ForegroundColor Red }
        else { Write-Host "[+] Firewall esta ATIVADO para o perfil: $($profile.Name)" -ForegroundColor Green }
    }
    if ($allEnabled) { Write-Host "`n[+] Todos os perfis do firewall estao ativos." -ForegroundColor Green }
}

function Verificar-Antivirus {
    $av = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct
    if ($av) { 
        Write-Host "[+] Antivirus Encontrado: $($av.displayName)" -ForegroundColor Green
        if ($av.productState -eq "397312" -or $av.productState -eq "266240") { Write-Host "[+] Status: Ativo e atualizado." -ForegroundColor Green }
        else { Write-Host "[!] Status: O antivirus pode estar desatualizado ou inativo." -ForegroundColor Yellow }
    } else { Write-Host "[!] Nenhum antivirus foi detectado pelo Windows." -ForegroundColor Red }
}

function Listar-ProgramasInicializacao {
    Get-CimInstance -ClassName Win32_StartupCommand | Select-Object Name, Command, User, Location | Format-Table -AutoSize
}

function Manage-DevTool {
    param(
        [string]$ToolName,
        [string]$WingetId,
        [string]$ExecutableName,
        [string]$VersionArgument,
        [switch]$NoInstall
    )
    
    $exePath = Get-Command $ExecutableName -ErrorAction SilentlyContinue
    if ($exePath) {
        $version = & $exePath.Source $VersionArgument
        Write-Host "[+] $ToolName ja esta instalado." -ForegroundColor Green
        Write-Host "    Versao: $version" -ForegroundColor Cyan
        if (-not $NoInstall) {
            $choice = Read-Host "`n[?] Deseja reinstalar/atualizar? (s/n)"
            if ($choice -eq 's') {
                Execute-Action -Title "INSTALANDO/ATUALIZANDO $ToolName" -Action { winget install -e --id $WingetId } -IsLongRunning
            }
        }
    } else {
        Write-Host "[!] $ToolName nao encontrado." -ForegroundColor Yellow
        if (-not $NoInstall) {
            $choice = Read-Host "`n[?] Deseja instalar agora? (s/n)"
            if ($choice -eq 's') {
                Execute-Action -Title "INSTALANDO $ToolName" -Action { winget install -e --id $WingetId } -IsLongRunning
            }
        }
    }
}


# --- LOOP PRINCIPAL ---
do {
    if (-not (Test-IsAdmin)) {
        Clear-Host; Write-Host "[!] ERRO: Este script precisa de privilegios de Administrador." -ForegroundColor Red; Write-Host "[!] Por favor, clique com o botao direito em 'run_admin.bat' e escolha 'Executar como administrador'." -ForegroundColor Red; Pausar; break
    }
    
    $systemStatus = Get-SystemStatus
    $mainMenuOptions = @(
        "[1] Manutencao do Sistema",
        "[2] Informacoes de Hardware",
        "[3] Diagnostico de Rede",
        "[4] Ferramentas de Limpeza",
        "[5] Otimizacao Avancada",
        "[6] Relatorios e Diagnosticos",
        "[7] Auditoria de Seguranca",
        "[8] Gerenciador de Desenvolvimento",
        "",
        "[9] AJUDA: O que cada menu faz?",
        "[0] Sair do SysBot"
    )
    $mainChoice = Show-Menu -Title "MENU PRINCIPAL" -Options $mainMenuOptions -Status $systemStatus

    switch ($mainChoice) {
        '1' { # Manutencao
            do {
                $subOptions = @("[1] Verificar e Instalar Atualizacoes do Windows", "[2] Verificar Integridade do Sistema (SFC)", "[3] Restaurar Saude do Sistema (DISM)", "[4] Verificar Drivers com Problemas", "[5] Atualizar Programas (winget)", "[6] Agendar Verificacao de Disco (CHKDSK)", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "MANUTENCAO DO SISTEMA" -Options $subOptions
                if ($subChoice -eq '9') { break }
                switch ($subChoice) {
                    '1' { Execute-Action -Title "VERIFICANDO ATUALIZACOES" -Action { Verificar-Atualizacoes -InstallUpdates } -IsLongRunning }
                    '2' { Execute-Action -Title "VERIFICANDO INTEGRIDADE (SFC)" -Action { sfc /scannow } -IsLongRunning }
                    '3' { Execute-Action -Title "RESTAURANDO SAUDE (DISM)" -Action { DISM /Online /Cleanup-Image /RestoreHealth } -IsLongRunning }
                    '4' { Execute-Action -Title "VERIFICANDO DRIVERS" -Action { Verificar-Drivers } }
                    '5' { Execute-Action -Title "ATUALIZANDO PROGRAMAS (WINGET)" -Action { 
                            if (Get-Command winget -ErrorAction SilentlyContinue) {
                                # Tenta corrigir problemas de configuração
                                Write-Host "[*] Passo 1 de 4: Verificando integridade das fontes do Winget..." -ForegroundColor Cyan
                                try {
                                    winget source reset --force | Out-Null
                                    Write-Host "    > Fontes resetadas para o padrão." -ForegroundColor Gray
                                } catch {
                                    Write-Host "    > Não foi possível resetar as fontes (pode não ser necessário)." -ForegroundColor DarkGray
                                }

                                Write-Host "`n[*] Passo 2 de 4: Atualizando catálogo de softwares..." -ForegroundColor Cyan
                                winget source update

                                Write-Host "`n[*] Passo 3 de 4: Buscando atualizações..." -ForegroundColor Cyan
                                [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

                                # Comando mais limpo para listar apenas o que tem atualizacao
                                $upgrades = winget list --upgrade-available --accept-source-agreements 2>&1

                                if (-not $upgrades) {
                                    Write-Host "[!] O Winget nao retornou nenhuma informacao. Pode haver um erro de conexao ou configuracao." -ForegroundColor Red
                                } else {
                                    $upgrades | Out-Host
                                    $outputString = $upgrades | Out-String

                                    if ($outputString -match "No installed package found" -or $outputString -match "Nenhum pacote instalado corresponde") {
                                        Write-Host "`n[+] Todos os programas estao atualizados!" -ForegroundColor Green
                                    } elseif ($outputString -match "Name" -or $outputString -match "Nome" -or $outputString -match "Id") {
                                        Write-Host "`n[?] Deseja instalar todas as atualizacoes listadas acima? (s/n)" -ForegroundColor Yellow
                                        $resp = Read-Host
                                        if ($resp -eq 's' -or $resp -eq 'S') {
                                            Criar-PontoRestauracao
                                            Write-Host "`n[*] Passo 4 de 4: Instalando atualizacoes..." -ForegroundColor Cyan
                                            winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
                                            Write-Host "`n[+] Processo de atualizacao finalizado." -ForegroundColor Green
                                        } else {
                                            Write-Host "`n[!] Atualizacao cancelada pelo usuario." -ForegroundColor Yellow
                                        }
                                    } else {
                                        Write-Host "`n[!] Nao foi possivel determinar se ha atualizacoes." -ForegroundColor Yellow
                                    }
                                }
                            } else {
                                Write-Host "[!] Winget nao encontrado. Instale o App Installer da Microsoft Store." -ForegroundColor Yellow
                            }
                        } -IsLongRunning }
                    '6' { Execute-Action -Title "AGENDANDO VERIFICACAO DE DISCO" -Action { Verificar-Disco } -IsLongRunning }
                    '8' { Show-HelpScreen -Title "AJUDA: MANUTENCAO" -HelpLines @("[1] Verificar Atualizacoes", "O que faz: Procura e instala updates oficiais do Windows para manter seu sistema seguro.", "Como faz: Tenta usar o modulo 'PSWindowsUpdate'. Se nao disponivel, abre o Windows Update.", "", "[2] Verificar Integridade (SFC)", "O que faz: Verifica se arquivos protegidos do sistema estao corrompidos.", "Como faz: Executa o comando 'sfc /scannow' para encontrar e tentar corrigir arquivos.", "", "[3] Restaurar Saude (DISM)", "O que faz: Repara a 'imagem' do Windows, que e uma copia de seguranca dos arquivos do sistema.", "Como faz: Executa 'DISM /Online /Cleanup-Image /RestoreHealth', que e mais poderoso que o SFC.", "", "[4] Verificar Drivers", "O que faz: Procura por dispositivos de hardware que estao reportando problemas ao Windows.", "Como faz: Consulta o Gerenciador de Dispositivos para encontrar codigos de erro.", "", "[5] Atualizar Programas (winget)", "O que faz: Atualiza todos os programas que voce instalou usando o Gerenciador de Pacotes do Windows.", "Como faz: Executa o comando 'winget upgrade --all' de forma automatica.", "", "[6] Agendar Verificacao de Disco", "O que faz: Agenda uma verificacao completa do seu HD ou SSD para a proxima reinicializacao.", "Como faz: Usa o 'chkdsk /f /r' para encontrar e reparar erros logicos e fisicos no disco.") }
                    default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '2' { # Hardware
            do {
                $subOptions = @("[1] Exibir Resumo de Hardware (CPU, GPU, RAM)", "[2] Status dos Discos e Armazenamento", "[3] Listar Programas Instalados", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "INFORMACOES DE HARDWARE" -Options $subOptions
                if ($subChoice -eq '9') { break }
                switch ($subChoice) {
                    '1' { Execute-Action -Title "RESUMO DE HARDWARE" -Action { Show-HardwareSummary } }
                    '2' { Execute-Action -Title "STATUS DOS DISCOS" -Action { Write-Host "`nDiscos fisicos:" -ForegroundColor Yellow; Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus | Format-Table -AutoSize; Write-Host "Volumes:" -ForegroundColor Yellow; Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | Select-Object DriveLetter, FileSystemLabel, @{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,2)}}, @{Name='FreeGB';Expression={[math]::Round($_.SizeRemaining/1GB,2)}}, @{Name='%Free';Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100,1)}} | Format-Table -AutoSize } }
                    '3' { Execute-Action -Title "PROGRAMAS INSTALADOS" -Action { $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -and $_.DisplayName -notlike "Update*" } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName; Write-Host "[*] Total de programas: $($programs.Count)" -ForegroundColor Cyan; $programs | Format-Table -AutoSize | Out-Host -Paging } }
                    '8' { Show-HelpScreen -Title "AJUDA: HARDWARE" -HelpLines @("[1] Exibir Resumo", "O que faz: Mostra um resumo tecnico dos seus principais componentes: CPU, GPU e RAM.", "Como faz: Coleta e exibe informacoes como modelo, nucleos, velocidade e uso da memoria.", "", "[2] Status dos Discos", "O que faz: Exibe detalhes sobre seus dispositivos de armazenamento.", "Como faz: Mostra seus HDs/SSDs, tipo, saude, e o espaco livre/usado em cada particao.", "", "[3] Programas Instalados", "O que faz: Cria uma lista de todos os programas instalados no seu computador.", "Como faz: Le o registro do Windows para encontrar e exibir todos os aplicativos.") }
                    default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '3' { # Rede
            do {
                $subOptions = @("[1] Configuracao de IP/DNS", "[2] Testar Conectividade Basica", "[3] Testar Velocidade da Internet", "[4] Testar Portas TCP", "[5] Liberar e Renovar Configuracao DHCP", "[6] Analisar Conexoes Ativas", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "DIAGNOSTICO DE REDE" -Options $subOptions
                if ($subChoice -eq '9') { break }
                switch ($subChoice) {
                    '1' { Execute-Action -Title "CONFIGURACAO DE REDE" -Action { Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" } | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-Table -AutoSize } }
                    '2' { Execute-Action -Title "TESTANDO CONECTIVIDADE" -Action { $ping1 = Test-Connection -ComputerName "8.8.8.8" -Count 4 -Quiet; Write-Host "Google DNS (8.8.8.8): $(if($ping1){'[+] OK'}else{'[-] FALHA'})" -ForegroundColor $(if($ping1){'Green'}else{'Red'}); $ping2 = Test-Connection -ComputerName "1.1.1.1" -Count 4 -Quiet; Write-Host "Cloudflare DNS (1.1.1.1): $(if($ping2){'[+] OK'}else{'[-] FALHA'})" -ForegroundColor $(if($ping2){'Green'}else{'Red'}) } }
                    '3' { Execute-Action -Title "TESTE BASICO DE VELOCIDADE" -Action { $url = "http://www.google.com"; $time = Measure-Command { $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 }; if ($response.StatusCode -eq 200) { Write-Host "[+] Conexao ativa - Tempo de resposta: $($time.TotalMilliseconds) ms" -ForegroundColor Green } } }
                    '4' { Execute-Action -Title "TESTE DE PORTA TCP" -Action { $hostname = Read-Host "Digite o host ou IP"; $port = Read-Host "Digite a porta"; if ($hostname -and $port) { Write-Host "[*] Testando $hostname`:$port..." -ForegroundColor Yellow; $result = Test-NetConnection -ComputerName $hostname -Port $port -WarningAction SilentlyContinue; if ($result.TcpTestSucceeded) { Write-Host "[+] Porta $port esta aberta em $hostname" -ForegroundColor Green } else { Write-Host "[-] Porta $port esta fechada ou filtrada em $hostname" -ForegroundColor Red } } } }
                    '5' { Execute-Action -Title "RENOVANDO CONFIGURACAO DE REDE" -Action { ipconfig /flushdns; ipconfig /release; ipconfig /renew } -IsLongRunning }
                    '6' { Execute-Action -Title "ANALISANDO CONEXOES ATIVAS" -Action { Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{Name='Process';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | Sort-Object Process | Format-Table -AutoSize | Out-Host -Paging } }
                    '8' { Show-HelpScreen -Title "AJUDA: REDE" -HelpLines @("[1] Configuracao de IP/DNS", "O que faz: Mostra suas configuracoes de rede atuais, como seu 'endereco' na rede local.", "Como faz: Exibe seu endereco IP, o 'portao' de saida para a internet (gateway) e os servidores DNS.", "", "[2] Testar Conectividade", "O que faz: Testa se seu computador consegue se comunicar com a internet de forma eficaz.", "Como faz: Envia um sinal (ping) para servidores confiaveis (Google) para ver se eles respondem.", "", "[3] Testar Velocidade", "O que faz: Realiza um teste basico de velocidade para medir o tempo de resposta da sua conexao.", "Como faz: Baixa um pequeno arquivo da internet e calcula a velocidade com base no tempo que levou.", "", "[4] Testar Portas TCP", "O que faz: Verifica se uma 'porta' de comunicacao (ex: 80 para web) esta aberta em um servidor.", "Como faz: Tenta estabelecer uma conexao com o site/servidor e a porta que voce informar.", "", "[5] Renovar Configuracao DHCP", "O que faz: Tenta resolver problemas de conexao 'resetando' suas configuracoes de rede.", "Como faz: Limpa o cache DNS e pede um novo endereco IP ao seu roteador.", "", "[6] Analisar Conexoes Ativas", "O que faz: Mostra em tempo real quais programas no seu PC estao usando a internet.", "Como faz: Lista todas as conexoes de rede ativas e qual processo (programa) e o responsavel.") }
                    default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '4' { # Limpeza
            do {
                $subOptions = @("[1] Limpeza Basica de Arquivos Temporarios", "[2] Limpeza Avancada com Storage Sense", "[3] Limpar Cache de Pre-carregamento (Prefetch)", "[4] Limpar Cache de Thumbnails e Icones", "[5] Limpar Historico de Documentos Recentes", "[6] Limpeza Completa (todas as opcoes)", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "FERRAMENTAS DE LIMPEZA" -Options $subOptions
                if ($subChoice -eq '9') { break }
                switch ($subChoice) {
                    '1' { Execute-Action -Title "LIMPEZA BASICA" -Action { Limpeza-Avancada -IncludeTempFiles } -IsLongRunning }
                    '2' { Execute-Action -Title "ABRINDO STORAGE SENSE" -Action { Start-Process "ms-settings:storagesense" } }
                    '3' { Execute-Action -Title "LIMPANDO PREFETCH" -Action { Limpeza-Avancada -IncludePrefetch } }
                    '4' { Execute-Action -Title "LIMPANDO CACHES VISUAIS" -Action { Limpeza-Avancada -IncludeThumbnails } }
                    '5' { Execute-Action -Title "LIMPANDO ARQUIVOS RECENTES" -Action { Limpeza-Avancada -IncludeRecentFiles } }
                    '6' { Execute-Action -Title "LIMPEZA COMPLETA" -Action { Limpeza-Avancada -IncludeTempFiles -IncludeThumbnails -IncludePrefetch -IncludeLogs -IncludeRecentFiles } -IsLongRunning }
                    '8' { Show-HelpScreen -Title "AJUDA: LIMPEZA" -HelpLines @("[1] Limpeza Basica", "O que faz: Remove 'lixo' digital que os programas e o sistema criam e que se acumula com o tempo.", "Como faz: Apaga de forma segura o conteudo das pastas temporarias do usuario e do sistema.", "", "[2] Limpeza Avancada (Storage Sense)", "O que faz: Abre a ferramenta oficial do Windows para uma limpeza de disco mais controlada.", "Como faz: Executa o atalho 'ms-settings:storagesense' para voce gerenciar o armazenamento.", "", "[3] Limpar Prefetch", "O que faz: Limpa um cache que o Windows usa para tentar acelerar o carregamento de programas.", "Como faz: Apaga os arquivos da pasta Prefetch. O Windows os recria automaticamente.", "", "[4] Limpar Caches Visuais", "O que faz: Remove o cache de miniaturas de imagens e icones, que pode corromper.", "Como faz: Apaga os bancos de dados de cache, forcando o Windows a recria-los.", "", "[5] Limpar Recentes", "O que faz: Limpa a lista de 'Acesso Rapido' e documentos recentes do Explorador de Arquivos.", "Como faz: Apaga os atalhos na pasta 'Recent'. Seus arquivos originais ficam intactos.", "", "[6] Limpeza Completa", "O que faz: Executa todas as acoes de limpeza listadas acima (exceto Storage Sense) de uma so vez.", "Como faz: Chama sequencialmente as funcoes de limpeza de temporarios, prefetch, etc.") }
                    default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '5' { # Otimizacao
            do {
                $subOptions = @("[1] Otimizar Unidades de Disco", "[2] Desfragmentar HDDs", "[3] Executar TRIM em SSDs", "[4] Ajustar Configuracoes de Energia", "[5] Analisar Servicos Nao Essenciais", "[6] Otimizacao Completa", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "OTIMIZACAO AVANCADA" -Options $subOptions
                if ($subChoice -eq '9') { break }
                switch ($subChoice) {
                    '1' { Execute-Action -Title "OTIMIZANDO UNIDADES" -Action { Otimizacao-Sistema -OptimizeDrives } -IsLongRunning }
                    '2' { Execute-Action -Title "DESFRAGMENTANDO HDDS" -Action { Otimizacao-Sistema -Defrag } -IsLongRunning }
                    '3' { Execute-Action -Title "EXECUTANDO TRIM EM SSDS" -Action { Otimizacao-Sistema -TrimSSD } -IsLongRunning }
                    '4' { Execute-Action -Title "AJUSTANDO ENERGIA" -Action { Write-Host "[*] Planos de energia disponiveis:" -ForegroundColor Yellow; powercfg /list; Write-Host "`n[i] Para alterar para Alto Desempenho, use o comando abaixo:" -ForegroundColor Blue; Write-Host "powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -ForegroundColor Gray; $response = Read-Host "`nDefinir para Alto Desempenho? (s/n)"; if ($response -eq 's') { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; Write-Host "[+] Plano alterado" -ForegroundColor Green } } }
                    '5' { Execute-Action -Title "ANALISANDO SERVICOS" -Action { Write-Host "[!] CUIDADO: Nao desative servicos sem conhecimento tecnico!" -ForegroundColor Red; Write-Host "`n[*] Servicos automaticos que estao parados:" -ForegroundColor Yellow; Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -eq "Stopped" } | Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize } }
                    '6' { Execute-Action -Title "OTIMIZACAO COMPLETA" -Action { Otimizacao-Sistema -OptimizeDrives -TrimSSD } -IsLongRunning }
                    '8' { Show-HelpScreen -Title "AJUDA: OTIMIZACAO" -HelpLines @("[1] Otimizar Unidades", "O que faz: Analisa e executa a otimizacao padrao do Windows para seus discos.", "Como faz: Executa 'Optimize-Volume', que aplica desfragmentacao para HDDs e TRIM para SSDs.", "", "[2] Desfragmentar HDDs", "O que faz: Reorganiza os 'pedacos' de arquivos em discos rigidos (HDDs) para acelerar a leitura.", "Como faz: Identifica os discos do tipo HDD e executa uma otimizacao focada neles.", "", "[3] Executar TRIM em SSDs", "O que faz: Melhora o desempenho e a vida util do seu SSD.", "Como faz: Avisa ao SSD quais blocos de dados podem ser apagados, agilizando futuras gravacoes.", "", "[4] Ajustar Energia", "O que faz: Permite que voce altere o plano de energia do Windows para focar em desempenho maximo.", "Como faz: Lista os planos e oferece a opcao de ativar o plano de 'Alto Desempenho'.", "", "[5] Analisar Servicos", "O que faz: Mostra servicos que iniciam com o Windows, mas que estao parados.", "Como faz: Filtra a lista de servicos para encontrar possiveis otimizacoes (uso avancado).", "", "[6] Otimizacao Completa", "O que faz: Executa as principais otimizacoes de disco de forma automatica.", "Como faz: Roda a otimizacao padrao e o comando TRIM nos discos apropriados.") }
                    default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '6' { # Relatorios
            do {
                $subOptions = @("[1] Gerar Relatorio do Sistema (HTML)", "[2] Exportar Lista de Drivers (CSV)", "[3] Exportar Programas Instalados (TXT)", "[4] Salvar Configuracao de Rede (TXT)", "[5] Criar Dump Completo do Sistema (TXT)", "[6] Analisar Integridade do Sistema", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "RELATORIOS E DIAGNOSTICOS" -Options $subOptions
                if ($subChoice -eq '9') { break }
                switch ($subChoice) {
                    '1' { Execute-Action -Title "GERANDO RELATORIO HTML" -Action { Criar-Relatorio } }
                    '2' { Execute-Action -Title "EXPORTANDO DRIVERS" -Action { Get-CimInstance Win32_SystemDriver | Export-Csv "$env:USERPROFILE\Desktop\Drivers_$(Get-Date -f yyyy-MM-dd).csv" -NoTypeInformation -Encoding UTF8 } }
                    '3' { Execute-Action -Title "EXPORTANDO PROGRAMAS" -Action { Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion | Out-File "$env:USERPROFILE\Desktop\Programas_$(Get-Date -f yyyy-MM-dd).txt" } }
                    '4' { Execute-Action -Title "SALVANDO CONFIGURACAO DE REDE" -Action { ipconfig /all | Out-File "$env:USERPROFILE\Desktop\Rede_$(Get-Date -f yyyy-MM-dd).txt" } }
                    '5' { Execute-Action -Title "CRIANDO DUMP DO SISTEMA" -Action { $folder = "$env:USERPROFILE\Desktop\SysBot_Dump_$(Get-Date -f yyyy-MM-dd_HH-mm)"; New-Item -ItemType Directory -Path $folder -Force | Out-Null; systeminfo | Out-File "$folder\systeminfo.txt"; Get-Process | Out-File "$folder\processes.txt"; Get-Service | Out-File "$folder\services.txt" } -IsLongRunning }
                    '6' { Execute-Action -Title "ANALISANDO INTEGRIDADE" -Action { $results = @(); sfc /verifyonly; if ($LASTEXITCODE -eq 0) { $results += "[+] SFC: Sistema integro" } else { $results += "[!] SFC: Problemas encontrados" }; $dismResult = DISM /Online /Cleanup-Image /ScanHealth; if ($dismResult -match "nenhuma corrupcao") { $results += "[+] DISM: Imagem integra" } else { $results += "[!] DISM: Possiveis problemas encontrados" }; $problemDrivers = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }; if ($problemDrivers) { $results += "[!] DRIVERS: $($problemDrivers.Count) dispositivos com problemas" } else { $results += "[+] DRIVERS: Todos funcionando corretamente" }; Write-Host "`n=== RESULTADOS DA ANALISE ===" -ForegroundColor Cyan; $results | ForEach-Object { $color = if ($_ -match '\[\+\]') { 'Green' } elseif ($_ -match '\[\!\]') { 'Yellow' } else { 'Red' }; Write-Host $_ -ForegroundColor $color } } -IsLongRunning }
                    '8' { Show-HelpScreen -Title "AJUDA: RELATORIOS" -HelpLines @("[1] Gerar Relatorio (HTML)", "O que faz: Cria um relatorio visual e organizado sobre seu sistema em um unico arquivo HTML.", "Como faz: Coleta informacoes e as formata em uma pagina web na sua Area de Trabalho.", "", "[2] Exportar Drivers (CSV)", "O que faz: Cria uma planilha (CSV) com uma lista tecnica de todos os drivers do seu sistema.", "Como faz: Exporta a lista para um arquivo que pode ser aberto no Excel ou Google Sheets.", "", "[3] Exportar Programas (TXT)", "O que faz: Cria um arquivo de texto simples com a lista de todos os seus programas.", "Como faz: Salva a lista de programas instalados em um arquivo .txt na sua Area de Trabalho.", "", "[4] Salvar Configuracao de Rede", "O que faz: Gera um arquivo de texto com um diagnostico completo e tecnico da sua rede.", "Como faz: Executa 'ipconfig /all' e outros comandos, salvando a saida em um arquivo.", "", "[5] Criar Dump do Sistema", "O que faz: Cria uma pasta com varios relatorios detalhados para diagnostico avancado.", "Como faz: Exporta varias informacoes tecnicas para arquivos de texto separados.", "", "[6] Analisar Integridade", "O que faz: Executa uma verificacao rapida da saude geral do sistema.", "Como faz: Roda SFC, DISM e verificacao de drivers em modo 'leitura', e exibe um resumo.") }
                    default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '7' { # Auditoria de Seguranca
            do {
                $subOptions = @("[1] Verificar Status do Firewall", "[2] Verificar Status do Antivirus", "[3] Listar Programas que Iniciam com o Sistema", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "AUDITORIA DE SEGURANCA" -Options $subOptions
                if ($subChoice -eq '9') { break }
                switch ($subChoice) {
                    '1' { Execute-Action -Title "STATUS DO FIREWALL" -Action { Verificar-Firewall } }
                    '2' { Execute-Action -Title "STATUS DO ANTIVIRUS" -Action { Verificar-Antivirus } }
                    '3' { Execute-Action -Title "PROGRAMAS NA INICIALIZACAO" -Action { Listar-ProgramasInicializacao } }
                    '8' { Show-HelpScreen -Title "AJUDA: SEGURANCA" -HelpLines @("[1] Verificar Status do Firewall", "O que faz: Verifica se o Firewall do Windows esta ativo para proteger sua rede.", "Como faz: Checa os perfis de rede (Publica, Privada, Dominio) e informa se algum esta desativado.", "", "[2] Verificar Status do Antivirus", "O que faz: Confere se ha um programa de antivirus ativo e atualizado.", "Como faz: Usa a Central de Seguranca do Windows para identificar o antivirus e seu estado.", "", "[3] Listar Programas na Inicializacao", "O que faz: Mostra os programas configurados para iniciar junto com o Windows.", "Como faz: Lista os programas que podem impactar o tempo de boot e o desempenho.") }
                    default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '8' { # Gerenciador de Desenvolvimento
            do {
                $subOptions = @("--- INSTALAR FERRAMENTAS ---", "[1] Gerenciar Python 3", "[2] Gerenciar Java (JDK)", "[3] Gerenciar Git", "[4] Gerenciar Visual Studio Code", "[5] Gerenciar NodeJS (LTS)", "", "--- VERIFICAR VERSOES ---", "[v1] Verificar todas as versoes", "", "[h] AJUDA: O que estas funcoes fazem?", "[0] Voltar ao Menu Principal")
                $subChoice = Show-Menu -Title "GERENCIADOR DE DESENVOLVIMENTO" -Options $subOptions
                if ($subChoice -eq '0') { break }
                switch ($subChoice) {
                    '1' { Manage-DevTool -ToolName "Python" -WingetId "Python.Python.3" -ExecutableName "python.exe" -VersionArgument "--version" }
                    '2' { Manage-DevTool -ToolName "Java" -WingetId "Oracle.JDK.21" -ExecutableName "java.exe" -VersionArgument "-version" }
                    '3' { Manage-DevTool -ToolName "Git" -WingetId "Git.Git" -ExecutableName "git.exe" -VersionArgument "--version" }
                    '4' { Manage-DevTool -ToolName "Visual Studio Code" -WingetId "Microsoft.VisualStudioCode" -ExecutableName "code.exe" -VersionArgument "--version" }
                    '5' { Manage-DevTool -ToolName "NodeJS" -WingetId "OpenJS.NodeJS.LTS" -ExecutableName "node.exe" -VersionArgument "--version" }
                    'v1' { 
                        Execute-Action -Title "VERIFICANDO VERSOES" -Action {
                            Manage-DevTool -ToolName "Python" -ExecutableName "python.exe" -VersionArgument "--version" -NoInstall
                            Manage-DevTool -ToolName "Java" -ExecutableName "java.exe" -VersionArgument "-version" -NoInstall
                            Manage-DevTool -ToolName "Git" -ExecutableName "git.exe" -VersionArgument "--version" -NoInstall
                        }
                    }
                    'h' { Show-HelpScreen -Title "AJUDA: DEV TOOLS" -HelpLines @("[1-5] Gerenciar Ferramentas", "O que faz: Verifica se uma ferramenta (Python, Java, etc.) esta instalada e mostra sua versao.", "Como faz: Se estiver instalada, pergunta se voce deseja reinstalar/atualizar. Se nao, pergunta se deseja instalar via winget.", "", "[v1] Verificar todas as versoes", "O que faz: Executa uma verificacao rapida de versao para Python, Java e Git.", "Como faz: Roda os comandos de versao de cada ferramenta e exibe o resultado.") }
                    default { if ($subChoice -ne '0') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
                }
            } while ($true)
        }
        '9' { Show-HelpScreen -Title "AJUDA GERAL" -HelpLines @("[1] Manutencao do Sistema", "    Executa tarefas essenciais para manter o sistema saudavel.", "", "[2] Informacoes de Hardware", "    Mostra detalhes sobre os componentes do seu computador.", "", "[3] Diagnostico de Rede", "    Ferramentas para verificar sua conexao com a internet.", "", "[4] Ferramentas de Limpeza", "    Libera espaco em disco removendo arquivos desnecessarios.", "", "[5] Otimizacao Avancada", "    Executa acoes para melhorar o desempenho do sistema.", "", "[6] Relatorios e Diagnosticos", "    Gera relatorios completos sobre o estado do seu sistema.", "", "[7] Auditoria de Seguranca", "    Verifica configuracoes basicas de seguranca do seu PC.", "", "[8] Gerenciador de Desenvolvimento", "    Instala e verifica ferramentas populares para programacao.") }
        '0' { Write-Host "`nEncerrando SysBot. Ate logo!" -ForegroundColor Green; Stop-Transcript; Start-Sleep -Seconds 1; exit }
        default { Write-Host "`n[-] Opcao invalida. Tente novamente." -ForegroundColor Red; Pausar }
    }
} while ($true)

Stop-Transcript
