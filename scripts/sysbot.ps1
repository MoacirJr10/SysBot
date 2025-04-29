# sysbot.ps1
Import-Module "$PSScriptRoot\utils.ps1"

# Verifica se está em modo administrador
Ensure-Admin

# Executa tarefas
Update-System
Clean-Temp
Optimize-Startup

Write-Host "`n[SysBot] Otimização concluída com sucesso!" -ForegroundColor Green
