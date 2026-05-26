<#
20260526 00:38:27
# ==========================================
# ADF KIT v4.1 - GUI PROFISSIONAL (CORRIGIDO)
# ==========================================
#>

param()

# ==========================================
# AUTO ELEVAÇÃO ADMIN
# ==========================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# ==========================================
# BIBLIOTECAS
# ==========================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# CONFIGURAÇÕES
# ==========================================

$basePath = "C:\ADF-Kit"
$configPath = Join-Path $basePath "config"
$logPath = "$basePath\Logs"
$cachePath = "$basePath\Cache"
$versionFile = Join-Path $configPath "version.json"

$url = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/pos-formatacao-auto.ps1"

# Criar estrutura de pastas
New-Item -ItemType Directory -Path $basePath  -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $configPath -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $logPath   -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $cachePath -Force -ErrorAction SilentlyContinue | Out-Null

# ==========================================
# FORMULÁRIO
# ==========================================

$form = New-Object Windows.Forms.Form
$form.Text = "ADF Kit v4.1"
$form.Size = New-Object Drawing.Size(550, 430)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::White

# ==========================================
# LABEL CLIENTE
# ==========================================

$labelCliente = New-Object System.Windows.Forms.Label
$labelCliente.Location = New-Object Drawing.Point(10, 25)
$labelCliente.Size = New-Object Drawing.Size(100, 20)
$labelCliente.Text = "Cliente:"
$labelCliente.Font = New-Object Drawing.Font("Arial", 10)
$form.Controls.Add($labelCliente)

# ==========================================
# TEXTBOX CLIENTE
# ==========================================

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object Drawing.Point(120, 20)
$textBox.Size = New-Object Drawing.Size(400, 30)
$textBox.Font = New-Object Drawing.Font("Arial", 10)
$form.Controls.Add($textBox)

# ==========================================
# BOTÃO EXECUTAR
# ==========================================

$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object Drawing.Point(10, 70)
$button.Size = New-Object Drawing.Size(510, 50)
$button.Text = "🚀 EXECUTAR PÓS-FORMATAÇÃO"
$button.Font = New-Object Drawing.Font("Arial", 14, [Drawing.FontStyle]::Bold)
$button.BackColor = [Drawing.Color]::LightGreen
$form.Controls.Add($button)

# ==========================================
# STATUS / LOG VISUAL
# ==========================================

$statusText = New-Object System.Windows.Forms.TextBox
$statusText.Location = New-Object Drawing.Point(10, 130)
$statusText.Size = New-Object Drawing.Size(510, 220)
$statusText.Multiline = $true
$statusText.ScrollBars = "Vertical"
$statusText.ReadOnly = $true
$statusText.Font = New-Object Drawing.Font("Consolas", 9)
$statusText.BackColor = [Drawing.Color]::Black
$statusText.ForeColor = [Drawing.Color]::LightGreen
$statusText.Text = "ADF KIT PRONTO`r`nPreencha o nome do cliente e clique em executar."
$form.Controls.Add($statusText)

# ==========================================
# BOTÃO LOGS
# ==========================================

$btnLogs = New-Object System.Windows.Forms.Button
$btnLogs.Location = New-Object Drawing.Point(10, 360)
$btnLogs.Size = New-Object Drawing.Size(120, 30)
$btnLogs.Text = "📁 Abrir Logs"
$form.Controls.Add($btnLogs)

# ==========================================
# BOTÃO CACHE
# ==========================================

$btnCache = New-Object System.Windows.Forms.Button
$btnCache.Location = New-Object Drawing.Point(140, 360)
$btnCache.Size = New-Object Drawing.Size(120, 30)
$btnCache.Text = "📦 Abrir Cache"
$form.Controls.Add($btnCache)

# ==========================================
# BOTÃO SAIR
# ==========================================

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Location = New-Object Drawing.Point(400, 360)
$btnExit.Size = New-Object Drawing.Size(120, 30)
$btnExit.Text = "❌ Sair"
$form.Controls.Add($btnExit)

# ==========================================
# FUNÇÃO STATUS
# ==========================================

function Write-Status($text) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $statusText.AppendText("[$timestamp] $text`r`n")
    $statusText.SelectionStart = $statusText.TextLength
    $statusText.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Get-SafeClientName {
    param([string]$Name)

    $cleanName = ($Name -replace '[^\w\-\. ]', '').Trim()

    if (-not $cleanName) {
        $cleanName = 'Padrao'
    }

    if ($cleanName.Length -gt 50) {
        $cleanName = $cleanName.Substring(0, 50).TrimEnd()
    }

    return $cleanName
}

function Invoke-ScriptPatch {
    param([string]$Content)

    if ($Content -notmatch '^\s*param\(') {
        $Content = @"
param(
    [string]$Cliente,
    [string]$LogFile
)

$Content
"@
    }

    $Content = $Content -replace '\$cliente\s*=\s*Read-Host\s+"Nome do cliente"', '$cliente = $Cliente'
    $Content = $Content -replace 'Start-Transcript\s+-Path\s+.*', 'Start-Transcript -Path $LogFile'

    return $Content
}

# ==========================================
# EXECUTAR PROCESSO
# ==========================================

$button.Add_Click({
        $cliente = Get-SafeClientName -Name $textBox.Text

        # Validação do nome
        if (-not $cliente) {
            [System.Windows.Forms.MessageBox]::Show(
                "Digite o nome do cliente antes de continuar.",
                "ADF KIT - Aviso",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        $button.Enabled = $false
        $logFile = Join-Path $logPath "$cliente-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        $scriptLocal = Join-Path $cachePath "pos-formatacao-auto.ps1"
        $scriptLocalTemp = Join-Path $cachePath "pos-formatacao-auto.ps1.tmp"

        Write-Status "=========================================="
        Write-Status "Cliente informado: $cliente"
        Write-Status "Iniciando processo..."

        try {
            $needsUpdate = $false
            try {
                $updateState = & (Join-Path $PSScriptRoot 'core\updater.ps1') -LocalVersionFile $versionFile -ReturnState
                if ($updateState -and $updateState.PSObject.Properties['NeedsUpdate']) {
                    $needsUpdate = [bool]$updateState.NeedsUpdate
                }
            }
            catch {
                Write-Status "Não foi possível validar a versão remota. Tentando usar cache local."
            }

            $conteudoScript = $null

            if ($needsUpdate -or -not (Test-Path $scriptLocal)) {
                Write-Status "Baixando script principal..."
                $conteudoScript = irm -Uri $url -ErrorAction Stop
                if (-not $conteudoScript) {
                    throw "Conteúdo do script remoto está vazio."
                }

                Write-Status "Download concluído com sucesso."
                Write-Status "Ajustando script para compatibilidade..."
                $conteudoScript = Invoke-ScriptPatch -Content $conteudoScript
                $conteudoScript | Set-Content -Path $scriptLocalTemp -Encoding UTF8 -Force -ErrorAction Stop
                Move-Item -Path $scriptLocalTemp -Destination $scriptLocal -Force -ErrorAction Stop

                if ($needsUpdate) {
                    & (Join-Path $PSScriptRoot 'core\updater.ps1') -LocalVersionFile $versionFile | Out-Null
                }

                Write-Status "Ajustes finalizados. Executando..."
            }
            else {
                Write-Status "Usando script local em cache."
                $conteudoScript = Get-Content -Path $scriptLocal -Raw -ErrorAction Stop
                $conteudoScript = Invoke-ScriptPatch -Content $conteudoScript
                $conteudoScript | Set-Content -Path $scriptLocal -Encoding UTF8 -Force -ErrorAction Stop
            }

            # Executa o script passando os parâmetros
            $process = Start-Process -FilePath "powershell.exe" `
                -ArgumentList @(
                "-ExecutionPolicy", "Bypass",
                "-NoProfile",
                "-File", $scriptLocal,
                "-Cliente", $cliente,
                "-LogFile", $logFile
            ) `
                -WindowStyle Normal `
                -PassThru `
                -ErrorAction Stop

            Write-Status "Processo iniciado. PID: $($process.Id)"
            Write-Status "Aguardando finalização..."

            $process.WaitForExit()

            Write-Status "Processo finalizado. Código de saída: $($process.ExitCode)"

            if (Test-Path $logFile) {
                Write-Status "Log gerado com sucesso em:"
                Write-Status "$logFile"
            }
            else {
                Write-Status "AVISO: Arquivo de log não foi encontrado."
            }

            [System.Windows.Forms.MessageBox]::Show(
                "Processo finalizado!`r`nLog salvo em: $logFile",
                "ADF KIT - Concluído",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

        }
        catch {
            $erroMsg = $_.Exception.Message
            Write-Status "ERRO: $erroMsg"

            [System.Windows.Forms.MessageBox]::Show(
                "Ocorreu um erro:`r`n$erroMsg",
                "ADF KIT - Erro",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
        finally {
            $button.Enabled = $true
            Write-Status "=========================================="
        }
    })

# ==========================================
# ABRIR PASTA DE LOGS
# ==========================================

$btnLogs.Add_Click({
        if (Test-Path $logPath) {
            Start-Process explorer.exe $logPath
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Pasta de logs não encontrada.", "Aviso", 0, 48)
        }
    })

# ==========================================
# ABRIR PASTA DE CACHE
# ==========================================

$btnCache.Add_Click({
        if (Test-Path $cachePath) {
            Start-Process explorer.exe $cachePath
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Pasta de cache não encontrada.", "Aviso", 0, 48)
        }
    })

# ==========================================
# BOTÃO SAIR
# ==========================================

$btnExit.Add_Click({
        $form.Close()
    })

# ==========================================
# INICIAR INTERFACE
# ==========================================

$textBox.Focus()
[void]$form.ShowDialog()