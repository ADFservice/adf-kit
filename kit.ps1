# ADF KIT v4.0 - SIMPLES E INFALÍVEL
param()

# ADMIN CHECK
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# CONFIG
$logPath = "C:\ADF-Kit\Logs"
$url = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/pos-formatacao-auto.ps1"
New-Item -ItemType Directory -Path $logPath -Force -ErrorAction SilentlyContinue | Out-Null

# FORM
$form = New-Object Windows.Forms.Form
$form.Text = "ADF Kit v4.0"
$form.Size = New-Object Drawing.Size(550, 400)
$form.StartPosition = "CenterScreen"

# CLIENTE
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object Drawing.Point(120, 20)
$textBox.Size = New-Object Drawing.Size(400, 30)
$textBox.Font = New-Object Drawing.Font("Arial", 10)
$form.Controls.Add($textBox)

$labelCliente = New-Object System.Windows.Forms.Label
$labelCliente.Location = New-Object Drawing.Point(10, 25)
$labelCliente.Size = New-Object Drawing.Size(100, 20)
$labelCliente.Text = "Cliente:"
$form.Controls.Add($labelCliente)

# BOTÃO EXECUTAR
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object Drawing.Point(10, 70)
$button.Size = New-Object Drawing.Size(510, 50)
$button.Text = "🚀 EXECUTAR PÓS-FORMATAÇÃO"
$button.Font = New-Object Drawing.Font("Arial", 14, [Drawing.FontStyle]::Bold)
$button.BackColor = [Drawing.Color]::LightGreen
$form.Controls.Add($button)

# STATUS TEXTBOX
$statusText = New-Object System.Windows.Forms.TextBox
$statusText.Location = New-Object Drawing.Point(10, 130)
$statusText.Size = New-Object Drawing.Size(530, 220)
$statusText.Multiline = $true
$statusText.ScrollBars = "Vertical"
$statusText.ReadOnly = $true
$statusText.Font = New-Object Drawing.Font("Consolas", 9)
$statusText.Text = "Status: Pronto"
$form.Controls.Add($statusText)

# BOTÃO LOGS
$btnLogs = New-Object System.Windows.Forms.Button
$btnLogs.Location = New-Object Drawing.Point(10, 360)
$btnLogs.Size = New-Object Drawing.Size(100, 30)
$btnLogs.Text = "📁 Logs"
$form.Controls.Add($btnLogs)

# FUNÇÃO STATUS
function Write-Status($text) {
    $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): $text`n")
    $statusText.SelectionStart = $statusText.TextLength
    $statusText.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# CLICK EXECUTAR
$button.Add_Click({
        $cliente = $textBox.Text.Trim()
        if (-not $cliente) {
            [System.Windows.Forms.MessageBox]::Show("Digite o cliente!", "Erro", "OK", "Warning")
            return
        }
    
        $logFile = Join-Path $logPath "$cliente-$(Get-Date -f 'yyyyMMdd-HHmmss').log"
        Write-Status "Iniciando para cliente: $cliente"
        Write-Status "Log: $logFile"
    
        try {
            # DOWNLOAD
            Write-Status "Baixando script..."
            $web = New-Object Net.WebClient
            $web.Headers.Add("User-Agent", "Mozilla/5.0")
            $scriptContent = $web.DownloadString($url)
        
            $scriptLocal = Join-Path $logPath "$cliente-script.ps1"
            $scriptContent | Out-File -FilePath $scriptLocal -Encoding UTF8
        
            "=== $(Get-Date) Cliente: $cliente ===" | Out-File $logFile -Encoding UTF8
            Write-Status "Script baixado OK"
        
            # EXECUTAR
            Write-Status "Executando..."
            $arguments = "-ExecutionPolicy Bypass -File `"$scriptLocal`" -Cliente `"$cliente`" -LogFile `"$logFile`""
            $process = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -WindowStyle Normal -PassThru
        
            # MONITORAR
            while (-not $process.HasExited) {
                Write-Status "Rodando... PID: $($process.Id)"
                Start-Sleep 3
                [System.Windows.Forms.Application]::DoEvents()
            }
        
            Write-Status "Finalizado! ExitCode: $($process.ExitCode)"
            "ExitCode: $($process.ExitCode)" | Add-Content $logFile
        
        }
        catch {
            Write-Status "ERRO: $($_.Exception.Message)"
        }
        finally {
            if (Test-Path $scriptLocal) { Remove-Item $scriptLocal -Force -ErrorAction SilentlyContinue }
        }
    })

# LOGS
$btnLogs.Add_Click({
        Start-Process explorer.exe $logPath
    })

# MOSTRAR
$textBox.Focus()
$form.ShowDialog()