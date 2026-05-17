#Requires -RunAsAdministrator
param(
    [string]$Cliente = "Desconhecido",
    [string]$LogFile = ""
)

function Write-Log($Message, $Level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($LogFile -and (Test-Path (Split-Path $LogFile))) {
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    }
    Write-Host $logEntry -ForegroundColor $(switch($Level) { 
        "ERROR" { "Red" }; "SUCCESS" { "Green" }; "WARNING" { "Yellow" }; default { "Cyan" } 
    })
}

Write-Log "=== INICIANDO DEBLOAT para $Cliente ===" "INFO"
Write-Log "Plataforma: $([Environment]::OSVersion.VersionString)" "INFO"

# DETECTAR PLATAFORMA
$IsServer = [Environment]::OSVersion.VersionString -match "Server"
$AppxSupported = $false

try {
    Import-Module Appx -ErrorAction Stop
    $AppxSupported = $true
    Write-Log "✅ Módulo Appx disponível" "SUCCESS"
} catch {
    Write-Log "⚠️ Appx não suportado (Server/LTSC). Pulando apps UWP." "WARNING"
}

# APPS UWP (só se suportado)
if ($AppxSupported) {
    Write-Log "Removendo apps UWP..." "INFO"
    $apps = @(
        "Microsoft.XboxApp","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay","Microsoft.GamingApp","Microsoft.SkypeApp",
        "MicrosoftTeams","Microsoft.MicrosoftSolitaireCollection","Microsoft.BingNews",
        "Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.People",
        "Microsoft.Todos","Microsoft.WindowsFeedbackHub","Microsoft.MicrosoftOfficeHub",
        "Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.MixedReality.Portal",
        "Clipchamp.Clipchamp"
    )
    
    foreach ($app in $apps) {
        Write-Log "  $app" "DarkGray"
        Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-AppxPackage $_ -ErrorAction SilentlyContinue
        }
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app | ForEach-Object {
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
        }
    }
} else {
    Write-Log "Ignorando apps UWP..." "INFO"
}

# REGISTRO - SEMPRE FUNCIONA
Write-Log "Aplicando políticas de registro..." "INFO"

$regTweaks = @{
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" = @{ "DisableWindowsConsumerFeatures" = 1 }
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" = @{ 
        "SubscribedContent-338388Enabled" = 0
        "SilentInstalledAppsEnabled" = 0
        "ContentDeliveryAllowed" = 0
        "OemPreInstalledAppsEnabled" = 0
        "PreInstalledAppsEnabled" = 0
        "PreInstalledAppsEverEnabled" = 0
    }
    "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" = @{ "AutoDownload" = 2 }
}

foreach ($path in $regTweaks.Keys) {
    New-Item $path -Force -ErrorAction SilentlyContinue | Out-Null
    foreach ($key in $regTweaks[$path].Keys) {
        try {
            Set-ItemProperty $path $key $regTweaks[$path][$key] -Type DWord -Force -ErrorAction Stop
            Write-Log "  ✅ $path : $key" "SUCCESS"
        } catch {
            Write-Log "  ⚠️ $path : $key" "WARNING"
        }
    }
}

# TASKS WINDOWS (telemetria, etc)
Write-Log "Desabilitando tarefas desnecessárias..." "INFO"
$tasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
)

Get-ScheduledTask $tasks -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue

# SERVIÇOS NÃO ESSENCIAIS
Write-Log "Configurando serviços..." "INFO"
$services = @("DiagTrack","dmwappushservice")
foreach ($svc in $services) {
    try {
        Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Log "  ✅ $svc desabilitado" "SUCCESS"
    } catch {
        Write-Log "  [IGNORADO] $svc" "DarkGray"
    }
}

# SUBSTITUA a seção Photo Viewer por esta (linhas finais):

# PHOTO VIEWER CORRIGIDO
Write-Log "Ativando Photo Viewer clássico..." "INFO"
$photoExts = @('.jpg','.jpeg','.png','.bmp','.gif','.tiff')

# Criar chave se não existir
$photoKey = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"
if (!(Test-Path $photoKey)) {
    New-Item -Path $photoKey -Force | Out-Null
}

foreach ($ext in $photoExts) {
    $fullPath = "$photoKey\$ext"
    try {
        # Criar property com Name explícito
        Set-ItemProperty -Path $photoKey -Name $ext -Value "PhotoViewer.FileAssoc.Tiff" -Type String -Force -ErrorAction Stop
        Write-Log "  ✅ $ext" "SUCCESS"
    } catch {
        Write-Log "  ⚠️ $ext : $($_.Exception.Message)" "WARNING"
    }
}

# LIMPEZA TEMP
Write-Log "Limpando arquivos temporários..." "INFO"
Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Log "🎉 === DEBLOAT CONCLUÍDO COM SUCESSO! ===" "SUCCESS"
Write-Host "`n" -NoNewline
Write-Host "==========================================" -ForegroundColor Green
Write-Host "      DEBLOAT FINALIZADO - $Cliente       " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Log completo salvo em: $LogFile" -ForegroundColor Cyan