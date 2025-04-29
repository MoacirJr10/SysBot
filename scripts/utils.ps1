function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "[SysBot] Rode o script como Administrador." -ForegroundColor Red
        exit
    }
}

function Update-System {
    Write-Host "[SysBot] Verificando atualizações..." -ForegroundColor Cyan
    Install-Module -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot
}

function Clean-Temp {
    Write-Host "[SysBot] Limpando arquivos temporários..." -ForegroundColor Yellow
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
}

function Optimize-Startup {
    Write-Host "[SysBot] Desabilitando programas desnecessários na inicialização..." -ForegroundColor Yellow
    Get-CimInstance -ClassName Win32_StartupCommand |
            Where-Object { $_.Location -like "*Startup*" } |
            ForEach-Object {
                Write-Host "Desabilitando: $($_.Name)"
                # Atenção: operação fictícia, personalize se desejar desativar algo específico
            }
}
