= =========================================
# ADF KIT - SILENT MODE
# Pós-formatação automática inteligente
# Versão 2.1 - Corrigida e Otimizada
# ==========================================

param(
    [string]$Cliente = "Padrao",
    [string]$LogFile = ""
)

# ==========================================
# AUTO ELEVAÇÃO ADMIN
# ==========================================
# Verifica se está executando como Administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    
    # Reexecuta o script com permissões elevadas e janela oculta
    Start-Process powershell.exe `
        -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" -Cliente `"$Cliente`" -LogFile `"$LogFile`"" `
        -Verb RunAs -WindowStyle Hidden
    exit
}

# ==========================================
# CONFIGURAÇÕES
# ==========================================
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue" # Desativa barra de progresso para acelerar downloads
$baseUrl = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/scripts"
$basePath = "C:\ADF-Kit"
$logPath = Join-Path $basePath "Logs"
$tempPath = Join-Path $basePath "Temp"

# ==========================================
# CRIAR ESTRUTURA DE PASTAS
# ==========================================
$pastas = @($basePath, $logPath, $tempPath)
foreach ($pasta in $pastas) {
    New-Item -ItemType Directory -Path $pasta -Force | Out-Null
}

# ==========================================
# CONFIGURAÇÃO DE LOG
# ==========================================
if (-not $LogFile) {
    $LogFile = Join-Path $logPath "$(Get-Date -Format 'yyyyMMdd-HHmmss')_$Cliente.log"
}

# Garante que o arquivo de log pode ser gravado
try {
    Start-Transcript -Path $LogFile -Force -ErrorAction Stop
}
catch {
    Write-Host "ERRO CRÍTICO: Não foi possível criar arquivo de log. $_" -ForegroundColor Red
    exit 1
}

# ==========================================
# CABEÇALHO
# ==========================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        ADF KIT - SILENT MODE" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cliente: $Cliente"
Write-Host "Log salvo em: $LogFile"
Write-Host ""

# ==========================================
# VERIFICAÇÃO DE CONEXÃO COM INTERNET
# ==========================================
Write-Host "Verificando conectividade com a internet..."
$internet = $null
try {
    # Teste mais confiável que apenas ping, tenta conectar em porta 80
    $request = [System.Net.WebRequest]::Create("http://www.google.com")
    $request.Timeout = 5000
    $response = $request.GetResponse()
    $internet = $true
}
catch {
    $internet = $false
}

if (-not $internet) {
    Write-Host "ERRO: Sem conexão com a internet. Processo abortado." -ForegroundColor Red
    Stop-Transcript
    exit 1
}
Write-Host "✅ Internet funcionando normalmente." -ForegroundColor Green
Write-Host ""

# ==========================================
# DETECÇÃO DE HARDWARE E SISTEMA
# ==========================================
Write-Host "Detectando especificações do hardware..."

# Coleta informações com tratamento de erro
try {
    $computador = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $ram = [math]::Round($computador.TotalPhysicalMemory / 1GB, 2)
    $domain = $computador.PartOfDomain
    $nomePC = $computador.Name

    $cpuInfo = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $cpu = $cpuInfo.Name

    $discoInfo = Get-PhysicalDisk -ErrorAction Stop | Select-Object -First 1
    $disk = $discoInfo.MediaType ?? "Desconhecido" # Corrige valor nulo
}
catch {
    Write-Host "AVISO: Falha ao coletar dados de hardware. Usando perfil padrão." -ForegroundColor Yellow
    $ram = 4
    $disk = "HDD"
    $domain = $false
}

Write-Host "• Nome do PC: $nomePC"
Write-Host "• RAM instalada: $ram GB"
Write-Host "• Processador: $cpu"
Write-Host "• Tipo de Disco: $disk"
Write-Host ""

# ==========================================
# DEFINIÇÃO DE PERFIL DE CONFIGURAÇÃO
# ==========================================
$perfil = "domestico" # Perfil padrão

if ($domain -eq $true) {
    $perfil = "empresa"
}
elseif ($ram -ge 16 -and $disk -eq "SSD") {
    $perfil = "completo"
}

Write-Host "📌 Perfil detectado: $perfil.ToUpper()"
Write-Host ""

# ==========================================
# FUNÇÃO PARA EXECUTAR SCRIPTS REMOTOS
# ==========================================
function Run-Script {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    Write-Host "`n=========================================="
    Write-Host "🔧 Executando etapa: $ScriptName"
    Write-Host "=========================================="

    $url = "$baseUrl/$ScriptName.ps1"
    $localScript = Join-Path $tempPath "$ScriptName.ps1"

    try {
        # Download com tratamento de erro melhorado
        Invoke-WebRequest -Uri $url -OutFile $localScript -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        
        # Verifica se o arquivo foi baixado e não está vazio
        if ((Get-Item $localScript -ErrorAction SilentlyContinue).Length -lt 10) {
            throw "Arquivo baixado está vazio ou corrompido."
        }

        # Execução do script baixado
        & powershell.exe -ExecutionPolicy Bypass -NoProfile -NonInteractive -File $localScript
        Write-Host "✅ Concluído: $ScriptName" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ FALHA na etapa '$ScriptName': $_" -ForegroundColor Red
    }
}

# ==========================================
# EXECUÇÃO CONFORME PERFIL DETECTADO
# ==========================================
switch ($perfil) {
    "domestico" {
        Run-Script "limpeza"
        Run-Script "install"
        Run-Script "debloat"
        Run-Script "privacy"
        Run-Script "ADF-Kit-Tweaks"
    }
    "empresa" {
        Run-Script "limpeza"
        Run-Script "install"
        Run-Script "debloat"
        Run-Script "privacy"
        Run-Script "hardening"
        Run-Script "ADF-Kit-Tweaks"
    }
    "completo" {
        Run-Script "limpeza"
        Run-Script "debloat"
        Run-Script "privacy"
        Run-Script "hardening"
        Run-Script "install"
        Run-Script "ADF-Kit-Tweaks"
    }
}

# ==========================================
# AJUSTES FINAIS DO SISTEMA
# ==========================================
Write-Host "`n=========================================="
Write-Host "⚙️ Aplicando ajustes finais de sistema"
Write-Host "=========================================="

# Define plano de energia para Alto Desempenho
try {
    & powercfg.exe -setactive SCHEME_MIN
    Write-Host "✅ Plano de energia definido para Alto Desempenho"
}
catch { Write-Host "⚠️ Não foi possível alterar plano de energia" }

# Atualiza Políticas de Grupo
try {
    & gpupdate.exe /force /wait:0
    Write-Host "✅ Políticas de grupo atualizadas"
}
catch { Write-Host "⚠️ Não foi possível atualizar políticas" }

# Limpeza de arquivos temporários do sistema
try {
    Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "✅ Arquivos temporários removidos"
}
catch { }

# ==========================================
# FINALIZAÇÃO
# ==========================================
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "      SISTEMA CONFIGURADO COM SUCESSO     " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Log completo salvo em:"
Write-Host $LogFile

# Encerra o registro de log
Stop-Transcript

# Limpeza da pasta temporária do ADF-Kit
Remove-Item $tempPath\* -Force -Recurse -ErrorAction SilentlyContinue

# Reinício Automático (descomente se desejar forçar)
# Write-Host "`nReiniciando o computador em 10 segundos..."
# Start-Sleep 10
# Restart-Computer -Force