# Executar como admin
if (-not ([Security.Principal.WindowsPrincipal] 
[Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Clear-Host
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "     ADF - PÓS-FORMATAÇÃO" -ForegroundColor Yellow
Write-Host "====================================="
Write-Host ""
Write-Host "1 - Doméstico"
Write-Host "2 - Empresa"
Write-Host "3 - Completo"
Write-Host "0 - Sair"
Write-Host ""

$perfil = Read-Host "Escolha o perfil"

$base = "https://raw.githubusercontent.com/SEU_USUARIO/kit-suporte/main/scripts"

function Run($script) {
    Write-Host "`nExecutando $script..." -ForegroundColor Cyan
    irm "$base/$script.ps1" | iex
}

switch ($perfil) {

    "1" {
        Write-Host "`nModo DOMÉSTICO" -ForegroundColor Green
        
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "privacy"

    }

    "2" {
        Write-Host "`nModo EMPRESA" -ForegroundColor Yellow
        
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "hardening"

    }

    "3" {
        Write-Host "`nModo COMPLETO" -ForegroundColor Magenta
        
        Run "limpeza"
        Run "debloat"
        Run "privacy"
        Run "hardening"
        Run "install"

    }

    default {
        Write-Host "Saindo..."
        exit
    }
}

# Ajustes finais
Write-Host "`nAplicando ajustes finais..." -ForegroundColor Cyan

# Plano de energia alto desempenho
powercfg -setactive SCHEME_MIN

# Atualizar políticas
gpupdate /force

Write-Host "`nSistema pronto para uso!" -ForegroundColor Green
pause