Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "ADF Kit Suporte"
$form.Size = "400,300"
$form.StartPosition = "CenterScreen"

$label = New-Object Windows.Forms.Label
$label.Text = "Nome do Cliente:"
$label.Location = "20,20"
$form.Controls.Add($label)

$txtCliente = New-Object Windows.Forms.TextBox
$txtCliente.Location = "150,20"
$form.Controls.Add($txtCliente)

$btn = New-Object Windows.Forms.Button
$btn.Text = "Executar Pós-Formatação Inteligente"
$btn.Size = "300,40"
$btn.Location = "50,80"

$btn.Add_Click({
    $url = "https://raw.githubusercontent.com/SEU_USUARIO/ADF-Kit/main/pos-formatacao-auto.ps1"
    irm $url | iex
})

$form.Controls.Add($btn)
$form.ShowDialog()