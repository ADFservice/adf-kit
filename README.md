ADF-Kit

Kit de automação para pós-formatação, manutenção e provisionamento de computadores Windows utilizando PowerShell.

O projeto foi desenvolvido com foco em:

padronização de atendimentos técnicos
automação de tarefas repetitivas
instalação rápida de utilitários
limpeza e otimização do sistema
redução de telemetria e recursos intrusivos
execução local ou remota via GitHub RAW
🚀 Recursos
🧹 Limpeza automática
%TEMP%
C:\Windows\Temp
Prefetch
cache do Windows Update
arquivos temporários
limpeza final do sistema
📦 Instalação automática de utilitários

Utilizando Winget:

Google Chrome
Python
PuTTY
Adobe Acrobat Reader
AnyDesk

Além de:

atalho automático para WhatsApp Web
🔐 Privacidade e Hardening
redução de telemetria
desativação de serviços de coleta
desativação do Copilot
desativação de sugestões e experiências do consumidor
ajustes seguros de privacidade
🧠 Detecção inteligente de perfil

O sistema detecta automaticamente:

quantidade de RAM
SSD/HDD
domínio corporativo

E escolhe automaticamente o perfil:

doméstico
empresa
completo
🖥️ Interface gráfica

Modo GUI simples para facilitar o uso durante atendimentos.

🧾 Logs automáticos

Geração de logs por atendimento:

C:\ADFKit\logs

🔄 Atualização remota

Scripts executados diretamente do GitHub RAW.

📂 Estrutura do Projeto
ADF-Kit/
│
├── kit.ps1
├── pos-formatacao.ps1
├── pos-formatacao-auto.ps1
├── silent.ps1
│
├── core/
│   └── updater.ps1
│
├── scripts/
│   ├── limpeza.ps1
│   ├── install.ps1
│   ├── debloat.ps1
│   ├── privacy.ps1
│   ├── hardening.ps1
│   ├── undo-hardening.ps1
│   └── diagnostico.ps1
│
├── config/
│   └── version.json
│
├── logs/
│
└── build/
    └── build-zip.ps1
⚡ Execução rápida
🔹 Modo Inteligente
irm https://raw.githubusercontent.com/SEU_USUARIO/ADF-Kit/main/pos-formatacao-auto.ps1 | iex
🔹 Modo Silencioso
irm https://raw.githubusercontent.com/SEU_USUARIO/ADF-Kit/main/silent.ps1 | iex
🔹 Loader GUI
irm https://raw.githubusercontent.com/SEU_USUARIO/ADF-Kit/main/kit.ps1 | iex
🔧 Requisitos
Windows 10 ou 11
PowerShell 5+
Winget instalado
Execução como Administrador
Conexão com internet
🛡️ Segurança

O projeto executa scripts remotos via:

irm URL | iex

Recomenda-se:

utilizar apenas repositórios próprios/confiáveis
validar alterações antes de publicar
manter backups dos scripts
implementar validação de hash futuramente
📌 Objetivo do Projeto

Este projeto foi criado para uso técnico e automação de pós-formatação, buscando:

ganho de produtividade
padronização
redução de tempo em atendimentos
centralização de scripts e ferramentas
⚠️ Aviso

Utilize por sua conta e risco.

Apesar do projeto buscar segurança e estabilidade, alterações em:

serviços
registro
telemetria
aplicativos do Windows

podem afetar ambientes específicos.

Recomenda-se:

testar em ambiente controlado
criar ponto de restauração
manter backup do sistema
📄 Licença

Uso pessoal/técnico.
Adapte conforme sua necessidade.