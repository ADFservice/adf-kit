# ADF-Kit

Kit de automação para pós-formatação, manutenção e provisionamento de computadores Windows com PowerShell.

## 🎯 Escopo

Este repositório consolida scripts de manutenção e provisionamento para uso técnico em ambientes Windows. O fluxo atual privilegia execução remota via `irm`, cache local e GUI para atendimento rápido.

## 🧩 Componentes principais

### `kit.ps1`

- interface gráfica para execução assistida
- coleta do nome do cliente
- prepara o log por atendimento
- consulta o updater antes de executar o fluxo principal
- reutiliza o cache local quando a versão está atualizada
- baixa o script remoto somente quando necessário

### `pos-formatacao-auto.ps1`

- fluxo principal de execução automatizada
- aplica rotinas de limpeza, hardening, privacidade e provisionamento
- utiliza scripts auxiliares em `scripts/`
- executa comandos do sistema com PATH corrigido para localizar utilitários do Windows

### `silent.ps1`

- execução sem interface
- útil para uso automatizado ou testes

### `core/updater.ps1`

- compara a versão remota com a versão local
- decide se o cache deve ser reutilizado ou atualizado
- grava o arquivo local de versão em `config/version.json`

### `scripts/install.ps1`

- instala e valida `winget`
- eleva o processo automaticamente quando necessário
- trata instalação do Microsoft Store em LTSC
- verifica aplicativos já instalados antes de reinstalar
- cria atalho de WhatsApp Web

## 🔄 Fluxo operacional

1. `kit.ps1` inicia a GUI.
2. O usuário informa o cliente.
3. O script valida a versão com `core/updater.ps1`.
4. Se a versão estiver atualizada, usa o script local em cache.
5. Se houver atualização, baixa o script remoto e atualiza o cache.
6. O script principal é executado com `Cliente` e `LogFile`.
7. O log é salvo em `C:\ADF-Kit\Logs`.

## 🧱 Estrutura do projeto

```text
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
```

## 🛠️ Execução

### Modo GUI

```powershell
irm https://raw.githubusercontent.com/ADFservice/adf-kit/main/kit.ps1 | iex
```

### Modo inteligente

```powershell
irm https://raw.githubusercontent.com/ADFservice/adf-kit/main/pos-formatacao-auto.ps1 | iex
```

### Modo silencioso

```powershell
irm https://raw.githubusercontent.com/ADFservice/adf-kit/main/silent.ps1 | iex
```

## 📁 Diretórios gerados

- `C:\ADF-Kit\Cache` — cache dos scripts baixados
- `C:\ADF-Kit\Logs` — logs por atendimento
- `C:\ADF-Kit\config` — versão local persistida

## 🔧 Requisitos

- Windows 10 ou 11
- PowerShell 5+ ou PowerShell 7
- `winget` disponível para o fluxo de instalação
- permissão administrativa para operações de sistema
- acesso à internet

## 🧪 Comportamento de instalação

`scripts/install.ps1` realiza as seguintes ações:

- valida se o processo está elevado
- tenta elevar automaticamente quando necessário
- detecta LTSC via SKU e caption
- instala o Microsoft Store quando aplicável
- valida o instalador baixado do Winget
- verifica se o aplicativo já está instalado
- instala utilitários via `winget`
- cria atalho para WhatsApp Web
- atualiza apps instalados quando aplicável

## 🔐 Segurança e uso

- o fluxo atual utiliza `irm` para baixar scripts remotos
- o cache local é reutilizado quando a versão está atualizada
- o uso de scripts remotos deve ser restrito a repositórios confiáveis
- revise o conteúdo antes de executar em ambientes críticos

## 📌 Observações técnicas

- o `kit.ps1` mantém o comportamento de execução com parâmetros `Cliente` e `LogFile`
- o updater usa `config/version.json` como referência local
- `pos-formatacao-auto.ps1` corrige o `PATH` para garantir resolução de ferramentas do sistema
- `scripts/install.ps1` não depende de estado do shell para elevação; ele se reinicia via `powershell.exe -Verb RunAs` quando necessário

## ⚠️ Aviso operacional

Este kit altera configurações de sistema, serviços, privacidade e aplicativos. Antes de uso em produção:

- teste em ambiente controlado
- crie snapshot ou restore point
- valide compatibilidade com o hardware e a imagem alvo
- confirme que o conteúdo remoto está aprovado

## 🧰 Troubleshooting

### `winget` não encontrado

- valide se o `winget` está instalado e disponível no PATH
- reinicie o PowerShell após instalação
- execute `scripts/install.ps1` novamente

### Falha de elevação

- confirme que o terminal foi iniciado como administrador
- o script `scripts/install.ps1` tenta elevar automaticamente
- se o UAC bloquear a execução, valide permissões do usuário

### Erro ao baixar scripts remotos

- confirme conectividade com internet
- valide se o endpoint do GitHub RAW está acessível
- verifique se a URL do repositório foi alterada

### `powercfg` / `gpupdate` não encontrados

- o fluxo principal ajusta o `PATH` para incluir `System32` e `SysWOW64`
- se o erro persistir, valide se o ambiente executa em Windows completo

### Cache inválido ou versão divergente

- apague `C:\ADF-Kit\Cache` ou `config/version.json` para forçar atualização
- execute novamente `kit.ps1`

### Log não gerado

- valide se `C:\ADF-Kit\Logs` existe
- confirme se o script foi executado com permissões adequadas
- verifique o terminal ou a janela do processo filho

## 📄 Licença

Uso pessoal/técnico. Ajuste conforme sua necessidade.