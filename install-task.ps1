# ==========================================
# ADF KIT - INSTALL TASK
# Cria tarefa automática pós-formatação
# Versão 2.1 - Corrigida e Otimizada
# ==========================================

#Requires -RunAsAdministrator

# ==========================================
# CONFIGURAÇÕES
# ==========================================
$basePath = "C:\ADF-Kit"
$scriptPath = Join-Path $basePath "silent.ps1"
$url = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/silent.ps1"
$nomeTarefa = "ADFKit"

# ==========================================
# CABEÇALHO
# ==========================================
Clear-Host
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      ADF KIT - INSTALL TASK" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# VERIFICAÇÃO DE PERMISSÃO ADMINISTRATIVA
# ==========================================
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Write-Host "🔑 Solicitando permissão de Administrador..."
    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs -Wait
    exit
}

# ==========================================
# VERIFICAÇÃO DE CONEXÃO
# ==========================================
Write-Host "🌐 Verificando conexão com a internet..."
try {
    $null = Test-Connection google.com -Quiet -Count 1 -ErrorAction Stop
    Write-Host "✅ Conexão OK." -ForegroundColor Green
}
catch {
    Write-Host "❌ ERRO: Sem conexão com a internet. Não é possível continuar." -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# ==========================================
# CRIA ESTRUTURA DE PASTAS
# ==========================================
Write-Host "`n📂 Preparando diretório em: $basePath"
New-Item -ItemType Directory -Path $basePath -Force -ErrorAction Stop | Out-Null

# ==========================================
# DOWNLOAD DO SCRIPT PRINCIPAL
# ==========================================
Write-Host "⬇️ Baixando arquivo silent.ps1 do repositório..."
try {
    Invoke-WebRequest -Uri $url -OutFile $scriptPath -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
    
    if (-not (Test-Path $scriptPath)) { throw "Arquivo não foi criado após o download." }
    
    Write-Host "✅ Download concluído com sucesso." -ForegroundColor Green
}
catch {
    Write-Host "❌ FALHA NO DOWNLOAD: $_" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# ==========================================
# REMOVER TAREFA ANTERIOR (SE EXISTIR)
# ==========================================
Write-Host "`n🧹 Verificando e removendo tarefa antiga (se houver)..."
try {
    $tarefaExistente = Get-ScheduledTask -TaskName $nomeTarefa -ErrorAction SilentlyContinue
    if ($tarefaExistente) {
        Unregister-ScheduledTask -TaskName $nomeTarefa -Confirm:$false -ErrorAction Stop
        Write-Host "→ Tarefa antiga removida."
    }
}
catch {
    Write-Host "→ Aviso: Não foi possível remover tarefa antiga ou não existia." -ForegroundColor Yellow
}

# ==========================================
# CRIAR NOVA TAREFA AGENDADA
# ==========================================
Write-Host "⚙️ Criando nova tarefa agendada..."

# Definição da Ação: Executar Powershell com parâmetros corretos
$argumentos = "-ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -File `"$scriptPath`""
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argumentos

# Disparador: Executar em todo logon de usuário
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Configurações: Executar mesmo se usuário não estiver logado, maior prioridade
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden

# Usuário: Sistema Local (máxima permissão)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try {
    Register-ScheduledTask `
        -TaskName $nomeTarefa `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "✅ TAREFA INSTALADA COM SUCESSO!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "`nA configuração automática ocorrerá:"
    Write-Host "• Automaticamente na próxima inicialização/logon"
    Write-Host "• Ou imediatamente se escolher a opção abaixo"
}
catch {
    Write-Host "❌ ERRO AO CRIAR TAREFA: $_" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# ==========================================
# OPÇÃO DE EXECUÇÃO IMEDIATA
# ==========================================
Write-Host ""
do {
    $runNow = Read-Host "Deseja executar a configuração AGORA? (S/N)"
} until ($runNow -match "^[SsNn]$")

if ($runNow -match "^[Ss]$") {
    Write-Host "`n▶️ Iniciando processo de configuração..."
    try {
        Start-ScheduledTask -TaskName $nomeTarefa -ErrorAction Stop
        Write-Host "Processo iniciado em segundo plano. Verifique os logs em C:\ADF-Kit\Logs em instantes." -ForegroundColor Cyan
    }
    catch {
        Write-Host "⚠️ Não foi possível iniciar a tarefa automaticamente. Execute manualmente." -ForegroundColor Yellow
    }
}

# ==========================================
# FINALIZAÇÃO
# ==========================================
Write-Host "`n✅ Instalação finalizada."
Read-Host "Pressione Enter para fechar"