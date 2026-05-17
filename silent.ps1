# ==========================================
# ADF KIT - SILENT MODE
# Pós-formatação automática inteligente
# ==========================================

param(
    [string]$Cliente = "Padrao",
    [string]$LogFile = ""
)

# ==========================================
# AUTO ELEVAÇÃO ADMIN
# ==========================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# ==========================================
# CONFIGURAÇÕES
# ==========================================

$ErrorActionPreference = "SilentlyContinue"

$baseUrl = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/scripts"

$basePath = "C:\ADF-Kit"
$logPath = "$basePath\Logs"
$tempPath = "$basePath\Temp"

# ==========================================
# CRIAR ESTRUTURA
# ==========================================

New-Item -ItemType Directory -Path $basePath -Force | Out-Null
New-Item -ItemType Directory -Path $logPath  -Force | Out-Null
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

# ==========================================
# LOG
# ==========================================

if (-not $LogFile) {

    $LogFile = Join-Path $logPath "$Cliente-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
}

Start-Transcript -Path $LogFile

# ==========================================
# HEADER
# ==========================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        ADF KIT - SILENT MODE" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cliente: $Cliente"
Write-Host "Log: $LogFile"

# ==========================================
# TESTAR INTERNET
# ==========================================

Write-Host ""
Write-Host "Verificando internet..."

$internet = Test-Connection google.com -Count 1 -Quiet

if (-not $internet) {

    Write-Host "Sem conexão com internet."
    Stop-Transcript
    exit
}

Write-Host "Internet OK."

# ==========================================
# DETECÇÃO HARDWARE
# ==========================================

Write-Host ""
Write-Host "Detectando hardware..."

$ram = [math]::Round(
    (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
)

$cpu = (Get-CimInstance Win32_Processor).Name

$disk = (
    Get-PhysicalDisk |
    Select-Object -First 1
).MediaType

$domain = (
    Get-CimInstance Win32_ComputerSystem
).PartOfDomain

Write-Host "RAM: $ram GB"
Write-Host "CPU: $cpu"
Write-Host "DISCO: $disk"

# ==========================================
# DETECÇÃO PERFIL
# ==========================================

$perfil = "domestico"

if ($domain) {

    $perfil = "empresa"
}
elseif ($ram -ge 16 -and $disk -eq "SSD") {

    $perfil = "completo"
}

Write-Host ""
Write-Host "Perfil detectado: $perfil"

# ==========================================
# FUNÇÃO EXECUTAR SCRIPT
# ==========================================

function Run-Script {

    param(
        [string]$ScriptName
    )

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Executando: $ScriptName"
    Write-Host "=========================================="

    $url = "$baseUrl/$ScriptName.ps1"

    $localScript = Join-Path $tempPath "$ScriptName.ps1"

    try {

        # DOWNLOAD
        Invoke-WebRequest `
            -Uri $url `
            -OutFile $localScript `
            -UseBasicParsing

        # EXECUÇÃO
        powershell.exe `
            -ExecutionPolicy Bypass `
            -File $localScript
    }
    catch {

        Write-Host "ERRO ao executar:"
        Write-Host $ScriptName
    }
}

# ==========================================
# EXECUÇÃO POR PERFIL
# ==========================================

switch ($perfil) {

    "domestico" {

        Run-Script "limpeza"
        Run-Script "install"
        Run-Script "debloat"
        Run-Script "privacy"
        Run-Script "ADF-Kit-Tweaks"
    }

    "empresa" {

        Run-Script "limpeza"
        Run-Script "install"
        Run-Script "debloat"
        Run-Script "privacy"
        Run-Script "hardening"
        Run-Script "ADF-Kit-Tweaks
    }

    "completo" {

        Run-Script "limpeza"
        Run-Script "debloat"
        Run-Script "privacy"
        Run-Script "hardening"
        Run-Script "ADF-Kit-Tweaks
        Run-Script "install"
    }
}

# ==========================================
# AJUSTES FINAIS
# ==========================================

Write-Host ""
Write-Host "Aplicando ajustes finais..."

# Energia
& "$env:SystemRoot\System32\powercfg.exe" `
    -setactive SCHEME_MIN

# Atualizar políticas
& "$env:SystemRoot\System32\gpupdate.exe" `
    /force

# Limpeza TEMP final
Remove-Item "$env:TEMP\*" `
    -Force `
    -Recurse `
    -ErrorAction SilentlyContinue

# ==========================================
# FINAL
# ==========================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " SISTEMA FINALIZADO COM SUCESSO "
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Logs:"
Write-Host $LogFile

# ==========================================
# ENCERRAR LOG
# ==========================================

Stop-Transcript

# ==========================================
# REINÍCIO OPCIONAL
# ==========================================

# Restart-Computer -Force