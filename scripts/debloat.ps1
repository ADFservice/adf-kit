20260526 00:54:09 || #Requires -RunAsAdministrator
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
        if (Test-Path $logDir)) {
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

# DETECTAR PLATAFORMA
$IsServer = [Environment]::OSVersion.VersionString -match "Server"
$AppxSupported = $false

try {
    Import-Module Appx -ErrorAction Stop
    $AppxSupported = $true
    Write-Log "✅ Módulo Appx disponível" "SUCCESS"
}
catch {
    Write-Log "⚠️ Appx não suportado (Server/LTSC). Pulando apps UWP." "WARNING"
}

# APPS UWP (só se suportado)
if ($AppxSupported) {
    Write-Log "Removendo apps UWP..." "INFO"
    $apps = @(
        "Microsoft.XboxApp", "Microsoft.XboxGamingOverlay", "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay", "Microsoft.GamingApp", "Microsoft.SkypeApp",
        "MicrosoftTeams", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.BingNews",
        "Microsoft.BingWeather", "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.People",
        "Microsoft.Todos", "Microsoft.WindowsFeedbackHub", "Microsoft.MicrosoftOfficeHub",
        "Microsoft.ZuneMusic", "Microsoft.ZuneVideo", "Microsoft.MixedReality.Portal",
        "Clipchamp.Clipchamp"
    )
    
    foreach ($app in $apps) {
        Write-Log "  $app" "DarkGray"
        # Remover pacote para todos os usuários
        Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-AppxPackage $_ -AllUsers -ErrorAction Stop
            }
            catch {
                Write-Log "    ⚠️ Falha ao remover para usuários: $($_.Exception.Message)" "WARNING"
            }
        }
        # Remover pacote provisionado
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | 
        Where-Object DisplayName -eq $app | 
        ForEach-Object {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop
            }
            catch {
                Write-Log "    ⚠️ Falha ao remover pacote provisionado: $($_.Exception.Message)" "WARNING"
            }
        }
    }
}
else {
    Write-Log "Ignorando apps UWP..." "INFO"
}

# REGISTRO - SEMPRE FUNCIONA
Write-Log "Aplicando políticas de registro..." "INFO"

$regTweaks = @{
    # Desativa recursos de consumo e conteúdo em nuvem
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"                 = @{ 
        "DisableWindowsConsumerFeatures" = 1
        "DisableCloudContent"            = 1
        "DisableThirdPartySuggestions"   = 1
    }
    # Desativa entrega de conteúdo, anúncios e sugestões
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" = @{ 
        "SubscribedContent-338388Enabled"  = 0
        "SubscribedContent-338389Enabled"  = 0
        "SilentInstalledAppsEnabled"       = 0
        "ContentDeliveryAllowed"           = 0
        "OemPreInstalledAppsEnabled"       = 0
        "PreInstalledAppsEnabled"          = 0
        "PreInstalledAppsEverEnabled"      = 0
        "SystemPaneSuggestionsEnabled"     = 0
        "RotatingLockScreenEnabled"        = 0
        "RotatingLockScreenOverlayEnabled" = 0
    }
    # Desativa atualizações automáticas da Loja
    "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"                         = @{ 
        "AutoDownload" = 2 
    }
    # Desativa anúncios e sugestões no Menu Iniciar
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"                     = @{
        "DisableStartMenuSuggestions"   = 1
        "DisableAdvertisingAppsInStart" = 1
    }
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"      = @{
        "Start_IrisRecommendations"     = 0
        "ShowSyncProviderNotifications" = 0
    }
    # Desativa ID de Publicidade
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"        = @{
        "Enabled" = 0
    }
    # Desativa dicas e sugestões do Windows
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"                       = @{
        "DisableTips"                  = 1
        "DisableAppNotifications"      = 0
        "DisableCloudOptimizedContent" = 1
    }
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" = @{
        "NOC_GLOBAL_SETTING_ALLOW_TIPS_NOTIFICATION"        = 0
        "NOC_GLOBAL_SETTING_ALLOW_SUGGESTIONS_NOTIFICATION" = 0
    }
    # Serviços de telemetria
    "HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack"                      = @{
        "Start" = 4
    }
    "HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice"               = @{
        "Start" = 4
    }
}

foreach ($path in $regTweaks.Keys) {
    try {
        if (!(Test-Path $path)) {
            New-Item $path -Force -ErrorAction Stop | Out-Null
        }
        foreach ($key in $regTweaks[$path].Keys) {
            $valor = $regTweaks[$path][$key]
            Set-ItemProperty -Path $path -Name $key -Value $valor -Type DWord -Force -ErrorAction Stop
            Write-Log "  ✅ $path : $key = $valor" "SUCCESS"
        }
    }
    catch {
        Write-Log "  ⚠️ $path : $($_.Exception.Message)" "WARNING"
    }
}

# TASKS WINDOWS (telemetria, coleta de dados, sugestões)
Write-Log "Desabilitando tarefas desnecessárias..." "INFO"
$tasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask",
    "\Microsoft\Windows\Shell\FamilySafetyMonitor",
    "\Microsoft\Windows\Shell\FamilySafetyRefresh"
)

foreach ($tarefa in $tasks) {
    try {
        $caminhoTarefa = Split-Path $tarefa -Parent
        $nomeTarefa = Split-Path $tarefa -Leaf
        $existente = Get-ScheduledTask -TaskPath "$caminhoTarefa\" -TaskName $nomeTarefa -ErrorAction SilentlyContinue
        if ($existente) {
            Disable-ScheduledTask -TaskPath $existente.TaskPath -TaskName $existente.TaskName -ErrorAction Stop | Out-Null
            Write-Log "  ✅ Tarefa desabilitada: $nomeTarefa" "SUCCESS"
        }
    }
    catch {
        Write-Log "  ⚠️ Não foi possível desabilitar $nomeTarefa : $($_.Exception.Message)" "WARNING"
    }
}

# SERVIÇOS NÃO ESSENCIAIS
Write-Log "Configurando serviços..." "INFO"
$services = @("DiagTrack", "dmwappushservice", "WMPNetworkSvc", "RetailDemo")
foreach ($svc in $services) {
    try {
        $servico = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($servico) {
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
            Set-Service $svc -StartupType Disabled -ErrorAction Stop
            Write-Log "  ✅ $svc desabilitado e parado" "SUCCESS"
        }
        else {
            Write-Log "  ℹ️ Serviço $svc não existe nesta versão do Windows" "INFO"
        }
    }
    catch {
        Write-Log "  ⚠️ Falha ao configurar $svc : $($_.Exception.Message)" "WARNING"
    }
}

# PHOTO VIEWER CORRIGIDO E HABILITADO
Write-Log "Ativando Photo Viewer clássico..." "INFO"
$photoExts = @('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tiff', '.ico', '.wdp')

# Habilitar o Visualizador de Fotos no sistema
$chaveHabilitacao = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities"
if (!(Test-Path $chaveHabilitacao)) {
    New-Item -Path $chaveHabilitacao -Force -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path $chaveHabilitacao -Name "ApplicationDescription" -Value "Visualizador de Fotos do Windows" -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $chaveHabilitacao -Name "ApplicationName" -Value "PhotoViewer" -Type String -Force -ErrorAction SilentlyContinue

# Associações de arquivos
$photoKey = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"
if (!(Test-Path $photoKey)) {
    New-Item -Path $photoKey -Force -ErrorAction SilentlyContinue | Out-Null
}

foreach ($ext in $photoExts) {
    try {
        Set-ItemProperty -Path $photoKey -Name $ext -Value "PhotoViewer.FileAssoc.Tiff" -Type String -Force -ErrorAction Stop
        
        # Configurar para usuários atuais
        $chaveUsuario = "HKCU:\Software\Classes\$ext\OpenWithProgIds"
        if (!(Test-Path $chaveUsuario)) {
            New-Item -Path $chaveUsuario -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $chaveUsuario -Name "PhotoViewer.FileAssoc.Tiff" -Value "" -Type String -Force -ErrorAction SilentlyContinue
        
        Write-Log "  ✅ Associação feita: $ext" "SUCCESS"
    }
    catch {
        Write-Log "  ⚠️ Falha em $ext : $($_.Exception.Message)" "WARNING"
    }
}

# Registrar o ProgID necessário
$progId = "HKLM:\SOFTWARE\Classes\PhotoViewer.FileAssoc.Tiff"
if (!(Test-Path $progId)) {
    New-Item -Path $progId -Force -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path $progId -Name "(Default)" -Value "Visualizador de Fotos do Windows" -Type String -Force -ErrorAction SilentlyContinue
$commandPath = "$progId\shell\open\command"
if (!(Test-Path $commandPath)) {
    New-Item -Path $commandPath -Force -ErrorAction SilentlyContinue | Out-Null
}
Set-ItemProperty -Path $commandPath -Name "(Default)" -Value "%SystemRoot%\System32\rundll32.exe `"%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1" -Type String -Force -ErrorAction SilentlyContinue

# LIMPEZA TEMP
Write-Log "Limpando arquivos temporários..." "INFO"
@("$env:TEMP", "$env:WINDIR\Temp", "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Temporary Internet Files") | ForEach-Object {
    if (Test-Path $_) {
        Get-ChildItem $_ -Recurse -Force -ErrorAction SilentlyContinue | 
        Where-Object { $_.PSIsContainer -eq $false } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "  ✅ Limpo: $_" "SUCCESS"
    }
}

Write-Log "🎉 === DEBLOAT CONCLUÍDO COM SUCESSO! ===" "SUCCESS"
Write-Host "`n" -NoNewline
Write-Host "==========================================" -ForegroundColor Green
Write-Host "      DEBLOAT FINALIZADO - $Cliente       " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
if ($LogFile) {
    Write-Host "Log completo salvo em: $LogFile" -ForegroundColor Cyan
}