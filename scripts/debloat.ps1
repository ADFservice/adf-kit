#Requires -RunAsAdministrator

# ==========================================
# ADF KIT - DEBLOAT PROFISSIONAL
# ==========================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      ADF KIT - DEBLOAT WINDOWS" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------
# APPS QUE PODEM SER REMOVIDOS COM SEGURANÇA
# ------------------------------------------

$apps = @(

    # Xbox
    "Microsoft.XboxApp",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.GamingApp",

    # Comunicação
    "Microsoft.SkypeApp",
    "MicrosoftTeams",

    # Jogos
    "Microsoft.MicrosoftSolitaireCollection",

    # Apps promocionais / extras
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.People",
    "Microsoft.Todos",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.MicrosoftOfficeHub",

    # Multimídia extra
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",

    # Mixed Reality
    "Microsoft.MixedReality.Portal",

    # Outros
    "Clipchamp.Clipchamp"
    "Microsoft.Windows.Photos"
)

# ------------------------------------------
# FUNÇÃO DE REMOÇÃO
# ------------------------------------------

function Remove-Bloat {

    param (
        [string]$AppName
    )

    Write-Host ""
    Write-Host "Removendo: $AppName" -ForegroundColor Cyan

    # Remove instalado
    $installed = Get-AppxPackage -Name $AppName -AllUsers

    if ($installed) {

        foreach ($pkg in $installed) {

            try {

                Remove-AppxPackage `
                    -Package $pkg.PackageFullName `
                    -ErrorAction Stop

                Write-Host "  [OK] Pacote instalado removido" -ForegroundColor Green

            }
            catch {

                Write-Host "  [ERRO] Falha ao remover instalado" -ForegroundColor Yellow
            }
        }

    }
    else {

        Write-Host "  [INFO] Não instalado" -ForegroundColor DarkGray
    }

    # Remove provisionado
    $provisioned = Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -eq $AppName }

    if ($provisioned) {

        foreach ($prov in $provisioned) {

            try {

                Remove-AppxProvisionedPackage `
                    -Online `
                    -PackageName $prov.PackageName `
                    -ErrorAction Stop | Out-Null

                Write-Host "  [OK] Provisionamento removido" -ForegroundColor Green

            }
            catch {

                Write-Host "  [ERRO] Falha ao remover provisionado" -ForegroundColor Yellow
            }
        }

    }
    else {

        Write-Host "  [INFO] Não provisionado" -ForegroundColor DarkGray
    }
}

# ------------------------------------------
# EXECUÇÃO
# ------------------------------------------

foreach ($app in $apps) {

    Remove-Bloat $app
}

# ------------------------------------------
# DESATIVAR REINSTALAÇÃO AUTOMÁTICA
# ------------------------------------------

Write-Host ""
Write-Host "Aplicando políticas anti-bloat..." -ForegroundColor Cyan

# Consumer Features
New-Item `
    -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
    -Force | Out-Null

New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
    -Name "DisableWindowsConsumerFeatures" `
    -Value 1 `
    -PropertyType DWord `
    -Force | Out-Null

# Sugestões
New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SubscribedContent-338388Enabled" `
    -Value 0 `
    -PropertyType DWord `
    -Force | Out-Null

# Apps sugeridos
New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name "SilentInstalledAppsEnabled" `
    -Value 0 `
    -PropertyType DWord `
    -Force | Out-Null

# ------------------------------------------
# LIMPEZA FINAL
# ------------------------------------------

Write-Host ""
Write-Host "Limpando cache residual..." -ForegroundColor Cyan

Get-AppxPackage -AllUsers |
Where-Object { $_.Name -match "Xbox|Skype|Zune|Bing|Teams" } |
ForEach-Object {

    try {

        Remove-AppxPackage `
            -Package $_.PackageFullName `
            -ErrorAction SilentlyContinue

    }
    catch {}
}

# ------------------------------------------
# FINAL
# ------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Debloat concluído com sucesso." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host ""
Write-Host "Reativando Windows Photo Viewer..." -ForegroundColor Cyan

$photoViewerReg = @"

Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations]
".jpg"="PhotoViewer.FileAssoc.Tiff"
".jpeg"="PhotoViewer.FileAssoc.Tiff"
".png"="PhotoViewer.FileAssoc.Tiff"
".bmp"="PhotoViewer.FileAssoc.Tiff"
".gif"="PhotoViewer.FileAssoc.Tiff"

"@

$tempReg = "$env:TEMP\photoviewer.reg"

$photoViewerReg | Out-File $tempReg -Encoding ASCII

reg import $tempReg

Remove-Item $tempReg -Force

Write-Host "Windows Photo Viewer ativado." -ForegroundColor Green

# OBS:
# Mantidos propositalmente:
# - Microsoft Store
# - Edge
# - WebView2
# - Paint
# - Fotos
# - Calculadora
# - Windows Security
# - Notepad
#
# Para evitar quebra do sistema e problemas
# futuros em suporte técnico.