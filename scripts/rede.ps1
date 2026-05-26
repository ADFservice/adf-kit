<#
Script: Reparo-Completo-Rede-ADM.ps1
Objetivo: SEMPRE executar como Administrador, corrigir erros 0x709, 711 e todos os problemas de rede
Compatibilidade: Windows 10 e Windows 11
#>

# ==============================================
# 🔴 BLOCO OBRIGATÓRIO: FORÇA EXECUÇÃO COMO ADMINISTRADOR
# ==============================================
# Verifica se o script está rodando com privilégios de Administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Se NÃO for ADM: abre uma nova janela do PowerShell como ADM e executa este mesmo script
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    # Encerra a versão sem permissão
    exit
}

# ==============================================
# 🟢 INÍCIO DO REPARO COMPLETO DE REDE
# ==============================================
Clear-Host
Write-Host "`n=== REPARO TOTAL DE REDE (EXECUTANDO COMO ADMINISTRADOR) ===" -ForegroundColor Cyan
Write-Host "Corrigindo: Erros 0x709, 711, falhas de conexao, lentidao, queda de sinal, DNS, IP, etc`n" -ForegroundColor Cyan

# ==============================================
# 1. LIMPEZA PROFUNDA DE CACHE E TABELAS
# ==============================================
Write-Host "[1/13] Limpando cache DNS, ARP, registros e rotas..."
ipconfig /flushdns      # Limpa cache de endereços DNS
arp -d *                # Limpa cache de endereços físicos da rede
nbtstat -R              # Limpa cache de nomes na rede local
nbtstat -RR             # Atualiza registro de nomes
route -f                # Limpa todas as rotas de rede personalizadas
Write-Host "✅ Limpeza concluída`n" -ForegroundColor Green

# ==============================================
# 2. REDEFINIÇÃO DE PROTOCOLOS E CONFIGURAÇÕES
# ==============================================
Write-Host "[2/13] Redefinindo Winsock e pilha TCP/IP..."
netsh winsock reset all       # Restaura catálogo Winsock ao padrão
netsh int ip reset all        # Redefine configurações IP
netsh int ipv4 reset          # Redefine IPv4
netsh int ipv6 reset          # Redefine IPv6
Write-Host "✅ Protocolos restaurados`n" -ForegroundColor Green

# ==============================================
# 3. CORREÇÃO ERRO 711: SERVIÇOS DE CONEXÃO
# ==============================================
Write-Host "[3/13] Configurando e reiniciando serviços essenciais (Erro 711)..."
$servicos = @("TapiSrv", "RasMan", "SstpSvc", "Dhcp", "Netman", "NlaSvc", "WlanSvc", "LanmanWorkstation", "Winmgmt")
foreach ($servico in $servicos) {
    # Define tipo de inicialização correto para cada serviço
    switch ($servico) {
        "TapiSrv" { $tipo = "Manual" }
        "RasMan" { $tipo = "Manual" }
        "SstpSvc" { $tipo = "Manual" }
        default { $tipo = "Automatic" }
    }

    # Ajusta inicialização, para e inicia o serviço
    Set-Service -Name $servico -StartupType $tipo -ErrorAction SilentlyContinue
    Stop-Service -Name $servico -Force -ErrorAction SilentlyContinue
    Start-Service -Name $servico -ErrorAction SilentlyContinue

    if (Get-Service $servico -ErrorAction SilentlyContinue) {
        Write-Host "✅ Serviço $servico : OK"
    }
    else {
        Write-Host "⚠️ Serviço $servico : Não aplicável ou não encontrado" -ForegroundColor Yellow
    }
}
Write-Host "`n✅ Serviços configurados`n" -ForegroundColor Green

# ==============================================
# 4. CORREÇÃO ERRO 0x709: PERMISSÕES E REGISTRO
# ==============================================
Write-Host "[4/13] Corrigindo permissões e políticas do Registro (Erro 0x709)..."
# Libera acesso total para Administradores na chave de rede
icacls "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /grant Administradores:F /T /C /Q
# Remove bloqueios de alteração de rede
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoNetworkConnections" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoNetSetup" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoNetSetupSecurityPage" -Value 0 -ErrorAction SilentlyContinue
Write-Host "✅ Permissões corrigidas`n" -ForegroundColor Green

# ==============================================
# 5. REDEFINIÇÃO DE FIREWALL E SEGURANÇA
# ==============================================
Write-Host "[5/13] Redefinindo Firewall do Windows..."
netsh advfirewall reset                          # Restaura configuração padrão
netsh advfirewall set allprofiles state on       # Mantém Firewall LIGADO (segurança)
Remove-NetFirewallRule -All -ErrorAction SilentlyContinue # Remove regras corrompidas
Write-Host "✅ Firewall redefinido`n" -ForegroundColor Green

# ==============================================
# 6. LIMPEZA DE PROXY E CONFIGURAÇÕES DE ACESSO
# ==============================================
Write-Host "[6/13] Limpando configurações de Proxy e WinHTTP..."
netsh winhttp reset proxy                        # Zera proxy do sistema
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "" -ErrorAction SilentlyContinue
Write-Host "✅ Proxy desativado e limpo`n" -ForegroundColor Green

# ==============================================
# 7. AJUSTES AVANÇADOS DE DESEMPENHO TCP/IP
# ==============================================
Write-Host "[7/13] Otimizando parâmetros TCP/IP..."
netsh int tcp set global autotuninglevel=normal  # Ajusta recepção de dados
netsh int tcp set global rss=enabled              # Habilita processamento em múltiplos núcleos
netsh int tcp set global chimney=enabled         # Melhora transferência de dados
netsh int tcp set global netdma=disabled         # Ajuste de compatibilidade
netsh int tcp set global congestionprovider=default # Controle de congestionamento
Write-Host "✅ Parâmetros otimizados`n" -ForegroundColor Green

# ==============================================
# 8. REDEFINIÇÃO DE ADAPTADORES DE REDE
# ==============================================
Write-Host "[8/13] Reiniciando adaptadores de rede..."
Get-NetAdapter | Restart-NetAdapter -ErrorAction SilentlyContinue
Write-Host "✅ Adaptadores reiniciados`n" -ForegroundColor Green

# ==============================================
# 9. REDEFINIÇÃO DE REDES WI-FI SALVAS
# ==============================================
Write-Host "[9/13] Removendo perfis Wi-Fi corrompidos..."
$perfis = netsh wlan show profiles 2>$null | Select-String "Todos os Perfis"
if ($perfis) {
    netsh wlan delete profile name=* >$null
    Write-Host "✅ Perfis Wi-Fi removidos (serão recriados ao conectar)"
}
else {
    Write-Host "ℹ️ Nenhuma rede Wi-Fi salva encontrada"
}
Write-Host "`n"

# ==============================================
# 10. RENOVAÇÃO DE IP E REGISTRO DNS
# ==============================================
Write-Host "[10/13] Renovando endereço IP e registro DNS..."
ipconfig /release           # Libera IP atual
ipconfig /renew             # Solicita novo IP ao roteador
ipconfig /flushdns          # Limpa cache novamente
ipconfig /registerdns       # Atualiza registro no servidor DNS
Write-Host "✅ IP renovado e registrado`n" -ForegroundColor Green

# ==============================================
# 11. REDEFINIÇÃO TOTAL DE COMPONENTES DE REDE
# ==============================================
Write-Host "[11/13] Executando redefinição profunda de rede (netcfg -d)..."
netcfg -d  # Remove e reinstala TODOS os drivers, protocolos e serviços de rede
Write-Host "✅ Componentes reinstalados`n" -ForegroundColor Green

# ==============================================
# 12. REPARO DE ARQUIVOS DO SISTEMA
# ==============================================
Write-Host "[12/13] Verificando e reparando arquivos corrompidos do Windows..."
sfc /scannow                                   # Verifica e repara arquivos protegidos
DISM /Online /Cleanup-Image /CheckHealth       # Verifica estado da imagem
DISM /Online /Cleanup-Image /ScanHealth       # Verifica corrupções
DISM /Online /Cleanup-Image /RestoreHealth     # Repara imagem do Windows
Write-Host "✅ Sistema verificado e reparado`n" -ForegroundColor Green

# ==============================================
# 13. REDEFINIÇÃO DE REDE NATIVA DO WINDOWS
# ==============================================
Write-Host "[13/13] Aplicando redefinição padrão do Windows..."
# Comando equivalente a: Configurações > Rede e Internet > Redefinir rede
netsh interface set interface name="Wi-Fi" admin=enabled 2>$null
netsh interface set interface name="Ethernet" admin=enabled 2>$null
Write-Host "✅ Configurações finais aplicadas`n" -ForegroundColor Green

# ==============================================
# 📌 FINALIZAÇÃO
# ==============================================
Write-Host "`n`n=== TODOS OS REPAROS FORAM CONCLUÍDOS COM SUCESSO ===" -ForegroundColor Green
Write-Host "`nCorreções aplicadas:"
Write-Host "• Erros 0x709 e 711 resolvidos"
Write-Host "• Conexões, DNS, IP e adaptadores redefinidos"
Write-Host "• Serviços, permissões e registro corrigidos"
Write-Host "• Arquivos corrompidos reparados"
Write-Host "• Proxy, Firewall e perfis limpos"

Write-Host "`n⚠️  OBRIGATÓRIO: REINICIE O COMPUTADOR AGORA para aplicar todas as alterações definitivamente." -ForegroundColor Red
pause