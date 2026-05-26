Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "ADF Kit Suporte"
$form.Size = New-Object System.Drawing.Size(400, 350)
$form.StartPosition = "CenterScreen"

# Título
$label = New-Object System.Windows.Forms.Label
$label.Text = "ADF - Kit de Suporte"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(120, 20)
$form.Controls.Add($label)

# Base URL
$base = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/scripts"

function Run-Script($script) {
    $temp = "$env:TEMP\$script.ps1"
    Invoke-WebRequest "$base/$script.ps1" -OutFile $temp
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$temp`"" -Verb RunAs
}

# Botões
$btn1 = New-Object System.Windows.Forms.Button
$btn1.Text = "Limpeza"
$btn1.Size = New-Object System.Drawing.Size(120, 30)
$btn1.Location = New-Object System.Drawing.Point(30, 80)
$btn1.Add_Click({ Run-Script "limpeza" })
$form.Controls.Add($btn1)

$btn2 = New-Object System.Windows.Forms.Button
$btn2.Text = "Rede"
$btn2.Size = New-Object System.Drawing.Size(120, 30)
$btn2.Location = New-Object System.Drawing.Point(200, 80)
$btn2.Add_Click({ Run-Script "rede" })
$form.Controls.Add($btn2)

$btn3 = New-Object System.Windows.Forms.Button
$btn3.Text = "Diagnóstico"
$btn3.Size = New-Object System.Drawing.Size(120, 30)
$btn3.Location = New-Object System.Drawing.Point(30, 140)
$btn3.Add_Click({ Run-Script "diagnostico" })
$form.Controls.Add($btn3)

$btn4 = New-Object System.Windows.Forms.Button
$btn4.Text = "Instalar Apps"
$btn4.Size = New-Object System.Drawing.Size(120, 30)
$btn4.Location = New-Object System.Drawing.Point(200, 140)
$btn4.Add_Click({ Run-Script "install" })
$form.Controls.Add($btn4)

# Botão sair
$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Sair"
$btnExit.Size = New-Object System.Drawing.Size(120, 30)
$btnExit.Location = New-Object System.Drawing.Point(120, 220)
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

# Executar
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()