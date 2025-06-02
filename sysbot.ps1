# ===================== SYSBOT v3.1 =====================
# Script principal de manutenção e otimização do sistema
# =======================================================

# Caminho do módulo de utilidades
$utilsPath = Join-Path -Path $PSScriptRoot -ChildPath "utils.ps1"

# Importar módulo
if (Test-Path $utilsPath) {
    . $utilsPath
} else {
    Write-Host "❌ Arquivo utils.ps1 não encontrado." -ForegroundColor Red
    exit
}

function Exibir-Menu {
    Write-Header
    Write-Host @"
========================= MENU =========================

 [1] 🧠 Verificar uso de memória RAM
 [2] 🔄 Verificar atualizações do Windows
 [3] 🧹 Executar limpeza básica
 [4] 💾 Otimizar discos
 [5] 🔍 Verificar drivers
 [6] 🧪 Verificar integridade do disco
 [7] 📄 Gerar relatório do sistema

 [0] ❌ Sair do SysBot

========================================================
"@ -ForegroundColor Cyan
}

# Loop principal
do {
    Exibir-Menu
    $opcao = Read-Host "`nDigite sua opção"

    switch ($opcao) {
        "1" { Verificar-MemoriaRAM }
        "2" { Verificar-Atualizacoes }
        "3" { Limpeza-Basica }
        "4" { Otimizacao-Disco }
        "5" { Verificar-Drivers }
        "6" { Verificar-Disco }
        "7" { Criar-Relatorio }
        "0" {
            Write-Host "`n👋 Encerrando SysBot. Até logo!" -ForegroundColor Green
            break
        }
        default {
            Write-Host "`n❌ Opção inválida. Tente novamente." -ForegroundColor Red
        }
    }

    if ($opcao -ne "0") { Pausar }

} while ($true)
