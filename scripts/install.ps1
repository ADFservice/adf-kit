function App-Installed($id) {
    $result = winget list --id=$id 2>$null
    return $result -match $id
}

$apps = @(
    "Google.Chrome",
    "Python.Python.3",
    "PuTTY.PuTTY",
    "Adobe.Acrobat.Reader.64-bit",
    "AnyDeskSoftwareGmbH.AnyDesk"
)

foreach ($app in $apps) {
    if (App-Installed $app) {
        Write-Host "$app já instalado"
    } else {
        winget install --id=$app -e --silent --accept-package-agreements --accept-source-agreements
    }
}

$shortcutPath = "$env:PUBLIC\Desktop\WhatsApp.lnk"

if (!(Test-Path $shortcutPath)) {
    $ws = New-Object -ComObject WScript.Shell
    $s = $ws.CreateShortcut($shortcutPath)
    $s.TargetPath = "https://web.whatsapp.com"
    $s.Save()
}