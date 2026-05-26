$ErrorActionPreference = 'Stop'

function Test-Admin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Admin {
    if (Test-Admin) {
        return
    }

    Write-Host '🔐 Reexecutando o script com privilégios de Administrador...'
    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $PSCommandPath
    )

    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -WindowStyle Hidden
    exit 0
}

Ensure-Admin

function Get-OperatingSystemInfo {
    try {
        return Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Install-MicrosoftStoreIfLTSC {
    Write-Host "`n🔍 Verificando se é Windows 10/11 LTSC..."

    $osInfo = Get-OperatingSystemInfo
    $osEdition = if ($osInfo) { [int]$osInfo.OperatingSystemSKU } else { 0 }
    $caption = if ($osInfo) { [string]$osInfo.Caption } else { '' }
    $isLTSC = ($osEdition -in @(125, 126, 145, 146)) -or ($caption -match 'LTSC')

    if (-not $isLTSC) {
        Write-Host "ℹ️ Não é edição LTSC. Loja já deve estar disponível."
        return $true
    }

    $wsresetPath = Join-Path $env:SystemRoot 'System32\wsreset.exe'
    if (-not (Test-Path $wsresetPath)) {
        Write-Host "❌ wsreset.exe não foi encontrado em $wsresetPath."
        return $false
    }

    Write-Host "⚠️ Edição LTSC detectada. Ativando Microsoft Store via comando oficial wsreset -i..."

    try {
        & $wsresetPath -i
        Write-Host "✅ Comando executado. Aguardando finalização do processo..."
        Start-Sleep -Seconds 15
        Write-Host "✅ Microsoft Store ativada e instalada com sucesso no LTSC."
        return $true
    }
    catch {
        Write-Host "❌ Falha ao ativar a Microsoft Store: $_"
        return $false
    }
}

function Install-Winget {
    Write-Host "`n🔍 Verificando se o Winget está instalado..."
    $wingetExists = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

    if ($wingetExists) {
        Write-Host "✅ Winget já está instalado e disponível."
        return $true
    }

    Write-Host "⚠️ Winget não encontrado. Iniciando instalação..."
    try {
        $apiUrl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
        $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -Headers @{ 'User-Agent' = 'ADF-Kit' }
        $installerUrl = $release.assets | Where-Object { $_.name -like '*msixbundle' } | Select-Object -ExpandProperty browser_download_url -First 1

        if (-not $installerUrl) {
            throw 'Não foi possível obter o link do instalador do Winget.'
        }

        $outputFile = Join-Path $env:TEMP 'Microsoft.DesktopAppInstaller.msixbundle'
        Invoke-WebRequest -Uri $installerUrl -OutFile $outputFile -UseBasicParsing

        if (-not (Test-Path $outputFile)) {
            throw 'Arquivo do instalador do Winget não foi baixado.'
        }

        Add-AppxPackage -Path $outputFile

        $wingetExists = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
        if ($wingetExists) {
            Write-Host '✅ Winget instalado com sucesso.'
            return $true
        }

        throw 'Instalação concluída, mas o Winget não está acessível. Reinicie o computador para concluir.'
    }
    catch {
        Write-Host "❌ Falha ao instalar o Winget: $_"
        return $false
    }
}

function Test-AppInstalled($id) {
    try {
        $result = winget list --id=$id 2>$null
        return $result -match [regex]::Escape($id)
    }
    catch {
        return $false
    }
}

if (-not (Test-Admin)) {
    Write-Host '❌ Este script precisa ser executado com privilégios de Administrador.'
    exit 1
}

if (-not (Install-MicrosoftStoreIfLTSC)) {
    Write-Host "`n⛔ Não é possível configurar a Microsoft Store. O processo foi interrompido."
    exit 1
}

if (-not (Install-Winget)) {
    Write-Host "`n⛔ Não é possível continuar sem o Winget instalado."
    exit 1
}

$apps = @(
    'Google.Chrome',
    'Python.Python.3',
    'PuTTY.PuTTY',
    'Adobe.Acrobat.Reader.64-bit',
    'AnyDeskSoftwareGmbH.AnyDesk',
    'RustDesk.RustDesk',
    '7-Zip.7-Zip',
    'voidtools.Everything',
    'Microsoft.PowerToys',
    'CrystalDewWorld.CrystalDiskInfo',
    'WiresharkFoundation.Wireshark'
)

foreach ($app in $apps) {
    if (Test-AppInstalled $app) {
        Write-Host "`n✅ $app já está instalado."
        continue
    }

    Write-Host "`n🔄 Instalando $app..."
    try {
        winget install --id=$app -e --silent --accept-package-agreements --accept-source-agreements
        Write-Host "✅ $app instalado com sucesso."
    }
    catch {
        Write-Host "❌ Falha ao instalar $app : $_"
    }
}

$shortcutPath = Join-Path $env:PUBLIC 'Desktop\WhatsApp.lnk'

if (-not (Test-Path $shortcutPath)) {
    try {
        $ws = New-Object -ComObject WScript.Shell
        $s = $ws.CreateShortcut($shortcutPath)
        $s.TargetPath = 'https://web.whatsapp.com'
        $s.Save()
        Write-Host "`n✅ Atalho do WhatsApp Web criado na área de trabalho."
    }
    catch {
        Write-Host "`n❌ Falha ao criar atalho: $_"
    }
}
else {
    Write-Host "`nℹ️ O atalho do WhatsApp Web já existe."
}

Write-Host "`n🔄 Verificando e aplicando atualizações de todos os programas..."
try {
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Host "`n✅ Todos os programas estão atualizados e prontos para uso!"
}
catch {
    Write-Host "`n⚠️ Ocorreu um erro durante as atualizações: $_"
}