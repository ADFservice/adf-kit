# Executar como admin (robusto)
function Ensure-RunAs {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        $scriptPath = $PSCommandPath
        if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Definition }
        $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath)

        $pwPath = $null
        $pw = Get-Command powershell.exe -ErrorAction SilentlyContinue
        if ($pw) { $pwPath = $pw.Source }
        elseif (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { $pwPath = (Get-Command pwsh.exe).Source }
        elseif (Test-Path (Join-Path $PSHOME 'pwsh.exe')) { $pwPath = Join-Path $PSHOME 'pwsh.exe' }
        elseif (Test-Path (Join-Path $PSHOME 'powershell.exe')) { $pwPath = Join-Path $PSHOME 'powershell.exe' }

        if (-not $pwPath) {
            Write-Host "⚠️ Não foi possível localizar PowerShell para reexecutar como administrador." -ForegroundColor Red
            exit 1
        }

        Start-Process -FilePath $pwPath -ArgumentList $args -Verb RunAs
        exit
    }
}
Ensure-RunAs

# Configuração de logs/transcript
$logPath = "C:\ADFKit\logs"
New-Item -ItemType Directory -Path $logPath -Force | Out-Null
$cliente = Read-Host "Nome do cliente (ou Enter para Padrao)"
if (-not $cliente) { $cliente = "Padrao" }
$transcriptFile = Join-Path $logPath "$cliente-$(Get-Date -Format yyyyMMdd-HHmmss)-pos-formatacao-auto.log"
Start-Transcript -Path $transcriptFile -Force

Clear-Host
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   ADF - PÓS-FORMATAÇÃO INTELIGENTE" -ForegroundColor Yellow
Write-Host "====================================="

# 🔎 Coleta de dados
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$cpu = (Get-CimInstance Win32_Processor).Name
$domain = (Get-CimInstance Win32_ComputerSystem).PartOfDomain
$disk = Get-PhysicalDisk | Select-Object -First 1
$diskType = $disk.MediaType

Write-Host "`nDetectando hardware..."
Write-Host "RAM: $ramGB GB"
Write-Host "CPU: $cpu"
Write-Host "Em domínio: $domain"
Write-Host "Disco: $diskType"

# 🧠 Decisão de perfil
$perfil = "Domestico"

if ($domain -eq $true) {
    $perfil = "Empresa"
}
elseif ($ramGB -ge 16 -and $diskType -eq "SSD") {
    $perfil = "Completo"
}
elseif ($ramGB -le 4) {
    $perfil = "Domestico"
}

Write-Host "`nPerfil detectado: $perfil" -ForegroundColor Green

# 🔁 Permitir override manual
$confirm = Read-Host "Deseja alterar? (s/n)"

if ($confirm -eq "s") {
    Write-Host "1 - Doméstico"
    Write-Host "2 - Empresa"
    Write-Host "3 - Completo"
    $opt = Read-Host "Escolha"

    switch ($opt) {
        "1" { $perfil = "Domestico" }
        "2" { $perfil = "Empresa" }
        "3" { $perfil = "Completo" }
    }
}

# 🌐 Base scripts
$base = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/scripts"

function Run($script) {
    Write-Host "`nExecutando $script..." -ForegroundColor Cyan
    try {
        $scriptContent = irm "$base/$script.ps1" -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($scriptContent)) {
            throw "Conteúdo remoto vazio para $script"
        }
        iex $scriptContent
    }
    catch {
        Write-Host "⚠️ Aviso: falha ao executar $script - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 🚀 Execução por perfil
switch ($perfil) {

    "Domestico" {
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "privacy"
    }

    "Empresa" {
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "hardening"
    }

    "Completo" {
        Run "limpeza"
        Run "debloat"
        Run "privacy"
        Run "hardening"
        Run "install"
    }
}

# ⚙️ Ajustes finais
Write-Host "`nAplicando ajustes finais..."

powercfg -setactive SCHEME_MIN
gpupdate /force

Write-Host "`nSistema pronto!" -ForegroundColor Green
Stop-Transcript
pause