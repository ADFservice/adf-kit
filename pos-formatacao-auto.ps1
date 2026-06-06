# ==================================================
# ADF KIT - MODO INTELIGENTE (VERSÃO CORRIGIDA)
# ==================================================

# ✅ 1. GARANTE EXECUÇÃO COMO ADMINISTRADOR (robusto)
function Ensure-RunAs {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        $scriptPath = $PSCommandPath
        if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Definition }
        $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath)
        $pw = (Get-Command powershell.exe -ErrorAction SilentlyContinue)
        $pwPath = if ($pw) { $pw.Source } else { 'powershell.exe' }
        Start-Process -FilePath $pwPath -ArgumentList $args -Verb RunAs
        exit
    }
}
Ensure-RunAs

# ✅ 2. SISTEMA DE ATUALIZAÇÃO COM TRATAMENTO DE ERRO (não quebra sem internet)
try {
    irm https://raw.githubusercontent.com/ADFservice/adf-kit/main/core/updater.ps1 -ErrorAction Stop | iex
}
catch {
    Write-Host "`n❌ ERRO: Sem conexão com a internet ou servidor indisponível.`n" -ForegroundColor Red
    Write-Host "Verifique sua rede e tente novamente.`n" -ForegroundColor Yellow
    pause
    exit 1
}

# ✅ 3. IDENTIFICAÇÃO DO CLIENTE
$cliente = Read-Host "Nome do cliente"
if (-not $cliente) { $cliente = "Padrao" }

# ✅ 4. CONFIGURAÇÃO DE LOGS
$logPath = "C:\ADFKit\logs"
New-Item -ItemType Directory -Path $logPath -Force | Out-Null

Start-Transcript -Path "$logPath\$cliente-$(Get-Date -Format yyyyMMdd-HHmm).log"

# ✅ 4.1. GARANTE EXECUTÁVEIS DO WINDOWS NO PATH
$system32 = Join-Path $env:SystemRoot 'System32'
$sysWOW64 = Join-Path $env:SystemRoot 'SysWOW64'
foreach ($dir in @($system32, $sysWOW64)) {
    if (Test-Path $dir -and ($env:PATH -split ';' -notcontains $dir)) {
        $env:PATH = "$dir;$env:PATH"
    }
}

Clear-Host
Write-Host "ADF KIT - MODO INTELIGENTE"

# ✅ 5. COLETA DE DADOS COM SEGURANÇA (não deixa variáveis vazias)
$ramEmBytes = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty TotalPhysicalMemory -ErrorAction SilentlyContinue
$ram = if ($ramEmBytes) { [math]::Round($ramEmBytes / 1GB) } else { 4 } # Assume 4GB se não ler

$domain = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PartOfDomain -ErrorAction SilentlyContinue
$domain = if ($domain) { $domain } else { $false } # Assume que NÃO é domínio se não ler

$disk = Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty MediaType -ErrorAction SilentlyContinue
$disk = if ($disk) { $disk } else { "HDD" } # Assume HDD se não conseguir ler

# ✅ 6. DEFINIÇÃO DE PERFIL
if ($domain) {
    $perfil = "empresa"
}
elseif ($ram -ge 16 -and $disk -eq "SSD") {
    $perfil = "completo"
}
else {
    $perfil = "domestico"
}

Write-Host "Perfil detectado: $perfil"

# ✅ 7. CONFIGURAÇÃO DOS SCRIPTS
$base = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/scripts"

function Run($s) {
    Write-Host "Executando $s..."
    try {
        $scriptContent = irm "$base/$s.ps1" -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($scriptContent)) {
            throw "Conteúdo remoto vazio."
        }
        
        # Limpar prefixos de timestamp/log corrompidos
        $lines = $scriptContent -split "`n"
        $cleaned = @()
        foreach ($line in $lines) {
            if ($line -match '^\d{8}\s+\d{2}:\d{2}:\d{2}\s+\|\|') {
                continue
            }
            $cleaned += $line
        }
        $scriptContent = $cleaned -join "`n"
        
        if ($scriptContent.Length -lt 100) {
            throw "Conteúdo remoto corrompido ou muito pequeno"
        }
        
        iex $scriptContent
    }
    catch {
        Write-Host "⚠️ Aviso: Não foi possível executar '$s'. Continuando...`n" -ForegroundColor Red
        Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ✅ 8. EXECUÇÃO POR PERFIL (CORRIGIDO ERRO DE ASPAS E NOME DA FUNÇÃO)
switch ($perfil) {
    "domestico" {
        Run "limpeza"
        Run "install"
        Run "debloat"
        # Run "ADF-Kit-Tweaks"  # Linha corrigida, pronta para usar se quiser
    }

    "empresa" {
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "hardening"
        # Run "ADF-Kit-Tweaks"
    }

    "completo" {
        Run "limpeza"
        Run "debloat"
        Run "privacy"
        Run "hardening"
        Run "install"
        # Run "ADF-Kit-Tweaks"
    }
}

# ✅ 9. PLANO DE ENERGIA (CORRIGIDO CÓDIGO LEGADO QUE PODE NÃO EXISTIR)
# Código oficial do plano de ALTO DESEMPENHO para Windows 10 e 11
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
gpupdate /force

# ✅ 10. FERRAMENTA DE ATIVAÇÃO
irm https://get.activated.win | iex

# ✅ 11. FINALIZAÇÃO
Write-Host "Sistema pronto!"
Stop-Transcript
pause