param(
    [string]$LocalVersionFile,
    [switch]$ReturnState
)

$basePath = $env:ADFKIT_PATH
if ([string]::IsNullOrWhiteSpace($basePath)) {
    $basePath = 'C:\ADF-Kit'
}

if ([string]::IsNullOrWhiteSpace($LocalVersionFile)) {
    $localVersionFile = Join-Path $basePath 'config\version.json'
}
else {
    $localVersionFile = $LocalVersionFile
}

$remoteVersionInfo = irm https://raw.githubusercontent.com/ADFservice/adf-kit/main/config/version.json
$remoteVersion = [string]$remoteVersionInfo.version

$localVersion = $null
if (Test-Path $localVersionFile) {
    try {
        $localVersion = (Get-Content -Path $localVersionFile -Raw | ConvertFrom-Json).version
    }
    catch {
        $localVersion = $null
    }
}

$needsUpdate = [string]::IsNullOrWhiteSpace($localVersion) -or ($localVersion -ne $remoteVersion)

if ($ReturnState) {
    [pscustomobject]@{
        RemoteVersion = $remoteVersion
        LocalVersion  = if ($localVersion) { $localVersion } else { $null }
        NeedsUpdate   = $needsUpdate
    }
    return
}

if ($needsUpdate) {
    Write-Host "Atualização necessária. Versão remota: $remoteVersion"
    if (-not (Test-Path (Split-Path $localVersionFile -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $localVersionFile -Parent) -Force | Out-Null
    }
    @{
        version = $remoteVersion
    } | ConvertTo-Json -Depth 10 | Set-Content -Path $localVersionFile -Encoding UTF8
    Write-Host "Versão local atualizada para $remoteVersion"
}
else {
    Write-Host "Versão local atualizada. Usando cache local: $localVersion"
}

if ($needsUpdate) {
    exit 1
}

exit 0