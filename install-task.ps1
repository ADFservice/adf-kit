# ==========================================
# ADF KIT - INSTALL TASK
# Cria tarefa automática pós-formatação
# ==========================================

#Requires -RunAsAdministrator

# ==========================================
# CONFIGURAÇÕES
# ==========================================

$basePath = "C:\ADF-Kit"
$scriptPath = "$basePath\silent.ps1"

# URL RAW
$url = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/silent.ps1"

# ==========================================
# HEADER
# ==========================================

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      ADF KIT - INSTALL TASK" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# ADMIN CHECK
# ==========================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Write-Host "Executando como administrador..."

    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs

    exit
}

# ==========================================
# INTERNET
# ==========================================

Write-Host "Verificando internet..."

$internet = Test-Connection google.com -Quiet -Count 1

if (-not $internet) {

    Write-Host ""
    Write-Host "Sem internet." -ForegroundColor Red
    pause
    exit
}

Write-Host "Internet OK." -ForegroundColor Green

# ==========================================
# ESTRUTURA
# ==========================================

Write-Host ""
Write-Host "Criando estrutura..."

New-Item `
    -ItemType Directory `
    -Path $basePath `
    -Force `
    -ErrorAction SilentlyContinue | Out-Null

# ==========================================
# DOWNLOAD SILENT.PS1
# ==========================================

Write-Host ""
Write-Host "Baixando silent.ps1..."

try {

    Invoke-WebRequest `
        -Uri $url `
        -OutFile $scriptPath `
        -UseBasicParsing

    Write-Host "Download concluído." -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "Falha no download." -ForegroundColor Red
    Write-Host $_.Exception.Message

    pause
    exit
}

# ==========================================
# REMOVER TAREFA ANTIGA
# ==========================================

Write-Host ""
Write-Host "Verificando tarefa anterior..."

try {

    Unregister-ScheduledTask `
        -TaskName "ADFKit" `
        -Confirm:$false `
        -ErrorAction SilentlyContinue
}
catch {}

# ==========================================
# CRIAR TAREFA
# ==========================================

Write-Host ""
Write-Host "Criando tarefa automática..."

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger `
    -AtLogOn

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

try {

    Register-ScheduledTask `
        -TaskName "ADFKit" `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Force | Out-Null

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host " TAREFA CRIADA COM SUCESSO " -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "A pós-formatação será executada"
    Write-Host "automaticamente no próximo login."
}
catch {

    Write-Host ""
    Write-Host "ERRO ao criar tarefa." -ForegroundColor Red
    Write-Host $_.Exception.Message

    pause
    exit
}

# ==========================================
# OPCIONAL - EXECUTAR AGORA
# ==========================================

Write-Host ""
$runNow = Read-Host "Executar agora? (S/N)"

if ($runNow -match "S|s") {

    Write-Host ""
    Write-Host "Executando tarefa..."

    Start-ScheduledTask -TaskName "ADFKit"

    Write-Host "Tarefa iniciada."
}

# ==========================================
# FINAL
# ==========================================

Write-Host ""
Write-Host "Finalizado."

pause