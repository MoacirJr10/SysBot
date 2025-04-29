@echo off
:: Executa o script PowerShell como Administrador
powershell -ExecutionPolicy Bypass -NoProfile -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0..\scripts\sysbot.ps1\"' -Verb RunAs"
