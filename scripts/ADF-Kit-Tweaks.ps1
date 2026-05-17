# ==========================================
# ADF-Kit - Safe Windows Maintenance Toolkit
# Base inspirado em boas práticas do WinUtil
# ==========================================

# Requer execução como Administrador

# -------------------------------
# Verificação de privilégios
# -------------------------------

# ==========================================
# AUTO ELEVAÇÃO ADMIN
# ==========================================

if (-not ([Security.Principal.WindowsPrincipal]  [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# -------------------------------
# Banner
# -------------------------------

Clear-Host
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "         ADF-Kit Maintenance Tool          " -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# -------------------------------
# Funções Utilitárias
# -------------------------------

function Write-Section {
    param([string]$Text)

    Write-Host ""
    Write-Host "==== $Text ====" -ForegroundColor Yellow
}

function Create-RestorePoint {
    Write-Section "Criando ponto de restauração"

    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "ADF-Kit Restore Point" -RestorePointType "MODIFY_SETTINGS"

        Write-Host "Ponto de restauração criado com sucesso." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao criar ponto de restauração." -ForegroundColor Red
    }
}

# -------------------------------
# Tweaks Seguros
# -------------------------------

function Enable-FileExtensions {
    Write-Section "Exibindo extensões de arquivos"

    Set-ItemProperty \
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" \
    -Name HideFileExt \
    -Value 0

    Write-Host "Extensões habilitadas." -ForegroundColor Green
}

function Enable-HiddenFiles {
    Write-Section "Exibindo arquivos ocultos"

    Set-ItemProperty \
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" \
    -Name Hidden \
    -Value 1

    Write-Host "Arquivos ocultos habilitados." -ForegroundColor Green
}

function Disable-StartMenuSuggestions {
    Write-Section "Desabilitando sugestões do Menu Iniciar"

    Set-ItemProperty \
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" \
    -Name SystemPaneSuggestionsEnabled \
    -Value 0

    Write-Host "Sugestões desabilitadas." -ForegroundColor Green
}

function Disable-BingSearch {
    Write-Section "Desabilitando Bing Search no Menu Iniciar"

    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null

    Set-ItemProperty \
    -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" \
    -Name DisableSearchBoxSuggestions \
    -Value 1

    Write-Host "Bing Search desabilitado." -ForegroundColor Green
}

function Set-ExplorerThisPC {
    Write-Section "Definindo Explorer para abrir em Este Computador"

    Set-ItemProperty \
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" \
    -Name LaunchTo \
    -Value 1

    Write-Host "Explorer configurado." -ForegroundColor Green
}

# -------------------------------
# Limpeza e Manutenção
# -------------------------------

function Clear-TempFiles {
    Write-Section "Limpando arquivos temporários"

    try {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Arquivos temporários removidos." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha parcial na limpeza." -ForegroundColor Yellow
    }
}

function Flush-DNS {
    Write-Section "Limpando cache DNS"

    ipconfig /flushdns
}

function Repair-WindowsImage {
    Write-Section "Reparando imagem do Windows"

    DISM /Online /Cleanup-Image /RestoreHealth
}

function Run-SystemFileChecker {
    Write-Section "Executando SFC"

    sfc /scannow
}

# -------------------------------
# Winget e Programas Essenciais
# -------------------------------

function Install-BasicApps {
    Write-Section "Instalando aplicativos básicos"

    $apps = @(
        "7zip.7zip",
        "Google.Chrome",
        "Mozilla.Firefox",
        "VideoLAN.VLC",
        "Adobe.Acrobat.Reader.64-bit",
        "Notepad++.Notepad++",
        "AnyDeskSoftwareGmbH.AnyDesk",
        "Microsoft.VisualStudioCode"
    )

    foreach ($app in $apps) {
        Write-Host "Instalando: $app"

        winget install --id $app --silent --accept-package-agreements --accept-source-agreements
    }
}

function Install-Runtimes {
    Write-Section "Instalando runtimes"

    $packages = @(
        "Microsoft.VCRedist.2015+.x64",
        "Microsoft.DotNet.DesktopRuntime.8",
        "Microsoft.EdgeWebView2Runtime"
    )

    foreach ($pkg in $packages) {
        Write-Host "Instalando: $pkg"

        winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements
    }
}

# -------------------------------
# Otimizações Seguras
# -------------------------------

function Set-HighPerformancePowerPlan {
    Write-Section "Ativando plano de energia de alto desempenho"

    powercfg -setactive SCHEME_MIN
}

function Disable-BackgroundApps {
    Write-Section "Desabilitando apps em segundo plano"

    New-Item \
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" \
    -Force | Out-Null

    Set-ItemProperty \
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" \
    -Name GlobalUserDisabled \
    -Value 1

    Write-Host "Apps em segundo plano desabilitados." -ForegroundColor Green
}

# -------------------------------
# Atualizações
# -------------------------------

function Update-WingetPackages {
    Write-Section "Atualizando aplicativos via Winget"

    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
}

# -------------------------------
# Menu Principal
# -------------------------------

function Show-Menu {
    Write-Host ""
    Write-Host "1 - Criar ponto de restauração"
    Write-Host "2 - Aplicar tweaks seguros"
    Write-Host "3 - Limpar temporários"
    Write-Host "4 - Reparar Windows (DISM + SFC)"
    Write-Host "5 - Instalar aplicativos básicos"
    Write-Host "6 - Instalar runtimes"
    Write-Host "7 - Atualizar programas Winget"
    Write-Host "8 - Aplicar otimizações seguras"
    Write-Host "0 - Sair"
    Write-Host ""
}

# -------------------------------
# Execuções agrupadas
# -------------------------------

function Run-SafeTweaks {
    Enable-FileExtensions
    Enable-HiddenFiles
    Disable-StartMenuSuggestions
    Disable-BingSearch
    Set-ExplorerThisPC
}

function Run-SafeOptimizations {
    Set-HighPerformancePowerPlan
    Disable-BackgroundApps
}

function Run-WindowsRepair {
    Repair-WindowsImage
    Run-SystemFileChecker
}

# -------------------------------
# Loop principal
# -------------------------------

while ($true) {

    Show-Menu

    $option = Read-Host "Escolha uma opção"

    switch ($option) {

        "1" {
            Create-RestorePoint
        }

        "2" {
            Run-SafeTweaks
        }

        "3" {
            Clear-TempFiles
            Flush-DNS
        }

        "4" {
            Run-WindowsRepair
        }

        "5" {
            Install-BasicApps
        }

        "6" {
            Install-Runtimes
        }

        "7" {
            Update-WingetPackages
        }

        "8" {
            Run-SafeOptimizations
        }

        "0" {
            break
        }

        default {
            Write-Host "Opção inválida." -ForegroundColor Red
        }
    }

    Pause
}
