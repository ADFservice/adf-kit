# Executar como admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Clear-Host
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "     ADF - PÓS-FORMATAÇÃO" -ForegroundColor Yellow
Write-Host "====================================="
Write-Host ""
Write-Host "1 - Doméstico"
Write-Host "2 - Empresa"
Write-Host "3 - Completo"
Write-Host "0 - Sair"
Write-Host ""

$perfil = Read-Host "Escolha o perfil"

# Endereço do repositório atualizado
$base = "https://raw.githubusercontent.com/ADFservice/adf-kit/main/scripts"

# Lista para armazenar os erros
$scriptsComErro = @()

function Run($script) {
    Write-Host "`nVerificando e executando $script..." -ForegroundColor Cyan
    $url = "$base/$script.ps1"
    
    try {
        # Tenta obter o conteúdo do arquivo
        $conteudo = Invoke-RestMethod -Uri $url -UseBasicParsing -ErrorAction Stop
        # Se deu certo, executa
        Invoke-Expression $conteudo
        Write-Host "✅ $script executado com sucesso!" -ForegroundColor Green
    }
    catch {
        $mensagemErro = "❌ Erro em '$script': Não encontrado ou falha ao carregar. Endereço: $url"
        Write-Host $mensagemErro -ForegroundColor Red
        # Adiciona o erro na lista
        $scriptsComErro += $script
    }
}

switch ($perfil) {

    "1" {
        Write-Host "`nModo DOMÉSTICO" -ForegroundColor Green
        
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "privacy"
    }

    "2" {
        Write-Host "`nModo EMPRESA" -ForegroundColor Yellow
        
        Run "limpeza"
        Run "install"
        Run "debloat"
        Run "hardening"
    }

    "3" {
        Write-Host "`nModo COMPLETO" -ForegroundColor Magenta
        
        Run "limpeza"
        Run "debloat"
        Run "privacy"
        Run "hardening"
        Run "install"
    }

    default {
        Write-Host "Saindo..."
        exit
    }
}

# Ajustes finais
Write-Host "`nAplicando ajustes finais..." -ForegroundColor Cyan

# Plano de energia alto desempenho
powercfg -setactive SCHEME_MIN

# Atualizar políticas
gpupdate /force

# --------------------------
# Resumo final de execução
# --------------------------
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "          RESUMO DA EXECUÇÃO         " -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Cyan

if ($scriptsComErro.Count -eq 0) {
    Write-Host "`n✅ Todos os scripts foram executados com sucesso!" -ForegroundColor Green
}
else {
    Write-Host "`n⚠️ Os seguintes scripts apresentaram erro ou não foram encontrados:" -ForegroundColor Red
    foreach ($erro in $scriptsComErro) {
        Write-Host "   - $erro" -ForegroundColor Red
    }
    Write-Host "`nVerifique se os arquivos existem no caminho: $base" -ForegroundColor Yellow
}

Write-Host "`nSistema pronto para uso!" -ForegroundColor Green
pause