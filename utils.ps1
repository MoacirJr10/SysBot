# SysBot Utilities - Funcoes de Interface e Animacao

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
    
    # A animacao agora e chamada aqui!
    Show-SlideHeader

    $width = 70

    # Footer / Credits
    if ($Title -eq "MENU PRINCIPAL") {
        Write-Host "     Desenvolvido por: MoacirJr10 (Estudante de Engenharia de Computacao)" -ForegroundColor Gray
        Write-Host "     GitHub: MoacirJr10 | Sugestoes sao sempre bem-vindas!" -ForegroundColor Gray
        Write-Host ""
    }

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
