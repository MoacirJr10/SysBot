@echo off
:: SysBot Advanced v3.0 - Manutenção Completa do Sistema
title SysBot - Manutenção Avançada
color 0A
setlocal enabledelayedexpansion

:: Configurações iniciais
set "ROOT_DIR=%~dp0"
set "LOG_DIR=%ROOT_DIR%logs"
set "PS_SCRIPT=%ROOT_DIR%sysbot_main.ps1"

:: Verificar requisitos
where powershell >nul 2>&1
if %errorlevel% neq 0 (
echo [ERRO] PowerShell nâo estâ instalado ou nâo estâ no PATH
pause
exit /b 1
)

if not exist "%PS_SCRIPT%" (
echo [ERRO] Arquivo principal sysbot_main.ps1 nâo encontrado
pause
exit /b 1
)

:main_menu
cls
echo.
echo ===============================================
echo        SYSBOT - MANUTENeÇeO AVANeADA
echo ===============================================
echo.
echo 1. Atualizaçao do Sistema
echo 2. Limpeza de Arquivos Temporários
echo 3. Otimizaçao de Inicializaçao
echo 4. Relatório Completo do Sistema
echo 5. Executar Todas as Tarefas
echo 6. Sair
echo.
set /p choice=Selecione uma opçao:

if "%choice%"=="1" goto update_system
if "%choice%"=="2" goto clean_temp
if "%choice%"=="3" goto optimize_startup
if "%choice%"=="4" goto system_report
if "%choice%"=="5" goto full_maintenance
if "%choice%"=="6" exit /b
goto main_menu

:update_system
cls
echo.
echo [ATUALIZAeÇeO DO SISTEMA]
echo.
echo 1. Verificar e instalar atualizaçães do Windows
echo 2. Atualizar apenas definiçães do Windows Defender
echo 3. Voltar ao menu principal
echo.
set /p update_choice=Selecione:

if "%update_choice%"=="1" (
echo.
echo [VERIFICANDO ATUALIZAeEES DO WINDOWS...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; $result = Update-System; if ($result) { Write-Host 'Atualizaçao concluída com sucesso' -ForegroundColor Green } else { Write-Host 'Falha na atualizaçao' -ForegroundColor Red } }"
pause
)
if "%update_choice%"=="2" (
echo.
echo [ATUALIZANDO DEFINIeEES DO DEFENDER...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; if (Get-Command Update-MpSignature -ErrorAction SilentlyContinue) { Update-MpSignature; Write-Host 'Definiçães atualizadas' -ForegroundColor Green } else { Write-Host 'Windows Defender nâo disponível' -ForegroundColor Yellow } }"
pause
)
goto main_menu

:clean_temp
cls
echo.
echo [LIMPEZA DE ARQUIVOS TEMPeeRIOS]
echo.
echo 1. Limpar arquivos temporários padrão
echo 2. Limpar com opçães avançadas
echo 3. Voltar ao menu principal
echo.
set /p clean_choice=Selecione:

if "%clean_choice%"=="1" (
echo.
echo [LIMPEZA PADReO EM ANDAMENTO...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; $result = Clean-TempFiles; if ($result) { Write-Host ('Limpeza concluída: '+$result.FilesRemoved+' arquivos removidos ('+$result.MBRemoved+' MB)') -ForegroundColor Green } else { Write-Host 'Falha na limpeza' -ForegroundColor Red } }"
pause
)
if "%clean_choice%"=="2" (
echo.
echo [LIMPEZA AVANeADA]
echo 1. Limpar cache do Windows Update
echo 2. Limpar arquivos de prefetch
echo 3. Limpar todos os arquivos temporários
echo 4. Voltar
echo.
set /p adv_clean_choice=Selecione:

if "%adv_clean_choice%"=="1" (
echo.
echo [LIMPANDO CACHE DO WINDOWS UPDATE...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; Remove-Item -Path '$env:SystemRoot\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'Cache do Windows Update limpo' -ForegroundColor Green }"
pause
)
if "%adv_clean_choice%"=="2" (
echo.
echo [LIMPANDO ARQUIVOS DE PREFETCH...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; Remove-Item -Path '$env:SystemRoot\Prefetch\*' -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'Arquivos de prefetch limpos' -ForegroundColor Green }"
pause
)
if "%adv_clean_choice%"=="3" (
echo.
echo [LIMPANDO TODOS OS ARQUIVOS TEMPeeRIOS...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; Get-ChildItem -Path $env:SystemRoot\Temp, $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'Todos os arquivos temporários limpos' -ForegroundColor Green }"
pause
)
goto clean_temp
)
goto main_menu

:optimize_startup
cls
echo.
echo [OTIMIZAeÇeO DE INICIALIZAeÇeO]
echo.
echo 1. Listar itens de inicializaçao
echo 2. Desativar itens de inicializaçao
echo 3. Otimizar unidades de disco
echo 4. Voltar ao menu principal
echo.
set /p optimize_choice=Selecione:

if "%optimize_choice%"=="1" (
echo.
echo [ITENS DE INICIALIZAeÇeO]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; $items = Optimize-SystemStartup; if ($items.StartupItems.Count -gt 0) { Write-Host 'Itens encontrados:'; $items.StartupItems | Format-Table -AutoSize } else { Write-Host 'Nenhum item de inicializaçao encontrado' -ForegroundColor Yellow } }"
pause
)
if "%optimize_choice%"=="2" (
echo.
echo [DESATIVAR ITENS DE INICIALIZAeÇeO]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; $startupPath = [Environment]::GetFolderPath('Startup'); $items = Get-ChildItem -Path $startupPath, 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup' -ErrorAction SilentlyContinue; if ($items) { $items | Format-Table Name, FullName -AutoSize; Write-Host '`nPara desativar, remova os atalhos das pastas acima.' -ForegroundColor Yellow } else { Write-Host 'Nenhum item de inicializaçao encontrado' -ForegroundColor Yellow } }"
pause
)
if "%optimize_choice%"=="3" (
echo.
echo [OTIMIZANDO UNIDADES DE DISCO...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; $result = Optimize-SystemStartup; if ($result.OptimizedVolumes.Count -gt 0) { Write-Host ('Unidades otimizadas: '+($result.OptimizedVolumes -join ', ')) -ForegroundColor Green } else { Write-Host 'Nenhuma unidade otimizada' -ForegroundColor Yellow } }"
pause
)
goto main_menu

:system_report
cls
echo.
echo [RELATeeRIO DO SISTEMA]
echo.
echo 1. Relatório resumido
echo 2. Relatório completo
echo 3. Salvar relatório em arquivo
echo 4. Voltar ao menu principal
echo.
set /p report_choice=Selecione:

if "%report_choice%"=="1" (
echo.
echo [RELATeeRIO RESUMIDO]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; Generate-SystemReport | Out-Null }"
pause
)
if "%report_choice%"=="2" (
echo.
echo [RELATeeRIO COMPLETO]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; $computerInfo = Get-ComputerInfo; $diskInfo = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' }; $memoryInfo = @{ Total = [math]::Round($computerInfo.OsTotalVisibleMemorySize / 1MB, 2); Free = [math]::Round($computerInfo.OsFreePhysicalMemory / 1MB, 2) }; Write-Host '`n=== INFORMAeEES DETALHADAS ===' -ForegroundColor Cyan; $computerInfo | Format-List *; Write-Host '`n=== DISCOS ===' -ForegroundColor Cyan; $diskInfo | Format-Table -AutoSize; Write-Host '`n=== MEMeeRIA ===' -ForegroundColor Cyan; Write-Host ('Total: '+$memoryInfo.Total+' MB | Livre: '+$memoryInfo.Free+' MB') }"
pause
)
if "%report_choice%"=="3" (
echo.
set /p report_name=Digite o nome para o arquivo (sem extensao):
echo [SALVANDO RELATeeRIO...]
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; $reportPath = Join-Path -Path '%LOG_DIR%' -ChildPath ('%report_name%_'+$(Get-Date -Format 'yyyy-MM-dd_HH-mm')+'.txt'); Generate-SystemReport *>&1 | Out-File -FilePath $reportPath -Force; Write-Host ('Relatório salvo em: '+$reportPath) -ForegroundColor Green }"
pause
)
goto main_menu

:full_maintenance
cls
echo.
echo [MANUTENeÇeO COMPLETA]
echo.
echo Este processo pode levar vários minutos...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module '%PS_SCRIPT%'; Write-Host '=== ATUALIZAeÇeO ===' -ForegroundColor Cyan; $updateResult = Update-System; Write-Host '`n=== LIMPEZA ===' -ForegroundColor Cyan; $cleanResult = Clean-TempFiles; if ($cleanResult) { Write-Host ('Arquivos removidos: '+$cleanResult.FilesRemoved+' ('+$cleanResult.MBRemoved+' MB)') -ForegroundColor Green }; Write-Host '`n=== OTIMIZAeÇeO ===' -ForegroundColor Cyan; $optimizeResult = Optimize-SystemStartup; if ($optimizeResult.OptimizedVolumes.Count -gt 0) { Write-Host ('Unidades otimizadas: '+($optimizeResult.OptimizedVolumes -join ', ')) -ForegroundColor Green }; Write-Host '`n=== RELATeeRIO ===' -ForegroundColor Cyan; Generate-SystemReport | Out-Null; Write-Host '`n=== CONCLUSeO ===' -ForegroundColor Cyan; Write-Host 'Manutençao completa finalizada' -ForegroundColor Green }"
pause
goto main_menu