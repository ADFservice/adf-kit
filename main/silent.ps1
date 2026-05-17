# =====================================
# ADF KIT - MODO SILENCIOSO
# =====================================

# ADMIN
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell `
        "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# CONFIG
$ErrorActionPreference = "SilentlyContinue"

# LOG
$logPath = "C:\ADFKit\logs"
New-Item -ItemType Directory -Path $logPath -Force | Out-Null

$logFile = "$logPath\silent-$(Get-Date -Format yyyyMMdd-HHmmss).log"

Start-Transcript -Path $logFile

# BASE
$base = "https://raw.githubusercontent.com/SEU_USUARIO/ADF-Kit/main/scripts"

# HARDWARE
$ram = [math]::Round(
    (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
)

$domain = (Get-CimInstance Win32_ComputerSystem).PartOfDomain

$disk = (
    Get-PhysicalDisk | Select-Object -First 1
).MediaType

# PERFIL
$perfil = "domestico"

if ($domain) {
    $perfil = "empresa"
}
elseif ($ram -ge 16 -and $disk -eq "SSD") {
    $perfil = "completo"
}

Write-Host "Perfil detectado: $perfil"

# EXECUTOR
function Run($script) {

    Write-Host "Executando: $script"

    try {
        irm "$base/$script.ps1" | iex
    }
    catch {
        Write-Host "Erro em $script"
    }
}

# EXECUÇÃO
switch ($perfil) {

    "domestico" {

        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "privacy"
    }

    "empresa" {

        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "hardening"
    }

    "completo" {

        Run "limpeza"
        Run "debloat"
        Run "privacy"
        Run "hardening"
        Run "install"
    }
}

# AJUSTES FINAIS

# Energia
powercfg -setactive SCHEME_MIN

# Atualizar políticas
gpupdate /force

# Limpar arquivos temporários finais
Remove-Item "$env:TEMP\*" -Force -Recurse

# FINAL
Write-Host "FINALIZADO"

Stop-Transcript

# Reinício opcional
# Restart-Computer -Force