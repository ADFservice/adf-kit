irm https://raw.githubusercontent.com/ADFservice/adf-kit/main/core/updater.ps1 | iex

$cliente = Read-Host "Nome do cliente"
if (-not $cliente) { $cliente = "Padrao" }

$logPath = "C:\ADFKit\logs"
New-Item -ItemType Directory -Path $logPath -Force | Out-Null

Start-Transcript -Path "$logPath\$cliente-$(Get-Date -Format yyyyMMdd-HHmm).log"

Clear-Host
Write-Host "ADF KIT - MODO INTELIGENTE"

$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$domain = (Get-CimInstance Win32_ComputerSystem).PartOfDomain
$disk = (Get-PhysicalDisk | Select-Object -First 1).MediaType

if ($domain) {
    $perfil = "empresa"
}
elseif ($ram -ge 16 -and $disk -eq "SSD") {
    $perfil = "completo"
}
else {
    $perfil = "domestico"
}

Write-Host "Perfil detectado: $perfil"

$base = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/scripts"

function Run($s) {
    Write-Host "Executando $s..."
    irm "$base/$s.ps1" | iex
}

switch ($perfil) {
    "domestico" {
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run-Script "ADF-Kit-Tweaks
    }

    "empresa" {
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "hardening"
        Run-Script "ADF-Kit-Tweaks
    }

    "completo" {
        Run "limpeza"
        Run "debloat"
        Run "privacy"
        Run "hardening"
        Run "install"
        Run-Script "ADF-Kit-Tweaks
    }
    
}

powercfg -setactive SCHEME_MIN
gpupdate /force

irm https://get.activated.win | iex

Write-Host "Sistema pronto!"
Stop-Transcript
pause