# --- Configuracoes Iniciais ---
#Requires -Version 5.1
#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-StrictMode -Version Latest

# --- Configuracoes Globais ---
$script:DaysForOldLogs = 30
$script:LowDiskSpaceThreshold = 15
$script:LogDirectory = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "SysBot\logs"
$script:DesktopDirectory = [Environment]::GetFolderPath("DesktopDirectory")

# --- Tema Visual (Retro-Moderno) ---
$script:Theme = @{
    # Status Icons (usando caracteres ASCII compatíveis)
    Success = "[OK]"
    Error = "[!!]"
    Warning = "[!]"
    Info = "[*]"
    Bullet = ">"
    Gear = "[*]"
    Lock = "[L]"
    Chart = "[#]"
    
    # Separators
    ThinLine = "-"
    ThickLine = "="
    Cross = "+"
    TLeft = "+"
    TRight = "+"
    BLeft = "+"
    BRight = "+"
    TJoin = "+"
    BJoin = "+"
    VBar = "|"
    
    # Colors
    ColorSuccess = "Green"
    ColorError = "Red"
    ColorWarning = "Yellow"
    ColorInfo = "Cyan"
    ColorAccent = "Magenta"
    ColorMuted = "Gray"
}

# --- Gerenciamento de Logs ---
if ($env:OS -ne "Windows_NT") { throw "SysBot requer Windows." }
if ($PSVersionTable.PSEdition -ne "Desktop") { throw "Use Windows PowerShell 5.1 (powershell.exe)." }
if ([Environment]::OSVersion.Version.Major -lt 10) { throw "SysBot requer Windows 10 ou 11." }
New-Item -ItemType Directory -Path $script:LogDirectory -Force | Out-Null
$logFile = Join-Path $script:LogDirectory ("SysBot-Log_{0}_{1}.txt" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"), $PID)
Start-Transcript -LiteralPath $logFile | Out-Null

# ==============================================================================================
#                                   FUNCOES DE UI E CORE
# ==============================================================================================

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Pausar {
    [void](Read-Host "Pressione Enter para voltar ao menu")
}

function Write-StatusLine {
    param(
        [string]$Status,
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $icon = switch ($Type) {
        "Success" { $script:Theme.Success }
        "Error" { $script:Theme.Error }
        "Warning" { $script:Theme.Warning }
        default { $script:Theme.Info }
    }
    
    $color = switch ($Type) {
        "Success" { $script:Theme.ColorSuccess }
        "Error" { $script:Theme.ColorError }
        "Warning" { $script:Theme.ColorWarning }
        default { $script:Theme.ColorInfo }
    }
    
    Write-Host "$icon $Status" -ForegroundColor $color -NoNewline
    if ($Message) {
        Write-Host " : $Message" -ForegroundColor White
    } else {
        Write-Host ""
    }
}

function Write-Separator {
    param([int]$Width = 92, [string]$Style = "thin")
    
    if ($Style -eq "thick") {
        Write-Host ($script:Theme.ThickLine * ($Width + 4)) -ForegroundColor $script:Theme.ColorAccent
    } else {
        Write-Host ($script:Theme.ThinLine * ($Width + 4)) -ForegroundColor $script:Theme.ColorMuted
    }
}

function Write-Header {
    param([string]$Text, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host "  +=======================================================+" -ForegroundColor $Color
    Write-Host "  |  $($Text.PadRight(49))  |" -ForegroundColor $Color
    Write-Host "  +=======================================================+" -ForegroundColor $Color
    Write-Host ""
}

function Write-Footer {
    param([string]$Color = "Cyan")
    Write-Host "  +=======================================================+" -ForegroundColor $Color
    Write-Host ""
}

function Write-Success {
    param([string]$Message, [string]$Indent = "")
    Write-StatusLine -Status "OK" -Message $Message -Type "Success"
}

function Write-SysError {
    param([string]$Message, [string]$Indent = "")
    Write-StatusLine -Status "ERRO" -Message $Message -Type "Error"
}

function Write-SysWarning {
    param([string]$Message, [string]$Indent = "")
    Write-StatusLine -Status "AVISO" -Message $Message -Type "Warning"
}

function Write-Info {
    param([string]$Message, [string]$Indent = "")
    Write-StatusLine -Status "INFO" -Message $Message -Type "Info"
}

function Show-ProgressMessage {
    param([string]$Message)
    Write-Host "$($script:Theme.Gear) $Message" -ForegroundColor $script:Theme.ColorInfo
}

function Draw-Box {
    param(
        [int]$Width = 92,
        [string]$Title = "",
        [string]$TitleColor = "Green",
        [string]$BorderColor = "Cyan",
        [switch]$Modern
    )
    if ($Modern) {
        # MODERNO: Usando caracteres Unicode
        $topLeft = $script:Theme.TLeft
        $topRight = $script:Theme.TRight
        $bottomLeft = $script:Theme.BLeft
        $bottomRight = $script:Theme.BRight
        $horizontal = $script:Theme.ThickLine
    } else {
        # RETRO: ASCII puro
        $topLeft = "+"
        $topRight = "+"
        $bottomLeft = "+"
        $bottomRight = "+"
        $horizontal = "-"
    }
    
    $line = $topLeft + ($horizontal * ($Width + 2)) + $topRight
    
    if ($Title) {
        $paddedTitle = $Title.PadLeft(((($Width - 2) - $Title.Length) / 2) + $Title.Length).PadRight($Width - 2)
        Write-Host $line -ForegroundColor $BorderColor
        Write-Host "║ $($paddedTitle) ║" -ForegroundColor $TitleColor
        Write-Host $line -ForegroundColor $BorderColor
    } else {
        Write-Host $line -ForegroundColor $BorderColor
    }
}

function Show-Menu {
    param([string]$Title, [array]$Options, [hashtable]$Status)
    Clear-Host
    Write-Host "SysBot | Manutencao e diagnostico do Windows" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Green
    Write-Host ""
    if ($Status) {
        Write-Host "Status: $($Status.Text)" -ForegroundColor $Status.Color
        foreach ($reason in $Status.Reasons) { Write-Host " - $reason" -ForegroundColor Yellow }
        Write-Host ""
    }
    foreach ($option in $Options) { Write-Host "  $option" -ForegroundColor Yellow }
    if ($Title -eq "MENU PRINCIPAL") {
        Write-Host ""
        Write-Host "Desenvolvido por Moacir Pereira | github.com/MoacirJr10/SysBot"
        Write-Host "Sugestoes e contribuicoes sao bem-vindas."
        Write-Host "Log: $logFile" -ForegroundColor Gray
    }
    return (Read-Host "Escolha uma opcao").Trim()
}

function Invoke-SysNative {
    param([Parameter(Mandatory)][string]$Name, [string[]]$Arguments = @(), [int[]]$AllowedExitCodes = @(0))
    $command = Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1
    & $command.Source @Arguments
    $exitCode = $LASTEXITCODE
    if ($AllowedExitCodes -notcontains $exitCode) {
        throw "$Name retornou codigo $exitCode. Consulte a saida e o log."
    }
    if ($exitCode -ne 0) {
        Write-SysWarning "$Name retornou codigo $exitCode; consulte a saida para interpretar o resultado."
    }
}

function Confirm-SysAction {
    param([string]$Message)
    return ((Read-Host "$Message (s/N)") -eq "s")
}

function Execute-Action {
    param(
        [string]$Title,
        [scriptblock]$Action,
        [switch]$IsLongRunning
    )
    Clear-Host
    
    Write-Host ""
    Write-Header ">> $Title" -Color "Magenta"
    
    if ($IsLongRunning) {
        Write-Host "$($script:Theme.Bullet) Esta operacao pode levar varios minutos. Por favor, aguarde..." -ForegroundColor $script:Theme.ColorInfo
        Write-Host ""
    }

    try {
        & $Action
        Write-Host ""
        Write-Info "Rotina encerrada. Consulte os resultados acima."
    } catch {
        Write-Host ""
        Write-SysError "Ocorreu um erro durante a execucao."
        Write-Host "   Detalhes: $($_.Exception.Message)" -ForegroundColor $script:Theme.ColorMuted
    }
    
    Write-Footer -Color "Magenta"
    Pausar
}

function Show-HelpScreen {
    param([string]$Title, [array]$HelpLines)
    Clear-Host
    
    Write-Header $Title -Color "Cyan"
    Write-Host ""

    foreach($line in $HelpLines) {
        if ($line.StartsWith("[")) {
            Write-Host "  $($script:Theme.Bullet) " -NoNewline -ForegroundColor $script:Theme.ColorAccent
            Write-Host $line -ForegroundColor Yellow
        } elseif ($line -eq "") {
            Write-Host ""
        } else {
            Write-Host "    $line" -ForegroundColor Gray
        }
    }
    
    Write-Footer -Color "Cyan"
    Pausar
}

# ==============================================================================================
#                                   FUNCOES DE LOGICA (BACKEND)
# ==============================================================================================

function Criar-PontoRestauracao {
    Show-ProgressMessage "Tentando criar um Ponto de Restauracao do Sistema..."
    try {
        $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "SysBot_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Success "Ponto de restauracao criado com sucesso!"
    } catch {
        Write-SysWarning "Nao foi possivel criar o ponto de restauracao."
        Write-Host "   Motivo: $($_.Exception.Message)" -ForegroundColor $script:Theme.ColorMuted
        Write-Host "   Dica: Verifique se a 'Protecao do Sistema' esta ativada no Windows." -ForegroundColor $script:Theme.ColorMuted
        Start-Sleep -Seconds 2
    }
}

function Get-SystemStatus {
    $reasons = @()
    $unknown = @()
    try {
        $volume = Get-Volume -DriveLetter $env:SystemDrive.Substring(0,1) -ErrorAction Stop
        if ($volume.Size -le 0) { throw "Tamanho indisponivel" }
        $free = [math]::Round(100 * $volume.SizeRemaining / $volume.Size, 1)
        if ($free -lt $script:LowDiskSpaceThreshold) { $reasons += "$($env:SystemDrive) com $free% livre." }
    } catch { $unknown += "Nao foi possivel consultar espaco livre." }
    try {
        $updates = @(Get-CimInstance Win32_QuickFixEngineering -ErrorAction Stop | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending)
        if ($updates.Count -eq 0) { $unknown += "Historico de hotfixes indisponivel." }
        elseif ([datetime]$updates[0].InstalledOn -lt (Get-Date).AddDays(-30)) { $reasons += "Ultimo hotfix registrado ha mais de 30 dias; verifique Windows Update." }
    } catch { $unknown += "Falha ao consultar historico de hotfixes." }
    try {
        if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -or
            (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")) {
            $reasons += "Reinicio pendente detectado."
        }
    } catch { $unknown += "Nao foi possivel consultar reinicio pendente." }
    $status = @{ Text = "SEM ALERTAS NAS CHECAGENS BASICAS"; Color = "Green"; Reasons = @() }
    if ($reasons.Count -gt 0) { $status.Text = "ATENCAO NECESSARIA"; $status.Color = "Yellow" }
    elseif ($unknown.Count -gt 0) { $status.Text = "DIAGNOSTICO INCOMPLETO"; $status.Color = "Yellow" }
    $status.Reasons = @($reasons + $unknown)
    return $status
}

function Verificar-Atualizacoes {
    param([switch]$InstallUpdates)
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-SysWarning "PSWindowsUpdate nao instalado. Abrindo Windows Update; nenhuma instalacao automatica foi realizada."
        Start-Process "ms-settings:windowsupdate"
        return
    }
    Import-Module PSWindowsUpdate -ErrorAction Stop
    $updates = @(Get-WindowsUpdate -ErrorAction Stop)
    if ($updates.Count -eq 0) { Write-Info "Nenhuma atualizacao retornada pela consulta."; return }
    $updates | Format-Table -AutoSize | Out-Host
    if ($InstallUpdates -and (Confirm-SysAction "Instalar atualizacoes disponiveis sem reiniciar automaticamente?")) {
        Criar-PontoRestauracao
        Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop
        Write-Info "Confira o resultado de cada atualizacao e o eventual reinicio pendente."
    } else { Write-Info "Nenhuma instalacao solicitada." }
}

function Verificar-Drivers {
    $drivers = @(Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 })
    if ($drivers) {
        Write-SysWarning "Drivers com problemas encontrados:"
        $drivers | Select-Object Name, DeviceID | Format-Table -AutoSize
    } else { Write-Success "Todos os drivers estao funcionando corretamente" }
}

function Verificar-Disco {
    $drives = @(Get-Volume | Where-Object { $_.DriveType -eq "Fixed" -and $_.DriveLetter -and $_.FileSystem -eq "NTFS" })
    if (-not $drives.Count) { Write-SysWarning "Nenhum volume NTFS fixo encontrado."; return }
    foreach ($drive in $drives) {
        $letter = "$($drive.DriveLetter):"
        Write-Info "Verificacao online de $letter (sem /f ou /r)"
        Invoke-SysNative -Name "$env:SystemRoot\System32\chkdsk.exe" -Arguments @($letter, "/scan") -AllowedExitCodes @(0,1,2,3)
    }
    Write-Info "Nenhum reparo offline ou reinicio foi solicitado pelo SysBot."
}

function Show-HardwareSummary {
    Write-Header "[CPU] Processador" -Color "Cyan"
    Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List
    
    Write-Header "[GPU] Placa de Video" -Color "Cyan"
    Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Basic*" } | Select-Object Name, DriverVersion, @{Name='VRAM(MB)';Expression={[math]::Round($_.AdapterRAM/1MB,0)}} | Format-Table -AutoSize
    
    Write-Header "[RAM] Memoria" -Color "Cyan"
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $totalMem = $osInfo.TotalVisibleMemorySize; $freeMem = $osInfo.FreePhysicalMemory; $usedMem = $totalMem - $freeMem
    $totalRAM_GB = [math]::Round($totalMem / 1MB, 2); $usedPercent = [math]::Round(($usedMem / $totalMem) * 100, 2)
    Write-Host "Total de RAM: $totalRAM_GB GB" -ForegroundColor Yellow
    Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, @{Name="Capacidade(GB)";Expression={[math]::Round($_.Capacity / 1GB, 2)}}, Speed, Manufacturer | Format-Table -AutoSize
    Write-Host "Uso atual: $usedPercent%" -ForegroundColor $(if ($usedPercent -gt 80) { 'Red' } else { 'Green' })
}

function Test-SafeCleanupFolder {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not [IO.Path]::IsPathRooted($Path)) { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    $folder = Get-Item -LiteralPath $Path -Force
    if ($null -eq $folder.Parent) { return $false }
    while ($null -ne $folder) {
        if ($folder.Attributes -band [IO.FileAttributes]::ReparsePoint) { return $false }
        $folder = $folder.Parent
    }
    return $true
}

function Limpeza-Avancada {
    param([switch]$IncludeTempFiles, [switch]$IncludePrefetch, [switch]$IncludeThumbnails, [switch]$IncludeRecentFiles, [switch]$IncludeLogs)
    $local = [Environment]::GetFolderPath("LocalApplicationData")
    $windows = [Environment]::GetFolderPath("Windows")
    $recent = [Environment]::GetFolderPath("Recent")
    $targets = @()
    if ($IncludeTempFiles) {
        if ($local) { $targets += @{ Path = (Join-Path $local "Temp"); Filter = "*"; Days = 2 } }
        if ($windows) { $targets += @{ Path = (Join-Path $windows "Temp"); Filter = "*"; Days = 2 } }
    }
    if ($IncludePrefetch) { Write-SysWarning "Prefetch preservado: o Windows gerencia esse cache." }
    if ($IncludeThumbnails -and $local) { $targets += @{ Path = (Join-Path $local "Microsoft\Windows\Explorer"); Filter = "thumbcache_*.db"; Days = 2 } }
    if ($IncludeRecentFiles -and $recent) { $targets += @{ Path = $recent; Filter = "*.lnk"; Days = 2 } }
    if ($IncludeLogs) { $targets += @{ Path = $script:LogDirectory; Filter = "SysBot-Log_*.txt"; Days = $script:DaysForOldLogs } }
    $candidates = @()
    $failed = 0
    foreach ($target in $targets) {
        try {
            if (-not (Test-SafeCleanupFolder $target.Path)) { Write-SysWarning "Pasta ausente ou nao segura: $($target.Path)"; continue }
            $candidates += @(Get-ChildItem -LiteralPath $target.Path -Filter $target.Filter -File -Force |
                Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $_.LastWriteTime -lt (Get-Date).AddDays(-$target.Days) -and $_.FullName -ne $logFile })
        } catch { $failed++; Write-SysWarning "Falha de leitura em $($target.Path): $($_.Exception.Message)" }
    }
    $candidates = @($candidates | Sort-Object FullName -Unique)
    Write-Info "$($candidates.Count) arquivos candidatos. Apenas o nivel direto das pastas; sem apagar diretorios ou logs do Windows."
    if (-not $candidates.Count) { return }
    if (-not (Confirm-SysAction "Remover os arquivos candidatos?")) { Write-Info "Limpeza cancelada."; return }
    [long]$bytes = 0
    $removed = 0
    foreach ($candidate in $candidates) {
        try {
            if (-not (Test-SafeCleanupFolder $candidate.DirectoryName)) { throw "Pasta deixou de ser segura." }
            $item = Get-Item -LiteralPath $candidate.FullName -Force
            if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Tipo de arquivo alterado." }
            if ($item.LastWriteTime -ne $candidate.LastWriteTime -or $item.Length -ne $candidate.Length) { throw "Arquivo alterado desde a consulta." }
            $length = $item.Length
            Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
            $bytes += $length
            $removed++
        } catch { $failed++; Write-SysWarning "Ignorado: $($candidate.FullName) - $($_.Exception.Message)" }
    }
    Write-Info ("Removidos: {0}; falhas/ignorados: {1}; tamanho logico removido: {2:N2} MiB" -f $removed,$failed,($bytes / 1MB))
}

function Otimizacao-Sistema {
    param([switch]$OptimizeDrives, [switch]$Defrag, [switch]$TrimSSD)
    $volumes = @(Get-Volume | Where-Object { $_.DriveType -eq "Fixed" -and $_.DriveLetter -and $_.HealthStatus -eq "Healthy" -and $_.FileSystem -eq "NTFS" })
    if (-not $volumes.Count) { Write-SysWarning "Nenhum volume NTFS fixo e saudavel encontrado."; return }
    if (-not (Confirm-SysAction "Executar operacao de armazenamento nas unidades elegiveis?")) { Write-Info "Cancelado."; return }
    foreach ($volume in $volumes) {
        $letter = $volume.DriveLetter
        if ($OptimizeDrives) {
            # Windows seleciona a operacao apropriada para a midia.
            Invoke-SysNative -Name "$env:SystemRoot\System32\defrag.exe" -Arguments @("$($letter):", "/O", "/U", "/V")
            continue
        }
        $type = "Unknown"
        try {
            $partition = Get-Partition -DriveLetter $letter -ErrorAction Stop
            $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction Stop
            if ($disk.UniqueId) {
                $physical = @(Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.UniqueId -and $_.UniqueId -eq $disk.UniqueId })
                if ($physical.Count -eq 1) { $type = [string]$physical[0].MediaType }
            }
        } catch { Write-SysWarning "Nao foi possivel mapear $($letter): ao disco fisico." }
        if ($Defrag -and $type -eq "HDD") { Optimize-Volume -DriveLetter $letter -Defrag -Verbose -ErrorAction Stop }
        elseif ($TrimSSD -and $type -eq "SSD") { Optimize-Volume -DriveLetter $letter -ReTrim -Verbose -ErrorAction Stop }
        else { Write-Info "Unidade $($letter): ignorada (midia: $type)." }
    }
}

function Criar-Relatorio {
    $date = Get-Date -Format "yyyy-MM-dd_HH-mm"; $reportPath = "$script:DesktopDirectory\Relatorio_Sistema_$date.html"
    $html = @"
<!DOCTYPE html><html><head><title>Relatorio do Sistema - $date</title><style>body{font-family:Arial,sans-serif;margin:30px;background-color:#f9f9f9;text-align:center;}h1{color:#2E86AB;margin-bottom:5px;}h2{color:#A23B72;margin-top:30px;}.info{background-color:#e8f4fd;padding:10px;border-radius:8px;display:inline-block;margin:10px auto;font-weight:bold;}table{border-collapse:collapse;width:90%;margin:20px auto;box-shadow:0 2px 10px rgba(0,0,0,0.1);border-radius:8px;overflow:hidden;}th,td{border:1px solid #ddd;padding:10px;}th{background-color:#f2f2f2;color:#333;font-weight:bold;}td{background-color:#fff;}footer{margin-top:40px;color:#666;font-size:0.9em;}</style></head><body><h1>Relatorio do Sistema - SysBot</h1><div class="info">Gerado em: $(Get-Date)</div><h2>Informacoes Basicas</h2><table><tr><th>Item</th><th>Valor</th></tr><tr><td>Nome do Computador</td><td>$env:COMPUTERNAME</td></tr><tr><td>Usuario</td><td>$env:USERNAME</td></tr><tr><td>Sistema Operacional</td><td>$((Get-CimInstance Win32_OperatingSystem).Caption)</td></tr><tr><td>Versao</td><td>$((Get-CimInstance Win32_OperatingSystem).Version)</td></tr></table><h2>Hardware</h2><table><tr><th>Componente</th><th>Informacao</th></tr><tr><td>Processador</td><td>$((Get-CimInstance Win32_Processor).Name)</td></tr><tr><td>Memoria Total</td><td>$([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB</td></tr><tr><td>Arquitetura</td><td>$((Get-CimInstance Win32_OperatingSystem).OSArchitecture)</td></tr></table><h2>Discos</h2><table><tr><th>Unidade</th><th>Tamanho</th><th>Livre</th><th>Tipo</th></tr>
"@
    Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object { $sizeGB = [math]::Round($_.Size / 1GB, 2); $freeGB = [math]::Round($_.SizeRemaining / 1GB, 2); $html += "<tr><td>$($_.DriveLetter):</td><td>$sizeGB GB</td><td>$freeGB GB</td><td>$($_.FileSystem)</td></tr>" }
    $html += "</table><footer><p><em>Relatorio gerado pelo SysBot</em></p></footer></body></html>
"
    $html | Out-File $reportPath -Encoding UTF8
    Write-Success "Relatorio salvo em: $reportPath"
}

function Verificar-Firewall {
    $profiles = @(Get-NetFirewallProfile -ErrorAction Stop); $allEnabled = $true
    if (-not $profiles.Count) { throw "Nenhum perfil de firewall retornado." }
    foreach ($profile in $profiles) {
        if ($profile.Enabled -ne $true) {
            $allEnabled = $false
            Write-SysError "Firewall esta DESATIVADO para o perfil: $($profile.Name)"
        }
        else {
            Write-Success "Firewall esta ATIVADO para o perfil: $($profile.Name)"
        }
    }
    if ($allEnabled) { Write-Host "" ; Write-Success "Todos os perfis do firewall estao ativos." }
}

function Verificar-Antivirus {
    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        try {
            $mp = Get-MpComputerStatus -ErrorAction Stop
            $mp | Select-Object AMRunningMode, AntivirusEnabled, RealTimeProtectionEnabled, AntivirusSignatureLastUpdated, DefenderSignaturesOutOfDate | Format-List
            if ($mp.AntivirusEnabled -and $mp.RealTimeProtectionEnabled -and -not $mp.DefenderSignaturesOutOfDate) {
                Write-Success "Defender informa protecao em tempo real ativa e assinaturas atuais."
            } else { Write-SysWarning "Defender nao confirmou protecao em tempo real e assinaturas atuais; verifique Seguranca do Windows." }
        } catch { Write-SysWarning "Status do Defender indisponivel: $($_.Exception.Message)" }
    }
    try {
        $av = @(Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction Stop)
        if ($av.Count) { $av | Select-Object displayName | Format-Table -AutoSize }
        else { Write-SysWarning "Nenhum produto retornado pela Central de Seguranca." }
        Write-Info "A lista de produtos registrados nao comprova que um antivirus de terceiros esteja ativo ou atualizado."
    } catch { Write-SysWarning "Central de Seguranca indisponivel: $($_.Exception.Message)" }
}

function Listar-ProgramasInicializacao {
    Write-Info "Programas configurados para iniciar com o Windows:"
    Write-Host ""
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
        if ($LASTEXITCODE -ne 0) { Write-SysWarning "Falha ao consultar a versao (codigo $LASTEXITCODE)."; if ($NoInstall) { return } }
        Write-Host "[+] $ToolName ja esta instalado." -ForegroundColor Green
        Write-Host "    Versao: $version" -ForegroundColor Cyan
        if (-not $NoInstall) {
            $choice = Read-Host "`n[?] Deseja reinstalar/atualizar? (s/n)"
            if ($choice -eq 's') {
                Execute-Action -Title "INSTALANDO/ATUALIZANDO $ToolName" -Action { Invoke-SysNative -Name "winget.exe" -Arguments @("install", "--exact", "--id", $WingetId) } -IsLongRunning
            }
        }
    } else {
        Write-Host "[!] $ToolName nao encontrado." -ForegroundColor Yellow
        if (-not $NoInstall) {
            $choice = Read-Host "`n[?] Deseja instalar agora? (s/n)"
            if ($choice -eq 's') {
                Execute-Action -Title "INSTALANDO $ToolName" -Action { Invoke-SysNative -Name "winget.exe" -Arguments @("install", "--exact", "--id", $WingetId) } -IsLongRunning
            }
        }
    }
}

# ==============================================================================================
#                                   SUB-ROTINAS DE MENU
# ==============================================================================================

function Menu-Manutencao {
    do {
        $subOptions = @("[1] Verificar e Instalar Atualizacoes do Windows", "[2] Verificar Integridade do Sistema (SFC)", "[3] Restaurar Saude do Sistema (DISM)", "[4] Verificar Drivers com Problemas", "[5] Atualizar Programas (winget)", "[6] Verificar Disco Online (CHKDSK)", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "MANUTENCAO DO SISTEMA" -Options $subOptions
        if ($subChoice -eq '9') { break }
        switch ($subChoice) {
            '1' { Execute-Action -Title "VERIFICANDO ATUALIZACOES" -Action { Verificar-Atualizacoes -InstallUpdates } -IsLongRunning }
            '2' { Execute-Action -Title "VERIFICANDO INTEGRIDADE (SFC)" -Action { Invoke-SysNative -Name "$env:SystemRoot\System32\sfc.exe" -Arguments @("/scannow") } -IsLongRunning }
            '3' { Execute-Action -Title "RESTAURANDO SAUDE (DISM)" -Action { Invoke-SysNative -Name "$env:SystemRoot\System32\dism.exe" -Arguments @("/Online", "/Cleanup-Image", "/RestoreHealth") -AllowedExitCodes @(0,3010) } -IsLongRunning }
            '4' { Execute-Action -Title "VERIFICANDO DRIVERS" -Action { Verificar-Drivers } }
            '5' { Execute-Action -Title "ATUALIZANDO PROGRAMAS (WINGET)" -Action {
                    Invoke-SysNative -Name "winget.exe" -Arguments @("upgrade", "--accept-source-agreements")
                    if (Confirm-SysAction "Atualizar os pacotes elegiveis acima?") {
                        Criar-PontoRestauracao
                        Invoke-SysNative -Name "winget.exe" -Arguments @("upgrade", "--all", "--accept-source-agreements")
                    } else { Write-Info "Atualizacao cancelada." }
                } -IsLongRunning }
            '6' { Execute-Action -Title "VERIFICANDO DISCO ONLINE" -Action { Verificar-Disco } -IsLongRunning }
            '8' { Show-HelpScreen -Title "AJUDA: MANUTENCAO" -HelpLines @("[1] Verificar Atualizacoes", "O que faz: Procura e instala updates oficiais do Windows.", "", "[2] Verificar Integridade (SFC)", "O que faz: Verifica se arquivos protegidos do sistema estao corrompidos.", "", "[3] Restaurar Saude (DISM)", "O que faz: Repara a 'imagem' do Windows.", "", "[4] Verificar Drivers", "O que faz: Procura por dispositivos de hardware com problemas.", "", "[5] Atualizar Programas (winget)", "O que faz: Atualiza todos os programas instalados.", "", "[6] Verificar Disco Online", "O que faz: Executa uma verificacao online NTFS sem solicitar reparo offline.") }
            default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

function Menu-Hardware {
    do {
        $subOptions = @("[1] Exibir Resumo de Hardware (CPU, GPU, RAM)", "[2] Status dos Discos e Armazenamento", "[3] Listar Programas Instalados", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "INFORMACOES DE HARDWARE" -Options $subOptions
        if ($subChoice -eq '9') { break }
        switch ($subChoice) {
            '1' { Execute-Action -Title "RESUMO DE HARDWARE" -Action { Show-HardwareSummary } }
            '2' { Execute-Action -Title "STATUS DOS DISCOS" -Action { Write-Host "`nDiscos fisicos:" -ForegroundColor Yellow; Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, HealthStatus | Format-Table -AutoSize; Write-Host "Volumes:" -ForegroundColor Yellow; Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | Select-Object DriveLetter, FileSystemLabel, @{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,2)}}, @{Name='FreeGB';Expression={[math]::Round($_.SizeRemaining/1GB,2)}}, @{Name='%Free';Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100,1)}} | Format-Table -AutoSize } }
            '3' { Execute-Action -Title "PROGRAMAS INSTALADOS" -Action { $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -and $_.DisplayName -notlike "Update*" } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName; Write-Host "[*] Total de programas: $($programs.Count)" -ForegroundColor Cyan; $programs | Format-Table -AutoSize | Out-Host -Paging } }
            '8' { Show-HelpScreen -Title "AJUDA: HARDWARE" -HelpLines @("[1] Exibir Resumo", "O que faz: Mostra um resumo tecnico dos seus principais componentes.", "", "[2] Status dos Discos", "O que faz: Exibe detalhes sobre seus dispositivos de armazenamento.", "", "[3] Programas Instalados", "O que faz: Cria uma lista de todos os programas instalados.") }
            default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

function Menu-Rede {
    do {
        $subOptions = @("[1] Configuracao de IP/DNS", "[2] Testar Conectividade Basica", "[3] Testar Resposta HTTP", "[4] Testar Portas TCP", "[5] Renovar Configuracao DHCP", "[6] Analisar Conexoes Ativas", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "DIAGNOSTICO DE REDE" -Options $subOptions
        if ($subChoice -eq '9') { break }
        switch ($subChoice) {
            '1' { Execute-Action -Title "CONFIGURACAO DE REDE" -Action { Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" } | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-Table -AutoSize } }
            '2' { Execute-Action -Title "TESTANDO CONECTIVIDADE" -Action { $ping1 = Test-Connection -ComputerName "8.8.8.8" -Count 4 -Quiet; Write-Host "Google DNS (8.8.8.8): $(if($ping1){'[+] OK'}else{'[-] FALHA'})" -ForegroundColor $(if($ping1){'Green'}else{'Red'}); $ping2 = Test-Connection -ComputerName "1.1.1.1" -Count 4 -Quiet; Write-Host "Cloudflare DNS (1.1.1.1): $(if($ping2){'[+] OK'}else{'[-] FALHA'})" -ForegroundColor $(if($ping2){'Green'}else{'Red'}) } }
            '3' { Execute-Action -Title "TESTE DE RESPOSTA HTTP" -Action { $url = "https://www.google.com"; $time = Measure-Command { $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 }; if ($response.StatusCode -eq 200) { Write-Host "[+] Conexao ativa - Tempo de resposta: $($time.TotalMilliseconds) ms" -ForegroundColor Green } } }
            '4' { Execute-Action -Title "TESTE DE PORTA TCP" -Action { $hostname = Read-Host "Digite o host ou IP"; [int]$port = 0; $portInput = Read-Host "Digite a porta"; if (-not [int]::TryParse($portInput,[ref]$port) -or $port -lt 1 -or $port -gt 65535 -or [string]::IsNullOrWhiteSpace($hostname)) { throw "Informe um host e uma porta entre 1 e 65535." }; if ($hostname -and $port) { Write-Host "[*] Testando $hostname`:$port..." -ForegroundColor Yellow; $result = Test-NetConnection -ComputerName $hostname -Port $port -WarningAction SilentlyContinue; if ($result.TcpTestSucceeded) { Write-Host "[+] Porta $port esta aberta em $hostname" -ForegroundColor Green } else { Write-Host "[-] Porta $port esta fechada ou filtrada em $hostname" -ForegroundColor Red } } } }
            '5' { Execute-Action -Title "RENOVANDO CONFIGURACAO DE REDE" -Action { if (Confirm-SysAction "A renovacao DHCP pode interromper a rede e sessoes remotas. Continuar?") { Invoke-SysNative -Name "$env:SystemRoot\System32\ipconfig.exe" -Arguments @("/flushdns"); Invoke-SysNative -Name "$env:SystemRoot\System32\ipconfig.exe" -Arguments @("/renew") } else { Write-Info "Cancelado." } } -IsLongRunning }
            '6' { Execute-Action -Title "ANALISANDO CONEXOES ATIVAS" -Action { Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{Name='Process';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | Sort-Object Process | Format-Table -AutoSize | Out-Host -Paging } }
            '8' { Show-HelpScreen -Title "AJUDA: REDE" -HelpLines @("[1] Configuracao de IP/DNS", "O que faz: Mostra suas configuracoes de rede atuais.", "", "[2] Testar Conectividade", "O que faz: Testa se seu computador consegue se comunicar com a internet.", "", "[3] Testar Velocidade", "O que faz: Mede o tempo de uma requisicao HTTP; nao mede Mbps.", "", "[4] Testar Portas TCP", "O que faz: Verifica se uma 'porta' de comunicacao esta aberta.", "", "[5] Renovar Configuracao DHCP", "O que faz: Tenta resolver problemas de conexao 'resetando' suas configuracoes.", "", "[6] Analisar Conexoes Ativas", "O que faz: Mostra em tempo real quais programas estao usando a internet.") }
            default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

function Menu-Limpeza {
    do {
        $subOptions = @("[1] Limpeza Basica de Arquivos Temporarios", "[2] Limpeza Avancada com Storage Sense", "[3] Limpar Cache de Pre-carregamento (Prefetch)", "[4] Limpar Cache de Thumbnails e Icones", "[5] Limpar Historico de Documentos Recentes", "[6] Limpeza Completa Segura (todas as opcoes)", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "FERRAMENTAS DE LIMPEZA" -Options $subOptions
        if ($subChoice -eq '9') { break }
        switch ($subChoice) {
            '1' { Execute-Action -Title "LIMPEZA BASICA" -Action { Limpeza-Avancada -IncludeTempFiles } -IsLongRunning }
            '2' { Execute-Action -Title "ABRINDO STORAGE SENSE" -Action { Start-Process "ms-settings:storagesense" } }
            '3' { Execute-Action -Title "INFORMACOES SOBRE PREFETCH" -Action { Limpeza-Avancada -IncludePrefetch } }
            '4' { Execute-Action -Title "LIMPANDO CACHES VISUAIS" -Action { Limpeza-Avancada -IncludeThumbnails } }
            '5' { Execute-Action -Title "LIMPANDO ARQUIVOS RECENTES" -Action { Limpeza-Avancada -IncludeRecentFiles } }
            '6' { Execute-Action -Title "LIMPEZA COMPLETA" -Action { Limpeza-Avancada -IncludeTempFiles -IncludeThumbnails -IncludeLogs } -IsLongRunning }
            '8' { Show-HelpScreen -Title "AJUDA: LIMPEZA" -HelpLines @("[1] Limpeza Basica", "O que faz: Remove 'lixo' digital que os programas e o sistema criam.", "", "[2] Limpeza Avancada (Storage Sense)", "O que faz: Abre a ferramenta oficial do Windows para limpeza.", "", "[3] Sobre Prefetch", "O que faz: Preserva o cache de inicializacao gerenciado pelo Windows.", "", "[4] Limpar Caches Visuais", "O que faz: Remove o cache de miniaturas de imagens e icones.", "", "[5] Limpar Recentes", "O que faz: Limpa a lista de documentos recentes.", "", "[6] Limpeza Completa Segura", "O que faz: Remove arquivos elegiveis com confirmacao; preserva Prefetch e logs do Windows.") }
            default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

function Menu-Otimizacao {
    do {
        $subOptions = @("[1] Otimizar Unidades de Disco", "[2] Desfragmentar HDDs", "[3] Executar TRIM em SSDs", "[4] Ajustar Configuracoes de Energia", "[5] Analisar Servicos Nao Essenciais", "[6] Otimizacao Completa", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "OTIMIZACAO AVANCADA" -Options $subOptions
        if ($subChoice -eq '9') { break }
        switch ($subChoice) {
            '1' { Execute-Action -Title "OTIMIZANDO UNIDADES" -Action { Otimizacao-Sistema -OptimizeDrives } -IsLongRunning }
            '2' { Execute-Action -Title "DESFRAGMENTANDO HDDS" -Action { Otimizacao-Sistema -Defrag } -IsLongRunning }
            '3' { Execute-Action -Title "EXECUTANDO TRIM EM SSDS" -Action { Otimizacao-Sistema -TrimSSD } -IsLongRunning }
            '4' { Execute-Action -Title "AJUSTANDO ENERGIA" -Action { Write-Host "[*] Planos de energia disponiveis:" -ForegroundColor Yellow; powercfg /list; Write-Host "`n[i] Para alterar para Alto Desempenho, use o comando abaixo:" -ForegroundColor Blue; Write-Host "powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -ForegroundColor Gray; $response = Read-Host "`nDefinir para Alto Desempenho? (s/n)"; if ($response -eq 's') { Invoke-SysNative -Name "$env:SystemRoot\System32\powercfg.exe" -Arguments @("/setactive", "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"); Write-Host "[+] Plano alterado" -ForegroundColor Green } } }
            '5' { Execute-Action -Title "ANALISANDO SERVICOS" -Action { Write-Host "[!] CUIDADO: Nao desative servicos sem conhecimento tecnico!" -ForegroundColor Red; Write-Host "`n[*] Servicos automaticos que estao parados:" -ForegroundColor Yellow; Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -eq "Stopped" } | Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize } }
            '6' { Execute-Action -Title "OTIMIZACAO COMPLETA" -Action { Otimizacao-Sistema -OptimizeDrives } -IsLongRunning }
            '8' { Show-HelpScreen -Title "AJUDA: OTIMIZACAO" -HelpLines @("[1] Otimizar Unidades", "O que faz: Analisa e executa a otimizacao padrao do Windows.", "", "[2] Desfragmentar HDDs", "O que faz: Reorganiza os arquivos em discos rigidos (HDDs).", "", "[3] Executar TRIM em SSDs", "O que faz: Melhora o desempenho e a vida util do seu SSD.", "", "[4] Ajustar Energia", "O que faz: Permite alterar o plano de energia para desempenho maximo.", "", "[5] Analisar Servicos", "O que faz: Mostra servicos que iniciam com o Windows, mas que estao parados.", "", "[6] Otimizacao Completa", "O que faz: Executa as principais otimizacoes de disco.") }
            default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

function Menu-Relatorios {
    do {
        $subOptions = @("[1] Gerar Relatorio do Sistema (HTML)", "[2] Exportar Lista de Drivers (CSV)", "[3] Exportar Programas Instalados (TXT)", "[4] Salvar Configuracao de Rede (TXT)", "[5] Criar Dump Completo do Sistema (TXT)", "[6] Analisar Integridade do Sistema", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "RELATORIOS E DIAGNOSTICOS" -Options $subOptions
        if ($subChoice -eq '9') { break }
        switch ($subChoice) {
            '1' { Execute-Action -Title "GERANDO RELATORIO HTML" -Action { Criar-Relatorio } }
            '2' { Execute-Action -Title "EXPORTANDO DRIVERS" -Action { Get-CimInstance Win32_SystemDriver | Export-Csv "$script:DesktopDirectory\Drivers_$(Get-Date -f yyyy-MM-dd).csv" -NoTypeInformation -Encoding UTF8 } }
            '3' { Execute-Action -Title "EXPORTANDO PROGRAMAS" -Action { Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion | Out-File "$script:DesktopDirectory\Programas_$(Get-Date -f yyyy-MM-dd).txt" } }
            '4' { Execute-Action -Title "SALVANDO CONFIGURACAO DE REDE" -Action { ipconfig /all | Out-File "$script:DesktopDirectory\Rede_$(Get-Date -f yyyy-MM-dd).txt" } }
            '5' { Execute-Action -Title "CRIANDO DUMP DO SISTEMA" -Action { $folder = "$script:DesktopDirectory\SysBot_Dump_$(Get-Date -f yyyy-MM-dd_HH-mm)"; New-Item -ItemType Directory -Path $folder -Force | Out-Null; systeminfo | Out-File "$folder\systeminfo.txt"; Get-Process | Out-File "$folder\processes.txt"; Get-Service | Out-File "$folder\services.txt" } -IsLongRunning }
            '6' { Execute-Action -Title "ANALISANDO INTEGRIDADE" -Action { $results = @(); sfc /verifyonly; if ($LASTEXITCODE -eq 0) { $results += "[+] SFC: Sistema integro" } else { $results += "[!] SFC: Problemas encontrados" }; DISM /Online /Cleanup-Image /ScanHealth 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { $results += "[+] DISM: Imagem integra" } else { $results += "[!] DISM: Possiveis problemas encontrados" }; $problemDrivers = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }; if ($problemDrivers) { $results += "[!] DRIVERS: $($problemDrivers.Count) dispositivos com problemas" } else { $results += "[+] DRIVERS: Todos funcionando corretamente" }; Write-Host "`n=== RESULTADOS DA ANALISE ===" -ForegroundColor Cyan; $results | ForEach-Object { $color = if ($_ -match '\[\+\]') { 'Green' } elseif ($_ -match '\[\!\]') { 'Yellow' } else { 'Red' }; Write-Host $_ -ForegroundColor $color } } -IsLongRunning }
            '8' { Show-HelpScreen -Title "AJUDA: RELATORIOS" -HelpLines @("[1] Gerar Relatorio (HTML)", "O que faz: Cria um relatorio visual e organizado sobre seu sistema.", "", "[2] Exportar Drivers (CSV)", "O que faz: Cria uma planilha com uma lista tecnica de todos os drivers.", "", "[3] Exportar Programas (TXT)", "O que faz: Cria um arquivo de texto com a lista de todos os seus programas.", "", "[4] Salvar Configuracao de Rede", "O que faz: Gera um arquivo de texto com um diagnostico completo da rede.", "", "[5] Criar Dump do Sistema", "O que faz: Cria uma pasta com varios relatorios detalhados.", "", "[6] Analisar Integridade", "O que faz: Executa uma verificacao rapida da saude geral do sistema.") }
            default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

function Menu-Seguranca {
    do {
        $subOptions = @("[1] Verificar Status do Firewall", "[2] Verificar Status do Antivirus", "[3] Listar Programas que Iniciam com o Sistema", "", "[8] AJUDA: O que estas funcoes fazem?", "[9] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "AUDITORIA DE SEGURANCA" -Options $subOptions
        if ($subChoice -eq '9') { break }
        switch ($subChoice) {
            '1' { Execute-Action -Title "STATUS DO FIREWALL" -Action { Verificar-Firewall } }
            '2' { Execute-Action -Title "STATUS DO ANTIVIRUS" -Action { Verificar-Antivirus } }
            '3' { Execute-Action -Title "PROGRAMAS NA INICIALIZACAO" -Action { Listar-ProgramasInicializacao } }
            '8' { Show-HelpScreen -Title "AJUDA: SEGURANCA" -HelpLines @("[1] Verificar Status do Firewall", "O que faz: Verifica se o Firewall do Windows esta ativo.", "", "[2] Verificar Status do Antivirus", "O que faz: Confere se ha um programa de antivirus ativo e atualizado.", "", "[3] Listar Programas na Inicializacao", "O que faz: Mostra os programas configurados para iniciar junto com o Windows.") }
            default { if ($subChoice -ne '9') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

function Menu-DevTools {
    do {
        $subOptions = @("--- INSTALAR FERRAMENTAS ---", "[1] Gerenciar Python 3", "[2] Gerenciar Java (JDK)", "[3] Gerenciar Git", "[4] Gerenciar Visual Studio Code", "[5] Gerenciar NodeJS (LTS)", "", "--- VERIFICAR VERSOES ---", "[v1] Verificar todas as versoes", "", "[h] AJUDA: O que estas funcoes fazem?", "[0] Voltar ao Menu Principal")
        $subChoice = Show-Menu -Title "GERENCIADOR DE DESENVOLVIMENTO" -Options $subOptions
        if ($subChoice -eq '0') { break }
        switch ($subChoice) {
            '1' { Manage-DevTool -ToolName "Python" -WingetId "Python.Python.3.13" -ExecutableName "python.exe" -VersionArgument "--version" }
            '2' { Manage-DevTool -ToolName "Java" -WingetId "Oracle.JDK.21" -ExecutableName "java.exe" -VersionArgument "-version" }
            '3' { Manage-DevTool -ToolName "Git" -WingetId "Git.Git" -ExecutableName "git.exe" -VersionArgument "--version" }
            '4' { Manage-DevTool -ToolName "Visual Studio Code" -WingetId "Microsoft.VisualStudioCode" -ExecutableName "code.cmd" -VersionArgument "--version" }
            '5' { Manage-DevTool -ToolName "NodeJS" -WingetId "OpenJS.NodeJS.LTS" -ExecutableName "node.exe" -VersionArgument "--version" }
            'v1' {
                Execute-Action -Title "VERIFICANDO VERSOES" -Action {
                    Manage-DevTool -ToolName "Python" -ExecutableName "python.exe" -VersionArgument "--version" -NoInstall
                    Manage-DevTool -ToolName "Java" -ExecutableName "java.exe" -VersionArgument "-version" -NoInstall
                    Manage-DevTool -ToolName "Git" -ExecutableName "git.exe" -VersionArgument "--version" -NoInstall
                }
            }
            'h' { Show-HelpScreen -Title "AJUDA: DEV TOOLS" -HelpLines @("[1-5] Gerenciar Ferramentas", "O que faz: Verifica se uma ferramenta esta instalada e mostra sua versao.", "", "[v1] Verificar todas as versoes", "O que faz: Executa uma verificacao rapida de versao para Python, Java e Git.") }
            default { if ($subChoice -ne '0') {Write-Host "[-] Opcao invalida" -ForegroundColor Red; Pausar} }
        }
    } while ($true)
}

# ==============================================================================================
#                                   LOOP PRINCIPAL (MAIN)
# ==============================================================================================

try {
do {
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
        '1' { Menu-Manutencao }
        '2' { Menu-Hardware }
        '3' { Menu-Rede }
        '4' { Menu-Limpeza }
        '5' { Menu-Otimizacao }
        '6' { Menu-Relatorios }
        '7' { Menu-Seguranca }
        '8' { Menu-DevTools }
        '9' { Show-HelpScreen -Title "AJUDA GERAL" -HelpLines @("[1] Manutencao do Sistema", "    Executa tarefas essenciais para manter o sistema saudavel.", "", "[2] Informacoes de Hardware", "    Mostra detalhes sobre os componentes do seu computador.", "", "[3] Diagnostico de Rede", "    Ferramentas para verificar sua conexao com a internet.", "", "[4] Ferramentas de Limpeza", "    Libera espaco em disco removendo arquivos desnecessarios.", "", "[5] Otimizacao Avancada", "    Executa acoes para melhorar o desempenho do sistema.", "", "[6] Relatorios e Diagnosticos", "    Gera relatorios completos sobre o estado do seu sistema.", "", "[7] Auditoria de Seguranca", "    Verifica configuracoes basicas de seguranca do seu PC.", "", "[8] Gerenciador de Desenvolvimento", "    Instala e verifica ferramentas populares para programacao.") }
        '0' { Write-Host "`nEncerrando SysBot. Ate logo!" -ForegroundColor Green; break }
        default { Write-Host "`n[-] Opcao invalida. Tente novamente." -ForegroundColor Red; Pausar }
    }
    if ($mainChoice -eq "0") { break }
} while ($true)
} finally {
    Stop-Transcript | Out-Null
}
