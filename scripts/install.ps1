# Requer execução como Administrador
#Requires -RunAsAdministrator

function Install-MicrosoftStoreIfLTSC {
    Write-Host "`n🔍 Verificando se é Windows 10/11 LTSC..."

    # Códigos de edição correspondentes ao LTSC
    $osEdition = (Get-WmiObject -Class Win32_OperatingSystem).OperatingSystemSKU
    $isLTSC = $osEdition -in @(125, 126, 145, 146)

    if (-not $isLTSC) {
        Write-Host "ℹ️ Não é edição LTSC. Loja já deve estar disponível."
        return $true
    }

    Write-Host "⚠️ Edição LTSC detectada. Ativando Microsoft Store via comando oficial wsreset -i..."

    try {
        # Comando direto e oficial para instalar/restaurar a Loja
        wsreset -i

        Write-Host "✅ Comando executado. Aguardando finalização do processo..."
        Start-Sleep -Seconds 15 # Tempo necessário para instalação em segundo plano

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
        $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $installerUrl = $release.assets | Where-Object { $_.name -like "*msixbundle" } | Select-Object -ExpandProperty browser_download_url -First 1

        if (-not $installerUrl) {
            throw "Não foi possível obter o link do instalador do Winget."
        }

        $outputFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        Invoke-WebRequest -Uri $installerUrl -OutFile $outputFile -UseBasicParsing
        Add-AppxPackage -Path $outputFile

        # Verifica novamente após instalar
        $wingetExists = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
        if ($wingetExists) {
            Write-Host "✅ Winget instalado com sucesso."
            return $true
        }
        else {
            throw "Instalação concluída, mas o Winget não está acessível. Reinicie o computador para concluir."
        }
    }
    catch {
        Write-Host "❌ Falha ao instalar o Winget: $_"
        return $false
    }
}

function App-Installed($id) {
    $result = winget list --id=$id 2>$null
    return $result -match [regex]::Escape($id)
}

# 1. Se for LTSC, ativa a Microsoft Store com o comando direto
if (-not (Install-MicrosoftStoreIfLTSC)) {
    Write-Host "`n⛔ Não é possível configurar a Microsoft Store. O processo foi interrompido."
    exit 1
}

# 2. Garante que o Winget esteja instalado e funcionando
if (-not (Install-Winget)) {
    Write-Host "`n⛔ Não é possível continuar sem o Winget instalado."
    exit 1
}

# 3. Lista de programas definida (incluindo todos os que você pediu)
$apps = @(
    "Google.Chrome",
    "Python.Python.3",
    "PuTTY.PuTTY",
    "Adobe.Acrobat.Reader.64-bit",
    "AnyDeskSoftwareGmbH.AnyDesk",
    "RustDesk.RustDesk",
    "7-Zip.7-Zip",
    "voidtools.Everything",
    "Microsoft.PowerToys",
    "CrystalDewWorld.CrystalDiskInfo",
    "WiresharkFoundation.Wireshark"
)

# 4. Verifica e instala cada programa da lista
foreach ($app in $apps) {
    if (App-Installed $app) {
        Write-Host "`n✅ $app já está instalado."
    }
    else {
        Write-Host "`n🔄 Instalando $app..."
        try {
            winget install --id=$app -e --silent --accept-package-agreements --accept-source-agreements
            Write-Host "✅ $app instalado com sucesso."
        }
        catch {
            Write-Host "❌ Falha ao instalar $app : $_"
        }
    }
}

# 5. Cria atalho do WhatsApp Web na Área de Trabalho Pública
$shortcutPath = "$env:PUBLIC\Desktop\WhatsApp.lnk"

if (!(Test-Path $shortcutPath)) {
    try {
        $ws = New-Object -ComObject WScript.Shell
        $s = $ws.CreateShortcut($shortcutPath)
        $s.TargetPath = "https://web.whatsapp.com"
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

# 6. Atualiza todos os aplicativos instalados para a versão mais recente
Write-Host "`n🔄 Verificando e aplicando atualizações de todos os programas..."
try {
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Host "`n✅ Todos os programas estão atualizados e prontos para uso!"
}
catch {
    Write-Host "`n⚠️ Ocorreu um erro durante as atualizações: $_"
}