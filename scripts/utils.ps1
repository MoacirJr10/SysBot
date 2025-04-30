@echo off
:: SysBot Utilities v2.0 - Módulo de Diagnóstico
title SysBot - Utilitários do Sistema
color 0A
setlocal enabledelayedexpansion

:: Definir caminhos
set "ROOT_DIR=%~dp0"
set "LOG_DIR=%ROOT_DIR%logs"

:: Verificar se PowerShell está disponível
where powershell >nul 2>&1
if %errorlevel% neq 0 (
echo [ERRO] PowerShell nâo estâ instalado ou nâo estâ no PATH
pause
exit /b 1
)

:menu
cls
echo.
echo ===============================================
echo      SYSBOT - UTILITeRIOS DE DIAGNeSTICO
echo ===============================================
echo.
echo 1. Verificar Integridade do Sistema de Arquivos
echo 2. Limpar Cache DNS
echo 3. Verificar Portas Abertas
echo 4. Verificar Erros do Sistema
echo 5. Verificar Serviços Críticos
echo 6. Diagnóstico Completo
echo 7. Sair
echo.
set /p choice=Selecione uma opçao:

if "%choice%"=="1" goto filesystem
if "%choice%"=="2" goto dns
if "%choice%"=="3" goto ports
if "%choice%"=="4" goto errors
if "%choice%"=="5" goto services
if "%choice%"=="6" goto full
if "%choice%"=="7" exit /b
goto menu

:filesystem
cls
echo.
echo [INTEGRIDADE DO SISTEMA DE ARQUIVOS]
echo.
echo 1. Verificar unidade C: (Recomendado)
echo 2. Verificar outra unidade
echo 3. Voltar ao menu
echo.
set /p fs_choice=Selecione:

if "%fs_choice%"=="1" (
echo.
echo [VERIFICANDO UNIDADE C:...]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $result = Test-FileSystemIntegrity -driveLetter 'C'; if ($result -eq 0) { Write-Host 'Verificaçao concluída com sucesso' -ForegroundColor Green } else { Write-Host 'Problemas encontrados (Código: $result)' -ForegroundColor Yellow } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
if "%fs_choice%"=="2" (
echo.
set /p drive=Digite a letra da unidade (sem dois pontos):
echo [VERIFICANDO UNIDADE %drive%:...]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $result = Test-FileSystemIntegrity -driveLetter '%drive%'; if ($result -eq 0) { Write-Host 'Verificaçao concluída com sucesso' -ForegroundColor Green } else { Write-Host 'Problemas encontrados (Código: $result)' -ForegroundColor Yellow } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
goto menu

:dns
cls
echo.
echo [LIMPEZA DE CACHE DNS]
echo.
echo 1. Limpar cache DNS
echo 2. Voltar ao menu
echo.
set /p dns_choice=Selecione:

if "%dns_choice%"=="1" (
echo.
echo [LIMPANDO CACHE DNS...]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $result = Clear-DNSCache; if ($result) { Write-Host 'Cache DNS limpo com sucesso' -ForegroundColor Green } else { Write-Host 'Falha ao limpar cache DNS' -ForegroundColor Red } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
goto menu

:ports
cls
echo.
echo [VERIFICAeÇeO DE PORTAS ABERTAS]
echo.
echo 1. Verificar top 10 conexões
echo 2. Verificar conexões personalizadas
echo 3. Voltar ao menu
echo.
set /p ports_choice=Selecione:

if "%ports_choice%"=="1" (
echo.
echo [TOP 10 CONEXeES ATIVAS]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $connections = Get-OpenPorts -topCount 10; if ($connections) { $connections | Format-Table -AutoSize } else { Write-Host 'Nenhuma conexao encontrada' -ForegroundColor Yellow } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
if "%ports_choice%"=="2" (
echo.
set /p count=Quantas conexões deseja ver:
echo [VERIFICANDO %count% CONEXeES...]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $connections = Get-OpenPorts -topCount %count%; if ($connections) { $connections | Format-Table -AutoSize } else { Write-Host 'Nenhuma conexao encontrada' -ForegroundColor Yellow } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
goto menu

:errors
cls
echo.
echo [ERROS DO SISTEMA]
echo.
echo 1. Verificar erros das últimas 24 horas
echo 2. Verificar erros personalizado
echo 3. Voltar ao menu
echo.
set /p errors_choice=Selecione:

if "%errors_choice%"=="1" (
echo.
echo [ERROS DAS eLTIMAS 24 HORAS]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $errors = Get-SystemErrors -hoursBack 24; if ($errors -and $errors.Count -gt 0) { $errors | Format-Table -AutoSize } else { Write-Host 'Nenhum erro encontrado' -ForegroundColor Green } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
if "%errors_choice%"=="2" (
echo.
set /p hours=Quantas horas para trâs deseja verificar:
set /p max=Quantos erros mâximo deseja ver:
echo [VERIFICANDO ERROS...]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $errors = Get-SystemErrors -hoursBack %hours% -maxErrors %max%; if ($errors -and $errors.Count -gt 0) { $errors | Format-Table -AutoSize } else { Write-Host 'Nenhum erro encontrado' -ForegroundColor Green } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
goto menu

:services
cls
echo.
echo [SERVIeOS CReTICOS]
echo.
echo 1. Verificar status dos servi‚os críticos
echo 2. Tentar reiniciar servi‚os parados
echo 3. Voltar ao menu
echo.
set /p svc_choice=Selecione:

if "%svc_choice%"=="1" (
echo.
echo [VERIFICANDO SERVIeOS CReTICOS...]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $services = Test-CriticalServices; if ($services) { $services | Format-Table -AutoSize } else { Write-Host 'Nenhum serviço verificado' -ForegroundColor Yellow } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
if "%svc_choice%"=="2" (
echo.
echo [REINICIANDO SERVIeOS PARADOS...]
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; $services = Test-CriticalServices | Where-Object { $_.IsOK -eq $false }; if ($services) { foreach ($svc in $services) { try { Start-Service -Name $svc.Name -ErrorAction Stop; Write-Host ('Serviço '+$svc.Name+' reiniciado com sucesso') -ForegroundColor Green } catch { Write-Host ('Falha ao reiniciar '+$svc.Name+': $_') -ForegroundColor Red } } } else { Write-Host 'Nenhum serviço parado encontrado' -ForegroundColor Green } } catch { Write-Host 'Erro: $_' -ForegroundColor Red } }"
pause
)
goto menu

:full
cls
echo.
echo [DIAGNeSTICO COMPLETO]
echo.
echo Este processo pode levar alguns minutos...
echo.
powershell -NoProfile -Command "& { $ErrorActionPreference = 'Stop'; try { Import-Module '%ROOT_DIR%sysbot_utils.psm1' -Force; Write-Host '=== INTEGRIDADE DO SISTEMA DE ARQUIVOS ===' -ForegroundColor Cyan; $fsResult = Test-FileSystemIntegrity -driveLetter 'C'; Write-Host '`n=== CACHE DNS ===' -ForegroundColor Cyan; $dnsResult = Clear-DNSCache; Write-Host '`n=== PORTAS ABERTAS ===' -ForegroundColor Cyan; $ports = Get-OpenPorts -topCount 10; if ($ports) { $ports | Format-Table -AutoSize } else { Write-Host 'Nenhuma conexao encontrada' -ForegroundColor Yellow }; Write-Host '`n=== ERROS DO SISTEMA ===' -ForegroundColor Cyan; $errors = Get-SystemErrors -hoursBack 24; if ($errors -and $errors.Count -gt 0) { $errors | Format-Table -AutoSize } else { Write-Host 'Nenhum erro encontrado' -ForegroundColor Green }; Write-Host '`n=== SERVIeOS CReTICOS ===' -ForegroundColor Cyan; $services = Test-CriticalServices; if ($services) { $services | Format-Table -AutoSize } else { Write-Host 'Nenhum serviço verificado' -ForegroundColor Yellow }; Write-Host '`n=== RESUMO ===' -ForegroundColor Cyan; Write-Host 'Integridade do sistema de arquivos: $(if ($fsResult -eq 0) { 'OK' } else { 'Problemas (Código $fsResult)' })'; Write-Host 'Cache DNS: $(if ($dnsResult) { 'Limpo' } else { 'Falha' })'; Write-Host 'Serviços críticos: $($services | Where-Object { $_.IsOK -eq $true } | Measure-Object).Count/$($services.Count) em execução'; } catch { Write-Host 'Erro durante diagnóstico completo: $_' -ForegroundColor Red } }"
pause
goto menu