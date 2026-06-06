#Requires -RunAsAdministrator
param(
    [string]$Cliente = "Desconhecido",
    [string]$LogFile = ""
)

function Write-Log($Message, $Level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($LogFile) {
        $logDir = Split-Path $LogFile -ErrorAction SilentlyContinue
        if ($logDir -and !(Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force -ErrorAction SilentlyContinue | Out-Null
        }
        if (Test-Path $logDir) {
            Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
        }
    }
    $cor = switch ($Level) { 
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    Write-Host $logEntry -ForegroundColor $cor
}

Write-Log "=== INICIANDO DEBLOAT para $Cliente ===" "INFO"
Write-Log "Plataforma: $([Environment]::OSVersion.VersionString)" "INFO"

# ✅ REMOVER APLICATIVOS DESNECESSÁRIOS
$appsARemover = @(
    "Microsoft.BingWeather",
    "Microsoft.BingNews",
    "Microsoft.WindowsMaps",
    "Microsoft.Music",
    "Microsoft.Zune*",
    "Microsoft.MSPaint",
    "Microsoft.RemoteDesktop",
    "*EclipseManager*",
    "*ActiproSoftwareLLC*",
    "*AdobeSystemsIncorporated.Adobe*",
    "*Duolingo*",
    "*PandoraMediaInc*",
    "*CandyCrush*",
    "*BubbleWitch*",
    "*Spotify*",
    "*Telegram*",
    "*Slack*",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MixedReality.Portal"
)

Write-Log "Removendo aplicativos desnecessários..." "INFO"
foreach ($app in $appsARemover) {
    Get-AppxPackage $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
}
Write-Log "✅ Aplicativos removidos com sucesso" "SUCCESS"

# ✅ DESABILITAR SERVIÇOS DESNECESSÁRIOS
$servicosADesabilitar = @(
    "DiagTrack",           # Conectar Usuário e Telemetria
    "dmwappushservice",    # dmwappushservice
    "TapiSrv",            # Telefonia
    "ALG",                # Application Layer Gateway Service
    "TrkWks",             # Rastreador Distribuído de Ligações
    "lmhosts",            # TCP/IP NetBIOS Helper
    "WlanSvc",            # WLAN AutoConfig (se usar Ethernet)
    "mapsupdateservice",  # Mapa do Windows
    "RemoteRegistry"      # Registro Remoto
)

Write-Log "Desabilitando serviços desnecessários..." "INFO"
foreach ($service in $servicosADesabilitar) {
    $svc = Get-Service $service -ErrorAction SilentlyContinue
    if ($svc) {
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    }
}
Write-Log "✅ Serviços desabilitados com sucesso" "SUCCESS"

# ✅ OTIMIZAÇÕES DE PERFORMANCE
Write-Log "Aplicando otimizações de performance..." "INFO"

# Desabilitar Visual Effects
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue

# Desabilitar notificações desnecessárias
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK /t REG_DWORD /d 0 /f | Out-Null

Write-Log "✅ Otimizações aplicadas com sucesso" "SUCCESS"

Write-Log "=== DEBLOAT CONCLUÍDO ===" "SUCCESS"
