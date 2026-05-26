<#
Script de Limpeza de Arquivos Temporários
Data: 2026-05-26 | Horário: 01:08:34
#>

# ==============================================
# FORÇA EXECUÇÃO COMO ADMINISTRADOR
# ==============================================
# Verifica se está rodando com privilégios de administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        # Reexecuta o script como Administrador
        Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
        exit
    }
    catch {
        Write-Host "Executado sem sucesso"
        exit 1
    }
}

# ==============================================
# FECHA PROGRAMAS QUE POSSAM ESTAR USANDO OS ARQUIVOS
# ==============================================
# Lista de processos que podem bloquear arquivos nas pastas temporárias ou de atualização
$processosAlvo = @("explorer", "notepad", "winword", "excel", "chrome", "firefox", "wuauclt", "wusa")
foreach ($procNome in $processosAlvo) {
    $processos = Get-Process -Name $procNome -ErrorAction SilentlyContinue
    if ($processos) {
        # Força o encerramento dos processos
        $processos | Stop-Process -Force -ErrorAction SilentlyContinue
        # Aguarda um momento para garantir que foram encerrados
        Start-Sleep -Seconds 2
    }
}

# ==============================================
# EXECUTA A LIMPEZA
# ==============================================
$sucesso = $true

try {
    # Limpa pasta temporária do usuário
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction Stop

    # Limpa pasta temporária do sistema
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction Stop

    # Limpa pasta Prefetch
    Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction Stop

    # Para serviço do Windows Update e limpa cache
    Stop-Service wuauserv -Force -ErrorAction Stop
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction Stop
    Start-Service wuauserv -ErrorAction Stop
}
catch {
    $sucesso = $false
}

# ==============================================
# MENSAGEM FINAL
# ==============================================
if ($sucesso) {
    Write-Host "Executado com sucesso"
}
else {
    Write-Host "Executado sem sucesso"
}