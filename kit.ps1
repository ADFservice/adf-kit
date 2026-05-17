# ==========================================
# ADF KIT v4.1 - GUI PROFISSIONAL
# ==========================================

param()

# ==========================================
# AUTO ELEVAÇÃO ADMIN
# ==========================================

if (-not ([Security.Principal.WindowsPrincipal]
        [Security.Principal.WindowsIdentity]::GetCurrent()
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
$logPath = "$basePath\Logs"
$cachePath = "$basePath\Cache"

$url = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/pos-formatacao-auto.ps1"

# Criar estrutura
New-Item -ItemType Directory -Path $basePath  -Force -ErrorAction SilentlyContinue | Out-Null
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
$statusText.Text = "ADF KIT PRONTO"
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

# ==========================================
# EXECUTAR
# ==========================================

$button.Add_Click({

        $cliente = $textBox.Text.Trim()

        if (-not $cliente) {

            [System.Windows.Forms.MessageBox]::Show(
                "Digite o nome do cliente.",
                "ADF KIT",
                "OK",
                "Warning"
            )

            return
        }

        $button.Enabled = $false

        $logFile = Join-Path $logPath "$cliente-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

        $scriptLocal = Join-Path $cachePath "pos-formatacao-auto.ps1"

        Write-Status "Cliente: $cliente"
        Write-Status "Iniciando download..."

        try {

            # ==========================================
            # DOWNLOAD SCRIPT
            # ==========================================

            Invoke-WebRequest `
                -Uri $url `
                -OutFile $scriptLocal `
                -UseBasicParsing

            Write-Status "Download concluído."
            Write-Status "Script salvo em:"
            Write-Status $scriptLocal

            # ==========================================
            # EXECUTAR SCRIPT
            # ==========================================

            Write-Status "Executando pós-formatação..."

            $arguments = @(
                "-ExecutionPolicy Bypass"
                "-File `"$scriptLocal`""
                "-Cliente `"$cliente`""
                "-LogFile `"$logFile`""
            ) -join " "

            $process = Start-Process `
                -FilePath "powershell.exe" `
                -ArgumentList $arguments `
                -WindowStyle Normal `
                -PassThru

            Write-Status "PID: $($process.Id)"
            Write-Status "Aguardando finalização..."

            $process.WaitForExit()

            Write-Status "Finalizado."
            Write-Status "ExitCode: $($process.ExitCode)"

            # ==========================================
            # ABRIR LOG
            # ==========================================

            if (Test-Path $logFile) {

                Write-Status "Log salvo em:"
                Write-Status $logFile
            }

        }
        catch {

            Write-Status "ERRO:"
            Write-Status $_.Exception.Message

            [System.Windows.Forms.MessageBox]::Show(
                $_.Exception.Message,
                "ERRO",
                "OK",
                "Error"
            )
        }
        finally {

            $button.Enabled = $true
        }
    })

# ==========================================
# BOTÃO LOGS
# ==========================================

$btnLogs.Add_Click({

        Start-Process explorer.exe $logPath
    })

# ==========================================
# BOTÃO CACHE
# ==========================================

$btnCache.Add_Click({

        Start-Process explorer.exe $cachePath
    })

# ==========================================
# BOTÃO SAIR
# ==========================================

$btnExit.Add_Click({

        $form.Close()
    })

# ==========================================
# MOSTRAR
# ==========================================

$textBox.Focus()

[void]$form.ShowDialog()