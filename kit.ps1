# =====================================
# ADF KIT v2.2 - COMPLETO E FUNCIONANDO
# =====================================

# ADMIN CHECK
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configurações
$logPath = "C:\ADF-Kit\Logs\"
$url = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/pos-formatacao-auto.ps1"

if (!(Test-Path $logPath)) { 
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null 
}

# FORM PRINCIPAL
$form = New-Object Windows.Forms.Form
$form.Text = "ADF Kit v2.2 - Pós-Formatação"
$form.Size = New-Object System.Drawing.Size(520, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# TÍTULO
$lblTitulo = New-Object Windows.Forms.Label
$lblTitulo.Text = "🚀 ADF Kit - Pós-Formatação Inteligente"
$lblTitulo.Location = New-Object System.Drawing.Point(20, 10)
$lblTitulo.Size = New-Object System.Drawing.Size(480, 30)
$lblTitulo.Font = (New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold))
$lblTitulo.ForeColor = [System.Drawing.Color]::DarkBlue
$form.Controls.Add($lblTitulo)

# CLIENTE
$lblCliente = New-Object Windows.Forms.Label
$lblCliente.Text = "👤 Nome do Cliente:"
$lblCliente.Location = New-Object System.Drawing.Point(20, 50)
$lblCliente.Size = New-Object System.Drawing.Size(130, 25)
$form.Controls.Add($lblCliente)

$txtCliente = New-Object Windows.Forms.TextBox
$txtCliente.Location = New-Object System.Drawing.Point(160, 50)
$txtCliente.Size = New-Object System.Drawing.Size(320, 25)
$form.Controls.Add($txtCliente)

# BOTÃO TESTE REDE
$btnTesteRede = New-Object Windows.Forms.Button
$btnTesteRede.Text = "🧪 Testar Rede"
$btnTesteRede.Location = New-Object System.Drawing.Point(20, 85)
$btnTesteRede.Size = New-Object System.Drawing.Size(120, 35)
$btnTesteRede.BackColor = [System.Drawing.Color]::LightYellow
$form.Controls.Add($btnTesteRede)

# BOTÃO EXECUTAR
$btnExecutar = New-Object Windows.Forms.Button
$btnExecutar.Text = "🚀 EXECUTAR KIT"
$btnExecutar.Location = New-Object System.Drawing.Point(155, 85)
$btnExecutar.Size = New-Object System.Drawing.Size(325, 35)
$btnExecutar.BackColor = [System.Drawing.Color]::LightGreen
$btnExecutar.Font = (New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold))
$form.Controls.Add($btnExecutar)

# STATUS
$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = "Status: Pronto para executar"
$lblStatus.Location = New-Object System.Drawing.Point(20, 130)
$lblStatus.Size = New-Object System.Drawing.Size(480, 80)
$lblStatus.Font = (New-Object System.Drawing.Font("Consolas", 9))
$lblStatus.ForeColor = [System.Drawing.Color]::Gray
$lblStatus.BorderStyle = "FixedSingle"
$form.Controls.Add($lblStatus)

# PROGRESSBAR
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 220)
$progressBar.Size = New-Object System.Drawing.Size(480, 25)
$progressBar.Style = "Marquee"
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# LOGS
$lblLogs = New-Object Windows.Forms.Label
$lblLogs.Text = "📁 Logs salvos em: C:\ADF-Kit\Logs\"
$lblLogs.Location = New-Object System.Drawing.Point(20, 255)
$lblLogs.Size = New-Object System.Drawing.Size(480, 20)
$lblLogs.Font = (New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Italic))
$lblLogs.ForeColor = [System.Drawing.Color]::DarkGreen
$form.Controls.Add($lblLogs)

$btnAbrirLogs = New-Object Windows.Forms.Button
$btnAbrirLogs.Text = "📂 Abrir Logs"
$btnAbrirLogs.Location = New-Object System.Drawing.Point(20, 280)
$btnAbrirLogs.Size = New-Object System.Drawing.Size(120, 30)
$btnAbrirLogs.BackColor = [System.Drawing.Color]::LightBlue
$form.Controls.Add($btnAbrirLogs)

# CANCELAR
$btnCancelar = New-Object Windows.Forms.Button
$btnCancelar.Text = "⛔ Cancelar"
$btnCancelar.Location = New-Object System.Drawing.Point(420, 280)
$btnCancelar.Size = New-Object System.Drawing.Size(80, 30)
$btnCancelar.BackColor = [System.Drawing.Color]::LightCoral
$btnCancelar.Enabled = $false
$form.Controls.Add($btnCancelar)

# VARIÁVEIS GLOBAIS
$script:processo = $null
$script:cancelando = $false

# FUNÇÃO STATUS
function Update-Status($texto, $cor = "Gray") {
    $lblStatus.Text = "$(Get-Date -Format 'HH:mm:ss') - $texto"
    $lblStatus.ForeColor = $cor
    $form.Refresh()
    Start-Sleep -Milliseconds 100
}

# EVENTO: TESTAR REDE
$btnTesteRede.Add_Click({
        Update-Status "Testando conexão..." "Orange"
    
        $testes = @(
            @{Nome = "Internet (Google)"; Url = "http://www.google.com"; Metodo = "Head" }
            @{Nome = "GitHub"; Url = "https://github.com"; Metodo = "Head" }
            @{Nome = "Script ADF"; Url = $url; Metodo = "Get" }
        )
    
        $resultados = @()
        foreach ($teste in $testes) {
            try {
                $res = Invoke-WebRequest -Uri $teste.Url -Method $teste.Metodo -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop
                $resultados += "✅ $($teste.Nome) - OK ($([math]::Round($res.Headers.'Content-Length'[0]/1KB,1)) KB)"
            }
            catch {
                $resultados += "❌ $($teste.Nome) - $($_.Exception.Message.Split("`r`n")[0])"
            }
        }
    
        Update-Status ($resultados -join "`n") "Blue"
        [System.Windows.Forms.MessageBox]::Show(($resultados -join "`n"), "Resultado Rede", "OK", "Information")
    })

# EVENTO: EXECUTAR
$btnExecutar.Add_Click({
        $cliente = $txtCliente.Text.Trim()
        if ([string]::IsNullOrEmpty($cliente)) {
            [System.Windows.Forms.MessageBox]::Show("Informe o nome do cliente!", "Erro", "OK", "Warning")
            return
        }
    
        # Preparar
        $logFile = "$logPath\$cliente-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        $btnExecutar.Enabled = $false
        $btnCancelar.Enabled = $true
        $progressBar.Visible = $true
        $script:cancelando = $false
    
        # PASSO 1: TESTE REDE RÁPIDO
        Update-Status "1/4 Testando rede..." "Orange"
        try {
            $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 5 -UseBasicParsing
        }
        catch {
            Update-Status "SEM INTERNET! Conecte-se e tente novamente." "Red"
            return
        }
    
        # PASSO 2: DOWNLOAD
        Update-Status "2/4 Baixando script ($([math]::Round((Invoke-WebRequest $url -UseBasicParsing).Content.Length/1KB,1)) KB)..." "Blue"
        try {
            $scriptContent = Invoke-WebRequest -Uri $url -TimeoutSec 30 -UseBasicParsing
            $scriptPath = "$logPath\$cliente-script.ps1"
            $scriptContent.Content | Out-File $scriptPath -Encoding UTF8
        
            "`n=== INÍCIO $(Get-Date) ===`nCliente: $cliente" | Out-File $logFile -Encoding UTF8
            "Script baixado: $scriptPath" | Out-File $logFile -Append -Encoding UTF8
        
            Update-Status "✅ Script baixado! 3/4 Executando..." "Green"
        }
        catch {
            Update-Status "ERRO DOWNLOAD: $($_.Exception.Message)" "Red"
            return
        }
    
        # PASSO 3: EXECUTAR
        try {
            $paramString = "-Cliente `"$cliente`" -LogPath `"$logPath`" -LogFile `"$logFile`""
        
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "powershell.exe"
            $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $paramString"
            $processInfo.WindowStyle = "Hidden"
            $processInfo.UseShellExecute = $false
        
            Update-Status "🔄 Executando pós-formatação..." "Blue"
            $script:processo = [System.Diagnostics.Process]::Start($processInfo)
        
            # Aguardar com timeout
            if ($script:processo.WaitForExit(600000)) {
                # 10 minutos
                $exitCode = $script:processo.ExitCode
                if ($exitCode -eq 0) {
                    Update-Status "🎉 SUCESSO! ExitCode: $exitCode | Log: $logFile" "DarkGreen"
                }
                else {
                    Update-Status "⚠️ Concluído com warnings (ExitCode: $exitCode) | Log: $logFile" "Orange"
                }
            }
            else {
                Update-Status "⏰ TIMEOUT (10min) - Finalizando..." "DarkOrange"
                $script:processo.Kill()
            }
        }
        catch {
            Update-Status "ERRO EXECUÇÃO: $($_.Exception.Message)" "Red"
        }
        finally {
            # LIMPEZA
            if (Test-Path $scriptPath) { Remove-Item $scriptPath -Force }
            $progressBar.Visible = $false
            $btnExecutar.Enabled = $true
            $btnCancelar.Enabled = $false
        }
    })

# CANCELAR
$btnCancelar.Add_Click({
        if ($script:processo -and !$script:cancelando) {
            $script:cancelando = $true
            $script:processo.Kill()
            Update-Status "⛔ Cancelado pelo usuário" "DarkRed"
            $progressBar.Visible = $false
            $btnExecutar.Enabled = $true
            $btnCancelar.Enabled = $false
        }
    })

# ABRIR LOGS
$btnAbrirLogs.Add_Click({
        Start-Process explorer.exe $logPath
    })

# MOSTRAR
$form.Add_Shown({ $txtCliente.Focus() })
$form.ShowDialog()