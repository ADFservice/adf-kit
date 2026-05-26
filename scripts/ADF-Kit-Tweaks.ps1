20260526 00:46:56 || # ==========================================
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

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
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
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "ADF-Kit Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "Ponto de restauração criado com sucesso." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao criar ponto de restauração: $_" -ForegroundColor Red
    }
}

# ==========================================
# INSTALAÇÃO AUTOMÁTICA DO WINGET
# ==========================================
function Install-Winget {
    Write-Section "Verificando e Instalando Winget"

    # Verifica se o Winget já está disponível
    try {
        Get-Command winget -ErrorAction Stop | Out-Null
        Write-Host "Winget já está instalado e funcionando." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Winget não encontrado. Iniciando instalação..." -ForegroundColor Yellow
    }

    try {
        # Define URLs para download dos pacotes necessários
        $uiLibUrl = "https://aka.ms/Microsoft.UI.Xaml.2.8_64bit"
        $wingetUrl = "https://aka.ms/getwinget"

        # Cria diretório temporário
        $tempPath = "$env:TEMP\ADFKit_Install"
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

        $uiLibPath = "$tempPath\Microsoft.UI.Xaml.2.8.msix"
        $wingetPath = "$tempPath\AppInstaller.msixbundle"

        Write-Host "Baixando dependências..."
        Invoke-WebRequest -Uri $uiLibUrl -OutFile $uiLibPath -UseBasicParsing
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath -UseBasicParsing

        Write-Host "Instalando dependência Microsoft.UI.Xaml..."
        Add-AppxPackage -Path $uiLibPath -ErrorAction Stop

        Write-Host "Instalando Winget (App Installer)..."
        Add-AppxPackage -Path $wingetPath -ErrorAction Stop

        # Limpeza dos arquivos temporários
        Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue

        # Verifica novamente após instalação
        Start-Sleep -Seconds 3
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Winget instalado com sucesso!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Instalação concluída, mas pode ser necessário reiniciar o terminal para usar o Winget." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "Falha durante a instalação do Winget: $_" -ForegroundColor Red
        return $false
    }
}

function Test-WingetAvailable {
    # Primeiro tenta instalar se não existir
    return Install-Winget
}

# -------------------------------
# Tweaks Seguros
# -------------------------------

function Enable-FileExtensions {
    Write-Section "Exibindo extensões de arquivos"
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0 -ErrorAction Stop
        Write-Host "Extensões habilitadas." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao habilitar extensões: $_" -ForegroundColor Red
    }
}

function Enable-HiddenFiles {
    Write-Section "Exibindo arquivos ocultos"
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1 -ErrorAction Stop
        Write-Host "Arquivos ocultos habilitados." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao habilitar arquivos ocultos: $_" -ForegroundColor Red
    }
}

function Disable-StartMenuSuggestions {
    Write-Section "Desabilitando sugestões do Menu Iniciar"
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SystemPaneSuggestionsEnabled -Value 0 -ErrorAction Stop
        Write-Host "Sugestões desabilitadas." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao desabilitar sugestões: $_" -ForegroundColor Red
    }
}

function Disable-BingSearch {
    Write-Section "Desabilitando Bing Search no Menu Iniciar"
    try {
        $regPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name DisableSearchBoxSuggestions -Value 1 -ErrorAction Stop
        Write-Host "Bing Search desabilitado." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao desabilitar Bing Search: $_" -ForegroundColor Red
    }
}

function Set-ExplorerThisPC {
    Write-Section "Definindo Explorer para abrir em Este Computador"
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name LaunchTo -Value 1 -ErrorAction Stop
        Write-Host "Explorer configurado." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao configurar Explorer: $_" -ForegroundColor Red
    }
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
        Write-Host "Falha parcial na limpeza: $_" -ForegroundColor Yellow
    }
}

function Flush-DNS {
    Write-Section "Limpando cache DNS"
    try {
        ipconfig /flushdns | Out-Null
        Write-Host "Cache DNS limpo." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao limpar cache DNS: $_" -ForegroundColor Red
    }
}

function Repair-WindowsImage {
    Write-Section "Reparando imagem do Windows"
    try {
        DISM /Online /Cleanup-Image /RestoreHealth /ErrorAction Stop
        Write-Host "Reparo da imagem concluído." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha no reparo da imagem: $_" -ForegroundColor Red
    }
}

function Run-SystemFileChecker {
    Write-Section "Executando SFC"
    try {
        sfc /scannow
        Write-Host "Verificação de arquivos concluída." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha na execução do SFC: $_" -ForegroundColor Red
    }
}

# -------------------------------
# Winget e Programas Essenciais
# -------------------------------

function Install-BasicApps {
    Write-Section "Instalando aplicativos básicos"
    if (-not (Test-WingetAvailable)) {
        Write-Host "Não foi possível continuar sem o Winget instalado." -ForegroundColor Red
        return
    }

    $apps = @(
        # === Aplicativos Originais ===
        "7zip.7zip",
        "Google.Chrome",
        "Mozilla.Firefox",
        "VideoLAN.VLC",
        "Adobe.Acrobat.Reader.64-bit",
        "Notepad++.Notepad++",
        "AnyDeskSoftwareGmbH.AnyDesk",
        "Microsoft.VisualStudioCode",

        # === Novos - Produtividade ===
        "Microsoft.PowerToys",          # Ferramentas oficiais da Microsoft para produtividade
        "ShareX.ShareX",                # Captura de tela, gravação e anotações
        "QNAP.QDir",                    # Gerenciador de arquivos avançado e leve
        "Obsidian.Obsidian",            # Anotações e organização de conhecimento

        # === Novos - Manutenção e Diagnóstico ===
        "CrystalDewWorld.CrystalDiskInfo", # Verifica saúde e temperatura de Discos/SSDs
        "Microsoft.SysinternalsSuite",  # Ferramentas avançadas de sistema e diagnóstico
        "CCleaner.CCleaner",            # Limpeza completa de sistema e registros
        "DefenderUI.DefenderUI",        # Interface aprimorada para o Windows Defender

        # === Novos - Utilitários Gerais ===
        "Bitwarden.Bitwarden",          # Gerenciador de senhas seguro
        "HandBrake.HandBrake",          # Conversor e otimizador de vídeo
        "GlavSoft.TinyWall"             # Firewall leve e eficaz
    )

    foreach ($app in $apps) {
        Write-Host "Instalando: $app"
        try {
            winget install --id $app --silent --accept-package-agreements --accept-source-agreements -ErrorAction Stop
            Write-Host "$app instalado com sucesso." -ForegroundColor Green
        }
        catch {
            Write-Host "Falha ao instalar $app : $_" -ForegroundColor Yellow
        }
    }
}

function Install-Runtimes {
    Write-Section "Instalando runtimes"
    if (-not (Test-WingetAvailable)) {
        Write-Host "Não foi possível continuar sem o Winget instalado." -ForegroundColor Red
        return
    }

    $packages = @(
        "Microsoft.VCRedist.2015+.x64",
        "Microsoft.DotNet.DesktopRuntime.8",
        "Microsoft.EdgeWebView2Runtime"
    )

    foreach ($pkg in $packages) {
        Write-Host "Instalando: $pkg"
        try {
            winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements -ErrorAction Stop
            Write-Host "$pkg instalado com sucesso." -ForegroundColor Green
        }
        catch {
            Write-Host "Falha ao instalar $pkg : $_" -ForegroundColor Yellow
        }
    }
}

# -------------------------------
# Otimizações Seguras
# -------------------------------

function Set-HighPerformancePowerPlan {
    Write-Section "Ativando plano de energia de alto desempenho"
    try {
        $planExists = powercfg /list | Select-String "SCHEME_MIN"
        if ($planExists) {
            powercfg -setactive SCHEME_MIN
            Write-Host "Plano de alto desempenho ativado." -ForegroundColor Green
        }
        else {
            Write-Host "Plano de energia não encontrado neste sistema." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Falha ao alterar plano de energia: $_" -ForegroundColor Red
    }
}

function Disable-BackgroundApps {
    Write-Section "Desabilitando apps em segundo plano"
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name GlobalUserDisabled -Value 1 -ErrorAction Stop
        Write-Host "Apps em segundo plano desabilitados." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao desabilitar apps em segundo plano: $_" -ForegroundColor Red
    }
}

# -------------------------------
# Atualizações
# -------------------------------

function Update-WingetPackages {
    Write-Section "Atualizando aplicativos via Winget"
    if (-not (Test-WingetAvailable)) {
        Write-Host "Não foi possível continuar sem o Winget instalado." -ForegroundColor Red
        return
    }

    try {
        winget upgrade --all --silent --accept-package-agreements --accept-source-agreements -ErrorAction Stop
        Write-Host "Atualizações concluídas." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha nas atualizações: $_" -ForegroundColor Red
    }
}

# -------------------------------
# Menu Principal
# -------------------------------

function Show-Menu {
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "           MENU PRINCIPAL                 " -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "1 - Criar ponto de restauração"
    Write-Host "2 - Aplicar tweaks seguros (Explorador e Menu)"
    Write-Host "3 - Limpar arquivos temporários e cache DNS"
    Write-Host "4 - Reparar Windows (DISM + SFC)"
    Write-Host "5 - Instalar aplicativos básicos e otimizados"
    Write-Host "6 - Instalar Runtimes essenciais"
    Write-Host "7 - Atualizar todos os programas instalados"
    Write-Host "8 - Aplicar otimizações de desempenho"
    Write-Host "0 - Sair"
    Write-Host "===========================================" -ForegroundColor Cyan
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
        "1" { Create-RestorePoint }
        "2" { Run-SafeTweaks }
        "3" { Clear-TempFiles; Flush-DNS }
        "4" { Run-WindowsRepair }
        "5" { Install-BasicApps }
        "6" { Install-Runtimes }
        "7" { Update-WingetPackages }
        "8" { Run-SafeOptimizations }
        "0" { break }
        default { Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red }
    }

    Write-Host ""
    Pause
}